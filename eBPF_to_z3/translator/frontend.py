from __future__ import annotations

import re
from pathlib import Path

from .ir import (
    BindConst,
    DerefEq,
    FieldEq,
    FieldInfo,
    IfBlock,
    IfReturn,
    IncrementDeref,
    IncrementField,
    Lookup,
    MapInfo,
    PacketAssign,
    PacketBoundsCheck,
    PacketProgram,
    PacketTotalCheck,
    Program,
    PtrExists,
    PtrMissing,
    StructInfo,
)


TYPE_BITS = {
    "__u8": 8,
    "__u16": 16,
    "__u32": 32,
    "__u64": 64,
}


def parse_c_subset(path: str | Path, program_name: str | None = None) -> Program:
    """Parse the restricted eBPF-C subset used by the Katran counter examples.

    This is intentionally pattern-based. The rest of the translator consumes a
    typed IR, so replacing this module with tree-sitter/clang later is contained.
    """

    source = _strip_comments(Path(path).read_text())
    name = program_name or Path(path).stem
    program = Program(name=name)
    program.structs.update(_parse_structs(source))
    program.maps.update(_parse_maps(source, program.structs))

    body = _extract_function_body(source, "pktcntr")
    program.statements = _parse_statements(_split_top_level_statements(body))
    return program


def parse_packet_parser_subset(path: str | Path, program_name: str | None = None) -> PacketProgram:
    """Parse the packet parser/bounds-check subset used by parse_pkt_tcp*.c."""

    source = _strip_comments(Path(path).read_text())
    name = program_name or Path(path).stem
    program = PacketProgram(name=name)
    pointer_structs: dict[str, str] = {}

    for stmt in _split_top_level_statements(source):
        normalized = " ".join(stmt.split())
        if not normalized or normalized.startswith("return "):
            continue

        required_match = re.match(r"void\s+\*\s*(\w+)\s*=\s*(?P<expr>.*?)\s*;", normalized)
        if required_match and "sizeof" in required_match.group("expr"):
            structs = re.findall(r"sizeof\s*\(\s*struct\s+(\w+)\s*\)", required_match.group("expr"))
            if structs:
                program.statements.append(PacketTotalCheck(structs))
            continue

        assign_match = re.match(
            r"(\w+)\s*=\s*\(struct\s+(\w+)\s*\*\)\s*(?P<rhs>.*?)\s*;",
            normalized,
        )
        if assign_match:
            target = assign_match.group(1)
            struct_type = assign_match.group(2)
            rhs = assign_match.group("rhs").strip()
            base, offset_struct = _parse_packet_rhs(rhs, pointer_structs)
            pointer_structs[target] = struct_type
            program.statements.append(PacketAssign(target, struct_type, base, offset_struct))
            continue

        check_match = re.match(r"if\s*\(\s*unlikely\s*\(\s*(\w+)\s*\+\s*1\s*>\s*data_end\s*\)\s*\)\s*\{.*\}\s*;?", normalized)
        if check_match:
            ptr = check_match.group(1)
            if ptr not in pointer_structs:
                raise ValueError(f"bounds check references unknown pointer {ptr}")
            program.statements.append(PacketBoundsCheck(ptr, pointer_structs[ptr]))
            continue

        total_check_match = re.match(r"if\s*\(\s*unlikely\s*\(\s*\w+\s*>\s*data_end\s*\)\s*\)\s*\{.*\}\s*;?", normalized)
        if total_check_match:
            # The preceding PacketTotalCheck carries the sizeof list.
            continue

    return program


def _strip_comments(source: str) -> str:
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
    source = re.sub(r"//.*", "", source)
    source = source.replace("```c", "").replace("```", "")
    return source


def _parse_packet_rhs(rhs: str, pointer_structs: dict[str, str]) -> tuple[str, str | None]:
    if rhs == "data":
        return "data", None
    plus_match = re.match(r"\(?\s*(\w+)\s*\+\s*1\s*\)?", rhs)
    if plus_match:
        base = plus_match.group(1)
        if base not in pointer_structs:
            raise ValueError(f"pointer assignment references unknown base {base}")
        return base, pointer_structs[base]
    raise ValueError(f"unsupported packet pointer rhs: {rhs}")


def _parse_structs(source: str) -> dict[str, StructInfo]:
    structs: dict[str, StructInfo] = {}
    for match in re.finditer(r"struct\s+(\w+)\s*\{(?P<body>.*?)\};", source, re.S):
        fields: list[FieldInfo] = []
        for field_match in re.finditer(r"(__u(?:8|16|32|64))\s+(\w+)\s*;", match.group("body")):
            fields.append(FieldInfo(field_match.group(2), TYPE_BITS[field_match.group(1)]))
        structs[match.group(1)] = StructInfo(match.group(1), fields)
    return structs


def _parse_maps(source: str, structs: dict[str, StructInfo]) -> dict[str, MapInfo]:
    maps: dict[str, MapInfo] = {}
    pattern = re.compile(r"struct\s*\{(?P<body>.*?)\}\s*(?P<name>\w+)\s+SEC\(\"\.maps\"\)\s*;", re.S)
    for match in pattern.finditer(source):
        body = match.group("body")
        key_bits = 32
        value_bits = None
        value_struct = None

        key_match = re.search(r"__type\s*\(\s*key\s*,\s*(__u(?:8|16|32|64))\s*\)", body)
        if key_match:
            key_bits = TYPE_BITS[key_match.group(1)]

        scalar_value_match = re.search(r"__type\s*\(\s*value\s*,\s*(__u(?:8|16|32|64))\s*\)", body)
        struct_value_match = re.search(r"__type\s*\(\s*value\s*,\s*struct\s+(\w+)\s*\)", body)
        if scalar_value_match:
            value_bits = TYPE_BITS[scalar_value_match.group(1)]
        elif struct_value_match:
            struct_name = struct_value_match.group(1)
            if struct_name not in structs:
                raise ValueError(f"map {match.group('name')} references unknown struct {struct_name}")
            value_struct = struct_name
        else:
            raise ValueError(f"could not parse value type for map {match.group('name')}")

        maps[match.group("name")] = MapInfo(match.group("name"), key_bits, value_bits, value_struct)
    return maps


def _extract_function_body(source: str, function_name: str) -> str:
    start_match = re.search(rf"\b{re.escape(function_name)}\s*\([^)]*\)\s*\{{", source)
    if not start_match:
        raise ValueError(f"could not find function {function_name}")
    open_index = start_match.end() - 1
    depth = 0
    for index in range(open_index, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[open_index + 1:index]
    raise ValueError(f"could not find end of function {function_name}")


def _split_top_level_statements(body: str) -> list[str]:
    statements: list[str] = []
    start = 0
    depth = 0
    index = 0
    while index < len(body):
        char = body[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                end = index + 1
                if end < len(body) and body[end] == ";":
                    end += 1
                stmt = body[start:end].strip()
                if stmt:
                    statements.append(stmt)
                start = end
        elif char == ";" and depth == 0:
            stmt = body[start:index + 1].strip()
            if stmt:
                statements.append(stmt)
            start = index + 1
        index += 1
    tail = body[start:].strip()
    if tail:
        statements.append(tail)
    return statements


def _parse_statements(raw_statements: list[str]) -> list:
    parsed = []
    for raw in raw_statements:
        stmt = " ".join(raw.split())
        if not stmt or stmt.startswith("return "):
            continue

        if stmt.startswith("if "):
            parsed.append(_parse_if(stmt))
            continue

        const_match = re.match(r"__(u(?:8|16|32|64))\s+(\w+)\s*=\s*(\d+)\s*;", stmt)
        if const_match:
            parsed.append(BindConst(const_match.group(2), int(const_match.group(3)), int(const_match.group(1)[1:])))
            continue

        lookup_match = re.match(
            r"(?:struct\s+\w+\s*\*\s*|__u(?:8|16|32|64)\s*\*\s*)?(\w+)\s*=\s*bpf_map_lookup_elem\s*\(&(\w+),\s*&(\w+)\)\s*;",
            stmt,
        )
        if lookup_match:
            parsed.append(Lookup(lookup_match.group(1), lookup_match.group(2), lookup_match.group(3)))
            continue

        field_inc_match = re.match(r"(\w+)->(\w+)\s*\+=\s*(\d+)\s*;", stmt)
        if field_inc_match:
            parsed.append(IncrementField(field_inc_match.group(1), field_inc_match.group(2), int(field_inc_match.group(3))))
            continue

        deref_inc_match = re.match(r"\*(\w+)\s*\+=\s*(\d+)\s*;", stmt)
        if deref_inc_match:
            parsed.append(IncrementDeref(deref_inc_match.group(1), int(deref_inc_match.group(2))))
            continue

    return parsed


def _parse_if(stmt: str):
    match = re.match(r"if\s*\((?P<cond>.*?)\)\s*\{(?P<body>.*)\}\s*;?", stmt)
    if not match:
        raise ValueError(f"unsupported if statement: {stmt}")
    cond = _parse_cond(match.group("cond"))
    body_text = match.group("body").strip()
    if re.search(r"\breturn\b", body_text):
        return IfReturn(cond)
    return IfBlock(cond, _parse_statements(_split_top_level_statements(body_text)))


def _parse_cond(cond: str):
    cond = " ".join(cond.split())
    if "||" in cond:
        parts = [part.strip() for part in cond.split("||")]
        # The current Katran pattern only uses "if (!ptr || (*ptr == 0)) return".
        if len(parts) == 2 and parts[0].startswith("!") and parts[1].startswith("(*"):
            ptr = parts[0][1:].strip()
            eq_match = re.match(r"\(\*(\w+)\s*==\s*(\d+)\)", parts[1])
            if eq_match and eq_match.group(1) == ptr:
                return ("or", PtrMissing(ptr), DerefEq(ptr, int(eq_match.group(2))))
        raise ValueError(f"unsupported disjunction: {cond}")
    if cond.startswith("!"):
        return PtrMissing(cond[1:].strip())
    if re.match(r"^\w+$", cond):
        return PtrExists(cond)
    field_eq = re.match(r"(\w+)->(\w+)\s*==\s*(\d+)", cond)
    if field_eq:
        return FieldEq(field_eq.group(1), field_eq.group(2), int(field_eq.group(3)))
    deref_eq = re.match(r"\(\*(\w+)\s*==\s*(\d+)\)", cond)
    if deref_eq:
        return DerefEq(deref_eq.group(1), int(deref_eq.group(2)))
    raise ValueError(f"unsupported condition: {cond}")
