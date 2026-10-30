from __future__ import annotations

"""Parse helpers shared by the ``spy_ast`` package.

All parsing is done by the V-based dialect parser; the standard library
parser is never consulted. The parser accepts the Python-compatible subset
plus the ``match``-as-expression extension, and raises :class:`SyntaxError`
for anything else. Rejecting the long tail of valid Python outside the
subset is deliberate: a successful parse always means a faithful tree.

* :func:`parse_expression` / :func:`parse_module` are the direct entry
  points for expressions and modules.
* :func:`parse` mirrors the :func:`ast.parse` signature (``source``,
  ``filename``, ``mode``, ``type_comments``, ``feature_version``) so it can
  replace it call-for-call. The extra keyword arguments are accepted for
  compatibility but do not change parsing.
"""

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

from . import ast

try:
    from . import _vext  # type: ignore[attr-defined]
except Exception:
    _vext = None


PKG_DIR = Path(__file__).resolve().parent
ROOT = PKG_DIR.parents[0]
V_SOURCE_DIR = ROOT
V_CLI_SOURCE_DIR = ROOT / "cmd" / "pyast_parser"
PACKAGED_V_SOURCE_DIR = PKG_DIR / "_vsrc"
PARSER_BINARY = PKG_DIR / "_bin" / ("pyast_parser.exe" if os.name == "nt" else "pyast_parser")


class SpySyntaxError(SyntaxError, ValueError):
    """Raised when the dialect parser rejects its input.

    Subclasses :class:`SyntaxError` so ``except SyntaxError`` handlers written
    for builtin :func:`ast.parse` keep working, and :class:`ValueError` for
    backwards compatibility with earlier ``spy-ast`` releases.
    """


def parse(
    source: str | bytes | bytearray,
    filename: str = "<unknown>",
    mode: str = "exec",
    *,
    type_comments: bool = False,
    feature_version: tuple[int, int] | None = None,
    optimize: int = -1,
) -> Any:
    """Drop-in replacement for :func:`ast.parse`, powered only by spy-ast.

    Accepts the same arguments (``type_comments``, ``feature_version`` and
    ``optimize`` are accepted for compatibility and otherwise ignored).
    ``mode="eval"`` parses an expression, ``mode="exec"`` a module, and
    ``mode="single"`` a module body wrapped in :class:`ast.Interactive`.
    Raises :class:`SyntaxError` for source outside the supported subset.
    """
    if mode != "exec" and mode != "eval" and mode != "single":
        raise ValueError(f"parse() mode must be 'exec', 'eval' or 'single', not {mode!r}")
    if isinstance(source, ast.AST):
        # Mirror the standard library: compile() accepts an already-parsed
        # tree and round-trips it (py2many passes trees back into ast.parse).
        if mode == "exec" and isinstance(source, ast.Module):
            return source
        if mode == "eval" and isinstance(source, ast.Expression):
            return source
        if mode == "single" and isinstance(source, ast.Interactive):
            return source
        if mode == "eval":
            raise TypeError(f"expected Expression node, got {type(source).__name__}")
        raise TypeError(f"expected Module node, got {type(source).__name__}")
    text = _coerce_text(source)
    try:
        if mode == "eval":
            return parse_expression(text)
        module = parse_module(text)
        if mode == "single":
            return ast.fix_missing_locations(ast.Interactive(body=module.body))
        return module
    except SpySyntaxError as err:
        err.filename = filename
        raise


def parse_expression(source: str | bytes | bytearray) -> ast.Expression:
    payload = _run_parser("--json-expr", _coerce_text(source))
    tree = ast.Expression(body=_expr_from_json(payload))
    return ast.fix_missing_locations(tree)


def parse_module(source: str | bytes | bytearray) -> ast.Module:
    payload = _run_parser("--json", _coerce_text(source))
    if payload.get("type") != "Module":
        raise SpySyntaxError(f"expected Module payload, got {payload.get('type')}")
    tree = ast.Module(body=[_stmt_from_json(item) for item in payload["body"]], type_ignores=[])
    return ast.fix_missing_locations(tree)


def _coerce_text(source: str | bytes | bytearray) -> str:
    if isinstance(source, str):
        return source
    if isinstance(source, (bytes, bytearray)):
        return bytes(source).decode("utf-8")
    raise TypeError(f"parse() argument must be str or bytes, got {type(source).__name__}")


def _run_parser(mode: str, source: str) -> dict[str, Any]:
    if _vext is not None:
        payload = _vext.parse_json(mode, source, str(PKG_DIR))
        return json.loads(payload)

    with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False) as handle:
        path = Path(handle.name)
        handle.write(source)

    cmd, cwd, module_path = _parser_command(mode, path)
    try:
        env = os.environ.copy()
        if module_path is not None:
            env["VMODULES"] = str(module_path)
        proc = subprocess.run(cmd, cwd=cwd, env=env, check=False, text=True, capture_output=True)
    finally:
        path.unlink(missing_ok=True)
        if module_path is not None:
            link = module_path / "pyast"
            link.unlink(missing_ok=True)
            shutil.rmtree(module_path, ignore_errors=True)

    if proc.returncode != 0:
        message = proc.stderr.strip() or proc.stdout.strip() or "unknown parser failure"
        raise SpySyntaxError(message)

    return json.loads(proc.stdout)


def _parser_command(mode: str, source_path: Path) -> tuple[list[str], Path, Path | None]:
    if PARSER_BINARY.exists():
        return [str(PARSER_BINARY), mode, str(source_path)], ROOT, None
    if PACKAGED_V_SOURCE_DIR.exists():
        module_path = _module_path_for(PACKAGED_V_SOURCE_DIR)
        packaged_cli = module_path / "pyast" / "cmd" / "pyast_parser"
        return ["v", "-enable-globals", "run", str(packaged_cli), mode, str(source_path)], ROOT, module_path
    module_path = _module_path_for(V_SOURCE_DIR)
    local_cli = module_path / "pyast" / "cmd" / "pyast_parser"
    return ["v", "-enable-globals", "run", str(local_cli), mode, str(source_path)], ROOT, module_path


def _module_path_for(source_dir: Path) -> Path:
    module_path = Path(tempfile.mkdtemp(prefix="pyast_vmodules_"))
    (module_path / "pyast").symlink_to(source_dir, target_is_directory=True)
    return module_path


def _stmt_from_json_inner(data: dict[str, Any]) -> ast.stmt:
    kind = data["type"]
    if kind == "Import":
        return ast.Import(names=[_alias_from_json(item) for item in data["names"]])
    if kind == "ImportFrom":
        return ast.ImportFrom(
            module=data["module"] or None,
            names=[_alias_from_json(item) for item in data["names"]],
            level=data.get("level", 0),
        )
    if kind == "Expr":
        return ast.Expr(value=_expr_from_json(data["value"]))
    if kind == "Assign":
        return ast.Assign(
            targets=[_set_ctx(_expr_from_json(item), ast.Store) for item in data["targets"]],
            value=_expr_from_json(data["value"]),
            type_comment=None,
        )
    if kind == "AugAssign":
        return ast.AugAssign(
            target=_set_ctx(_expr_from_json(data["target"]), ast.Store),
            op=_bin_op(data["op"]),
            value=_expr_from_json(data["value"]),
        )
    if kind == "AnnAssign":
        value = data.get("value")
        return ast.AnnAssign(
            target=_set_ctx(_expr_from_json(data["target"]), ast.Store),
            annotation=_expr_from_json(data["annotation"]),
            value=None if value is None else _expr_from_json(value),
            simple=int(data.get("simple", 0)),
        )
    if kind == "Pass":
        return ast.Pass()
    if kind == "Break":
        return ast.Break()
    if kind == "Continue":
        return ast.Continue()
    if kind == "Return":
        raw = data["value"]
        return ast.Return(value=None if raw is None else _expr_from_json(raw))
    if kind == "Assert":
        raw = data.get("msg")
        return ast.Assert(
            test=_expr_from_json(data["test"]),
            msg=None if raw is None else _expr_from_json(raw),
        )
    if kind == "Delete":
        return ast.Delete(
            targets=[_set_ctx(_expr_from_json(item), ast.Del) for item in data["targets"]]
        )
    if kind == "Raise":
        exc = data.get("exc")
        cause = data.get("cause")
        return ast.Raise(
            exc=None if exc is None else _expr_from_json(exc),
            cause=None if cause is None else _expr_from_json(cause),
        )
    if kind == "Global":
        return ast.Global(names=list(data.get("names", [])))
    if kind == "Nonlocal":
        return ast.Nonlocal(names=list(data.get("names", [])))
    if kind == "If":
        return ast.If(
            test=_expr_from_json(data["test"]),
            body=[_stmt_from_json(item) for item in data["body"]],
            orelse=[_stmt_from_json(item) for item in data["orelse"]],
        )
    if kind == "While":
        return ast.While(
            test=_expr_from_json(data["test"]),
            body=[_stmt_from_json(item) for item in data["body"]],
            orelse=[_stmt_from_json(item) for item in data["orelse"]],
        )
    if kind in ("For", "AsyncFor"):
        node = (
            ast.AsyncFor
            if kind == "AsyncFor"
            else ast.For
        )(
            target=_set_ctx(_expr_from_json(data["target"]), ast.Store),
            iter=_expr_from_json(data["iter"]),
            body=[_stmt_from_json(item) for item in data["body"]],
            orelse=[_stmt_from_json(item) for item in data["orelse"]],
            type_comment=None,
        )
        return node
    if kind in ("FunctionDef", "AsyncFunctionDef"):
        cls = ast.AsyncFunctionDef if kind == "AsyncFunctionDef" else ast.FunctionDef
        node = cls(
            name=data["name"],
            args=_arguments_from_json(data["args"]),
            body=[_stmt_from_json(item) for item in data["body"]],
            decorator_list=[_expr_from_json(item) for item in data.get("decorator_list", [])],
            returns=None
            if data.get("returns") is None
            else _expr_from_json(data["returns"]),
            type_comment=None,
        )
        _set_optional_field(node, "type_params", [])
        return node
    if kind == "ClassDef":
        node = ast.ClassDef(
            name=data["name"],
            bases=[_expr_from_json(item) for item in data["bases"]],
            keywords=[_keyword_from_json(item) for item in data.get("keywords", [])],
            body=[_stmt_from_json(item) for item in data["body"]],
            decorator_list=[_expr_from_json(item) for item in data.get("decorator_list", [])],
        )
        _set_optional_field(node, "type_params", [])
        return node
    if kind in ("With", "AsyncWith"):
        cls = ast.AsyncWith if kind == "AsyncWith" else ast.With
        return cls(
            items=[_withitem_from_json(item) for item in data["items"]],
            body=[_stmt_from_json(item) for item in data["body"]],
            type_comment=None,
        )
    if kind in ("Try", "TryStar"):
        cls = ast.TryStar if kind == "TryStar" else ast.Try
        return cls(
            body=[_stmt_from_json(item) for item in data["body"]],
            handlers=[_except_handler_from_json(item) for item in data["handlers"]],
            orelse=[_stmt_from_json(item) for item in data["orelse"]],
            finalbody=[_stmt_from_json(item) for item in data["finalbody"]],
        )
    raise SpySyntaxError(f"unsupported statement type: {kind}")


def _expr_from_json_inner(data: dict[str, Any]) -> ast.expr:
    kind = data["type"]
    if kind == "Constant":
        return ast.Constant(value=data["value"], kind=None)
    if kind == "Float":
        return ast.Constant(value=float(data["value"]), kind=None)
    if kind == "Ellipsis":
        return ast.Constant(value=Ellipsis, kind=None)
    if kind == "Bytes":
        return ast.Constant(value=bytes(data["value"]))
    if kind == "Name":
        return ast.Name(id=data["id"], ctx=ast.Load())
    if kind == "Call":
        return ast.Call(
            func=_expr_from_json(data["func"]),
            args=[_expr_from_json(item) for item in data["args"]],
            keywords=[_keyword_from_json(item) for item in data.get("keywords", [])],
        )
    if kind == "Attribute":
        return ast.Attribute(value=_expr_from_json(data["value"]), attr=data["attr"], ctx=ast.Load())
    if kind == "Subscript":
        return ast.Subscript(
            value=_expr_from_json(data["value"]),
            slice=_expr_from_json(data["slice"]),
            ctx=ast.Load(),
        )
    if kind == "Starred":
        return ast.Starred(value=_expr_from_json(data["value"]), ctx=ast.Load())
    if kind == "Slice":
        lower = data.get("lower")
        upper = data.get("upper")
        step = data.get("step")
        return ast.Slice(
            lower=None if lower is None else _expr_from_json(lower),
            upper=None if upper is None else _expr_from_json(upper),
            step=None if step is None else _expr_from_json(step),
        )
    if kind == "UnaryOp":
        return ast.UnaryOp(op=_unary_op(data["op"]), operand=_expr_from_json(data["operand"]))
    if kind == "BinOp":
        return ast.BinOp(
            left=_expr_from_json(data["left"]),
            op=_bin_op(data["op"]),
            right=_expr_from_json(data["right"]),
        )
    if kind == "BoolOp":
        return ast.BoolOp(op=_bool_op(data["op"]), values=[_expr_from_json(item) for item in data["values"]])
    if kind == "Compare":
        return ast.Compare(
            left=_expr_from_json(data["left"]),
            ops=[_cmp_op(str(x)) for x in data["ops"]],
            comparators=[_expr_from_json(item) for item in data["comparators"]],
        )
    if kind == "IfExp":
        return ast.IfExp(
            test=_expr_from_json(data["test"]),
            body=_expr_from_json(data["body"]),
            orelse=_expr_from_json(data["orelse"]),
        )
    if kind == "NamedExpr":
        return ast.NamedExpr(
            target=ast.Name(id=data["target"], ctx=ast.Store()),
            value=_expr_from_json(data["value"]),
        )
    if kind == "Lambda":
        return ast.Lambda(
            args=_arguments_from_json(data["args"]),
            body=_expr_from_json(data["body"]),
        )
    if kind == "Yield":
        raw = data.get("value")
        return ast.Yield(value=None if raw is None else _expr_from_json(raw))
    if kind == "YieldFrom":
        return ast.YieldFrom(value=_expr_from_json(data["value"]))
    if kind == "Await":
        return ast.Await(value=_expr_from_json(data["value"]))
    if kind == "List":
        return ast.List(elts=[_expr_from_json(item) for item in data["elts"]], ctx=ast.Load())
    if kind == "Tuple":
        return ast.Tuple(elts=[_expr_from_json(item) for item in data["elts"]], ctx=ast.Load())
    if kind == "Set":
        return ast.Set(elts=[_expr_from_json(item) for item in data["elts"]])
    if kind == "Dict":
        keys = [None if item is None else _expr_from_json(item) for item in data["keys"]]
        return ast.Dict(keys=keys, values=[_expr_from_json(item) for item in data["values"]])
    if kind == "ListComp":
        return ast.ListComp(
            elt=_expr_from_json(data["elt"]),
            generators=[_comprehension_from_json(item) for item in data["generators"]],
        )
    if kind == "SetComp":
        return ast.SetComp(
            elt=_expr_from_json(data["elt"]),
            generators=[_comprehension_from_json(item) for item in data["generators"]],
        )
    if kind == "GeneratorExp":
        return ast.GeneratorExp(
            elt=_expr_from_json(data["elt"]),
            generators=[_comprehension_from_json(item) for item in data["generators"]],
        )
    if kind == "DictComp":
        return ast.DictComp(
            key=_expr_from_json(data["key"]),
            value=_expr_from_json(data["value"]),
            generators=[_comprehension_from_json(item) for item in data["generators"]],
        )
    if kind == "JoinedStr":
        return ast.JoinedStr(values=[_expr_from_json(item) for item in data["values"]])
    if kind == "FormattedValue":
        raw = data.get("format_spec")
        return ast.FormattedValue(
            value=_expr_from_json(data["value"]),
            conversion=int(data.get("conversion", -1)),
            format_spec=None if raw is None else _expr_from_json(raw),
        )
    if kind == "Match":
        return ast.Match(
            subject=_expr_from_json(data["subject"]),
            cases=[_case_from_json(item) for item in data["cases"]],
        )
    raise SpySyntaxError(f"unsupported expression type: {kind}")



def _apply_loc(node, data):
    """Attach V-parser source positions, mirroring stdlib ``ast`` attributes."""
    node.lineno = data.get("line") or 1
    node.col_offset = data.get("col", 0) or 0
    node.end_lineno = data.get("end_line") or node.lineno
    node.end_col_offset = data.get("end_col", 0) or 0
    return node


def _stmt_from_json(data):
    return _apply_loc(_stmt_from_json_inner(data), data)

def _expr_from_json(data):
    return _apply_loc(_expr_from_json_inner(data), data)

def _arg_from_json(data):
    return _apply_loc(_arg_from_json_inner(data), data)

def _arguments_from_json(data):
    return _apply_loc(_arguments_from_json_inner(data), data)

def _keyword_from_json(data):
    return _apply_loc(_keyword_from_json_inner(data), data)

def _comprehension_from_json(data):
    return _apply_loc(_comprehension_from_json_inner(data), data)

def _except_handler_from_json(data):
    return _apply_loc(_except_handler_from_json_inner(data), data)

def _withitem_from_json(data):
    return _apply_loc(_withitem_from_json_inner(data), data)

def _pattern_from_json(data):
    return _apply_loc(_pattern_from_json_inner(data), data)

def _case_from_json(data):
    return _apply_loc(_case_from_json_inner(data), data)

def _alias_from_json(data):
    return _apply_loc(_alias_from_json_inner(data), data)


def _set_ctx(node: ast.AST, ctx: ast.expr_context) -> ast.AST:
    if isinstance(node, ast.Name):
        node.ctx = ctx() if isinstance(ctx, type) else ctx
        return node
    if isinstance(node, ast.Starred):
        node.value = _set_ctx(node.value, ctx)
        node.ctx = ctx() if isinstance(ctx, type) else ctx
        return node
    if isinstance(node, (ast.Tuple, ast.List)):
        node.elts = [_set_ctx(elt, ctx) for elt in node.elts]
        node.ctx = ctx() if isinstance(ctx, type) else ctx
        return node
    if isinstance(node, (ast.Attribute, ast.Subscript)):
        node.ctx = ctx() if isinstance(ctx, type) else ctx
        return node
    return node


def _keyword_from_json_inner(data: dict[str, Any]) -> ast.keyword:
    return ast.keyword(arg=data.get("arg"), value=_expr_from_json(data["value"]))


def _comprehension_from_json_inner(data: dict[str, Any]) -> ast.comprehension:
    return ast.comprehension(
        target=_set_ctx(_expr_from_json(data["target"]), ast.Store),
        iter=_expr_from_json(data["iter"]),
        ifs=[_expr_from_json(item) for item in data.get("ifs", [])],
        is_async=int(data.get("is_async", 0)),
    )


def _except_handler_from_json_inner(data: dict[str, Any]) -> ast.ExceptHandler:
    if data.get("type", "ExceptHandler") != "ExceptHandler":
        raise SpySyntaxError(f"unsupported handler type: {data.get('type')}")
    typ = data.get("typ")
    return ast.ExceptHandler(
        type=None if typ is None else _expr_from_json(typ),
        name=data.get("name"),
        body=[_stmt_from_json(item) for item in data["body"]],
    )


def _withitem_from_json_inner(data: dict[str, Any]) -> ast.withitem:
    if data.get("type", "withitem") != "withitem":
        raise SpySyntaxError(f"unsupported withitem type: {data.get('type')}")
    raw = data.get("vars")
    return ast.withitem(
        context_expr=_expr_from_json(data["context_expr"]),
        optional_vars=None if raw is None else _set_ctx(_expr_from_json(raw), ast.Store),
    )


def _arg_from_json_inner(data: dict[str, Any]) -> ast.arg:
    raw = data.get("annotation")
    return ast.arg(
        arg=str(data["arg"]),
        annotation=None if raw is None else _expr_from_json(raw),
        type_comment=None,
    )


def _arguments_from_json_inner(data: dict[str, Any]) -> ast.arguments:
    return ast.arguments(
        posonlyargs=[_arg_from_json(item) for item in data.get("posonlyargs", [])],
        args=[_arg_from_json(item) for item in data.get("args", [])],
        vararg=None if data.get("vararg") is None else _arg_from_json(data["vararg"]),
        kwonlyargs=[_arg_from_json(item) for item in data.get("kwonlyargs", [])],
        kw_defaults=[
            None if item is None else _expr_from_json(item)
            for item in data.get("kw_defaults", [])
        ],
        kwarg=None if data.get("kwarg") is None else _arg_from_json(data["kwarg"]),
        defaults=[_expr_from_json(item) for item in data.get("defaults", [])],
    )


def _pattern_from_json_inner(data: dict[str, Any]) -> ast.pattern:
    kind = data["type"]
    if kind == "MatchAs":
        return ast.MatchAs(pattern=None, name=data.get("name"))
    if kind == "MatchValue":
        value = _expr_from_json(data["value"])
        if not isinstance(value, ast.Constant):
            raise SpySyntaxError("MatchValue must contain Constant")
        return ast.MatchValue(value=value)
    raise SpySyntaxError(f"unsupported pattern type: {kind}")


def _case_from_json_inner(data: dict[str, Any]) -> ast.match_case:
    if data["type"] != "match_case":
        raise SpySyntaxError(f"unsupported case type: {data['type']}")
    return ast.match_case(
        pattern=_pattern_from_json(data["pattern"]),
        guard=None,
        body=[ast.Expr(value=_expr_from_json(data["body"]))],
    )


def _alias_from_json_inner(data: dict[str, Any]) -> ast.alias:
    return ast.alias(name=data["name"], asname=data.get("asname"))


def _set_optional_field(node: ast.AST, name: str, value: Any) -> None:
    if name in getattr(node, "_fields", ()):
        setattr(node, name, value)


def _unary_op(name: str) -> ast.unaryop:
    ops = {
        "Not": ast.Not,
        "UAdd": ast.UAdd,
        "USub": ast.USub,
        "Invert": ast.Invert,
    }
    return ops[name]()


def _bin_op(name: str) -> ast.operator:
    ops = {
        "Add": ast.Add,
        "Sub": ast.Sub,
        "Mult": ast.Mult,
        "Div": ast.Div,
        "FloorDiv": ast.FloorDiv,
        "Mod": ast.Mod,
        "Pow": ast.Pow,
        "MatMult": ast.MatMult,
        "BitAnd": ast.BitAnd,
        "BitOr": ast.BitOr,
        "BitXor": ast.BitXor,
        "LShift": ast.LShift,
        "RShift": ast.RShift,
    }
    return ops[name]()


def _bool_op(name: str) -> ast.boolop:
    ops = {
        "And": ast.And,
        "Or": ast.Or,
    }
    return ops[name]()


def _cmp_op(name: str) -> ast.cmpop:
    ops = {
        "Eq": ast.Eq,
        "NotEq": ast.NotEq,
        "Lt": ast.Lt,
        "LtE": ast.LtE,
        "Gt": ast.Gt,
        "GtE": ast.GtE,
        "In": ast.In,
        "NotIn": ast.NotIn,
        "Is": ast.Is,
        "IsNot": ast.IsNot,
    }
    return ops[name]()
