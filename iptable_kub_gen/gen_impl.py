#!/usr/bin/env python3
import sys
import json

VAR_NAMES = ["srcPort", "srcIP", "dstPort", "dstIP", "protocol", "ctstate", "mark", "rand"]

# All filtering decisions (0 --> accept, 1 --> drop)
DECISIONS = ["(bv 0 4)", "(bv 1 4)"]

# constant to compare with
# TODO: get this constant list from input
CMP_CONSTS = ["(bv 0 4)", "(bv 1 4)", "(bv 2 4)", "(bv 3 4)", "(bv 4 4)", "(bv 5 4)", 
              "(bv 6 4)", "(bv 7 4)", "(bv 8 4)", "(bv 9 4)", "(bv 10 4)", 
              "(bv 11 4)", "(bv 12 4)", "(bv 13 4)", "(bv 14 4)", "(bv 15 4)"]

# comparison operators
CMP_OPS = ["bveq"]

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
        ;; node {node_id} condition:
        [{normal_const}    (choose {' '.join(CMP_CONSTS)})]

        [{cond_name}
          (choose
            ;; IP branch (bvand (choose srcIP dstIP) mask) ?= ipConst
            ((choose {' '.join(CMP_OPS)})
               (bvand (choose srcIP dstIP) {mask_name})
               {normal_const})
            ;; non IP branch
            ((choose {' '.join(CMP_OPS)})
               (choose {no_mask_parameters})
               {normal_const}))]
    """

def gen_node(node_id, depth):
    """
    递归生成一个节点的 let* bindings 代码片段和该节点最终表达式名字。
    返回：(bindings_str, expr_name)
    """
    expr_name = gen_expr_name(node_id)

    # depth 0：leaf node, choose a decision
    if depth == 0:
        bindings = []
        choice_name = f"choice{node_id}"
        bindings.append(
            f"[{choice_name} (choose 0 1 2 3)]"
        )
        # expr = 根据 choiceN 选 DECISIONS
        cases = []
        # (list (bv 5 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)
        for i, d in enumerate(DECISIONS):
            cases.append(f"[(= {choice_name} {i}) (list {d} {chain_parameters})]")
        cond_body = "\n".join(cases)
        bindings.append(
            f"[{expr_name} (cond\n{indent(cond_body, 4)}\n        )]"
        )
        return "\n".join(bindings), expr_name

    # depth > 0：内部节点
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

    bindings.append(left_bindings)
    bindings.append(right_bindings)

    # 当前节点表达式：if cond then left_expr else right_expr
    bindings.append(
        f"[{expr_name} (if {cond_name} {left_expr} {right_expr})]"
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
        mask_def_str = f"[{m} (?? (bitvector 32))]"
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
