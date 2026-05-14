# eBPF-C to Z3 Translator

This is a small rule-based translator for restricted eBPF-C patterns.

## Map-Counter Programs

The translator recognizes the Katran packet-counter patterns automatically:

- `__u32 key = 0;`
- `ptr = bpf_map_lookup_elem(&map, &key);`
- early-return guards such as `if (!ptr) return ...;`
- scalar guards such as `if (!ptr || (*ptr == 0)) return ...;`
- struct-field guards such as `if (ptr->flag == 0) return ...;`
- increments such as `*ptr += 1;` and `ptr->counter += 1;`

The relation between original and optimized maps is not guessed from C. It is
specified in JSON so map-merging proofs remain explicit.

Example:

```bash
python -m eBPF_to_z3.translator.translate \
  --orig eBPF_to_z3/katran_xdp_pktcntr.c \
  --opt eBPF_to_z3/katran_xdp_pktcntr_opt.c \
  --relation eBPF_to_z3/katran_relation.json \
  --out eBPF_to_z3/katran_xdp_pktcntr_gen_z3.py

python eBPF_to_z3/katran_xdp_pktcntr_gen_z3.py
```

## Packet-Parser Programs

The translator recognizes packet parser/bounds-check patterns automatically:

- `ptr = (struct hdr *)data;`
- `next = (struct next_hdr *)(ptr + 1);`
- `if (unlikely(ptr + 1 > data_end)) return ...;`
- `required_end = data + sizeof(struct ...) + ...;`
- `if (unlikely(required_end > data_end)) return ...;`

Header sizes and observable pointer names are provided by JSON.

Example:

```bash
python -m eBPF_to_z3.translator.translate \
  --orig eBPF_to_z3/parse_pkt_tcp.c \
  --opt eBPF_to_z3/parse_pkt_tcp_opt.c \
  --packet-spec eBPF_to_z3/parse_pkt_tcp_spec.json \
  --out eBPF_to_z3/parse_pkt_tcp_gen_z3.py

python eBPF_to_z3/parse_pkt_tcp_gen_z3.py
```

## Internals

The translator intentionally has three parts:

1. `frontend.py`: restricted eBPF-C pattern parser.
2. `ir.py`: typed semantic IR.
3. `z3_emit.py` and `packet_z3_emit.py`: Z3 Python generators.
