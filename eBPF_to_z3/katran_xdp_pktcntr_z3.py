from z3 import *

#
# ============================================================
# eBPF Map-Merging Equivalence Verification in Z3
# ============================================================
#
# Original version:
#
#   ctl_array[0] controls whether we increment
#   cntrs_array[0] stores the packet counter
#
# Optimized version:
#
#   both values are merged into ONE map:
#
#     merged_map[0] = flag
#     merged_map[1] = counter
#
# Goal:
#
#   Verify both programs produce the same observable result.
#
# ============================================================
#

# ------------------------------------------------------------
# Constants
# ------------------------------------------------------------

FLAG_KEY  = BitVecVal(0, 32)
CNTR_KEY  = BitVecVal(0, 32)

MERGED_FLAG_KEY = BitVecVal(0, 32)
MERGED_CNTR_KEY = BitVecVal(1, 32)

# ------------------------------------------------------------
# Original Program State
# ------------------------------------------------------------

ctl_array_0_flag = Array(
    "ctl_array_0_flag",
    BitVecSort(32),
    BitVecSort(1)
)

ctl_array_0 = Array(
    "ctl_array_0",
    BitVecSort(32),
    BitVecSort(32)
)

cntrs_array_0_flag = Array(
    "cntrs_array_0_flag",
    BitVecSort(32),
    BitVecSort(1)
)

cntrs_array_0 = Array(
    "cntrs_array_0",
    BitVecSort(32),
    BitVecSort(64)
)

# ------------------------------------------------------------
# Optimized Program State
# ------------------------------------------------------------

Val = Datatype('Val')

Val.declare(
    'mkVal',

    ('x', BitVecSort(32)),
    ('y', BitVecSort(64))
)

Val = Val.create()

merged_map_0_flag = Array(
    "merged_map_0_flag",
    BitVecSort(32),
    BitVecSort(1)
)

merged_map_0 = Array(
    "merged_map_0",
    BitVecSort(32),
    Val
)

# ------------------------------------------------------------
# Relational Assumptions
#
# ------------------------------------------------------------

preconditions = [
    (Select(ctl_array_0_flag, FLAG_KEY) & Select(cntrs_array_0_flag, CNTR_KEY)) == Select(merged_map_0_flag, MERGED_FLAG_KEY),
    Select(ctl_array_0, FLAG_KEY) == Val.x(Select(merged_map_0, MERGED_FLAG_KEY)),
    Select(cntrs_array_0, CNTR_KEY) == Val.y(Select(merged_map_0, MERGED_CNTR_KEY))
]

# ============================================================
# Original Program Semantics
# ============================================================

ctl_array_0_flag_v = Select(ctl_array_0_flag, FLAG_KEY)
ctl_array_0_v = Select(ctl_array_0, FLAG_KEY)
cntrs_array_0_flag_v = Select(cntrs_array_0_flag, CNTR_KEY)
cntrs_array_0_v = Select(cntrs_array_0, CNTR_KEY)

cntrs_array_0_1 = If(
    And(ctl_array_0_flag_v != BitVecVal(0, 1), ctl_array_0_v == BitVecVal(0, 32), cntrs_array_0_flag_v != BitVecVal(0, 1)),

    Store(
        cntrs_array_0,
        CNTR_KEY,
        cntrs_array_0_v + BitVecVal(1, 64)
    ),

    cntrs_array_0
)

orig_counter_after = Select(
    cntrs_array_0_1,
    CNTR_KEY
)

# ============================================================
# Optimized Program Semantics
# ============================================================

merged_map_0_flag_v = Select(merged_map_0_flag, MERGED_FLAG_KEY)
merged_map_0_v = Select(merged_map_0, MERGED_FLAG_KEY)


opt_merged_map_1 = If(
    And(merged_map_0_flag_v != BitVecVal(0, 1), Val.x(merged_map_0_v) == BitVecVal(0, 32)),

    Store(
        merged_map_0,
        MERGED_CNTR_KEY,
        Val.mkVal(Val.x(Select(merged_map_0, MERGED_FLAG_KEY)), Val.y(Select(merged_map_0, MERGED_CNTR_KEY)) + BitVecVal(1, 64))
    ),

    merged_map_0
)
opt_counter_after = Val.y(Select(opt_merged_map_1, MERGED_CNTR_KEY))

# ============================================================
# Equivalence Check
#
# We prove:
#
#   final counter values are equal
#
# ============================================================

s = Solver()

s.add(preconditions)

# Try to find a counterexample
s.add(
        orig_counter_after != opt_counter_after
)

# ------------------------------------------------------------
# Result
# ------------------------------------------------------------

result = s.check()

print("Verification result:", result)

if result == sat:
    print("\nCounterexample found:\n")
    print(s.model())
else:
    print("\nPrograms are equivalent.")