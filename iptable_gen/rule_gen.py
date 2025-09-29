import sys
import random

random.seed(42)
thirty_two_bit_dic = {}
sixteen_bit_dic = {}
eight_bit_dic = {}
eight_bit_dic[0] = 1
eight_bit_dic[1] = 1
## Criterion 1: Making the default rule to PKT DROP

## Criterion 2: Allow certain ip addresses
def allow_ip():
    # genrate a random 32-bit constant
    sip = random.randint(0, 2**32 - 1)
    dip = random.randint(0, 2**32 - 1)
    thirty_two_bit_dic[sip] = 1
    thirty_two_bit_dic[dip] = 1
    ret_l = [sip, dip, None, None, None]
    return ret_l

## Criterion 3: Allow trafic from certain port ID (e.g., SSH, HTTPS, HTTP)
def allow_port():
    # genrate a random 16-bit constant
    sport = random.randint(0, 2**16 - 1)
    dport = random.randint(0, 2**16 - 1)
    sixteen_bit_dic[sport] = 1
    sixteen_bit_dic[dport] = 1
    ret_l = [None, None, 1, sport, dport]
    return ret_l

## Criterion 4: Load Balancing 
def load_balance():
    pass
    sip = random.randint(0, 2**32 - 1)
    dip1 = random.randint(0, 2**32 - 1)
    dip2 = random.randint(0, 2**32 - 1)
    ret_l = [sip, dip1, 1, None, None]
    ret_l2 = [sip, dip2, 1, None, None]
    return ret_l, ret_l2

## Criterion 5: Port forwarding
def port_forward():
    pass
    # genrate a random 16-bit constant
    sport = random.randint(0, 2**16 - 1)
    dport1 = random.randint(0, 2**16 - 1)
    dport2 = random.randint(0, 2**16 - 1)
    ret_l = [None, None, 1, sport, dport1]
    ret_l2 = [None, None, 1, sport, dport2]
    return ret_l, ret_l2

# (define (spec srcip dstip proto sport dport)
#   (if (and (bveq dport (bv 8080 16)) (bveq sport (bv 80 16))) (bv 1 8) 
#   (if (and (bveq dport (bv 81 16)) (bveq sport (bv 80 16))) (bv 1 8) (bv 0 8))))
def code_gen(iptable_rules):
    out_str = ""
    out_str += "(define (spec srcip dstip proto sport dport)\n"
    
    for r in iptable_rules:
        out_str += "  (if (and "
        sip, dip, proto, sport, dport = r
        
        if sip is not None:
            out_str += f"(bveq srcip (bv #x{sip:08x} 32))"
        if dip is not None:
            out_str += f"(bveq dstip (bv #x{dip:08x} 32))"
        if proto is not None:
            out_str += f"(bveq proto (bv #x{proto:02x} 8))"
        if sport is not None:
            out_str += f"(bveq sport (bv #x{sport:04x} 16))"
        if dport is not None:
            out_str += f"(bveq dport (bv #x{dport:04x} 16))"
        out_str += ") (bv 1 8)\n"
    out_str += "(bv 0 8)"
    for r in iptable_rules:
        out_str += ")"
    out_str += ")"
    return out_str

# (define-grammar (const8)
#   [cst (choose (bv 0 8) (bv 1 8) (bv 6 8))])

# (define-grammar (const32)
#   [cst (choose (bv 0 32) (bv 1 32) (bv 42 32))])

# (define-grammar (const16)
#   [cst (choose (bv 0 16) (bv 1 16) (bv 8080 16) (bv 80 16) (bv 81 16))])
def constant_synthesis_gen(thirty_two_bit_dic, sixteen_bit_dic, eight_bit_dic):
    out_str = ""
    if len(eight_bit_dic) != 0:
        eight_str = "(define-grammar (const8)\n"
        eight_str += "  [cst (choose "
        for k in eight_bit_dic.keys():
            eight_str += f"(bv {k} 8) "
        eight_str += ")])\n"
    else:
        eight_str = "(define-grammar (const8)\n"
        eight_str += "  [cst (choose (bv 0 8) (bv 1 8))])\n"
    if len(sixteen_bit_dic) != 0:
        sixteen_str = "(define-grammar (const16)\n"
        sixteen_str += "  [cst (choose "
        for k in sixteen_bit_dic.keys():
            sixteen_str += f"(bv {k} 16) "
        sixteen_str += ")])\n"
    else:
        sixteen_str = "(define-grammar (const16)\n"
        sixteen_str += "  [cst (choose (bv 0 16) (bv 1 16))])\n"
    if len(thirty_two_bit_dic) != 0:
        thirty_two_str = "(define-grammar (const32)\n"
        thirty_two_str += "  [cst (choose "
        for k in thirty_two_bit_dic.keys():
            thirty_two_str += f"(bv {k} 32) "
        thirty_two_str += ")])\n"
    else:
        thirty_two_str = "(define-grammar (const32)\n"
        thirty_two_str += "  [cst (choose (bv 0 32) (bv 1 32))])\n"

    out_str += thirty_two_str
    out_str += sixteen_str
    out_str += eight_str
    
    return out_str

def main(argv):
    if len(argv) != 2:
        print("Usage: python3 rule_gen.py num_of_rules")
        return
    num_of_rules = int(argv[1])
    # set random seed for reproducibility
    iptable_rules = []
    for i in range(num_of_rules):
        rand_v = random.randint(2, 3)
        if rand_v == 2:
            l = allow_ip()
        elif rand_v == 3:
            l = allow_port()
        elif rand_v == 4:
            pass
        else:
            pass
        iptable_rules.append(l)
    spec_str = code_gen(iptable_rules)
    print(spec_str)
    print("-------")
    constant_synthesis_str = constant_synthesis_gen(thirty_two_bit_dic, sixteen_bit_dic, eight_bit_dic)
    print(constant_synthesis_str)

if __name__ == "__main__":
    main(sys.argv)