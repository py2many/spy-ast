from __future__ import annotations

from typing import Any

from . import ast
from .wrapper import SpySyntaxError, parse, parse_expression, parse_module

__all__ = ["ast", "parse", "parse_expression", "parse_module", "SpySyntaxError"]


def __getattr__(name: str) -> Any:
    """Allow ``import spy_ast as ast`` style usage.

    Any attribute not defined at the top level (node classes, ``dump``,
    ``unparse``, ``walk``, ``NodeVisitor``, ...) resolves to the matching
    member of :mod:`spy_ast.ast`, which itself mirrors stdlib :mod:`ast`.
    """
    return getattr(ast, name)
