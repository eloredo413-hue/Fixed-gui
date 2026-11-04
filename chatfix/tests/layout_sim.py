import re, lupa
lua = lupa.LuaRuntime(unpack_returned_tuples=False)
block = open('../ChatFix.lua', encoding='utf8').read()
relayout = re.search(r"local RELAYOUT = \[==\[\n(.*?)\]==\]", block, re.S).group(1)

lua.execute("""
function UDim2_new(xs, xo, ys, yo) return {X = {Scale = xs, Offset = xo}, Y = {Scale = ys, Offset = yo}} end
UDim2 = {new = UDim2_new}
""")
lua.execute("""
function simulate(fixed, relayoutSrc)
  local this = {Chats = {}, MessageContainer = {Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,0,0)},
                ScrollingFrame = {CanvasSize = UDim2.new(0,0,0,0), CanvasPosition = {Y = 0}}}
  function this:SetCanvasPosition(p) end
  if fixed then load(relayoutSrc, 'relayout', 't', setmetatable({this = this, ipairs = ipairs, UDim2 = UDim2}, {__index = _G}))() end
  local H, WINDOW, MAX = 18, 90, 50
  local function remove(msg)
    for i, m in ipairs(this.Chats) do
      if m == msg then
        this.ScrollingFrame.CanvasSize = UDim2.new(0,0,0, this.ScrollingFrame.CanvasSize.Y.Offset - m.gui.Size.Y.Offset)
        local r = table.remove(this.Chats, i)
        if fixed then this:RelayoutChats() end   -- what the patched RemoveChatMessage does
        return r
      end
    end
  end
  for n = 1, 200 do
    local m = {gui = {Position = UDim2.new(0,0,0,0), Size = UDim2.new(1,0,0,H)}, id = n}
    function m:GetGui() return self.gui end
    this.Chats[#this.Chats + 1] = m
    local y = this.MessageContainer.Size.Y.Offset
    m.gui.Position = UDim2.new(0,0,0, m.gui.Position.Y.Offset + y)
    this.MessageContainer.Size = UDim2.new(1,0,0, y + H)
    this.ScrollingFrame.CanvasSize = UDim2.new(0,0,0, this.ScrollingFrame.CanvasSize.Y.Offset + H)
    if MAX < #this.Chats then remove(this.Chats[1]) end
  end
  -- scrolled to the bottom: which messages are inside the visible window?
  local canvas = this.ScrollingFrame.CanvasSize.Y.Offset
  local top, visible = canvas - WINDOW, 0
  local lastBottom = 0
  for _, m in ipairs(this.Chats) do
    local y0 = m.gui.Position.Y.Offset
    if y0 + H > top and y0 < canvas then visible = visible + 1 end
    lastBottom = math.max(lastBottom, y0 + H)
  end
  return canvas, lastBottom, visible, #this.Chats
end
""")
sim = lua.eval("simulate")
for label, fixed in (("BEFORE fix", False), ("AFTER fix ", True)):
    canvas, lastBottom, visible, count = sim(fixed, relayout)
    print(f"{label}: 200 messages sent, {count} kept | canvas height {canvas} | newest message ends at {lastBottom} | messages visible at bottom: {visible}")
