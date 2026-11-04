local TeleportService = game:GetService("TeleportService")
local Players         = game:GetService("Players")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Env = (getgenv and getgenv()) or _G

-- Once per server. Running this again (Confirm pressed twice, the GUI
-- picked from two menus, or run again after the rejoin) queued and
-- loaded a second copy of the chat and icon controller, and rejoined
-- again.
if Env.Old2023GuiStarted then
    local message = "2023 GUI is already running in this server (" .. tostring(Env.Settings2016Version or "build unknown")
        .. "). To load the newest version, leave the game, rejoin and run this script again."
    warn("[2023 GUI] " .. message)
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "Settings2016AlreadyGui"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 2147483647
        pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
        gui.Parent = CoreGui
        local label = Instance.new("TextLabel")
        label.Name = "Text"
        label.AnchorPoint = Vector2.new(0.5, 0)
        label.Position = UDim2.new(0.5, 0, 0, 50)
        label.AutomaticSize = Enum.AutomaticSize.XY
        label.Size = UDim2.fromOffset(0, 0)
        label.BackgroundColor3 = Color3.new(0, 0, 0)
        label.BackgroundTransparency = 0.3
        label.BorderSizePixel = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 16
        label.TextWrapped = true
        label.TextColor3 = Color3.fromRGB(255, 190, 80)
        label.Text = message
        label.Active = false
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 8)
        padding.PaddingRight = UDim.new(0, 8)
        padding.PaddingTop = UDim.new(0, 4)
        padding.PaddingBottom = UDim.new(0, 4)
        padding.Parent = label
        local limit = Instance.new("UISizeConstraint")
        limit.MaxSize = Vector2.new(560, 400)
        limit.Parent = label
        label.Parent = gui
        task.delay(12, function() gui:Destroy() end)
    end)
    return
end
Env.Old2023GuiStarted = true

local queue_teleport = queue_on_teleport or (syn and syn.queue_on_teleport)

pcall(function() setfflag("EnableInGameMenuChrome", "False") end)
pcall(function() setfflag("EnableInGameMenuChromeABTest3", "False") end)
pcall(function() setfflag("EnableInGameMenuChromeABTest4", "False") end)
pcall(function() setfflag("EnableInGameMenuControls", "True") end)
pcall(function() setfflag("EnableInGameMenuModernization", "True") end)
pcall(function() setfflag("EnableMenuControlsABTest", "False") end)
pcall(function() setfflag("EnableV3MenuABTest3", "False") end)
pcall(function() setfflag("EnableInGameMenuSongbirdABTest", "False") end)

-- ============================================================
-- ON-SCREEN STATUS
--
-- SHOW_STATUS: messages at the top when something is wrong (red / orange).
-- SHOW_LOADED: also a green "loaded" message naming the build. Off by default.
-- SHOW_HUD: a small line along the bottom edge saying what the menu is doing.
--   Off by default; turn it on (and SHOW_LOADED) when reporting a problem: a
--   screenshot or recording then also shows the menu's build and state.
--
-- USE_ORIGINAL_MENU_IF_NO_FIX: only if the fixed menu cannot be downloaded,
--   load the ORIGINAL (unfixed, crashes/old bugs) menu instead of none.
--   Off by default: a silent fall-back to the unfixed menu looks exactly like
--   "the bugs came back".
-- ============================================================
local SHOW_STATUS = true
local SHOW_LOADED = false
local SHOW_HUD = false
local USE_ORIGINAL_MENU_IF_NO_FIX = false

-- ============================================================
-- CHAT BOX
--
-- USE_2017_CHAT: the chat window is the 2017-19 chat box ("Tap here to chat"). If it cannot
--   be loaded, the old chat stays the chat window and an orange message says so.
--   false = always the old chat.
-- CHAT_OPEN_AT_START: the chat box starts open. By default it starts closed and the chat
--   icon in the top bar opens it.
-- ============================================================
local USE_2017_CHAT = true
local CHAT_OPEN_AT_START = false

-- ============================================================
-- IF THE ESC MENU STILL CRASHES ROBLOX OR MISBEHAVES
--
-- 1) Set ESC_TRACE = true, run this script, do the thing that goes wrong, and
--    paste me your clipboard: the whole trace (last 300 lines) is kept there
--    after every step (and written to workspace/Settings2016_trace.txt when
--    your executor can write files). If Roblox died, the LAST line is the
--    exact step that was running at that moment.
--
-- 2) Or find it yourself: turn one switch on at a time and see which one
--    makes the crash stop. Each switch skips one part of opening the menu.
-- ============================================================
local ESC_TRACE = false
local ESC_SAFE = {
    NoInputLock  = false, -- don't block movement/mouse keys while the menu is open
    NoCoreGui    = false, -- don't hide/show chat, player list and backpack
    NoNativeHide = false, -- don't touch Roblox's own settings menu objects
    NoTopBar     = false, -- don't switch the Roblox top bar off while open
}

local diagnosticsHeader = "local Env = (getgenv and getgenv()) or _G\n"
    .. "Env.EscLoaderShowStatus = " .. tostring(SHOW_STATUS) .. "\n"
    .. "Env.EscLoaderShowLoaded = " .. tostring(SHOW_LOADED) .. "\n"
    .. "Env.EscLoaderShowHud = " .. tostring(SHOW_HUD) .. "\n"
    .. "Env.EscLoaderOriginalFallback = " .. tostring(USE_ORIGINAL_MENU_IF_NO_FIX) .. "\n"
    .. "Env.EscLoaderUse2017Chat = " .. tostring(USE_2017_CHAT) .. "\n"
    .. "Env.EscLoaderChatOpen = " .. tostring(CHAT_OPEN_AT_START) .. "\n"
    .. "Env.Settings2016Trace = " .. tostring(ESC_TRACE) .. "\n"
    .. "Env.Settings2016Safe = {"
for name, on in pairs(ESC_SAFE) do
    diagnosticsHeader = diagnosticsHeader .. name .. " = " .. tostring(on == true) .. ", "
end
diagnosticsHeader = diagnosticsHeader .. "}\n"

local scriptToRun = diagnosticsHeader .. [=[
    local Env = (getgenv and getgenv()) or _G
    if Env.Old2023GuiPayloadRan then return end
    Env.Old2023GuiPayloadRan = true
    -- Running the 2023 GUI script again in this server must not rejoin.
    Env.Old2023GuiStarted = true

    local SHOW_STATUS = Env.EscLoaderShowStatus ~= false
    local SHOW_LOADED = Env.EscLoaderShowLoaded == true
    local SHOW_HUD = Env.EscLoaderShowHud == true
    local STATUS_GUI_NAME = "Settings2016StatusGui"
    local HUD_GUI_NAME = "Settings2016HudGui"

    ----------------------------------------------------------------
    -- Small on-screen status: which menu build is running and what it
    -- is doing. Turn it off with SHOW_STATUS / SHOW_HUD at the top of
    -- the script.
    ----------------------------------------------------------------
    local StatusGui, StatusLabel, StatusToken = nil, nil, 0
    local HudGui, HudLabel = nil, nil

    local function makeStatusGui(name)
        local gui = Instance.new("ScreenGui")
        gui.Name = name
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 2147483647
        pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
        pcall(function() gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None end)
        pcall(function() gui.Parent = game:GetService("CoreGui") end)
        if not gui.Parent then
            pcall(function() gui.Parent = gethui and gethui() end)
        end
        if not gui.Parent then
            pcall(function()
                gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
            end)
        end
        return gui
    end

    local function makeStatusLabel(gui, position, anchor, textSize, transparency)
        local label = Instance.new("TextLabel")
        label.Name = "Text"
        label.AnchorPoint = anchor
        label.Position = position
        label.AutomaticSize = Enum.AutomaticSize.XY
        label.Size = UDim2.fromOffset(0, 0)
        label.BackgroundColor3 = Color3.new(0, 0, 0)
        label.BackgroundTransparency = transparency
        label.BorderSizePixel = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = textSize
        label.TextWrapped = true
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Text = ""
        label.Active = false
        pcall(function() label.Interactable = false end)
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 8)
        padding.PaddingRight = UDim.new(0, 8)
        padding.PaddingTop = UDim.new(0, 4)
        padding.PaddingBottom = UDim.new(0, 4)
        padding.Parent = label
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = label
        local limit = Instance.new("UISizeConstraint")
        local viewWidth = 640
        pcall(function() viewWidth = workspace.CurrentCamera.ViewportSize.X - 40 end)
        limit.MaxSize = Vector2.new(math.max(200, math.min(640, viewWidth)), 400)
        limit.Parent = label
        label.Parent = gui
        return label
    end

    local GREEN = Color3.fromRGB(120, 255, 140)
    local ORANGE = Color3.fromRGB(255, 190, 80)
    local RED = Color3.fromRGB(255, 110, 110)

    local function showStatus(text, color, seconds)
        print("[Status] " .. text)
        if not SHOW_STATUS then return end
        if color == GREEN and not SHOW_LOADED then return end
        pcall(function()
            if not (StatusGui and StatusGui.Parent) then
                StatusGui = makeStatusGui(STATUS_GUI_NAME)
                StatusLabel = makeStatusLabel(StatusGui, UDim2.new(0.5, 0, 0, 50), Vector2.new(0.5, 0), 16, 0.3)
            end
            StatusLabel.Text = text
            StatusLabel.TextColor3 = color or GREEN
            StatusToken = StatusToken + 1
            local token = StatusToken
            task.delay(seconds or 10, function()
                if token == StatusToken and StatusGui then
                    pcall(function() StatusGui:Destroy() end)
                    StatusGui, StatusLabel = nil, nil
                end
            end)
        end)
    end

    -- A line along the bottom edge that follows what the menu is doing: a
    -- recording of a problem then shows the menu's state at that moment.
    local function startHud(getText)
        if not SHOW_HUD then return end
        task.spawn(function()
            local ok = pcall(function()
                HudGui = makeStatusGui(HUD_GUI_NAME)
                HudLabel = makeStatusLabel(HudGui, UDim2.new(0.5, 0, 1, -2), Vector2.new(0.5, 1), 11, 0.45)
                HudLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
                HudLabel.Font = Enum.Font.SourceSans
            end)
            if not ok then return end
            while HudGui and HudGui.Parent do
                local good, text = pcall(getText)
                if good and type(text) == "string" and HudLabel.Text ~= text then
                    HudLabel.Text = text
                end
                task.wait(0.4)
            end
        end)
    end

    print("[Payload] started")

    -- After a teleport this runs before the game has loaded, and the
    -- menu needs the Roblox GUI to be there.
    if not game:IsLoaded() then game.Loaded:Wait() end

    -- 1. Load the fixed ESC menu and show which build is running.
    -- Several tries (a changing query string stops GitHub's cache serving an older copy for a
    -- few minutes), the download is checked (build number, complete file), and the original
    -- menu is only used if USE_ORIGINAL_MENU_IF_NO_FIX is on.
    local MENU_URL = "https://raw.githubusercontent.com/eloredo413-hue/E/ccr-36205392-d1pxs7/2023_esc_menu.lua"
    local ORIGINAL_MENU_URL = "https://raw.githubusercontent.com/letsafe/something/refs/heads/main/2023escmenuv3.lua"
    local EXPECTED_BUILD = 5008 -- 2023-esc-v5.8
    local EXPECTED_NAME = "v5.8"

    local function buildOf(source)
        local tag = source:match('Settings2016Version%s*=%s*"([^"]+)"')
        local major, minor = tostring(tag):match("v(%d+)%.(%d+)")
        return (tonumber(major) or 0) * 1000 + (tonumber(minor) or 0), tag
    end

    local function fetch(url)
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if ok and type(body) == "string" and #body > 0 then return body end
        return nil, ok and "empty reply" or tostring(body)
    end

    local menuSource, menuTag, menuProblem, oldSource, oldTag
    for round = 1, 3 do
        for _, withBuster in ipairs({ true, false }) do
            local url = MENU_URL
            if withBuster then url = url .. "?cb=" .. tostring(os.time()) .. "_" .. round end
            local body, err = fetch(url)
            if not body then
                menuProblem = err
            else
                local build, tag = buildOf(body)
                if not tag then
                    menuProblem = "the reply is not the menu (" .. #body .. " bytes)"
                elseif build < EXPECTED_BUILD then
                    oldSource, oldTag = body, tag
                    menuProblem = "GitHub served an older copy (" .. tostring(tag) .. ")"
                elseif not body:find("end of 2023_esc_menu.lua", 1, true) then
                    menuProblem = "the download was cut short (" .. #body .. " bytes)"
                else
                    menuSource, menuTag = body, tag
                    break
                end
            end
            warn("[Payload] ESC menu download:", menuProblem)
        end
        if menuSource then break end
        task.wait(1)
    end

    local menuIsOld, menuIsOriginal = false, false
    if not menuSource and oldSource then
        menuSource, menuTag, menuIsOld = oldSource, oldTag, true
    end
    if not menuSource and Env.EscLoaderOriginalFallback == true then
        local body = fetch(ORIGINAL_MENU_URL)
        if body then menuSource, menuTag, menuIsOriginal = body, "ORIGINAL", true end
    end

    local function menuStatusText()
        local api = Env.Settings2016
        if api and type(api.GetStatus) == "function" then return api:GetStatus() end
        return "ESC menu: no status (" .. tostring(menuTag) .. ")"
    end

    if not menuSource then
        showStatus("2023 ESC menu NOT loaded: " .. tostring(menuProblem) .. ". Roblox's own menu is in use - rejoin and run the script again.", RED, 30)
    else
        local chunk, compileError = loadstring(menuSource)
        if not chunk then
            showStatus("2023 ESC menu " .. tostring(menuTag) .. " did not compile: " .. tostring(compileError), RED, 30)
        else
            local ran, runError = pcall(chunk)
            if not ran then
                warn("[Payload] ESC menu errored:", runError)
                showStatus("2023 ESC menu " .. tostring(menuTag) .. " ERROR while starting: " .. tostring(runError), RED, 30)
            elseif not menuIsOriginal and not Env.Settings2016 then
                showStatus("2023 ESC menu " .. tostring(menuTag) .. " did not finish starting (see the console / warnings).", RED, 30)
            elseif menuIsOriginal then
                showStatus("Using the ORIGINAL 2023 menu: the fixed copy could not be downloaded (" .. tostring(menuProblem) .. "). It has the old bugs.", ORANGE, 30)
            elseif menuIsOld then
                showStatus("2023 ESC menu " .. tostring(menuTag) .. " loaded, but it is an OLD cached copy (wanted " .. EXPECTED_NAME .. "). Rejoin in a few minutes.", ORANGE, 30)
            else
                showStatus("2023 ESC menu " .. tostring(menuTag) .. " loaded", GREEN, 8)
            end
            if ran then startHud(menuStatusText) end
        end
    end
    print("[Payload] ESC menu loaded")

    -- 2. Chat
    local Players          = game:GetService("Players")
    local CoreGui          = game:GetService("CoreGui")
    local StarterGui       = game:GetService("StarterGui")
    local UserInputService = game:GetService("UserInputService")
    local TextChatService  = game:GetService("TextChatService")

    -- 2a. The 2017-19 chat box: the chat window and chat bar of the 2017 core gui. Downloaded
    -- like the menu (a few tries, a changing query string, the download is checked). If it
    -- cannot be started, the old chat below stays the chat window and an orange message says so.
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
    
    local CHAT_BOX_URL = "https://raw.githubusercontent.com/eloredo413-hue/E/ccr-f33d83ed-bgaekc/2017_chat_box.lua"
    local EXPECTED_CHAT_REVISION = 1
    local chatBoxOk = false

    if Env.EscLoaderUse2017Chat ~= false then
        Env.Chat2017Skipped = nil
        local chatSource, chatProblem
        for round = 1, 3 do
            for _, withBuster in ipairs({ true, false }) do
                local url = CHAT_BOX_URL
                if withBuster then url = url .. "?cb=" .. tostring(os.time()) .. "_" .. round end
                local body, err = fetch(url)
                if not body then
                    chatProblem = err
                elseif (tonumber(body:match("Env%.Chat2017Revision = (%d+)")) or 0) < EXPECTED_CHAT_REVISION then
                    chatProblem = "the reply is not the chat box, or an older copy (" .. #body .. " bytes)"
                elseif not body:find("end of 2017_chat_box.lua", 1, true) then
                    chatProblem = "the download was cut short (" .. #body .. " bytes)"
                else
                    chatSource = body
                    break
                end
                warn("[Payload] chat box download:", chatProblem)
            end
            if chatSource then break end
            task.wait(1)
        end
        if chatSource then
            -- Chat fix: scroll / vanishing bug and colours
            chatSource = ChatFix.Patch(chatSource, "chat box")
            local chunk, compileError = loadstring(chatSource)
            if not chunk then
                chatProblem = "it did not compile: " .. tostring(compileError)
            else
                local ran, runError = pcall(chunk)
                if not ran then chatProblem = "it errored while starting: " .. tostring(runError) end
            end
        end
        chatBoxOk = type(Env.Chat2017) == "table"
        if chatBoxOk then
            print("[Payload] 2017 chat box started")
            if Env.EscLoaderChatOpen == true then pcall(Env.Chat2017.SetVisible, true) end
        elseif Env.Chat2017Skipped == "legacychat" then
            print("[Payload] this game has the legacy chat: no chat box needed")
        else
            local problem = "2017 chat box NOT loaded (" .. tostring(chatProblem or Env.Chat2017Skipped or "unknown reason") .. "): the old chat is used instead."
            -- A red or orange message that is already showing stays: this one goes under it.
            local current = StatusLabel and StatusLabel.Parent and StatusLabel.Text or ""
            if current ~= "" and StatusLabel.TextColor3 ~= GREEN then
                showStatus(current .. "\n" .. problem, StatusLabel.TextColor3, 30)
            else
                showStatus(problem, ORANGE, 20)
            end
        end
    end

    -- 2b. The old chat. It is still loaded as before, so whatever else it does stays as it was;
    -- only its window is not shown while the chat box runs.
    pcall(function()
        game:GetObjects("rbxassetid://122252029612413")[1].Parent = game.Workspace
    end)
    print("[Payload] workspace object loaded")

    local launched, launchError = pcall(function()
        local rbxmSuite = loadstring(game:HttpGet("https://raw.githubusercontent.com/yeku/forks/refs/heads/main/Scripts/RBXMSuite.luau"))()
        task.wait()
        rbxmSuite.launch("rbxassetid://111872120766790", {
            runscripts     = true,
            deferred       = true,
            nocache        = false,
            nocirculardeps = true,
            debug          = true,
            verbose        = false,
        })
    end)
    if not launched then
        warn("[Payload] old chat failed to load:", launchError)
        if not chatBoxOk then
            -- Keep the normal chat rather than switching it off with nothing
            -- to replace it.
            return
        end
    else
        print("[Payload] rbxmSuite launched")

        pcall(function()
            TextChatService.BubbleChatConfiguration.Enabled = false
        end)

        pcall(function() game:GetService("CoreGui").ExperienceChat.Enabled = false end)

        pcall(function()
            local chatGui = Players.LocalPlayer.PlayerGui:WaitForChild("Chat", 5)
            if chatGui then
                chatGui.Frame.Size = UDim2.new(0.4, 0, 0.35, 0)
                chatGui.Frame.ChatChannelParentFrame.Size = UDim2.new(1, -44, 1, -46)
                if chatGui.Frame.ResizeButton then
                    chatGui.Frame.ResizeButton:Destroy()
                end
            end
        end)
    end

    if chatBoxOk then
        -- The chat box is the chat window now: the old chat's window stays off (and comes
        -- back if the chat box is ever stopped).
        task.spawn(function()
            local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
            local function hideOldWindow(gui)
                if gui.Name ~= "Chat" or not gui:IsA("ScreenGui") then return end
                pcall(function() gui.Enabled = false end)
                gui:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if gui.Enabled and Env.Chat2017 then gui.Enabled = false end
                end)
            end
            for _, gui in ipairs(playerGui:GetChildren()) do hideOldWindow(gui) end
            playerGui.ChildAdded:Connect(hideOldWindow)
        end)
    end
    print("[Payload] chat gui prepped, starting icon controller")

    -- 3. TopBar Chat Icon Controller
    task.spawn(function()
        local Players             = game:GetService("Players")
        local RunService          = game:GetService("RunService")
        local UserInputService    = game:GetService("UserInputService")
        local ReplicatedStorage   = game:GetService("ReplicatedStorage")
        local CoreGui             = game:GetService("CoreGui")
        local VirtualInputManager = game:GetService("VirtualInputManager")

        local player    = Players.LocalPlayer

        local chatOffIcon = "rbxasset://textures/ui/TopBar/chatOff.png"
        local chatOnIcon  = "rbxasset://textures/ui/TopBar/chatOn.png"

        local ICON_SIZE     = 24
        local ICON_OFFSET_X = 0
        local ICON_OFFSET_Y = 0

        local BADGE_SIZE      = 18
        local BADGE_OFFSET_X  = -5
        local BADGE_OFFSET_Y  = 1
        local BADGE_TEXT_SIZE = 14

        local INSET_TOP    = 0
        local INSET_BOTTOM = 0
        local INSET_LEFT   = 0
        local INSET_RIGHT  = 0

        local NATIVE_INSET_TOP    = 0
        local NATIVE_INSET_BOTTOM = 0
        local NATIVE_INSET_LEFT   = 0
        local NATIVE_INSET_RIGHT  = 0

        local unreadCount = 0
        local chatOpen    = false
        local ourIcon     = nil
        local badgeOuter  = nil
        local badgeLabel  = nil
        local hookedBtn   = nil
        local pillTarget  = nil

        -- The ESC menu keeps a voice "BETA" badge inside the same top-bar frame, and this script
        -- puts its own icon inside the chat button: neither is ever "the chat button".
        local function isOwnObject(d)
            local cur = d
            for _ = 1, 40 do
                if not cur or cur == CoreGui then return false end
                local n = cur.Name
                if n:sub(1, 12) == "Settings2016" or n:sub(1, 10) == "LegacyChat" then
                    return true
                end
                cur = cur.Parent
            end
            return false
        end

        local function findNativeChatButton()
            local topBarApp = CoreGui:FindFirstChild("TopBarApp")
            if not topBarApp then return nil end

            for _, d in ipairs(topBarApp:GetDescendants()) do
                if d:IsA("GuiButton") and d.Visible and not isOwnObject(d) then
                    local n = d.Name:lower()
                    if (n == "chat" or n == "chatbutton" or n == "robloxchatbutton")
                       and not n:find("window") and not n:find("frame") then
                        return d
                    end
                end
            end

            -- Other builds name it differently ("ChatIcon", "chat_button" ...).
            for _, d in ipairs(topBarApp:GetDescendants()) do
                if d:IsA("GuiButton") and d.Visible and not isOwnObject(d) then
                    local n = d.Name:lower()
                    local s = d.AbsoluteSize
                    if n:find("chat", 1, true)
                       and not n:find("window") and not n:find("frame")
                       and not n:find("badge") and not n:find("legacy")
                       and s.X >= 20 and s.X <= 80 and s.Y >= 20 and s.Y <= 80 then
                        return d
                    end
                end
            end

            local list = {}
            for _, d in ipairs(topBarApp:GetDescendants()) do
                if d:IsA("GuiButton") and d.Visible and not isOwnObject(d) then
                    local p = d.AbsolutePosition
                    local s = d.AbsoluteSize
                    local sizeOk = s.X >= 26 and s.X <= 60 and s.Y >= 26 and s.Y <= 60
                    local posOk  = p.X >= 40 and p.X <= 130 and p.Y >= -60 and p.Y <= 20
                    if sizeOk and posOk then
                        table.insert(list, {btn = d, x = p.X})
                    end
                end
            end
            table.sort(list, function(a, b) return a.x < b.x end)
            return list[1] and list[1].btn
        end

        local function findPill(btn)
            if not btn then return nil end
            local btnSize = btn.AbsoluteSize
            local btnArea = btnSize.X * btnSize.Y
            if btnArea <= 0 then return nil end

            local best, bestArea = nil, 0
            for _, d in ipairs(btn:GetDescendants()) do
                if d:IsA("ImageLabel")
                   and d.Name ~= "LegacyChatIcon"
                   and d.Name ~= "LegacyChatBadge"
                   and d.Name ~= "LegacyChatBadgeChild"
                   and d.Name ~= "LegacyChatBadgeLabel"
                   and d.Visible then
                    local sz = d.AbsoluteSize
                    local area = sz.X * sz.Y
                    if area >= btnArea * 0.35 and area > bestArea then
                        best, bestArea = d, area
                    end
                end
            end
            return best or btn
        end

        local function hideNativeExtras(btn, pill)
            if not btn then return end

            if btn:IsA("ImageButton") then
                pcall(function() btn.ImageTransparency = 1 end)
            end

            for _, d in ipairs(btn:GetDescendants()) do
                if d == pill then
                elseif d.Name == "LegacyChatIcon"
                    or d.Name == "LegacyChatBadge"
                    or d.Name == "LegacyChatBadgeChild"
                    or d.Name == "LegacyChatBadgeLabel" then
                elseif d:IsA("ImageLabel") then
                    d.ImageTransparency = 1
                elseif d:IsA("Frame") then
                    d.BackgroundTransparency = 1
                    d.Visible = false
                elseif d:IsA("TextLabel") then
                    d.TextTransparency = 1
                end
            end
        end

        local function attachIcon(pill)
            if not pill then return end
            if ourIcon and ourIcon.Parent then ourIcon:Destroy() end

            pcall(function() pill.ClipsDescendants = true end)

            ourIcon = Instance.new("ImageLabel")
            ourIcon.Name                   = "LegacyChatIcon"
            ourIcon.AnchorPoint            = Vector2.new(0.5, 0.5)
            ourIcon.Position               = UDim2.new(0.5, ICON_OFFSET_X, 0.5, ICON_OFFSET_Y)
            ourIcon.Size                   = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
            ourIcon.BackgroundTransparency = 1
            ourIcon.Image                  = chatOpen and chatOnIcon or chatOffIcon
            ourIcon.ImageTransparency      = 0
            ourIcon.Visible                = true
            ourIcon.Active                 = false
            ourIcon.ZIndex                 = 500
            ourIcon.Parent                 = pill
            print("[LegacyChat] icon attached to", pill:GetFullName())
        end

        local function attachBadge(btn)
            if not btn then return end
            if badgeOuter and badgeOuter.Parent then badgeOuter:Destroy() end

            badgeOuter = Instance.new("Frame")
            badgeOuter.Name             = "LegacyChatBadge"
            badgeOuter.Parent           = btn
            badgeOuter.AnchorPoint      = Vector2.new(1, 0)
            badgeOuter.Position         = UDim2.new(1, BADGE_OFFSET_X, 0, BADGE_OFFSET_Y)
            badgeOuter.Size             = UDim2.new(0, BADGE_SIZE, 0, BADGE_SIZE)
            badgeOuter.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            badgeOuter.Visible          = false
            badgeOuter.Active           = false
            badgeOuter.ZIndex           = 520

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent       = badgeOuter

            local inner = Instance.new("Frame")
            inner.Name             = "LegacyChatBadgeChild"
            inner.Parent           = badgeOuter
            inner.Size             = UDim2.new(1, -3, 1, -3)
            inner.Position         = UDim2.new(0.5, 0, 0.5, 0)
            inner.AnchorPoint      = Vector2.new(0.5, 0.5)
            inner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            inner.Active           = false
            inner.ZIndex           = 521

            local innerCorner = Instance.new("UICorner")
            innerCorner.CornerRadius = UDim.new(1, 0)
            innerCorner.Parent       = inner

            badgeLabel = Instance.new("TextLabel")
            badgeLabel.Name                   = "LegacyChatBadgeLabel"
            badgeLabel.Parent                 = inner
            badgeLabel.Size                   = UDim2.new(1, 0, 1, 0)
            badgeLabel.Position               = UDim2.new(0.5, 0, 0.5, -1)
            badgeLabel.AnchorPoint            = Vector2.new(0.5, 0.5)
            badgeLabel.BackgroundTransparency = 1
            badgeLabel.Text                   = "0"
            badgeLabel.TextColor3             = Color3.fromRGB(0, 0, 0)
            badgeLabel.Font                   = Enum.Font.SourceSansBold
            badgeLabel.TextSize               = BADGE_TEXT_SIZE
            badgeLabel.ZIndex                 = 522
        end

        local function doToggle(source)
            local box = Env.Chat2017
            if box then
                -- the chat box opens and closes itself: the icon shows what it really is
                box.Toggle()
                chatOpen = box.GetVisible()
            else
                chatOpen = not chatOpen
            end
            print("[LegacyChat] toggle ("..source..") ->", chatOpen)

            if chatOpen then unreadCount = 0 end

            if ourIcon and ourIcon.Parent then
                ourIcon.Image = chatOpen and chatOnIcon or chatOffIcon
            end
        end

        local function hookButton(btn)
            if not btn then return end
            hookedBtn  = btn
            pillTarget = findPill(btn)

            print("[LegacyChat] Hooked:", btn.Name,
                  "pos=", btn.AbsolutePosition,
                  "size=", btn.AbsoluteSize)

            hideNativeExtras(btn, pillTarget)
            attachIcon(pillTarget)
            attachBadge(btn)
        end

        local function forwardClickToNative()
            if not hookedBtn or not hookedBtn.Parent then return end
            local center = hookedBtn.AbsolutePosition + hookedBtn.AbsoluteSize * 0.5
            task.spawn(function()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true,  game, 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
                end)
            end)
        end

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
               and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            if not pillTarget or not pillTarget.Parent then return end

            local pos
            if input.UserInputType == Enum.UserInputType.Touch then
                pos = Vector2.new(input.Position.X, input.Position.Y)
            else
                pos = UserInputService:GetMouseLocation()
            end

            local abs  = pillTarget.AbsolutePosition
            local size = pillTarget.AbsoluteSize

            local left   = abs.X + INSET_LEFT
            local right  = abs.X + size.X - INSET_RIGHT
            local top    = abs.Y + INSET_TOP
            local bottom = abs.Y + size.Y - INSET_BOTTOM

            if not (pos.X >= left and pos.X <= right
                    and pos.Y >= top and pos.Y <= bottom) then
                return
            end

            doToggle("pill")

            if hookedBtn and hookedBtn.Parent then
                local bAbs  = hookedBtn.AbsolutePosition
                local bSize = hookedBtn.AbsoluteSize

                local nLeft   = bAbs.X + NATIVE_INSET_LEFT
                local nRight  = bAbs.X + bSize.X - NATIVE_INSET_RIGHT
                local nTop    = bAbs.Y + NATIVE_INSET_TOP
                local nBottom = bAbs.Y + bSize.Y - NATIVE_INSET_BOTTOM

                local insideNative =
                    pos.X >= nLeft and pos.X <= nRight
                    and pos.Y >= nTop and pos.Y <= nBottom

                -- (the old chat is toggled by Roblox's own chat button; the chat box is not)
                if not insideNative and not Env.Chat2017 then
                    forwardClickToNative()
                end
            end
        end)

        task.spawn(function()
            local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if not events then return end
            local onMessage = events:FindFirstChild("OnMessageDoneFiltering")
            if not onMessage or not onMessage:IsA("RemoteEvent") then return end
            onMessage.OnClientEvent:Connect(function(data)
                if type(data) ~= "table" then return end
                if data.FromSpeaker == player.Name then return end
                if not chatOpen then unreadCount = unreadCount + 1 end
            end)
        end)

        task.spawn(function()
            local ok2, tcs = pcall(function()
                return game:GetService("TextChatService")
            end)
            if not ok2 or not tcs then return end
            pcall(function()
                tcs.MessageReceived:Connect(function(msg)
                    if not msg then return end
                    local src = msg.TextSource
                    if src and src.UserId == player.UserId then return end
                    if not chatOpen then unreadCount = unreadCount + 1 end
                end)
            end)
        end)

        print("[LegacyChat] scanning for chat button...")
        task.spawn(function()
            local deadline = tick() + 15
            while tick() < deadline do
                local btn = findNativeChatButton()
                if btn then
                    hookButton(btn)
                    return
                end
                RunService.Heartbeat:Wait()
            end
            warn("[LegacyChat] Native chat button not found after 15s.")
        end)

        task.spawn(function()
            while true do
                task.wait(1.5)
                if not (ourIcon and ourIcon.Parent) then
                    local ok, b = pcall(findNativeChatButton)
                    if ok and b and b ~= hookedBtn then
                        hookButton(b)
                    elseif ok and b and hookedBtn == b and not (ourIcon and ourIcon.Parent) then
                        hookButton(b)
                    end
                end
            end
        end)

        task.spawn(function()
            while true do
                local topBarApp = CoreGui:FindFirstChild("TopBarApp")
                if topBarApp then
                    topBarApp.DescendantAdded:Connect(function()
                        task.wait(0.1)
                        if not ourIcon or not ourIcon.Parent then
                            local b = findNativeChatButton()
                            if b then hookButton(b) end
                        end
                    end)
                    return
                end
                RunService.Heartbeat:Wait()
            end
        end)

        RunService.RenderStepped:Connect(function()
            -- The chat box can be opened and closed from elsewhere too (the 2023 menu hides the
            -- chat while it is open): the icon follows what it is.
            local box = Env.Chat2017
            if box then
                local open = box.GetVisible()
                if open ~= chatOpen then
                    chatOpen = open
                    if open then unreadCount = 0 end
                end
            end

            if pillTarget and pillTarget.Parent then
                pcall(function()
                    if pillTarget.ClipsDescendants ~= true then
                        pillTarget.ClipsDescendants = true
                    end
                end)
            end

            if ourIcon and ourIcon.Parent then
                local want = chatOpen and chatOnIcon or chatOffIcon
                if ourIcon.Image ~= want then ourIcon.Image = want end
                if ourIcon.Visible ~= true then ourIcon.Visible = true end
                if ourIcon.ImageTransparency ~= 0 then ourIcon.ImageTransparency = 0 end
                if ourIcon.Active ~= false then ourIcon.Active = false end

                local tPos  = UDim2.new(0.5, ICON_OFFSET_X, 0.5, ICON_OFFSET_Y)
                local tSize = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
                if ourIcon.Position    ~= tPos  then ourIcon.Position    = tPos  end
                if ourIcon.Size        ~= tSize then ourIcon.Size        = tSize end
                if ourIcon.AnchorPoint ~= Vector2.new(0.5, 0.5) then
                    ourIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                end
                if ourIcon.ZIndex < 500 then ourIcon.ZIndex = 500 end
            end

            if badgeOuter and badgeOuter.Parent and badgeLabel then
                if badgeOuter.Active ~= false then badgeOuter.Active = false end

                local tBadgePos = UDim2.new(1, BADGE_OFFSET_X, 0, BADGE_OFFSET_Y)
                if badgeOuter.Position ~= tBadgePos then
                    badgeOuter.Position = tBadgePos
                end

                if chatOpen or unreadCount == 0 then
                    if badgeOuter.Visible then badgeOuter.Visible = false end
                else
                    if not badgeOuter.Visible then badgeOuter.Visible = true end
                    local txt  = unreadCount >= 100 and "99+" or tostring(unreadCount)
                    local size = unreadCount >= 100 and 9
                               or (unreadCount >= 10 and 11 or BADGE_TEXT_SIZE)
                    if badgeLabel.Text ~= txt      then badgeLabel.Text     = txt  end
                    if badgeLabel.TextSize ~= size then badgeLabel.TextSize = size end
                end
            end

            if hookedBtn and hookedBtn.Parent
               and (not ourIcon or not ourIcon.Parent) then
                pillTarget = findPill(hookedBtn)
                hideNativeExtras(hookedBtn, pillTarget)
                attachIcon(pillTarget)
                attachBadge(hookedBtn)
            end

            if hookedBtn and not hookedBtn.Parent then
                hookedBtn  = nil
                ourIcon    = nil
                badgeOuter = nil
                badgeLabel = nil
                pillTarget = nil
                task.spawn(function()
                    task.wait(0.5)
                    local b = findNativeChatButton()
                    if b then hookButton(b) end
                end)
            end
        end)
    end)
]=]

local function loadHere()
    local ok, err = pcall(function()
        loadstring(scriptToRun)()
    end)
    if not ok then
        warn("[2023 GUI] failed to load:", err)
    end
end

-- Without queue_on_teleport the GUI would be lost in the rejoin, and
-- running this again afterwards would only rejoin again. Load it here.
if not (queue_teleport and pcall(queue_teleport, scriptToRun)) then
    warn("[2023 GUI] queue_on_teleport is not available; loading without the rejoin")
    loadHere()
    return
end

-- The GUI is not loaded in this server too: the teleport closes it while
-- the downloads and the chat's scripts are still starting. If the
-- rejoin fails, load it here instead.
TeleportService.TeleportInitFailed:Connect(function(player)
    if player == LocalPlayer then
        task.spawn(loadHere)
    end
end)

local teleported, teleportError = pcall(function()
    if #Players:GetPlayers() <= 1 then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end)

if not teleported then
    warn("[2023 GUI] could not rejoin:", teleportError)
    loadHere()
end