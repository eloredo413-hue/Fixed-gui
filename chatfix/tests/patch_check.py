import sys, lupa
lua = lupa.LuaRuntime(unpack_returned_tuples=False)
lua.execute("loadstring = load; warn = function(...) print('WARN', ...) end")
block = open('../ChatFix.lua', encoding='utf8').read()
lua.execute(block)  # defines local ChatFix -> make it global for the test
lua.execute(block.replace("local ChatFix =", "ChatFix =", 1))
patch = lua.eval("function(s, l) return ChatFix.Patch(s, l) end")
bad = 0
for path in sys.argv[1:]:
    name = path.split('/')[-1]
    src = open(path, encoding='utf8').read()
    out = patch(src, name)
    ok = out != src and out.startswith("local Chat2017Fx")
    for needle in ["RelayoutChats() return RemovedMessage", "RichText = true; Text = chatMessageDisplayText;",
                   "RichText = true; Text = systemMessageDisplayText;", "Chat2017Fx.NameColor or playerColor",
                   "Chat2017Fx.Handle(this, msg)", "Chat2017Fx.Escape(msg.Text)", "function this:RelayoutChats()"]:
        if needle not in out:
            print("  MISSING in", name, ":", needle); ok = False
    again = patch(out, name)   # second pass must change nothing
    if again != out: print("  second pass changed the source"); ok = False
    print(name, "PATCHED OK" if ok else "FAILED", len(src), "->", len(out))
    bad += (not ok)
sys.exit(bad)
