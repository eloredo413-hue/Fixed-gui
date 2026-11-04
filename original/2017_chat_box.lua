--[[
	2017-19 CHAT BOX (standalone)

	The chat window and chat bar of the 2017 core gui ("Tap here to chat", the dark window above
	the bar, coloured names, "Please chat '/?' or '/help' for a list of chat commands."), as a
	script of its own, for the 2023 and 2021 GUIs.

	  * It draws its own window. Roblox's modern chat window (CoreGui.ExperienceChat) is switched
	    off only while this runs and is switched back on when it stops.
	  * It starts closed, like the 2017 chat on a phone. getgenv().Chat2017 has Toggle(),
	    SetVisible(open), GetVisible() and FocusChatBar().
	  * When Roblox's chat is switched off and on again (the 2023 menu does that while it is
	    open), the window comes back open if it was open.
	  * Stop it with getgenv().Chat2017Cleanup().
	  * A game that still uses the legacy chat already has a chat window of this kind: nothing is
	    started there (getgenv().Chat2017 stays nil).

	The window itself is the Chat module of the Legacy 2017 model (Roblox's old CoreScripts chat,
	adapted to TextChatService): the same code, with a few small edits. It is parented to this
	script's ScreenGui; its connections on services and its two fade loops can be stopped; a
	message from the game itself is shown as a system line; message text is shown as typed
	(TextChatService escapes it); and it opens again after Roblox's chat is switched off and on.
]]

local Environment = (getgenv or function() return _G end)

local Env = Environment()

-- Stop an earlier copy first.

if Env.Chat2017Cleanup then
	pcall(Env.Chat2017Cleanup)
	Env.Chat2017Cleanup = nil
end

Env.Chat2017 = nil
Env.Chat2017Version = "2017-chat-r1"
Env.Chat2017Revision = 1

-- Services

local Players = game:GetService("Players")

local CoreGui = game:GetService("CoreGui")

local TextChatService = game:GetService("TextChatService")

-- Games that use the legacy chat already have a chat window of this kind.

local UsesTextChatService = true

pcall(function()
	if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
		UsesTextChatService = false
	end
end)

if not UsesTextChatService then
	print("[2017 chat] this game uses the legacy chat: its own chat window is the one to use, nothing to start")
	Env.Chat2017Skipped = "legacychat"
	return
end

Env.Chat2017Skipped = nil

-- The chat window sends and receives through the general channel.

local TextChannels = TextChatService:WaitForChild("TextChannels", 15)

local General = TextChannels and TextChannels:WaitForChild("RBXGeneral", 15)

if not General then
	warn("[2017 chat] the game has no general text channel (RBXGeneral): the chat box was not started")
	Env.Chat2017Skipped = "nochannel"
	return
end

-- The window's own ScreenGui: below the top bar and inside the camera cut-out, drawn above the
-- game's windows and below the menus.

for _, Child in ipairs(CoreGui:GetChildren()) do
	if Child.Name == "Chat2017Gui" then
		pcall(function()
			Child:Destroy()
		end)
	end
end

local Chat2017Host = Instance.new("ScreenGui")

Chat2017Host.Name = "Chat2017Gui"

Chat2017Host.ResetOnSpawn = false

Chat2017Host.DisplayOrder = 100

-- the 2017 gui lays its windows out with global z-indexes
Chat2017Host.ZIndexBehavior = Enum.ZIndexBehavior.Global

pcall(function()
	Chat2017Host.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end)

pcall(function()
	Chat2017Host.Parent = CoreGui
end)

if not Chat2017Host.Parent then
	pcall(function()
		Chat2017Host.Parent = gethui and gethui()
	end)
end

if not Chat2017Host.Parent then
	pcall(function()
		Chat2017Host.Parent = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
	end)
end

if not Chat2017Host.Parent then
	warn("[2017 chat] there is no place for the chat window: the chat box was not started")
	Env.Chat2017Skipped = "noparent"
	return
end

-- Everything the module connects on a service is kept here, and its loops end with Alive.

local Chat2017State = {
	Alive = true,
}

local Chat2017Connections = {}

local Chat2017Track = function(Connection)
	-- the module disconnects and reconnects some of them every time the chat bar is shown:
	-- the ones it has already disconnected are dropped
	if #Chat2017Connections >= 64 then
		local Kept = {}

		for _, Old in ipairs(Chat2017Connections) do
			if Old.Connected ~= false then
				table.insert(Kept, Old)
			end
		end

		table.clear(Chat2017Connections)

		for _, Old in ipairs(Kept) do
			table.insert(Chat2017Connections, Old)
		end
	end

	table.insert(Chat2017Connections, Connection)

	return Connection
end

--============================================================*
-- THE CHAT MODULE (Legacy 2017 model, Core/2017/NewRobloxGui/Modules/Chat)
--============================================================*

-- TextChatService hands out message text escaped for rich text ("don&apos;t", "&lt;3"), and a
-- message from the game can carry rich text tags. The 2017 window shows plain text.

local Chat2017PlainText = function(Text, StripTags)
	Text = tostring(Text)

	if StripTags then
		Text = string.gsub(Text, "<[^>]*>", "")
	end

	Text = string.gsub(Text, "&lt;", "<")

	Text = string.gsub(Text, "&gt;", ">")

	Text = string.gsub(Text, "&quot;", "\"")

	Text = string.gsub(Text, "&apos;", "'")

	Text = string.gsub(Text, "&#39;", "'")

	Text = string.gsub(Text, "&amp;", "&")

	return Text
end

local Chat2017Run = function()

--==== the Chat module starts here ====--

--[[
		// FileName: Chat.lua
		// Written by: SolarCrane
		// Description: Code for lua side chat on ROBLOX.
	]]

--[[ CONSTANTS ]]
local TextChatService =
	game:GetService("TextChatService")
local RBXGeneral: TextChannel =
	game.TextChatService
	:WaitForChild("TextChannels")
	:WaitForChild("RBXGeneral")

local FORCE_CHAT_GUI = false
local NON_CORESCRIPT_MODE = false

local MESSAGES_FADE_OUT_TIME = 15
local MAX_UDIM_SIZE = 2^15 - 1

local PHONE_SCREEN_WIDTH = 640
local TABLET_SCREEN_WIDTH = 1024

local PHONE_CHAT_WINDOW_WIDTH = 0.5
local PHONE_CHAT_WINDOW_HEIGHT = 0.42
local TABLET_CHAT_WINDOW_WIDTH = 0.4
local TABLET_CHAT_WINDOW_HEIGHT = 0.28

local FLOOD_CHECK_MESSAGE_COUNT = 7
local FLOOD_CHECK_MESSAGE_INTERVAL = 15

local VR_CHAT_CLICK_DEBOUNCE = 0.25

local SCROLLBAR_THICKNESS = 7

local CHAT_COLORS =
	{
		Color3.new(253/255, 41/255, 67/255),
		Color3.new(1/255, 162/255, 255/255),
		Color3.new(2/255, 184/255, 87/255),
		BrickColor.new("Bright violet").Color,
		BrickColor.new("Bright orange").Color,
		BrickColor.new("Bright yellow").Color,
		BrickColor.new("Light reddish violet").Color,
		BrickColor.new("Brick yellow").Color,
	}

local emptySelectionImage =
	Instance.new("ImageLabel")

emptySelectionImage.ImageTransparency = 1
emptySelectionImage.BackgroundTransparency = 1

--[[ SERVICES ]]

local RunService =
	game:GetService("RunService")

local CoreGuiService =
	game:GetService("CoreGui")

local PlayersService =
	game:GetService("Players")

local DebrisService =
	game:GetService("Debris")

local GuiService =
	game:GetService("GuiService")

local InputService =
	game:GetService("UserInputService")

local StarterGui =
	game:GetService("StarterGui")

local ContextActionService =
	game:GetService("ContextActionService")

--[[ END OF SERVICES ]]

--[[ Fast Flags ]]

local playerDropDownEnabledSuccess,
	playerDropDownEnabledFlagValue =
	pcall(
		function()
			return settings():GetFFlag(
				"PlayerDropDownEnabled"
			)
		end
	)

local IsPlayerDropDownEnabled =
	playerDropDownEnabledSuccess
	and playerDropDownEnabledFlagValue

local getMoveChatSuccess,
	moveChatActiveValue =
	pcall(
		function()
			return settings():GetFFlag(
				"SetCoreMoveChat"
			)
		end
	)

local allowMoveChat =
	getMoveChatSuccess
	and moveChatActiveValue

local getDisableChatBarSuccess,
	disableChatBarValue =
	pcall(
		function()
			return settings():GetFFlag(
				"SetCoreDisableChatBar"
			)
		end
	)

local allowDisableChatBar =
	getDisableChatBarSuccess
	and disableChatBarValue

--[[ SCRIPT VARIABLES ]]

while PlayersService.LocalPlayer == nil do
	PlayersService.ChildAdded:wait()
end

local Player =
	PlayersService.LocalPlayer

local GuiRoot =
	Instance.new("Frame")

GuiRoot.Name = "GuiRoot"

GuiRoot.Size =
	UDim2.new(
		1,
		0,
		1,
		0
	)

GuiRoot.BackgroundTransparency = 1

local chatRepositioned = false
local chatBarDisabled = false

local lastSelectedPlayer = nil
local lastSelectedButton = nil

local playerDropDownModule = nil
local playerDropDown = nil
local blockingUtility = nil

local topbarEnabled = true

-- Load the old PlayerDropDown only when it is actually available.
-- A missing legacy dropdown must NOT prevent Chat.lua from loading.

if
	not NON_CORESCRIPT_MODE
	and not InputService.VREnabled
	and not InputService.TouchEnabled
then
	local NewRobloxGui =
		Chat2017Host

	local Modules =
		NewRobloxGui
		and NewRobloxGui:FindFirstChild(
			"Modules"
		)

	local PlayerDropDown =
		Modules
		and Modules:FindFirstChild(
			"PlayerDropDown"
		)

	if PlayerDropDown then
		local Success, Result =
			pcall(
				require,
				PlayerDropDown
			)

		if Success and Result then
			playerDropDownModule =
				Result

			local DropDownSuccess,
				DropDownResult =
				pcall(
					function()
						return playerDropDownModule:CreatePlayerDropDown()
					end
				)

			if DropDownSuccess then
				playerDropDown =
					DropDownResult
			end

			local BlockingSuccess,
				BlockingResult =
				pcall(
					function()
						return playerDropDownModule:CreateBlockingUtility()
					end
				)

			if BlockingSuccess then
				blockingUtility =
					BlockingResult
			end
		else
			warn(
				"[Legacy Chat] PlayerDropDown failed: "
					.. tostring(Result)
			)
		end
	end
end

--[[ END OF SCRIPT VARIABLES ]]

local function GetLuaChatFilteringFlag()
	local flagSuccess,
		flagValue =
		pcall(
			function()
				return settings():GetFFlag(
					"LuaChatFiltering"
				)
			end
		)

	return flagSuccess
		and flagValue == true
end

local Util = {}

do
	function Util.IsTouchDevice()
		local touchEnabled = false

		pcall(
			function()
				touchEnabled =
					InputService.TouchEnabled
			end
		)

		return touchEnabled
	end

	function Util.IsSmallScreenSize()
		return
			GuiRoot.AbsoluteSize.X
			<= PHONE_SCREEN_WIDTH
	end

	function Util.Create(instanceType)
		return function(data)
			local obj =
				Instance.new(instanceType)

			for k, v in pairs(data) do
				if type(k) == "number" then
					v.Parent = obj
				else
					obj[k] = v
				end
			end

			return obj
		end
	end

	function Util.Clamp(
		low,
		high,
		input
	)
		return math.max(
			low,
			math.min(
				high,
				input
			)
		)
	end

	function Util.Linear(
		t,
		b,
		c,
		d
	)
		if t >= d then
			return b + c
		end

		return c * t / d + b
	end

	function Util.EaseOutQuad(
		t,
		b,
		c,
		d
	)
		if t >= d then
			return b + c
		end

		t = t / d

		return
			-c * t * (t - 2)
			+ b
	end

	function Util.EaseInOutQuad(
		t,
		b,
		c,
		d
	)
		if t >= d then
			return b + c
		end

		t = t / (d / 2)

		if t < 1 then
			return
				c / 2 * t * t
				+ b
		end

		t = t - 1

		return
			-c / 2
			* (t * (t - 2) - 1)
			+ b
	end

	function Util.PropertyTweener(
		instance,
		prop,
		start,
		final,
		duration,
		easingFunc,
		cbFunc
	)
		local this = {}

		this.StartTime = tick()

		this.EndTime =
			this.StartTime
			+ duration

		this.Cancelled = false

		local finished = false
		local percentComplete = 0

		spawn(
			function()
				local now = tick()

				while
					now < this.EndTime
					and instance
				do
					if this.Cancelled then
						return
					end

					local Success =
						pcall(
							function()
								instance[prop] =
								easingFunc(
									now - this.StartTime,
									start,
									final - start,
									duration
								)
							end
						)

					if not Success then
						return
					end

					percentComplete =
						Util.Clamp(
							0,
							1,
							(now - this.StartTime)
							/ duration
						)

					RunService.RenderStepped:wait()

					now = tick()
				end

				if
					this.Cancelled == false
					and instance
				then
					local Success =
						pcall(
							function()
								instance[prop] =
								final
							end
						)

					if not Success then
						return
					end

					finished = true
					percentComplete = 1

					if cbFunc then
						cbFunc()
					end
				end
			end
		)

		function this:GetPercentComplete()
			return percentComplete
		end

		function this:IsFinished()
			return finished
		end

		function this:Cancel()
			this.Cancelled = true
		end

		return this
	end

	function Util.Signal()
		local sig = {}

		local mSignaler =
			Instance.new("BindableEvent")

		local mArgData = nil
		local mArgDataCount = nil

		function sig:fire(...)
			mArgData = {
				...
			}

			mArgDataCount =
				select(
					"#",
					...
				)

			mSignaler:Fire()
		end

		function sig:connect(f)
			if not f then
				error(
					"connect(nil)",
					2
				)
			end

			return
				mSignaler.Event:connect(
					function()
						f(
							unpack(
								mArgData,
								1,
								mArgDataCount
							)
						)
					end
				)
		end

		function sig:wait()
			mSignaler.Event:wait()

			assert(
				mArgData,
				"Missing arg data, likely due to :TweenSize/Position corrupting threadrefs."
			)

			return
				unpack(
					mArgData,
					1,
					mArgDataCount
				)
		end

		return sig
	end

	function Util.DisconnectEvent(conn)
		if conn then
			pcall(
				function()
					conn:Disconnect()
				end
			)
		end

		return nil
	end

	function Util.SetGUIInsetBounds(
		x,
		y
	)
		local success =
			pcall(
				function()
					GuiService:SetGlobalGuiInset(
						0,
						x,
						0,
						y
					)
				end
			)

		if not success then
			pcall(
				function()
					GuiService:SetGlobalSizeOffsetPixel(
						-x,
						-y
					)
				end
			)
		end
	end

	local baseUrl =
		game:GetService(
			"ContentProvider"
		).BaseUrl:lower()

	baseUrl =
		string.gsub(
			baseUrl,
			"/m.",
			"/www."
		)

	function Util.GetSecureApiBaseUrl()
		local secureApiUrl =
			baseUrl

		secureApiUrl =
			string.gsub(
				secureApiUrl,
				"http://",
				"https://"
			)

		secureApiUrl =
			string.gsub(
				secureApiUrl,
				"www",
				"api"
			)

		return secureApiUrl
	end

	function Util.GetPlayerByName(
		playerName
	)
		local lowerName =
			string.lower(
				playerName
			)

		for _, player in pairs(
			PlayersService:GetPlayers()
			) do
			if
				string.lower(
					player.Name
				)
					== lowerName
			then
				return player
			end
		end

		return nil
	end

	local adminCache = {}

	function Util.IsPlayerAdminAsync(
		player
	)
		local userId =
			player
			and player.UserId

		if userId then
			if adminCache[userId] == nil then
				local isAdmin = false

				pcall(
					function()
						isAdmin =
							player:IsInGroup(
								1200769
							)
					end
				)

				adminCache[userId] =
					isAdmin
			end

			return adminCache[userId]
		end

		return false
	end

	local function GetNameValue(
		pName
	)
		local value = 0

		for index = 1, #pName do
			local cValue =
				string.byte(
					string.sub(
						pName,
						index,
						index
					)
				)

			local reverseIndex =
				#pName - index + 1

			if #pName % 2 == 1 then
				reverseIndex =
					reverseIndex - 1
			end

			if reverseIndex % 4 >= 2 then
				cValue = -cValue
			end

			value =
				value + cValue
		end

		return value
	end

	function Util.ComputeChatColor(
		pName
	)
		return
			CHAT_COLORS[
		(
			GetNameValue(pName)
				% #CHAT_COLORS
		) + 1
		]
	end

	local testLabel =
		Instance.new("TextLabel")

	testLabel.TextWrapped = true

	testLabel.Position =
		UDim2.new(
			1,
			0,
			1,
			0
		)

	testLabel.Parent =
		GuiRoot

	local TextSizeCache = {}

	function Util.GetStringTextBounds(
		text,
		font,
		fontSize,
		sizeBounds
	)
		sizeBounds =
			sizeBounds
			or false

		if not TextSizeCache[text] then
			TextSizeCache[text] = {}
		end

		if not TextSizeCache[text][font] then
			TextSizeCache[text][font] = {}
		end

		if not TextSizeCache[text][font][sizeBounds] then
			TextSizeCache[text][font][sizeBounds] = {}
		end

		if
			not TextSizeCache[text][font][sizeBounds][fontSize]
		then
			testLabel.Text = text
			testLabel.Font = font
			testLabel.FontSize = fontSize

			if sizeBounds then
				testLabel.TextWrapped = true
				testLabel.Size = sizeBounds
			else
				testLabel.TextWrapped = false
			end

			TextSizeCache[text][font][sizeBounds][fontSize] =
				testLabel.TextBounds
		end

		return
			TextSizeCache[text][font][sizeBounds][fontSize]
	end

	local PRINTABLE_CHARS =
		"[^"
		.. string.char(32)
		.. "-"
		.. string.char(126)
		.. "]"

	local WHITESPACE_CHARS =
		"("
		.. string.rep("%s", 7)
		.. ")%s+"

	function Util.FilterUnprintableCharacters(
		str
	)
		if not GetLuaChatFilteringFlag() then
			return str
		end

		local result =
			str:gsub(
				PRINTABLE_CHARS,
				""
			)

		result =
			result:gsub(
				WHITESPACE_CHARS,
				"%1"
			)

		return result
	end
end

local SelectChatModeEvent =
	Util.Signal()

local SelectPlayerEvent =
	Util.Signal()

local function CreateChatMessage()
	local this = {}

	this.FadeRoutines = {}

	function this:GetMessageFontSize(
		settings
	)
		return
			Util.IsSmallScreenSize()
			and settings.SmallScreenFontSize
			or settings.FontSize
	end

	function this:OnResize()
	end

	function this:FadeIn()
		local gui =
			this:GetGui()

		if gui then
			gui.Visible = true
		end
	end

	function this:FadeOut()
		local gui =
			this:GetGui()

		if gui then
			gui.Visible = false
		end
	end

	function this:GetGui()
		return this.Container
	end

	function this:Destroy()
		if this.Container ~= nil then
			this.Container:Destroy()
			this.Container = nil
		end

		if this.FadeRoutines then
			for _, routine in pairs(
				this.FadeRoutines
				) do
				routine:Cancel()
			end

			this.FadeRoutines = {}
		end
	end

	return this
end

local function CreateSystemChatMessage(
	settings,
	chattedMessage
)
	local this =
		CreateChatMessage()

	this.Settings = settings
	this.rawChatString =
		chattedMessage

	function this:OnResize(
		containerSize
	)
		if
			this.Container
			and this.ChatMessage
		then
			if InputService.VREnabled then
				this.ChatMessage.Position =
					UDim2.new(
						0,
						4,
						0,
						0
					)

				this.ChatMessage.Size =
					UDim2.new(
						1,
						0,
						1,
						0
					)
			end

			this.Container.Size =
				UDim2.new(
					1,
					0,
					0,
					1000
				)

			local textHeight =
				this.ChatMessage.TextBounds.Y

			local newContainerHeight =
				textHeight + 5

			this.Container.Size =
				UDim2.new(
					1,
					0,
					0,
					newContainerHeight
				)

			return newContainerHeight
		end
	end

	function this:FadeIn()
		local gui =
			this:GetGui()

		if gui then
			gui.Visible = true

			for _, routine in pairs(
				this.FadeRoutines
				) do
				routine:Cancel()
			end

			this.FadeRoutines = {}

			local tweenableObjects =
				{
					this.ChatMessage;
				}

			for _, object in pairs(
				tweenableObjects
				) do
				object.TextTransparency = 0

				object.TextStrokeTransparency =
					this.Settings.TextStrokeTransparency
			end

			if this.MessageBackgroundImage then
				this.MessageBackgroundImage.Visible =
					InputService.VREnabled
			end
		end
	end

	function this:FadeOut(instant)
		local gui =
			this:GetGui()

		if gui then
			if instant then
				gui.Visible = false
			else
				local tweenableObjects =
					{
						this.ChatMessage;
					}

				for _, object in pairs(
					tweenableObjects
					) do
					table.insert(
						this.FadeRoutines,
						Util.PropertyTweener(
							object,
							"TextTransparency",
							object.TextTransparency,
							1,
							1,
							Util.Linear
						)
					)

					table.insert(
						this.FadeRoutines,
						Util.PropertyTweener(
							object,
							"TextStrokeTransparency",
							object.TextStrokeTransparency,
							1,
							0.85,
							Util.Linear
						)
					)
				end
			end

			if this.MessageBackgroundImage then
				this.MessageBackgroundImage.Visible = false
			end
		end
	end

	local function CreateMessageGuiElement()
		local fontSize =
			this:GetMessageFontSize(
				this.Settings
			)

		local systemMessageDisplayText =
			this.rawChatString or ""

		local systemMessageSize =
			Util.GetStringTextBounds(
				systemMessageDisplayText,
				this.Settings.Font,
				fontSize,
				UDim2.new(
					0,
					400,
					0,
					1000
				)
			)

		local container =
			Util.Create"Frame"
		{
			Name = "MessageContainer";
			Position =
				UDim2.new(
					0,
					0,
					0,
					0
				);
			ZIndex = 1;
			BackgroundColor3 =
				Color3.new(
					0,
					0,
					0
				);
			BackgroundTransparency = 1;
		}

		this.MessageBackgroundImage =
			Util.Create"ImageLabel"
		{
			Name = "TextEntryBackground";
			Size =
				UDim2.new(
					1,
					0,
					1,
					-2
				);
			Position =
				UDim2.new(
					0,
					0,
					0,
					1
				);
			Image =
				"rbxasset://textures/ui/Chat/VRChatBackground.png";
			ScaleType =
				Enum.ScaleType.Slice;
			SliceCenter =
				Rect.new(
					8,
					8,
					56,
					56
				);
			BackgroundTransparency = 1;
			ImageTransparency = 0.3;
			BorderSizePixel = 0;
			ZIndex = 1;
			Visible =
				InputService.VREnabled;
			Parent = container;
		}

		local chatMessage =
			Util.Create"TextLabel"
		{
			Name = "SystemChatMessage";
			Position =
				UDim2.new(
					0,
					0,
					0,
					0
				);
			Size =
				UDim2.new(
					1,
					0,
					1,
					0
				);
			Text =
				systemMessageDisplayText;
			ZIndex = 1;
			BackgroundColor3 =
				Color3.new(
					0,
					0,
					0
				);
			BackgroundTransparency = 1;
			TextXAlignment =
				Enum.TextXAlignment.Left;
			TextYAlignment =
				Enum.TextYAlignment.Top;
			TextWrapped = true;
			TextColor3 =
				this.Settings.DefaultMessageTextColor;
			FontSize = fontSize;
			Font = this.Settings.Font;
			TextStrokeColor3 =
				this.Settings.TextStrokeColor;
			TextStrokeTransparency =
				this.Settings.TextStrokeTransparency;
			Parent = container;
		}

		if InputService.VREnabled then
			chatMessage.Position =
				UDim2.new(
					0,
					4,
					0,
					0
				)

			chatMessage.Size =
				UDim2.new(
					1,
					0,
					1,
					0
				)
		end

		container.Size =
			UDim2.new(
				1,
				0,
				0,
				systemMessageSize.Y + 1
			)

		this.Container = container
		this.ChatMessage = chatMessage
	end

	CreateMessageGuiElement()

	return this
end

--[[ Popup Handling ]]--

function createPopupFrame(
	selectedPlayer,
	selectedButton
)
	if
		selectedPlayer
		and selectedPlayer.Parent
		== PlayersService
	then
		if lastSelectedButton
			~= selectedButton
		then
			if lastSelectedButton ~= nil then
				lastSelectedButton.BackgroundTransparency =
					1

				lastSelectedButton = nil
			end

			lastSelectedButton = selectedButton
			lastSelectedPlayer = selectedPlayer

			selectedButton.BackgroundTransparency =
				0.5

			if
				IsPlayerDropDownEnabled
				and playerDropDown
			then
				playerDropDown.HidePopupImmediately =
					true

				local PopupFrame =
					playerDropDown:CreatePopup(
						selectedPlayer
					)

				PopupFrame.Position =
					UDim2.new(
						0,
						selectedButton.AbsolutePosition.X
						+ selectedButton.AbsoluteSize.X
						+ 2,
						0,
						selectedButton.AbsolutePosition.Y
					)

				PopupFrame.Size =
					UDim2.new(
						0,
						150,
						PopupFrame.Size.Y.Scale,
						PopupFrame.Size.Y.Offset
					)

				PopupFrame.ZIndex = 5
				PopupFrame.Parent = GuiRoot

				for _, button in pairs(
					PopupFrame:GetChildren()
					) do
					button.BackgroundTransparency = 0
					button.ZIndex = 6
				end
			end
		else
			if
				IsPlayerDropDownEnabled
				and playerDropDown
			then
				playerDropDown:Hide()
			end

			lastSelectedPlayer = nil
		end
	end
end

function popupHidden()
	if lastSelectedButton then
		lastSelectedPlayer = nil

		lastSelectedButton.BackgroundTransparency =
			1

		lastSelectedButton = nil
	end
end

if
	IsPlayerDropDownEnabled
	and playerDropDown
then
	playerDropDown.HiddenSignal:connect(
		popupHidden
	)
end

Chat2017Track(InputService.InputBegan:connect(
	function(
		inputObject,
		isProcessed
	)
		if isProcessed then
			return
		end

		local inputType =
			inputObject.UserInputType

		if
			(
				inputType
					== Enum.UserInputType.Touch
					and inputObject.UserInputState
					== Enum.UserInputState.Begin
			)
				or inputType
				== Enum.UserInputType.MouseButton1
		then
			if
				lastSelectedButton
				and IsPlayerDropDownEnabled
				and playerDropDown
			then
				playerDropDown:Hide()
			end
		end
	end
))

--[[ End of popup handling ]]--

local function CreatePlayerChatMessage(
	settings,
	playerChatType,
	sendingPlayer,
	chattedMessage,
	receivingPlayer
)
	local this =
		CreateChatMessage()

	this.Settings = settings
	this.PlayerChatType =
		playerChatType
	this.SendingPlayer =
		sendingPlayer
	this.RawMessageContent =
		chattedMessage
	this.ReceivingPlayer =
		receivingPlayer
	this.ReceivedTime =
		tick()

	this.Neutral =
		this.SendingPlayer
		and this.SendingPlayer.Neutral
		or true

	this.TeamColor =
		this.SendingPlayer
		and this.SendingPlayer.TeamColor
		or BrickColor.new("White")

	function this:OnResize(
		containerSize
	)
		if
			this.Container
			and this.ChatMessage
		then
			this.Container.Size =
				UDim2.new(
					1,
					0,
					0,
					1000
				)

			local textHeight =
				this.ChatMessage.TextBounds.Y

			local newContainerHeight =
				textHeight + 5

			this.Container.Size =
				UDim2.new(
					1,
					0,
					0,
					newContainerHeight
				)

			return newContainerHeight
		end
	end

	function this:FormatMessage()
		local result = ""

		if this.RawMessageContent then
			result =
				this.RawMessageContent
		end

		return result
	end

	function this:FormatChatType()
		if this.PlayerChatType then
			if
				this.PlayerChatType
				== Enum.PlayerChatType.All
			then
			elseif
				this.PlayerChatType
				== Enum.PlayerChatType.Team
			then
				return "[Team]"
			elseif
				this.PlayerChatType
				== Enum.PlayerChatType.Whisper
			then
			end
		end
	end

	function this:FormatPlayerNameText()
		local playerName = ""

		if
			this.PlayerChatType
			== Enum.PlayerChatType.Whisper
			and this.SendingPlayer
			== Player
		then
			playerName =
				(
					this.ReceivingPlayer
					and this.ReceivingPlayer.Name
					or ""
				)
		else
			playerName =
				(
					this.SendingPlayer
					and this.SendingPlayer.Name
					or ""
				)
		end

		return
			"["
			.. playerName
			.. "]:"
	end

	function this:FadeIn()
		local gui =
			this:GetGui()

		if gui then
			gui.Visible = true

			for _, routine in pairs(
				this.FadeRoutines
				) do
				routine:Cancel()
			end

			this.FadeRoutines = {}

			local tweenableObjects =
				{
					this.WhisperToText;
					this.WhisperFromText;
					this.ChatModeButton;
					this.UserNameButton;
					this.ChatMessage;
				}

			for _, object in pairs(
				tweenableObjects
				) do
				object.TextTransparency = 0

				object.TextStrokeTransparency =
					this.Settings.TextStrokeTransparency

				object.Active = true
			end

			if this.UserNameDot then
				this.UserNameDot.ImageTransparency = 0
			end

			if this.MessageBackgroundImage then
				this.MessageBackgroundImage.Visible =
					InputService.VREnabled
			end
		end
	end

	function this:FadeOut(
		instant
	)
		local gui =
			this:GetGui()

		if gui then
			if instant then
				gui.Visible = false
			else
				local tweenableObjects =
					{
						this.WhisperToText;
						this.WhisperFromText;
						this.ChatModeButton;
						this.UserNameButton;
						this.ChatMessage;
					}

				for _, object in pairs(
					tweenableObjects
					) do
					table.insert(
						this.FadeRoutines,
						Util.PropertyTweener(
							object,
							"TextTransparency",
							object.TextTransparency,
							1,
							1,
							Util.Linear
						)
					)

					table.insert(
						this.FadeRoutines,
						Util.PropertyTweener(
							object,
							"TextStrokeTransparency",
							object.TextStrokeTransparency,
							1,
							0.85,
							Util.Linear
						)
					)

					object.Active = false
				end

				if this.UserNameDot then
					table.insert(
						this.FadeRoutines,
						Util.PropertyTweener(
							this.UserNameDot,
							"ImageTransparency",
							this.UserNameDot.ImageTransparency,
							1,
							1,
							Util.Linear
						)
					)
				end
			end

			if this.MessageBackgroundImage then
				this.MessageBackgroundImage.Visible =
					false
			end
		end
	end

	function this:Destroy()
		if this.Container ~= nil then
			this.Container:Destroy()
			this.Container = nil
		end

		this.ClickedOnModeConn =
			Util.DisconnectEvent(
				this.ClickedOnModeConn
			)

		this.ClickedOnPlayerConn =
			Util.DisconnectEvent(
				this.ClickedOnPlayerConn
			)

		this.RightClickedOnPlayerConn =
			Util.DisconnectEvent(
				this.RightClickedOnPlayerConn
			)
	end

	local function CreateMessageGuiElement()
		local fontSize =
			this:GetMessageFontSize(
				this.Settings
			)

		local toMesasgeDisplayText =
			"To "

		local toMessageSize =
			Util.GetStringTextBounds(
				toMesasgeDisplayText,
				this.Settings.Font,
				fontSize
			)

		local fromMesasgeDisplayText =
			"From "

		local fromMessageSize =
			Util.GetStringTextBounds(
				fromMesasgeDisplayText,
				this.Settings.Font,
				fontSize
			)

		local chatTypeDisplayText =
			this:FormatChatType()

		local chatTypeSize =
			chatTypeDisplayText
			and Util.GetStringTextBounds(
				chatTypeDisplayText,
				this.Settings.Font,
				fontSize
			)
			or Vector2.new(
				0,
				0
			)

		local playerNameDisplayText =
			this:FormatPlayerNameText()

		local playerNameSize =
			Util.GetStringTextBounds(
				playerNameDisplayText,
				this.Settings.Font,
				fontSize
			)

		local singleSpaceSize =
			Util.GetStringTextBounds(
				" ",
				this.Settings.Font,
				fontSize
			)

		local numNeededSpaces =
			math.ceil(
				playerNameSize.X
				/ math.max(
					1,
					singleSpaceSize.X
				)
			) + 1

		local chatMessageDisplayText =
			utf8.char(0x200E)
			.. string.rep(
				" ",
				numNeededSpaces
			)
			.. utf8.char(0x2068)
			.. this:FormatMessage()
			.. utf8.char(0x2069)

		local chatMessageSize =
			Util.GetStringTextBounds(
				chatMessageDisplayText,
				this.Settings.Font,
				fontSize,
				UDim2.new(
					0,
					math.max(
						1,
						400
						- 5
						- playerNameSize.X
					),
					0,
					1000
				)
			)

		local playerColor =
			this.Settings.DefaultMessageTextColor

		if this.SendingPlayer then
			if
				this.PlayerChatType
				== Enum.PlayerChatType.Whisper
			then
				if
					this.SendingPlayer
					== Player
					and this.ReceivingPlayer
				then
					playerColor =
						Util.ComputeChatColor(
							this.ReceivingPlayer.Name
						)
				else
					playerColor =
						Util.ComputeChatColor(
							this.SendingPlayer.Name
						)
				end
			else
				if this.SendingPlayer.Neutral then
					playerColor =
						Util.ComputeChatColor(
							this.SendingPlayer.Name
						)
				else
					playerColor =
						this.SendingPlayer.TeamColor.Color
				end
			end
		end

		local container =
			Util.Create"Frame"
		{
			Name = "MessageContainer";
			Position =
				UDim2.new(
					0,
					0,
					0,
					0
				);
			ZIndex = 1;
			BackgroundColor3 =
				Color3.new(
					0,
					0,
					0
				);
			BackgroundTransparency = 1;
		}

		this.MessageBackgroundImage =
			Util.Create"ImageLabel"
		{
			Name = "TextEntryBackground";
			Size =
				UDim2.new(
					1,
					0,
					1,
					-2
				);
			Position =
				UDim2.new(
					0,
					0,
					0,
					1
				);
			Image =
				"rbxasset://textures/ui/Chat/VRChatBackground.png";
			ScaleType =
				Enum.ScaleType.Slice;
			SliceCenter =
				Rect.new(
					8,
					8,
					56,
					56
				);
			BackgroundTransparency = 1;
			ImageTransparency = 0.3;
			BorderSizePixel = 0;
			ZIndex = 1;
			Visible =
				InputService.VREnabled;
			Parent = container;
		}

		local xOffset =
			InputService.VREnabled
			and 4
			or 0

		if
			this.SendingPlayer
			and this.SendingPlayer == Player
			and this.PlayerChatType
			== Enum.PlayerChatType.Whisper
		then
			local whisperToText =
				Util.Create"TextLabel"
			{
				Name = "WhisperTo";
				Position =
					UDim2.new(
						0,
						0,
						0,
						0
					);
				Size =
					UDim2.new(
						0,
						toMessageSize.X,
						0,
						toMessageSize.Y
					);
				Text =
					toMesasgeDisplayText;
				ZIndex = 1;
				BackgroundColor3 =
					Color3.new(
						0,
						0,
						0
					);
				BackgroundTransparency = 1;
				TextXAlignment =
					Enum.TextXAlignment.Left;
				TextYAlignment =
					Enum.TextYAlignment.Top;
				TextWrapped = true;
				TextColor3 =
					this.Settings.DefaultMessageTextColor;
				FontSize = fontSize;
				Font = this.Settings.Font;
				TextStrokeColor3 =
					this.Settings.TextStrokeColor;
				TextStrokeTransparency =
					this.Settings.TextStrokeTransparency;
				Parent = container;
			}

			xOffset =
				xOffset
				+ toMessageSize.X

			this.WhisperToText =
				whisperToText
		elseif
			this.SendingPlayer
			and this.SendingPlayer ~= Player
			and this.PlayerChatType
			== Enum.PlayerChatType.Whisper
		then
			local whisperFromText =
				Util.Create"TextLabel"
			{
				Name = "WhisperFromText";
				Position =
					UDim2.new(
						0,
						0,
						0,
						0
					);
				Size =
					UDim2.new(
						0,
						fromMessageSize.X,
						0,
						fromMessageSize.Y
					);
				Text =
					fromMesasgeDisplayText;
				ZIndex = 1;
				BackgroundColor3 =
					Color3.new(
						0,
						0,
						0
					);
				BackgroundTransparency = 1;
				TextXAlignment =
					Enum.TextXAlignment.Left;
				TextYAlignment =
					Enum.TextYAlignment.Top;
				TextWrapped = true;
				TextColor3 =
					this.Settings.DefaultMessageTextColor;
				FontSize = fontSize;
				Font = this.Settings.Font;
				TextStrokeColor3 =
					this.Settings.TextStrokeColor;
				TextStrokeTransparency =
					this.Settings.TextStrokeTransparency;
				Parent = container;
			}

			xOffset =
				xOffset
				+ fromMessageSize.X

			this.WhisperFromText =
				whisperFromText
		end

		if chatTypeDisplayText then
			local chatModeButton =
				Util.Create(
					Util.IsTouchDevice()
					and "TextLabel"
					or "TextButton"
				)
			{
				Name = "ChatMode";
				BackgroundTransparency = 1;
				ZIndex = 2;
				Text =
					chatTypeDisplayText;
				TextColor3 =
					this.Settings.DefaultMessageTextColor;
				Position =
					UDim2.new(
						0,
						xOffset,
						0,
						0
					);
				TextXAlignment =
					Enum.TextXAlignment.Left;
				TextYAlignment =
					Enum.TextYAlignment.Top;
				FontSize = fontSize;
				Font = this.Settings.Font;
				Size =
					UDim2.new(
						0,
						chatTypeSize.X,
						0,
						chatTypeSize.Y
					);
				TextStrokeColor3 =
					this.Settings.TextStrokeColor;
				TextStrokeTransparency =
					this.Settings.TextStrokeTransparency;
				Parent = container;
			}

			if chatModeButton:IsA(
				"TextButton"
				) then
				this.ClickedOnModeConn =
					chatModeButton.MouseButton1Click:connect(
						function()
							SelectChatModeEvent:fire(
								this.PlayerChatType
							)
						end
					)
			end

			if
				this.PlayerChatType
				== Enum.PlayerChatType.Team
			then
				chatModeButton.TextColor3 =
					playerColor
			end

			xOffset =
				xOffset
				+ chatTypeSize.X
				+ 1

			this.ChatModeButton =
				chatModeButton
		end

		local userNameButton =
			Util.Create(
				Util.IsTouchDevice()
				and "TextLabel"
				or "TextButton"
			)
		{
			Name = "PlayerName";
			BackgroundTransparency = 1;
			BackgroundColor3 =
				Color3.new(
					0,
					1,
					1
				);
			BorderSizePixel = 0;
			ZIndex = 2;
			Text =
				playerNameDisplayText;
			TextColor3 = playerColor;
			Position =
				UDim2.new(
					0,
					xOffset,
					0,
					0
				);
			TextXAlignment =
				Enum.TextXAlignment.Left;
			TextYAlignment =
				Enum.TextYAlignment.Top;
			FontSize = fontSize;
			Font = this.Settings.Font;
			Size =
				UDim2.new(
					0,
					playerNameSize.X,
					0,
					playerNameSize.Y
				);
			TextStrokeColor3 =
				this.Settings.TextStrokeColor;
			TextStrokeTransparency =
				this.Settings.TextStrokeTransparency;
			Parent = container;
		}

		if userNameButton:IsA(
			"TextButton"
			) then
			this.ClickedOnPlayerConn =
				userNameButton.MouseButton1Click:connect(
					function()
						local gui =
						this:GetGui()

						if
							gui
							and gui.Visible
						then
							if
								this.PlayerChatType
								== Enum.PlayerChatType.Whisper
								and this.SendingPlayer
								== Player
								and this.ReceivingPlayer
							then
								SelectPlayerEvent:fire(
									this.ReceivingPlayer
								)
							else
								SelectPlayerEvent:fire(
									this.SendingPlayer
								)
							end
						end
					end
				)

			this.RightClickedOnPlayerConn =
				userNameButton.MouseButton2Click:connect(
					function()
						local gui =
						this:GetGui()

						if
							gui
							and gui.Visible
						then
							if
								IsPlayerDropDownEnabled
								and playerDropDown
							then
								if
									this.SendingPlayer
									and this.SendingPlayer
									~= Player
								then
									createPopupFrame(
										this.SendingPlayer,
										userNameButton
									)
								end
							end
						end
					end
				)
		end

		local chatMessage =
			Util.Create"TextLabel"
		{
			Name = "ChatMessage";
			Position =
				UDim2.new(
					0,
					xOffset,
					0,
					0
				);
			Size =
				UDim2.new(
					1,
					-xOffset,
					1,
					0
				);
			Text =
				chatMessageDisplayText;
			ZIndex = 1;
			BackgroundColor3 =
				Color3.new(
					0,
					0,
					0
				);
			BackgroundTransparency = 1;
			TextXAlignment =
				Enum.TextXAlignment.Left;
			TextYAlignment =
				Enum.TextYAlignment.Top;
			TextWrapped = true;
			TextColor3 =
				this.Settings.DefaultMessageTextColor;
			FontSize = fontSize;
			Font = this.Settings.Font;
			TextStrokeColor3 =
				this.Settings.TextStrokeColor;
			TextStrokeTransparency =
				this.Settings.TextStrokeTransparency;
			Parent = container;
		}

		if InputService.VREnabled then
			chatMessage.Size =
				chatMessage.Size
			- UDim2.new(
				0,
				4,
				0,
				0
			)
		end

		if
			chatMessage.Text == "Label"
			and chatMessageDisplayText
			~= "Label"
		then
			chatMessage.Text =
				string.rep(
					" ",
					numNeededSpaces
				)
				.. "[Content Deleted]"
		end

		if
			this.SendingPlayer
			and Util.IsPlayerAdminAsync(
				this.SendingPlayer
			)
		then
			chatMessage.TextColor3 =
				this.Settings.AdminTextColor
		end

		chatMessage.Size =
			chatMessage.Size
			+ UDim2.new(
				0,
				0,
				0,
				chatMessage.TextBounds.Y
			)

		container.Size =
			UDim2.new(
				1,
				0,
				0,
				math.max(
					chatMessageSize.Y + 1,
					userNameButton.Size.Y.Offset + 1
				)
			)

		this.Container = container
		this.ChatMessage = chatMessage
		this.UserNameButton =
			userNameButton
	end

	CreateMessageGuiElement()

	return this
end

local function CreateChatBarWidget(
	settings
)
	local this = {}

	this.MessageMode = "All"
	this.TargetWhisperPlayer = nil
	this.Settings = settings

	this.WidgetVisible = false
	this.FadedIn = true

	-- True ONLY for the mobile "..." keyboard-focus behavior.
	this.MobileFocusOnly = false
	this.SuppressMobileFocusChangedSignal = false

	this.ChatBarGainedFocusEvent =
		Util.Signal()

	this.ChatBarLostFocusEvent =
		Util.Signal()

	this.ChatCommandEvent =
		Util.Signal()

	this.ChatErrorEvent =
		Util.Signal()

	this.ChatBarFloodEvent =
		Util.Signal()

	this.ChatSubmittedEvent =
		Util.Signal()

	this.unfocusedAt = 0

	local chatCoreGuiEnabled = true

	local function nocase(s)
		s =
			string.gsub(
				s,
				"%a",
				function(c)
					return string.format(
						"[%s%s]",
						string.lower(c),
						string.upper(c)
					)
				end
			)

		return s
	end

	this.ChatMatchingRegex =
		{
			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/w ")
					.. "(%w+_?%w+)"
				)
			end] = "Whisper";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/whisper ")
					.. "(%w+_?%w+)"
				)
			end] = "Whisper";

			[function(chatBarText)
				return string.find(
					chatBarText,
					"^%%"
				)
			end] = "Team";

			[function(chatBarText)
				return string.find(
					chatBarText,
					"^%(TEAM%)"
				)
			end] = "Team";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/t")
				)
			end] = "Team";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/team")
				)
			end] = "Team";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/a")
				)
			end] = "All";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/all")
				)
			end] = "All";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/s")
				)
			end] = "All";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/say")
				)
			end] = "All";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/e")
				)
			end] = "Emote";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/emote")
				)
			end] = "Emote";

			[function(chatBarText)
				return string.find(
					chatBarText,
					"^/%?"
				)
			end] = "Help";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/help")
				)
			end] = "Help";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/block ")
					.. "(%w+_?%w+)"
				)
			end] = "Block";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/unblock ")
					.. "(%w+_?%w+)"
				)
			end] = "Unblock";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/mute ")
					.. "(%w+_?%w+)"
				)
			end] = "Mute";

			[function(chatBarText)
				return string.find(
					chatBarText,
					nocase("^/unmute ")
					.. "(%w+_?%w+)"
				)
			end] = "Unmute";
		}

	local ChatModesDict =
		{
			["Whisper"] = "Whisper";
			["Team"] = "Team";
			["All"] = "All";
			[Enum.PlayerChatType.Whisper] =
			"Whisper";
			[Enum.PlayerChatType.Team] =
			"Team";
			[Enum.PlayerChatType.All] =
			"All";
		}

	local function TearDownEvents()
		this.ClickToChatButtonConn =
			Util.DisconnectEvent(
				this.ClickToChatButtonConn
			)

		this.ChatBarFocusLostConn =
			Util.DisconnectEvent(
				this.ChatBarFocusLostConn
			)

		this.ChatBarLostFocusConn =
			Util.DisconnectEvent(
				this.ChatBarLostFocusConn
			)

		this.SelectChatModeConn =
			Util.DisconnectEvent(
				this.SelectChatModeConn
			)

		this.SelectPlayerConn =
			Util.DisconnectEvent(
				this.SelectPlayerConn
			)

		this.FocusChatBarInputBeganConn =
			Util.DisconnectEvent(
				this.FocusChatBarInputBeganConn
			)

		this.InputBeganConn =
			Util.DisconnectEvent(
				this.InputBeganConn
			)

		this.ChatBarChangedConn =
			Util.DisconnectEvent(
				this.ChatBarChangedConn
			)

		this.ReturnPressedConn =
			Util.DisconnectEvent(
				this.ReturnPressedConn
			)

		this.EnterKeyConn =
			Util.DisconnectEvent(
				this.EnterKeyConn
			)
	end

	local function HookUpEvents()
		TearDownEvents()

		if this.ClickToChatButton then
			this.ClickToChatButtonConn =
				this.ClickToChatButton.MouseButton1Click:connect(
					function()
						-- Tapping the mobile prompt focuses the actual TextBox.
						-- It must NOT act like the topbar "..." button.
						if Util.IsTouchDevice() then
							this.SuppressMobileFocusChangedSignal = true
							this:FocusChatBar()
							task.defer(function()
								this.SuppressMobileFocusChangedSignal = false
							end)
						else
							this:FocusChatBar()
						end
					end
				)
		end

		if this.ChatBar then
			local count = 0
			local suppressFocusLostSubmit =
				false

			this.Submitting = false

			-- PC: normal Return/Enter.
			if not Util.IsTouchDevice() then
				this.FocusChatBarInputBeganConn =
					Chat2017Track(InputService.InputBegan:connect(
						function(inputObj)
							if
								this:IsFocused()
								and inputObj.KeyCode
								== Enum.KeyCode.Return
							then
								if not this.Submitting then
									this.Submitting =
									true

									suppressFocusLostSubmit =
									true

									this:SubmitChat()

									this.ChatBar:ReleaseFocus(
										false
									)

									task.defer(
										function()
											suppressFocusLostSubmit =
											false

											this.Submitting =
											false
										end
									)
								end

								return
							end

							if
								inputObj.KeyCode
								== Enum.KeyCode.Backspace
								and this:GetChatBarText()
								== ""
							then
								if count == 0 then
									count =
									count + 1
								else
									this:SetMessageMode(
										"All"
									)
								end
							else
								count = 0
							end
						end
					))
			end

			this.ChatBarFocusLostConn =
				this.ChatBar.FocusLost:connect(
					function(enterPressed)
						count = 0
						this.unfocusedAt =
						tick()

						if
							enterPressed
							and not suppressFocusLostSubmit
							and not this.Submitting
						then
							this.Submitting =
							true

							this:SubmitChat()

							this.Submitting =
							false
						end

						this.ChatBarLostFocusEvent:fire(
							false
						)
					end
				)

			-- Mobile on-screen Return.
			this.ReturnPressedConn =
				this.ChatBar.ReturnPressedFromOnScreenKeyboard:Connect(
					function()
						if not Util.IsTouchDevice() then
							return
						end

						if not this.Submitting then
							this.Submitting =
							true

							suppressFocusLostSubmit =
							true

							this:SubmitChat()

							this.ChatBar:ReleaseFocus(
								false
							)

							task.defer(
								function()
									suppressFocusLostSubmit =
									false

									this.Submitting =
									false
								end
							)
						end
					end
				)

			this.ChatBarChangedConn =
				this.ChatBar.Changed:connect(
					function(prop)
						if prop == "Text" then
							this:OnChatBarTextChanged()

						elseif
							prop == "TextFits"
							or prop == "TextBounds"
							or prop == "Visible"
						then
							this:OnChatBarBoundsChanged()
						end
					end
				)
		end

		if this.ChatBarLostFocusEvent then
			this.ChatBarLostFocusConn =
				this.ChatBarLostFocusEvent:connect(
					function(enterPressed)
						this:OnChatBarFocusLost(
							enterPressed
						)
					end
				)
		end

		this.SelectChatModeConn =
			SelectChatModeEvent:connect(
				function(chatType)
					this:SetMessageMode(
						chatType
					)

					this:FocusChatBar()
				end
			)

		this.SelectPlayerConn =
			SelectPlayerEvent:connect(
				function(chatPlayer)
					this.TargetWhisperPlayer =
					chatPlayer

					this:SetMessageMode(
						"Whisper"
					)

					this:FocusChatBar()
				end
			)

		this.InputBeganConn =
			Chat2017Track(InputService.InputBegan:connect(
				function(inputObject)
					if
						inputObject.KeyCode
						== Enum.KeyCode.Escape
					then
						this:SetChatBarText("")
					end
				end
			))
	end

	function this:CalculateVisibility()
		if this.ChatBarContainer then
			local enabled =
				this.WidgetVisible
				and chatCoreGuiEnabled
				and not NON_CORESCRIPT_MODE

			if enabled then
				HookUpEvents()
			else
				TearDownEvents()
			end

			this.ChatBarContainer.Visible =
				enabled
				and this.FadedIn
				and not chatBarDisabled
				and not this.MobileFocusOnly
		end
	end

	function this:ToggleVisibility(
		visible
	)
		if
			visible
			~= this.WidgetVisible
		then
			this.WidgetVisible =
				visible

			this:CalculateVisibility()
		end

		if
			this.ChatBarContainer
			and (
				NON_CORESCRIPT_MODE
					or chatBarDisabled
			)
		then
			this.ChatBarContainer.Visible =
				false
		end
	end

	function this:FadeIn()
		this.FadedIn = true
		this:CalculateVisibility()
	end

	function this:FadeOut()
		this.FadedIn = false
		this:CalculateVisibility()
	end

	function this:CoreGuiChanged(
		coreGuiType,
		enabled
	)
		if
			coreGuiType
			== Enum.CoreGuiType.Chat
			or coreGuiType
			== Enum.CoreGuiType.All
		then
			chatCoreGuiEnabled =
				enabled

			this:CalculateVisibility()
		end
	end

	function this:IsAChatMode(
		mode
	)
		return
			ChatModesDict[mode]
			~= nil
	end

	function this:ProcessChatBarModes(
		requireWhitespaceAfterChatMode
	)
		local matchedAChatCommand =
			false

		if this.ChatBar then
			local chatBarText =
				this:SanitizeInput(
					this:GetChatBarText()
				)

			for regexFunc, actionType in pairs(
				this.ChatMatchingRegex
				) do
				local start,
					finish,
					capture =
					regexFunc(
						chatBarText
					)

				if start and finish then
					local whitespaceAfterSlashCommand =
						string.find(
							string.sub(
								chatBarText,
								finish + 1,
								finish + 1
							),
							"%s"
						)

					if
						(
							not requireWhitespaceAfterChatMode
								and finish
								== #chatBarText
						)
							or whitespaceAfterSlashCommand
					then
						if
							this:IsAChatMode(
								actionType
							)
						then
							if actionType == "Whisper" then
								local targetPlayer =
									capture
									and Util.GetPlayerByName(
										capture
									)

								if targetPlayer then
									this.TargetWhisperPlayer =
										targetPlayer

									this:SetChatBarText(
										string.sub(
											chatBarText,
											finish + 2
										)
									)

									this:SetMessageMode(
										actionType
									)

									this.ChatCommandEvent:fire(
										true,
										actionType,
										capture
									)
								else
									if
										not requireWhitespaceAfterChatMode
									then
										this:SetChatBarText(
											""
										)

										this.ChatCommandEvent:fire(
											false,
											actionType,
											capture
										)
									end
								end
							else
								this:SetChatBarText(
									string.sub(
										chatBarText,
										finish + 2
									)
								)

								this:SetMessageMode(
									actionType
								)

								this.ChatCommandEvent:fire(
									true,
									actionType,
									capture
								)
							end
						elseif actionType == "Emote" then
							this:SetMessageMode(
								"All"
							)

						elseif
							not requireWhitespaceAfterChatMode
						then
							if actionType == "Help" then
								this:SetChatBarText(
									""
								)
							end

							this.ChatCommandEvent:fire(
								true,
								actionType,
								capture
							)
						end

						matchedAChatCommand =
							true
					end
				end
			end
		end

		return matchedAChatCommand
	end

	local previousText = ""

	function this:OnChatBarTextChanged()
		if not Util.IsTouchDevice() then
			this:ProcessChatBarModes(
				true
			)

			local originalText =
				this:GetChatBarText()

			local newText =
				Util.FilterUnprintableCharacters(
					originalText
				)

			if newText ~= originalText then
				previousText =
					newText
			end

			local fixedText =
				newText

			if
				#newText
				> this.Settings.MaxCharactersInMessage
				or originalText
				~= newText
			then
				if
					#newText
					== #previousText + 1
				then
					fixedText =
						string.sub(
							previousText,
							1,
							this.Settings.MaxCharactersInMessage
						)
				else
					fixedText =
						string.sub(
							newText,
							1,
							this.Settings.MaxCharactersInMessage
						)
				end
			end

			this:SetChatBarText(
				fixedText
			)

			-- PC uses ClickToChat as the prompt.
			-- Never leave it visible over actual typed text.
			if this.ClickToChatButton then
				if fixedText ~= "" then
					this.ClickToChatButton.Visible = false
					this.ClickToChatButton.Active = false
				elseif not this:IsFocused() then
					this.ClickToChatButton.Visible = true
					this.ClickToChatButton.Active = true
				end
			end

			previousText =
				fixedText
		end
	end

	function this:OnChatBarBoundsChanged()
	end

	function this:GetChatBarText()
		return
			this.ChatBar
			and this.ChatBar.Text
			or ""
	end

	function this:SetChatBarText(
		newText
	)
		if
			this.ChatBar
			and newText
			~= this.ChatBar.Text
		then
			this.ChatBar.Text =
				newText
		end
	end

	function this:GetMessageMode()
		return this.MessageMode
	end

	function this:SetMessageMode(
		newMessageMode
	)
		newMessageMode =
			ChatModesDict[
		newMessageMode
		]

		local chatRecipientText =
			"["
			.. (
				this.TargetWhisperPlayer
				and this.TargetWhisperPlayer.Name
				or ""
			)
			.. "]"

		if
			this.MessageMode
			~= newMessageMode
			or (
				newMessageMode
					== "Whisper"
					and this.ChatModeText
					and chatRecipientText
					~= this.ChatModeText.Text
			)
		then
			if this.ChatModeText then
				this.MessageMode =
					newMessageMode

				if newMessageMode == "Whisper" then
					local chatRecipientTextBounds =
						Util.GetStringTextBounds(
							chatRecipientText,
							this.ChatModeText.Font,
							this.ChatModeText.FontSize
						)

					this.ChatModeText.TextColor3 =
						this.Settings.WhisperTextColor

					this.ChatModeText.Text =
						chatRecipientText

					this.ChatModeText.Size =
						UDim2.new(
							0,
							chatRecipientTextBounds.X,
							1,
							0
						)

				elseif newMessageMode == "Team" then
					local chatTeamText =
						"[Team]"

					local chatTeamTextBounds =
						Util.GetStringTextBounds(
							chatTeamText,
							this.ChatModeText.Font,
							this.ChatModeText.FontSize
						)

					this.ChatModeText.TextColor3 =
						this.Settings.TeamTextColor

					this.ChatModeText.Text =
						"[Team]"

					this.ChatModeText.Size =
						UDim2.new(
							0,
							chatTeamTextBounds.X,
							1,
							0
						)
				else
					this.ChatModeText.Text =
						""

					this.ChatModeText.Size =
						UDim2.new(
							0,
							0,
							1,
							0
						)
				end

				if this.ChatBar then
					local offset =
						this.ChatModeText.Size.X.Offset
						+ this.ChatModeText.Position.X.Offset

					this.ChatBar.Size =
						UDim2.new(
							1,
							-14 - offset,
							1,
							0
						)

					this.ChatBar.Position =
						UDim2.new(
							0,
							7 + offset,
							0,
							0
						)
				end
			end
		end
	end

	-- =========================================================
	-- MOBILE CHAT FIX
	-- =========================================================

	function this:ShowChatBar()
		if
			not this.ChatBar
			or not this.ChatBarContainer
			or chatBarDisabled
			or not chatCoreGuiEnabled
		then
			return
		end

		this.MobileFocusOnly = false
		this.WidgetVisible = true
		this.FadedIn = true

		this:CalculateVisibility()

		this.ChatBarContainer.Visible = true

		if Util.IsTouchDevice() then
			-- On mobile, ClickToChat IS the visible chat bar.
			-- The TextBox stays behind it until the user taps it.
			this.ChatBar.Visible = true
			this.ChatBar.TextTransparency = 1
			this.ChatBar.BackgroundTransparency = 1
			this.ChatBar.PlaceholderText = ""

			if this.ChatBarBackground then
				this.ChatBarBackground.BackgroundTransparency = 0.6
			end

			if this.ChatBarInnerBackground then
				this.ChatBarInnerBackground.BackgroundTransparency = 0.6
			end

			if this.ClickToChatButton then
				this.ClickToChatButton.Visible = true
				this.ClickToChatButton.Active = true
				this.ClickToChatButton.Text = "Tap here to chat"
			end
		else
			-- Desktop keeps the same overlay-style legacy bar.
			this.ChatBar.Visible = true
			this.ChatBar.TextTransparency = 0.4
			this.ChatBar.BackgroundTransparency = 1
			this.ChatBar.PlaceholderText = ""

			if this.ClickToChatButton then
				local showPrompt =
					this:GetChatBarText() == ""

				this.ClickToChatButton.Visible =
					showPrompt

				this.ClickToChatButton.Active =
					showPrompt
			end

			if this.ChatBarBackground then
				this.ChatBarBackground.BackgroundTransparency = 0.6
			end

			if this.ChatBarInnerBackground then
				this.ChatBarInnerBackground.BackgroundTransparency = 0.6
			end
		end

		if this.ChatModeText then
			this.ChatModeText.Visible = false
		end
	end

	function this:FocusChatBar()
		if
			this.ChatBar
			and not chatBarDisabled
			and chatCoreGuiEnabled
		then
			local focusOnly =
				Util.IsTouchDevice()
				and this.MobileFocusOnly

			if focusOnly then
				-- The mobile "..." action focuses the hidden
				-- TextBox without opening the ChatWindow.
				this.WidgetVisible = true
				this.FadedIn = true

				HookUpEvents()

				this.ChatBarContainer.Visible = true
				this.ChatBar.Visible = true
				this.ChatBar.TextTransparency = 1
				this.ChatBar.BackgroundTransparency = 1
				this.ChatBar.PlaceholderText = ""

				if this.ChatBarBackground then
					this.ChatBarBackground.BackgroundTransparency = 1
				end

				if this.ChatBarInnerBackground then
					this.ChatBarInnerBackground.BackgroundTransparency = 1
				end

				if this.ClickToChatButton then
					this.ClickToChatButton.Visible = false
					this.ClickToChatButton.Active = false
				end

				if this.ChatModeText then
					this.ChatModeText.Visible = false
				end
			else
				-- Normal focus: the visible ClickToChat overlay is
				-- removed so the actual TextBox receives input.
				this:ShowChatBar()

				this.ChatBar.TextTransparency = 0.4

				if this.ClickToChatButton then
					this.ClickToChatButton.Visible = false
					this.ClickToChatButton.Active = false
				end
			end

			this.ChatBar:CaptureFocus()

			if
				Util.IsTouchDevice()
				or InputService.VREnabled
			then
				this:SetMessageMode("All")
			end

			this:OnChatBarBoundsChanged()
			this.ChatBarGainedFocusEvent:fire()
		end
	end

	function this:RemoveFocus()
		if this:IsFocused() then
			this.ChatBar:ReleaseFocus()
		end
	end

	function this:IsFocused()
		return
			this.ChatBar
			and this.ChatBar
			== InputService:GetFocusedTextBox()
	end

	function this:WasFocused()
		return
			(tick() - this.unfocusedAt)
			< VR_CHAT_CLICK_DEBOUNCE
	end

	function this:SanitizeInput(
		input
	)
		local sanitizedInput =
			input

		local _, _, capture =
			string.find(
				sanitizedInput,
				"^%s*(.*)%s*$"
			)

		sanitizedInput =
			capture or ""

		return sanitizedInput
	end

	local sentMessageTimeQueue =
		{}

	function this:FloodCheck()
		if not GetLuaChatFilteringFlag() then
			return false
		end

		while
			sentMessageTimeQueue[1]
			and tick()
			- sentMessageTimeQueue[1]
				> FLOOD_CHECK_MESSAGE_INTERVAL
		do
			table.remove(
				sentMessageTimeQueue,
				1
			)
		end

		if
			#sentMessageTimeQueue
			> FLOOD_CHECK_MESSAGE_COUNT
		then
			return true
		end

		return false
	end

	function this:SubmitChat()
		if not this.ChatBar then
			return
		end

		this:ProcessChatBarModes(
			false
		)

		local cText =
			this:SanitizeInput(
				this:GetChatBarText()
			)

		if cText == "" then
			return
		end

		if this:FloodCheck() then
			this.ChatBarFloodEvent:fire()
			return
		end

		local currentMessageMode =
			this:GetMessageMode()

		if currentMessageMode == "Team" then
			if
				Player
				and Player.Neutral == true
			then
				this.ChatErrorEvent:fire(
					"You're not on a team."
				)
			else
				pcall(
					function()
						PlayersService:TeamChat(
							cText
						)
					end
				)
			end

		elseif currentMessageMode == "Whisper" then
			if this.TargetWhisperPlayer then
				if
					this.TargetWhisperPlayer
					== Player
				then
					this.ChatErrorEvent:fire(
						"You cannot send a whisper to yourself."
					)
				else
					pcall(
						function()
							PlayersService:WhisperChat(
								cText,
								this.TargetWhisperPlayer
							)
						end
					)
				end
			else
				this.ChatErrorEvent:fire(
					"Invalid whisper target."
				)
			end

		elseif currentMessageMode == "All" then
			task.spawn(
				function()
					local success,
					result =
						pcall(
							function()
								return RBXGeneral:SendAsync(
									cText
								)
							end
						)

					if not success then
						warn(
							"[Legacy Chat] SendAsync failed:",
							result
						)
					elseif
						result
						and result.Status
						~= Enum.TextChatMessageStatus.Success
					then
						warn(
							"[Legacy Chat] Message was not accepted. Status:",
							result.Status
						)
					end
				end
			)
		end

		table.insert(
			sentMessageTimeQueue,
			tick()
		)

		this:SetChatBarText("")

		this.ChatSubmittedEvent:fire()
	end

	function this:OnChatBarFocusLost(enterPressed)
		if this.ChatBar then
			this.ChatBar.Visible = true

			if
				enterPressed
				or InputService.VREnabled
			then
				this:SubmitChat()
			end

			if this.MobileFocusOnly then
				-- The "..." keyboard-only bar disappears after
				-- focus is released. The ChatWindow remains closed.
				if this.ClickToChatButton then
					this.ClickToChatButton.Visible = false
					this.ClickToChatButton.Active = false
				end

				this.ChatBarContainer.Visible = false
			else
				-- Normal legacy mobile state: the visible chat bar is
				-- the "Tap here to chat" button.
				if Util.IsTouchDevice() then
					this.ChatBar.TextTransparency = 1
					this.ChatBar.BackgroundTransparency = 1
					this.ChatBar.PlaceholderText = ""

					if this.ClickToChatButton then
						this.ClickToChatButton.Visible = true
						this.ClickToChatButton.Active = true
						this.ClickToChatButton.Text = "Tap here to chat"
					end
				else
					this.ChatBar.TextTransparency = 0.4
					this.ChatBar.BackgroundTransparency = 1
					this.ChatBar.PlaceholderText = ""

					if this.ClickToChatButton then
						local text =
							this:GetChatBarText()

						local showPrompt =
							text == ""

						this.ClickToChatButton.Visible =
							showPrompt

						this.ClickToChatButton.Active =
							showPrompt
					end
				end

				if this.ChatBarBackground then
					this.ChatBarBackground.BackgroundTransparency = 0.6
				end

				if this.ChatBarInnerBackground then
					this.ChatBarInnerBackground.BackgroundTransparency = 0.6
				end

				if
					this.ChatBarContainer
					and this.WidgetVisible
				then
					this.ChatBarContainer.Visible = true
				end
			end

			if this.ChatModeText then
				this.ChatModeText.Visible = false
			end
		end
	end

	local function CreateChatBar()
		local chatBarContainer =
			Util.Create"Frame"
		{
			Name = "ChatBarContainer";
			Position =
				UDim2.new(
					0,
					0,
					1,
					-42
				);
			Size =
				UDim2.new(
					1,
					0,
					0,
					42
				);
			ZIndex = 1;
			BackgroundColor3 =
				Color3.fromRGB(
					163,
					162,
					165
				);
			BackgroundTransparency = 1;
			BorderColor3 =
				Color3.fromRGB(
					27,
					42,
					53
				);
			BorderSizePixel = 1;
		}

		local chatBarBackground =
			Util.Create"Frame"
		{
			Name = "Frame";
			Position =
				UDim2.new(
					0,
					0,
					0,
					0
				);
			Size =
				UDim2.new(
					1,
					0,
					1,
					0
				);
			ZIndex = 1;
			BackgroundColor3 =
				Color3.fromRGB(
					0,
					0,
					0
				);
			BackgroundTransparency = 0.6;
			BorderColor3 =
				Color3.fromRGB(
					27,
					42,
					53
				);
			BorderSizePixel = 0;
			Selectable = false;
		}

		chatBarBackground.Parent =
			chatBarContainer

		local chatBarInnerBackground =
			Util.Create"Frame"
		{
			Name = "BoxFrame";
			Position =
				UDim2.new(
					0,
					7,
					0,
					7
				);
			Size =
				UDim2.new(
					1,
					-14,
					1,
					-14
				);
			ZIndex = 1;
			BackgroundColor3 =
				Color3.fromRGB(
					255,
					255,
					255
				);
			BackgroundTransparency = 0.6;
			BorderColor3 =
				Color3.fromRGB(
					27,
					42,
					53
				);
			BorderSizePixel = 0;
			Selectable = false;
		}

		chatBarInnerBackground.Parent =
			chatBarBackground

		local chatBarContent =
			Util.Create"Frame"
		{
			Name = "Frame";
			Position =
				UDim2.new(
					0,
					5,
					0,
					5
				);
			Size =
				UDim2.new(
					1,
					-10,
					1,
					-10
				);
			ZIndex = 1;
			BackgroundColor3 =
				Color3.fromRGB(
					163,
					162,
					165
				);
			BackgroundTransparency = 1;
			BorderColor3 =
				Color3.fromRGB(
					27,
					42,
					53
				);
			BorderSizePixel = 1;
			Selectable = false;
		}

		chatBarContent.Parent =
			chatBarInnerBackground

		local chatBar =
			Util.Create"TextBox"
		{
			Name = "ChatBar";
			Position =
				UDim2.new(
					0,
					0,
					0,
					0
				);
			Size =
				UDim2.new(
					1,
					0,
					1,
					0
				);
			Text = "";
			ZIndex = 1;

			BackgroundColor3 =
				Color3.fromRGB(
					163,
					162,
					165
				);

			BackgroundTransparency = 1;

			BorderColor3 =
				Color3.fromRGB(
					27,
					42,
					53
				);

			BorderSizePixel = 1;

			Active = true;
			Selectable = false;

			TextColor3 =
				Color3.fromRGB(
					0,
					0,
					0
				);

			TextTransparency = 0.4;

			TextStrokeColor3 =
				Color3.fromRGB(
					0,
					0,
					0
				);

			TextStrokeTransparency = 1;

			TextXAlignment =
				Enum.TextXAlignment.Left;

			TextYAlignment =
				Enum.TextYAlignment.Top;

			TextWrapped = true;

			Font =
				Enum.Font.SourceSansBold;

			FontSize =
				Enum.FontSize.Size18;

			ClearTextOnFocus = false;
			MultiLine = false;

			PlaceholderText =
				Util.IsTouchDevice()
				and "Tap here to chat"
				or 'To chat click here or press "/" key';

			Visible = true;

			SelectionImageObject =
				emptySelectionImage;
		}

		chatBar.Parent =
			chatBarContent

		local chatModeText =
			Util.Create"TextButton"
		{
			Name = "MessageMode";
			Position =
				UDim2.new(
					0,
					0,
					0,
					0
				);
			Size =
				UDim2.new(
					0,
					0,
					0,
					0
				);

			BackgroundColor3 =
				Color3.fromRGB(
					163,
					162,
					165
				);

			BackgroundTransparency = 1;

			BorderColor3 =
				Color3.fromRGB(
					27,
					42,
					53
				);

			BorderSizePixel = 1;

			Active = true;
			Selectable = false;

			ZIndex = 1;

			Text = "";

			TextColor3 =
				Color3.fromRGB(
					35,
					76,
					142
				);

			TextTransparency = 0.4;

			TextStrokeColor3 =
				Color3.fromRGB(
					0,
					0,
					0
				);

			TextStrokeTransparency = 1;

			TextXAlignment =
				Enum.TextXAlignment.Left;

			TextYAlignment =
				Enum.TextYAlignment.Center;

			TextWrapped = true;

			Font =
				Enum.Font.SourceSansBold;

			FontSize =
				Enum.FontSize.Size18;

			AutoButtonColor = true;
			Modal = false;
		}

		chatModeText.Parent =
			chatBarContent

		local clickToChatButton =
			Util.Create"TextButton"
		{
			Name = "ClickToChat";
			Position =
				UDim2.new(
					0,
					0,
					0,
					0
				);
			Size =
				UDim2.new(
					1,
					0,
					1,
					0
				);

			BackgroundColor3 =
				Color3.fromRGB(
					163,
					162,
					165
				);

			BackgroundTransparency = 1;

			BorderColor3 =
				Color3.fromRGB(
					27,
					42,
					53
				);

			BorderSizePixel = 1;

			Active = true;
			Selectable = false;

			ZIndex = 2;

			Text =
				'To chat click here or press "/" key';

			TextColor3 =
				Color3.fromRGB(
					0,
					0,
					0
				);

			TextTransparency = 0.4;

			TextStrokeColor3 =
				Color3.fromRGB(
					0,
					0,
					0
				);

			TextStrokeTransparency = 1;

			TextXAlignment =
				Enum.TextXAlignment.Left;

			TextYAlignment =
				Enum.TextYAlignment.Top;

			TextWrapped = true;

			Font =
				Enum.Font.SourceSansBold;

			FontSize =
				Enum.FontSize.Size18;

			AutoButtonColor = false;
			Modal = false;
		}

		clickToChatButton.Parent =
			chatBarContent

		if Util.IsTouchDevice() then
			clickToChatButton.Text =
				"Tap here to chat"
		end

		this.ChatBarContainer =
			chatBarContainer

		this.ChatBarBackground =
			chatBarBackground

		this.ChatBarInnerBackground =
			chatBarInnerBackground

		this.ClickToChatButton =
			clickToChatButton

		this.ChatBar =
			chatBar

		this.ChatBarPlaceholderText =
			Util.IsTouchDevice()
			and "Tap here to chat"
			or 'To chat click here or press "/" key'

		this.ChatModeText =
			chatModeText

		this.ChatBarContainer.Parent =
			GuiRoot

		local function RobloxClientScreenSizeChanged(
			newSize
		)
			if not chatBarContainer then
				return
			end

			if
				newSize.X
				<= PHONE_SCREEN_WIDTH
			then
				chatBarContainer.Size =
					UDim2.new(
						0.5,
						0,
						0,
						42
					)

				-- Only the mobile position is changed: 2 px below the ChatWindow.
				chatBarContainer.Position =
					UDim2.new(
						0,
						0,
						PHONE_CHAT_WINDOW_HEIGHT,
						3
					)

				chatBar.FontSize = Enum.FontSize.Size14
				clickToChatButton.FontSize = Enum.FontSize.Size14
				chatModeText.FontSize = Enum.FontSize.Size14

			elseif
				newSize.X
				<= TABLET_SCREEN_WIDTH
			then
				chatBarContainer.Size =
					UDim2.new(
						0.4,
						0,
						0,
						42
					)

				-- Only the mobile position is changed: 2 px below the ChatWindow.
				chatBarContainer.Position =
					UDim2.new(
						0,
						0,
						TABLET_CHAT_WINDOW_HEIGHT,
						3
					)

				chatBar.FontSize = Enum.FontSize.Size18
				clickToChatButton.FontSize = Enum.FontSize.Size18
				chatModeText.FontSize = Enum.FontSize.Size18
			else
				chatBarContainer.Size =
					UDim2.new(
						0.3,
						0,
						0,
						42
					)

				chatBarContainer.Position =
					UDim2.new(
						0,
						0,
						0.25,
						-18
					)

				chatBar.FontSize =
					Enum.FontSize.Size18

				clickToChatButton.FontSize =
					Enum.FontSize.Size18

				chatModeText.FontSize =
					Enum.FontSize.Size18
			end

			if InputService.VREnabled then
				chatBarContainer.Position =
					UDim2.new(
						0,
						0,
						0.3,
						-42
					)
			end
		end

		GuiRoot.Changed:connect(
			function(prop)
				if
					prop == "AbsoluteSize"
					and not chatRepositioned
				then
					RobloxClientScreenSizeChanged(
						GuiRoot.AbsoluteSize
					)
				end
			end
		)

		RobloxClientScreenSizeChanged(
			GuiRoot.AbsoluteSize
		)
	end

	CreateChatBar()

	return this
end

local function CreateChatWindowWidget(
	settings
)
	local this = {}

	this.Settings = settings
	this.Chats = {}
	this.BackgroundVisible = false
	this.ChatsVisible = false
	this.WidgetVisible = false
	this.NewUnreadMessage = false
	this.MessageCount = 0

	this.MessageCountChanged =
		Util.Signal()

	this.FadeInSignal =
		Util.Signal()

	this.FadeOutSignal =
		Util.Signal()

	this.ChatWindowPagingConn = nil

	local lastMoveTime = tick()
	local lastEnterTime = tick()
	local lastLeaveTime = tick()

	local lastFadeOutTime = 0
	local lastFadeInTime = 0
	local lastChatActivity = 0

	local FadeLock = false

	local chatCoreGuiEnabled = true


	local function PointInChatWindow(pt)
		local point0 =
			this.ChatContainer.AbsolutePosition

		local point1 =
			point0
			+ this.ChatContainer.AbsoluteSize

		point1 =
			point1
			+ Vector2.new(
				0,
				34
			)

		return
			point0.X <= pt.X
			and point1.X >= pt.X
			and point0.Y <= pt.Y
			and point1.Y >= pt.Y
	end

	function this:IsHovering()
		if
			this.ChatContainer
			and this.LastMousePosition
			and this:CalculateVisibility()
		then
			return PointInChatWindow(
				this.LastMousePosition
			)
		end

		return false
	end

	function this:SetFadeLock(
		lock
	)
		FadeLock = lock
	end

	function this:GetFadeLock()
		return FadeLock
	end

	function this:SetCanvasPosition(
		newCanvasPosition
	)
		if this.ScrollingFrame then
			local maxSize =
				Vector2.new(
					math.max(
						0,
						this.ScrollingFrame.CanvasSize.X.Offset
						- this.ScrollingFrame.AbsoluteWindowSize.X
					),
					math.max(
						0,
						this.ScrollingFrame.CanvasSize.Y.Offset
						- this.ScrollingFrame.AbsoluteWindowSize.Y
					)
				)

			this.ScrollingFrame.CanvasPosition =
				Vector2.new(
					Util.Clamp(
						0,
						maxSize.X,
						newCanvasPosition.X
					),
					Util.Clamp(
						0,
						maxSize.Y,
						newCanvasPosition.Y
					)
				)
		end
	end

	function this:ScrollToBottom()
		if this.ScrollingFrame then
			this:SetCanvasPosition(
				Vector2.new(
					this.ScrollingFrame.CanvasPosition.X,
					this.ScrollingFrame.CanvasSize.Y.Offset
				)
			)
		end
	end

	function this:FadeIn(
		duration,
		lockFade
	)
		if not FadeLock then
			duration =
				duration
				or 0.75

			local backgroundTransparency =
				InputService.VREnabled
				and 1
				or 0.6

			if this.BackgroundTweener then
				this.BackgroundTweener:Cancel()
			end

			lastFadeInTime =
				tick()

			lastChatActivity =
				tick()

			this.ScrollingFrame.ScrollingEnabled =
				true

			this.ScrollingFrame.ScrollBarThickness =
				SCROLLBAR_THICKNESS

			this.BackgroundTweener =
				Util.PropertyTweener(
					this.ChatContainer,
					"BackgroundTransparency",
					this.ChatContainer.BackgroundTransparency,
					backgroundTransparency,
					duration,
					Util.Linear
				)

			this.BackgroundVisible =
				true

			this:FadeInChats()

			this.ChatWindowPagingConn =
				Util.DisconnectEvent(
					this.ChatWindowPagingConn
				)

			this.ChatWindowPagingConn =
				Chat2017Track(InputService.InputBegan:connect(
					function(inputObject)
						local key =
						inputObject.KeyCode

						if
							key
							== Enum.KeyCode.PageUp
						then
							this:SetCanvasPosition(
								this.ScrollingFrame.CanvasPosition
								- Vector2.new(
									0,
									this.ScrollingFrame.AbsoluteWindowSize.Y
								)
							)

						elseif
							key
							== Enum.KeyCode.PageDown
						then
							this:SetCanvasPosition(
								this.ScrollingFrame.CanvasPosition
								+ Vector2.new(
									0,
									this.ScrollingFrame.AbsoluteWindowSize.Y
								)
							)

						elseif
							key
							== Enum.KeyCode.Home
						then
							this:SetCanvasPosition(
								Vector2.new(
									0,
									0
								)
							)

						elseif
							key
							== Enum.KeyCode.End
						then
							this:ScrollToBottom()
						end
					end
				))

			if this.FadeInSignal then
				this.FadeInSignal:fire()
			end
		end
	end

	function this:FadeOut(
		duration,
		unlockFade
	)
		if not FadeLock then
			duration =
				duration
				or 0.75

			if this.BackgroundTweener then
				this.BackgroundTweener:Cancel()
			end

			lastFadeOutTime =
				tick()

			lastChatActivity =
				tick()

			this.ScrollingFrame.ScrollingEnabled =
				false

			this.ScrollingFrame.ScrollBarThickness =
				0

			this.BackgroundTweener =
				Util.PropertyTweener(
					this.ChatContainer,
					"BackgroundTransparency",
					this.ChatContainer.BackgroundTransparency,
					1,
					duration,
					Util.Linear,
					function()
						if this.FadeOutSignal then
							this.FadeOutSignal:fire()
						end
					end
				)

			this.BackgroundVisible =
				false

			this.ChatWindowPagingConn =
				Util.DisconnectEvent(
					this.ChatWindowPagingConn
				)
		end
	end

	function this:FadeInChats()
		if this.ChatsVisible == true then
			return
		end

		this.ChatsVisible =
			true

		for _, message in pairs(
			this.Chats
			) do
			message:FadeIn()
		end
	end

	function this:FadeOutChats()
		if InputService.VREnabled then
			return
		end

		if this.ChatsVisible == false then
			return
		end

		this.ChatsVisible =
			false

		if
			IsPlayerDropDownEnabled
			and playerDropDown
		then
			playerDropDown:Hide()
		end

		for _, message in pairs(
			this.Chats
			) do
			local messageGui =
				message:GetGui()

			local instant = false

			if
				messageGui
				and this.ScrollingFrame
			then
				if
					messageGui.AbsolutePosition.Y
					>
					(
						this.ScrollingFrame.AbsolutePosition
							+ this.ScrollingFrame.AbsoluteWindowSize
					).Y
						or
						messageGui.AbsolutePosition.Y
						+ messageGui.AbsoluteSize.Y
						< this.ScrollingFrame.AbsolutePosition.Y
				then
					instant = true
				end
			end

			message:FadeOut(
				instant
			)
		end
	end

	local ResizeCount = 0

	function this:OnResize()
		ResizeCount =
			ResizeCount + 1

		local currentResizeCount =
			ResizeCount

		local isScrolledDown =
			this:IsScrolledDown()

		wait()

		if this.ScrollingFrame then
			if
				currentResizeCount
				~= ResizeCount
			then
				return
			end

			local scrollingFrameAbsoluteSize =
				this.ScrollingFrame.AbsoluteWindowSize

			if
				scrollingFrameAbsoluteSize
				~= nil
				and scrollingFrameAbsoluteSize.X
				> 0
				and scrollingFrameAbsoluteSize.Y
				> 0
			then
				local ySize = 0

				for _, message in pairs(
					this.Chats
					) do
					local newHeight =
						message:OnResize(
							scrollingFrameAbsoluteSize
						)

					if newHeight then
						local chatMessageElement =
							message:GetGui()

						if chatMessageElement then
							local chatMessageElementYSize =
								chatMessageElement.Size.Y.Offset

							chatMessageElement.Position =
								UDim2.new(
									0,
									0,
									0,
									ySize
								)

							ySize =
								ySize
								+ chatMessageElementYSize
						end
					end
				end

				if
					this.MessageContainer
					and this.ScrollingFrame
				then
					this.MessageContainer.Size =
						UDim2.new(
							this.MessageContainer.Size.X.Scale,
							this.MessageContainer.Size.X.Offset,
							0,
							ySize
						)

					this.MessageContainer.Position =
						UDim2.new(
							0,
							0,
							0,
							0
						)

					this.ScrollingFrame.CanvasSize =
						UDim2.new(
							this.ScrollingFrame.CanvasSize.X.Scale,
							this.ScrollingFrame.CanvasSize.X.Offset,
							this.ScrollingFrame.CanvasSize.Y.Scale,
							ySize
						)
				end
			end

			if isScrolledDown then
				this:ScrollToBottom()
			else
				this:ScrollToBottom()
			end
		end
	end

	function this:FilterMessage(
		playerChatType,
		sendingPlayer,
		chattedMessage,
		receivingPlayer
	)
		if
			chattedMessage
			and string.sub(
				chattedMessage,
				1,
				1
			) ~= "/"
		then
			return true
		end

		return false
	end

	function this:PushMessageIntoQueue(
		chatMessage,
		silently
	)
		table.insert(
			this.Chats,
			chatMessage
		)

		local isScrolledDown =
			this:IsScrolledDown()

		local chatMessageElement =
			chatMessage:GetGui()

		chatMessageElement.Parent =
			this.MessageContainer

		local chatMessageHeight =
			chatMessage:OnResize()
			or 10

		local ySize =
			this.MessageContainer.Size.Y.Offset

		local chatMessageElementYSize =
			UDim2.new(
				0,
				0,
				0,
				chatMessageHeight
			)

		if not silently then
			this.MessageCount =
				this.MessageCount + 1
		end

		chatMessageElement.Position =
			chatMessageElement.Position
			+ UDim2.new(
				0,
				0,
				0,
				ySize
			)

		this.MessageContainer.Size =
			this.MessageContainer.Size
			+ chatMessageElementYSize

		this.ScrollingFrame.CanvasSize =
			this.ScrollingFrame.CanvasSize
			+ chatMessageElementYSize

		if
			this.Settings.MaxWindowChatMessages
			< #this.Chats
		then
			this:RemoveOldestMessage()
		end

		if isScrolledDown then
			this:ScrollToBottom()
		elseif not silently then
			this.NewUnreadMessage =
				true
		end

		if silently then
			if this.ChatsVisible == false then
				chatMessage:FadeOut(
					true
				)
			end
		else
			this:FadeInChats()

			lastChatActivity =
				tick()

			this.MessageCountChanged:fire(
				this.MessageCount
			)
		end

		if
			ySize
			> (MAX_UDIM_SIZE / 2)
		then
			this:OnResize()
		end
	end

	function this:AddSystemChatMessage(
		chattedMessage,
		silently
	)
		local chatMessage =
			CreateSystemChatMessage(
				this.Settings,
				chattedMessage
			)

		this:PushMessageIntoQueue(
			chatMessage,
			silently
		)
	end

	local function checkEnum(
		enumItems,
		value
	)
		for _, enum in pairs(
			enumItems
			) do
			if enum.Value == value then
				return enum
			end
		end

		return nil
	end

	local function shallowCopy(
		tableToCopy
	)
		local newTable = {}

		for key, value in pairs(
			tableToCopy
			) do
			newTable[key] = value
		end

		return newTable
	end

	function this:AddDeveloperSystemChatMessage(
		informationTable
	)
		local settings =
			shallowCopy(
				this.Settings
			)

		if
			informationTable["Text"]
			and type(
				informationTable["Text"]
			) == "string"
		then
			if
				informationTable["Color"]
				and pcall(
					function()
						Color3.new(
							informationTable["Color"].r,
							informationTable["Color"].g,
							informationTable["Color"].b
						)
					end
				)
			then
				settings.DefaultMessageTextColor =
					informationTable["Color"]
			end

			if informationTable["Font"] then
				local success,
					value =
					pcall(
						function()
							return checkEnum(
								Enum.Font:GetEnumItems(),
								informationTable["Font"].Value
							)
						end
					)

				if
					success
					and value ~= nil
				then
					settings.Font =
						value
				end
			end

			if informationTable["FontSize"] then
				local success,
					value =
					pcall(
						function()
							return checkEnum(
								Enum.FontSize:GetEnumItems(),
								informationTable["FontSize"].Value
							)
						end
					)

				if
					success
					and value ~= nil
				then
					settings.FontSize =
						value
				end
			end

			local chatMessage =
				CreateSystemChatMessage(
					settings,
					informationTable["Text"]
				)

			this:PushMessageIntoQueue(
				chatMessage,
				false
			)
		end
	end

	function this:AddChatMessage(
		playerChatType,
		sendingPlayer,
		chattedMessage,
		receivingPlayer,
		silently
	)
		local fixedChattedMessage =
			Util.FilterUnprintableCharacters(
				chattedMessage
			)

		if
			this:FilterMessage(
				playerChatType,
				sendingPlayer,
				fixedChattedMessage,
				receivingPlayer
			)
		then
			local chatMessage =
				CreatePlayerChatMessage(
					this.Settings,
					playerChatType,
					sendingPlayer,
					fixedChattedMessage,
					receivingPlayer
				)

			this:PushMessageIntoQueue(
				chatMessage,
				silently
			)
		end
	end

	function this:RemoveOldestMessage()
		local oldestChat =
			this.Chats[1]

		if oldestChat then
			return this:RemoveChatMessage(
				oldestChat
			)
		end
	end

	function this:RemoveChatMessage(
		chatMessage
	)
		if chatMessage then
			for index, message in pairs(
				this.Chats
				) do
				if chatMessage == message then
					local guiObj =
						chatMessage:GetGui()

					if guiObj then
						local ySize =
							guiObj.Size.Y.Offset

						this.ScrollingFrame.CanvasSize =
							this.ScrollingFrame.CanvasSize
						- UDim2.new(
							0,
							0,
							0,
							ySize
						)

						this:SetCanvasPosition(
							this.ScrollingFrame.CanvasPosition
						)

						guiObj.Parent = nil
					end

					message:Destroy()

					return table.remove(
						this.Chats,
						index
					)
				end
			end
		end
	end

	function this:IsScrolledDown()
		if this.ScrollingFrame then
			local yCanvasSize =
				this.ScrollingFrame.CanvasSize.Y.Offset

			local yContainerSize =
				this.ScrollingFrame.AbsoluteWindowSize.Y

			local yScrolledPosition =
				this.ScrollingFrame.CanvasPosition.Y

			return
				yCanvasSize
				< yContainerSize
				or
				yCanvasSize
			- yScrolledPosition
				<= yContainerSize + 5
		end

		return false
	end

	function this:GetMessageCount()
		return this.MessageCount
	end

	function this:CalculateVisibility()
		return
			this.WidgetVisible
			and (
				chatCoreGuiEnabled
				or NON_CORESCRIPT_MODE
			)
	end

	function this:ToggleVisibility(
		visible
	)
		this.WidgetVisible =
			visible

		if this.ChatContainer then
			this.ChatContainer.Visible =
				this:CalculateVisibility()
		end
	end

	function this:CoreGuiChanged(
		coreGuiType,
		enabled
	)
		if
			coreGuiType
			== Enum.CoreGuiType.Chat
			or coreGuiType
			== Enum.CoreGuiType.All
		then
			chatCoreGuiEnabled =
				enabled

			if this.ChatContainer then
				this.ChatContainer.Visible =
					this:CalculateVisibility()
			end
		end
	end

	function this:AddWelcomeMessage(
		chattedMessage
	)
		-- The welcome message is a real system chat message.
		-- It is inserted into the same MessageContainer as every
		-- other chat entry, so it gets the exact same sizing,
		-- wrapping and vertical padding as normal messages.
		local chatMessage =
			CreateSystemChatMessage(
				this.Settings,
				chattedMessage
			)

		-- Keep the welcome message from increasing the public
		-- message counter or creating an unread-message state.
		this:PushMessageIntoQueue(
			chatMessage,
			true
		)
	end

	local function CreateChatWindow()
		local container =
			Util.Create"TextButton"
		{
			Name = "ChatWindowContainer";

			Size =
				UDim2.new(
					0.3,
					0,
					0.25,
					-22
				);

			Position =
				UDim2.new(
					0,
					0,
					0,
					2
				);

			ZIndex = 1;

			BackgroundColor3 =
				Color3.fromRGB(
					0,
					0,
					0
				);

			BackgroundTransparency =
				0.6;

			BorderSizePixel = 0;
			Text = "";

			SelectionImageObject =
				emptySelectionImage;
		}

		local scrollingFrame =
			Util.Create"ScrollingFrame"
		{
			Name = "ChatWindow";

			-- Desktop keeps the original legacy viewport.
			-- Phone/tablet are changed to a 2 px inset below.
			Size =
				UDim2.new(
					1,
					-4 - 10,
					1,
					-20
				);

			CanvasSize =
				UDim2.new(
					1,
					-4 - 10,
					0,
					0
				);

			Position =
				UDim2.new(
					0,
					10,
					0,
					10
				);

			ZIndex = 1;

			BackgroundColor3 =
				Color3.new(
					0,
					0,
					0
				);

			BackgroundTransparency = 1;

			BottomImage =
				"rbxasset://textures/ui/scroll-bottom.png";

			MidImage =
				"rbxasset://textures/ui/scroll-middle.png";

			TopImage =
				"rbxasset://textures/ui/scroll-top.png";

			ScrollBarThickness = 0;
			BorderSizePixel = 0;
			ScrollingEnabled = false;
			Parent = container;
		}

		local messageContainer =
			Util.Create"Frame"
		{
			Name = "MessageContainer";

			Size =
				UDim2.new(
					1,
					-SCROLLBAR_THICKNESS - 1,
					0,
					0
				);

			Position =
				UDim2.new(
					0,
					0,
					0,
					0
				);

			ZIndex = 1;

			BackgroundColor3 =
				Color3.new(
					0,
					0,
					0
				);

			BackgroundTransparency = 1;
			Parent = scrollingFrame;
		}

		local function OnChatWindowResize(
			prop
		)
			if prop == "AbsoluteSize" then
				messageContainer.Position =
					UDim2.new(
						0,
						0,
						0,
						0
					)
			end

			if prop == "CanvasPosition" then
				if this.ScrollingFrame then
					if this:IsScrolledDown() then
						this.NewUnreadMessage =
							false
					end
				end
			end
		end

		container.Changed:connect(
			function(prop)
				if prop == "AbsoluteSize" then
					this:OnResize()
				end
			end
		)

		local function SetScrollingFrameLayout(
			isPhone,
			isTablet
		)
			if isPhone or isTablet then
				-- Phone/tablet: the scrolling viewport fills the
				-- ChatWindow with exactly 2 px on every side.
				scrollingFrame.Position =
					UDim2.new(
						0,
						10,
						0,
						2
					);

				scrollingFrame.Size =
					UDim2.new(
						1,
						-12,
						1,
						-4
					);

				scrollingFrame.CanvasSize =
					UDim2.new(
						1,
						-4,
						0,
						this.MessageContainer
						and this.MessageContainer.Size.Y.Offset
						or 0
					)
			else
				-- Desktop: preserve the existing layout.
				scrollingFrame.Position =
					UDim2.new(
						0,
						10,
						0,
						10
					)

				scrollingFrame.Size =
					UDim2.new(
						1,
						-4 - 10,
						1,
						-20
					)

				scrollingFrame.CanvasSize =
					UDim2.new(
						1,
						-4 - 10,
						0,
						this.MessageContainer
						and this.MessageContainer.Size.Y.Offset
						or 0
					)
			end
		end

		local function RobloxClientScreenSizeChanged(
			newSize
		)
			if not container then
				return
			end

			local isTouchDevice =
				Util.IsTouchDevice()

			-- Match the ChatBar exactly: mobile/tablet mode is
			-- selected from the screen width, not the shortest side.
			local isPhone =
				isTouchDevice
				and newSize.X
				<= PHONE_SCREEN_WIDTH

			local isTablet =
				isTouchDevice
				and newSize.X
				<= TABLET_SCREEN_WIDTH

			SetScrollingFrameLayout(
				isPhone,
				isTablet
			)

			if InputService.VREnabled then

				container.Size =
					UDim2.new(
						1,
						0,
						1,
						0
					)

			elseif isPhone then

				container.Size =
					UDim2.new(
						PHONE_CHAT_WINDOW_WIDTH,
						0,
						PHONE_CHAT_WINDOW_HEIGHT,
						0
					)

			elseif isTablet then

				container.Size =
					UDim2.new(
						TABLET_CHAT_WINDOW_WIDTH,
						0,
						TABLET_CHAT_WINDOW_HEIGHT,
						0
					)

			elseif
				newSize.X
				<= TABLET_SCREEN_WIDTH
			then

				container.Size =
					UDim2.new(
						0.4,
						0,
						0.3,
						-22
					)

			else

				container.Size =
					UDim2.new(
						0.3,
						0,
						0.25,
						-22
					)
			end
		end

		GuiRoot.Changed:connect(
			function(prop)
				if
					prop == "AbsoluteSize"
					and not chatRepositioned
				then
					RobloxClientScreenSizeChanged(
						GuiRoot.AbsoluteSize
					)
				end
			end
		)

		RobloxClientScreenSizeChanged(
			GuiRoot.AbsoluteSize
		)

		messageContainer.Changed:connect(
			OnChatWindowResize
		)

		scrollingFrame.Changed:connect(
			OnChatWindowResize
		)

		this.ChatContainer =
			container

		this.ScrollingFrame =
			scrollingFrame

		this.MessageContainer =
			messageContainer


		this.ChatContainer.Parent =
			GuiRoot

		local dontFadeOutOnMouseLeave =
			false

		if Util.IsTouchDevice() then
			local touchCount = 0

			this.InputBeganConn =
				Chat2017Track(InputService.InputBegan:connect(
					function(inputObject)
						if
							inputObject.UserInputType
							== Enum.UserInputType.Touch
							and inputObject.UserInputState
							== Enum.UserInputState.Begin
						then
							if PointInChatWindow(
								Vector2.new(
									inputObject.Position.X,
									inputObject.Position.Y
								)
								) then
								touchCount =
								touchCount + 1

								dontFadeOutOnMouseLeave =
								true
							end
						end
					end
				))

			this.InputEndedConn =
				Chat2017Track(InputService.InputEnded:connect(
					function(inputObject)
						if
							inputObject.UserInputType
							== Enum.UserInputType.Touch
							and inputObject.UserInputState
							== Enum.UserInputState.End
						then
							local endedCount =
							touchCount

							wait(2)

							if
								touchCount
								== endedCount
							then
								dontFadeOutOnMouseLeave =
								false
							end
						end
					end
				))

			spawn(
				function()
					while Chat2017State.Alive do
						wait()

						local now =
							tick()

						if
							this.BackgroundVisible
							and now
							>
							lastChatActivity
								+ MESSAGES_FADE_OUT_TIME
						then
							if
								not dontFadeOutOnMouseLeave
							then
								this:FadeOut(
									1.5
								)
							end

						elseif
							this.ChatsVisible
							and now
							>
							lastChatActivity
								+ MESSAGES_FADE_OUT_TIME
						then
							this:FadeOutChats()
						end
					end
				end
			)
		else
			this.LastMousePosition =
				Vector2.new()

			this.MouseEnterFrameConn =
				this.ChatContainer.MouseEnter:connect(
					function()
						lastEnterTime =
						tick()

						if
							this.BackgroundTweener
							and not this.BackgroundTweener:IsFinished()
							and not this.BackgroundVisible
						then
							this:FadeIn()
						end
					end
				)

			this.MouseMoveConn =
				Chat2017Track(InputService.InputChanged:connect(
					function(inputObject)
						if
							inputObject.UserInputType
							== Enum.UserInputType.MouseMovement
						then
							lastMoveTime =
							tick()

							this.LastMousePosition =
							Vector2.new(
								inputObject.Position.X,
								inputObject.Position.Y
							)

							if
								this.BackgroundTweener
								and this.BackgroundTweener:GetPercentComplete()
								< 0.5
								and this.BackgroundVisible
							then
								if
									not dontFadeOutOnMouseLeave
								then
									this:FadeOut()
								end
							end
						end
					end
				))

			local clickCount = 0

			this.InputBeganConn =
				Chat2017Track(InputService.InputBegan:connect(
					function(inputObject)
						if
							inputObject.UserInputType
							== Enum.UserInputType.MouseButton1
							and inputObject.UserInputState
							== Enum.UserInputState.Begin
						then
							if PointInChatWindow(
								Vector2.new(
									inputObject.Position.X,
									inputObject.Position.Y
								)
								) then
								clickCount =
								clickCount + 1

								dontFadeOutOnMouseLeave =
								true
							end
						end
					end
				))

			this.InputEndedConn =
				Chat2017Track(InputService.InputEnded:connect(
					function(inputObject)
						if
							inputObject.UserInputType
							== Enum.UserInputType.MouseButton1
							and inputObject.UserInputState
							== Enum.UserInputState.End
						then
							local nowCount =
							clickCount

							wait(1.3)

							if
								nowCount
								== clickCount
							then
								dontFadeOutOnMouseLeave =
								false
							end
						end
					end
				))

			this.MouseLeaveFrameConn =
				this.ChatContainer.MouseLeave:connect(
					function()
						lastLeaveTime =
						tick()

						if
							this.BackgroundTweener
							and not this.BackgroundTweener:IsFinished()
							and this.BackgroundVisible
						then
							if
								not dontFadeOutOnMouseLeave
							then
								this:FadeOut()
							end
						end
					end
				)

			spawn(
				function()
					while Chat2017State.Alive do
						wait()

						local now =
							tick()

						if this:IsHovering() then
							if
								now - lastMoveTime
								> 1.3
								and not this.BackgroundVisible
							then
								this:FadeIn()
							end
						else
							if
								this.BackgroundVisible
								and now
								>
								lastChatActivity
									+ MESSAGES_FADE_OUT_TIME
							then
								if
									not dontFadeOutOnMouseLeave
								then
									this:FadeOut(
										1.5
									)
								end

							elseif
								this.ChatsVisible
								and now
								>
								lastChatActivity
									+ MESSAGES_FADE_OUT_TIME
							then
								this:FadeOutChats()
							end
						end
					end
				end
			)
		end
	end

	CreateChatWindow()

	return this
end

local function CreateChat()
	local this = {}

	this.Settings =
		{
			GlobalTextColor =
			Color3.new(
				112/255,
				110/255,
				106/255
			);

			WhisperTextColor =
			Color3.new(
				77/255,
				139/255,
				255/255
			);

			TeamTextColor =
			Color3.new(
				230/255,
				207/255,
				0
			);

			DefaultMessageTextColor =
			Color3.new(
				255/255,
				255/255,
				243/255
			);

			AdminTextColor =
			Color3.new(
				1,
				215/255,
				0
			);

			TextStrokeTransparency = 0.75;

			TextStrokeColor =
			Color3.new(
				34/255,
				34/255,
				34/255
			);

			Font =
			Enum.Font.SourceSansBold;

			SmallScreenFontSize =
			Enum.FontSize.Size14;

			FontSize =
			Enum.FontSize.Size18;

			MaxWindowChatMessages = 50;
			MaxCharactersInMessage = 140;
		}

	this.CurrentWindowMessageCountChanged =
		nil

	this.VisibilityStateChanged =
		Util.Signal()

	this.ChatBarFocusChanged =
		Util.Signal()

	this.Visible = false

	function this:CoreGuiChanged(
		coreGuiType,
		enabled
	)
		if
			coreGuiType
			== Enum.CoreGuiType.Chat
			or coreGuiType
			== Enum.CoreGuiType.All
		then
			if enabled then
				-- chat box: it was open before the chat was switched off
				if this.Chat2017ShowAgain then
					this.Chat2017ShowAgain = nil

					task.defer(
						function()
							if Chat2017State.Alive then
								this:SetVisible(true)
							end
						end
					)
				end

				this.SpecialKeyPressedConn =
					Util.DisconnectEvent(
						this.SpecialKeyPressedConn
					)

				this.SpecialKeyPressedConn =
					Chat2017Track(InputService.InputBegan:Connect(
						function(key)
							if Util.IsTouchDevice() then
								return
							end

							if
								key.KeyCode
								~= Enum.KeyCode.Slash
							then
								return
							end

							local focusedTextBox =
							InputService:GetFocusedTextBox()

							if focusedTextBox then
								return
							end

							if not this.Visible then
								this:SetVisible(true)
							end

							task.defer(
								function()
									if this.ChatBarWidget then
										this.ChatBarWidget.MobileFocusOnly =
										false

										this.ChatBarWidget:FocusChatBar()
									end
								end
							)
						end
					))
			else
				this.SpecialKeyPressedConn =
					Util.DisconnectEvent(
						this.SpecialKeyPressedConn
					)

				if this.ChatBarWidget then
					this.ChatBarWidget.MobileFocusOnly =
						false

					this.ChatBarWidget:RemoveFocus()

					this.ChatBarWidget:ToggleVisibility(
						false
					)
				end

				if this.ChatWindowWidget then
					this.ChatWindowWidget:ToggleVisibility(
						false
					)

					this.ChatWindowWidget:FadeOut(
						0
					)
				end

				-- chat box: remember that the window was open, to open it again when the chat is switched on
				if this.Visible then
					this.Chat2017ShowAgain = true
				end

				this.Visible = false
			end

			if this.MobileChatButton then
				if enabled then
					this.MobileChatButton.Parent =
						GuiRoot

					this.MobileChatButton.Visible =
						true
				else
					this.MobileChatButton.Parent =
						nil
				end
			end
		end

		if this.ChatWindowWidget then
			this.ChatWindowWidget:CoreGuiChanged(
				coreGuiType,
				enabled
			)
		end

		if this.ChatBarWidget then
			this.ChatBarWidget:CoreGuiChanged(
				coreGuiType,
				enabled
			)
		end
	end

	function this:OnPlayerChatted(
		playerChatType,
		sendingPlayer,
		chattedMessage,
		receivingPlayer
	)
		if this.ChatWindowWidget then
			local isDebugCommand = false

			pcall(
				function()
					if
						sendingPlayer
						== PlayersService.LocalPlayer
					then
					end
				end
			)

			if not (
				this:IsPlayerBlocked(
					sendingPlayer
				)
					or this:IsPlayerMuted(
						sendingPlayer
					)
					or isDebugCommand
				) then
				this.ChatWindowWidget:AddChatMessage(
					playerChatType,
					sendingPlayer,
					chattedMessage,
					receivingPlayer
				)
			end
		end
	end

	function this:OnPlayerAdded(
		newPlayer
	)
		if newPlayer then
			spawn(
				function()
					Util.IsPlayerAdminAsync(
						newPlayer
					)
				end
			)
		end
	end

	function this:IsPlayerBlocked(
		player
	)
		return false
	end

	function this:BlockPlayerAsync(
		playerToBlock
	)
	end

	function this:UnblockPlayerAsync(
		playerToUnblock
	)
	end

	function this:IsPlayerMuted(
		player
	)
		return false
	end

	function this:MutePlayer(
		playerToMute
	)
		if
			playerToMute
			and playerToMute
			~= Player
		then
			if playerToMute.UserId > 0 then
				if
					not this:IsPlayerMuted(
						playerToMute
					)
				then
					if blockingUtility then
						blockingUtility:MutePlayer(
							playerToMute
						)

						this.ChatWindowWidget:AddSystemChatMessage(
							playerToMute.Name
								.. " is now muted."
						)
					end
				else
					this.ChatWindowWidget:AddSystemChatMessage(
						playerToMute.Name
							.. " is already muted."
					)
				end
			else
				this.ChatWindowWidget:AddSystemChatMessage(
					"You cannot mute guests."
				)
			end
		else
			this.ChatWindowWidget:AddSystemChatMessage(
				"You cannot mute yourself."
			)
		end
	end

	function this:UnmutePlayer(
		playerToUnmute
	)
		if playerToUnmute then
			if
				this:IsPlayerMuted(
					playerToUnmute
				)
			then
				if blockingUtility then
					blockingUtility:UnmutePlayer(
						playerToUnmute
					)

					this.ChatWindowWidget:AddSystemChatMessage(
						playerToUnmute.Name
							.. " is no longer muted."
					)
				end
			else
				this.ChatWindowWidget:AddSystemChatMessage(
					playerToUnmute.Name
						.. " is not muted."
				)
			end
		end
	end

	function this:CreateTouchDeviceChatButton()
		return
			Util.Create"ImageButton"
		{
			Name = "TouchDeviceChatButton";
			Size =
				UDim2.new(
					0,
					128,
					0,
					32
				);
			Position =
				UDim2.new(
					0,
					88,
					0,
					0
				);
			BackgroundTransparency = 1.0;
			Image =
				"http://www.roblox.com/asset/?id=97078724";
		}
	end

	function this:PrintWelcome()
		if this.ChatWindowWidget then
			-- It is a normal system chat message, so TextWrapped
			-- handles the line break naturally on small screens.
			this.ChatWindowWidget:AddWelcomeMessage(
				"Please chat '/?' or '/help' for a list of chat commands."
			)
		end
	end

	local doOnceVRWelcome = false

	function this:PrintVRWelcome()
		if
			this.ChatWindowWidget
			and not doOnceVRWelcome
		then
			if InputService.VREnabled then
				this.ChatWindowWidget:AddSystemChatMessage(
					"Press here to chat",
					true
				)

				doOnceVRWelcome = true
			end
		end
	end

	function this:PrintHelp()
		if this.ChatWindowWidget then
			this.ChatWindowWidget:AddSystemChatMessage(
				"Help Menu"
			)

			this.ChatWindowWidget:AddSystemChatMessage(
				"Chat Commands:"
			)

			this.ChatWindowWidget:AddSystemChatMessage(
				"/w [PlayerName] or /whisper [PlayerName] - Whisper Chat"
			)

			this.ChatWindowWidget:AddSystemChatMessage(
				"/t or /team - Team Chat"
			)

			this.ChatWindowWidget:AddSystemChatMessage(
				"/a or /all - All Chat"
			)

			this.ChatWindowWidget:AddSystemChatMessage(
				"/block [PlayerName] - Block communications from Target Player"
			)

			this.ChatWindowWidget:AddSystemChatMessage(
				"/unblock [PlayerName] - Restore communications from Target Player"
			)

			this.ChatWindowWidget:AddSystemChatMessage(
				"/mute [PlayerName] - Mute in-game communications from Target Player"
			)

			this.ChatWindowWidget:AddSystemChatMessage(
				"/unmute [PlayerName] - Restore in-game communications from Target Player"
			)
		end
	end

	local focusCount = 0

	function this:CreateGUI()
		if FORCE_CHAT_GUI or true then
			if NON_CORESCRIPT_MODE then
				local chatGui =
					Instance.new(
						"ScreenGui"
					)

				chatGui.Name =
					"NewRobloxGui"

				chatGui.Parent =
					Player:WaitForChild(
						"PlayerGui"
					)

				GuiRoot.Parent =
					chatGui
			end

			this.ChatWindowWidget =
				CreateChatWindowWidget(
					this.Settings
				)

			this.ChatBarWidget =
				CreateChatBarWidget(
					this.Settings
				)

			this.CurrentWindowMessageCountChanged =
				this.ChatWindowWidget.MessageCountChanged

			this.ChatWindowWidget.FadeInSignal:connect(
				function()
					this.ChatBarWidget:FadeIn()
				end
			)

			this.ChatWindowWidget.FadeOutSignal:connect(
				function()
					this.ChatBarWidget:FadeOut()
				end
			)

			this.ChatWindowWidget:FadeOut(
				0
			)

			this.ChatBarWidget.ChatBarGainedFocusEvent:connect(
				function()
					focusCount =
						focusCount + 1

					if not Util.IsTouchDevice() then
						this.ChatWindowWidget:FadeIn(
							0.25
						)

						this.ChatWindowWidget:SetFadeLock(
							true
						)
					end

					if not this.SuppressMobileFocusChangedSignal then
						this.ChatBarFocusChanged:fire(
							true
						)
					end
				end
			)

			this.ChatBarWidget.ChatBarLostFocusEvent:connect(
				function()
					local focusNow =
						focusCount

					if Util.IsTouchDevice() then
						delay(
							2,
							function()
								if
									focusNow
									== focusCount
								then
									this.ChatWindowWidget:SetFadeLock(
										false
									)
								end
							end
						)
					else
						this.ChatWindowWidget:SetFadeLock(
							false
						)
					end

					this.ChatBarFocusChanged:fire(
						false
					)
				end
			)

			this.ChatBarWidget.ChatBarFloodEvent:connect(
				function()
					if this.ChatWindowWidget then
						this.ChatWindowWidget:AddSystemChatMessage(
							"Wait before sending another message."
						)
					end
				end
			)

			this.ChatBarWidget.ChatErrorEvent:connect(
				function(msg)
					if msg then
						this.ChatWindowWidget:AddSystemChatMessage(
							msg
						)
					end
				end
			)

			this.ChatBarWidget.ChatCommandEvent:connect(
				function(
					success,
					actionType,
					capture
				)
					if actionType == "Help" then
						this:PrintHelp()

					elseif actionType == "Block" then
						local blockPlayerName =
							capture
							and tostring(capture)
							or ""

						local playerToBlock =
							Util.GetPlayerByName(
								blockPlayerName
							)

						if playerToBlock then
							spawn(
								function()
									this:BlockPlayerAsync(
										playerToBlock
									)
								end
							)
						else
							this.ChatWindowWidget:AddSystemChatMessage(
								"Cannot block "
									.. blockPlayerName
									.. " because they are not in the game."
							)
						end

					elseif actionType == "Unblock" then
						local unblockPlayerName =
							capture
							and tostring(capture)
							or ""

						local playerToBlock =
							Util.GetPlayerByName(
								unblockPlayerName
							)

						if playerToBlock then
							spawn(
								function()
									this:UnblockPlayerAsync(
										playerToBlock
									)
								end
							)
						else
							this.ChatWindowWidget:AddSystemChatMessage(
								"Cannot unblock "
									.. unblockPlayerName
									.. " because they are not in the game."
							)
						end

					elseif actionType == "Mute" then
						local mutePlayerName =
							capture
							and tostring(capture)
							or ""

						local playerToMute =
							Util.GetPlayerByName(
								mutePlayerName
							)

						if playerToMute then
							this:MutePlayer(
								playerToMute
							)
						else
							this.ChatWindowWidget:AddSystemChatMessage(
								"Cannot mute "
									.. mutePlayerName
									.. " because they are not in the game."
							)
						end

					elseif actionType == "Unmute" then
						local unmutePlayerName =
							capture
							and tostring(capture)
							or ""

						local playerToMute =
							Util.GetPlayerByName(
								unmutePlayerName
							)

						if playerToMute then
							this:UnmutePlayer(
								playerToMute
							)
						else
							this.ChatWindowWidget:AddSystemChatMessage(
								"Cannot unmute "
									.. unmutePlayerName
									.. " because they are not in the game."
							)
						end

					elseif actionType == "Whisper" then
						if success == false then
							local playerName =
								capture
								and tostring(capture)
								or "Unknown"

							this.ChatWindowWidget:AddSystemChatMessage(
								"Unable to Send a Whisper to Player: "
									.. playerName
							)
						end

					elseif actionType == "Unknown" then
						if success == false then
							local commandText =
								capture
								and tostring(capture)
								or "Unknown"

							this.ChatWindowWidget:AddSystemChatMessage(
								"Invalid Slash Command: "
									.. commandText
							)
						end
					end
				end
			)

			if not NON_CORESCRIPT_MODE then
				local function onVREnabled()
					if InputService.VREnabled then
						this.Settings.TextStrokeTransparency =
							1

						this:PrintVRWelcome()

						local NewRobloxGui =
							Chat2017Host

						if not NewRobloxGui then
							return
						end

						local Modules =
							NewRobloxGui:FindFirstChild(
								"Modules"
							)

						local VR =
							Modules
							and Modules:FindFirstChild(
								"VR"
							)

						local Panel3DModule =
							VR
							and VR:FindFirstChild(
								"Panel3D"
							)

						if not Panel3DModule then
							return
						end

						local Success,
							Panel3D =
							pcall(
								require,
								Panel3DModule
							)

						if not Success
							or not Panel3D
						then
							return
						end

						local panel =
							Panel3D.Get(
								"Chat"
							)

						if not panel then
							return
						end

						panel:LinkTo(
							"Keyboard"
						)

						panel:SetType(
							Panel3D.Type.Fixed
						)

						panel:ResizePixels(
							300,
							125
						)

						GuiRoot.Parent =
							panel:GetGUI()

						if
							this.ChatWindowWidget
							and this.ChatWindowWidget.ChatContainer
						then
							this.ChatWindowWidget.ChatContainer.MouseButton1Click:connect(
								function()
									if this.ChatBarWidget then
										if this.ChatBarWidget:WasFocused() then
											this.ChatBarWidget:RemoveFocus()
										else
											this:FocusChatBar()
										end
									end
								end
							)
						end

						function panel:CalculateTransparency()
							return 0
						end
					else
						this.Settings.TextStrokeTransparency =
							0.75

						local NewRobloxGui =
							Chat2017Host

						if NewRobloxGui then
							GuiRoot.Parent =
								NewRobloxGui
						end
					end
				end

				onVREnabled()

				Chat2017Track(InputService.Changed:connect(
					function(prop)
						if prop == "VREnabled" then
							onVREnabled()
						end
					end
				))
			end
		end
	end

	local toggleCount = 0

	local function SetVisbility(
		newVisibility
	)
		this.Visible =
			newVisibility

		if this.ChatWindowWidget then
			this.ChatWindowWidget:ToggleVisibility(
				this.Visible
			)

			if this.Visible then
				if Util.IsTouchDevice() then
					this.ChatWindowWidget:FadeIn(
						0.25
					)
				else
					toggleCount =
						toggleCount + 1

					local thisToggle =
						toggleCount

					local thisFocusCount =
						focusCount

					this.ChatWindowWidget:FadeIn()

					this.ChatWindowWidget:SetFadeLock(
						true
					)

					delay(
						5,
						function()
							if
								thisToggle
								== toggleCount
								and thisFocusCount
								== focusCount
							then
								this.ChatWindowWidget:SetFadeLock(
									false
								)
							end
						end
					)
				end
			end
		end

		if this.ChatBarWidget then
			this.ChatBarWidget.MobileFocusOnly = false

			if this.Visible then
				this.ChatBarWidget:ShowChatBar()
			else
				this.ChatBarWidget:ToggleVisibility(false)
			end

			if this.Visible then
				this.ChatBarWidget:FadeIn()
			end

			if
				InputService.VREnabled
				and not this.Visible
			then
				this.ChatBarWidget:RemoveFocus()
			end
		end

		if
			IsPlayerDropDownEnabled
			and playerDropDown
		then
			if not this.Visible then
				playerDropDown:Hide()
			end
		end

		if InputService.VREnabled then
			local NewRobloxGui =
				Chat2017Host

			if not NewRobloxGui then
				return
			end

			local Modules =
				NewRobloxGui:FindFirstChild(
					"Modules"
				)

			local VR =
				Modules
				and Modules:FindFirstChild(
					"VR"
				)

			local Panel3DModule =
				VR
				and VR:FindFirstChild(
					"Panel3D"
				)

			if not Panel3DModule then
				return
			end

			local Success,
				Panel3D =
				pcall(
					require,
					Panel3DModule
				)

			if
				not Success
				or not Panel3D
			then
				return
			end

			local panel =
				Panel3D.Get(
					"Chat"
				)

			if not panel then
				return
			end

			if this.Visible then
				local headLook =
					Panel3D.GetHeadLookXZ(
						true
					)

				panel.localCF =
					headLook
					* CFrame.Angles(
						math.rad(5),
						0,
						0
					)
					* CFrame.new(
						0,
						0,
						6.5
					)

				panel:ForceShowUntilLookedAt()
			else
				panel:SetVisible(
					this.Visible
				)
			end
		end

		this.VisibilityStateChanged:fire(
			this.Visible
		)
	end

	function this:ToggleVisibility()
		-- This is the actual chat-window visibility button on ALL devices.
		-- It must never focus the mobile ChatBar by itself.
		SetVisbility(
			not this.Visible
		)
	end

	function this:FocusChatBarFromMobileEllipsis()
		-- The mobile "..." button is a full switch to the keyboard-only chat input.
		-- If the ChatWindow is open, close it first so the two states never overlap.
		if Util.IsTouchDevice() and this.ChatBarWidget then
			if this.Visible then
				SetVisbility(false)
			end

			this.ChatBarWidget.MobileFocusOnly =
				true

			this.ChatBarWidget:FocusChatBar()
		end
	end

	function this:SetVisible(
		visible
	)
		-- Normal Chat button path.
		if this.ChatBarWidget then
			this.ChatBarWidget.MobileFocusOnly =
				false
		end

		SetVisbility(
			visible
		)
	end

	function this:FocusChatBar()
		if this.ChatBarWidget then
			if Util.IsTouchDevice() then
				-- If the window is not visible, this is the
				-- focus-only path used by "...".
				if not this.Visible then
					this.ChatBarWidget.MobileFocusOnly =
						true
				end

				this.ChatBarWidget:FocusChatBar()
			elseif this.Visible then
				this.ChatBarWidget.MobileFocusOnly =
					false

				this.ChatBarWidget:FocusChatBar()
			end
		end
	end

	function this:IsFocused(
		useWasFocused
	)
		if not this.ChatBarWidget then
			return false
		end

		return
			this.ChatBarWidget:IsFocused()
			or (
				useWasFocused
				and this.ChatBarWidget:WasFocused()
			)
	end

	function this:GetCurrentWindowMessageCount()
		if this.ChatWindowWidget then
			return
				this.ChatWindowWidget:GetMessageCount()
		end

		return 0
	end

	function this:TopbarEnabledChanged(
		enabled
	)
		topbarEnabled =
			enabled
	end

	function this:Initialize()
		if not NON_CORESCRIPT_MODE then
			local function isUDim2Value(
				value
			)
				local success,
					newValue =
					pcall(
						function()
							return UDim2.new(
								value.X.Scale,
								value.X.Offset,
								value.Y.Scale,
								value.Y.Offset
							)
						end
					)

				return
					success
					and newValue
					or nil
			end

			local function isBubbleChatOn()
				return
					not PlayersService.ClassicChat
					and PlayersService.BubbleChat
			end

			if allowMoveChat then
			end
		end

		this:OnPlayerAdded(
			Player
		)

		Chat2017Track(PlayersService.ChildAdded:connect(
			function(child)
				if child:IsA("Player") then
					this:OnPlayerAdded(
						child
					)
				end
			end
		))

		this:CreateGUI()

		-- RECEIVE CHAT
		Chat2017Track(RBXGeneral.MessageReceived:Connect(
			function(msg)
				if not msg.TextSource then
					-- chat box: a message from the game itself (DisplaySystemMessage) is shown as a system line
					if
						msg.Status == Enum.TextChatMessageStatus.Success
						and type(msg.Text) == "string"
						and msg.Text ~= ""
						and this.ChatWindowWidget
					then
						this.ChatWindowWidget:AddSystemChatMessage(Chat2017PlainText(msg.Text, true))
					end

					return
				end

				if
					msg.Status
					~= Enum.TextChatMessageStatus.Success
				then
					return
				end

				local plr =
					PlayersService:GetPlayerByUserId(
						msg.TextSource.UserId
					)

				if not plr then
					return
				end

				local skipLocal = false

				pcall(
					function()
						skipLocal =
							game.Lighting.LocalChatsAreUnfiltered.Value
					end
				)

				if
					skipLocal
					and plr
					== PlayersService.LocalPlayer
				then
					return
				end

				this:OnPlayerChatted(
					Enum.PlayerChatType.All,
					plr,
					Chat2017PlainText(msg.Text, false),
					nil
				)
			end
		))

		-- LOCAL UNFILTERED CHAT
		Chat2017Track(TextChatService.SendingMessage:Connect(
			function(msg)
				local isUnfiltered = false

				pcall(
					function()
						isUnfiltered =
							game.Lighting.LocalChatsAreUnfiltered.Value
					end
				)

				if
					isUnfiltered
					and msg.TextSource
				then
					local plr =
						PlayersService:GetPlayerByUserId(
							msg.TextSource.UserId
						)

					if
						plr
						== PlayersService.LocalPlayer
					then
						this:OnPlayerChatted(
							Enum.PlayerChatType.All,
							plr,
							msg.Text,
							nil
						)
					end
				end
			end
		))

		this:CoreGuiChanged(
			Enum.CoreGuiType.Chat,
			true
		)

		this.CoreGuiChangedConn =
			Util.DisconnectEvent(
				this.CoreGuiChangedConn
			)

		pcall(
			function()
				this.CoreGuiChangedConn =
					Chat2017Track(StarterGui.CoreGuiChangedSignal:connect(
						function(
							coreGuiType,
							enabled
						)
							this:CoreGuiChanged(
								coreGuiType,
								enabled
							)
						end
					))
			end
		)

		if not NON_CORESCRIPT_MODE then
			this:PrintWelcome()
		end
	end

	return this
end

local moduleApiTable = {}

-- Main Entry Point
do
	local ChatInstance =
		CreateChat()

	ChatInstance:Initialize()

	function moduleApiTable:ToggleVisibility()
		ChatInstance:ToggleVisibility()
	end

	function moduleApiTable:SetVisible(
		visible
	)
		ChatInstance:SetVisible(
			visible
		)
	end

	function moduleApiTable:FocusChatBar()
		ChatInstance:FocusChatBar()
	end

	function moduleApiTable:FocusChatBarFromMobileEllipsis()
		ChatInstance:FocusChatBarFromMobileEllipsis()
	end

	function moduleApiTable:GetVisibility()
		return ChatInstance.Visible
	end

	function moduleApiTable:GetMessageCount()
		return
			ChatInstance:GetCurrentWindowMessageCount()
	end

	function moduleApiTable:TopbarEnabledChanged(
		...
	)
		return
			ChatInstance:TopbarEnabledChanged(
				...
			)
	end

	function moduleApiTable:IsFocused(
		useWasFocused
	)
		return
			ChatInstance:IsFocused(
				useWasFocused
			)
	end

	moduleApiTable.ChatBarFocusChanged =
		ChatInstance.ChatBarFocusChanged

	moduleApiTable.VisibilityStateChanged =
		ChatInstance.VisibilityStateChanged

	moduleApiTable.MessagesChanged =
		ChatInstance.CurrentWindowMessageCountChanged
end

return moduleApiTable

--==== the Chat module ends here ====--

end

--============================================================*
-- START IT
--============================================================*

local Started, Api = pcall(Chat2017Run)

if not Started or type(Api) ~= "table" then
	warn("[2017 chat] the chat box failed to start:", Api)

	Chat2017State.Alive = false

	for _, Connection in ipairs(Chat2017Connections) do
		pcall(function()
			Connection:Disconnect()
		end)
	end

	pcall(function()
		Chat2017Host:Destroy()
	end)

	Env.Chat2017Skipped = "error"
	return
end

local Chat = {
	Version = Env.Chat2017Version,
	Host = Chat2017Host,
}

local Call = function(Name, ...)
	if not Chat2017State.Alive then
		return nil
	end

	local Success, Result = pcall(Api[Name], Api, ...)

	if not Success then
		warn("[2017 chat] " .. Name .. " failed:", Result)

		return nil
	end

	return Result
end

Chat.Toggle = function()
	Call("ToggleVisibility")
end

Chat.SetVisible = function(Open)
	Call("SetVisible", Open and true or false)
end

Chat.GetVisible = function()
	return Call("GetVisibility") == true
end

Chat.FocusChatBar = function()
	Call("FocusChatBar")
end

-- Roblox's own chat window is kept off while this runs (and put back when it stops).

local ExperienceChat

local ExperienceChatWasEnabled

local ExperienceChatGuard

task.spawn(function()
	local Gui = CoreGui:WaitForChild("ExperienceChat", 15)

	if not Gui or not Chat2017State.Alive then
		return
	end

	ExperienceChat = Gui

	pcall(function()
		ExperienceChatWasEnabled = Gui.Enabled
		Gui.Enabled = false
	end)

	ExperienceChatGuard = Gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if Chat2017State.Alive and Gui.Enabled then
			Gui.Enabled = false
		end
	end)
end)

local Cleanup

Cleanup = function()
	if not Chat2017State.Alive then
		return
	end

	Chat2017State.Alive = false

	for _, Connection in ipairs(Chat2017Connections) do
		pcall(function()
			Connection:Disconnect()
		end)
	end

	table.clear(Chat2017Connections)

	if ExperienceChatGuard then
		pcall(function()
			ExperienceChatGuard:Disconnect()
		end)
	end

	if ExperienceChat and ExperienceChatWasEnabled ~= nil then
		pcall(function()
			ExperienceChat.Enabled = ExperienceChatWasEnabled
		end)
	end

	pcall(function()
		Chat2017Host:Destroy()
	end)

	if Env.Chat2017 == Chat then
		Env.Chat2017 = nil
	end

	if Env.Chat2017Cleanup == Cleanup then
		Env.Chat2017Cleanup = nil
	end
end

Env.Chat2017 = Chat

Env.Chat2017Cleanup = Cleanup

print("[2017 chat] chat box started (closed: the chat icon opens it)")

-- end of 2017_chat_box.lua
