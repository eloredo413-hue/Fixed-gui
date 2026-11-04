import sys, lupa
lua = lupa.LuaRuntime(unpack_returned_tuples=False)
chk = lua.eval("function(s) local f, e = load(s) if f then return 'OK' end return 'FAIL: ' .. tostring(e) end")
for path in sys.argv[1:]:
    src = open(path, encoding='utf8').read().replace("local RBXGeneral: TextChannel =", "local RBXGeneral =")
    print(path.split('/')[-1], chk(src)[:200])
