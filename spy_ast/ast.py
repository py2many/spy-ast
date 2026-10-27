from __future__ import annotations

"""Drop-in replacement for Python's built-in :mod:`ast` module.

Use it anywhere you would use ``import ast``::

    import spy_ast.ast as ast

    tree = ast.parse(source)

Parsing is done entirely by the ``spy-ast`` dialect parser; the standard
library parser is never consulted. The parser accepts the Python-compatible
subset plus ``match`` as an expression::

    value = match x:
        1: "one"
        _: "other"

Source outside the supported subset raises :class:`SyntaxError` instead of
producing a degraded tree.

Node classes and helpers (``dump``, ``unparse``, ``walk``,
``NodeVisitor``, ``NodeTransformer``, ``fix_missing_locations``, ...) are
the standard library objects, so trees built here are genuine ``ast`` nodes
and existing visitors, transformers, and rewriters keep working unchanged.
Dialect trees get source locations filled in uniformly.
"""

import ast as _stdlib_ast
from ast import *  # noqa: F401,F403
from typing import Any


def parse(
    source: str | bytes | bytearray,
    filename: str = "<unknown>",
    mode: str = "exec",
    *,
    type_comments: bool = False,
    feature_version: tuple[int, int] | None = None,
    optimize: int = -1,
) -> Any:
    """Parse *source* into an AST, mirroring :func:`ast.parse`.

    Python-compatible input is handled by the standard library parser and
    produces byte-identical trees. Input the standard parser rejects (the
    ``match``-as-expression dialect) falls back to the ``spy-ast`` parser.
    """
    from .wrapper import parse as _parse

    return _parse(
        source,
        filename=filename,
        mode=mode,
        type_comments=type_comments,
        feature_version=feature_version,
        optimize=optimize,
    )


def __getattr__(name: str) -> Any:
    """Delegate any name not explicitly defined here to stdlib :mod:`ast`.

    This keeps the shim complete even as the standard library gains new
    helpers or node classes.
    """
    return getattr(_stdlib_ast, name)


def __dir__() -> list[str]:
    return sorted(set(globals()) | set(dir(_stdlib_ast)))


del Any
