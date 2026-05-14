module main

import os
import pyast

fn main() {
	args := os.args[1..]
	if args.len < 2 {
		eprintln('usage: v run cmd/pyast_parser --json <source-file> | --json-expr <source-file>')
		exit(2)
	}
	mode := args[0]
	source_path := args[1]
	source := os.read_file(source_path) or {
		eprintln('failed to read ${source_path}: ${err}')
		exit(1)
	}
	if mode == '--json' {
		payload := pyast.parse_module_json(source) or {
			eprintln('parse error: ${err}')
			exit(1)
		}
		println(payload.trim_space())
		return
	}
	if mode == '--json-expr' {
		payload := pyast.parse_expression_json(source) or {
			eprintln('parse error: ${err}')
			exit(1)
		}
		println(payload.trim_space())
		return
	}
	eprintln('unknown mode: ${mode}')
	exit(2)
}
