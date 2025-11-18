import sexpdata
import sys
from eBPFgen import eBPFcodegen
# ---------- Part 1: sexpdata -> 纯 Python 结构 ----------

def sexp_to_python(node):
    if isinstance(node, sexpdata.Symbol):
        return node.value()
    if isinstance(node, list):
        return [sexp_to_python(x) for x in node]
    if isinstance(node, sexpdata.Quoted):
        return ["quote", sexp_to_python(node.value())]
    return node

# ---------- Part 2: 一个简单的 evaluator ----------

def eval_expr(expr, env):
    """
    expr: 由 sexp_to_python 得到的 Python 结构
    env:  字典，比如 {"choice0LL": 3, "Const0": {...}}
    """
    # 整数：直接返回
    if isinstance(expr, int):
        return expr

    # 字符串：变量名或符号
    if isinstance(expr, str):
        # 如果是环境里已有的变量，就取它的值
        if expr in env:
            return env[expr]
        # 否则，当成“符号”/自由变量
        return {"var": expr}

    # 列表：S-expression
    if isinstance(expr, list):
        if len(expr) == 0:
            return None

        head = expr[0]

        # (bv value width)
        if head == "bv":
            val = eval_expr(expr[1], env)
            width = eval_expr(expr[2], env)
            return {"type": "bv", "value": val, "width": width}

        # (= a b)
        if head == "=":
            left = eval_expr(expr[1], env)
            right = eval_expr(expr[2], env)
            # 两边都是整数：可以比较
            if isinstance(left, int) and isinstance(right, int):
                return left == right
            # 其他情况先不计算，保留结构
            return {"eq": (left, right)}

        # (cond [test expr] ... [else expr])
        if head == "cond":
            # 每个 clause 是 [test, result]
            for clause in expr[1:]:
                test = clause[0]
                value = clause[1]
                # else 分支
                if isinstance(test, str) and test == "else":
                    return eval_expr(value, env)
                test_val = eval_expr(test, env)
                if isinstance(test_val, bool) and test_val:
                    return eval_expr(value, env)
            return None  # 理论上不该走到这里

        # (if cond then else)
        if head == "if":
            cond_val = eval_expr(expr[1], env)
            then_expr = expr[2]
            else_expr = expr[3]
            if isinstance(cond_val, bool):
                if cond_val:
                    return eval_expr(then_expr, env)
                else:
                    return eval_expr(else_expr, env)
            # 条件算不出 True/False，就保留结构
            return {
                "if": {
                    "cond": cond_val,
                    "then": eval_expr(then_expr, env),
                    "else": eval_expr(else_expr, env),
                }
            }

        # 其他形式，例如:
        # (bvand srcIP mask0)
        # ((choose bveq) (bvand ...) Const0)
        # 我们统一递归解析子表达式，保留为结构化形式
        return [eval_expr(x, env) for x in expr]

    # 其他类型（很少用到）
    return expr

# ---------- Part 3: 解析 impl.rkt, 按 let* 顺序求每个变量的值 ----------

def load_racket_expr(filename):
    lines = []
    with open(filename) as f:
        for line in f:
            # Fine the real beginning
            if line.strip().startswith("(define"):
                lines.append(line)
                break  # continue collecting other lines
        # collecting other lines of code
        for line in f:
            lines.append(line)

    code = "".join(lines)
    return code


def main(filename):
    code = load_racket_expr(filename)

    ast = sexpdata.loads(code)
    py = sexp_to_python(ast)

    # py: ['define', ['impl', ...params...], ['let*', bindings, body_expr]]
    define_kw, func_def, let_expr = py
    assert define_kw == "define"

    func_name = func_def[0]      # 'impl'
    params = func_def[1:]        # ['srcPort', 'srcIP', ...]
    # print("Function:", func_name, "params:", params)

    assert let_expr[0] == "let*"
    bindings = let_expr[1]       # [[name, expr], ...]
    body_expr = let_expr[2]      # 'expr0'

    env = {}

    print("=== Evaluate let* bindings in order ===")
    for name, expr in bindings:
        val = eval_expr(expr, env)
        env[name] = val
        # print(f"{name} = {val}")
    print("=== Evaluate let* bindings in order DONE===")
    
    print("\n=== Evaluate body expr0 ===")
    result = eval_expr(body_expr, env)
    # print(f"expr0 = {result}")
    print("\n=== Evaluate body expr0 DONE===")
    print(f"expr0 = {result}")
    eBPFcodegen(expr=result, name="iptable_impl")
    print("successful parse the result.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python parse_impl.py <filename>")
        sys.exit(0)
    filename = str(sys.argv[1])
    main(filename)

# expr0 = 
# {'if': 
#  {'cond': [[{'var': 'choose'}, {'var': 'bveq'}], [{'var': 'bvand'}, {'var': 'srcIP'}, {'var': 'mask0'}], {'type': 'bv', 'value': 2130706432, 'width': 32}], 
#   'then': {'if': {'cond': [[{'var': 'choose'}, {'var': 'bveq'}], [{'var': 'bvand'}, {'var': 'srcIP'}, {'var': 'mask0L'}], {'type': 'bv', 'value': 2130706432, 'width': 32}], 
#                   'then': {'type': 'bv', 'value': 0, 'width': 4}, 'else': {'type': 'bv', 'value': 1, 'width': 4}}
#           }, 
#  'else': {'if': {'cond': [[{'var': 'choose'}, {'var': 'bveq'}], [{'var': 'bvand'}, {'var': 'dstIP'}, {'var': 'mask0R'}], {'type': 'bv', 'value': 2130706432, 'width': 32}], 
#                  'then': {'type': 'bv', 'value': 1, 'width': 4}, 'else': {'type': 'bv', 'value': 0, 'width': 4}
#                 }
#         }
# }}
