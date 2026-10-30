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
VERSION = "0.1.6"
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

    On macOS the downloaded V distribution (v_macos_arm64.zip) links via
    its bundled TCC by default, producing binaries with
    ``@rpath/libgc.dylib`` and ``LC_RPATH /Users/runner/work/_temp/vlang/v/``
    baked in. That path only exists on the CI builder, so every 0.1.5
    macOS wheel fails at runtime with ``dyld: Library not loaded:
    @rpath/libgc.dylib`` (py2many ``-k rust``: 43 failures). Forcing
    ``-cc clang`` links the system/bundled libgc statically (as the
    Homebrew V does locally) and yields a standalone binary with only a
    libSystem dependency. Only applied on macOS when the caller did not
    already select a compiler."""
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
    only exists on the GitHub Actions builder. Catch that here so a broken
    wheel never reaches PyPI. ``otool`` is always present on macOS
    builders; a missing tool is a no-op."""
    if sys.platform != "darwin":
        return
    otool = shutil.which("otool")
    if otool is None:
        return
    proc = subprocess.run(
        [otool, "-L", str(path)], check=False, text=True, capture_output=True
    )
    if proc.returncode != 0:
        return
    output = proc.stdout
    if "@rpath/libgc.dylib" in output:
        raise RuntimeError(
            f"{path.name}: links @rpath/libgc.dylib; "
            "build with -cc clang for a static libgc"
        )
    rproc = subprocess.run(
        [otool, "-l", str(path)], check=False, text=True, capture_output=True
    )
    if rproc.returncode == 0 and ("/Users/runner" in rproc.stdout or "_temp/vlang" in rproc.stdout):
        raise RuntimeError(
            f"{path.name}: LC_RPATH points at CI builder temp dir; "
            "build with -cc clang for a standalone binary"
        )


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
        _assert_macos_standalone(out)
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
        _assert_macos_standalone(out)
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

    rows: list[tuple[str, str, str]] = []
    with zipfile.ZipFile(wheel_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for py in sorted(PACKAGE_DIR.rglob("*.py")):
            arcname = py.relative_to(ROOT).as_posix()
            rows.append(_write_entry(zf, arcname, py.read_bytes(), 0o644))

        rows.append(_write_entry(zf, f"{PACKAGE_DIR.name}/{ext_name}", ext_data, 0o755))
        rows.append(_write_entry(zf, f"{PACKAGE_DIR.name}/{lib_name}", lib_data, 0o755))
        rows.append(_write_entry(zf, f"{PACKAGE_DIR.name}/_bin/{bin_name}", bin_data, 0o755))

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
