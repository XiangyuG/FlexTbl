#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import json
import re
from sexpdata import loads, Symbol

# ========== 小工具 ==========

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

# ========== 通用替换函数（带 stop_names） ==========

def substitute_expr(node, env, stop_names=None):
    """
    通用 AST 替换：
    - var 且在 env 中，则递归替换
    - var 且在 stop_names 中，则停止展开
    """
    if stop_names is None:
        stop_names = set()

    if isinstance(node, dict):
        if node.get("type") == "var":
            nm = node["name"]
            if nm in stop_names:
                return node
            if nm in env:
                return substitute_expr(env[nm], env, stop_names)
            return node

        out = {}
        for k, v in node.items():
            out[k] = substitute_expr(v, env, stop_names)
        return out

    elif isinstance(node, list):
        return [substitute_expr(x, env, stop_names) for x in node]

    else:
        return node

# ========== 表达式转字符串（C风格） ==========

def format_bv(v, w):
    if w == 32:
        return f"0x{v:08x}"
    if w == 16:
        return f"0x{v:04x}"
    if w == 8:
        return f"0x{v:02x}"
    return str(v)

def stringify_expr(ast):
    t = ast.get("type")
    if t == "var":
        return ast["name"]
    if t == "bv":
        return format_bv(ast["value"], ast["width"])
    if t in ("bveq", "bvand", "bvor"):
        return stringify_condition(ast)
    # 其它情况直接 json
    return json.dumps(ast)

def stringify_condition(ast):
    t = ast.get("type")
    if t == "bveq":
        return f"({stringify_expr(ast['left'])} == {stringify_expr(ast['right'])})"
    if t == "bvand":
        return f"({stringify_expr(ast['left'])} & {stringify_expr(ast['right'])})"
    if t == "bvor":
        return f"({stringify_expr(ast['left'])} | {stringify_expr(ast['right'])})"
    if t == "var":
        return ast["name"]
    if t == "bv":
        return stringify_expr(ast)
    return json.dumps(ast)

# ========== 条件打印 ==========

def print_conditions(env):
    # 只用非 cond/expr 绑定去展开 cond*
    env_base = {
        k: v
        for (k, v) in env.items()
        if not (k.startswith("cond") or k.startswith("expr"))
    }

    print("\n===== Conditions (cond*) =====")
    for nm in sorted(env.keys()):
        if not nm.startswith("cond"):
            continue
        raw = env[nm]
        expanded = substitute_expr(raw, env_base)
        cond_str = stringify_condition(expanded)
        print(f"{nm:10s}= {cond_str}")

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
                "hex": format_bv(info["value"], info["width"]),
            }
    return consts

def extract_from_define_text(raw):
    m = re.search(r"\(define\b", raw)
    if not m:
        raise RuntimeError("No '(define ...' found")
    return raw[m.start():].strip()

# ========== 构建 expr 决策结构 ==========

def build_expr_structure(env):
    """
    返回: {exprName: {"kind":"decision"/"leaf", ...}}
    decision 节点有: cond, then, else
    leaf 节点只有 kind="leaf"
    """
    info = {}
    for nm, ast in env.items():
        if not nm.startswith("expr"):
            continue

        if ast.get("type") == "cond":
            branches = ast.get("branches", [])
            if len(branches) == 1:
                body = branches[0]["body"]
                if body.get("type") == "if":
                    cond_ast = body["cond"]
                    then_ast = body["then"]
                    else_ast = body["else"]
                    if (
                        cond_ast.get("type") == "var"
                        and then_ast.get("type") == "var"
                        and else_ast.get("type") == "var"
                    ):
                        info[nm] = {
                            "kind": "decision",
                            "cond": cond_ast["name"],
                            "then": then_ast["name"],
                            "else": else_ast["name"],
                        }
                        continue
                # 其它 cond 形式当 leaf 处理
                info[nm] = {"kind": "leaf"}
            else:
                info[nm] = {"kind": "leaf"}
        else:
            info[nm] = {"kind": "leaf"}
    return info

def print_expr_tree(bodyname, expr_info):
    print("\n===== Expression decision tree =====")

    visited = set()

    def dfs(name, indent=""):
        if name in visited:
            return
        visited.add(name)

        node = expr_info.get(name)
        if node is None:
            print(f"{indent}{name}: [no info]")
            return

        if node["kind"] == "decision":
            cond = node["cond"]
            th = node["then"]
            el = node["else"]
            print(f"{indent}{name}:")
            print(f"{indent}  if {cond:6s} -> {th}")
            print(f"{indent}  else    -> {el}")
            dfs(th, indent + "  ")
            dfs(el, indent + "  ")
        else:
            print(f"{indent}{name}: [leaf]")

    dfs(bodyname)

# ========== leaf expr 总结 ==========

def summarize_leaf_expr(name, ast):
    """
    期望 leaf expr 形如:
      (cond [else (let* (...) (list ...))])
    或直接 (let* (...) (list ...))
    """
    print(f"\n{name}:")

    # 去掉最外层 cond
    if ast.get("type") == "cond":
        branches = ast.get("branches", [])
        if len(branches) != 1 or branches[0]["cond"] is not True:
            print("  [complex leaf cond, raw AST:]")
            print(json.dumps(ast, indent=2))
            return
        body = branches[0]["body"]
    else:
        body = ast

    # let* 展开一次临时变量（只在本 expr 内）
    if body.get("type") == "let*":
        bindings = body["bindings"]
        local_env = {k: v for (k, v) in bindings.items()}
        final_body = substitute_expr(body["body"], local_env)
    else:
        final_body = body

    if final_body.get("type") != "list":
        print("  [unexpected leaf body (not list)]:")
        print(json.dumps(final_body, indent=2))
        return

    items = final_body["items"]
    if len(items) < 8:
        print("  [unexpected list length]:", len(items))
        print(json.dumps(final_body, indent=2))
        return

    # list: [ret srcPort srcIP dstPort dstIP protocol ctstate mark rand]
    ret     = stringify_expr(items[0])
    dstPort = stringify_expr(items[3])
    dstIP   = stringify_expr(items[4])
    ctstate = stringify_expr(items[6])
    mark    = stringify_expr(items[7])

    print(f"  decision(ret) = {ret}")
    print(f"  dstPort       = {dstPort}")
    print(f"  dstIP         = {dstIP}")
    print(f"  ctstate       = {ctstate}")
    print(f"  mark          = {mark}")

def summarize_leaf_expr_json(name, ast):
    # 期望 leaf expr 形如:
    #   (cond [else (let* (...) (list ...))])
    # 或直接 (let* (...) (list ...))

    # 去掉最外层 cond
    if ast.get("type") == "cond":
        branches = ast.get("branches", [])
        body = branches[0]["body"]
    else:
        body = ast

    # let* 展开临时变量
    if body.get("type") == "let*":
        bindings = body["bindings"]
        local_env = {k: v for (k, v) in bindings.items()}
        final_body = substitute_expr(body["body"], local_env)
    else:
        final_body = body

    items = final_body["items"]

    # list: [ret srcPort srcIP dstPort dstIP protocol ctstate mark rand]
    ret     = stringify_expr(items[0])
    dstPort = stringify_expr(items[3])
    dstIP   = stringify_expr(items[4])
    ctstate = stringify_expr(items[6])
    mark    = stringify_expr(items[7])

    return {
        "decision": ret,
        "dstPort": dstPort,
        "dstIP": dstIP,
        "ctstate": ctstate,
        "mark": mark,
    }
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

    # 构建所有 let* 绑定的 AST 环境
    env = {}
    for bp in binds:
        nm = sym_name(bp[0])
        env[nm] = parse_expr(bp[1])

    # 输出 cond* 含义
    print_conditions(env)

    # 构造 expr 决策结构
    expr_info = build_expr_structure(env)

    # 打印决策树（不展开 subexpr）
    # print_expr_tree(bodyname, expr_info)

    # 打印所有 leaf expr 的结果摘要
    print("\n===== Leaf expr summaries =====")
    json_result = {}
    for nm, info in sorted(expr_info.items()):
        if info["kind"] == "leaf":
            json_result[nm] = summarize_leaf_expr_json(nm, env[nm])

    print("\n===== JSON Leaf Output =====")
    print(json.dumps(json_result, indent=2))
    print("\n===== DONE =====")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python3 eBPFcodegen.py sol.txt")
        sys.exit(1)
    main(sys.argv[1])
