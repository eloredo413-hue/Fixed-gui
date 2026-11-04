import re, lupa
lua = lupa.LuaRuntime(unpack_returned_tuples=False)
block = open('../ChatFix.lua', encoding='utf8').read()
runtime = re.search(r"local RUNTIME = \[==\[\n(.*?)\]==\]", block, re.S).group(1)
runtime = runtime.replace("local Chat2017Fx =", "Chat2017Fx =", 1)

lua.execute("""
-- minimal Roblox stand-ins
local me = {UserId = 1, Name = "me"}
local other = {UserId = 2, Name = "other"}
local players = {LocalPlayer = me}
function players:GetPlayerByUserId(id) if id == 1 then return me elseif id == 2 then return other end end
local tcs = {}
local lighting = {FindFirstChild = function() return nil end}
game = {GetService = function(_, n) return ({Players = players, TextChatService = tcs, Lighting = lighting})[n] end}
Enum = {TextChatMessageStatus = {Success = 'Success'}, PlayerChatType = {All = 'All'}}
Color3 = {fromRGB = function(r, g, b) return string.format('rgb(%d,%d,%d)', r, g, b) end}
task = {spawn = function(f, ...) f(...) end, wait = function() end}   -- run inline; the poll loop is skipped below
warn = function(...) print('WARN', ...) end
-- the game's own chat-colour callback (what a chat colour command sets up)
GAME_CALLS = 0
local function gameCallback(m)
  GAME_CALLS = GAME_CALLS + 1
  if m.Text == 'colourme' then
    return {Text = '<font color="#00ff00">colourme</font>', PrefixText = '<font color="#ff8800">[me]:</font>'}
  end
  return nil
end
getcallbackvalue = function(obj, prop) return gameCallback end
""")
# run the injected runtime, but stop its endless poll loop after the first pass
lua.execute("task.spawn = function(f, ...) end")
lua.execute(runtime)
lua.execute("task.spawn = function(f, ...) f(...) end")

lua.execute("""
-- a fake chat window that records what it was asked to show
SHOWN = {}
CHAT = {ChatWindowWidget = {AddSystemChatMessage = function(_, t) SHOWN[#SHOWN+1] = {kind='system', text=t} end}}
function CHAT:OnPlayerChatted(ptype, plr, text, _)
  SHOWN[#SHOWN+1] = {kind='player', who=plr.Name, text=text, nameColor=Chat2017Fx.NameColor}
end
-- like the engine: runs the callback first (the wrapper is what's installed now)
function deliver(msg)
  if tcs_cb then tcs_cb(msg) end
  Chat2017Fx.Handle(CHAT, msg)
end
""")
lua.execute("tcs_cb = game:GetService('TextChatService').OnIncomingMessage")
assert lua.eval("tcs_cb ~= nil"), "wrapper was not installed on TextChatService"

lua.execute("""
local src2 = {UserId = 2}
local src1 = {UserId = 1}
deliver({MessageId='a', Status='Success', Text='hello &lt;3 it&apos;s', TextSource = src2})
deliver({MessageId='b', Status='Success', Text='colourme', TextSource = src1})
deliver({MessageId='c', Status='Success', Text='<font color="#ff0000">Server restarting</font>', TextSource = nil})
deliver({MessageId='d', Status='Success', Text='', TextSource = nil})
deliver({MessageId='e', Status='Failed',  Text='blocked', TextSource = src2})
""")
shown = lua.eval("SHOWN")
rows = [dict(shown[i]) for i in range(1, len(shown) + 1)]
for r in rows: print(r)
assert len(rows) == 3, "expected 3 lines (empty + failed ones skipped)"
assert rows[0]['text'] == "hello &lt;3 it&apos;s" and rows[0].get('nameColor') is None
assert rows[1]['text'] == '<font color="#00ff00">colourme</font>' and rows[1]['nameColor'] == 'rgb(255,136,0)'
assert rows[2]['kind'] == 'system' and rows[2]['text'] == '<font color="#ff0000">Server restarting</font>'
assert lua.eval("Chat2017Fx.NameColor") is None
print("game callback still ran for every message:", lua.eval("GAME_CALLS"))
print("escape test:", lua.eval("Chat2017Fx.Escape('<b>hi</b> & \"x\"')"))
print("ALL RUNTIME CHECKS PASSED")
