from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .frontend import parse_c_subset
from .ir import (
    DerefEq,
    FieldEq,
    IfBlock,
    IfReturn,
    IncrementDeref,
    IncrementField,
    Lookup,
    MapInfo,
    Program,
    PtrExists,
    PtrMissing,
)


@dataclass
class PointerBinding:
    map_name: str
    key_expr: str


class Z3ProgramEmitter:
    def __init__(self, program: Program, side: str, relation: dict[str, Any]):
        self.program = program
        self.side = side
        self.relation = relation
        self.ptrs: dict[str, PointerBinding] = {}
        self.consts: dict[str, str] = {}
        self.path = "BoolVal(True)"
        self.map_versions = {name: self._map_array_name(name) for name in program.maps}
        self.lines: list[str] = []
        self.update_counter = 0

    def emit_semantics(self) -> list[str]:
        self.lines.append(f"# {self.side} program: {self.program.name}")
        for stmt in self.program.statements:
            self._emit_stmt(stmt)
        return self.lines

    def observable_expr(self, obs: dict[str, Any]) -> str:
        map_name = obs["map"]
        key_expr = self._key_const(obs["key"])
        field = obs.get("field")
        value_expr = f"Select({self.map_versions[map_name]}, {key_expr})"
        if field:
            return self._field_expr(value_expr, self.program.maps[map_name], field)
        return value_expr

    def _emit_stmt(self, stmt):
        if hasattr(stmt, "name") and hasattr(stmt, "value") and hasattr(stmt, "bits"):
            self.consts[stmt.name] = f"BitVecVal({stmt.value}, {stmt.bits})"
            return
        if isinstance(stmt, Lookup):
            self.ptrs[stmt.ptr] = PointerBinding(stmt.map_name, self.consts[stmt.key_var])
            return
        if isinstance(stmt, IfReturn):
            self.path = self._and(self.path, self._not(self._cond_expr(stmt.cond)))
            return
        if isinstance(stmt, IfBlock):
            saved = self.path
            self.path = self._and(self.path, self._cond_expr(stmt.cond))
            for child in stmt.body:
                self._emit_stmt(child)
            self.path = saved
            return
        if isinstance(stmt, IncrementDeref):
            self._emit_increment(stmt.ptr, None, stmt.amount)
            return
        if isinstance(stmt, IncrementField):
            self._emit_increment(stmt.ptr, stmt.field, stmt.amount)
            return
        raise ValueError(f"unsupported statement {stmt}")

    def _emit_increment(self, ptr: str, field: str | None, amount: int):
        binding = self.ptrs[ptr]
        map_info = self.program.maps[binding.map_name]
        old_map = self.map_versions[binding.map_name]
        new_map = f"{self._map_array_name(binding.map_name)}_{self.update_counter + 1}"
        self.update_counter += 1

        old_value = f"Select({old_map}, {binding.key_expr})"
        if field is None:
            updated_value = f"{old_value} + BitVecVal({amount}, {map_info.value_bits})"
        else:
            updated_value = self._struct_update_expr(old_map, map_info, binding.key_expr, field, amount)

        self.lines.extend(
            [
                f"{new_map} = If(",
                f"    {self.path},",
                f"    Store({old_map}, {binding.key_expr}, {updated_value}),",
                f"    {old_map}",
                ")",
                "",
            ]
        )
        self.map_versions[binding.map_name] = new_map

    def _cond_expr(self, cond) -> str:
        if isinstance(cond, tuple) and cond[0] == "or":
            return f"Or({self._cond_expr(cond[1])}, {self._cond_expr(cond[2])})"
        if isinstance(cond, PtrExists):
            binding = self.ptrs[cond.ptr]
            return f"Select({self._map_flag_name(binding.map_name)}, {binding.key_expr}) != BitVecVal(0, 1)"
        if isinstance(cond, PtrMissing):
            binding = self.ptrs[cond.ptr]
            return f"Select({self._map_flag_name(binding.map_name)}, {binding.key_expr}) == BitVecVal(0, 1)"
        if isinstance(cond, DerefEq):
            binding = self.ptrs[cond.ptr]
            map_info = self.program.maps[binding.map_name]
            return f"Select({self._map_array_name(binding.map_name)}, {binding.key_expr}) == BitVecVal({cond.value}, {map_info.value_bits})"
        if isinstance(cond, FieldEq):
            binding = self.ptrs[cond.ptr]
            map_info = self.program.maps[binding.map_name]
            value = f"Select({self._map_array_name(binding.map_name)}, {binding.key_expr})"
            field_expr = self._field_expr(value, map_info, cond.field)
            field_bits = self._field_bits(map_info, cond.field)
            return f"{field_expr} == BitVecVal({cond.value}, {field_bits})"
        raise ValueError(f"unsupported condition {cond}")

    def _struct_update_expr(self, map_name: str, map_info: MapInfo, key_expr: str, field: str, amount: int) -> str:
        struct = self.program.structs[map_info.value_struct]
        args = []
        for item in struct.fields:
            current = self._field_expr(f"Select({map_name}, {key_expr})", map_info, item.name)
            if item.name == field:
                current = f"{current} + BitVecVal({amount}, {item.bits})"
            args.append(current)
        return f"{self._datatype_name(map_info)}.mk{self._datatype_name(map_info)}({', '.join(args)})"

    def _field_expr(self, value_expr: str, map_info: MapInfo, field: str) -> str:
        return f"{self._datatype_name(map_info)}.{field}( {value_expr} )".replace("( ", "(").replace(" )", ")")

    def _field_bits(self, map_info: MapInfo, field: str) -> int:
        struct = self.program.structs[map_info.value_struct]
        for item in struct.fields:
            if item.name == field:
                return item.bits
        raise ValueError(f"unknown field {field} in {map_info.value_struct}")

    def _map_array_name(self, map_name: str) -> str:
        override = self.relation.get("z3_names", {}).get(self.side, {}).get(map_name)
        return override or f"{map_name}_0"

    def _map_flag_name(self, map_name: str) -> str:
        return f"{self._map_array_name(map_name)}_flag"

    def _datatype_name(self, map_info: MapInfo) -> str:
        return self.relation.get("datatypes", {}).get(map_info.value_struct, map_info.value_struct.title().replace("_", ""))

    def _key_const(self, key: int) -> str:
        return f"BitVecVal({key}, 32)"

    def _not(self, expr: str) -> str:
        return f"Not({expr})"

    def _and(self, left: str, right: str) -> str:
        if left == "BoolVal(True)":
            return right
        return f"And({left}, {right})"


def generate_z3(orig_path: str | Path, opt_path: str | Path, relation_path: str | Path) -> str:
    relation = json.loads(Path(relation_path).read_text())
    orig = parse_c_subset(orig_path, "original")
    opt = parse_c_subset(opt_path, "optimized")

    lines = [
        "from z3 import *",
        "",
        "# Generated by eBPF_to_z3.translator.translate",
        "",
    ]
    lines.extend(_emit_declarations(orig, opt, relation))
    lines.extend(_emit_preconditions(relation))

    orig_emitter = Z3ProgramEmitter(orig, "original", relation)
    opt_emitter = Z3ProgramEmitter(opt, "optimized", relation)
    lines.append("# Original Program Semantics")
    lines.extend(orig_emitter.emit_semantics())
    lines.append("# Optimized Program Semantics")
    lines.extend(opt_emitter.emit_semantics())

    orig_obs = orig_emitter.observable_expr(relation["observable"]["original"])
    opt_obs = opt_emitter.observable_expr(relation["observable"]["optimized"])
    lines.extend(
        [
            "# Equivalence Check",
            "s = Solver()",
            "s.add(preconditions)",
            f"s.add({orig_obs} != {opt_obs})",
            "",
            "result = s.check()",
            'print("Verification result:", result)',
            "if result == sat:",
            '    print("\\nCounterexample found:\\n")',
            "    print(s.model())",
            "else:",
            '    print("\\nPrograms are equivalent.")',
            "",
        ]
    )
    return "\n".join(lines)


def _emit_declarations(orig: Program, opt: Program, relation: dict[str, Any]) -> list[str]:
    lines: list[str] = ["# Declarations"]
    emitted_datatypes = set()
    for program in [orig, opt]:
        for map_info in program.maps.values():
            if map_info.value_struct and map_info.value_struct not in emitted_datatypes:
                datatype = relation.get("datatypes", {}).get(map_info.value_struct, map_info.value_struct.title())
                struct = program.structs[map_info.value_struct]
                lines.append(f"{datatype} = Datatype('{datatype}')")
                fields = ", ".join(f"('{field.name}', BitVecSort({field.bits}))" for field in struct.fields)
                lines.append(f"{datatype}.declare('mk{datatype}', {fields})")
                lines.append(f"{datatype} = {datatype}.create()")
                lines.append("")
                emitted_datatypes.add(map_info.value_struct)

    for side, program in [("original", orig), ("optimized", opt)]:
        for map_info in program.maps.values():
            z3_name = relation.get("z3_names", {}).get(side, {}).get(map_info.name, f"{map_info.name}_0")
            lines.append(f"{z3_name}_flag = Array('{z3_name}_flag', BitVecSort({map_info.key_bits}), BitVecSort(1))")
            if map_info.value_struct:
                datatype = relation.get("datatypes", {}).get(map_info.value_struct, map_info.value_struct.title())
                lines.append(f"{z3_name} = Array('{z3_name}', BitVecSort({map_info.key_bits}), {datatype})")
            else:
                lines.append(f"{z3_name} = Array('{z3_name}', BitVecSort({map_info.key_bits}), BitVecSort({map_info.value_bits}))")
            lines.append("")
    return lines


def _emit_preconditions(relation: dict[str, Any]) -> list[str]:
    lines = ["# Relational Assumptions", "preconditions = ["]
    for item in relation["preconditions"]:
        lines.append(f"    {item},")
    lines.extend(["]", ""])
    return lines

