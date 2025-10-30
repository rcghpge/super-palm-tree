import ctypes, sys
from pathlib import Path

def _lib_candidates():
    root = Path(__file__).resolve().parents[2]
    out = root / "out"
    candidates = []

    if sys.platform.startswith("win"):
        # Windows Multi-config
        for cfg in ("Release", "Debug", "RelWithDebInfo", "MinSizeRel"):
            candidates += [out / cfg / "bin" / "abi.dll",
                           out / cfg / "lib" / "abi.dll"]

        # Fallback
        candidates += [out / "bin" / "abi.dll", out / "lib" / "abi.dll"]
    elif sys.platform == "darwin":
        candidates += [out / "lib" / "libabi.dylib"]
    else:
        # Linux/FreeBSD
        candidates += [out / "lib" / "libabi.so"]

    return [p for p in candidates if p.exists()]

def _load_lib():
    for p in _lib_candidates():
        try:
            return ctypes.CDLL(str(p))
        except OSError:
            continue
    raise FileNotFoundError("ABI shared library not found in ./out. Build with CMake first.")

_lib = _load_lib()

class AbiPoint(ctypes.Structure):
    _fields_ = [("x", ctypes.c_int32), ("y", ctypes.c_int32)]

_lib.abi_add_i32.argtypes = (ctypes.c_int32, ctypes.c_int32)
_lib.abi_add_i32.restype  = ctypes.c_int32

_lib.abi_dot2f.argtypes = (ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float)
_lib.abi_dot2f.restype  = ctypes.c_double

_lib.abi_is_positive.argtypes = (ctypes.c_double,)
_lib.abi_is_positive.restype  = ctypes.c_bool

_lib.abi_make_point.argtypes = (ctypes.c_int32, ctypes.c_int32)
_lib.abi_make_point.restype  = AbiPoint

_lib.abi_manhattan.argtypes = (AbiPoint,)
_lib.abi_manhattan.restype  = ctypes.c_int64

_lib.abi_hello.argtypes = (ctypes.c_char_p,)
_lib.abi_hello.restype  = ctypes.c_char_p

_lib.abi_free.argtypes = (ctypes.c_void_p,)
_lib.abi_free.restype  = None

def add_i32(a:int, b:int) -> int:
    return int(_lib.abi_add_i32(a, b))

def dot2f(a0:float, a1:float, b0:float, b1:float) -> float:
    return float(_lib.abi_dot2f(a0, a1, b0, b1))

def is_positive(v:float) -> bool:
    return bool(_lib.abi_is_positive(v))

def make_point(x:int, y:int) -> AbiPoint:
    return _lib.abi_make_point(x, y)

def manhattan(p:AbiPoint) -> int:
    return int(_lib.abi_manhattan(p))

def hello(name:str|None=None) -> str:
    raw = _lib.abi_hello(name.encode("utf-8") if name is not None else None)
    if not raw:
        return ""
    try:
        s = ctypes.string_at(raw).decode("utf-8", errors="replace")
        return s
    finally:
        _lib.abi_free(raw)
