-- [[ CHAT FIX BLOCK ]]
-- Shared by the 2017 / 2019 / 2021 / 2023 old GUIs. They all use the same
-- 2017 chat window (Chat.lua), which has two bugs:
--
--   1. Scroll / vanishing bug. When the window passes 50 messages it drops
--      the oldest one and shrinks the canvas, but never moves the remaining
--      messages up or shrinks their container. Every message after that is
--      drawn further below the canvas, so you get a blank box that can't be
--      scrolled and (once enough was trimmed) shows nothing at all.
--
--   2. Colours. Message text was drawn as plain text, so colour tags
--      (<font color="...">) never rendered. Messages that come from the game
--      (red server messages, DisplaySystemMessage) were ignored or had their
--      tags stripped, and the text colour that chat-colour commands set
--      (TextChatService.OnIncomingMessage) never reached this window.
--
-- ChatFix.Patch(source, label) takes the Chat module source, fixes both and
-- returns the new source. If a fix can't be applied it is skipped, and if the
-- result doesn't compile the original source is returned untouched.

local ChatFix = (function()

	local Fix = {}

	-- Goes at the very top of the chat module. One copy of this lives in each
	-- chat window, plus one shared record of what the game's chat callback did.
	local RUNTIME = [==[
local Chat2017Fx = (function()
	local Fx = {}
	local Players = game:GetService("Players")
	local TextChatService = game:GetService("TextChatService")
	local Env = (getgenv or function() return _G end)()

	local Shared = Env.Chat2017FixShared
	if type(Shared) ~= "table" then
		Shared = { Records = {}, Order = {}, Calls = 0, Misses = 0 }
		Env.Chat2017FixShared = Shared
	end

	-- Message text from TextChatService is escaped ("&lt;") and the label now
	-- reads rich text, so text that isn't escaped yet gets escaped here.
	function Fx.Escape(Text)
		Text = tostring(Text)
		Text = string.gsub(Text, "&", "&amp;")
		Text = string.gsub(Text, "<", "&lt;")
		Text = string.gsub(Text, ">", "&gt;")
		Text = string.gsub(Text, '"', "&quot;")
		Text = string.gsub(Text, "'", "&apos;")
		return Text
	end

	-- What the game's OnIncomingMessage callback returned for each message
	-- (this is where chat colour commands put their colours). The callback
	-- can't be read normally, so it is read with getcallbackvalue and wrapped.
	local function record(Message, Props)
		local Id = Message.MessageId
		Shared.Calls = Shared.Calls + 1
		Shared.Records[Id] = Props or false
		table.insert(Shared.Order, Id)
		if #Shared.Order > 300 then
			for _ = 1, 100 do
				Shared.Records[table.remove(Shared.Order, 1)] = nil
			end
		end
	end

	local function wrapCallback()
		if not getcallbackvalue then return end
		local Ok, Current = pcall(getcallbackvalue, TextChatService, "OnIncomingMessage")
		if not Ok or type(Current) ~= "function" or Current == Shared.Wrapper then return end
		local Original = Current
		local Wrapper = function(Message)
			local Props = Original(Message)
			pcall(record, Message, Props)
			return Props
		end
		local Set = pcall(function()
			TextChatService.OnIncomingMessage = Wrapper
		end)
		if Set then
			Shared.Wrapper = Wrapper
		end
	end

	if not Shared.Polling then
		Shared.Polling = true
		pcall(wrapCallback)
		task.spawn(function()
			while true do
				task.wait(2)
				pcall(wrapCallback)
			end
		end)
	end

	local function parseColor(Text)
		if type(Text) ~= "string" then return nil end
		Text = string.lower(Text)
		local Hex = string.match(Text, 'color%s*=%s*["\']?#(%x%x%x%x%x%x)')
		if Hex then
			return Color3.fromRGB(
				tonumber(string.sub(Hex, 1, 2), 16),
				tonumber(string.sub(Hex, 3, 4), 16),
				tonumber(string.sub(Hex, 5, 6), 16)
			)
		end
		local R, G, B = string.match(Text, 'color%s*=%s*["\']?rgb%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)')
		if R then
			return Color3.fromRGB(tonumber(R), tonumber(G), tonumber(B))
		end
		return nil
	end

	-- Name colour for the message being added right now (the window reads it).
	Fx.NameColor = nil

	function Fx.Process(Chat, Msg, Props)
		if Msg.Status ~= Enum.TextChatMessageStatus.Success then return end

		local Text, Prefix = Msg.Text, nil
		if Props then
			local Ok, PropText, PropPrefix = pcall(function()
				return Props.Text, Props.PrefixText
			end)
			if Ok then
				if type(PropText) == "string" and PropText ~= "" then
					Text = PropText
				end
				Prefix = PropPrefix
			end
		end

		if type(Text) ~= "string" or Text == "" then return end

		local Window = Chat.ChatWindowWidget
		if not Window then return end

		-- From the game itself (red server messages and so on): its own line,
		-- tags kept so its colours show.
		if not Msg.TextSource then
			Window:AddSystemChatMessage(Text)
			return
		end

		local Plr = Players:GetPlayerByUserId(Msg.TextSource.UserId)
		if not Plr then return end

		local Skip = false
		pcall(function()
			local Flag = game:GetService("Lighting"):FindFirstChild("LocalChatsAreUnfiltered")
			if Flag and Flag.Value and Plr == Players.LocalPlayer then
				Skip = true
			end
		end)
		if Skip then return end

		Fx.NameColor = parseColor(Prefix)
		local Ok, Err = pcall(Chat.OnPlayerChatted, Chat, Enum.PlayerChatType.All, Plr, Text, nil)
		Fx.NameColor = nil
		if not Ok then
			warn("[Chat fix] " .. tostring(Err))
		end
	end

	-- Messages are added one at a time, in order. When the game has a chat
	-- callback, each one waits a moment for what the callback made of it.
	local Queue, Working = {}, false

	function Fx.Handle(Chat, Msg)
		table.insert(Queue, { Chat, Msg })
		if Working then return true end
		Working = true
		task.spawn(function()
			while #Queue > 0 do
				local Item = table.remove(Queue, 1)
				local Message = Item[2]
				local Props = Shared.Records[Message.MessageId]
				if Props == nil and Shared.Wrapper and Shared.Misses < 5 then
					local Started = os.clock()
					repeat
						task.wait()
					until Shared.Records[Message.MessageId] ~= nil or os.clock() - Started > 0.25
					Props = Shared.Records[Message.MessageId]
					-- the callback never runs here: stop waiting for it
					if Props == nil and Shared.Calls == 0 then
						Shared.Misses = Shared.Misses + 1
					end
				end
				if Props == false then Props = nil end
				local Ok, Err = pcall(Fx.Process, Item[1], Message, Props)
				if not Ok then
					warn("[Chat fix] " .. tostring(Err))
				end
			end
			Working = false
		end)
		return true
	end

	return Fx
end)()
]==]

	-- Put right before RemoveOldestMessage: lays every message out again,
	-- one under the other from the top, and sizes the container and canvas
	-- to match.
	local RELAYOUT = [==[
function this:RelayoutChats()
	local Frame = this.ScrollingFrame
	local Container = this.MessageContainer
	if not (Frame and Container) then return end
	local Y = 0
	for _, Message in ipairs(this.Chats) do
		local Gui = Message:GetGui()
		if Gui then
			Gui.Position = UDim2.new(0, 0, 0, Y)
			Y = Y + Gui.Size.Y.Offset
		end
	end
	Container.Position = UDim2.new(0, 0, 0, 0)
	Container.Size = UDim2.new(Container.Size.X.Scale, Container.Size.X.Offset, 0, Y)
	Frame.CanvasSize = UDim2.new(Frame.CanvasSize.X.Scale, Frame.CanvasSize.X.Offset, Frame.CanvasSize.Y.Scale, Y)
	this:SetCanvasPosition(Frame.CanvasPosition)
end

]==]

	-- { name, pattern, replacement(match, captures...) }
	local PATCHES = {
		{
			"drop type annotation",
			"local RBXGeneral: TextChannel =",
			function() return "local RBXGeneral =" end,
		},
		{
			"layout after trim (1/2)",
			"function%s+this:RemoveOldestMessage%(%)",
			function(Match) return RELAYOUT .. Match end,
		},
		{
			"layout after trim (2/2)",
			"return%s+table%.remove%(%s*this%.Chats%s*,%s*index%s*%)",
			function()
				return "local RemovedMessage = table.remove(this.Chats, index) this:RelayoutChats() return RemovedMessage"
			end,
		},
		{
			"rich text on player messages",
			"Text%s*=%s*chatMessageDisplayText%s*;",
			function() return "RichText = true; Text = chatMessageDisplayText;" end,
		},
		{
			"rich text on system messages",
			"Text%s*=%s*systemMessageDisplayText%s*;",
			function() return "RichText = true; Text = systemMessageDisplayText;" end,
		},
		{
			"name colour",
			"TextColor3%s*=%s*playerColor%s*;",
			function() return "TextColor3 = (Chat2017Fx.NameColor or playerColor);" end,
		},
		{
			"receive handler",
			"RBXGeneral%.MessageReceived:Connect%(%s*function%s*%(msg%)",
			function(Match) return Match .. " if Chat2017Fx.Handle(this, msg) then return end " end,
		},
		{
			"escape your own message",
			"OnPlayerChatted%(([^%)]-),%s*msg%.Text%s*,%s*nil%s*%)",
			function(Before)
				return "OnPlayerChatted(" .. Before .. ", Chat2017Fx.Escape(msg.Text), nil)"
			end,
			true, -- optional
		},
	}

	function Fix.Patch(Source, Label)
		Label = Label or "chat"
		if type(Source) ~= "string" then return Source end

		-- Already fixed (a second pass would double up the patches).
		if string.find(Source, "Chat2017Fx", 1, true) then
			return Source
		end

		local Patched = Source
		local Applied, Skipped = {}, {}

		for _, Patch in ipairs(PATCHES) do
			local Name, Pattern, Replace, Optional = Patch[1], Patch[2], Patch[3], Patch[4]
			local Result, Count = string.gsub(Patched, Pattern, Replace)
			if Count >= 1 then
				Patched = Result
				table.insert(Applied, Name)
			elseif not Optional and Name ~= "drop type annotation" then
				table.insert(Skipped, Name)
			end
		end

		-- the runtime is only needed when something uses it
		if string.find(Patched, "Chat2017Fx", 1, true) then
			Patched = RUNTIME .. Patched
		end

		if #Skipped > 0 then
			warn("[Chat fix] " .. Label .. ": could not apply: " .. table.concat(Skipped, ", "))
		end

		-- never leave the chat worse than it was: if the fixed source doesn't
		-- compile, use the original
		local Compiled, CompileError = loadstring(Patched)
		if not Compiled then
			warn("[Chat fix] " .. Label .. ": fixed chat did not compile, using the original (" .. tostring(CompileError) .. ")")
			return Source
		end

		print("[Chat fix] " .. Label .. ": applied " .. #Applied .. " fixes")
		return Patched
	end

	return Fix

end)()
-- [[ END CHAT FIX BLOCK ]]
