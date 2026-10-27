from __future__ import annotations

import ast as stdlib_ast
import inspect
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import spy_ast
import spy_ast.ast as ast
from spy_ast.wrapper import SpySyntaxError


# Sources inside the V parser's strict subset. These must produce trees
# identical to the standard library.
SUPPORTED_SOURCES = [
    "x = 1\n",
    "x = True\n",
    "x = False\n",
    "x = None\n",
    "x = _\n",
    "import sys\n",
    "import sys, os.path\n",
    "import numpy as np\n",
    "from os import path\n",
    "from os import path as p, getcwd\n",
    "from . import sibling\n",
    "from .pkg import mod as m\n",
    "pass\n",
    "def f():\n    pass\n",
    "def f(x, y):\n    return x + y\n",
    "class C:\n    pass\n",
    "class C(Base, mixin.Factory):\n    def f(self):\n        return self.value\n",
    "if x:\n    y = 1\nelse:\n    y = 2\n",
    "if x:\n    pass\nelif y:\n    pass\n",
    "while x:\n    break\nelse:\n    pass\n",
    "for item in items:\n    continue\nelse:\n    pass\n",
    "def f(x):\n    if not x or x < 3:\n        return x\n    return\n",
    "if __name__ == '__main__':\n    main()\n",
    "x = obj.method(1)[2].attr\n",
    "x = f(1, y + 2)\n",
    "x = -a + +b\n",
    "x = not a or b and c\n",
    "x = a < b <= c > d >= e == f != g\n",
    "print('hello')\n",
]

SUPPORTED_EXPRESSIONS = [
    "1",
    "'hello'",
    "True",
    "False",
    "None",
    "_",
    "x",
    "+x",
    "-x",
    "not x",
    "1 + 2 * 3",
    "(1 + 2) * 3",
    "a - b - c",
    "a / b",
    "a and b and c",
    "a or b or c",
    "a and not b or c",
    "a < b",
    "a <= b > c != d == e >= f",
    "f()",
    "f(1, x + 2)",
    "obj.attr",
    "items[0]",
    "obj.method(1)[2].attr",
]

# Valid Python outside the strict subset. Rejecting these is deliberate;
# parsing must fail loudly with SyntaxError, never degrade the tree.
REJECTED_SOURCES = [
    "x: int = 1\n",
    "x += 1\n",
    "x, y = y, x\n",
    "a, *b, c = items\n",
    "del items[0]\n",
    "def f(x=1):\n    pass\n",
    "def f(*args, **kwargs):\n    pass\n",
    "def f(x: int) -> int:\n    return x\n",
    "@decorator\ndef f():\n    pass\n",
    "async def f():\n    await g()\n",
    "for k, v in d.items():\n    pass\n",
    "try:\n    pass\nexcept ValueError:\n    pass\n",
    "try:\n    pass\nexcept* ValueError:\n    pass\n",
    "with open('f') as f:\n    pass\n",
    "raise ValueError('bad')\n",
    "raise\n",
    "assert x, 'must hold'\n",
    "global x\n",
    "x = lambda a: a\n",
    "x = [i * 2 for i in items]\n",
    "x = {'a': 1}\n",
    "x = [1, 2, *rest]\n",
    "x = (1, 2)\n",
    "x = items[1:2]\n",
    "x = a if b else c\n",
    "x = (yield v)\n",
    "x = yield\n",
    "x = (y := 1)\n",
    "x = f'{name}={value}'\n",
    "x = 3.14\n",
    "x = 0xFF\n",
    "x = ...\n",
    "x = a | b\n",
    "x = a % b\n",
    "x = a ** b\n",
    "x = a is b\n",
    "x = f(1, k=2)\n",
    "x = ~a\n",
    "y = 1\nx = await y\n",
]


@pytest.mark.parametrize("source", SUPPORTED_SOURCES)
def test_parse_supported_source_matches_stdlib(source: str) -> None:
    assert stdlib_ast.dump(ast.parse(source)) == stdlib_ast.dump(stdlib_ast.parse(source))


@pytest.mark.parametrize("source", SUPPORTED_EXPRESSIONS)
def test_parse_supported_expression_matches_stdlib(source: str) -> None:
    assert stdlib_ast.dump(ast.parse(source, mode="eval")) == stdlib_ast.dump(
        stdlib_ast.parse(source, mode="eval")
    )


@pytest.mark.parametrize("source", REJECTED_SOURCES)
def test_parse_rejects_unsupported_python(source: str) -> None:
    # Sanity: these really are valid Python, we just don't support them.
    stdlib_ast.parse(source)
    with pytest.raises(SpySyntaxError):
        ast.parse(source)
    with pytest.raises(SyntaxError):
        ast.parse(source)


def test_shim_exposes_full_stdlib_surface() -> None:
    missing = [name for name in dir(stdlib_ast) if not hasattr(ast, name)]
    assert missing == []
    for name in [
        "AST",
        "NodeVisitor",
        "NodeTransformer",
        "dump",
        "unparse",
        "walk",
        "fix_missing_locations",
        "iter_child_nodes",
        "iter_fields",
        "copy_location",
        "increment_lineno",
        "get_source_segment",
        "literal_eval",
        "get_docstring",
        "Constant",
        "Match",
        "match_case",
        "arg",
        "arguments",
        "alias",
    ]:
        assert getattr(ast, name) is getattr(stdlib_ast, name)


def test_parse_signature_matches_stdlib() -> None:
    assert list(inspect.signature(ast.parse).parameters) == list(
        inspect.signature(stdlib_ast.parse).parameters
    )


def test_parse_returns_stdlib_types_for_supported_source() -> None:
    tree = ast.parse("x = 1\n")
    assert type(tree) is stdlib_ast.Module
    assert isinstance(tree, stdlib_ast.AST)
    visitor_names: list[str] = []

    class Finder(stdlib_ast.NodeVisitor):
        def visit_Name(self, node: stdlib_ast.Name) -> None:
            visitor_names.append(node.id)

    Finder().visit(tree)
    assert visitor_names == ["x"]


def test_node_transformer_roundtrip() -> None:
    tree = ast.parse("x = 1\n")

    class Renamer(ast.NodeTransformer):
        def visit_Name(self, node: ast.Name) -> ast.AST:
            if node.id == "x":
                return ast.copy_location(ast.Name(id="y", ctx=node.ctx), node)
            return node

    renamed = Renamer().visit(tree)
    assert stdlib_ast.dump(renamed) == stdlib_ast.dump(stdlib_ast.parse("y = 1\n"))
    assert stdlib_ast.unparse(renamed) == stdlib_ast.unparse(stdlib_ast.parse("y = 1\n"))


def test_parse_dialect_match_expression_exec_mode() -> None:
    with pytest.raises(SyntaxError):
        stdlib_ast.parse("y = match x:\n    1: 10\n    _: 0\n")
    tree = ast.parse("y = match x:\n    1: 10\n    _: 0\n")
    assert isinstance(tree, stdlib_ast.Module)
    value = tree.body[0].value
    assert isinstance(value, stdlib_ast.Match)
    assert isinstance(value.cases[0].pattern, stdlib_ast.MatchValue)
    assert isinstance(value.cases[1].pattern, stdlib_ast.MatchAs)


def test_parse_dialect_match_expression_eval_mode() -> None:
    with pytest.raises(SyntaxError):
        stdlib_ast.parse("match x:\n    1: 1\n    _: 0\n", mode="eval")
    tree = ast.parse("match x:\n    1: 1\n    _: 0\n", mode="eval")
    assert isinstance(tree, stdlib_ast.Expression)
    assert isinstance(tree.body, stdlib_ast.Match)


def test_dialect_trees_carry_locations() -> None:
    tree = ast.parse("y = match x:\n    1: 10\n    _: 0\n")
    missing = [
        node
        for node in stdlib_ast.walk(tree)
        if "lineno" in node._attributes and not hasattr(node, "lineno")
    ]
    assert missing == []
    assert tree.body[0].lineno == 1


def test_parse_errors_raise_syntax_error() -> None:
    with pytest.raises(SpySyntaxError):
        ast.parse("def broken(:\n")
    with pytest.raises(SyntaxError):
        ast.parse("def broken(:\n")
    with pytest.raises(SyntaxError):
        ast.parse("1 + * 2\n", mode="eval")
    assert issubclass(SpySyntaxError, SyntaxError)
    assert issubclass(SpySyntaxError, ValueError)


def test_parse_error_carries_filename() -> None:
    with pytest.raises(SyntaxError) as excinfo:
        ast.parse("def broken(:\n", filename="transpile_target.py")
    assert excinfo.value.filename == "transpile_target.py"


def test_parse_accepts_bytes_and_single_mode() -> None:
    assert stdlib_ast.dump(ast.parse(b"x = 1\n")) == stdlib_ast.dump(stdlib_ast.parse(b"x = 1\n"))
    assert stdlib_ast.dump(ast.parse("x = 1\n", mode="single")) == stdlib_ast.dump(
        stdlib_ast.parse("x = 1\n", mode="single")
    )
    with pytest.raises(ValueError):
        ast.parse("x = 1\n", mode="bogus")


def test_parse_type_comments_are_ignored_but_accepted() -> None:
    tree = ast.parse("x = 1  # type: int\n", type_comments=True)
    assert isinstance(tree.body[0], stdlib_ast.Assign)
    assert tree.body[0].type_comment is None


def test_top_level_package_supports_ast_style_access() -> None:
    assert spy_ast.parse("x = 1\n").body[0].targets[0].id == "x"
    assert spy_ast.NodeVisitor is stdlib_ast.NodeVisitor
    assert spy_ast.dump is stdlib_ast.dump
    assert spy_ast.fix_missing_locations is stdlib_ast.fix_missing_locations
