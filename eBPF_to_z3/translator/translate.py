from __future__ import annotations

import argparse
from pathlib import Path

from .packet_z3_emit import generate_packet_z3
from .z3_emit import generate_z3


def detect_translation_kind(orig_path: str, opt_path: str, relation: str | None, packet_spec: str | None) -> str:
    source = Path(orig_path).read_text() + "\n" + Path(opt_path).read_text()
    has_map = "bpf_map_lookup_elem" in source
    has_packet = "data_end" in source and ("sizeof(struct" in source or "> data_end" in source)

    if relation:
        return "map"
    if packet_spec:
        return "packet"
    if has_packet:
        return "packet"
    if has_map:
        return "map"
    raise ValueError("could not infer translator kind from input programs")


def main() -> None:
    parser = argparse.ArgumentParser(description="Translate a restricted eBPF-C pair into a Z3 equivalence checker.")
    parser.add_argument("--orig", required=True, help="Original eBPF C program")
    parser.add_argument("--opt", required=True, help="Optimized eBPF C program")
    parser.add_argument("--relation", help="JSON relation/precondition spec for map-merging programs")
    parser.add_argument("--packet-spec", help="Optional JSON header-size/observable spec for packet parsers")
    parser.add_argument("--out", required=True, help="Generated Python/Z3 script")
    args = parser.parse_args()

    try:
        kind = detect_translation_kind(args.orig, args.opt, args.relation, args.packet_spec)
    except ValueError as exc:
        parser.error(str(exc))

    if kind == "map":
        if not args.relation:
            parser.error("--relation is required for map-merging programs")
        output = generate_z3(args.orig, args.opt, args.relation)
    else:
        output = generate_packet_z3(args.orig, args.opt, args.packet_spec)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(output)
    print(f"wrote {out_path}")


if __name__ == "__main__":
    main()
