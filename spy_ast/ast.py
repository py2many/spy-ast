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
import inspect as _inspect
from ast import *  # noqa: F401,F403
from typing import Any


def _parse_forward(
    source: str | bytes | bytearray,
    filename: str,
    mode: str,
    type_comments: bool,
    feature_version: tuple[int, int] | None,
    optimize: int,
) -> Any:
    from .wrapper import parse as _parse

    return _parse(
        source,
        filename=filename,
        mode=mode,
        type_comments=type_comments,
        feature_version=feature_version,
        optimize=optimize,
    )


if "optimize" in _inspect.signature(_stdlib_ast.parse).parameters:

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

        Parsing is done entirely by the ``spy-ast`` dialect parser; the
        standard library parser is never consulted.
        """
        return _parse_forward(source, filename, mode, type_comments, feature_version, optimize)

else:

    def parse(
        source: str | bytes | bytearray,
        filename: str = "<unknown>",
        mode: str = "exec",
        *,
        type_comments: bool = False,
        feature_version: tuple[int, int] | None = None,
    ) -> Any:
        """Parse *source* into an AST, mirroring :func:`ast.parse`.

        Parsing is done entirely by the ``spy-ast`` dialect parser; the
        standard library parser is never consulted.
        """
        return _parse_forward(source, filename, mode, type_comments, feature_version, -1)


def __getattr__(name: str) -> Any:
    """Delegate any name not explicitly defined here to stdlib :mod:`ast`.

    This keeps the shim complete even as the standard library gains new
    helpers or node classes.
    """
    return getattr(_stdlib_ast, name)


def __dir__() -> list[str]:
    return sorted(set(globals()) | set(dir(_stdlib_ast)))


del Any
