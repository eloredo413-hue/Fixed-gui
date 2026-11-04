import sys, os, lupa
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
lua = lupa.LuaRuntime(unpack_returned_tuples=False)
chk = lua.eval("function(s) local f, e = load(s) if f then return 'compiles' end return 'does not compile: ' .. tostring(e):sub(1,110) end")
for name in ("2017_gui.lua", "2019_gui.lua", "2021_gui.lua", "2023_old_gui.lua"):
    o = chk(open(f"{root}/original/{name}", encoding="utf8").read())
    f = chk(open(f"{root}/fixed/{name}", encoding="utf8").read())
    print(f"{name:18} original: {o}\n{'':18} fixed:    {f}")
