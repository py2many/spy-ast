module pyast_test

import pyast

fn test_parse_expression_returns_typed_ast() {
	expr := pyast.parse_expression('match x:
    0: 10
    name: name
    _: 99
')!
	match expr {
		pyast.MatchExpr {
			assert expr.cases.len == 3
			assert expr.cases[0].pattern is pyast.ValuePattern
			assert expr.cases[1].pattern is pyast.BindPattern
			assert expr.cases[2].pattern is pyast.WildcardPattern
		}
		else {
			assert false
		}
	}
}

fn test_parse_module_returns_typed_ast() {
	mod := pyast.parse_module('x = 1
print(x)
')!
	assert mod.body.len == 2
	assert mod.body[0] is pyast.AssignStmt
	assert mod.body[1] is pyast.ExprStmt
}
