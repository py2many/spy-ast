"""PEP 517 backend for spy-ast.

Build outputs include:
- Python package `spy_ast`
- Native V shared library
- CPython extension that calls into the V shared library
- Native parser executable fallback
"""

from __future__ import annotations

import base64
import hashlib
import io
import os
import pathlib
import shutil
import shlex
import subprocess
import sys
import sysconfig
import tarfile
import tempfile
import zipfile


NAME = "spy-ast"
VERSION = "0.1.7"
ROOT = pathlib.Path(__file__).resolve().parent
PACKAGE_DIR = ROOT / "spy_ast"
VSRC_DIR = ROOT
VCLI_DIR = ROOT / "cmd" / "pyast_parser"
EXT_SOURCE = PACKAGE_DIR / "_vext.c"
BINARY_BASENAME = "pyast_parser"


def _dist_info_dir() -> str:
    return f"{NAME.replace('-', '_')}-{VERSION}.dist-info"


def _python_tag() -> str:
    return f"cp{sys.version_info.major}{sys.version_info.minor}"


def _abi_tag() -> str:
    return _python_tag()


def _platform_tag() -> str:
    platform = sysconfig.get_platform().replace("-", "_").replace(".", "_")
    if sys.platform.startswith("linux"):
        if platform == "linux_x86_64":
            return "manylinux_2_34_x86_64"
        if platform == "linux_aarch64":
            return "manylinux_2_34_aarch64"
    if sys.platform == "darwin" and "universal2" in platform:
        # V emits a single-arch binary for the build host (arm64 on
        # macos-latest, x86_64 on older Intel runners). Tagging it
        # universal2 lies to pip: an Intel Mac would install an arm64-only
        # binary (or vice versa) and fail at import/dlopen time. Report the
        # real host arch instead. True fat binaries (lipo) can re-enable
        # universal2 once the backend actually produces them.
        # Note: arm64 macOS starts at 11.0, so a 10.x deployment target
        # carried over from the universal2 tag (e.g. macosx_10_13_arm64)
        # is invalid and rejected by installers (uv). Bump to 11.0.
        import platform as _plat
        import re as _re

        machine = _plat.machine().lower()
        arch = "arm64" if machine in ("arm64", "aarch64") else "x86_64"
        platform = platform.replace("universal2", arch)
        if arch == "arm64":
            m = _re.match(r"macosx_(\d+)_(\d+)_arm64", platform)
            if m and (int(m.group(1)), int(m.group(2))) < (11, 0):
                platform = "macosx_11_0_arm64"
    return platform


def _wheel_tag() -> str:
    return f"{_python_tag()}-{_abi_tag()}-{_platform_tag()}"



def _wheel_name() -> str:
    return f"{NAME.replace('-', '_')}-{VERSION}-{_wheel_tag()}.whl"


def _metadata() -> str:
    return "\n".join(
        [
            "Metadata-Version: 2.1",
            f"Name: {NAME}",
            f"Version: {VERSION}",
            "Summary: Static Python AST parser for a modified Python dialect with match as an expression.",
            "Requires-Python: >=3.10",
            "",
        ]
    )


def _wheel_file() -> str:
    return "\n".join(
        [
            "Wheel-Version: 1.0",
            "Generator: spy-ast-local-backend",
            "Root-Is-Purelib: false",
            f"Tag: {_wheel_tag()}",
            "",
        ]
    )


def _record_line(path: str, data: bytes) -> tuple[str, str, str]:
    digest = hashlib.sha256(data).digest()
    b64 = base64.urlsafe_b64encode(digest).decode("ascii").rstrip("=")
    return path, f"sha256={b64}", str(len(data))


def _run_checked(cmd: list[str], cwd: pathlib.Path | None = None) -> None:
    proc = subprocess.run(cmd, cwd=cwd, check=False, text=True, capture_output=True)
    if proc.returncode != 0:
        out = (proc.stdout or "").strip()
        err = (proc.stderr or "").strip()
        # V prints the real C compiler error to stdout, with only
        # "builder error:" on stderr. Include both, tail-capped.
        combined = "\n".join(s for s in (err, out) if s)
        if len(combined) > 8000:
            combined = combined[-8000:]
        message = combined or "command failed"
        rendered = " ".join(shlex.quote(x) for x in cmd)
        raise RuntimeError(f"{rendered}: {message}")


def _remove_gnu_property_note(path: pathlib.Path) -> None:
    if os.name == "nt" or not sys.platform.startswith("linux"):
        return
    objcopy = shutil.which("objcopy")
    if objcopy is None:
        return
    _run_checked([objcopy, "--remove-section", ".note.gnu.property", str(path)], cwd=ROOT)


def _with_module_path(cmd: list[str], temp_dir: pathlib.Path) -> list[str]:
    module_dir = temp_dir / "pyast"
    temp_dir.mkdir(parents=True, exist_ok=True)
    try:
        module_dir.symlink_to(ROOT, target_is_directory=True)
    except OSError:
        shutil.copytree(
            ROOT,
            module_dir,
            ignore=shutil.ignore_patterns(
                ".git",
                ".venv",
                "__pycache__",
                "dist",
                "dist-*",
                "wheelhouse",
                "vlang",
            ),
        )
    return [cmd[0], "-path", f"{temp_dir}|@vlib|@vmodules", *cmd[1:]]


def _shared_lib_name() -> str:
    if os.name == "nt":
        return "pyast_parser.dll"
    if sys.platform == "darwin":
        return "libpyast_parser.dylib"
    return "libpyast_parser.so"


def _vflags() -> list[str]:
    return shlex.split(os.environ.get("VFLAGS", ""))


def _vflags_for_native() -> list[str]:
    """Flags for building the shared lib and fallback binary.

    V's default Linux backend is its bundled TCC, which emits a reference
    to ``tcc_backtrace`` (builtin backtrace support). That symbol is
    provided by the TCC runtime when linking executables, but stays
    undefined in ``v -shared`` output, so ``dlopen()`` fails on
    ubuntu-24.04 with ``undefined symbol: tcc_backtrace`` (py2many#857
    attempt #3, 44 failures, all ``-k rust``). Forcing ``-cc gcc`` plus
    ``-d no_backtrace`` avoids the TCC runtime entirely. Only applied on
    Linux and only if the caller did not already select a compiler.

    On macOS the downloaded V distribution (v_macos_arm64.zip) links
    ``-lgc`` against its own bundled ``thirdparty/tcc/lib`` with an
    absolute ``LC_RPATH`` pointing at the build machine, so 0.1.5 macOS
    wheels failed off the CI builder with ``dyld: Library not loaded:
    @rpath/libgc.dylib`` (py2many ``-k rust``: 43 failures). Forcing
    ``-cc clang`` keeps the toolchain consistent; standalone-ness is then
    enforced by vendoring any remaining non-system dylibs into the wheel
    (see :func:`_bundle_macos_libraries`). Only applied on macOS when the
    caller did not already select a compiler."""
    flags = _vflags()
    if sys.platform.startswith("linux"):
        if not any(f == "-cc" or f.startswith("-cc=") for f in flags):
            flags = ["-cc", "gcc", *flags]
        if "no_backtrace" not in flags:
            flags = ["-d", "no_backtrace", *flags]
    elif sys.platform == "darwin":
        if not any(f == "-cc" or f.startswith("-cc=") for f in flags):
            flags = ["-cc", "clang", *flags]
    return flags


def _assert_macos_standalone(path: pathlib.Path) -> None:
    """Fail fast if a macOS artifact needs CI-only dynamic libraries.

    The 0.1.5 macOS wheels shipped binaries with
    ``@rpath/libgc.dylib`` + ``LC_RPATH .../work/_temp/vlang/...`` which
    only exists on the GitHub Actions builder. Runs after
    :func:`_bundle_macos_libraries`; anything still referencing ``@rpath``
    or a builder-temp ``LC_RPATH`` is a hard error so a broken wheel never
    reaches PyPI."""
    if sys.platform != "darwin":
        return
    own_id = _otool_install_id(path)
    for dep in _otool_linked_libs(path):
        if dep == own_id:
            continue
        if dep.startswith("@rpath/"):
            raise RuntimeError(
                f"{path.name}: unvendored dependency {dep}; "
                "_bundle_macos_libraries should have rewritten it"
            )
    for rpath in _otool_rpaths(path):
        if _is_builder_temp_path(rpath):
            raise RuntimeError(
                f"{path.name}: LC_RPATH points at builder temp dir ({rpath}); "
                "_bundle_macos_libraries should have removed it"
            )


_MACOS_TEMP_PATH_MARKERS = (
    "/Users/runner",
    "_temp/vlang",
    "/tmp/",
    "/var/folders",
    "/private/tmp",
    "/private/var",
)


def _is_builder_temp_path(path: str) -> bool:
    return any(marker in path for marker in _MACOS_TEMP_PATH_MARKERS)


def _otool_linked_libs(path: pathlib.Path) -> list[str]:
    """Parse ``otool -L`` into the list of recorded dependency paths."""
    proc = subprocess.run(
        ["otool", "-L", str(path)], check=False, text=True, capture_output=True
    )
    if proc.returncode != 0:
        raise RuntimeError(f"otool -L {path.name} failed: {proc.stderr.strip()}")
    libs: list[str] = []
    for line in proc.stdout.splitlines()[1:]:
        line = line.strip()
        if line:
            libs.append(line.split()[0])
    return libs


def _otool_rpaths(path: pathlib.Path) -> list[str]:
    """Parse ``otool -l`` into the list of LC_RPATH entries."""
    proc = subprocess.run(
        ["otool", "-l", str(path)], check=False, text=True, capture_output=True
    )
    if proc.returncode != 0:
        raise RuntimeError(f"otool -l {path.name} failed: {proc.stderr.strip()}")
    rpaths: list[str] = []
    in_rpath = False
    for line in proc.stdout.splitlines():
        stripped = line.strip()
        if stripped == "cmd LC_RPATH":
            in_rpath = True
        elif stripped.startswith("cmd "):
            in_rpath = False
        elif in_rpath and stripped.startswith("path "):
            rpaths.append(stripped[5:].split(" (offset")[0])
    return rpaths


def _needs_vendoring(dep: str) -> bool:
    """True for dynamic deps that won't exist on a user's machine."""
    if dep.startswith(("/usr/lib/", "/System/")):
        return False
    if dep.startswith("@rpath/"):
        return True
    # Absolute references outside the OS (e.g. /opt/homebrew/...dylib from
    # a -d dynamic_boehm build) break the same way off-machine.
    return dep.startswith("/")


def _otool_install_id(path: pathlib.Path) -> str | None:
    """Return a dylib's own LC_ID install name, or None for executables."""
    proc = subprocess.run(
        ["otool", "-D", str(path)], check=False, text=True, capture_output=True
    )
    if proc.returncode != 0:
        return None
    lines = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
    if len(lines) >= 2:
        return lines[-1]
    return None


def _resolve_macos_dep(dep: str, rpaths: list[str]) -> pathlib.Path:
    if dep.startswith("@rpath/"):
        rel = dep[len("@rpath/"):]
        for rpath in rpaths:
            candidate = pathlib.Path(rpath) / rel
            if candidate.is_file():
                return candidate.resolve()
        raise RuntimeError(
            f"cannot resolve {dep}; searched LC_RPATHs: {rpaths or ['(none)']}"
        )
    candidate = pathlib.Path(dep)
    if candidate.is_file():
        return candidate.resolve()
    raise RuntimeError(f"cannot resolve absolute dependency {dep}: file not found")


def _bundle_macos_libraries(entries: dict[str, bytes]) -> dict[str, bytes]:
    """Vendor non-system dylibs into the wheel (delocate-style).

    Upstream V links ``-lgc`` against its own ``thirdparty/tcc/lib`` with
    an absolute builder-only ``LC_RPATH`` (verified on 0.5.1 and 0.5.2),
    so without this step every macOS wheel dies off-builder with ``dyld:
    Library not loaded: @rpath/libgc.dylib``. Each needed library is
    copied to ``spy_ast/_lib/``, consumers are rewritten to
    ``@loader_path``-relative references, builder-temp ``LC_RPATH``s
    are deleted, and modified files are ad-hoc re-signed.

    Takes and returns ``{wheel arcname: file bytes}`` for the native
    artifacts; vendored libraries come back as extra ``spy_ast/_lib/*``
    entries. No-op when nothing needs vendoring (e.g. a Homebrew-V build
    that already links libgc statically).
    """
    for tool in ("otool", "install_name_tool", "codesign"):
        if shutil.which(tool) is None:
            raise RuntimeError(f"{tool} is required to build macOS wheels")
    package_prefix = f"{PACKAGE_DIR.name}/"
    lib_dir_arc = f"{PACKAGE_DIR.name}/_lib"
    with tempfile.TemporaryDirectory() as tmpdir:
        stage = pathlib.Path(tmpdir)
        for arcname, data in entries.items():
            target = stage / arcname
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        vendored: dict[str, str] = {}  # basename -> arcname under _lib
        pending = [
            stage / arcname
            for arcname in entries
            if (stage / arcname).is_file()
        ]
        while pending:
            consumer = pending.pop()
            own_id = _otool_install_id(consumer)
            rpaths = _otool_rpaths(consumer)
            for dep in _otool_linked_libs(consumer):
                if dep == own_id or not _needs_vendoring(dep):
                    continue
                basename = dep.rsplit("/", 1)[-1]
                if basename not in vendored:
                    resolved = _resolve_macos_dep(dep, rpaths)
                    dest = stage / lib_dir_arc / basename
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    dest.write_bytes(resolved.read_bytes())
                    try:
                        dest.chmod(0o755)
                    except OSError:
                        pass
                    vendored[basename] = f"{lib_dir_arc}/{basename}"
                    pending.append(dest)
        # Rewrite every staged Mach-O (artifacts + vendored libs).
        staged_files = [path for path in stage.rglob("*") if path.is_file()]
        for path in staged_files:
            arcname = path.relative_to(stage).as_posix()
            if not arcname.startswith(package_prefix):
                continue
            consumer_dir = pathlib.PurePosixPath(arcname).parent
            own_id = _otool_install_id(path)
            rpaths = _otool_rpaths(path)
            changed = False
            for dep in _otool_linked_libs(path):
                if dep == own_id or not _needs_vendoring(dep):
                    continue
                basename = dep.rsplit("/", 1)[-1]
                rel = os.path.relpath(
                    f"{lib_dir_arc}/{basename}", start=str(consumer_dir)
                )
                _run_checked(
                    ["install_name_tool", "-change", dep, f"@loader_path/{rel}", str(path)],
                    cwd=ROOT,
                )
                changed = True
            if path.parent == stage / lib_dir_arc:
                _run_checked(
                    ["install_name_tool", "-id", f"@loader_path/{path.name}", str(path)],
                    cwd=ROOT,
                )
                changed = True
            elif own_id is not None and (own_id.startswith("/") or own_id.startswith("@rpath/")):
                # Normalize the shared library's own temp-build install name
                # (e.g. /var/folders/.../libpyast_parser.dylib) so nothing
                # references the builder filesystem. Nothing looks it up by
                # id (_vext dlopens by absolute path), so any stable value works.
                if _is_builder_temp_path(own_id) or own_id.startswith("/"):
                    _run_checked(
                        ["install_name_tool", "-id", f"@rpath/{path.name}", str(path)],
                        cwd=ROOT,
                    )
                    changed = True
            for rpath in rpaths:
                if _is_builder_temp_path(rpath):
                    _run_checked(
                        ["install_name_tool", "-delete_rpath", rpath, str(path)],
                        cwd=ROOT,
                    )
                    changed = True
            if changed:
                _run_checked(["codesign", "-s", "-", "-f", str(path)], cwd=ROOT)
            _assert_macos_standalone(path)
        result: dict[str, bytes] = {}
        for path in staged_files:
            arcname = path.relative_to(stage).as_posix()
            if arcname.startswith(package_prefix):
                result[arcname] = path.read_bytes()
        return result


def _build_shared_library() -> tuple[str, bytes]:
    libname = _shared_lib_name()
    with tempfile.TemporaryDirectory() as tmpdir:
        temp_dir = pathlib.Path(tmpdir)
        out = temp_dir / libname
        target = temp_dir / "pyast"
        cmd = _with_module_path(
            ["v", "-enable-globals", *_vflags_for_native(), "-shared", "-o", str(out), str(target)],
            temp_dir,
        )
        _run_checked(cmd, cwd=ROOT)
        _assert_no_tcc_symbols(out)
        return libname, out.read_bytes()


def _build_binary() -> tuple[str, bytes]:
    suffix = ".exe" if os.name == "nt" else ""
    with tempfile.TemporaryDirectory() as tmpdir:
        temp_dir = pathlib.Path(tmpdir)
        out = temp_dir / f"{BINARY_BASENAME}{suffix}"
        target = temp_dir / "pyast" / "cmd" / "pyast_parser"
        cmd = _with_module_path(
            ["v", "-enable-globals", *_vflags_for_native(), "-o", str(out), str(target)],
            temp_dir,
        )
        _run_checked(cmd, cwd=ROOT)
        _remove_gnu_property_note(out)
        return out.name, out.read_bytes()


def _assert_no_tcc_symbols(path: pathlib.Path) -> None:
    """Fail fast if the shared lib keeps a TCC-runtime dependency.

    ``tcc_backtrace`` is undefined in the 0.1.3 manylinux wheels and
    breaks ``dlopen()`` on every Linux runner. ``nm`` may be absent on
    some builders, so a missing tool is a no-op; finding the symbol is
    a hard error."""
    if not sys.platform.startswith("linux"):
        return
    data = path.read_bytes()
    if b"tcc_backtrace" not in data:
        return
    nm = shutil.which("nm")
    if nm is not None:
        proc = subprocess.run(
            [nm, "-D", "--undefined-only", str(path)],
            check=False, text=True, capture_output=True,
        )
        if proc.returncode == 0 and "tcc_backtrace" in proc.stdout:
            raise RuntimeError(
                f"{path.name}: undefined symbol tcc_backtrace; "
                "build with -cc gcc -d no_backtrace"
            )
        return
    raise RuntimeError(
        f"{path.name}: contains tcc_backtrace reference; "
        "build with -cc gcc -d no_backtrace"
    )


def _build_python_extension() -> tuple[str, bytes]:
    ext_suffix = sysconfig.get_config_var("EXT_SUFFIX") or ".so"
    include_dir = sysconfig.get_paths().get("include")
    if not include_dir:
        raise RuntimeError("unable to locate Python include directory")
    with tempfile.TemporaryDirectory() as tmpdir:
        out = pathlib.Path(tmpdir) / f"_vext{ext_suffix}"
        cmd = ["cc", "-O2"]
        if os.name != "nt":
            cmd.append("-fPIC")
        cmd.extend(["-I", include_dir, str(EXT_SOURCE), "-shared", "-o", str(out)])
        if sys.platform == "darwin":
            cmd.extend(["-undefined", "dynamic_lookup"])
        elif os.name == "nt":
            lib_dir = sysconfig.get_config_var("LIBDIR") or str(pathlib.Path(sys.base_prefix) / "libs")
            py_lib = f"python{sys.version_info.major}{sys.version_info.minor}"
            cmd.extend(["-L", lib_dir, f"-l{py_lib}"])
        elif os.name != "nt":
            cmd.append("-ldl")
        _run_checked(cmd, cwd=ROOT)
        return out.name, out.read_bytes()


def _write_entry(zf: zipfile.ZipFile, arcname: str, data: bytes, mode: int) -> tuple[str, str, str]:
    info = zipfile.ZipInfo(arcname)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.create_system = 3  # Unix mode bits
    info.external_attr = (mode & 0xFFFF) << 16
    zf.writestr(info, data)
    return _record_line(arcname, data)


def _sdist_name() -> str:
    return f"{NAME.replace('-', '_')}-{VERSION}"


def _sdist_filename() -> str:
    return f"{_sdist_name()}.tar.gz"


def _sdist_paths() -> list[pathlib.Path]:
    paths = [
        ROOT / "build_backend.py",
        ROOT / "LICENSE",
        ROOT / "pyproject.toml",
        ROOT / "v.mod",
    ]
    paths.extend(sorted(PACKAGE_DIR.rglob("*.py")))
    paths.extend(sorted(PACKAGE_DIR.rglob("*.c")))
    paths.extend(sorted((ROOT / "tests_vlang_parser").rglob("*.py")))
    paths.extend(sorted(VSRC_DIR.glob("*.v")))
    paths.extend(sorted((ROOT / "cmd").rglob("*.v")))
    for sample in [ROOT / "test.py", ROOT / "test_nested_match.py"]:
        if sample.exists():
            paths.append(sample)
    return sorted({path for path in paths if path.exists()})


def _write_sdist_entry(tf: tarfile.TarFile, path: pathlib.Path, arcname: str) -> None:
    info = tf.gettarinfo(str(path), arcname)
    info.uid = 0
    info.gid = 0
    info.uname = ""
    info.gname = ""
    with path.open("rb") as handle:
        tf.addfile(info, handle)


def _write_sdist_bytes(tf: tarfile.TarFile, arcname: str, data: bytes, mode: int = 0o644) -> None:
    info = tarfile.TarInfo(arcname)
    info.size = len(data)
    info.mode = mode
    info.uid = 0
    info.gid = 0
    info.uname = ""
    info.gname = ""
    tf.addfile(info, io.BytesIO(data))


def get_requires_for_build_wheel(config_settings=None):  # noqa: D401
    return []


def get_requires_for_build_sdist(config_settings=None):
    return []


def get_requires_for_build_editable(config_settings=None):
    return []


def build_sdist(sdist_directory, config_settings=None):
    sdist_dir = pathlib.Path(sdist_directory)
    sdist_dir.mkdir(parents=True, exist_ok=True)
    sdist_path = sdist_dir / _sdist_filename()
    prefix = _sdist_name()

    with tarfile.open(sdist_path, "w:gz", format=tarfile.PAX_FORMAT) as tf:
        _write_sdist_bytes(tf, f"{prefix}/PKG-INFO", _metadata().encode("utf-8"))
        for path in _sdist_paths():
            arcname = f"{prefix}/{path.relative_to(ROOT).as_posix()}"
            _write_sdist_entry(tf, path, arcname)

    return sdist_path.name


def build_wheel(wheel_directory, config_settings=None, metadata_directory=None):
    wheel_dir = pathlib.Path(wheel_directory)
    wheel_dir.mkdir(parents=True, exist_ok=True)
    wheel_path = wheel_dir / _wheel_name()
    dist_info = _dist_info_dir()

    ext_name, ext_data = _build_python_extension()
    lib_name, lib_data = _build_shared_library()
    bin_name, bin_data = _build_binary()

    native_entries = {
        f"{PACKAGE_DIR.name}/{lib_name}": lib_data,
        f"{PACKAGE_DIR.name}/_bin/{bin_name}": bin_data,
    }
    if sys.platform == "darwin":
        # Rewrite builder-only dynamic deps (e.g. V's @rpath/libgc.dylib)
        # to vendored @loader_path copies; fails fast on regression.
        native_entries = _bundle_macos_libraries(native_entries)

    rows: list[tuple[str, str, str]] = []
    with zipfile.ZipFile(wheel_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for py in sorted(PACKAGE_DIR.rglob("*.py")):
            arcname = py.relative_to(ROOT).as_posix()
            rows.append(_write_entry(zf, arcname, py.read_bytes(), 0o644))

        rows.append(_write_entry(zf, f"{PACKAGE_DIR.name}/{ext_name}", ext_data, 0o755))
        for arcname in sorted(native_entries):
            rows.append(_write_entry(zf, arcname, native_entries[arcname], 0o755))

        for src in sorted(VSRC_DIR.glob("*.v")):
            rows.append(
                _write_entry(
                    zf,
                    f"{PACKAGE_DIR.name}/_vsrc/{src.name}",
                    src.read_bytes(),
                    0o644,
                )
            )
        for src in sorted(VCLI_DIR.glob("*.v")):
            rows.append(
                _write_entry(
                    zf,
                    f"{PACKAGE_DIR.name}/_vsrc/cmd/pyast_parser/{src.name}",
                    src.read_bytes(),
                    0o644,
                )
            )

        metadata_path = f"{dist_info}/METADATA"
        rows.append(_write_entry(zf, metadata_path, _metadata().encode("utf-8"), 0o644))

        wheel_meta_path = f"{dist_info}/WHEEL"
        rows.append(_write_entry(zf, wheel_meta_path, _wheel_file().encode("utf-8"), 0o644))

        record_path = f"{dist_info}/RECORD"
        record_lines = [",".join(row) for row in rows]
        record_lines.append(f"{record_path},,")
        record_data = ("\n".join(record_lines) + "\n").encode("utf-8")
        _write_entry(zf, record_path, record_data, 0o644)

    return wheel_path.name


def build_editable(wheel_directory, config_settings=None, metadata_directory=None):
    return build_wheel(wheel_directory, config_settings, metadata_directory)


def prepare_metadata_for_build_wheel(metadata_directory, config_settings=None):
    meta_dir = pathlib.Path(metadata_directory) / _dist_info_dir()
    meta_dir.mkdir(parents=True, exist_ok=True)
    (meta_dir / "METADATA").write_text(_metadata(), encoding="utf-8")
    (meta_dir / "WHEEL").write_text(_wheel_file(), encoding="utf-8")
    (meta_dir / "RECORD").write_text("", encoding="utf-8")
    return meta_dir.name


def prepare_metadata_for_build_editable(metadata_directory, config_settings=None):
    return prepare_metadata_for_build_wheel(metadata_directory, config_settings)
