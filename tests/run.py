"""Run each native-contract Lua test in its own Lua 5.4 state. Requires lupa."""
from pathlib import Path
import os
from lupa.lua54 import LuaRuntime

root = Path(__file__).resolve().parents[1]
os.chdir(root)
for path in sorted((root / "tests").glob("test_*.lua")):
    LuaRuntime(unpack_returned_tuples=True).execute(path.read_text(encoding="utf-8"))
    print("PASS", path.name)
