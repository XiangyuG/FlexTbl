# --- IR node definitions ---

class Expr:
    pass

class BVConst(Expr):
    def __init__(self, value, width):
        self.value = value
        self.width = width

class Var(Expr):
    def __init__(self, name):
        self.name = name

class Op(Expr):
    def __init__(self, op, args):
        self.op = op          # e.g., 'bveq', 'bvand'
        self.args = args      # list[Expr]

class If(Expr):
    def __init__(self, cond, then_branch, else_branch):
        self.cond = cond          # Expr, 通常是 Op(bveq, [...])
        self.then_branch = then_branch  # Expr
        self.else_branch = else_branch  # Expr

# --- Parsing helpers ---

def parse_expr(node):
    """Parse a generic expression node."""
    # bitvector constant
    if isinstance(node, dict) and "type" in node and node["type"] == "bv":
        return BVConst(node["value"], node["width"])

    # simple variable
    if isinstance(node, dict) and "var" in node:
        return Var(node["var"])

    # if-then-else expression
    if isinstance(node, dict) and "if" in node:
        if_node = node["if"]
        cond = parse_cond(if_node["cond"])
        then_branch = parse_expr(if_node["then"])
        else_branch = parse_expr(if_node["else"])
        return If(cond, then_branch, else_branch)

    # operator application in list form: [ {'var': 'bvand'}, arg1, arg2, ... ]
    if isinstance(node, list):
        if not node:
            raise ValueError("Empty list node encountered")

        head = node[0]
        if isinstance(head, dict) and "var" in head:
            op_name = head["var"]
        else:
            raise ValueError(f"Unsupported operator head in list: {head}")

        args = [parse_expr(arg) for arg in node[1:]]
        return Op(op_name, args)

    raise ValueError(f"Unknown node format: {node}")


def parse_cond(cond_node):
    """
    cond_node is like:
      [[{'var': 'choose'}, {'var': 'bveq'}], lhs, rhs]
    or:
      [{'var': 'bveq'}, lhs, rhs]
    """
    if not isinstance(cond_node, list) or len(cond_node) != 3:
        raise ValueError(f"Unexpected cond format: {cond_node}")

    op_spec, lhs, rhs = cond_node

    # op_spec can be a list [ {'var':'choose'}, {'var':'bveq'} ]
    # or a single dict {'var':'bveq'}
    if isinstance(op_spec, list):
        last = op_spec[-1]
        if not (isinstance(last, dict) and "var" in last):
            raise ValueError(f"Bad op spec: {op_spec}")
        op_name = last["var"]
    elif isinstance(op_spec, dict) and "var" in op_spec:
        op_name = op_spec["var"]
    else:
        raise ValueError(f"Unsupported op spec: {op_spec}")

    return Op(op_name, [parse_expr(lhs), parse_expr(rhs)])

# --- Codegen: expression emitter ---

def emit_expr(expr):
    """Emit C expression string."""
    if isinstance(expr, BVConst):
        # 简单处理：直接用十进制，eBPF 里你可以根据 width 再决定 cast
        return str(expr.value)

    if isinstance(expr, Var):
        return expr.name

    if isinstance(expr, Op):
        op = expr.op
        args = expr.args

        if op == "bveq":
            # (a == b)
            return f"({emit_expr(args[0])} == {emit_expr(args[1])})"

        if op == "bvand":
            # (a & b)
            return f"({emit_expr(args[0])} & {emit_expr(args[1])})"

        # 其他算子先简单 fallback. TODO: solve other operators
        inner = ", ".join(emit_expr(a) for a in args)
        return f"{op}({inner})"

    raise ValueError(f"Cannot emit C expr for: {expr}")

# --- Codegen: statements emitting into a target variable ---

def emit_stmt(expr, target_var, indent=4):
    """
    Emit C statements that assign the value of `expr` to `target_var`.
    """
    space = " " * indent

    # constant -> target_var = V;
    if isinstance(expr, BVConst):
        if expr.value == 0:
            return f"{space}return XDP_PASS;\n"
        assert expr.value == 1, "Currently, only support XDP_PASS(0) and XDP_DROP(1)"
        return f"{space}return XDP_DROP;\n"

    # variable -> target_var = var;
    if isinstance(expr, Var):
        return f"{space}{target_var} = {expr.name};\n"

    # pure operation -> target_var = <expr>;
    if isinstance(expr, Op):
        return f"{space}{target_var} = {emit_expr(expr)};\n"

    # if-expression -> if (...) { ... } else { ... }
    if isinstance(expr, If):
        out = ""
        cond_code = emit_expr(expr.cond)
        out += f"{space}if ({cond_code}) {{\n"
        out += emit_stmt(expr.then_branch, target_var, indent + 4)
        out += f"{space}}} else {{\n"
        out += emit_stmt(expr.else_branch, target_var, indent + 4)
        out += f"{space}}}\n"
        return out

    raise ValueError(f"Cannot emit C stmt for: {expr}")

# --- Top-level: generate a C helper function ---

def generate_c_function(ast, name="eval_expr0"):
    """
    Generate a eBPF-friendly function:
    __u32 eval_expr0(__u32 srcIP, __u32 dstIP, __u32 ctstate, ...);
    """
    header = (
        "static __always_inline __u32 " + name + "(\n"
        "    __u32 srcIP,\n"
        "    __u32 dstIP,\n"
        "    __u32 ctstate)\n"
        "{\n"
    )

    body = emit_stmt(ast, "decision", indent=4)
    # return default decision (currently, we set the default decision to be pass)
    # Actually, the program should never reach this part
    footer = "    return XDP_PASS;\n}\n" 

    return header + body + footer

def eBPFcodegen(expr, name="iptable_impl"):
    ast = parse_expr(expr)
    eBPF_code = generate_c_function(ast, name=name)
    print(eBPF_code)
    return eBPF_code
    
