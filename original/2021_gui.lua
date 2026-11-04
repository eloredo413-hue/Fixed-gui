local TeleportService = game:GetService("TeleportService")
local Players         = game:GetService("Players")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

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
-- USE_MAIN_BRANCH_IF_NO_FIX: if the fixed 2019 menu cannot be downloaded,
--   load the older copy from the main branch instead of none (an orange
--   message says so).
-- ============================================================
local SHOW_STATUS = true
local SHOW_LOADED = false
local SHOW_HUD = false
local USE_MAIN_BRANCH_IF_NO_FIX = true

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
-- LEAVE / RESET CONFIRMATION PAGES (2019 ESC menu)
--
-- MATCH_LEAVE_TO_RESET: the "Are you sure you want to leave the game?" page is laid
--   out exactly like "Are you sure you want to reset your character?" (same question
--   position and size, same button positions and gap).
-- FIRST_BUTTON_BLUE: the first button of both pages ("Leave" and "Reset") is always
--   blue, as soon as the page opens, on touch screens too.
-- ============================================================
local MATCH_LEAVE_TO_RESET = true
local FIRST_BUTTON_BLUE = true

local scriptToRun = "local SHOW_STATUS = " .. tostring(SHOW_STATUS) .. "\n"
    .. "local SHOW_LOADED = " .. tostring(SHOW_LOADED) .. "\n"
    .. "local SHOW_HUD = " .. tostring(SHOW_HUD) .. "\n"
    .. "local USE_MAIN_BRANCH_IF_NO_FIX = " .. tostring(USE_MAIN_BRANCH_IF_NO_FIX) .. "\n"
    .. "local USE_2017_CHAT = " .. tostring(USE_2017_CHAT) .. "\n"
    .. "local CHAT_OPEN_AT_START = " .. tostring(CHAT_OPEN_AT_START) .. "\n"
    .. "local MATCH_LEAVE_TO_RESET = " .. tostring(MATCH_LEAVE_TO_RESET) .. "\n"
    .. "local FIRST_BUTTON_BLUE = " .. tostring(FIRST_BUTTON_BLUE) .. "\n"
    .. [=[
    local Env = (getgenv and getgenv()) or _G
    local STATUS_GUI_NAME = "Legacy2019StatusGui"
    local HUD_GUI_NAME = "Legacy2019HudGui"

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

    ----------------------------------------------------------------
    -- Leave / Reset confirmation pages of the 2019 ESC menu.
    --
    -- The two pages are built separately and came out different: the
    -- Leave page sat lower, with its buttons closer together. The
    -- Reset page is the one to follow, so the Leave page copies its
    -- layout (page size, question, button positions and sizes).
    -- The first button of each page ("Leave", "Reset") is kept blue,
    -- whatever the menu does to it (hover, selection, the touch-screen
    -- clean-up that turns blue buttons grey again).
    --
    -- The pages are found by their text, so this does not depend on
    -- how the menu names them. A page that is not on screen is
    -- unparented by the menu; it is still found through the menu's
    -- module records, or the nil instances.
    ----------------------------------------------------------------
    local BLUE_BUTTON = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButtonSelected.png"

    local QUESTIONS = {
        leave = { question = "leave the game", confirm = "leave" },
        reset = { question = "reset your character", confirm = "reset" },
    }

    local function textOf(object)
        local ok, text = pcall(function() return object.Text end)
        if ok and type(text) == "string" then
            return (text:lower():match("^%s*(.-)%s*$"))
        end
        return nil
    end

    local function isQuestion(object, kind)
        if not object:IsA("TextLabel") then return false end
        local text = textOf(object)
        return text ~= nil and text:find(QUESTIONS[kind].question, 1, true) ~= nil
    end

    -- The question, the page it sits on, and the two buttons.
    local function findParts(root, kind)
        local question = nil
        if isQuestion(root, kind) then
            question = root
        else
            for _, d in ipairs(root:GetDescendants()) do
                if isQuestion(d, kind) then question = d break end
            end
        end
        local page = question and question.Parent
        if not page then return nil end

        local word = QUESTIONS[kind].confirm
        local confirm, cancel = nil, nil
        for _, d in ipairs(page:GetDescendants()) do
            if d:IsA("GuiButton") and not (confirm and confirm:IsAncestorOf(d))
               and not (cancel and cancel:IsAncestorOf(d)) then
                local texts = { textOf(d) }
                for _, c in ipairs(d:GetDescendants()) do
                    local text = (c:IsA("TextLabel") or c:IsA("TextButton")) and textOf(c)
                    if text then table.insert(texts, text) end
                end
                for _, text in ipairs(texts) do
                    if text == word then
                        confirm = confirm or d
                    elseif text:find("^don") and text:find(word, 1, true) then
                        cancel = cancel or d
                    end
                end
            end
        end
        if not confirm then return nil end
        return { page = page, question = question, confirm = confirm, cancel = cancel }
    end

    local function stillValid(parts, kind)
        return parts ~= nil and parts.question.Parent == parts.page
            and isQuestion(parts.question, kind)
            and parts.confirm:IsDescendantOf(parts.page)
    end

    -- Places to look: the menu's gui, the menu's modules (the pages and the hub
    -- keep their page frames), and the objects with no parent.
    local function searchRoots(menuGui)
        local roots = {}
        if menuGui and menuGui.Parent then table.insert(roots, menuGui) end
        pcall(function()
            local records = Env.__rbxm_suite_modules
            if type(records) ~= "table" then return end
            local function addPage(value)
                if type(value) == "table" and typeof(rawget(value, "Page")) == "Instance" then
                    table.insert(roots, rawget(value, "Page"))
                end
            end
            for module, record in pairs(records) do
                if typeof(module) == "Instance" and type(record) == "table"
                   and (module.Name == "LeaveGame" or module.Name == "ResetCharacter"
                        or module.Name == "SettingsHub") then
                    local data = rawget(record, "data")
                    addPage(data)
                    local hub = type(data) == "table" and rawget(data, "Instance")
                    if type(hub) == "table" then
                        for _, value in pairs(hub) do addPage(value) end
                    end
                end
            end
        end)
        pcall(function()
            if type(getnilinstances) ~= "function" then return end
            for _, object in ipairs(getnilinstances()) do
                if typeof(object) == "Instance" and object:IsA("GuiObject") then
                    table.insert(roots, object)
                end
            end
        end)
        return roots
    end

    local function copyProps(from, to, props)
        for _, prop in ipairs(props) do
            pcall(function()
                local value = from[prop]
                if to[prop] ~= value then to[prop] = value end
            end)
        end
    end

    local function makeBlue(button)
        pcall(function()
            if button:IsA("ImageButton") and button.Image ~= BLUE_BUTTON then
                button.Image = BLUE_BUTTON
            end
        end)
    end

    local function matchLeaveToReset(leave, reset)
        copyProps(reset.page, leave.page, { "Size" })
        copyProps(reset.question, leave.question, {
            "AnchorPoint", "Position", "Size", "TextSize", "TextScaled", "TextWrapped",
            "TextXAlignment", "TextYAlignment",
        })
        for _, pair in ipairs({ { leave.confirm, reset.confirm }, { leave.cancel, reset.cancel } }) do
            local mine, theirs = pair[1], pair[2]
            if mine and theirs then
                -- The buttons hang off the same element as on the Reset page.
                if theirs.Parent == reset.question and mine.Parent ~= leave.question then
                    mine.Parent = leave.question
                elseif theirs.Parent == reset.page and mine.Parent ~= leave.page then
                    mine.Parent = leave.page
                end
                copyProps(theirs, mine, { "AnchorPoint", "Position", "Size" })
            end
        end
    end

    local function startConfirmPageFix()
        if not (MATCH_LEAVE_TO_RESET or FIRST_BUTTON_BLUE) then return end
        local RunService = game:GetService("RunService")
        local found = { leave = nil, reset = nil }

        task.spawn(function()
            local warned, started = false, os.clock()
            while Env.Legacy2019Menu do
                local missing = false
                for kind in pairs(QUESTIONS) do
                    if not stillValid(found[kind], kind) then
                        found[kind] = nil
                        missing = true
                    end
                end
                if missing then
                    local menuGui = game:GetService("CoreGui"):FindFirstChild("NewRobloxGui")
                    for _, root in ipairs(searchRoots(menuGui)) do
                        for kind in pairs(QUESTIONS) do
                            if not found[kind] then
                                local ok, parts = pcall(findParts, root, kind)
                                if ok and parts then
                                    found[kind] = parts
                                    print("[Payload] " .. kind .. " page found:", parts.page:GetFullName())
                                end
                            end
                        end
                        if found.leave and found.reset then break end
                    end
                    if not (found.leave and found.reset) and not warned and os.clock() - started > 30 then
                        warned = true
                        warn("[Payload] leave / reset pages not found yet (leave: "
                            .. tostring(found.leave ~= nil) .. ", reset: " .. tostring(found.reset ~= nil) .. ")")
                    end
                end
                -- (looking through every object with no parent is not free: slower after a while)
                task.wait(missing and (os.clock() - started > 30 and 5 or 0.5) or 2)
            end
        end)

        -- Every frame, before it is drawn: whatever changed them since is put back.
        RunService.RenderStepped:Connect(function()
            local leave, reset = found.leave, found.reset
            if MATCH_LEAVE_TO_RESET and leave and reset then
                matchLeaveToReset(leave, reset)
            end
            if FIRST_BUTTON_BLUE then
                if leave then makeBlue(leave.confirm) end
                if reset then makeBlue(reset.confirm) end
            end
        end)
    end

    print("[Payload] started")

    -- 1. Load the 2019 ESC Menu (the Roblox logo opens it) and show which build is running.
    -- In the background, so the chat and icons don't wait for it.
    -- Several tries (a changing query string stops GitHub's cache serving an older copy for a
    -- few minutes), the download is checked (build number, complete file).
    task.spawn(function()
        local MENU_URL = "https://raw.githubusercontent.com/eloredo413-hue/2019-core-gui/ccr-f33d83ed-bgaekc/2019%20gui"
        local MAIN_BRANCH_URL = "https://raw.githubusercontent.com/eloredo413-hue/2019-core-gui/refs/heads/main/2019%20gui"
        local EXPECTED_REVISION = 9 -- 2019-gui-r9
        local EXPECTED_NAME = "r9"

        local function revisionOf(source)
            local tag = source:match('Legacy2019MenuVersion%s*=%s*"([^"]+)"')
            return tonumber(tostring(tag):match("r(%d+)")) or 0, tag
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
                    local revision, tag = revisionOf(body)
                    if not tag then
                        menuProblem = "the download is incomplete or not the 2019 menu (" .. #body .. " bytes)"
                    elseif revision < EXPECTED_REVISION then
                        oldSource, oldTag = body, tag
                        menuProblem = "GitHub served an older copy (" .. tostring(tag) .. ")"
                    elseif not body:find("end of 2019 gui", 1, true) then
                        menuProblem = "the download was cut short (" .. #body .. " bytes)"
                    else
                        menuSource, menuTag = body, tag
                        break
                    end
                end
                warn("[Payload] 2019 ESC menu download:", menuProblem)
            end
            if menuSource then break end
            task.wait(1)
        end

        local menuIsOld, menuIsMain = false, false
        if not menuSource and oldSource then
            menuSource, menuTag, menuIsOld = oldSource, oldTag, true
        end
        if not menuSource and USE_MAIN_BRANCH_IF_NO_FIX then
            local body = fetch(MAIN_BRANCH_URL)
            if body then menuSource, menuTag, menuIsMain = body, "main branch", true end
        end

        local function menuStatusText()
            local api = Env.Legacy2019Menu
            if api and type(api.GetStatus) == "function" then return api.GetStatus() end
            return "2019 menu: no status (" .. tostring(menuTag) .. ")"
        end

        if not menuSource then
            showStatus("2019 ESC menu NOT loaded: " .. tostring(menuProblem) .. ". Roblox's own menu is in use - rejoin and run the script again.", RED, 30)
        else
            local chunk, compileError = loadstring(menuSource)
            if not chunk then
                showStatus("2019 ESC menu " .. tostring(menuTag) .. " did not compile: " .. tostring(compileError), RED, 30)
            else
                local ran, runError = pcall(chunk)
                if not ran then
                    warn("[Payload] 2019 ESC menu errored:", runError)
                    showStatus("2019 ESC menu " .. tostring(menuTag) .. " ERROR while starting: " .. tostring(runError), RED, 30)
                elseif not Env.Legacy2019MenuVersion or not Env.Legacy2019Menu then
                    if menuIsMain then
                        showStatus("Using the OLDER 2019 menu (main branch): the fixed copy could not be downloaded (" .. tostring(menuProblem) .. ").", ORANGE, 30)
                    else
                        showStatus("2019 ESC menu " .. tostring(menuTag) .. " did not start (see the console / warnings).", RED, 30)
                    end
                elseif menuIsMain then
                    showStatus("Using the OLDER 2019 menu (main branch): the fixed copy could not be downloaded (" .. tostring(menuProblem) .. ").", ORANGE, 30)
                elseif menuIsOld then
                    showStatus("2019 ESC menu " .. tostring(menuTag) .. " loaded, but it is an OLD cached copy (wanted " .. EXPECTED_NAME .. "). Rejoin in a few minutes.", ORANGE, 30)
                else
                    showStatus("2019 ESC menu " .. tostring(menuTag) .. " loaded", GREEN, 8)
                end
                if ran then
                    startHud(menuStatusText)
                    startConfirmPageFix()
                end
            end
        end
        print("[Payload] 2019 ESC menu loaded")
    end)

    -- 2. Chat
    if not game:IsLoaded() then game.Loaded:Wait() end

    local Players          = game:GetService("Players")
    local CoreGui          = game:GetService("CoreGui")
    local StarterGui       = game:GetService("StarterGui")
    local UserInputService = game:GetService("UserInputService")
    local TextChatService  = game:GetService("TextChatService")

    -- 2a. The 2017-19 chat box: the chat window and chat bar of the 2017 core gui. Downloaded
    -- like the menu (a few tries, a changing query string, the download is checked). If it
    -- cannot be started, the old chat below stays the chat window and an orange message says so.
    local CHAT_BOX_URL = "https://raw.githubusercontent.com/eloredo413-hue/E/ccr-f33d83ed-bgaekc/2017_chat_box.lua"
    local EXPECTED_CHAT_REVISION = 1
    local chatBoxOk = false

    if USE_2017_CHAT then
        Env.Chat2017Skipped = nil
        local chatSource, chatProblem
        for round = 1, 3 do
            for _, withBuster in ipairs({ true, false }) do
                local url = CHAT_BOX_URL
                if withBuster then url = url .. "?cb=" .. tostring(os.time()) .. "_" .. round end
                local ok, body = pcall(function() return game:HttpGet(url) end)
                if not ok or type(body) ~= "string" or #body == 0 then
                    chatProblem = ok and "empty reply" or tostring(body)
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
            if CHAT_OPEN_AT_START then pcall(Env.Chat2017.SetVisible, true) end
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
            -- No chat at all: stop here, as before (the normal chat stays on).
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

        local ICON_SIZE     = 20
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

        local function findNativeChatButton()
            local topBarApp = CoreGui:FindFirstChild("TopBarApp")
            if not topBarApp then return nil end

            for _, d in ipairs(topBarApp:GetDescendants()) do
                if d:IsA("GuiButton") and d.Visible then
                    local n = d.Name:lower()
                    if (n == "chat" or n == "chatbutton" or n == "robloxchatbutton")
                       and not n:find("window") and not n:find("frame") then
                        return d
                    end
                end
            end

            local list = {}
            for _, d in ipairs(topBarApp:GetDescendants()) do
                if d:IsA("GuiButton") and d.Visible then
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
            -- The chat box can be opened and closed from elsewhere too (the menu hides the chat
            -- while it is open): the icon follows what it is.
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

    -- 4. TopBar Roblox Logo
    -- Same method as the chat icon: hide the native logo and draw our
    -- own image inside the button's rounded background.
    task.spawn(function()
        local RunService = game:GetService("RunService")
        local CoreGui    = game:GetService("CoreGui")

        local LOGO_ID = "73899106811349"

        -- Tried in order until one loads: the asset's thumbnail (works
        -- for decals and images), then the id as an image. Until one
        -- does, Roblox's own logo stays, so the icon is never blank.
        local LOGO_IMAGES = {
            "rbxthumb://type=Asset&id=" .. LOGO_ID .. "&w=150&h=150",
            "rbxassetid://" .. LOGO_ID,
        }

        local logoImage = nil

        task.spawn(function()
            local ContentProvider = game:GetService("ContentProvider")
            for _, image in ipairs(LOGO_IMAGES) do
                local status
                pcall(function()
                    ContentProvider:PreloadAsync({ image }, function(_, fetchStatus)
                        status = fetchStatus
                    end)
                end)
                if status == Enum.AssetFetchStatus.Success then
                    logoImage = image
                    return
                end
            end
            warn("[LegacyLogo] logo image (asset " .. LOGO_ID .. ") did not load; keeping Roblox's logo.")
        end)

        local LOGO_SIZE = 24

        -- The 2019 ESC menu puts an invisible button inside the logo.
        local MENU_BUTTON = "Legacy2019MenuButton"

        local ourLogo  = nil
        local logoBtn  = nil
        local logoPill = nil

        local function findNativeMenuButton()
            local topBarApp = CoreGui:FindFirstChild("TopBarApp")
            if not topBarApp then return nil end

            -- The logo button sits inside an element named like "MenuIcon".
            local best, bestArea = nil, 0
            for _, d in ipairs(topBarApp:GetDescendants()) do
                if d:IsA("GuiButton") and d.Visible and d.Name ~= MENU_BUTTON then
                    local inMenuIcon = false
                    local p = d
                    while p and p ~= topBarApp do
                        if p.Name:lower():find("menuicon") then
                            inMenuIcon = true
                            break
                        end
                        p = p.Parent
                    end
                    local s = d.AbsoluteSize
                    if inMenuIcon and s.X * s.Y > bestArea then
                        best, bestArea = d, s.X * s.Y
                    end
                end
            end
            if best then return best end

            -- Otherwise: the leftmost icon-sized button.
            local left = nil
            for _, d in ipairs(topBarApp:GetDescendants()) do
                if d:IsA("GuiButton") and d.Visible and d.Name ~= MENU_BUTTON then
                    local s = d.AbsoluteSize
                    if s.X >= 26 and s.X <= 60 and s.Y >= 26 and s.Y <= 60
                       and (not left or d.AbsolutePosition.X < left.AbsolutePosition.X) then
                        left = d
                    end
                end
            end
            return left
        end

        local function findLogoPill(btn)
            local btnArea = btn.AbsoluteSize.X * btn.AbsoluteSize.Y
            if btnArea <= 0 then return btn end

            local best, bestArea = nil, 0
            for _, d in ipairs(btn:GetDescendants()) do
                if d:IsA("ImageLabel") and d.Name ~= "LegacyRobloxLogo" and d.Visible then
                    local area = d.AbsoluteSize.X * d.AbsoluteSize.Y
                    if area >= btnArea * 0.35 and area > bestArea then
                        best, bestArea = d, area
                    end
                end
            end
            return best or btn
        end

        -- The logo button's own image is the dark rounded background,
        -- so leave the button alone and only hide the logo image(s)
        -- inside it. (Unlike the chat icon, which is hooked on an outer
        -- wrapper button.)
        local function hideNativeLogo(btn, pill)
            for _, d in ipairs(btn:GetDescendants()) do
                if d ~= pill and d ~= ourLogo and d:IsA("ImageLabel") then
                    d.ImageTransparency = 1
                end
            end
        end

        local function attachLogo(pill)
            if ourLogo and ourLogo.Parent then ourLogo:Destroy() end

            ourLogo = Instance.new("ImageLabel")
            ourLogo.Name                   = "LegacyRobloxLogo"
            ourLogo.AnchorPoint            = Vector2.new(0.5, 0.5)
            ourLogo.Position               = UDim2.new(0.5, 0, 0.5, 0)
            ourLogo.Size                   = UDim2.new(0, LOGO_SIZE, 0, LOGO_SIZE)
            ourLogo.BackgroundTransparency = 1
            ourLogo.Image                  = logoImage or ""
            ourLogo.Visible                = logoImage ~= nil
            ourLogo.ScaleType              = Enum.ScaleType.Fit
            ourLogo.Active                 = false
            ourLogo.ZIndex                 = 500
            ourLogo.Parent                 = pill
            print("[LegacyLogo] logo attached to", pill:GetFullName())
        end

        local function hookLogo(btn)
            logoBtn  = btn
            logoPill = findLogoPill(btn)
            if logoImage then hideNativeLogo(btn, logoPill) end
            attachLogo(logoPill)
        end

        local deadline = tick() + 15
        while not logoBtn and tick() < deadline do
            local btn = findNativeMenuButton()
            if btn then
                hookLogo(btn)
            else
                RunService.Heartbeat:Wait()
            end
        end
        if not logoBtn then
            warn("[LegacyLogo] Roblox logo button not found after 15s.")
        end

        RunService.RenderStepped:Connect(function()
            -- The top bar rebuilt the button: find it again.
            if not logoBtn or not logoBtn:IsDescendantOf(CoreGui) then
                local btn = findNativeMenuButton()
                if btn then hookLogo(btn) end
                return
            end

            if not ourLogo or not ourLogo.Parent then
                hookLogo(logoBtn)
                return
            end

            -- Not loaded (yet): keep Roblox's logo showing.
            if not logoImage then
                if ourLogo.Visible then ourLogo.Visible = false end
                return
            end

            -- Keep the native logo hidden and ours as set.
            hideNativeLogo(logoBtn, logoPill)
            if ourLogo.Image ~= logoImage then ourLogo.Image = logoImage end
            if ourLogo.ImageTransparency ~= 0 then ourLogo.ImageTransparency = 0 end
            if ourLogo.Visible ~= true then ourLogo.Visible = true end
            local tSize = UDim2.new(0, LOGO_SIZE, 0, LOGO_SIZE)
            if ourLogo.Size ~= tSize then ourLogo.Size = tSize end
        end)
    end)
]=]

if queue_teleport then
    queue_teleport(scriptToRun)
end

pcall(function()
    loadstring(scriptToRun)()
end)

if #Players:GetPlayers() <= 1 then
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
else
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end