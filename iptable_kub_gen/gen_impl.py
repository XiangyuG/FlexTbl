#!/usr/bin/env python3
import sys
import json

VAR_NAMES = ["srcPort", "srcIP", "dstPort", "dstIP", "protocol", "ctstate", "mark", "rand"]

# All filtering decisions (0 --> accept, 1 --> drop)
DECISIONS = ["(bv 0 4)", "(bv 1 4)", "(bv 2 4)", "(bv 3 4)", "(bv 4 4)", "(bv 5 4)", "(bv 6 4)", "(bv 7 4)"]

# default constant to compare with
CMP_CONSTS = ["(bv 0 4)", "(bv 1 4)", "(bv 2 4)", "(bv 3 4)", "(bv 4 4)", "(bv 5 4)"]

# comparison operators
CMP_OPS = ["bveq"]

OPERATORS = ["bvand", "bvor"]

chain_parameters = " ".join(VAR_NAMES)
no_mask_parameters = ""
for v in VAR_NAMES:
    if v != "srcIP" and v != "dstIP":
        if no_mask_parameters == "":
            no_mask_parameters += v
        else: 
            no_mask_parameters += " " + v

def gen_cond_name(node_id):
    return f"cond{node_id}"


def gen_expr_name(node_id):
    return f"expr{node_id}"


def indent(s, n=2):
    pad = " " * n
    return "\n".join(pad + line if line.strip() else line for line in s.splitlines())


var_choose = f"(choose {' '.join(VAR_NAMES)})"


def gen_cond_block(cond_name, node_id):
    mask_name   = f"mask{node_id}"
    normal_const = f"Const{node_id}"

    return f"""
        [{normal_const}    (choose {' '.join(CMP_CONSTS)})]

        [{cond_name}
          (choose
            ((choose {' '.join(CMP_OPS)})
               (bvand (choose srcIP dstIP) {mask_name})
               {normal_const})
            ((choose {' '.join(CMP_OPS)})
               (choose {no_mask_parameters})
               {normal_const}))]
    """


def gen_set_str(node_id, bindings):
    set_str = ""
    let_bindings = []  # list of "[var binding]" strings

    for v in VAR_NAMES:
        if v != "rand" and v != "protocol":
            const_val_name1 = f"Const{node_id}_{v}_1"
            const_val_name2 = f"Const{node_id}_{v}_2"
            bindings.append(f"[{const_val_name1}    (choose {' '.join(CMP_CONSTS)})]")
            bindings.append(f"[{const_val_name2}    (choose {' '.join(CMP_CONSTS)})]")

            # 生成内部变量名字：srcPort3 / srcIP3 / ...
            new_v = f"{v}{node_id}"

            # let* 里面的绑定
            binding_expr = (
                f"[{new_v} "
                f"(choose {v} "
                f"((choose {' '.join(OPERATORS)}) "
                f"(choose {v} {const_val_name1}) {const_val_name2}))]"
            )
            let_bindings.append(binding_expr)

            # curr_set_str = f"(let ([{v}{node_id} (choose {v} ((choose {' '.join(OPERATORS)}) (choose {v} {const_val_name1}) {const_val_name2})))])"
            # # curr_set_str = f"(set! {v} (choose {v} ((choose {' '.join(OPERATORS)}) (choose {v} {const_val_name1}) {const_val_name2})))"
            # set_str += curr_set_str + "\n"
        else:
            continue
    binds = "\n        ".join(let_bindings)
    set_str = (
        f"(let* (\n"
        f"        {binds}\n"
        f"       )\n"
    )

    return set_str, bindings

def gen_node(node_id, depth):
    """
    递归生成一个节点的 let* bindings 代码片段和该节点最终表达式名字。
    返回：(bindings_str, expr_name)
    """
    expr_name = gen_expr_name(node_id)

    # depth 0：leaf node, choose a decision
    if depth == 0:
        bindings = []
        # choice_name = f"choice{node_id}"
        # bindings.append(
        #     f"[{choice_name} (choose 0 1 2 3)]"
        # )
        # Generate a series of set statements (e.g., (set! {v} (op op1 op2)))
        set_str, bindings = gen_set_str(node_id, bindings)
        cases = []
        # (list (bv 5 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)
        return_parameters = ""
        for v in VAR_NAMES:
            if v != "rand" and v != "protocol":
                return_parameters += f" {v}{node_id}"
            else:
                return_parameters += f" {v}"
        # for i, d in enumerate(DECISIONS):
        #     cases.append(f"[(= {choice_name} {i}) \n {set_str} (list {d} {return_parameters}))]")
        # cond_body = "\n".join(cases)
        ret_var_name = f"ret{node_id}"
        bindings.append(
            f"[{ret_var_name} (choose {' '.join(DECISIONS)})]"
        )

        cases.append(f"[else \n {set_str} (list {ret_var_name} {return_parameters}))]")
        cond_body = "\n".join(cases)
        bindings.append(
            f"[{expr_name} (cond\n{indent(cond_body, 4)}\n        )]"
        )
        return "\n".join(bindings), expr_name

    # depth > 0：internal node
    bindings = []

    # 条件 condX: (op var const)
    cond_name = gen_cond_name(node_id)

    bindings.append(gen_cond_block(cond_name, node_id))

    # bindings.append(
    #     f"[{cond_name} ((choose {' '.join(CMP_OPS)}) "
    #     f"(choose {' '.join(VAR_NAMES)}) "
    #     f"(choose {' '.join(CMP_CONSTS)}))]"
    # )

    # 生成左、右子树
    left_bindings, left_expr = gen_node(f"{node_id}L", depth - 1)
    right_bindings, right_expr = gen_node(f"{node_id}R", depth - 1)

    # choice_name = f"choice{node_id}"
    # bindings.append(
    #     f"[{choice_name} (choose 0 1 2 3 4)]"
    # )
    bindings.append(left_bindings)
    bindings.append(right_bindings)

    # Generate a series of set statements (e.g., (set! {v} (op op1 op2)))
    # set_str, bindings = gen_set_str(node_id, bindings)
    # cases = []
    # return_parameters = ""
    # for v in VAR_NAMES:
    #     if v != "rand" and v != "protocol":
    #         return_parameters += f" {v}{node_id}"
    #     else:
    #         return_parameters += f" {v}"
    # for i, d in enumerate(DECISIONS):
    #     cases.append(f"[(= {choice_name} {i}) \n {set_str} (list {d} {return_parameters}))]")
    # cond_body = "\n".join(cases)
    # 当前节点表达式：if cond then left_expr else right_expr
    # bindings.append(
    #     f"[{expr_name} (cond\n{indent(cond_body, 4)}"
    # )

    bindings.append(
        f"[{expr_name} (cond\n"
    )
    bindings.append(
        f"    [else (if {cond_name} {left_expr} {right_expr})]"
    )
    bindings.append(
        f")]"
    )

    return "\n".join(bindings), expr_name

def collect_nodes(prefix, depth):
    """
    Return all node-name suffixes for a given depth.
    prefix: "" for root, "L", "R", "LL", ...
    """
    if depth == 0:
        return [prefix]

    # recursively collect left and right subtree nodes
    return collect_nodes(prefix + "L", depth - 1) + \
           collect_nodes(prefix + "R", depth - 1)

def gen_symbolic_masks(depth):
    nodes = []
    mask_names = []
    for i in range(depth):
        nodes += collect_nodes("0", i)
    if len(nodes) != 0:
        mask_names = [f"mask{n}" for n in nodes]  # mask0, mask0L, mask0R, ...
    return mask_names


def gen_impl(depth, constant_list):
    global CMP_CONSTS
    for v in constant_list:
        CMP_CONSTS.append(v)

    bindings, root_expr = gen_node("0", depth)
    mask_l = gen_symbolic_masks(depth)
    header = f"""
(define (impl {chain_parameters})
  (let* (
"""
    for m in mask_l:
        # [mask0 (?? (bitvector 32))]
        # mask_def_str = f"[{m} (?? (bitvector 32))]"
        mask_def_str = f"[{m} (choose {' '.join(CMP_CONSTS)})]"
        header += indent(mask_def_str, 12) + "\n"
    footer = f"""
        )
    {root_expr}))
"""

    return header + indent(bindings, 4) + footer


if __name__ == "__main__":

    if len(sys.argv) != 3:
        print("Usage: python gen_impl.py <depth> <constant filename>")
        sys.exit(0)
    depth = int(sys.argv[1])
    constant_filename = str(sys.argv[2])
    with open(constant_filename) as f:
        constant_list = json.load(f)

    code = gen_impl(depth, constant_list)
    print(code)
