# file: gen_eval.py
import json
from textwrap import indent

def bv32(node):
    assert node["type"] == "bv" and node["width"] == 32
    v = node["value"]
    return v

def sym(node):
    assert node["type"] == "sym"
    # map to C field names
    m = {"srcip":"srcip","dstip":"dstip","proto":"proto","sport":"sport","dport":"dport"}
    return f"{m[node['name']]}"

def boollit(node):
    assert node["type"] == "bool"
    return "true" if node["value"] else "false"

def to_expr(node):
    t = node["type"]
    if t == "equal":
        L = to_expr(node["left"])
        R = to_expr(node["right"])
        if L == "proto":
            assert isinstance(R, int)
            if R == 0:
                return f"{L} == IPPROTO_UDP"
            elif R == 1:
                return f"{L} == IPPROTO_TCP"
            else:
                assert False, "unexpected protocol value"
        elif R == "proto":
            assert isinstance(L, int)
            if L == 0:
                return f"{R} == IPPROTO_UDP"
            elif L == 1:
                return f"{R} == IPPROTO_TCP"
            else:
                assert False, "unexpected protocol value"
        return f"{L} == {R}"
    if t == "and":
        # empty -> true
        parts = [to_expr(a) for a in node["args"]]
        out_str = ""
        for p in parts:
            if p != 'true' and p != '':
                if out_str:
                    out_str += " && "
                out_str += p
        return out_str
    if t == "bv":
        return bv32(node)
    if t == "sym":
        return sym(node)
    if t == "bool":
        return boollit(node)
    if t == "call":
        raise NotImplementedError("generic calls not expected here")
    raise NotImplementedError(t)

def to_packet_assigns(pkt_node):
    eBPF = {"sport":"source","dport":"dest"}
    assert pkt_node["type"] == "packet"
    def f(field):
        n = pkt_node[field]
        if n["type"] == "sym":
            # No need to update symbolic variables to itself
            return ""
        elif n["type"] == "bv":
            if field == "sport" or field == "dport":
                out_str = "if (proto == IPPROTO_TCP) {\n"
                out_str += f"    tcp->{eBPF[field]} = bpf_ntohs({bv32(n)});\n"
                out_str += "} else if (proto == IPPROTO_UDP) {\n"
                out_str += f"    udp->{eBPF[field]} = bpf_ntohs({bv32(n)});\n"
                out_str += "};\n"
                return out_str
            elif field == "proto":
                if bv32(n) == 0:
                    return "proto = IPPROTO_UDP;"
                elif bv32(n) == 1:
                    return "proto = IPPROTO_TCP;"
                else:
                    raise NotImplementedError(f"unknown protocol value: {bv32(n)}")
            return f"{field} = {bv32(n)};"
        else:
            raise NotImplementedError(f"packet field {field}: {n['type']}")
    assigns = []
    for k in ["srcip","dstip","proto","sport","dport"]:
        assigns.append(f(k))
    out_str = ""
    for a in assigns:
        if a != "":
            if out_str:
                out_str += "\n"
            out_str += a
    return out_str

def to_cons(node):
    assert node["type"] == "cons"
    flag = node["car"]
    pkt  = node["cdr"]
    assert flag["type"] == "bv" and flag["width"] == 32
    code = []
    code.append(to_packet_assigns(pkt))
    # Return the decision
    if bv32(flag) == 0:
        code.append("return XDP_PASS;")
    else:
        code.append("return XDP_DROP;")
    out_str = ""
    for c in code:
        if c != "":
            if out_str:
                out_str += "\n"
            out_str += c
    return out_str

def to_stmt(node):
    t = node["type"]
    if t == "if":
        cond = to_expr(node["cond"])
        thn  = to_stmt(node["then"])
        els  = to_stmt(node["else"])
        # cond == "" means that the condition is always true, then there is no need for an else statement
        if cond == "":
            return f"{indent(thn, '    ')}\n"
        return (
            f"if ({cond}) {{\n"
            f"{indent(thn, '    ')}\n"
            f"}} else {{\n"
            f"{indent(els, '    ')}\n"
            f"}}"
        )
    if t == "cons":
        return to_cons(node)
    raise NotImplementedError(f"stmt {t}")

def generate_eval(json_ast):
    assert json_ast["type"] == "define" and json_ast["name"] == "impl-fast"
    body = json_ast["body"]
    body_c = to_stmt(body)
    return (
        f"{indent(body_c, '    ')}\n"
        "    return XDP_DROP;\n"
    )
    # Default is XDP_DROP, if no conditions match

if __name__ == "__main__":
    import sys, pathlib
    data = json.load(sys.stdin)
    template_filename = "eBPF_template.py"
    template_file = pathlib.Path(template_filename)
    tpl = template_file.read_text(encoding="utf-8")
    eBPF_core_func = generate_eval(data)
    out = tpl.replace("{{MY PROGRAM}}", eBPF_core_func)

    print(eBPF_core_func)
