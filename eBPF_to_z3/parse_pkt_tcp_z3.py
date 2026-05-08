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

eth = data

iph = eth + ETH_SZ

tcph = iph + IP_SZ

ts_opt = tcph + TCP_SZ

orig_cond = And(

    eth + ETH_SZ <= data_end,

    iph + IP_SZ <= data_end,

    tcph + TCP_SZ <= data_end,

    ts_opt + TS_SZ <= data_end
)

# ------------------------------------------------
# Optimized parser
# ------------------------------------------------

TOTAL = ETH_SZ + IP_SZ + TCP_SZ + TS_SZ

opt_cond = (

    data + TOTAL <= data_end
)

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