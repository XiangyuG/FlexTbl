import random

# 候选值集合
proto_vals = [0]          # 只有 0
ip_vals = [0, 1, 42]      # IP 值
port_vals = [0, 1, 42]    # Port 值

def make_rule(proto, srcIP, dstIP, srcPort, dstPort):
    return f"""(and (bveq proto (bv {proto} 8))
        (bveq srcIP (bv {srcIP} 32))
        (bveq dstIP (bv {dstIP} 32))
        (bveq srcPort (bv {srcPort} 16))
        (bveq dstPort (bv {dstPort} 16)))"""

def gen_spec(n):
    # 所有可能组合
    all_combos = [
        (p, s, d, sp, dp)
        for p in proto_vals
        for s in ip_vals
        for d in ip_vals
        for sp in port_vals
        for dp in port_vals
    ]

    # 随机挑选 n 个不重复
    chosen = random.sample(all_combos, n)

    # 拼接 if 结构
    code = f"(define (spec{n} proto srcIP dstIP srcPort dstPort)\n"
    for rule in chosen:
        cond = make_rule(*rule)
        code += f"  (if {cond} (bv 1 8)\n"
    code += "    (bv 0 8)" + ")" * n + ")\n"
    return code

if __name__ == "__main__":
    N = 20  # 想要几条规则就改这里
    racket_code = gen_spec(N)
    print(racket_code)
