module pyast

pub fn parse_module_json(source string) !string {
	mut parser := new_parser(source)!
	mod := parser.parse_module()!
	return module_json(mod)
}

pub fn parse_expression_json(source string) !string {
	mut parser := new_parser(source)!
	expr := parser.parse_expr_root()!
	return expr_json(expr)
}

@[export: 'pyast_parse_module_json']
pub fn pyast_parse_module_json(source &char) &char {
	src := unsafe { cstring_to_vstring(source) }
	payload := parse_module_json(src) or { return unsafe { nil } }
	return payload.str
}

@[export: 'pyast_parse_expression_json']
pub fn pyast_parse_expression_json(source &char) &char {
	src := unsafe { cstring_to_vstring(source) }
	payload := parse_expression_json(src) or { return unsafe { nil } }
	return payload.str
}

@[export: 'pyast_last_error']
pub fn pyast_last_error() &char {
	return c'parse error'
}
