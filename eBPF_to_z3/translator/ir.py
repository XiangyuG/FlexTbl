from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional


@dataclass(frozen=True)
class FieldInfo:
    name: str
    bits: int


@dataclass(frozen=True)
class StructInfo:
    name: str
    fields: list[FieldInfo]


@dataclass(frozen=True)
class MapInfo:
    name: str
    key_bits: int
    value_bits: Optional[int] = None
    value_struct: Optional[str] = None
    z3_name: Optional[str] = None

    @property
    def is_struct_value(self) -> bool:
        return self.value_struct is not None


@dataclass(frozen=True)
class Expr:
    pass


@dataclass(frozen=True)
class PtrExists(Expr):
    ptr: str


@dataclass(frozen=True)
class PtrMissing(Expr):
    ptr: str


@dataclass(frozen=True)
class DerefEq(Expr):
    ptr: str
    value: int


@dataclass(frozen=True)
class FieldEq(Expr):
    ptr: str
    field: str
    value: int


@dataclass(frozen=True)
class Stmt:
    pass


@dataclass(frozen=True)
class BindConst(Stmt):
    name: str
    value: int
    bits: int


@dataclass(frozen=True)
class Lookup(Stmt):
    ptr: str
    map_name: str
    key_var: str


@dataclass(frozen=True)
class IfReturn(Stmt):
    cond: Expr


@dataclass(frozen=True)
class IfBlock(Stmt):
    cond: Expr
    body: list[Stmt]


@dataclass(frozen=True)
class IncrementDeref(Stmt):
    ptr: str
    amount: int = 1


@dataclass(frozen=True)
class IncrementField(Stmt):
    ptr: str
    field: str
    amount: int = 1


@dataclass
class Program:
    name: str
    structs: dict[str, StructInfo] = field(default_factory=dict)
    maps: dict[str, MapInfo] = field(default_factory=dict)
    statements: list[Stmt] = field(default_factory=list)


@dataclass(frozen=True)
class PacketAssign:
    name: str
    struct_type: str
    base: str
    offset_struct: Optional[str] = None


@dataclass(frozen=True)
class PacketBoundsCheck:
    ptr: str
    ptr_struct: str


@dataclass(frozen=True)
class PacketTotalCheck:
    structs: list[str]


@dataclass
class PacketProgram:
    name: str
    statements: list[PacketAssign | PacketBoundsCheck | PacketTotalCheck] = field(default_factory=list)
