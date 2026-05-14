from z3 import *

# ------------------------------------------------
# Symbolic packet memory
# ------------------------------------------------

mem = Array(
    'mem',
    BitVecSort(64),
    BitVecSort(8)
)

# ------------------------------------------------
# Symbolic pointers
# ------------------------------------------------

data = BitVec('data', 64)

data_end = BitVec('data_end', 64)

# ------------------------------------------------
# Header sizes
# ------------------------------------------------

ETH_SZ = BitVecVal(14, 64)
IP_SZ  = BitVecVal(20, 64)
TCP_SZ = BitVecVal(20, 64)
TS_SZ  = BitVecVal(12, 64)

# ------------------------------------------------
# Original parser
# ------------------------------------------------

eth_orig = data

origin_cond = BoolVal(True)

iph_orig = BitVec('iph_orig', 64)
iph_orig = If(eth_orig + ETH_SZ <= data_end, eth_orig + ETH_SZ, iph_orig)
origin_cond = And(origin_cond, eth_orig + ETH_SZ <= data_end)

tcph_orig = BitVec('tcph_orig', 64)
tcph_orig = If(And(origin_cond, iph_orig + IP_SZ <= data_end), iph_orig + IP_SZ, BitVecVal(0, 64))
origin_cond = And(origin_cond, iph_orig + IP_SZ <= data_end)

ts_opt_orig = If(And(origin_cond, tcph_orig + TCP_SZ <= data_end), tcph_orig + TCP_SZ, BitVecVal(0, 64))
origin_cond = And(origin_cond, tcph_orig + TCP_SZ <= data_end)

# ------------------------------------------------
# Optimized parser
# ------------------------------------------------

TOTAL = ETH_SZ + IP_SZ + TCP_SZ + TS_SZ

opt_cond = (

    data + TOTAL <= data_end
)

eth_opt = If(opt_cond, data, BitVecVal(0, 64))
iph_opt = If(opt_cond, eth_opt + ETH_SZ, BitVecVal(0, 64))
tcph_opt = If(opt_cond, iph_opt + IP_SZ, BitVecVal(0, 64))
ts_opt_opt = If(opt_cond, tcph_opt + TCP_SZ, BitVecVal(0, 64))

# ------------------------------------------------
# Equivalence proof
# ------------------------------------------------

s = Solver()

# Search for counterexample
ret_cond = And(orig_cond != opt_cond)

s.add(data == BitVecVal(0, 64))
s.add(orig_cond != opt_cond)

result = s.check()

print(result)

if result == sat:
    print("Counterexample:")
    print(s.model())
else:
    print("Equivalent")