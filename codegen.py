import sys
# -*- coding: utf-8 -*-
"""
Parse Racket Rosette output like:
(define (impl-fast srcip dstip proto sport dport) <BODY>)
into a JSON-ready AST, validated against the grammar you provided.

No external dependencies.
"""

import re
import json

# -------------------------
# 1) A tiny S-expression parser (string -> nested lists/atoms)
# -------------------------

_TOKEN = re.compile(r"""\s*(
    ;[^\n]*              |   # ; 到行尾/EOF 的注释（不强制结尾换行）
    \(|\)                |   # 括号
    "#t"|#t|"#f"|#f      |   # 布尔
    "[^"\\]*(?:\\.[^"\\]*)*" | # 字符串（简单转义）
    [^\s()]+                 # 其它原子：符号、#x...、数字等
)""", re.VERBOSE)

def tokenize(s: str):
    pos, n = 0, len(s)
    while pos < n:
        m = _TOKEN.match(s, pos)
        if not m:
            # 如果剩余都是空白，就正常结束；否则报错
            if s[pos:].strip() == "":
                break
            raise SyntaxError(f"Unexpected char at {pos}: {s[pos:pos+20]!r}")
        tok = m.group(1)
        pos = m.end()
        # 跳过注释
        if tok.startswith(';'):
            continue
        yield tok

def parse_sexprs(s):
    tokens = list(tokenize(s))
    idx = 0

    def parse():
        nonlocal idx
        if idx >= len(tokens): raise SyntaxError("Unexpected EOF")
        tok = tokens[idx]; idx += 1
        if tok == '(':
            lst = []
            while True:
                if idx >= len(tokens):
                    raise SyntaxError("Unclosed '('")
                if tokens[idx] == ')':
                    idx += 1
                    return lst
                lst.append(parse())
        elif tok == ')':
            raise SyntaxError("Unexpected ')'")
        else:
            return atom(tok)

    def atom(tok):
        if tok in ('#t', '"#t"'): return True
        if tok in ('#f', '"#f"'): return False
        if tok.startswith('"') and tok.endswith('"'):
            # unescape minimal
            return bytes(tok[1:-1], 'utf-8').decode('unicode_escape')
        return tok  # leave symbol/hex as str

    # Many top-level forms? Return list
    forms = []
    while idx < len(tokens):
        forms.append(parse())
    return forms

# -------------------------
# 2) AST normalization (nested lists -> typed dicts)
# -------------------------

def is_symbol(x, name=None):
    return isinstance(x, str) and (name is None or x == name)

def is_list(x, n=None):
    return isinstance(x, list) and (n is None or len(x) == n)

def expect(cond, msg):
    if not cond: raise ValueError(msg)

def to_ast(x):
    # atoms
    if x is True: return {'type': 'bool', 'value': True}
    if x is False: return {'type': 'bool', 'value': False}
    if isinstance(x, str):  # symbol or raw token like #x... hex literal token (handled inside bv)
        return {'type': 'sym', 'name': x}

    # lists (call forms)
    expect(is_list(x) and x, f"Bad form: {x}")
    head = x[0]

    # (define (impl-fast args...) body)
    if is_symbol(head, 'define'):
        expect(len(x) == 3, f"(define ...) arity: {x}")
        fun = x[1]
        body = x[2]
        expect(is_list(fun) and len(fun) >= 1, f"define head must be (name args...): {fun}")
        expect(is_symbol(fun[0]), f"function name symbol expected: {fun[0]}")
        name = fun[0]
        args = fun[1:]
        for a in args:
            expect(is_symbol(a), f"arg must be symbol: {a}")
        return {
            'type': 'define',
            'name': name,
            'params': args,
            'body': to_ast(body)
        }

    # General call
    expect(is_symbol(head), f"head symbol expected: {head}")
    op = head

    # (if c t e)
    if op == 'if':
        expect(len(x) == 4, f"(if c t e) arity: {x}")
        return {'type': 'if', 'cond': to_ast(x[1]), 'then': to_ast(x[2]), 'else': to_ast(x[3])}

    # (and a b c ...)
    if op == 'and':
        return {'type': 'and', 'args': [to_ast(a) for a in x[1:]]}

    # (equal? a b)
    if op == 'equal?':
        expect(len(x) == 3, f"(equal? a b) arity: {x}")
        return {'type': 'equal', 'left': to_ast(x[1]), 'right': to_ast(x[2])}

    # (bv HEX 32)
    if op == 'bv':
        expect(len(x) == 3, f"(bv HEX WIDTH) arity: {x}")
        hex_tok = x[1]
        width = x[2]
        expect(is_symbol(hex_tok) and hex_tok.startswith('#x'), f"bv hex like #x...: {hex_tok}")
        expect(is_symbol(width) and width.isdigit(), f"bv width int: {width}")
        value = int(hex_tok[2:], 16)
        return {'type': 'bv', 'value': value, 'width': int(width)}

    # (packet a b c d e)
    if op == 'packet':
        expect(len(x) == 6, f"(packet 5-args) arity: {x}")
        return {
            'type': 'packet',
            'srcip': to_ast(x[1]),
            'dstip': to_ast(x[2]),
            'proto': to_ast(x[3]),
            'sport': to_ast(x[4]),
            'dport': to_ast(x[5]),
        }

    # (cons a b)
    if op == 'cons':
        expect(len(x) == 3, f"(cons a b) arity: {x}")
        return {'type': 'cons', 'car': to_ast(x[1]), 'cdr': to_ast(x[2])}

    # fallback: generic call
    return {'type': 'call', 'op': op, 'args': [to_ast(a) for a in x[1:]]}

# -------------------------
# 3) Grammar validation (Impl_grammar)
#    Categories: int32?, vexpr, cond-expr, expr
# -------------------------

def is_int32(node):
    return isinstance(node, dict) and node.get('type') == 'bv' and node.get('width') == 32

def is_sym_in(node, allowed):
    return node.get('type') == 'sym' and node.get('name') in allowed

def is_vexpr(node, symset):
    # vexpr ::= src_sym | dst_sym | proto_sym | sport_sym | dport_sym | int32?
    return (
        is_sym_in(node, symset) or
        is_int32(node)
    )

def is_cond_expr(node, symset):
    # cond-expr ::= #t | (equal? v v) | (and c c c c c)
    t = node.get('type')
    if t == 'bool' and node.get('value') is True:
        return True
    if t == 'equal':
        return is_vexpr(node['left'], symset) and is_vexpr(node['right'], symset)
    if t == 'and':
        args = node['args']
        if len(args) != 5:  # grammar requires 5 in the sample
            return False
        return all(is_cond_expr(a, symset) for a in args)
    # allow nested cond-expr via (and ...) already; other forms not allowed
    return False

def is_expr(node, symset):
    # expr ::= (if cond-expr expr expr)
    #       |  (cons int32? (packet src_fin dst_fin proto_fin sport_fin dport_fin))
    t = node.get('type')
    if t == 'if':
        return is_cond_expr(node['cond'], symset) and is_expr(node['then'], symset) and is_expr(node['else'], symset)
    if t == 'cons':
        car_ok = is_int32(node['car'])
        cdr = node['cdr']
        if cdr.get('type') != 'packet':
            return False
        # src_fin/dst_fin/... ::= choose {symbol in symset OR int32?}
        def fin_ok(n):
            return is_sym_in(n, symset) or is_int32(n)
        return car_ok and all([
            fin_ok(cdr['srcip']),
            fin_ok(cdr['dstip']),
            fin_ok(cdr['proto']),
            fin_ok(cdr['sport']),
            fin_ok(cdr['dport']),
        ])
    return False

def validate_top_define(ast):
    """Ensure it's (define (impl-fast srcip dstip proto sport dport) expr) and expr fits grammar."""
    expect(ast.get('type') == 'define' and ast.get('name') == 'impl-fast',
           "Top-level must be (define (impl-fast ...) ...)")
    params = ast['params']
    expect(params == ['srcip', 'dstip', 'proto', 'sport', 'dport'],
           f"Params must be srcip dstip proto sport dport, got {params}")
    symset = set(params)
    expect(is_expr(ast['body'], symset), "Body does not conform to Impl_grammar expr")
    return True

# -------------------------
# 4) Convenience function: input string -> JSON AST (validated)
# -------------------------

def parse_impl_fast_to_json(code: str):
    forms = parse_sexprs(code)
    # 找到 (define (impl-fast ... ) ...)
    target = None
    for f in forms:
        if isinstance(f, list) and len(f) >= 3 and f[0] == 'define' and isinstance(f[1], list) and f[1][0] == 'impl-fast':
            target = f; break
    if target is None:
        raise ValueError("No (define (impl-fast ...) ...) found.")
    ast = to_ast(target)
    validate_top_define(ast)
    return ast

# -------------------------
# 5) Demo
# -------------------------
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 codegen.py <input_file>")
        sys.exit(1)

    input_file = sys.argv[1]

    with open(input_file, "r") as f:
        lines = f.readlines()

    # Skip the first line and join the rest into one string
    sample = "".join(lines[1:])

    ast = parse_impl_fast_to_json(sample)
    print(json.dumps(ast, ensure_ascii=False, indent=2))
