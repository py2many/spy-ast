from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from spy_ast import ast, parse_expression, parse_module


def test_parse_arithmetic() -> None:
    parsed = parse_expression("1 + 2 * 3")
    assert isinstance(parsed.body, ast.BinOp)


def test_parse_match_expression_and_dump() -> None:
    source = "match x:\n    0: 10\n    y: y + 1\n    _: 99\n"
    parsed = parse_expression(source)
    assert isinstance(parsed.body, ast.Match)
    dumped = ast.dump(parsed)
    assert "Match(subject=Name(id='x', ctx=Load())" in dumped
    assert "match_case(pattern=MatchValue(value=Constant(value=0))" in dumped


def test_parse_module_import_and_call() -> None:
    source = 'import sys\nprint("hello")\n'
    parsed = parse_module(source)
    assert isinstance(parsed, ast.Module)
    assert len(parsed.body) == 2
    assert isinstance(parsed.body[0], ast.Import)
    assert parsed.body[0].names[0].name == "sys"

    call_expr = parsed.body[1]
    assert isinstance(call_expr, ast.Expr)
    call = call_expr.value
    assert isinstance(call, ast.Call)
    assert isinstance(call.func, ast.Name)
    assert call.func.id == "print"
    assert len(call.args) == 1
    assert isinstance(call.args[0], ast.Constant)
    assert call.args[0].value == "hello"


def test_control_flow_defs_and_expr_features() -> None:
    source = (
        "class C(Base):\n"
        "    def f(x, y):\n"
        "        if not x or y < 3:\n"
        "            return x.attr[0] + y\n"
        "        else:\n"
        "            while x:\n"
        "                for i in y:\n"
        "                    continue\n"
        "                break\n"
        "            return\n"
    )
    parsed = parse_module(source)
    dumped = ast.dump(parsed)
    assert "ClassDef(name='C'" in dumped
    assert "FunctionDef(name='f', args=arguments(" in dumped
    assert "arg(arg='x')" in dumped
    assert "arg(arg='y')" in dumped
    assert "If(test=BoolOp(op=Or()" in dumped
    assert "UnaryOp(op=Not()" in dumped
    assert "Compare(left=Name(id='y', ctx=Load()), ops=[Lt()]" in dumped
    assert (
        "Subscript(value=Attribute(value=Name(id='x', ctx=Load()), attr='attr', ctx=Load()), "
        "slice=Constant(value=0), ctx=Load())" in dumped
    )
    assert "While(test=Name(id='x', ctx=Load())" in dumped
    assert "For(target=Name(id='i', ctx=Store()), iter=Name(id='y'" in dumped
    assert "Continue()" in dumped
    assert "Break()" in dumped
    assert "Return()" in dumped


def test_indentation_based_match_expression() -> None:
    source = (
        "x = 2\n"
        "y = match x:\n"
        "    1: 10\n"
        "    _: 0\n"
        "print(y)\n"
    )
    parsed = parse_module(source)
    dumped = ast.dump(parsed)
    assert "Assign(targets=[Name(id='y', ctx=Store())], value=Match(subject=Name(id='x', ctx=Load())" in dumped
    assert "MatchAs()" in dumped


def test_old_python_match_statement_syntax_is_rejected() -> None:
    with pytest.raises(ValueError):
        parse_expression("match x: case 1: 2")


def test_arrow_style_match_is_rejected() -> None:
    with pytest.raises(ValueError):
        parse_expression("match x { 1 => 10, _ => 0 }")


def test_brace_style_match_is_rejected() -> None:
    with pytest.raises(ValueError):
        parse_expression("match x { 1: 10, _: 0 }")


def test_full_python_module_is_rejected() -> None:
    # jpeg_parser.py uses full Python (decorators, annotations, keyword
    # arguments, ...), which is outside the V parser's strict subset.
    # Rejection is deliberate: spy-ast never falls back to builtin ast, so
    # unsupported input fails loudly instead of degrading the tree.
    import spy_ast
    from spy_ast.wrapper import SpySyntaxError

    source = Path(__file__).resolve().parents[1] / "examples" / "jpeg_parser.py"
    with pytest.raises(SpySyntaxError):
        spy_ast.parse(source.read_text())


def test_v_parser_rejects_unsupported_statements() -> None:
    # The V parser is strict: anything outside its subset is an error rather
    # than a silently degraded tree.
    # The V parser is strict: anything outside its subset is an error rather
    # than a silently degraded tree. Each source below is either invalid
    # Python or a deliberately unsupported construct.
    for source in [
        "x = 1j\n",
        "x = f'{v:{w}}'\n",
        "type u8 = int\n",
        "match x:\n    case 1:\n        pass\n",
    ]:
        with pytest.raises(ValueError):
            parse_module(source)


def test_parse_nested_match_variant_module() -> None:
    source = Path(__file__).resolve().parents[1] / "examples" / "nested_match.py"
    parsed = parse_module(source.read_text())
    dumped = ast.dump(parsed)
    assert dumped.count("Match(subject=") >= 3


def test_parenthesized_match_expression() -> None:
    source = (
        "def f(x: int) -> str:\n"
        "    return (match x:\n"
        '        1: "a"\n'
        '        _: "b"\n'
        "    )\n"
    )
    parsed = parse_module(source)
    dumped = ast.dump(parsed)
    assert "Match(subject=Name(id='x', ctx=Load())" in dumped
    assert "match_case(pattern=MatchValue(value=Constant(value=1))" in dumped
    assert "MatchAs()" in dumped


def test_parenthesized_match_closing_paren_alignments() -> None:
    # `)` on the last body line and on its own line at the arm indent
    # both terminate the match.
    for tail in (')\n', '\n        )\n'):
        source = (
            "def f(x: int) -> str:\n"
            "    return (match x:\n"
            '        1: "a"\n'
            f'        _: "b"{tail}'
        )
        parsed = parse_module(source)
        assert isinstance(parsed.body[0].body[0].value, ast.Match)


def test_parenthesized_match_nested() -> None:
    source = (
        "def f(a: int, b: int) -> str:\n"
        "    return (match a:\n"
        "        1: (match b:\n"
        '            2: "x"\n'
        '            _: "y")\n'
        '        _: "z")\n'
    )
    parsed = parse_module(source)
    dumped = ast.dump(parsed)
    assert dumped.count("Match(subject=") == 2


def test_parenthesized_match_subject() -> None:
    source = (
        "x = match (match y:\n"
        "        1: 2\n"
        "        _: 3):\n"
        "    4: 5\n"
        "    _: 6\n"
    )
    parsed = parse_module(source)
    dumped = ast.dump(parsed)
    assert dumped.count("Match(subject=") == 2


def test_match_subject_must_be_parenthesized() -> None:
    # `match match x: ... :` cannot work: closing the inner match requires a
    # dedent, which cannot land on a fresh (outer arm) indent level.
    with pytest.raises(ValueError):
        parse_module("x = match match y:\n    1: 2\n    _: 3:\n    4: 5\n    _: 6\n")


def test_match_statement_desugars_to_if() -> None:
    source = "def f(x):\n    match x:\n        1: return 10\n        _: return 20\n"
    parsed = parse_module(source)
    (stmt,) = parsed.body[0].body
    assert isinstance(stmt, ast.If)
    assert isinstance(stmt.test, ast.Compare)
    assert isinstance(stmt.test.ops[0], ast.Eq)
    assert isinstance(stmt.body[0], ast.Return)
    (orelse,) = stmt.orelse
    assert isinstance(orelse, ast.Return)


def test_match_statement_multi_statement_arms() -> None:
    source = (
        "def f(x):\n"
        "    y = 0\n"
        "    match x:\n"
        "        1: y = 10\n"
        "        _: y = 20\n"
        "    return y\n"
    )
    parsed = parse_module(source)
    Franz = parsed.body[0].body[1]
    assert isinstance(Franz, ast.If)
    assert isinstance(Franz.body[0], ast.Assign)


def test_match_statement_missing_wildcard_falls_through() -> None:
    source = "def f(x):\n    match x:\n        1: print(1)\n"
    parsed = parse_module(source)
    (stmt,) = parsed.body[0].body
    assert isinstance(stmt, ast.If)
    assert stmt.orelse == []


def test_match_statement_complex_subject_uses_walrus() -> None:
    source = (
        "def f(x):\n"
        "    match f(x):\n"
        "        1: print(1)\n"
        "        2: print(2)\n"
        "        _: print(3)\n"
    )
    parsed = parse_module(source)
    (stmt,) = parsed.body[0].body
    assert isinstance(stmt, ast.If)
    assert isinstance(stmt.test.left, ast.NamedExpr)
    assert stmt.test.left.target.id == "__spy_match_0"
    dumped = ast.dump(parsed)
    # Bound once (walrus target) + read once per remaining int arm.
    assert dumped.count("__spy_match_0") == 2


def test_match_statement_rejects_captures() -> None:
    with pytest.raises(ValueError, match="capture patterns"):
        parse_module("def f(x):\n    match x:\n        y: print(1)\n")


def test_match_statement_rejects_duplicate_wildcard() -> None:
    with pytest.raises(ValueError, match="duplicate"):
        parse_module("def f(x):\n    match x:\n        _: print(1)\n        _: print(2)\n")


def test_match_statement_rejects_arm_after_wildcard() -> None:
    with pytest.raises(ValueError, match="unreachable"):
        parse_module("def f(x):\n    match x:\n        _: print(1)\n        1: print(2)\n")


def test_match_statement_rejects_wildcard_only() -> None:
    with pytest.raises(ValueError, match="int-literal"):
        parse_module("def f(x):\n    match x:\n        _: print(1)\n")


def test_match_soft_keyword_still_usable() -> None:
    parsed = parse_module("match = 5\nprint(match)\n")
    assert isinstance(parsed.body[0], ast.Assign)
    parsed = parse_module("print(match(1))\n")
    assert isinstance(parsed.body[0].value.args[0], ast.Call)


def test_match_statement_nests() -> None:
    source = (
        "def f(x):\n"
        "    match x:\n"
        "        1:\n"
        "            match x:\n"
        "                1: return 1\n"
        "                _: return 2\n"
        "        _: return 0\n"
    )
    parsed = parse_module(source)
    (outer,) = parsed.body[0].body
    assert isinstance(outer, ast.If)
    (inner,) = outer.body
    assert isinstance(inner, ast.If)


def test_if_after_match_expression_is_a_statement() -> None:
    # Regression test: the `if` below used to be misread as a conditional
    # expression over the match (`expected kw_else, found colon`).
    source = (
        "def f(code):\n"
        "    kind = match code:\n"
        "        43: 1\n"
        "        _: -1\n"
        "    if kind == 1:\n"
        "        return 1\n"
        "    return kind\n"
    )
    parsed = parse_module(source)
    entry, *rest = parsed.body[0].body
    assert isinstance(entry.value, ast.Match)
    assert isinstance(rest[0], ast.If)


def test_match_expression_in_call_args() -> None:
    parsed = parse_module(
        "def f(y):\n    return str(match y:\n        1: 10\n        _: 20)\n"
    )
    call = parsed.body[0].body[0].value
    assert isinstance(call, ast.Call)
    assert isinstance(call.args[0], ast.Match)


def test_match_expression_in_call_args_with_sibling() -> None:
    parsed = parse_module(
        "def f(y):\n    return str(match y:\n        1: 10\n        _: 20, y)\n"
    )
    call = parsed.body[0].body[0].value
    assert isinstance(call.args[0], ast.Match)
    assert isinstance(call.args[1], ast.Name)


def test_match_expression_in_list_display() -> None:
    parsed = parse_module("x = [match y:\n    1: 10\n    _: 20]\n")
    (elt,) = parsed.body[0].value.elts
    assert isinstance(elt, ast.Match)


def test_match_expression_in_dict_and_subscript() -> None:
    parsed = parse_module('x = {"k": match y:\n    1: 10\n    _: 20}\n')
    assert isinstance(parsed.body[0].value.values[0], ast.Match)
    parsed = parse_module("x = a[match y:\n    1: 0\n    _: 1]\n")
    assert isinstance(parsed.body[0].value.slice, ast.Match)


def test_match_expression_in_while_test() -> None:
    parsed = parse_module(
        "def f(y):\n    while (match y:\n        1: True\n        _: False\n    ):\n        print(1)\n"
    )
    assert isinstance(parsed.body[0].body[0].test, ast.Match)


def test_sealed_token_and_expr() -> None:
    # Sum types with payloads, mirroring Bend2 `type X is Data`
    # definitions: variants act as tags, so there are no parallel int
    # constants and no matches on them. Recursive pairs go inline with
    # typing.Tuple (a BinOp-style wrapper is obsolete too).
    source = (
        "from adt import adt as sealed\n"
        "from typing import Tuple\n"
        "\n"
        "@sealed\n"
        "class Token:\n"
        "    NUM: float\n"
        "    PLUS: None\n"
        "    MINUS: None\n"
        "    SKIP: None\n"
        "\n"
        "@sealed\n"
        "class Expr:\n"
        "    NUMBER: float\n"
        "    VARIABLE: str\n"
        "    ADD: Tuple[\"Expr\", \"Expr\"]\n"
        "    DIVIDE: Tuple[\"Expr\", \"Expr\"]\n"
        "\n"
        "def is_op(tok: Token) -> bool:\n"
        "    if tok.is_plus():\n"
        "        return True\n"
        "    if tok.is_minus():\n"
        "        return True\n"
        "    return False\n"
        "\n"
        "def eval_number(e: Expr):\n"
        "    if e.is_number():\n"
        "        return e.number()\n"
        "    return 0.0\n"
        "\n"
        "def eval_add(e: Expr):\n"
        "    if e.is_add():\n"
        "        pair = e.add()\n"
        "        return eval_number(pair[0]) + eval_number(pair[1])\n"
        "    return 0.0\n"
        "\n"
        'if __name__ == "__main__":\n'
        "    print(is_op(Token.PLUS()))\n"
        "    print(eval_number(Expr.NUMBER(2.0)))\n"
        "    print(eval_add(Expr.ADD(Expr.NUMBER(2.0), Expr.NUMBER(3.0))))\n"
    )
    parsed = parse_module(source)
    classes = {
        node.name: node
        for node in parsed.body
        if isinstance(node, ast.ClassDef)
    }
    assert set(classes) == {"Token", "Expr"}

    def decorator_ids(node: ast.ClassDef) -> list:
        return [getattr(d, "id", None) for d in node.decorator_list]

    assert decorator_ids(classes["Token"]) == ["sealed"]
    assert decorator_ids(classes["Expr"]) == ["sealed"]

    def annotations(node: ast.ClassDef) -> dict:
        found = {}
        for stmt in node.body:
            if isinstance(stmt, ast.AnnAssign) and isinstance(stmt.target, ast.Name):
                found[stmt.target.id] = stmt.annotation
        return found

    token_anns = annotations(classes["Token"])
    assert getattr(token_anns["NUM"], "id", None) == "float"
    assert all(token_anns[k] is None or getattr(token_anns[k], "value", None) is None
               for k in ("PLUS", "MINUS", "SKIP"))
    expr_anns = annotations(classes["Expr"])
    assert getattr(expr_anns["NUMBER"], "id", None) == "float"
    assert getattr(expr_anns["VARIABLE"], "id", None) == "str"
    for variant in ("ADD", "DIVIDE"):
        ann = expr_anns[variant]
        assert isinstance(ann, ast.Subscript)
        assert ann.value.id == "Tuple"

    dumped = ast.dump(parsed)
    # No matches and no int tags anywhere: dispatch is is_* checks.
    assert "Match(subject=" not in dumped
    assert "MatchValue" not in dumped
    # Nullary + payload construction, is_* checks, tuple indexing.
    assert "attr='PLUS'" in dumped
    assert "attr='NUMBER'" in dumped
    assert "is_plus" in dumped and "is_add" in dumped
    assert "pair" in dumped


def test_parse_match_expr_fixture() -> None:
    # Pinned copy of py2many's tests/cases/match_expr.py: the
    # match-as-expression dialect fixture (lexer + shunting-yard parser
    # + match-based evaluator over sealed Token/Expr, no int op codes).
    source = Path(__file__).resolve().parents[1] / "examples" / "match_expr.py"
    parsed = parse_module(source.read_text())
    dumped = ast.dump(parsed)
    assert dumped.count("Match(subject=") == 6
    # Variant patterns (Token.PLUS(), Expr.ADD(l, r)) as MatchClass.
    assert dumped.count("MatchClass") == 18
    assert "MatchAs()" in dumped
