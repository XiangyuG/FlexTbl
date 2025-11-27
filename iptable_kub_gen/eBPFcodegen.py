#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import json
import re
from sexpdata import loads, Symbol

def sym_name(x):
    return x.value() if isinstance(x, Symbol) else x

def is_sym(x, name: str) -> bool:
    return isinstance(x, Symbol) and x.value() == name

# ========== bitvector 解析 ==========

def parse_bv(sexp):
    return {
        "type": "bv",
        "value": int(sexp[1]),
        "width": int(sexp[2]),
    }

# ========== 表达式 AST 构建 ==========

def parse_expr(sexp):
    if isinstance(sexp, Symbol):
        return {"type": "var", "name": sexp.value()}

    if isinstance(sexp, int):
        return {"type": "int", "value": sexp}

    if isinstance(sexp, list):
        if not sexp:
            return {"type": "empty"}

        head = sexp[0]

        # (bv N W)
        if is_sym(head, "bv"):
            return parse_bv(sexp)

        # (bvand ...), (bvor ...), (bveq ...)
        if isinstance(head, Symbol) and head.value() in ("bvand", "bvor", "bveq"):
            return {
                "type": head.value(),
                "left": parse_expr(sexp[1]),
                "right": parse_expr(sexp[2]),
            }

        # (cond ...)
        if is_sym(head, "cond"):
            branches = []
            for br in sexp[1:]:
                tag = br[0]
                expr = br[1]
                if is_sym(tag, "else"):
                    branches.append({"cond": True, "body": parse_expr(expr)})
                else:
                    branches.append({"cond": parse_expr(tag), "body": parse_expr(expr)})
            return {"type": "cond", "branches": branches}

        # (if cond then else)
        if is_sym(head, "if"):
            return {
                "type": "if",
                "cond": parse_expr(sexp[1]),
                "then": parse_expr(sexp[2]),
                "else": parse_expr(sexp[3]),
            }

        # (let* ((x e1) (y e2) ...) body)
        if is_sym(head, "let*"):
            bindings = {}
            for bp in sexp[1]:
                nm = sym_name(bp[0])
                bindings[nm] = parse_expr(bp[1])
            body = parse_expr(sexp[2])
            return {"type": "let*", "bindings": bindings, "body": body}

        # (list a b c ...)
        if is_sym(head, "list"):
            return {
                "type": "list",
                "items": [parse_expr(e) for e in sexp[1:]],
            }

        # 其它一律当函数调用：(f a b c ...)
        return {
            "type": "call",
            "func": sym_name(head),
            "args": [parse_expr(e) for e in sexp[1:]],
        }

    raise ValueError(f"Unknown expr: {sexp}")

# ========== 变量替换 ==========
def is_expr_symbol(name: str) -> bool:
    return name.startswith("expr")

def substitute_expr(node, env):
    if isinstance(node, dict):

        # 如果是 var
        if node.get("type") == "var":
            nm = node["name"]

            # NEW: expr* 停止展开
            if is_expr_symbol(nm):
                return node

            # 普通变量继续展开
            if nm in env:
                return substitute_expr(env[nm], env)
            else:
                return node

        # 递归处理子节点
        out={}
        for k,v in node.items():
            out[k]=substitute_expr(v, env)
        return out

    elif isinstance(node,list):
        return [substitute_expr(x, env) for x in node]

    else:
        return node


# ========== 从 define 里抽 let* ==========

def extract_from_define(sexp):
    """
    期望结构：
      (define (impl_depth2 ...)
        (let* ((var1 expr1)
               (var2 expr2)
               ...
               (expr0 expr0-body))
          expr0))
    """
    assert is_sym(sexp[0], "define")

    header = sexp[1]
    body = sexp[2]

    func = sym_name(header[0])
    print(f"[info] function: {func}")

    assert is_sym(body[0], "let*")

    binds = body[1]
    bodyname = sym_name(body[2])

    # 找 expr0 的 RHS
    expr0_sexp = None
    for b in binds:
        nm = sym_name(b[0])
        if nm == bodyname:
            expr0_sexp = b[1]
            break

    if expr0_sexp is None:
        raise RuntimeError(f"body var {bodyname} not found in let* bindings")

    return binds, bodyname, expr0_sexp

# ========== 提取常量绑定 ==========

def collect_consts(binds):
    consts = {}
    for bp in binds:
        nm = sym_name(bp[0])
        val = bp[1]
        if isinstance(val, list) and val and is_sym(val[0], "bv"):
            info = parse_bv(val)
            consts[nm] = {
                "value": info["value"],
                "width": info["width"],
                "hex": hex(info["value"]),
            }
    return consts

def extract_from_define_text(raw):
    m = re.search(r"\(define\b", raw)
    if not m:
        raise RuntimeError("No '(define ...' found")
    return raw[m.start():].strip()

# ========== 主流程 ==========

def main(path):
    raw = open(path).read()
    raw = extract_from_define_text(raw)

    sexp = loads(raw)

    # 顶层 find define
    if isinstance(sexp, list) and sexp and is_sym(sexp[0], "define"):
        de = sexp
    elif isinstance(sexp, list):
        de = None
        for e in sexp:
            if isinstance(e, list) and e and is_sym(e[0], "define"):
                de = e
                break
        if de is None:
            raise RuntimeError("No (define ...) found in top-level")
    else:
        raise RuntimeError("Unrecognized top-level structure")

    binds, bodyname, expr0_sexp = extract_from_define(de)

    # 常量输出
    consts = collect_consts(binds)
    print("\n===== Constant bindings =====")
    for k, v in consts.items():
        print(f"{k:25s} = {v['hex']} ({v['value']}, {v['width']} bits)")

    # 构建所有绑定的 AST 环境
    env = {}
    for bp in binds:
        nm = sym_name(bp[0])
        env[nm] = parse_expr(bp[1])

    # 为每一个以 "expr" 开头的绑定生成一个 fully-expanded AST
    print("\n===== Fully-expanded expr* ASTs =====")
    for nm in sorted(env.keys()):
        if not nm.startswith("expr"):
            continue

        # 避免展开自己时被自引用（虽然你这里不会）
        env_for_this = dict(env)
        # env_for_this.pop(nm, None)  # 理论上可以删掉自己，防止奇怪递归

        expanded = substitute_expr(env_for_this[nm], env_for_this)
        print(f"\n--- expanded {nm} ---")
        print(json.dumps(expanded, indent=2))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python3 eBPFcodegen.py sol.txt")
        sys.exit(1)
    main(sys.argv[1])
