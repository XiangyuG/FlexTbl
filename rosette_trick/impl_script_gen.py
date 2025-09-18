def gen_vanilla(name: str, n: int) -> str:
    lines = []
    # 函数头
    lines.append(f"(define ({name} proto srcIP dstIP srcPort dstPort)")
    # 生成 n 条规则
    for i in range(n):
        lines.append("  (if (and (choose (bveq proto (?? (bitvector 8))) #t)")
        lines.append("           (choose (bveq srcIP (?? (bitvector 32))) #t)")
        lines.append("           (choose (bveq dstIP (?? (bitvector 32))) #t)")
        lines.append("           (choose (bveq srcPort (?? (bitvector 16))) #t)")
        lines.append("           (choose (bveq dstPort (?? (bitvector 16))) #t))")
        lines.append("      (bv 1 8)")
        lines.append("  ")
    # 最后一条 else 返回 (bv 0 8)
    lines.append("      (bv 0 8)")
    # 关闭所有括号
    lines.append(")" * n)
    # 结束 define
    lines.append(")")

    return "\n".join(lines)

def gen_opt(name: str, n: int) -> str:
    header = f"(define ({name} proto srcIP dstIP srcPort dstPort)"
    rule = """  (if (and (choose (bveq proto (const8)) #t)
           (choose (bveq srcIP (const32)) #t)
           (choose (bveq dstIP (const32)) #t)
           (choose (bveq srcPort (const16)) #t)
           (choose (bveq dstPort (const16)) #t))
      (bv 1 8)"""
    lines = [header]
    # 插入 n 条规则
    for _ in range(n):
        lines.append(rule)
    # 最后的 else
    lines.append("      (bv 0 8)" + ")" * n)
    # 结束 define
    lines.append(")")
    return "\n".join(lines)


if __name__ == "__main__":
    rule_num = 20
    code = gen_vanilla(f"impl{rule_num}", rule_num)
    print(code)
    print(";;;-----------------------Below is vanilla version")
    code = gen_opt(f"impl{rule_num}vanilla", rule_num)
    print(code)
