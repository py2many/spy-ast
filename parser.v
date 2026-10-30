module pyast

import strconv

enum TokenKind {
	eof
	newline
	indent
	dedent
	ident
	int_lit
	float_lit
	string_lit
	bytes_lit
	ellipsis
	kw_true
	kw_false
	kw_none
	kw_match
	kw_import
	kw_from
	kw_as
	kw_if
	kw_else
	kw_elif
	kw_pass
	kw_for
	kw_in
	kw_is
	kw_while
	kw_break
	kw_continue
	kw_return
	kw_def
	kw_class
	kw_and
	kw_or
	kw_not
	kw_assert
	kw_del
	kw_raise
	kw_try
	kw_except
	kw_finally
	kw_with
	kw_lambda
	kw_yield
	kw_await
	kw_async
	kw_global
	kw_nonlocal
	underscore
	lparen
	rparen
	lbrace
	rbrace
	lbracket
	rbracket
	plus
	minus
	star
	slash
	percent
	pow
	floordiv
	lshift
	rshift
	amp
	pipe
	caret
	tilde
	at_sign
	assign
	colon_assign
	arrow
	comma
	dot
	colon
	semicolon
	lt
	gt
	le
	ge
	eqeq
	noteq
	fstr_start
	fstr_text
	fstr_field_open
	fstr_field_close
	fstr_bang
	fstr_spec
	fstr_end
}

struct Token {
mut:
	kind     TokenKind
	text     string
	line     int
	col      int
	end_line int
	end_col  int
}

pub type Expr = AttributeExpr
	| AwaitExpr
	| BinaryExpr
	| BoolExpr
	| BoolOpExpr
	| BytesExpr
	| CallExpr
	| CompareExpr
	| DictCompExpr
	| DictExpr
	| EllipsisExpr
	| FloatExpr
	| FormattedValueExpr
	| GeneratorExpExpr
	| IfExpExpr
	| IntExpr
	| JoinedStrExpr
	| LambdaExpr
	| ListCompExpr
	| ListExpr
	| MatchExpr
	| NameExpr
	| NamedExpr
	| NoneExpr
	| SetCompExpr
	| SetExpr
	| SliceExpr
	| StarredExpr
	| StringExpr
	| SubscriptExpr
	| TupleExpr
	| UnaryExpr
	| YieldExpr
	| YieldFromExpr

pub type Pattern = BindPattern | ValuePattern | WildcardPattern

pub type Stmt = AnnAssignStmt
	| AssertStmt
	| AssignStmt
	| AugAssignStmt
	| BreakStmt
	| ClassDefStmt
	| ContinueStmt
	| DeleteStmt
	| ExprStmt
	| ForStmt
	| FunctionDefStmt
	| GlobalStmt
	| IfStmt
	| ImportStmt
	| ImportFromStmt
	| NonlocalStmt
	| PassStmt
	| RaiseStmt
	| ReturnStmt
	| TryStmt
	| WhileStmt
	| WithStmt

pub struct IntExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value int
}

// FloatExpr carries the normalized source lexeme so the exact spelling
// round-trips through JSON without binary float formatting issues.
pub struct FloatExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	text string
}

pub struct StringExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value string
}

pub struct BytesExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value string
}

pub struct BoolExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value bool
}

pub struct NoneExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
}

pub struct EllipsisExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
}

pub struct ListExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	elts []Expr
}

pub struct TupleExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	elts []Expr
}

pub struct SetExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	elts []Expr
}

pub struct DictExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	keys   []?Expr
	values []Expr
}

pub struct StarredExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value Expr
}

pub struct SliceExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	lower ?Expr
	upper ?Expr
	step  ?Expr
}

pub struct IfExpExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	test   Expr
	body   Expr
	orelse Expr
}

pub struct NamedExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	target string
	value  Expr
}

pub struct LambdaExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	args FunctionArgs
	body Expr
}

pub struct YieldExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value ?Expr
}

pub struct YieldFromExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value Expr
}

pub struct AwaitExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value Expr
}

pub struct ComprehensionClause {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	target   Expr
	iter     Expr
	ifs      []Expr
	is_async bool
}

pub struct ListCompExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	elt        Expr
	generators []ComprehensionClause
}

pub struct SetCompExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	elt        Expr
	generators []ComprehensionClause
}

pub struct GeneratorExpExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	elt        Expr
	generators []ComprehensionClause
}

pub struct DictCompExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	key        Expr
	value      Expr
	generators []ComprehensionClause
}

pub struct FormattedValueExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value      Expr
	conversion int
	format_spec ?Expr
}

pub struct JoinedStrExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	values []Expr
}

pub struct NameExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	name string
}

pub struct CallKeyword {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	name  ?string
	value Expr
}

pub struct CallExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	func     Expr
	args     []Expr
	keywords []CallKeyword
}

pub struct AttributeExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value Expr
	attr  string
}

pub struct SubscriptExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value Expr
	slice Expr
}

pub struct UnaryExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	op      string
	operand Expr
}

pub struct BinaryExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	left  Expr
	op    string
	right Expr
}

pub struct BoolOpExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	op     string
	values []Expr
}

pub struct CompareExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	left        Expr
	ops         []string
	comparators []Expr
}

pub struct MatchCase {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	pattern Pattern
	body    Expr
}

pub struct MatchExpr {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	subject Expr
	cases   []MatchCase
}

pub struct ValuePattern {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value int
}

pub struct BindPattern {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	name string
}

pub struct WildcardPattern {
pub:
	line     int
	col      int
	end_line int
	end_col  int
}

pub struct ExprStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value Expr
}

pub struct AssignStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	targets []Expr
	value   Expr
}

pub struct AugAssignStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	target Expr
	op     string
	value  Expr
}

pub struct AnnAssignStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	target     Expr
	annotation Expr
	value      ?Expr
	simple      bool
}

pub struct PassStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
}

pub struct BreakStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
}

pub struct ContinueStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
}

pub struct ReturnStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	value ?Expr
}

pub struct IfStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	test   Expr
	body   []Stmt
	orelse []Stmt
}

pub struct WhileStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	test   Expr
	body   []Stmt
	orelse []Stmt
}

pub struct ForStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	target   Expr
	iter     Expr
	body     []Stmt
	orelse   []Stmt
	is_async bool
}

pub struct FunctionArg {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	name       string
	annotation ?Expr
}

pub struct FunctionArgs {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	posonlyargs []FunctionArg
	args        []FunctionArg
	vararg      ?FunctionArg
	kwonlyargs  []FunctionArg
	kw_defaults []?Expr
	kwarg       ?FunctionArg
	defaults    []Expr
}

pub struct FunctionDefStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	name           string
	args           FunctionArgs
	body           []Stmt
	decorator_list []Expr
	returns        ?Expr
	is_async       bool
}

pub struct ClassDefStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	name           string
	bases          []Expr
	keywords       []CallKeyword
	body           []Stmt
	decorator_list []Expr
}

pub struct AssertStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	test Expr
	msg  ?Expr
}

pub struct DeleteStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	targets []Expr
}

pub struct RaiseStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	exc   ?Expr
	cause ?Expr
}

pub struct ExceptHandler {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	typ  ?Expr
	name string
	body []Stmt
}

pub struct TryStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	body      []Stmt
	handlers  []ExceptHandler
	orelse    []Stmt
	finalbody []Stmt
	is_star   bool
}

pub struct WithItem {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	context_expr Expr
	vars         ?Expr
}

pub struct WithStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	items    []WithItem
	body     []Stmt
	is_async bool
}

pub struct GlobalStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	names []string
}

pub struct NonlocalStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	names []string
}

pub struct ImportAlias {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	name   string
	asname string
}

pub struct ImportStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	names []ImportAlias
}

pub struct ImportFromStmt {
pub:
	line     int
	col      int
	end_line int
	end_col  int
	module string
	level  int
	names  []ImportAlias
}

pub struct Module {
pub:
	body []Stmt
}

struct Lexer {
	source string
mut:
	pos           int
	at_line_start bool   = true
	indent_stack  []int  = [0]
	pending       []Token
	brace_depth   int
	line_starts   []int
	tok_start     int
}

// lookup_pos maps a byte offset to a 1-based line and 0-based column.
// The line table is built lazily on first use.
fn (mut l Lexer) lookup_pos(pos int) (int, int) {
	if l.line_starts.len == 0 {
		l.line_starts << 0
		for i := 0; i < l.source.len; i++ {
			if l.source[i] == `\n` {
				l.line_starts << i + 1
			}
		}
	}
	mut line := 1
	mut lo := 0
	mut hi := l.line_starts.len - 1
	for lo <= hi {
		mid := (lo + hi) / 2
		if l.line_starts[mid] <= pos {
			line = mid + 1
			lo = mid + 1
		} else {
			hi = mid - 1
		}
	}
	line_start := l.line_starts[line - 1]
	mut col := pos - line_start
	if col < 0 {
		col = 0
	}
	return line, col
}

fn (mut l Lexer) stamp(mut tok Token, start int, end int) Token {
	tok.line, tok.col = l.lookup_pos(start)
	tok.end_line, tok.end_col = l.lookup_pos(end)
	return tok
}

fn (mut l Lexer) next_token() !Token {
	if l.pending.len > 0 {
		tok := l.pending[0]
		l.pending = l.pending[1..]
		return tok
	}
	l.tok_start = l.pos
	mut tok := l.next_token_inner()!
	return l.stamp(mut tok, l.tok_start, l.pos)
}

fn (mut l Lexer) next_token_inner() !Token {
	for {
		if l.pending.len > 0 {
			tok := l.pending[0]
			l.pending = l.pending[1..]
			return tok
		}
		if l.pos >= l.source.len {
			// An unterminated final line still ends the last statement:
			// synthesize the newline CPython would emit before DEDENTs.
			if !l.at_line_start && l.brace_depth == 0 {
				l.at_line_start = true
				return Token{
					kind: .newline
					text: '\n'
				}
			}
			if l.indent_stack.len > 1 {
				l.indent_stack = l.indent_stack[..l.indent_stack.len - 1]
				return Token{
					kind: .dedent
					text: ''
				}
			}
			return Token{
				kind: .eof
				text: ''
			}
		}
		if l.at_line_start && l.brace_depth == 0 {
			l.handle_indentation()!
			if l.pending.len > 0 {
				continue
			}
			if l.pos >= l.source.len {
				continue
			}
		}
		l.skip_inline_ws()
		if l.pos >= l.source.len {
			continue
		}
		l.tok_start = l.pos
		ch := l.source[l.pos]
		if ch == `#` {
			l.skip_comment()
			continue
		}
		if ch == `\n` {
			l.pos++
			if l.brace_depth > 0 {
				continue
			}
			l.at_line_start = true
			return Token{
				kind: .newline
				text: '\n'
			}
		}
		l.at_line_start = false

		if is_alpha(ch) {
			start := l.pos
			l.pos++
			for l.pos < l.source.len && is_alnum(l.source[l.pos]) {
				l.pos++
			}
			text := l.source[start..l.pos]
			if string_prefix_kind(text) != 0
				&& l.pos < l.source.len
				&& (l.source[l.pos] == `"` || l.source[l.pos] == `'`) {
				return l.lex_prefixed_string(text)!
			}
			return keyword_or_ident(text)
		}
		if is_digit(ch) {
			return l.lex_number()!
		}
		if ch == `"` || ch == `'` {
			text := l.read_string_literal(ch)!
			return Token{
				kind: .string_lit
				text: text
			}
		}
		if ch == `.` {
			if l.pos + 2 < l.source.len && l.source[l.pos + 1] == `.`
				&& l.source[l.pos + 2] == `.` {
				l.pos += 3
				return Token{
					kind: .ellipsis
					text: '...'
				}
			}
			if l.pos + 1 < l.source.len && is_digit(l.source[l.pos + 1]) {
				return l.lex_number()!
			}
			l.pos++
			return Token{
				kind: .dot
				text: '.'
			}
		}

		l.pos++
		return match ch {
			`(` {
				l.brace_depth++
				Token{
					kind: .lparen
					text: '('
				}
			}
			`)` {
				if l.brace_depth > 0 {
					l.brace_depth--
				}
				Token{
					kind: .rparen
					text: ')'
				}
			}
			`{` {
				l.brace_depth++
				Token{
					kind: .lbrace
					text: '{'
				}
			}
			`}` {
				if l.brace_depth > 0 {
					l.brace_depth--
				}
				Token{
					kind: .rbrace
					text: '}'
				}
			}
			`[` {
				l.brace_depth++
				Token{
					kind: .lbracket
					text: '['
				}
			}
			`]` {
				if l.brace_depth > 0 {
					l.brace_depth--
				}
				Token{
					kind: .rbracket
					text: ']'
				}
			}
			`+` {
				Token{
					kind: .plus
					text: '+'
				}
			}
			`-` {
				if l.pos < l.source.len && l.source[l.pos] == `>` {
					l.pos++
					Token{
						kind: .arrow
						text: '->'
					}
				} else {
					Token{
						kind: .minus
						text: '-'
					}
				}
			}
			`*` {
				if l.pos < l.source.len && l.source[l.pos] == `*` {
					l.pos++
				Token{
					kind: .pow
					text: '**'
				}
				} else {
					Token{
						kind: .star
						text: '*'
					}
				}
			}
			`/` {
				if l.pos < l.source.len && l.source[l.pos] == `/` {
					l.pos++
				Token{
					kind: .floordiv
					text: '//'
				}
				} else {
					Token{
						kind: .slash
						text: '/'
					}
				}
			}
			`%` {
				Token{
					kind: .percent
					text: '%'
				}
			}
			`&` {
				Token{
					kind: .amp
					text: '&'
				}
			}
			`^` {
				Token{
					kind: .caret
					text: '^'
				}
			}
			`~` {
				Token{
					kind: .tilde
					text: '~'
				}
			}
			`,` {
				Token{
					kind: .comma
					text: ','
				}
			}
			`;` {
				Token{
					kind: .semicolon
					text: ';'
				}
			}
			// NOTE: `.` is lexed in next_token before this match (ellipsis,
			// leading-dot floats, attribute dots).
			`:` {
				if l.pos < l.source.len && l.source[l.pos] == `=` {
					l.pos++
					Token{
						kind: .colon_assign
						text: ':='
					}
					} else {
						Token{
							kind: .colon
							text: ':'
						}
					}
			}
			`|` {
				Token{
					kind: .pipe
					text: '|'
				}
			}
			`@` {
				Token{
					kind: .at_sign
					text: '@'
				}
			}
			`<` {
				if l.pos < l.source.len && l.source[l.pos] == `<` {
					l.pos++
					Token{
						kind: .lshift
						text: '<<'
					}
					} else if l.pos < l.source.len && l.source[l.pos] == `=` {
						l.pos++
						Token{
							kind: .le
							text: '<='
						}
						} else {
							Token{
								kind: .lt
								text: '<'
							}
						}
			}
			`>` {
				if l.pos < l.source.len && l.source[l.pos] == `>` {
					l.pos++
					Token{
						kind: .rshift
						text: '>>'
					}
					} else if l.pos < l.source.len && l.source[l.pos] == `=` {
							l.pos++
							Token{
								kind: .ge
								text: '>='
							}
							} else {
								Token{
									kind: .gt
									text: '>'
								}
							}
			}
			`!` {
				if l.pos < l.source.len && l.source[l.pos] == `=` {
					l.pos++
					Token{
						kind: .noteq
						text: '!='
					}
				} else {
					return error('unexpected token "!"')
				}
			}
			`=` {
				if l.pos < l.source.len && l.source[l.pos] == `=` {
					l.pos++
					Token{
						kind: .eqeq
						text: '=='
					}
				} else {
					Token{
						kind: .assign
						text: '='
					}
				}
			}
			else {
				return error('unexpected token "${rune(ch)}"')
			}
		}
	}
	return error('unreachable lexer state')
}

fn keyword_or_ident(text string) Token {
	return match text {
		'True' {
			Token{
				kind: .kw_true
				text: text
			}
		}
		'False' {
			Token{
				kind: .kw_false
				text: text
			}
		}
		'None' {
			Token{
				kind: .kw_none
				text: text
			}
		}
		'match' {
			Token{
				kind: .kw_match
				text: text
			}
		}
		'import' {
			Token{
				kind: .kw_import
				text: text
			}
		}
		'from' {
			Token{
				kind: .kw_from
				text: text
			}
		}
		'as' {
			Token{
				kind: .kw_as
				text: text
			}
		}
		'if' {
			Token{
				kind: .kw_if
				text: text
			}
		}
		'else' {
			Token{
				kind: .kw_else
				text: text
			}
		}
		'elif' {
			Token{
				kind: .kw_elif
				text: text
			}
		}
		'pass' {
			Token{
				kind: .kw_pass
				text: text
			}
		}
		'for' {
			Token{
				kind: .kw_for
				text: text
			}
		}
		'in' {
			Token{
				kind: .kw_in
				text: text
			}
		}
		'while' {
			Token{
				kind: .kw_while
				text: text
			}
		}
		'break' {
			Token{
				kind: .kw_break
				text: text
			}
		}
		'continue' {
			Token{
				kind: .kw_continue
				text: text
			}
		}
		'return' {
			Token{
				kind: .kw_return
				text: text
			}
		}
		'def' {
			Token{
				kind: .kw_def
				text: text
			}
		}
		'class' {
			Token{
				kind: .kw_class
				text: text
			}
		}
		'and' {
			Token{
				kind: .kw_and
				text: text
			}
		}
		'or' {
			Token{
				kind: .kw_or
				text: text
			}
		}
		'is' {
			Token{
				kind: .kw_is
				text: text
			}
		}
		'assert' {
			Token{
				kind: .kw_assert
				text: text
			}
		}
		'del' {
			Token{
				kind: .kw_del
				text: text
			}
		}
		'raise' {
			Token{
				kind: .kw_raise
				text: text
			}
		}
		'try' {
			Token{
				kind: .kw_try
				text: text
			}
		}
		'except' {
			Token{
				kind: .kw_except
				text: text
			}
		}
		'finally' {
			Token{
				kind: .kw_finally
				text: text
			}
		}
		'with' {
			Token{
				kind: .kw_with
				text: text
			}
		}
		'lambda' {
			Token{
				kind: .kw_lambda
				text: text
			}
		}
		'yield' {
			Token{
				kind: .kw_yield
				text: text
			}
		}
		'await' {
			Token{
				kind: .kw_await
				text: text
			}
		}
		'async' {
			Token{
				kind: .kw_async
				text: text
			}
		}
		'global' {
			Token{
				kind: .kw_global
				text: text
			}
		}
		'nonlocal' {
			Token{
				kind: .kw_nonlocal
				text: text
			}
		}
		'not' {
			Token{
				kind: .kw_not
				text: text
			}
		}
		'_' {
			Token{
				kind: .underscore
				text: text
			}
		}
		else {
			Token{
				kind: .ident
				text: text
			}
		}
	}
}

fn (mut l Lexer) handle_indentation() ! {
	if l.brace_depth > 0 {
		return
	}
	mut i := l.pos
	mut spaces := 0
	for i < l.source.len {
		ch := l.source[i]
		if ch == ` ` {
			spaces++
			i++
			continue
		}
		if ch == `\t` {
			return error('tabs are not supported for indentation')
		}
		break
	}
	if i < l.source.len && l.source[i] == `#` {
		for i < l.source.len && l.source[i] != `\n` {
			i++
		}
	}
	if i < l.source.len && l.source[i] == `\n` {
		l.pos = i
		return
	}
	l.pos = i
	l.at_line_start = false

	curr := l.indent_stack[l.indent_stack.len - 1]
	if spaces > curr {
		l.indent_stack << spaces
		l.pending << l.stamp(mut Token{
			kind: .indent
			text: ''
		}, i, i)
		return
	}
	if spaces < curr {
		for l.indent_stack.len > 1 && l.indent_stack[l.indent_stack.len - 1] > spaces {
			l.indent_stack = l.indent_stack[..l.indent_stack.len - 1]
			l.pending << l.stamp(mut Token{
				kind: .dedent
				text: ''
			}, i, i)
		}
		if l.indent_stack[l.indent_stack.len - 1] != spaces {
			return error('inconsistent indentation')
		}
	}
}

fn (mut l Lexer) skip_inline_ws() {
	for l.pos < l.source.len {
		ch := l.source[l.pos]
		if ch == ` ` || ch == `\r` || ch == `\t` {
			l.pos++
			continue
		}
		break
	}
}

fn (mut l Lexer) skip_comment() {
	for l.pos < l.source.len && l.source[l.pos] != `\n` {
		l.pos++
	}
}

fn is_alpha(ch u8) bool {
	return (ch >= `a` && ch <= `z`) || (ch >= `A` && ch <= `Z`) || ch == `_`
}

fn is_alnum(ch u8) bool {
	return is_alpha(ch) || is_digit(ch)
}

fn is_digit(ch u8) bool {
	return ch >= `0` && ch <= `9`
}

fn is_hex_digit(ch u8) bool {
	return is_digit(ch) || (ch >= `a` && ch <= `f`) || (ch >= `A` && ch <= `F`)
}

fn is_oct_digit(ch u8) bool {
	return ch >= `0` && ch <= `7`
}

fn is_bin_digit(ch u8) bool {
	return ch == `0` || ch == `1`
}

fn is_float_exponent(ch u8) bool {
	return ch == `e` || ch == `E`
}

// string_prefix_kind reports how an identifier immediately followed by a
// quote should be treated: 1 = plain/raw (r, u), 2 = f-string (f, rf),
// -1 = rejected (b, br). Returns 0 for ordinary identifiers.
fn string_prefix_kind(text string) int {
	lower := text.to_lower()
	if lower == 'r' || lower == 'u' {
		return 1
	}
	if lower == 'f' || lower == 'fr' || lower == 'rf' {
		return 2
	}
	if lower == 'b' || lower == 'br' || lower == 'rb' {
		return -1
	}
	return 0
}

// normalize_float_lexeme converts a Python float literal into a JSON-safe
// number literal: strips underscores, expands leading/trailing dots.
fn normalize_float_lexeme(raw string) string {
	mut out := ''
	for i := 0; i < raw.len; i++ {
		if raw[i] != `_` {
			out += raw[i].ascii_str()
		}
	}
	if out.starts_with('.') {
		out = '0' + out
	}
	if out.ends_with('.') {
		out += '0'
	}
	return out
}

// parse_int_literal parses decimal, hexadecimal, octal, and binary integer
// literals, tolerating the underscores Python allows between digits.
fn parse_int_literal(text string) !int {
	mut digits := ''
	for i := 0; i < text.len; i++ {
		if text[i] != `_` {
			digits += text[i].ascii_str()
		}
	}
	if digits.len > 2 && digits[0] == `0`
		&& (digits[1] == `x` || digits[1] == `X` || digits[1] == `o` || digits[1] == `O` || digits[1] == `b` || digits[1] == `B`) {
		base := if digits[1] == `x` || digits[1] == `X` {
				16
			} else if digits[1] == `o` || digits[1] == `O` {
				8
			} else {
				2
			}
		mut value := 0
		for i := 2; i < digits.len; i++ {
			ch := digits[i]
		digit := if ch >= `0` && ch <= `9` {
				int(ch - `0`)
			} else if ch >= `a` && ch <= `f` {
				int(ch - `a`) + 10
			} else if ch >= `A` && ch <= `F` {
				int(ch - `A`) + 10
			} else {
				return error('invalid integer literal')
			}
			if digit >= base {
				return error('invalid integer literal')
			}
			value = value * base + digit
		}
		return value
	}
	return strconv.atoi(digits) or { return error('invalid integer literal') }
}

fn (mut l Lexer) lex_number() !Token {
	start := l.pos
	// Non-decimal integer bases.
	if l.source[l.pos] == `0` && l.pos + 1 < l.source.len {
		next := l.source[l.pos + 1]
			if next == `x` || next == `X` {
			l.pos += 2
		digits := l.pos
			for l.pos < l.source.len
				&& (is_hex_digit(l.source[l.pos]) || l.source[l.pos] == `_`) {
				l.pos++
			}
			if l.pos == digits {
				return error('invalid hexadecimal literal')
			}
			return Token{
				kind: .int_lit
				text: l.source[start..l.pos]
			}
		}
		if next == `o` || next == `O` {
			l.pos += 2
			digits := l.pos
			for l.pos < l.source.len
				&& (is_oct_digit(l.source[l.pos]) || l.source[l.pos] == `_`) {
				l.pos++
			}
			if l.pos == digits {
				return error('invalid octal literal')
			}
			return Token{
				kind: .int_lit
				text: l.source[start..l.pos]
			}
		}
		if next == `b` || next == `B` {
			l.pos += 2
			digits := l.pos
			for l.pos < l.source.len
				&& (is_bin_digit(l.source[l.pos]) || l.source[l.pos] == `_`) {
				l.pos++
			}
			if l.pos == digits {
				return error('invalid binary literal')
			}
			return Token{
				kind: .int_lit
				text: l.source[start..l.pos]
			}
		}
	}
	// Decimal integer or float.
	for l.pos < l.source.len && (is_digit(l.source[l.pos]) || l.source[l.pos] == `_`) {
		l.pos++
	}
	mut is_float := false
	if l.pos < l.source.len && l.source[l.pos] == `.` {
		// A dot followed by a digit is a fraction; a bare trailing dot is
		// still a float (e.g. `3.`). Anything else (attribute access like
		// `x.5` cannot occur here since we start on a digit, but `3.foo`
		// would mislex: only take the dot when it cannot start an
		// identifier continuation... `3.foo` is invalid Python anyway.
		if l.pos + 1 >= l.source.len || is_digit(l.source[l.pos + 1])
			|| (!is_alpha(l.source[l.pos + 1]) && l.source[l.pos + 1] != `_`) {
			is_float = true
			l.pos++
			for l.pos < l.source.len
				&& (is_digit(l.source[l.pos]) || l.source[l.pos] == `_`) {
				l.pos++
			}
		}
	}
	if l.pos < l.source.len && is_float_exponent(l.source[l.pos]) {
		// Only treat e/E as an exponent when followed by digits (optional
		// sign); otherwise it is a name continuation error caught later.
		mut j := l.pos + 1
		if j < l.source.len && (l.source[j] == `+` || l.source[j] == `-`) {
			j++
		}
		if j < l.source.len && is_digit(l.source[j]) {
			is_float = true
			l.pos = j + 1
			for l.pos < l.source.len
				&& (is_digit(l.source[l.pos]) || l.source[l.pos] == `_`) {
				l.pos++
			}
		}
	}
	if is_float {
		return Token{
			kind: .float_lit
			text: normalize_float_lexeme(l.source[start..l.pos])
		}
	}
	return Token{
		kind: .int_lit
		text: l.source[start..l.pos]
	}
}

fn unescape_string(s string) string {
	mut out := ''
	mut i := 0
	for i < s.len {
		if s[i] == `\\` && i + 1 < s.len {
			next := s[i + 1]
		if next == `\n` {
			i += 2
			continue
		}
		if next == `\r` && i + 2 < s.len && s[i + 2] == `\n` {
			i += 3
			continue
		}
			out += match next {
				`n` { '\n' }
				`t` { '\t' }
				`"` { '"' }
				`\\` { '\\' }
				else { next.ascii_str() }
			}
			i += 2
			continue
		}
		out += s[i].ascii_str()
		i++
	}
	return out
}

fn (mut l Lexer) read_string_literal(quote u8) !string {
	triple := l.pos + 2 < l.source.len && l.source[l.pos + 1] == quote
		&& l.source[l.pos + 2] == quote
	if triple {
		l.pos += 3
		start := l.pos
		for l.pos + 2 < l.source.len {
			if l.source[l.pos] == quote && l.source[l.pos + 1] == quote
				&& l.source[l.pos + 2] == quote {
				text := l.source[start..l.pos]
				l.pos += 3
				return unescape_string(text)
			}
			if l.source[l.pos] == `\\` && l.pos + 1 < l.source.len {
				l.pos += 2
				continue
			}
			l.pos++
		}
		return error('unterminated triple-quoted string literal')
	}

	l.pos++
	start := l.pos
	for l.pos < l.source.len && l.source[l.pos] != quote {
		if l.source[l.pos] == `\\` && l.pos + 1 < l.source.len {
			l.pos += 2
			continue
		}
		if l.source[l.pos] == `\n` {
			return error('unterminated string literal')
		}
		l.pos++
	}
	if l.pos >= l.source.len {
		return error('unterminated string literal')
	}
	text := l.source[start..l.pos]
	l.pos++
	return unescape_string(text)
}

fn (mut l Lexer) read_raw_string_literal(quote u8) !string {
	triple := l.pos + 2 < l.source.len && l.source[l.pos + 1] == quote
		&& l.source[l.pos + 2] == quote
	if triple {
		l.pos += 3
		start := l.pos
		for l.pos < l.source.len {
			if l.source[l.pos] == quote && l.pos + 2 < l.source.len
				&& l.source[l.pos + 1] == quote && l.source[l.pos + 2] == quote {
				text := l.source[start..l.pos]
				l.pos += 3
				return text
			}
			if l.source[l.pos] == `\\` && l.pos + 1 < l.source.len {
				l.pos += 2
				continue
			}
			l.pos++
		}
		return error('unterminated triple-quoted string literal')
	}
	l.pos++
	start := l.pos
	for l.pos < l.source.len && l.source[l.pos] != quote {
		if l.source[l.pos] == `\\` && l.pos + 1 < l.source.len {
			l.pos += 2
			continue
		}
		if l.source[l.pos] == `\n` {
			return error('unterminated string literal')
		}
		l.pos++
	}
	if l.pos >= l.source.len {
		return error('unterminated string literal')
	}
	text := l.source[start..l.pos]
	l.pos++
	return text
}

fn hex_val(c u8) int {
	if c >= `0` && c <= `9` {
		return int(c - `0`)
	}
	if c >= `a` && c <= `f` {
		return int(c - `a`) + 10
	}
	if c >= `A` && c <= `F` {
		return int(c - `A`) + 10
	}
	return -1
}

fn bytes_to_text(b []u8) string {
	mut out := ''
	for c in b {
		out += c.ascii_str()
	}
	return out
}

fn unescape_bytes(s string) ![]u8 {
	mut out := []u8{}
	mut i := 0
	for i < s.len {
		if s[i] == `\\` && i + 1 < s.len {
			next := s[i + 1]
			if next == `\n` {
				i += 2
				continue
			}
			if next == `\r` && i + 2 < s.len && s[i + 2] == `\n` {
				i += 3
				continue
			}
			match next {
				`n` {
					out << u8(10)
					i += 2
					continue
				}
				`t` {
					out << u8(9)
					i += 2
					continue
				}
				`r` {
					out << u8(13)
					i += 2
					continue
				}
				`a` {
					out << u8(7)
					i += 2
					continue
				}
				`b` {
					out << u8(8)
					i += 2
					continue
				}
				`f` {
					out << u8(12)
					i += 2
					continue
				}
				`v` {
					out << u8(11)
					i += 2
					continue
				}
				`\\` {
					out << u8(92)
					i += 2
					continue
				}
				`'` {
					out << u8(39)
					i += 2
					continue
				}
				`"` {
					out << u8(34)
					i += 2
					continue
				}
				`0`, `1`, `2`, `3`, `4`, `5`, `6`, `7` {
					mut val := int(next - `0`)
					mut j := i + 2
					for j < s.len && j < i + 4 && s[j] >= `0` && s[j] <= `7` {
						val = val * 8 + int(s[j] - `0`)
						j++
					}
					out << u8(val & 0xff)
					i = j
					continue
				}
				`x` {
					if i + 3 >= s.len || hex_val(s[i + 2]) < 0 || hex_val(s[i + 3]) < 0 {
						return error('truncated \\x escape in bytes literal')
					}
					out << u8(hex_val(s[i + 2]) * 16 + hex_val(s[i + 3]))
					i += 4
					continue
				}
				else {
					if next == `N` || next == `u` || next == `U` {
						return error('unicode escape in bytes literal is not supported')
					}
					out << u8(92)
					out << next
					i += 2
					continue
				}
			}
		}
		out << s[i]
		i++
	}
	return out
}

fn (mut l Lexer) lex_prefixed_string(prefix_text string) !Token {
	lower := prefix_text.to_lower()
	if lower.contains('b') {
		is_raw := lower.contains('r')
		quote := l.source[l.pos]
		raw := l.read_raw_string_literal(quote)!
		mut data := []u8{}
		if is_raw {
			for k := 0; k < raw.len; k++ {
				data << raw[k]
			}
		} else {
			data = unescape_bytes(raw)!
		}
		return Token{
			kind: .bytes_lit
			text: bytes_to_text(data)
		}
	}
	quote := l.source[l.pos]
	if lower.contains('f') {
		return l.lex_fstring(quote, lower.contains('r'))
	}
	if lower.contains('r') {
		text := l.read_raw_string_literal(quote)!
		return Token{
			kind: .string_lit
			text: text
		}
	}
	text := l.read_string_literal(quote)!
	return Token{
		kind: .string_lit
		text: text
	}
}

// lex_fstring tokenizes a complete f-string (starting at its opening quote)
// into fstr_* tokens pushed onto the pending queue. Replacement fields are
// lexed with a throwaway sub-lexer so nesting (strings, dicts, nested
// f-strings) is handled by the normal machinery; format specs are kept as
// raw text and nested replacement fields inside them are rejected.
fn (mut l Lexer) lex_fstring(quote u8, is_raw bool) !Token {
	sl, sc := l.lookup_pos(l.pos)
	sel, sec := l.lookup_pos(l.pos + 1)
	mut toks := [Token{
		kind: .fstr_start
		text: ''
		line: sl
		col: sc
		end_line: sel
		end_col: sec
	}]
	triple := l.pos + 2 < l.source.len && l.source[l.pos + 1] == quote
		&& l.source[l.pos + 2] == quote
	if triple {
		l.pos += 3
	} else {
		l.pos++
	}
	for {
		mut raw := ''
		mut done := false
		mut field := false
		frag_start := l.pos
		for l.pos < l.source.len {
			ch := l.source[l.pos]
			if !triple && ch == `\n` {
				return error('unterminated f-string literal')
			}
			if ch == quote {
				if triple {
					if l.pos + 2 < l.source.len && l.source[l.pos + 1] == quote
						&& l.source[l.pos + 2] == quote {
						l.pos += 3
						done = true
						break
					}
					raw += ch.ascii_str()
					l.pos++
					continue
				}
				l.pos++
				done = true
				break
			}
			if ch == `\\` && l.pos + 1 < l.source.len {
				raw += l.source[l.pos..l.pos + 2]
				l.pos += 2
				continue
			}
			if ch == `{` {
				if l.pos + 1 < l.source.len && l.source[l.pos + 1] == `{` {
					raw += '{'
					l.pos += 2
					continue
				}
				l.pos++
				field = true
				break
			}
			if ch == `}` {
				if l.pos + 1 < l.source.len && l.source[l.pos + 1] == `}` {
					raw += '}'
					l.pos += 2
					continue
				}
				return error("single '}' encountered in f-string")
			}
			raw += ch.ascii_str()
			l.pos++
		}
		if !done && !field {
			return error('unterminated f-string literal')
		}
		chunk := if is_raw { raw } else { unescape_string(raw) }
		if chunk != '' {
			tl, tc := l.lookup_pos(frag_start)
			tel, tec := l.lookup_pos(l.pos)
			toks << Token{
				kind: .fstr_text
				text: chunk
				line: tl
				col: tc
				end_line: tel
				end_col: tec
			}
		}
		if done {
			el, ec := l.lookup_pos(l.pos)
			toks << Token{
				kind: .fstr_end
				text: ''
				line: el
				col: ec
				end_line: el
				end_col: ec
			}
			break
			}
		for tok in l.lex_fstring_field()! {
			toks << tok
		}
	}
	first := toks[0]
	for tok in toks[1..] {
		l.pending << tok
	}
	return first
}

// is_lambda_keyword_at reports whether a `lambda` keyword starts at
// position k, used to keep lambda body colons out of format specs.
fn is_lambda_keyword_at(s string, k int) bool {
	word := 'lambda'
	if k + word.len > s.len || s[k..k + word.len] != word {
		return false
	}
	if k > 0 && (is_alnum(s[k - 1]) || s[k - 1] == `_`) {
		return false
	}
	after := k + word.len
	if after < s.len && (is_alnum(s[after]) || s[after] == `_`) {
		return false
	}
	return true
}

fn (mut l Lexer) lex_fstring_field() ![]Token {
	ol, oc := l.lookup_pos(l.pos - 1)
	oel, oec := l.lookup_pos(l.pos)
	mut toks := [Token{
		kind: .fstr_field_open
		text: ''
		line: ol
		col: oc
		end_line: oel
		end_col: oec
	}]
	// Scan the field extent: up to the matching top-level `}`. Strings,
	// comments, and nested braces are skipped so only the field-closing
	// brace terminates the scan.
	start := l.pos
	mut depth := 0
	mut str_quote := u8(0)
	mut str_triple := false
	mut i := l.pos
	mut end := -1
	for i < l.source.len {
		ch := l.source[i]
		if str_quote != 0 {
			if ch == `\\` && i + 1 < l.source.len {
				i += 2
				continue
			}
			if ch == str_quote {
				if str_triple {
					if i + 2 < l.source.len && l.source[i + 1] == str_quote
						&& l.source[i + 2] == str_quote {
						i += 3
						str_quote = 0
						continue
					}
				} else {
					str_quote = 0
					i++
					continue
				}
			}
			i++
			continue
		}
		if ch == `#` {
			for i < l.source.len && l.source[i] != `\n` {
				i++
			}
			continue
		}
		if ch == `"` || ch == `'` {
			str_quote = ch
			str_triple = i + 2 < l.source.len && l.source[i + 1] == ch
				&& l.source[i + 2] == ch
			i += if str_triple { 3 } else { 1 }
			continue
		}
		if ch == `{` {
			depth++
			i++
			continue
		}
		if ch == `}` {
			if depth == 0 {
				end = i
				i++
				break
			}
			depth--
			i++
			continue
		}
		i++
	}
	if end < 0 {
		return error('unterminated replacement field in f-string')
	}
	extent := l.source[start..end]
	l.pos = i
	// Split the extent into expression and raw format spec at the first
	// top-level `:` that is not part of `:=`.
	mut expr_end := extent.len
	mut conversion := -1
	mut spec := ''
	mut sdepth := 0
	mut lam_depth := 0
	mut sstr := u8(0)
	mut striple := false
	mut k := 0
	for k < extent.len {
		ch := extent[k]
		if sstr != 0 {
			if ch == `\\` && k + 1 < extent.len {
				k += 2
				continue
			}
			if ch == sstr {
				if striple {
					if k + 2 < extent.len && extent[k + 1] == sstr && extent[k + 2] == sstr {
						k += 3
						sstr = 0
						continue
					}
				} else {
					sstr = 0
					k++
					continue
				}
			}
			k++
			continue
		}
		if ch == `"` || ch == `'` {
			sstr = ch
			striple = k + 2 < extent.len && extent[k + 1] == ch && extent[k + 2] == ch
			k += if striple { 3 } else { 1 }
			continue
		}
		if ch == `{` || ch == `(` || ch == `[` {
			sdepth++
			k++
			continue
		}
		if ch == `}` || ch == `)` || ch == `]` {
			sdepth--
			k++
			continue
		}
		if sdepth == 0 && is_lambda_keyword_at(extent, k) {
			lam_depth++
		}
		if sdepth == 0 && ch == `:` {
			if k + 1 < extent.len && extent[k + 1] == `=` {
				k += 2
				continue
			}
			if lam_depth > 0 {
				lam_depth--
				k++
				continue
			}
			expr_end = k
			spec = extent[k + 1..]
			break
		}
		k++
	}
	// Look for a trailing !s/!r/!a conversion in the expression part.
	mut expr_src := extent[..expr_end]
	mut cdepth := 0
	mut cstr := u8(0)
	mut ctriple := false
	mut m := 0
	for m < expr_src.len {
		ch := expr_src[m]
		if cstr != 0 {
			if ch == `\\` && m + 1 < expr_src.len {
				m += 2
				continue
			}
			if ch == cstr {
				if ctriple {
					if m + 2 < expr_src.len && expr_src[m + 1] == cstr
						&& expr_src[m + 2] == cstr {
						m += 3
						cstr = 0
						continue
					}
				} else {
					cstr = 0
					m++
					continue
				}
			}
			m++
			continue
		}
		if ch == `"` || ch == `'` {
			cstr = ch
			ctriple = m + 2 < expr_src.len && expr_src[m + 1] == ch
				&& expr_src[m + 2] == ch
			m += if ctriple { 3 } else { 1 }
			continue
		}
		if ch == `{` || ch == `(` || ch == `[` {
			cdepth++
			m++
			continue
		}
		if ch == `}` || ch == `)` || ch == `]` {
			cdepth--
			m++
			continue
		}
		if cdepth == 0 && ch == `!` && m + 1 < expr_src.len && expr_src[m + 1] != `=` {
			conv := expr_src[m + 1]
			if conv == `s` || conv == `S` || conv == `r` || conv == `R` || conv == `a`
				|| conv == `A` {
				conversion = match conv {
					`s`, `S` { 115 }
					`r`, `R` { 114 }
					else { 97 }
				}
				expr_src = expr_src[..m]
				break
			}
		}
		m++
	}
	if expr_src.trim_space() == '' {
		return error('empty replacement field in f-string')
	}
	// Lex the field expression with a throwaway sub-lexer. brace_depth=1
	// keeps newlines and indentation out of the token stream.
	mut sub := Lexer{
		source:      expr_src
		brace_depth: 1
	}
	// The sub-lexer reports positions relative to the field slice; shift
	// them to absolute source coordinates.
	base_line, base_col := l.lookup_pos(start)
	for {
		mut tok := sub.next_token()!
		if tok.kind == .eof {
			break
		}
		tok.line += base_line - 1
		if tok.line == base_line {
			tok.col += base_col
		}
		tok.end_line += base_line - 1
		if tok.end_line == base_line {
			tok.end_col += base_col
		}
		toks << tok
	}
	if conversion >= 0 {
		bl, bc := l.lookup_pos(l.pos)
		toks << Token{
			kind: .fstr_bang
			text: conversion.str()
			line: bl
			col: bc
			end_line: bl
			end_col: bc
		}
	}
	if spec != '' {
		// Nested replacement fields in specs are out of scope.
		if spec.contains('{') {
			return error('nested replacement fields in format spec are not supported')
		}
		spl, spc := l.lookup_pos(l.pos)
		toks << Token{
			kind: .fstr_spec
			text: spec
			line: spl
			col: spc
			end_line: spl
			end_col: spc
		}
	}
	cl, cc := l.lookup_pos(l.pos - 1)
	cel, cec := l.lookup_pos(l.pos)
	toks << Token{
		kind: .fstr_field_close
		text: ''
		line: cl
		col: cc
		end_line: cel
		end_col: cec
	}
	return toks
}

struct Parser {
mut:
	lexer             Lexer
	curr              Token
	next              Token
	prev_real         Token
	skip_stmt_newline bool
}

fn new_parser(source string) !Parser {
	normalized := source.replace('\r\n', '\n').replace('\r', '\n')
	mut lexer := Lexer{
		source: normalized
	}
	first := lexer.next_token()!
	second := lexer.next_token()!
	return Parser{
		lexer:     lexer
		curr:      first
		next:      second
		prev_real: first
	}
}

fn (mut p Parser) parse_expr_root() !Expr {
	expr := p.parse_expr()!
	for p.curr.kind == .newline {
		p.advance()!
	}
	p.expect(.eof)!
	return expr
}

fn (mut p Parser) parse_module() !Module {
	mut body := []Stmt{}
	p.consume_newlines()!
	for p.curr.kind != .eof {
		body << p.parse_stmt()!
		p.consume_newlines()!
	}
	return Module{
		body: body
	}
}

// parse_stmt is strict: anything outside the supported subset is an error.
// Callers that need full Python coverage should fall back to the standard
// library parser instead of silently degrading (e.g. to PassStmt), so a
// successful parse always means a faithful tree.
fn (mut p Parser) parse_stmt() !Stmt {
	return match p.curr.kind {
		.kw_if {
			p.parse_if_stmt()
		}
		.kw_while {
			p.parse_while_stmt()
		}
		.kw_for {
			p.parse_for_stmt(false)
		}
		.kw_def {
			p.parse_function_def([]Expr{}, false)
		}
		.kw_class {
			p.parse_class_def([]Expr{})
		}
		.kw_try {
			p.parse_try_stmt()
		}
		.kw_with {
			p.parse_with_stmt(false)
		}
		.kw_async {
			p.parse_async_stmt()
		}
		.at_sign {
			p.parse_decorated()
		}
		else {
			stmt := p.parse_simple_stmt()!
			p.finish_simple_stmt()!
			stmt
		}
	}
}

// finish_simple_stmt consumes the statement terminator after a simple
// statement, honouring the match-expression flag and trailing EOF.
fn (mut p Parser) finish_simple_stmt() ! {
	if p.curr.kind == .semicolon {
		p.advance()!
		if p.skip_stmt_newline {
			p.skip_stmt_newline = false
		}
		return
	}
	if p.skip_stmt_newline {
		p.skip_stmt_newline = false
		return
	}
	if p.curr.kind == .newline {
		p.advance()!
		return
	}
	if p.curr.kind == .eof {
		return
	}
	return error('expected newline after statement, found ${p.curr.kind}')
}

fn (mut p Parser) parse_decorated() !Stmt {
	mut decorators := []Expr{}
	for p.curr.kind == .at_sign {
		p.advance()!
		decorators << p.parse_test()!
		if p.curr.kind == .newline {
			p.advance()!
		} else if p.curr.kind != .eof {
			return error('expected newline after decorator, found ${p.curr.kind}')
		}
	}
	if p.curr.kind == .kw_async {
		p.advance()!
		if p.curr.kind != .kw_def {
			return error('expected def after async in decorated definition')
		}
		return p.parse_function_def(decorators, true)
	}
	if p.curr.kind == .kw_def {
		return p.parse_function_def(decorators, false)
	}
	if p.curr.kind == .kw_class {
		return p.parse_class_def(decorators)
	}
	return error('expected def or class after decorators')
}

fn (mut p Parser) parse_async_stmt() !Stmt {
	p.expect(.kw_async)!
	if p.curr.kind == .kw_def {
		return p.parse_function_def([]Expr{}, true)
	}
	if p.curr.kind == .kw_for {
		return p.parse_for_stmt(true)
	}
	if p.curr.kind == .kw_with {
		return p.parse_with_stmt(true)
	}
	return error('expected def, for, or with after async')
}

fn (mut p Parser) parse_if_stmt() !Stmt {
	start := p.curr
	p.expect(.kw_if)!
	test := p.parse_expr()!
	body := p.parse_suite(true)!
	return IfStmt{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		test:   test
		body:   body
		orelse: p.parse_if_orelse()!
	}
	}

	fn (mut p Parser) parse_if_orelse() ![]Stmt {
		start := p.curr
	if p.curr.kind == .kw_else {
		p.advance()!
		return p.parse_suite(true)!
	}
	if p.curr.kind == .kw_elif {
		p.advance()!
		test := p.parse_expr()!
		body := p.parse_suite(true)!
		return [
			Stmt(IfStmt{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				test:   test
				body:   body
				orelse: p.parse_if_orelse()!
			}),
		]
	}
	return []Stmt{}
	}

fn (mut p Parser) parse_while_stmt() !Stmt {
	start := p.curr
	p.expect(.kw_while)!
	test := p.parse_expr()!
	body := p.parse_suite(true)!
	mut orelse := []Stmt{}
	if p.curr.kind == .kw_else {
		p.advance()!
		orelse = p.parse_suite(true)!
	}
	return WhileStmt{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		test:   test
		body:   body
		orelse: orelse
	}
}

fn (mut p Parser) parse_for_stmt(is_async bool) !Stmt {
	start := p.curr
	p.expect(.kw_for)!
	target := p.parse_comp_target()!
	if !is_assign_target(target) {
		return error('invalid for loop target')
	}
	if p.curr.kind == .kw_in {
		p.advance()!
	} else {
		return error('expected in after for loop target')
	}
	iter := p.parse_expr()!
	body := p.parse_suite(true)!
	mut orelse := []Stmt{}
	if p.curr.kind == .kw_else {
		p.advance()!
		orelse = p.parse_suite(true)!
	}
	return ForStmt{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		target:   target
		iter:     iter
		body:     body
		orelse:   orelse
		is_async: is_async
	}
}

fn (mut p Parser) parse_function_def(decorators []Expr, is_async bool) !Stmt {
	start := p.curr
	p.expect(.kw_def)!
	name := p.parse_name_text() or { return error('expected function name') }
	args := p.parse_params(false)!
	mut returns := ?Expr(none)
	if p.curr.kind == .arrow {
		p.advance()!
		returns = p.parse_test()!
	}
	body := p.parse_suite(true)!
	return FunctionDefStmt{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		name:           name
		args:           args
		body:           body
		decorator_list: decorators
		returns:        returns
		is_async:       is_async
	}
}

// parse_params parses function or lambda parameters. Lambda parameters end
// at `:` and carry no annotations; function parameters end at `)` and may
// carry annotations, defaults, `/`, `*` and `**` markers.
fn (mut p Parser) parse_params(lambda_style bool) !FunctionArgs {
	start := p.curr
	mut posonlyargs := []FunctionArg{}
	mut args := []FunctionArg{}
	mut vararg := ?FunctionArg(none)
	mut kwonlyargs := []FunctionArg{}
	mut kw_defaults := []?Expr{}
	mut kwarg := ?FunctionArg(none)
	mut defaults := []Expr{}
	mut seen_star := false
	mut seen_slash := false
	if !lambda_style {
		p.expect(.lparen)!
	}
	if (!lambda_style && p.curr.kind == .rparen) || (lambda_style && p.curr.kind == .colon) {
		if !lambda_style {
			p.advance()!
		}
		return FunctionArgs{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			posonlyargs: posonlyargs
			args:        args
			vararg:      vararg
			kwonlyargs:  kwonlyargs
			kw_defaults: kw_defaults
			kwarg:       kwarg
			defaults:    defaults
		}
	}
	for {
		if (!lambda_style && p.curr.kind == .rparen) || (lambda_style && p.curr.kind == .colon) {
			break
		}
		if p.curr.kind == .slash && !lambda_style {
			if seen_star || seen_slash {
				return error('misplaced / in parameters')
			}
			seen_slash = true
			p.advance()!
			for a in args {
				posonlyargs << a
			}
			args = []FunctionArg{}
			defaults = []Expr{}
		} else if p.curr.kind == .star {
			if seen_star {
				return error('duplicate * in parameters')
			}
			seen_star = true
			p.advance()!
			if (!lambda_style && p.curr.kind == .rparen) || p.curr.kind == .comma
				|| (lambda_style && p.curr.kind == .colon) {
				// bare `*` introduces keyword-only parameters
			} else if is_name_token(p.curr.kind) {
				varg_tok := p.curr
				arg_name := p.parse_name_text()!
				mut ann := ?Expr(none)
				if !lambda_style && p.curr.kind == .colon {
					p.advance()!
					ann = p.parse_test()!
				}
				vararg = FunctionArg{
					line: varg_tok.line,
					col: varg_tok.col,
					end_line: p.prev_real.end_line,
					end_col: p.prev_real.end_col,
					name:       arg_name
					annotation: ann
				}
			} else {
				return error('expected parameter name after *')
			}
		} else if p.curr.kind == .pow {
			p.advance()!
			if p.curr.kind != .ident {
				return error('expected parameter name after **')
			}
			kwarg_tok := p.curr
			arg_name := p.parse_name_text()!
			mut ann := ?Expr(none)
			if !lambda_style && p.curr.kind == .colon {
				p.advance()!
				ann = p.parse_test()!
			}
			kwarg = FunctionArg{
				line: kwarg_tok.line,
				col: kwarg_tok.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				name:       arg_name
				annotation: ann
			}
		} else if is_name_token(p.curr.kind) {
			arg_tok := p.curr
			name := p.parse_name_text()!
			mut annotation := ?Expr(none)
			if !lambda_style && p.curr.kind == .colon {
				p.advance()!
				annotation = p.parse_test()!
			}
			mut default := ?Expr(none)
			if p.curr.kind == .assign {
				p.advance()!
				default = p.parse_test()!
			}
			arg := FunctionArg{
				line: arg_tok.line,
				col: arg_tok.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				name:       name
				annotation: annotation
			}
			if seen_star {
				kwonlyargs << arg
				kw_defaults << default
			} else {
				if dflt := default {
					defaults << dflt
				} else if defaults.len > 0 {
					return error('non-default argument follows default argument')
				}
				args << arg
			}
		} else {
			return error('expected parameter name, found ${p.curr.kind}')
		}
		if p.curr.kind == .comma {
			p.advance()!
			continue
		}
		break
	}
	if !lambda_style {
		p.expect(.rparen)!
	}
	return FunctionArgs{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		posonlyargs: posonlyargs
		args:        args
		vararg:      vararg
		kwonlyargs:  kwonlyargs
		kw_defaults: kw_defaults
		kwarg:       kwarg
		defaults:    defaults
	}
}

fn (mut p Parser) parse_class_def(decorators []Expr) !Stmt {
	start := p.curr
	p.expect(.kw_class)!
	name := p.parse_name_text() or { return error('expected class name') }
	mut bases := []Expr{}
	mut keywords := []CallKeyword{}
	if p.curr.kind == .lparen {
		p.advance()!
		if p.curr.kind != .rparen {
			parsed_args, parsed_kw := p.parse_class_args()!
			bases = parsed_args.clone()
			keywords = parsed_kw.clone()
		}
		p.expect(.rparen)!
	}
	body := p.parse_suite(true)!
	return ClassDefStmt{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		name:           name
		bases:          bases
		keywords:       keywords
		body:           body
		decorator_list: decorators
	}
}

fn (mut p Parser) parse_class_args() !([]Expr, []CallKeyword) {
	mut bases := []Expr{}
	mut keywords := []CallKeyword{}
	mut seen_keyword := false
	for {
		if p.curr.kind == .pow {
			pow_tok := p.curr
			p.advance()!
			keywords << CallKeyword{
				line: pow_tok.line,
				col: pow_tok.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				name:  none
				value: p.parse_test()!
			}
			seen_keyword = true
		} else {
			base := p.parse_test()!
			if p.curr.kind == .assign {
				if base is NameExpr {
					kw_base := base as NameExpr
					p.advance()!
					keywords << CallKeyword{
						line: kw_base.line,
						col: kw_base.col,
						end_line: p.prev_real.end_line,
						end_col: p.prev_real.end_col,
						name:  kw_base.name
						value: p.parse_test()!
					}
					seen_keyword = true
				} else {
					return error('keyword argument must be a name')
				}
			} else {
				if seen_keyword {
					return error('positional argument follows keyword argument')
				}
				bases << base
			}
		}
		if p.curr.kind == .comma {
			p.advance()!
			if p.curr.kind == .rparen {
				break
			}
			continue
		}
		break
	}
	return bases, keywords
}

// parse_suite parses a `:` block. With allow_single, a lone statement on
// the same line is also accepted (`if x: return 1`).
fn (mut p Parser) parse_suite(allow_single bool) ![]Stmt {
	p.expect(.colon)!
	if p.curr.kind == .newline {
		return p.parse_block_suite()
	}
	if !allow_single {
		return error('expected newline after :, found ${p.curr.kind}')
	}
	return [p.parse_stmt()!]
}

fn (mut p Parser) parse_block_suite() ![]Stmt {
	p.expect(.newline)!
	p.consume_newlines()!
	p.expect(.indent)!
	mut body := []Stmt{}
	p.consume_newlines()!
	for p.curr.kind != .dedent && p.curr.kind != .eof {
		body << p.parse_stmt()!
		p.consume_newlines()!
	}
	if body.len == 0 {
		return error('expected at least one statement in block')
	}
	p.expect(.dedent)!
	return body
}

fn (mut p Parser) parse_simple_stmt() !Stmt {
	start := p.curr
	if p.curr.kind == .kw_import || p.curr.kind == .kw_from {
		return p.parse_import_stmt()
	}
	if p.curr.kind == .kw_pass {
		p.advance()!
		return PassStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
		}
	}
	if p.curr.kind == .kw_break {
		p.advance()!
		return BreakStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
		}
	}
	if p.curr.kind == .kw_continue {
		p.advance()!
		return ContinueStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
		}
	}
	if p.curr.kind == .kw_return {
		p.advance()!
		if p.curr.kind == .newline {
			return ReturnStmt{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				value: none
			}
		}
		value := p.parse_expr()!
		return ReturnStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			value: value
		}
	}
	if p.curr.kind == .kw_assert {
		p.advance()!
		test := p.parse_test()!
		mut msg := ?Expr(none)
		if p.curr.kind == .comma {
			p.advance()!
			msg = p.parse_test()!
		}
		return AssertStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			test: test
			msg:  msg
		}
	}
	if p.curr.kind == .kw_del {
		p.advance()!
		targets := p.parse_expr()!
		targets_list := if targets is TupleExpr {
			(targets as TupleExpr).elts
		} else {
			[targets]
		}
		for t in targets_list {
			if !is_assign_target(t) {
				return error('invalid delete target')
			}
		}
		return DeleteStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			targets: targets_list
		}
	}
	if p.curr.kind == .kw_raise {
		p.advance()!
		mut exc := ?Expr(none)
		mut cause := ?Expr(none)
		if p.curr.kind != .newline && p.curr.kind != .eof {
			exc = p.parse_test()!
			if p.curr.kind == .kw_from {
				p.advance()!
				cause = p.parse_test()!
			}
		}
		return RaiseStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			exc:   exc
			cause: cause
		}
	}
	if p.curr.kind == .kw_global || p.curr.kind == .kw_nonlocal {
		is_global := p.curr.kind == .kw_global
		p.advance()!
		mut names := []string{}
		for {
			names << p.parse_name_text()!
			if p.curr.kind != .comma {
				break
			}
			p.advance()!
		}
		if is_global {
			return GlobalStmt{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				names: names
			}
		}
		return NonlocalStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			names: names
		}
	}
	if p.curr.kind == .kw_try {
		return p.parse_try_stmt()
	}
	if p.curr.kind == .kw_with {
		return p.parse_with_stmt(false)
	}
// Assignment, annotated assignment, augmented assignment, or a bare
// expression. Chained targets (`x = y = 1`) collect left to right.
	mut first := p.parse_expr()!
	mut targets := []Expr{}
	for {
		if p.curr.kind == .assign {
			p.advance()!
			targets << first
			first = p.parse_expr()!
			continue
		}
		aug := augassign_op(p.curr.kind, p.next.kind)
		if aug != '' {
			p.advance()!
			p.advance()!
			if !is_single_target(first) {
				return error('invalid augmented assignment target')
			}
			return AugAssignStmt{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				target: first
				op:     aug
				value:  p.parse_expr()!
			}
		}
		if p.curr.kind == .colon {
			p.advance()!
			if !is_single_target(first) {
				return error('invalid annotated assignment target')
			}
			annotation := p.parse_test()!
			mut value := ?Expr(none)
			if p.curr.kind == .assign {
				p.advance()!
				value = p.parse_expr()!
			}
			return AnnAssignStmt{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				target:     first
				annotation: annotation
				value:      value
				simple:     first is NameExpr
			}
		}
		break
	}
	if targets.len == 0 {
		return ExprStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			value: first
		}
	}
	for t in targets {
		if !is_assign_target(t) {
			return error('invalid assignment target')
		}
	}
	return AssignStmt{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		targets: targets
		value:   first
	}
}

// augassign_op maps a two-token operator sequence to its operator name.
	fn augassign_op(first TokenKind, second TokenKind) string {
		if second != .assign {
			return ''
		}
		return match first {
			.plus { 'Add' }
			.minus { 'Sub' }
			.star { 'Mult' }
			.slash { 'Div' }
			.floordiv { 'FloorDiv' }
			.percent { 'Mod' }
			.pow { 'Pow' }
			.at_sign { 'MatMult' }
			.amp { 'BitAnd' }
			.pipe { 'BitOr' }
			.caret { 'BitXor' }
			.lshift { 'LShift' }
			.rshift { 'RShift' }
			else { '' }
		}
	}

	// is_assign_target reports whether an expression may appear as an
	// assignment, for-loop, delete, or comprehension target.
	fn all_assign_targets(elts []Expr) bool {
	for e in elts {
		if !is_assign_target(e) {
			return false
		}
	}
	return true
}

fn is_assign_target(e Expr) bool {
		return match e {
			NameExpr, AttributeExpr, SubscriptExpr { true }
			StarredExpr { is_assign_target(e.value) }
	TupleExpr { all_assign_targets(e.elts) }
	ListExpr { all_assign_targets(e.elts) }
			else { false }
		}
	}

	fn is_single_target(e Expr) bool {
		return match e {
			NameExpr, AttributeExpr, SubscriptExpr { true }
			else { false }
		}
	}

	fn (mut p Parser) parse_try_stmt() !Stmt {
		start := p.curr
		p.expect(.kw_try)!
		body := p.parse_suite(false)!
		mut handlers := []ExceptHandler{}
		for p.curr.kind == .kw_except {
			p.advance()!
			mut handler_star := false
			if p.curr.kind == .star {
				handler_star = true
				p.advance()!
			}
			mut typ := ?Expr(none)
			mut name := ''
			if p.curr.kind != .colon {
				typ = p.parse_test()!
				if p.curr.kind == .kw_as {
					p.advance()!
					name = p.parse_name_text() or { return error('expected name after as in except handler') }
				}
			}
			handler_body := p.parse_suite(true)!
			handlers << ExceptHandler{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				typ:  typ
				name: name
				body: handler_body
			}
			if handler_star {
				return p.finish_star_try(body, handlers)!
			}
		}
		mut orelse := []Stmt{}
		if p.curr.kind == .kw_else {
			p.advance()!
			orelse = p.parse_suite(true)!
		}
		mut finalbody := []Stmt{}
		if p.curr.kind == .kw_finally {
			p.advance()!
			finalbody = p.parse_suite(true)!
		}
		if handlers.len == 0 && finalbody.len == 0 {
			return error('try statement needs an except or finally clause')
		}
		return TryStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			body:      body
			handlers:  handlers
			orelse:    orelse
			finalbody: finalbody
			is_star:   false
		}
	}

	fn (mut p Parser) finish_star_try(body []Stmt, handlers []ExceptHandler) !Stmt {
		start := p.curr
		mut orelse := []Stmt{}
		if p.curr.kind == .kw_else {
			p.advance()!
			orelse = p.parse_suite(true)!
		}
		mut finalbody := []Stmt{}
		if p.curr.kind == .kw_finally {
			p.advance()!
			finalbody = p.parse_suite(true)!
		}
		return TryStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			body:      body
			handlers:  handlers
			orelse:    orelse
			finalbody: finalbody
			is_star:   true
		}
	}

	fn (mut p Parser) parse_with_stmt(is_async bool) !Stmt {
		start := p.curr
		p.expect(.kw_with)!
		mut items := []WithItem{}
		for {
			context_expr := p.parse_test()!
			mut vars := ?Expr(none)
			if p.curr.kind == .kw_as {
				p.advance()!
				vars = p.parse_test()!
			}
			items << WithItem{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				context_expr: context_expr
				vars:         vars
			}
			if p.curr.kind != .comma {
				break
			}
			p.advance()!
		}
		body := p.parse_suite(true)!
		return WithStmt{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			items:    items
			body:     body
			is_async: is_async
		}
	}

fn (mut p Parser) parse_import_stmt() !Stmt {
	start := p.curr
	if p.curr.kind == .kw_from {
		return p.parse_import_from_stmt()
	}
	p.expect(.kw_import)!
	mut names := []ImportAlias{}
	names << p.parse_import_alias()!
	for p.curr.kind == .comma {
		p.advance()!
		names << p.parse_import_alias()!
	}
	return ImportStmt{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		names: names
	}
}

fn (mut p Parser) parse_import_alias() !ImportAlias {
	start := p.curr
	mut name := ''
	if p.curr.kind == .star {
		name = '*'
		p.advance()!
	} else {
		name = p.parse_dotted_name()!
	}
	mut asname := ''
	if p.curr.kind == .kw_as {
		p.advance()!
		asname = p.parse_name_text() or { return error('expected name after as in import') }
	}
	return ImportAlias{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		name:   name
		asname: asname
	}
}

fn (mut p Parser) parse_import_from_stmt() !Stmt {
	start := p.curr
	p.expect(.kw_from)!
	mut level := 0
	for p.curr.kind == .dot {
		level++
		p.advance()!
	}
	mut mod_name := ''
	if is_name_token(p.curr.kind) {
		mod_name = p.parse_dotted_name()!
	}
	p.expect(.kw_import)!
	mut parenthesized := false
	if p.curr.kind == .lparen {
		parenthesized = true
		p.advance()!
	}
	mut names := []ImportAlias{}
	names << p.parse_import_alias()!
	for p.curr.kind == .comma {
		p.advance()!
		if parenthesized && p.curr.kind == .rparen {
			break
		}
		if p.curr.kind == .newline {
			return error('expected import name, found newline')
		}
		names << p.parse_import_alias()!
	}
	if parenthesized {
		p.expect(.rparen)!
	}
	return ImportFromStmt{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		module: mod_name
		level:  level
		names:  names
	}
}

fn (mut p Parser) parse_dotted_name() !string {
	mut name := p.parse_name_text()!
	for p.curr.kind == .dot {
		p.advance()!
		name += '.' + p.parse_name_text()!
	}
	return name
}

// Expression precedence, loosest to tightest: tuple, lambda/yield/starred,
// namedexpr (:=), ifexp, or, and, not, comparison (incl. in/is), bitwise or,
// xor, and, shifts, additive, multiplicative, unary (+/-/~/await), power
// (**), postfix (calls, attributes, subscripts), primary.
fn (mut p Parser) parse_expr() !Expr {
	start := p.curr
	first := p.parse_test()!
	if p.curr.kind != .comma {
		return first
	}
	mut elts := [first]
	for p.curr.kind == .comma {
		p.advance()!
		if p.curr.kind == .rparen || p.curr.kind == .rbracket || p.curr.kind == .rbrace
			|| p.curr.kind == .newline || p.curr.kind == .eof
			|| p.curr.kind == .fstr_field_close {
			break
		}
		elts << p.parse_test()!
	}
	return TupleExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		elts: elts
	}
}

fn (mut p Parser) parse_test() !Expr {
	start := p.curr
	if p.curr.kind == .kw_lambda {
		return p.parse_lambda_expr()
	}
	if p.curr.kind == .kw_yield {
		return p.parse_yield_expr()
	}
	if p.curr.kind == .star {
		p.advance()!
		return StarredExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			value: p.parse_namedexpr()!
		}
	}
	return p.parse_namedexpr()
}

fn (mut p Parser) parse_namedexpr() !Expr {
	start := p.curr
	if is_name_token(p.curr.kind) && p.next.kind == .colon_assign {
		target := p.parse_name_text()!
		p.expect(.colon_assign)!
		return NamedExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			target: target
			value:  p.parse_namedexpr()!
		}
	}
	return p.parse_ifexp()
}

fn (mut p Parser) parse_ifexp() !Expr {
	start := p.curr
	body := p.parse_or_expr()!
	if p.curr.kind != .kw_if {
		return body
	}
	p.advance()!
	test := p.parse_or_expr()!
	p.expect(.kw_else)!
	return IfExpExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		test:   test
		body:   body
		orelse: p.parse_test()!
	}
}

fn (mut p Parser) parse_or_expr() !Expr {
	start := p.curr
	mut left := p.parse_and_expr()!
	if p.curr.kind != .kw_or {
		return left
	}
	mut values := [left]
	for p.curr.kind == .kw_or {
		p.advance()!
		values << p.parse_and_expr()!
	}
	return BoolOpExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		op:     'Or'
		values: values
	}
}

fn (mut p Parser) parse_and_expr() !Expr {
	start := p.curr
	mut left := p.parse_not_expr()!
	if p.curr.kind != .kw_and {
		return left
	}
	mut values := [left]
	for p.curr.kind == .kw_and {
		p.advance()!
		values << p.parse_not_expr()!
	}
	return BoolOpExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		op:     'And'
		values: values
	}
}

fn (mut p Parser) parse_not_expr() !Expr {
	start := p.curr
	if p.curr.kind == .kw_not {
		p.advance()!
		operand := p.parse_not_expr()!
		return UnaryExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			op:      'Not'
			operand: operand
		}
	}
	return p.parse_comparison_expr()
}

fn (mut p Parser) parse_comparison_expr() !Expr {
	start := p.curr
	mut left := p.parse_bitor()!
	mut ops := []string{}
	mut comparators := []Expr{}
	for {
		op := p.comparison_op() or { break }
		ops << op
		comparators << p.parse_bitor()!
	}
	if ops.len == 0 {
		return left
	}
	return CompareExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		left:        left
		ops:         ops
		comparators: comparators
	}
}

// comparison_op consumes one comparison operator (one or two tokens) and
// reports its name, or none when the cursor is not on one.
fn (mut p Parser) comparison_op() ?string {
	if p.curr.kind == .kw_in {
		p.advance() or { return none }
		return 'In'
	}
	if p.curr.kind == .kw_is {
		p.advance() or { return none }
		if p.curr.kind == .kw_not {
			p.advance() or { return none }
			return 'IsNot'
		}
		return 'Is'
	}
	if p.curr.kind == .kw_not && p.next.kind == .kw_in {
		p.advance() or { return none }
		p.advance() or { return none }
		return 'NotIn'
	}
	op := match p.curr.kind {
		.lt { 'Lt' }
		.gt { 'Gt' }
		.le { 'LtE' }
		.ge { 'GtE' }
		.eqeq { 'Eq' }
		.noteq { 'NotEq' }
		else { return none }
	}
	p.advance() or { return none }
	return op
}

fn (mut p Parser) parse_bitor() !Expr {
	start := p.curr
	mut left := p.parse_bitxor()!
	for p.curr.kind == .pipe && p.next.kind != .assign {
		p.advance()!
		right := p.parse_bitxor()!
		left = BinaryExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			left:  left
			op:    'BitOr'
			right: right
		}
	}
	return left
}

fn (mut p Parser) parse_bitxor() !Expr {
	start := p.curr
	mut left := p.parse_bitand()!
	for p.curr.kind == .caret && p.next.kind != .assign {
		p.advance()!
		right := p.parse_bitand()!
		left = BinaryExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			left:  left
			op:    'BitXor'
			right: right
		}
	}
	return left
}

fn (mut p Parser) parse_bitand() !Expr {
	start := p.curr
	mut left := p.parse_shift()!
	for p.curr.kind == .amp && p.next.kind != .assign {
		p.advance()!
		right := p.parse_shift()!
		left = BinaryExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			left:  left
			op:    'BitAnd'
			right: right
		}
	}
	return left
}

fn (mut p Parser) parse_shift() !Expr {
	start := p.curr
	mut left := p.parse_additive()!
	for (p.curr.kind == .lshift || p.curr.kind == .rshift) && p.next.kind != .assign {
		op := if p.curr.kind == .lshift { 'LShift' } else { 'RShift' }
		p.advance()!
		right := p.parse_additive()!
		left = BinaryExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			left:  left
			op:    op
			right: right
		}
	}
	return left
}

fn (mut p Parser) parse_additive() !Expr {
	start := p.curr
	mut left := p.parse_multiplicative()!
	for (p.curr.kind == .plus || p.curr.kind == .minus) && p.next.kind != .assign {
		op := if p.curr.kind == .plus { 'Add' } else { 'Sub' }
		p.advance()!
		right := p.parse_multiplicative()!
		left = BinaryExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			left:  left
			op:    op
			right: right
		}
	}
	return left
}

fn (mut p Parser) parse_multiplicative() !Expr {
	start := p.curr
	mut left := p.parse_unary()!
	for (p.curr.kind == .star || p.curr.kind == .slash || p.curr.kind == .floordiv
		|| p.curr.kind == .percent || p.curr.kind == .at_sign) && p.next.kind != .assign {
		op := match p.curr.kind {
			.star { 'Mult' }
			.slash { 'Div' }
			.floordiv { 'FloorDiv' }
			.percent { 'Mod' }
			else { 'MatMult' }
		}
		p.advance()!
		right := p.parse_unary()!
		left = BinaryExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			left:  left
			op:    op
			right: right
		}
	}
	return left
}

fn (mut p Parser) parse_unary() !Expr {
	start := p.curr
	if p.curr.kind == .kw_await {
		p.advance()!
		return AwaitExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			value: p.parse_unary()!
		}
	}
	if p.curr.kind == .plus || p.curr.kind == .minus || p.curr.kind == .tilde {
		op := match p.curr.kind {
			.plus { 'UAdd' }
			.minus { 'USub' }
			else { 'Invert' }
		}
		p.advance()!
		return UnaryExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			op:      op
			operand: p.parse_power()!
		}
	}
	return p.parse_power()
}

fn (mut p Parser) parse_power() !Expr {
	start := p.curr
	base := p.parse_postfix()!
	if p.curr.kind != .pow || p.next.kind == .assign {
		return base
	}
	p.advance()!
	return BinaryExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		left:  base
		op:    'Pow'
		right: p.parse_unary()!
	}
}

fn (mut p Parser) parse_lambda_expr() !Expr {
	start := p.curr
	p.expect(.kw_lambda)!
	args := p.parse_params(true)!
	p.expect(.colon)!
	return LambdaExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		args: args
		body: p.parse_test()!
	}
}

fn (mut p Parser) parse_yield_expr() !Expr {
	start := p.curr
	p.expect(.kw_yield)!
	if p.curr.kind == .kw_from {
		p.advance()!
		return YieldFromExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			value: p.parse_expr()!
		}
	}
	if p.curr.kind == .newline || p.curr.kind == .eof || p.curr.kind == .rparen
		|| p.curr.kind == .rbracket || p.curr.kind == .rbrace || p.curr.kind == .comma
		|| p.curr.kind == .colon || p.curr.kind == .fstr_field_close {
		return YieldExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			value: none
		}
	}
	return YieldExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		value: p.parse_expr()!
	}
}

fn (mut p Parser) parse_postfix() !Expr {
	start := p.curr
	mut expr := p.parse_primary()!
	for {
		if p.curr.kind == .lparen {
			p.advance()!
			args, keywords := p.parse_call_args()!
			p.expect(.rparen)!
			expr = CallExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				func:     expr
				args:     args
				keywords: keywords
			}
			continue
		}
		if p.curr.kind == .dot {
			p.advance()!
			if p.curr.kind != .ident {
				return error('expected attribute name after dot')
			}
			attr := p.curr.text
			p.advance()!
			expr = AttributeExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				value: expr
				attr:  attr
			}
			continue
		}
		if p.curr.kind == .lbracket {
			p.advance()!
			slice := p.parse_subscript_slice()!
			p.expect(.rbracket)!
			expr = SubscriptExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				value: expr
				slice: slice
			}
			continue
		}
		break
	}
	return expr
}

fn (mut p Parser) parse_call_args() !([]Expr, []CallKeyword) {
	mut args := []Expr{}
	mut keywords := []CallKeyword{}
	if p.curr.kind == .rparen {
		return args, keywords
	}
	mut seen_keyword := false
	for {
		if p.curr.kind == .pow {
			pow_tok := p.curr
			p.advance()!
			keywords << CallKeyword{
				line: pow_tok.line,
				col: pow_tok.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				name:  none
				value: p.parse_test()!
			}
			seen_keyword = true
		} else {
			mut arg := p.parse_test()!
			if p.curr.kind == .kw_for || (p.curr.kind == .kw_async && p.next.kind == .kw_for) {
				generators := p.parse_comp_clauses()!
				gen_line, gen_col := expr_start_pos(arg)
				arg = GeneratorExpExpr{
					line: gen_line,
					col: gen_col,
					end_line: p.prev_real.end_line,
					end_col: p.prev_real.end_col,
					elt:        arg
					generators: generators
				}
			}
			if p.curr.kind == .assign {
				if arg is NameExpr {
					kw_name := arg as NameExpr
					p.advance()!
					keywords << CallKeyword{
						line: kw_name.line,
						col: kw_name.col,
						end_line: p.prev_real.end_line,
						end_col: p.prev_real.end_col,
						name:  kw_name.name
						value: p.parse_test()!
					}
					seen_keyword = true
				} else {
					return error('keyword argument must be a name')
				}
			} else {
				if seen_keyword {
					return error('positional argument follows keyword argument')
				}
				args << arg
			}
		}
		if p.curr.kind == .comma {
			p.advance()!
			if p.curr.kind == .rparen {
				break
			}
			continue
		}
		break
	}
	return args, keywords
}

// parse_subscript_slice parses `a`, `a:b`, `:b`, `a:`, `::c`, `...`, and
// comma-separated combinations (which form a Tuple).
fn (mut p Parser) parse_subscript_slice() !Expr {
	start := p.curr
	mut items := []Expr{}
	for {
		if p.curr.kind == .colon {
			items << p.parse_slice_rest(none)!
		} else if p.curr.kind == .rbracket || p.curr.kind == .comma {
			return error('expected subscript, found ${p.curr.kind}')
		} else {
			lower := p.parse_test()!
			if p.curr.kind == .colon {
				items << p.parse_slice_rest(lower)!
			} else {
				items << lower
			}
		}
		if p.curr.kind == .comma {
			p.advance()!
			if p.curr.kind == .rbracket {
				break
			}
			continue
		}
		break
	}
	if items.len == 1 {
		return items[0]
	}
	return TupleExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		elts: items
	}
}

fn (mut p Parser) parse_slice_rest(lower ?Expr) !Expr {
	start := p.curr
	p.expect(.colon)!
	mut upper := ?Expr(none)
	if p.curr.kind != .colon && p.curr.kind != .comma && p.curr.kind != .rbracket {
		upper = p.parse_test()!
	}
	mut step := ?Expr(none)
	if p.curr.kind == .colon {
		p.advance()!
		if p.curr.kind != .comma && p.curr.kind != .rbracket {
			step = p.parse_test()!
		}
	}
	return SliceExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		lower: lower
		upper: upper
		step:  step
	}
}

struct ParserState {
mut:
	pos           int
	curr          Token
	next          Token
	at_line_start bool
	brace_depth   int
	indent_stack  []int
	pending       []Token
	skip_newline  bool
}

fn (mut p Parser) save_state() ParserState {
	return ParserState{
		pos:           p.lexer.pos
		curr:          p.curr
		next:          p.next
		at_line_start: p.lexer.at_line_start
		brace_depth:   p.lexer.brace_depth
		indent_stack:  p.lexer.indent_stack.clone()
		pending:       p.lexer.pending.clone()
		skip_newline:  p.skip_stmt_newline
	}
}

fn (mut p Parser) restore_state(s ParserState) {
	p.lexer.pos = s.pos
	p.curr = s.curr
	p.next = s.next
	p.lexer.at_line_start = s.at_line_start
	p.lexer.brace_depth = s.brace_depth
	p.lexer.indent_stack = s.indent_stack.clone()
	p.lexer.pending = s.pending.clone()
	p.skip_stmt_newline = s.skip_newline
}

// is_name_token reports tokens usable where Python allows a plain name.
// `match` is a soft keyword, so it doubles as an identifier.
fn is_name_token(kind TokenKind) bool {
	return kind == .ident || kind == .underscore || kind == .kw_match
}

fn (mut p Parser) parse_name_text() !string {
	if p.curr.kind == .ident || p.curr.kind == .underscore {
		name := if p.curr.kind == .underscore { '_' } else { p.curr.text }
		p.advance()!
		return name
	}
	if p.curr.kind == .kw_match {
		p.advance()!
		return 'match'
	}
	return error('expected name, found ${p.curr.kind}')
}

fn (mut p Parser) parse_primary() !Expr {
	start := p.curr
	if p.curr.kind == .kw_match {
		state := p.save_state()
		m := p.parse_match_expr() or {
			p.restore_state(state)
			p.advance()!
			return NameExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				name: 'match'
			}
		}
		return m
	}
	return match p.curr.kind {
		.int_lit {
			value := parse_int_literal(p.curr.text) or {
					return error('invalid integer literal')
				}
			p.advance()!
			IntExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				value: value
			}
		}
		.float_lit {
			text := p.curr.text
			p.advance()!
			FloatExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				text: text
			}
		}
		.string_lit {
			p.parse_string_atom()
		}
		.bytes_lit {
			p.parse_bytes_atom()
		}
		.fstr_start {
			p.parse_string_atom()
		}
		.ident {
			name := p.curr.text
			p.advance()!
			NameExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				name: name
			}
		}
		.underscore {
			p.advance()!
			NameExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				name: '_'
			}
		}
		.kw_true {
			p.advance()!
			BoolExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				value: true
			}
		}
		.kw_false {
			p.advance()!
			BoolExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				value: false
			}
		}
		.kw_none {
			p.advance()!
			NoneExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
			}
		}
		.ellipsis {
			p.advance()!
			EllipsisExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
			}
		}
		.lparen {
			p.parse_paren_expr()
		}
		.lbracket {
			p.parse_list_expr()
		}
		.lbrace {
			p.parse_dict_or_set_expr()
		}
		else {
			return error('expected expression, found ${p.curr.kind}')
		}
	}
}

// parse_bytes_atom parses one bytes literal plus any immediately adjacent
// ones, which Python merges into a single constant.
fn (mut p Parser) parse_bytes_atom() !Expr {
	start := p.curr
	mut value := ''
	for p.curr.kind == .bytes_lit {
		value += p.curr.text
		p.advance()!
	}
	return BytesExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		value: value
	}
}

// parse_string_atom parses one string literal plus any immediately
// adjacent ones. Plain neighbors merge into a single Constant, matching
// builtin parsing; mixing in f-strings yields a JoinedStr.
fn (mut p Parser) parse_string_atom() !Expr {
	mut parts := []Expr{}
	for p.curr.kind == .string_lit || p.curr.kind == .fstr_start {
		if p.curr.kind == .string_lit {
			lit_tok := p.curr
			parts << StringExpr{
				line: lit_tok.line,
				col: lit_tok.col,
				end_line: lit_tok.end_line,
				end_col: lit_tok.end_col,
				value: p.curr.text
			}
			p.advance()!
		} else {
			joined := p.parse_fstring_expr()! as JoinedStrExpr
			for v in joined.values {
				parts << v
			}
		}
	}
	if parts.len == 0 {
		return error('expected string literal')
	}
	return merge_string_parts(parts)
}

fn merge_string_parts(parts []Expr) Expr {
	mut values := []Expr{}
	mut pending := ''
	mut has_pending := false
	mut pend_line := 0
	mut pend_col := 0
	mut pend_end_line := 0
	mut pend_end_col := 0
	for part in parts {
		if part is StringExpr {
			text_part := part as StringExpr
			if !has_pending {
				pend_line = text_part.line
				pend_col = text_part.col
			}
			pend_end_line = text_part.end_line
			pend_end_col = text_part.end_col
			pending += text_part.value
			has_pending = true
		} else {
			if has_pending {
				values << StringExpr{
					line: pend_line
					col: pend_col
					end_line: pend_end_line
					end_col: pend_end_col
					value: pending
				}
				pending = ''
				has_pending = false
			}
			values << part
		}
	}
	if has_pending {
		values << StringExpr{
			line: pend_line
			col: pend_col
			end_line: pend_end_line
			end_col: pend_end_col
			value: pending
		}
	}
	if values.len == 1 {
		if values[0] is StringExpr {
			return values[0]
		}
	}
	fl, fc := expr_start_pos(parts[0])
	el, ec := expr_end_pos(parts[parts.len - 1])
	return JoinedStrExpr{
		line: fl
		col: fc
		end_line: el
		end_col: ec
		values: values
	}
}

fn expr_start_pos(e Expr) (int, int) {
	return match e {
		AttributeExpr { e.line, e.col }
		AwaitExpr { e.line, e.col }
		BinaryExpr { e.line, e.col }
		BoolExpr { e.line, e.col }
		BoolOpExpr { e.line, e.col }
		BytesExpr { e.line, e.col }
		CallExpr { e.line, e.col }
		CompareExpr { e.line, e.col }
		DictCompExpr { e.line, e.col }
		DictExpr { e.line, e.col }
		EllipsisExpr { e.line, e.col }
		FloatExpr { e.line, e.col }
		FormattedValueExpr { e.line, e.col }
		GeneratorExpExpr { e.line, e.col }
		IfExpExpr { e.line, e.col }
		IntExpr { e.line, e.col }
		JoinedStrExpr { e.line, e.col }
		LambdaExpr { e.line, e.col }
		ListCompExpr { e.line, e.col }
		ListExpr { e.line, e.col }
		MatchExpr { e.line, e.col }
		NameExpr { e.line, e.col }
		NamedExpr { e.line, e.col }
		NoneExpr { e.line, e.col }
		SetCompExpr { e.line, e.col }
		SetExpr { e.line, e.col }
		SliceExpr { e.line, e.col }
		StarredExpr { e.line, e.col }
		StringExpr { e.line, e.col }
		SubscriptExpr { e.line, e.col }
		TupleExpr { e.line, e.col }
		UnaryExpr { e.line, e.col }
		YieldExpr { e.line, e.col }
		YieldFromExpr { e.line, e.col }
	}
}

fn expr_end_pos(e Expr) (int, int) {
	return match e {
		AttributeExpr { e.end_line, e.end_col }
		AwaitExpr { e.end_line, e.end_col }
		BinaryExpr { e.end_line, e.end_col }
		BoolExpr { e.end_line, e.end_col }
		BoolOpExpr { e.end_line, e.end_col }
		BytesExpr { e.end_line, e.end_col }
		CallExpr { e.end_line, e.end_col }
		CompareExpr { e.end_line, e.end_col }
		DictCompExpr { e.end_line, e.end_col }
		DictExpr { e.end_line, e.end_col }
		EllipsisExpr { e.end_line, e.end_col }
		FloatExpr { e.end_line, e.end_col }
		FormattedValueExpr { e.end_line, e.end_col }
		GeneratorExpExpr { e.end_line, e.end_col }
		IfExpExpr { e.end_line, e.end_col }
		IntExpr { e.end_line, e.end_col }
		JoinedStrExpr { e.end_line, e.end_col }
		LambdaExpr { e.end_line, e.end_col }
		ListCompExpr { e.end_line, e.end_col }
		ListExpr { e.end_line, e.end_col }
		MatchExpr { e.end_line, e.end_col }
		NameExpr { e.end_line, e.end_col }
		NamedExpr { e.end_line, e.end_col }
		NoneExpr { e.end_line, e.end_col }
		SetCompExpr { e.end_line, e.end_col }
		SetExpr { e.end_line, e.end_col }
		SliceExpr { e.end_line, e.end_col }
		StarredExpr { e.end_line, e.end_col }
		StringExpr { e.end_line, e.end_col }
		SubscriptExpr { e.end_line, e.end_col }
		TupleExpr { e.end_line, e.end_col }
		UnaryExpr { e.end_line, e.end_col }
		YieldExpr { e.end_line, e.end_col }
		YieldFromExpr { e.end_line, e.end_col }
	}
}

fn (mut p Parser) parse_paren_expr() !Expr {
	start := p.curr
	p.expect(.lparen)!
	if p.curr.kind == .rparen {
		p.advance()!
		return TupleExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			elts: []Expr{}
		}
	}
	first := p.parse_test()!
	if p.curr.kind == .kw_for || (p.curr.kind == .kw_async && p.next.kind == .kw_for) {
		generators := p.parse_comp_clauses()!
		p.expect(.rparen)!
		return GeneratorExpExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			elt:        first
			generators: generators
		}
	}
	if p.curr.kind != .comma {
		p.expect(.rparen)!
		return first
	}
	mut elts := [first]
	for p.curr.kind == .comma {
		p.advance()!
		if p.curr.kind == .rparen {
			break
		}
		elts << p.parse_test()!
	}
	p.expect(.rparen)!
	return TupleExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		elts: elts
	}
}

fn (mut p Parser) parse_list_expr() !Expr {
	start := p.curr
	p.expect(.lbracket)!
	if p.curr.kind == .rbracket {
		p.advance()!
		return ListExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			elts: []Expr{}
		}
	}
	first := p.parse_test()!
	if p.curr.kind == .kw_for || (p.curr.kind == .kw_async && p.next.kind == .kw_for) {
		generators := p.parse_comp_clauses()!
		p.expect(.rbracket)!
		return ListCompExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			elt:        first
			generators: generators
		}
	}
	mut elts := [first]
	for p.curr.kind == .comma {
		p.advance()!
		if p.curr.kind == .rbracket {
			break
		}
		elts << p.parse_test()!
	}
	p.expect(.rbracket)!
	return ListExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		elts: elts
	}
}

fn (mut p Parser) parse_dict_or_set_expr() !Expr {
	start := p.curr
	p.expect(.lbrace)!
	if p.curr.kind == .rbrace {
		p.advance()!
		return DictExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			keys:   []?Expr{}
			values: []Expr{}
		}
	}
	if p.curr.kind == .pow {
		return p.parse_dict_expr_none_key(start)
	}
	first := p.parse_test()!
	if p.curr.kind == .colon {
		return p.parse_dict_expr(first, start)!
	}
	if p.curr.kind == .kw_for || (p.curr.kind == .kw_async && p.next.kind == .kw_for) {
		generators := p.parse_comp_clauses()!
		p.expect(.rbrace)!
		return SetCompExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			elt:        first
			generators: generators
		}
	}
	mut elts := [first]
	for p.curr.kind == .comma {
		p.advance()!
		if p.curr.kind == .rbrace {
			break
		}
		elts << p.parse_test()!
	}
	p.expect(.rbrace)!
	return SetExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		elts: elts
	}
}

fn (mut p Parser) parse_dict_expr(first Expr, lbrace Token) !Expr {
	p.expect(.colon)!
	value := p.parse_test()!
	mut keys := [?Expr(first)]
	mut values := [value]
	if p.curr.kind == .kw_for || (p.curr.kind == .kw_async && p.next.kind == .kw_for) {
		generators := p.parse_comp_clauses()!
		p.expect(.rbrace)!
		return DictCompExpr{
			line: lbrace.line,
			col: lbrace.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			key:        first
			value:      value
			generators: generators
		}
	}
	for p.curr.kind == .comma {
		p.advance()!
		if p.curr.kind == .rbrace {
			break
		}
		if p.curr.kind == .pow {
			p.advance()!
			keys << ?Expr(none)
			values << p.parse_test()!
			continue
		}
		key := p.parse_test()!
		p.expect(.colon)!
		keys << key
		values << p.parse_test()!
	}
	p.expect(.rbrace)!
	return DictExpr{
		line: lbrace.line,
		col: lbrace.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		keys:   keys
		values: values
	}
}

fn (mut p Parser) parse_dict_expr_none_key(lbrace Token) !Expr {
	mut keys := []?Expr{}
	mut values := []Expr{}
	for {
		p.expect(.pow)!
		keys << ?Expr(none)
		values << p.parse_test()!
		if p.curr.kind == .comma {
			p.advance()!
			if p.curr.kind == .rbrace {
				break
			}
			if p.curr.kind == .pow {
				continue
			}
			key := p.parse_test()!
			p.expect(.colon)!
			keys << key
			values << p.parse_test()!
			if p.curr.kind == .comma {
				p.advance()!
				if p.curr.kind == .rbrace {
					break
				}
				continue
			}
			break
		}
		break
	}
	p.expect(.rbrace)!
	return DictExpr{
		line: lbrace.line,
		col: lbrace.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		keys:   keys
		values: values
	}
}

	// parse_comp_target parses for-loop and comprehension targets. It
	// mirrors parse_expr but never consumes a bare `in`, which would
	// otherwise parse `for i in x` as a comparison.
	fn (mut p Parser) parse_comp_target() !Expr {
		start := p.curr
		first := p.parse_comp_target_atom()!
		if p.curr.kind != .comma {
			return first
		}
		mut elts := [first]
		for p.curr.kind == .comma {
			p.advance()!
			if p.curr.kind == .rparen || p.curr.kind == .rbracket
				|| p.curr.kind == .rbrace || p.curr.kind == .newline
				|| p.curr.kind == .eof {
					break
			}
			elts << p.parse_comp_target_atom()!
		}
		return TupleExpr{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			elts: elts
		}
	}

	fn (mut p Parser) parse_comp_target_atom() !Expr {
		start := p.curr
		if p.curr.kind == .star {
			p.advance()!
			return StarredExpr{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				value: p.parse_bitor()!
			}
		}
		return p.parse_bitor()
	}

fn (mut p Parser) parse_comp_clauses() ![]ComprehensionClause {
	start := p.curr
	mut clauses := []ComprehensionClause{}
	for p.curr.kind == .kw_for || (p.curr.kind == .kw_async && p.next.kind == .kw_for) {
		mut is_async := false
		if p.curr.kind == .kw_async {
			is_async = true
			p.advance()!
		}
		p.expect(.kw_for)!
		target := p.parse_comp_target()!
		if !is_assign_target(target) {
			return error('invalid comprehension target')
		}
		if p.curr.kind == .kw_in {
			p.advance()!
		} else {
			return error('expected in after comprehension target')
		}
		iter := p.parse_or_expr()!
		mut ifs := []Expr{}
		for p.curr.kind == .kw_if {
			p.advance()!
			ifs << p.parse_or_expr()!
		}
		clauses << ComprehensionClause{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			target:   target
			iter:     iter
			ifs:      ifs
			is_async: is_async
		}
	}
	if clauses.len == 0 {
		return error('expected at least one for clause in comprehension')
	}
	return clauses
}

fn (mut p Parser) parse_fstring_expr() !Expr {
	start := p.curr
	p.expect(.fstr_start)!
	mut values := []Expr{}
	for p.curr.kind != .fstr_end {
		if p.curr.kind == .eof {
			return error('unterminated f-string')
		}
		if p.curr.kind == .fstr_text {
			text_tok := p.curr
			values << StringExpr{
				line: text_tok.line,
				col: text_tok.col,
				end_line: text_tok.end_line,
				end_col: text_tok.end_col,
				value: p.curr.text
			}
			p.advance()!
			continue
			}
		if p.curr.kind == .fstr_field_open {
			field_tok := p.curr
			p.advance()!
			value := p.parse_expr()!
			mut conversion := -1
			if p.curr.kind == .fstr_bang {
				conversion = p.curr.text.int()
				p.advance()!
			}
			mut format_spec := ?Expr(none)
			if p.curr.kind == .fstr_spec {
				spec_tok := p.curr
				format_spec = JoinedStrExpr{
					line: spec_tok.line,
					col: spec_tok.col,
					end_line: spec_tok.end_line,
					end_col: spec_tok.end_col,
					values: [
						Expr(StringExpr{
							line: spec_tok.line,
							col: spec_tok.col,
							end_line: spec_tok.end_line,
							end_col: spec_tok.end_col,
							value: p.curr.text
						}),
					]
				}
				p.advance()!
			}
			p.expect(.fstr_field_close)!
			values << FormattedValueExpr{
				line: field_tok.line,
				col: field_tok.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				value:      value
				conversion: conversion
				format_spec: format_spec
			}
			continue
		}
		return error('expected f-string text or replacement field, found ${p.curr.kind}')
	}
	p.expect(.fstr_end)!
	return JoinedStrExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		values: values
	}
}

fn (mut p Parser) parse_match_expr() !Expr {
	p.expect(.kw_match)!
	subject := p.parse_expr()!
	if p.curr.kind == .colon {
		return p.parse_indented_match_cases(subject)
	}
	return error('expected ":" after match subject')
}

fn (mut p Parser) parse_indented_match_cases(subject Expr) !Expr {
	start := p.curr
	p.expect(.colon)!
	p.expect(.newline)!
	p.expect(.indent)!
	mut cases := []MatchCase{}
	p.consume_newlines()!
	for is_pattern_start(p.curr.kind) {
		pattern := p.parse_pattern()!
		p.expect(.colon)!
		body := p.parse_match_case_body()!
		p.consume_newlines()!
		cases << MatchCase{
			line: start.line,
			col: start.col,
			end_line: p.prev_real.end_line,
			end_col: p.prev_real.end_col,
			pattern: pattern
			body:    body
		}
	}
	if cases.len == 0 {
		return error('indented match expression needs at least one case')
	}
	p.expect(.dedent)!
	p.skip_stmt_newline = true
	return MatchExpr{
		line: start.line,
		col: start.col,
		end_line: p.prev_real.end_line,
		end_col: p.prev_real.end_col,
		subject: subject
		cases:   cases
	}
}

fn (mut p Parser) parse_match_case_body() !Expr {
	if p.curr.kind == .newline {
		p.expect(.newline)!
		p.expect(.indent)!
		body := p.parse_expr()!
		if p.skip_stmt_newline {
			p.skip_stmt_newline = false
		} else if p.curr.kind == .newline {
			p.expect(.newline)!
		}
		p.consume_newlines()!
		p.expect(.dedent)!
		return body
	}

	body := p.parse_expr()!
	if p.skip_stmt_newline {
		p.skip_stmt_newline = false
	} else {
		p.expect(.newline)!
	}
	return body
}

fn (mut p Parser) parse_pattern() !Pattern {
	start := p.curr
	return match p.curr.kind {
		.underscore {
			p.advance()!
			WildcardPattern{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
			}
		}
		.int_lit {
			value := strconv.atoi(p.curr.text) or { return error('invalid integer literal') }
			p.advance()!
			ValuePattern{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				value: value
			}
		}
		.ident {
			name := p.curr.text
			p.advance()!
			BindPattern{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				name: name
			}
		}
		.kw_match {
			p.advance()!
			BindPattern{
				line: start.line,
				col: start.col,
				end_line: p.prev_real.end_line,
				end_col: p.prev_real.end_col,
				name: 'match'
			}
		}
		else {
			return error('expected pattern, found ${p.curr.kind}')
		}
	}
}

fn is_pattern_start(kind TokenKind) bool {
	return kind == .underscore || kind == .int_lit || kind == .ident
}

fn (mut p Parser) consume_newlines() ! {
	for p.curr.kind == .newline {
		p.advance()!
	}
}

fn (mut p Parser) expect(kind TokenKind) ! {
	if p.curr.kind != kind {
		return error('expected ${kind}, found ${p.curr.kind}')
	}
	p.advance()!
}

fn (mut p Parser) advance() ! {
	if p.curr.kind !in [.indent, .dedent, .newline, .eof] {
		p.prev_real = p.curr
	}
	p.curr = p.next
	p.next = p.lexer.next_token()!
}

fn json_escape(s string) string {
	mut out := ''
	for i := 0; i < s.len; i++ {
		ch := s[i]
		out += match ch {
			`\\` { '\\\\' }
			`"` { '\\"' }
			`\n` { '\\n' }
			`\t` { '\\t' }
			else { ch.ascii_str() }
		}
	}
	return out
}

fn exprs_json(elts []Expr) string {
	mut parts := []string{}
	for e in elts {
		parts << expr_json(e)
	}
	return '[${parts.join(',')}]'
}

fn opt_expr_json(e ?Expr) string {
	if v := e {
		return expr_json(v)
	}
	return 'null'
}

fn stmts_json(body []Stmt) string {
	mut parts := []string{}
	for s in body {
		parts << stmt_json(s)
	}
	return '[${parts.join(',')}]'
}

fn arg_json(a FunctionArg) string {
	return '{"type":"arg","arg":"${json_escape(a.name)}","annotation":${opt_expr_json(a.annotation)},"line":${a.line},"col":${a.col},"end_line":${a.end_line},"end_col":${a.end_col}}'
}

fn args_json(a FunctionArgs) string {
	mut posonly := []string{}
	for x in a.posonlyargs {
		posonly << arg_json(x)
	}
	mut plain := []string{}
	for x in a.args {
		plain << arg_json(x)
	}
	mut vararg := 'null'
	if v := a.vararg {
		vararg = arg_json(v)
	}
	mut kwonly := []string{}
	for x in a.kwonlyargs {
		kwonly << arg_json(x)
	}
	mut kw_defaults := []string{}
	for d in a.kw_defaults {
		kw_defaults << opt_expr_json(d)
	}
	mut kwarg := 'null'
	if v := a.kwarg {
		kwarg = arg_json(v)
	}
	mut defaults := []string{}
	for d in a.defaults {
		defaults << expr_json(d)
	}
	return '{"posonlyargs":[${posonly.join(',')}],"args":[${plain.join(',')}],"vararg":${vararg},"kwonlyargs":[${kwonly.join(',')}],"kw_defaults":[${kw_defaults.join(',')}],"kwarg":${kwarg},"defaults":[${defaults.join(',')}],"line":${a.line},"col":${a.col},"end_line":${a.end_line},"end_col":${a.end_col}}'
}

fn keyword_json(k CallKeyword) string {
	if name := k.name {
		return '{"arg":"${json_escape(name)}","value":${expr_json(k.value)},"line":${k.line},"col":${k.col},"end_line":${k.end_line},"end_col":${k.end_col}}'
	}
	return '{"arg":null,"value":${expr_json(k.value)},"line":${k.line},"col":${k.col},"end_line":${k.end_line},"end_col":${k.end_col}}'
}

fn comp_json(c ComprehensionClause) string {
	mut ifs := []string{}
	for cond in c.ifs {
		ifs << expr_json(cond)
	}
	async_flag := if c.is_async { '1' } else { '0' }
	return '{"type":"comprehension","target":${expr_json(c.target)},"iter":${expr_json(c.iter)},"ifs":[${ifs.join(',')}],"is_async":${async_flag},"line":${c.line},"col":${c.col},"end_line":${c.end_line},"end_col":${c.end_col}}'
}

fn expr_json(expr Expr) string {
	return match expr {
		IntExpr {
			'{"type":"Constant","value":${expr.value},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		FloatExpr {
			'{"type":"Float","value":${expr.text},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		StringExpr {
			'{"type":"Constant","value":"${json_escape(expr.value)}","line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		BytesExpr {
			mut byte_parts := []string{}
			for b in expr.value.bytes() {
				byte_parts << b.str()
			}
			'{"type":"Bytes","value":[${byte_parts.join(',')}],"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		BoolExpr {
			val := if expr.value { 'true' } else { 'false' }
			'{"type":"Constant","value":${val},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		NoneExpr {
			'{"type":"Constant","value":null,"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		EllipsisExpr {
			'{"type":"Ellipsis","line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		NameExpr {
			'{"type":"Name","id":"${json_escape(expr.name)}","line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		CallExpr {
			mut call_args_json := []string{}
			for a in expr.args {
				call_args_json << expr_json(a)
			}
			mut kw_json := []string{}
			for k in expr.keywords {
				kw_json << keyword_json(k)
			}
			'{"type":"Call","func":${expr_json(expr.func)},"args":[${call_args_json.join(',')}],"keywords":[${kw_json.join(',')}],"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col} }'
		}
		AttributeExpr {
			'{"type":"Attribute","value":${expr_json(expr.value)},"attr":"${json_escape(expr.attr)}","line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		SubscriptExpr {
			'{"type":"Subscript","value":${expr_json(expr.value)},"slice":${expr_json(expr.slice)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		StarredExpr {
			'{"type":"Starred","value":${expr_json(expr.value)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		SliceExpr {
			'{"type":"Slice","lower":${opt_expr_json(expr.lower)},"upper":${opt_expr_json(expr.upper)},"step":${opt_expr_json(expr.step)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		UnaryExpr {
			'{"type":"UnaryOp","op":"${expr.op}","operand":${expr_json(expr.operand)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		BinaryExpr {
			'{"type":"BinOp","left":${expr_json(expr.left)},"op":"${expr.op}","right":${expr_json(expr.right)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		BoolOpExpr {
			mut values_json := []string{}
			for v in expr.values {
				values_json << expr_json(v)
			}
			'{"type":"BoolOp","op":"${expr.op}","values":[${values_json.join(',')}],"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col} }'
		}
		CompareExpr {
			mut ops_json := []string{}
			for op in expr.ops {
				ops_json << '"${op}"'
			}
			mut cmps_json := []string{}
			for c in expr.comparators {
				cmps_json << expr_json(c)
			}
			'{"type":"Compare","left":${expr_json(expr.left)},"ops":[${ops_json.join(',')}],"comparators":[${cmps_json.join(',')}],"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col} }'
			}
		IfExpExpr {
			'{"type":"IfExp","test":${expr_json(expr.test)},"body":${expr_json(expr.body)},"orelse":${expr_json(expr.orelse)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		NamedExpr {
			'{"type":"NamedExpr","target":"${json_escape(expr.target)}","value":${expr_json(expr.value)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		LambdaExpr {
			'{"type":"Lambda","args":${args_json(expr.args)},"body":${expr_json(expr.body)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		YieldExpr {
			'{"type":"Yield","value":${opt_expr_json(expr.value)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		YieldFromExpr {
			'{"type":"YieldFrom","value":${expr_json(expr.value)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		AwaitExpr {
			'{"type":"Await","value":${expr_json(expr.value)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		ListExpr {
			'{"type":"List","elts":${exprs_json(expr.elts)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		TupleExpr {
			'{"type":"Tuple","elts":${exprs_json(expr.elts)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		SetExpr {
			'{"type":"Set","elts":${exprs_json(expr.elts)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		DictExpr {
			mut keys_json := []string{}
			for k in expr.keys {
				keys_json << opt_expr_json(k)
			}
			mut values_json := []string{}
			for v in expr.values {
				values_json << expr_json(v)
			}
			'{"type":"Dict","keys":[${keys_json.join(',')}],"values":[${values_json.join(',')}],"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col} }'
			}
		ListCompExpr {
			mut gen_json := []string{}
			for g in expr.generators {
				gen_json << comp_json(g)
			}
			'{"type":"ListComp","elt":${expr_json(expr.elt)},"generators":[${gen_json.join(',')}],"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col} }'
			}
		SetCompExpr {
			mut gen_json := []string{}
			for g in expr.generators {
				gen_json << comp_json(g)
			}
			'{"type":"SetComp","elt":${expr_json(expr.elt)},"generators":[${gen_json.join(',')}],"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col} }'
			}
		GeneratorExpExpr {
			mut gen_json := []string{}
			for g in expr.generators {
				gen_json << comp_json(g)
			}
			'{"type":"GeneratorExp","elt":${expr_json(expr.elt)},"generators":[${gen_json.join(',')}],"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col} }'
			}
		DictCompExpr {
			mut gen_json := []string{}
			for g in expr.generators {
				gen_json << comp_json(g)
			}
			'{"type":"DictComp","key":${expr_json(expr.key)},"value":${expr_json(expr.value)},"generators":[${gen_json.join(',')}],"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col} }'
			}
		JoinedStrExpr {
			'{"type":"JoinedStr","values":${exprs_json(expr.values)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		FormattedValueExpr {
			'{"type":"FormattedValue","value":${expr_json(expr.value)},"conversion":${expr.conversion},"format_spec":${opt_expr_json(expr.format_spec)},"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col}}'
		}
		MatchExpr {
			mut cases_json := []string{}
			for item in expr.cases {
				cases_json << '{"type":"match_case","pattern":${pattern_json(item.pattern)},"body":${expr_json(item.body)},"line":${item.line},"col":${item.col},"end_line":${item.end_line},"end_col":${item.end_col}}'
			}
			'{"type":"Match","subject":${expr_json(expr.subject)},"cases":[${cases_json.join(',')}],"line":${expr.line},"col":${expr.col},"end_line":${expr.end_line},"end_col":${expr.end_col} }'
			}
	}
}

fn pattern_json(pattern Pattern) string {
	return match pattern {
		WildcardPattern { '{"type":"MatchAs","name":null,"line":${pattern.line},"col":${pattern.col},"end_line":${pattern.end_line},"end_col":${pattern.end_col}}' }
		BindPattern { '{"type":"MatchAs","name":"${json_escape(pattern.name)}","line":${pattern.line},"col":${pattern.col},"end_line":${pattern.end_line},"end_col":${pattern.end_col}}' }
		ValuePattern { '{"type":"MatchValue","value":{"type":"Constant","value":${pattern.value}},"line":${pattern.line},"col":${pattern.col},"end_line":${pattern.end_line},"end_col":${pattern.end_col}}' }
	}
}

fn alias_json(alias ImportAlias) string {
	if alias.asname == '' {
		return '{"type":"alias","name":"${json_escape(alias.name)}","asname":null,"line":${alias.line},"col":${alias.col},"end_line":${alias.end_line},"end_col":${alias.end_col}}'
	}
	return '{"type":"alias","name":"${json_escape(alias.name)}","asname":"${json_escape(alias.asname)}","line":${alias.line},"col":${alias.col},"end_line":${alias.end_line},"end_col":${alias.end_col}}'
}

fn stmt_json(stmt Stmt) string {
	return match stmt {
		ExprStmt {
			'{"type":"Expr","value":${expr_json(stmt.value)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col}}'
		}
		ImportStmt {
			mut names_json := []string{}
			for n in stmt.names {
				names_json << alias_json(n)
			}
			'{"type":"Import","names":[${names_json.join(',')}],"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col} }'
		}
		ImportFromStmt {
			mut names_json := []string{}
			for n in stmt.names {
				names_json << alias_json(n)
			}
			'{"type":"ImportFrom","module":"${json_escape(stmt.module)}","level":${stmt.level},"names":[${names_json.join(',')}],"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col} }'
			}
		AssignStmt {
			'{"type":"Assign","targets":${exprs_json(stmt.targets)},"value":${expr_json(stmt.value)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col}}'
		}
		AugAssignStmt {
			'{"type":"AugAssign","target":${expr_json(stmt.target)},"op":"${stmt.op}","value":${expr_json(stmt.value)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col}}'
		}
		AnnAssignStmt {
			simple_flag := if stmt.simple { '1' } else { '0' }
			'{"type":"AnnAssign","target":${expr_json(stmt.target)},"annotation":${expr_json(stmt.annotation)},"value":${opt_expr_json(stmt.value)},"simple":${simple_flag},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col}}'
		}
		PassStmt {
			'{"type":"Pass","line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col}}'
		}
		BreakStmt {
			'{"type":"Break","line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col}}'
		}
		ContinueStmt {
			'{"type":"Continue","line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col}}'
		}
		ReturnStmt {
			'{"type":"Return","value":${opt_expr_json(stmt.value)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col}}'
		}
		AssertStmt {
			'{"type":"Assert","test":${expr_json(stmt.test)},"msg":${opt_expr_json(stmt.msg)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col}}'
		}
		DeleteStmt {
			'{"type":"Delete","targets":${exprs_json(stmt.targets)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col}}'
		}
		RaiseStmt {
			'{"type":"Raise","exc":${opt_expr_json(stmt.exc)},"cause":${opt_expr_json(stmt.cause)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col}}'
		}
		GlobalStmt {
			mut names_json := []string{}
			for n in stmt.names {
				names_json << '"${json_escape(n)}"'
			}
			'{"type":"Global","names":[${names_json.join(',')}],"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col} }'
			}
		NonlocalStmt {
			mut names_json := []string{}
			for n in stmt.names {
				names_json << '"${json_escape(n)}"'
			}
			'{"type":"Nonlocal","names":[${names_json.join(',')}],"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col} }'
			}
		TryStmt {
			mut handlers_json := []string{}
			for h in stmt.handlers {
				handlers_json << except_json(h)
			}
			typ := if stmt.is_star { 'TryStar' } else { 'Try' }
			'{"type":"${typ}","body":${stmts_json(stmt.body)},"handlers":[${handlers_json.join(',')}],"orelse":${stmts_json(stmt.orelse)},"finalbody":${stmts_json(stmt.finalbody)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col} }'
			}
		WithStmt {
			mut items_json := []string{}
			for item in stmt.items {
				items_json << withitem_json(item)
			}
			typ := if stmt.is_async { 'AsyncWith' } else { 'With' }
			'{"type":"${typ}","items":[${items_json.join(',')}],"body":${stmts_json(stmt.body)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col} }'
			}
		IfStmt {
			'{"type":"If","test":${expr_json(stmt.test)},"body":${stmts_json(stmt.body)},"orelse":${stmts_json(stmt.orelse)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col} }'
			}
		WhileStmt {
			'{"type":"While","test":${expr_json(stmt.test)},"body":${stmts_json(stmt.body)},"orelse":${stmts_json(stmt.orelse)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col} }'
			}
		ForStmt {
			typ := if stmt.is_async { 'AsyncFor' } else { 'For' }
			'{"type":"${typ}","target":${expr_json(stmt.target)},"iter":${expr_json(stmt.iter)},"body":${stmts_json(stmt.body)},"orelse":${stmts_json(stmt.orelse)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col} }'
			}
		FunctionDefStmt {
			typ := if stmt.is_async { 'AsyncFunctionDef' } else { 'FunctionDef' }
			mut deco_json := []string{}
			for d in stmt.decorator_list {
				deco_json << expr_json(d)
			}
			'{"type":"${typ}","name":"${json_escape(stmt.name)}","args":${args_json(stmt.args)},"body":${stmts_json(stmt.body)},"decorator_list":[${deco_json.join(',')}],"returns":${opt_expr_json(stmt.returns)},"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col} }'
			}
		ClassDefStmt {
			mut bases_json := []string{}
			for b in stmt.bases {
				bases_json << expr_json(b)
			}
			mut kw_json := []string{}
			for k in stmt.keywords {
				kw_json << keyword_json(k)
			}
			mut deco_json := []string{}
			for d in stmt.decorator_list {
				deco_json << expr_json(d)
			}
			'{"type":"ClassDef","name":"${json_escape(stmt.name)}","bases":[${bases_json.join(',')}],"keywords":[${kw_json.join(',')}],"body":${stmts_json(stmt.body)},"decorator_list":[${deco_json.join(',')}],"line":${stmt.line},"col":${stmt.col},"end_line":${stmt.end_line},"end_col":${stmt.end_col} }'
			}
	}
}

fn except_json(h ExceptHandler) string {
	name_json := if h.name == '' { 'null' } else { '"${json_escape(h.name)}"' }
	return '{"type":"ExceptHandler","typ":${opt_expr_json(h.typ)},"name":${name_json},"body":${stmts_json(h.body)},"line":${h.line},"col":${h.col},"end_line":${h.end_line},"end_col":${h.end_col}}'
}

fn withitem_json(item WithItem) string {
	return '{"type":"withitem","context_expr":${expr_json(item.context_expr)},"vars":${opt_expr_json(item.vars)},"line":${item.line},"col":${item.col},"end_line":${item.end_line},"end_col":${item.end_col}}'
}

fn module_json(mod Module) string {
	mut body_json := []string{}
	for s in mod.body {
		body_json << stmt_json(s)
	}
	return '{"type":"Module","body":[${body_json.join(',')}]} '
}
