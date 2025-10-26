import re
import matplotlib.pyplot as plt
import numpy as np

# ---- Raw trace output ----
raw_data = r"""
b'           <...>-54778   [052] ..s1. 98129.610898: bpf_trace_printk: Pass Latency: 30 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.612157: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.613362: bpf_trace_printk: Pass Latency: 31 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.614584: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.615793: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.617119: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.618331: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.619523: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.620714: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.621909: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.623109: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.624311: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.625509: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.626710: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.627916: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.629109: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.630508: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.631712: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.632902: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.634099: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.635285: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.636473: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.637655: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.638852: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.640039: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.641226: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.642432: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.643622: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.645017: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.646222: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.647410: bpf_trace_printk: Pass Latency: 27 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.648598: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.649783: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.650982: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.652173: bpf_trace_printk: Pass Latency: 30 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.653357: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.654548: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.655734: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.656922: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.658113: bpf_trace_printk: Pass Latency: 31 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.659512: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.660711: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.661895: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.663087: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.664272: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.665458: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.666648: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.667833: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.669019: bpf_trace_printk: Pass Latency: 30 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.670211: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.671395: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.672580: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.673974: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.675179: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.676363: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.677545: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.678740: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.679927: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.681111: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.682299: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.683479: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.684662: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.685846: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.687035: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.688426: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.689619: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.690807: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.691991: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.693173: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.694364: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.695544: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.696727: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.697907: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.699097: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.700277: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.701454: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.702850: bpf_trace_printk: Pass Latency: 27 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.704043: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.705223: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.706410: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.707589: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.708771: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.709953: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.711146: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.712324: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.713503: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.714691: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.715882: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.717303: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.718505: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.719685: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.720862: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.722052: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.723238: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.724415: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.725594: bpf_trace_printk: Pass Latency: 31 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.726781: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.727960: bpf_trace_printk: Pass Latency: 29 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.729142: bpf_trace_printk: Pass Latency: 28 ns\\n'
b'           <...>-54778   [052] ..s1. 98129.730339: bpf_trace_printk: Pass Latency: 29 ns\\n'
"""

# ---- Step 1: Extract numeric latency values ----
latencies = [int(x) for x in re.findall(r'Latency:\s+(\d+)\s+ns', raw_data)]

# ---- Step 2: Basic statistics ----
mean_latency = np.mean(latencies)
median_latency = np.median(latencies)
p99_latency = np.percentile(latencies, 99)

print(f"Count: {len(latencies)} samples")
print(f"Mean: {mean_latency:.2f} ns")
print(f"Median: {median_latency:.2f} ns")
print(f"99th Percentile: {p99_latency:.2f} ns")

# ---- Step 3: Plot histogram ----
plt.figure(figsize=(8, 5))
plt.hist(latencies, bins=range(min(latencies), max(latencies)+1), color='steelblue', edgecolor='black', alpha=0.7)
plt.title("Latency (naive approach + PASS) Distribution (ns)")
plt.xlabel("Latency (ns)")
plt.ylabel("Count")
plt.grid(axis='y', linestyle='--', alpha=0.7)

# Annotate key stats
plt.axvline(mean_latency, color='red', linestyle='--', linewidth=1.5, label=f'Mean: {mean_latency:.1f} ns')
plt.axvline(median_latency, color='green', linestyle='--', linewidth=1.5, label=f'Median: {median_latency:.1f} ns')
plt.axvline(p99_latency, color='orange', linestyle='--', linewidth=1.5, label=f'P99: {p99_latency:.1f} ns')
plt.legend()

plt.tight_layout()

# ---- Step 4: Save to PDF ----
output_file = "latency_distribution.pdf"
plt.savefig(output_file, format='pdf')
print(f"Saved plot to {output_file}")
