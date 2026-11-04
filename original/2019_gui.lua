--[[
		___ _______ ________ ________ ________ ___ ___
		|\ \ |\ ___ \ |\ ____\|\ __ \|\ ____\ |\ \ / /|
		\ \ \ \ \ __/|\ \ \___|\ \ \|\ \ \ \___| \ \ \/ / /
		\ \ \ \ \ \_|/_\ \ \ __\ \ __ \ \ \ \ \ / /
		 \ \ \____\ \ \_|\ \ \ \|\ \ \ \ \ \ \ \____ \/ / /
		  \ \_______\ \_______\ \_______\ \__\ \__\ \_______\__/ / /
		   \|_______|\|_______|\|_______|\|__|\|__|\|_______|\____/ /

		> github.com/yeku/legacy

		>> a ROBLOX coregui changer that lets you use older designs

		[!] only supports 2012, 2013, 2014, 2015, 2016
		]]

if (not game:IsLoaded()) then

	game.Loaded:Wait()

end

-- Settings

local Developer = (isfile and (isfile("yeku.txt") and isfile("Legacy.rbxm")))

local Environment = (getgenv or function() return _G end)

local Settings = Environment().LegacySettings or ({
	Year = 2017,

	OldGraphics = false,

	HideDisplayName = true,

	SafeChat = true,

	OldConsole = true,

	OldBubbleChat = true,
})

-- Services

local Players = game:GetService("Players")

local CoreGui = game:GetService("CoreGui")

local StarterGui = game:GetService("StarterGui")

local Lighting = game:GetService("Lighting")

local TextChatService = game:GetService("TextChatService")

local UserInputService = game:GetService("UserInputService")

local MarketplaceService = game:GetService("MarketplaceService")

local RunService = game:GetService("RunService")

local TweenService = game:GetService("TweenService")

-- Variables

local RobloxGui = CoreGui:WaitForChild("RobloxGui", 30) or CoreGui:FindFirstChild("RobloxGui")

-- Mobile / some clients delay or omit ExperienceChat. Never hard-wait forever.
local ExperienceChat = CoreGui:FindFirstChild("ExperienceChat")
if not ExperienceChat then
	ExperienceChat = CoreGui:WaitForChild("ExperienceChat", 5)
end

local ChatBubbles = nil
if ExperienceChat then
	ChatBubbles = ExperienceChat:FindFirstChild("bubbleChat")
		or ExperienceChat:WaitForChild("bubbleChat", 3)
end

local IsTouchDevice = UserInputService.TouchEnabled

-- Types

-- export type Properties = { [string]: any } -- disabled for mobile executor compat

-- Functions

local Force = function(Object: Instance, Property: string, Value: any)

	if not Object then
		return
	end

	if (Object[Property] ~= Value) then
		Object[Property] = Value
	end

	Object:GetPropertyChangedSignal(Property):Connect(function()

		if (Object[Property] ~= Value) then
			Object[Property] = Value
		end

	end)

end

local Set = function(Object: Instance, Properties: Properties, Forced: boolean)

	if (not Object) then
		return
	end

	for Property, Value in next, Properties do

		local Success, Result = pcall(function()

			Object[Property] = Value

			if (Forced) then
				Force(Object, Property, Value)
			end

		end)

		if (not Success) then
			warn(`{Result} | {debug.traceback()}`)
		end

	end

end

local Create = function(ClassName: string, Properties: Properties, Forced: boolean, Parent: Instance?)

	local Object = Instance.new(ClassName)

	if (Parent) then
		Object.Parent = Parent
	end

	Set(Object, Properties, Forced)

	return Object

end

local Run = function(Bool: boolean, Callback: () -> ())

	if (Bool) then
		task.spawn(Callback)
	end

end

if ExperienceChat then
	pcall(function()
		ExperienceChat.Enabled = false
	end)
end

-- Module

local Suite = Environment().Suite or loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/yeku/forks/refs/heads/main/Scripts/RBXMSuite.luau"
))()

--============================================================*
-- CLASSIC ROBLOX LOADING GUI
-- 2017+ ONLY
--============================================================*

if Settings.Year >= 2017 then

	task.spawn(function()

		--====================================================*
		-- LOAD ROBLOXLOADINGGUI
		--====================================================*

		local Project

		local Success, Result =
			pcall(function()

				return Suite.launch(
					"rbxassetid://129525824550169",
					{
						runscripts = false,
						deferred = true,
						nocache = false,
						nocirculardeps = true,
						debug = false,
						verbose = false,
					}
				)

			end)

		if Success then
			Project = Result
		else

			warn(
				"Classic Loading GUI: failed to load RBXM:",
				Result
			)

			return

		end

		--====================================================*
		-- FIND IMPORTED GUI
		--====================================================*

		local LoadingScreen

		if typeof(Project) == "Instance" then

			if Project:IsA("ScreenGui") then

				LoadingScreen = Project

			else

				LoadingScreen =
					Project:FindFirstChild(
						"RobloxLoadingGui",
						true
					)

			end

		end

		--====================================================*
		-- FALLBACK SEARCH
		--====================================================*

		if not LoadingScreen then

			LoadingScreen =
				CoreGui:FindFirstChild(
					"RobloxLoadingGui",
					true
				)

		end

		--====================================================*
		-- WAIT FOR RBXM-SUITE IMPORT
		--====================================================*

		if not LoadingScreen then

			local StartTime =
				os.clock()

			while
				not LoadingScreen
				and os.clock() - StartTime < 10
			do

				LoadingScreen =
					CoreGui:FindFirstChild(
						"RobloxLoadingGui",
						true
					)

				task.wait()

			end

		end

		--====================================================*
		-- SAFETY CHECK
		--====================================================*

		if not LoadingScreen then

			warn(
				"Classic Loading GUI: RobloxLoadingGui could not be found."
			)

			return

		end

		--====================================================*
		-- MOVE INTO COREGUI
		--====================================================*

		if LoadingScreen.Parent ~= CoreGui then
			LoadingScreen.Parent = CoreGui
		end

		--====================================================*
		-- DISPLAY SETTINGS
		--====================================================*

		pcall(function()
			LoadingScreen.DisplayOrder = 2147483647
		end)

		pcall(function()
			LoadingScreen.IgnoreGuiInset = true
		end)

		pcall(function()
			LoadingScreen.ResetOnSpawn = false
		end)

		--====================================================*
		-- GUI HIERARCHY
		--====================================================*
		--
		-- RobloxLoadingGui
		-- └─ BlackFrame
		--    ├─ GraphicsFrame
		--    │  └─ LoadingImage
		--    │
		--    └─ InfoFrame
		--       ├─ UiMessageFrame
		--       │  └─ UiMessage
		--       ├─ CreatorLabel
		--       ├─ PlaceLabel
		--       └─ PlaceIcon
		--
		--====================================================*

		local BlackFrame =
			LoadingScreen:WaitForChild(
				"BlackFrame"
			)

		local GraphicsFrame =
			BlackFrame:WaitForChild(
				"GraphicsFrame"
			)

		local LoadingImage =
			GraphicsFrame:WaitForChild(
				"LoadingImage"
			)

		-- Use the 2017–2022 tilted Roblox icon
		LoadingImage.Image =
			"rbxthumb://type=Asset&id=84036832993951&w=150&h=150"

		local InfoFrame =
			BlackFrame:WaitForChild(
				"InfoFrame"
			)

		local UiMessageFrame =
			InfoFrame:WaitForChild(
				"UiMessageFrame"
			)

		local UiMessage =
			UiMessageFrame:WaitForChild(
				"UiMessage"
			)

		local CreatorLabel =
			InfoFrame:WaitForChild(
				"CreatorLabel"
			)

		local PlaceLabel =
			InfoFrame:WaitForChild(
				"PlaceLabel"
			)

		local PlaceIcon =
			InfoFrame:WaitForChild(
				"PlaceIcon"
			)

		--====================================================*
		-- GAME INFORMATION
		--====================================================*

		local SuccessInfo, GameInfo =
			pcall(
				function()

					return MarketplaceService:GetProductInfo(
						game.PlaceId
					)

				end
			)

		if SuccessInfo and GameInfo then

			--================================================*
			-- GAME TITLE
			--================================================*

			if
				GameInfo.Name
				and GameInfo.Name ~= ""
			then

				PlaceLabel.Text =
					GameInfo.Name

			else

				PlaceLabel.Text =
					game.Name

			end

			--================================================*
			-- CREATOR
			--================================================*

			if
				GameInfo.Creator
				and GameInfo.Creator.Name
			then

				CreatorLabel.Text =
					"By " .. GameInfo.Creator.Name

			else

				CreatorLabel.Text =
					""

			end

		else

			PlaceLabel.Text =
				game.Name

			CreatorLabel.Text =
				""

		end

		--====================================================*
		-- LOADING MESSAGE
		--====================================================*

		UiMessage.Text =
			"Joining Server"

		--====================================================*
		-- GAME THUMBNAIL
		--====================================================*

		local PlaceId = game.PlaceId

		if PlaceId and PlaceId ~= 0 then

			PlaceIcon.Image =
				"rbxthumb://type=GameThumbnail&id="
				.. PlaceId
				.. "&w=768&h=432"

		end

		--====================================================*
		-- ORIGINAL THUMBNAIL ASPECT RATIO
		--====================================================*

		local AspectConstraint =
			PlaceIcon:FindFirstChildOfClass(
				"UIAspectRatioConstraint"
			)

		if AspectConstraint then

			AspectConstraint.AspectRatio =
				1.778

			AspectConstraint.AspectType =
				Enum.AspectType.ScaleWithParentSize

			AspectConstraint.DominantAxis =
				Enum.DominantAxis.Width

		end

		--====================================================*
		-- ORIGINAL ROBLOX SPINNER
		--====================================================*

		local function spinnerEasingFunc(
			a,
			b,
			t
		)

			t = t * 2

			if t < 1 then

				return
					b / 2
					* t
					* t
					* t
					+ a

			else

				t = t - 2

				return
					b / 2
					* (
						t
						* t
						* t
						+ 2
					)
					+ b

			end

		end

		--====================================================*
		-- START SPINNER IMMEDIATELY
		--====================================================*

		local TURN_CYCLE_TIME =
			2

		local SpinnerConnection

		SpinnerConnection =
			RunService.RenderStepped:Connect(
				function()

					if
						not LoadingImage
						or not LoadingImage.Parent
					then

						if SpinnerConnection then

							SpinnerConnection:Disconnect()
							SpinnerConnection = nil

						end

						return

					end

					local CurrentTime =
						tick()

					local TimeInCycle =
						CurrentTime
						% TURN_CYCLE_TIME

					local CycleAlpha =
						spinnerEasingFunc(
							0,
							1,
							TimeInCycle
							/ TURN_CYCLE_TIME
						)

					LoadingImage.Rotation =
						CycleAlpha * 360

				end
			)

		--====================================================*
		-- KEEP LOADING SCREEN FOR 5 SECONDS
		--====================================================*

		task.wait(5)

		--====================================================*
		-- STOP SPINNER
		--====================================================*

		if SpinnerConnection then

			SpinnerConnection:Disconnect()
			SpinnerConnection = nil

		end

		--====================================================*
		-- FADE OUT
		--====================================================*

		local FadeTime =
			0.5

		local FadeInfo =
			TweenInfo.new(
				FadeTime,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)

		for _, Object in ipairs(
			LoadingScreen:GetDescendants()
		) do

			--================================================*
			-- TEXT
			--================================================*

			if
				Object:IsA("TextLabel")
				or Object:IsA("TextButton")
			then

				pcall(function()

					TweenService:Create(
						Object,
						FadeInfo,
						{
							TextTransparency = 1,
							TextStrokeTransparency = 1
						}
					):Play()

				end)

			--================================================*
			-- IMAGES
			--================================================*

			elseif
				Object:IsA("ImageLabel")
				or Object:IsA("ImageButton")
			then

				pcall(function()

					TweenService:Create(
						Object,
						FadeInfo,
						{
							ImageTransparency = 1
						}
					):Play()

				end)

			--================================================*
			-- FRAMES
			--================================================*

			elseif Object:IsA("Frame") then

				pcall(function()

					TweenService:Create(
						Object,
						FadeInfo,
						{
							BackgroundTransparency = 1
						}
					):Play()

				end)

			end

		end

		--====================================================*
		-- WAIT FOR FADE
		--====================================================*

		task.wait(FadeTime)

		--====================================================*
		-- REMOVE GUI
		--====================================================*

		if LoadingScreen then

			pcall(function()
				LoadingScreen:Destroy()
			end)

		end

	end)

end

-- Module / 2017 Chat
--
-- Legacy_2019.rbxm ships its own copy of the chat window. The 2017
-- chat window from Legacy2017.rbxm is used instead. Only the Chat
-- module is taken from it; its scripts are not run. Loaded before the
-- 2019 model so nothing yields between installing it and :Start().

local Chat2017 = (function()

	local Success, Result = pcall(function()

		local Model = Suite.launch(
			Suite.download(
				"letsafe/something@v1.0.0",
				"Legacy2017.rbxm"
			),
			{
				runscripts = false,
				debug = true,
			}
		)

		local Core = Model and Model:FindFirstChild("Core")
		local Client = Core and Core:FindFirstChild(tostring(Settings.Year))
		local Gui = Client and Client:FindFirstChild("NewRobloxGui")
		local Modules = Gui and Gui:FindFirstChild("Modules")
		local Chat = Modules and Modules:FindFirstChild("Chat")

		if not (Chat and Chat:IsA("ModuleScript")) then
			error(`no Chat module for {Settings.Year}`)
		end

		-- Some executors can't compile Luau type annotations, and the
		-- 2017 chat has one. Drop it so the chat still loads there.
		Chat.Source = Chat.Source:gsub(
			"local RBXGeneral: TextChannel =",
			"local RBXGeneral =",
			1
		)

		local Compiled, CompileError = loadstring(Chat.Source)

		if not Compiled then
			error(CompileError)
		end

		return Chat

	end)

	if Success then
		return Result
	end

	warn("[Legacy] 2017 chat unavailable, keeping the 2019 chat:", Result)

end)()

-- Module / Legacy

local Legacy = (function()

	local Path do

		if (Developer) then

			StarterGui:SetCore("SendNotification", {
				Title = "Legacy",
				Text = "Running the developer build",
				Duration = 5
			})

			Path = "Legacy.rbxm"

		else

			local RBXM = Suite.download(
                "Elite-random/test@idk",
                "Legacy_2019.rbxm"
			)

			Path = RBXM

		end

	end

	return Suite.launch(
		Path,
		{
			runscripts = true,
			debug = true,
			verbose = true
		}
	)

end)()

-- Swap in the 2017 chat. Modules load the first time they are
-- required, which happens during :Start(), so replacing it here is
-- enough for the topbar and settings menu to pick it up.

if Chat2017 then

	pcall(function()

		local Client = Legacy.Core:FindFirstChild(tostring(Settings.Year))
		local Modules = Client.NewRobloxGui.Modules
		local Chat2019 = Modules:FindFirstChild("Chat")

		Chat2017.Parent = Modules

		if Chat2019 then
			Chat2019:Destroy()
		end

	end)

end

-- Setup

local LegacyGui =
	Suite.require(Legacy):Start(
		Settings.Year,
		Settings.SafeChat
	)

pcall(function()
	RobloxGui.Enabled = false
end)

-- MOBILE FIX:
-- NotificationFrame does not have to exist on every client.
-- Do not crash if the current client does not create it.

local NotificationFrame =
	RobloxGui:FindFirstChild("NotificationFrame")

if NotificationFrame then
	NotificationFrame.Parent = LegacyGui
end

Run(Settings.OldConsole == true, function()

	loadstring(game:HttpGet(
		"https://raw.githubusercontent.com/yeku/forks/refs/heads/main/Scripts/LegacyConsole.luau"
	))()

end)

Run(Settings.OldGraphics == true, function()

	if (sethiddenproperty) then

		task.spawn(
			sethiddenproperty,
			Lighting,
			"Technology",
			Enum.Technology.Compatibility
		)

	end

	for _, Hidden in next, Lighting:QueryDescendants(
		"> DepthOfFieldEffect, > SunRaysEffect, > BloomEffect, > BlurEffect, > ColorCorrectionEffect, > Atmosphere"
	) do

		if (Hidden:IsA("Atmosphere")) then

			Hidden:Destroy()

		else

			Force(
				Hidden,
				"Enabled",
				false
			)

		end

	end

	Create(
		"ColorGradingEffect",
		{
			TonemapperPreset =
				Enum.TonemapperPreset.Retro
		}
	)

	Create(
		"ColorCorrectionEffect",
		{
			Saturation = 0,

			Contrast = -0.1,

			Parent = Lighting,
		}
	)

end)

Run(Settings.OldBubbleChat == true, function()

	--============================================================*
	-- LEGACY BUBBLE CHAT
	-- Based on the old Roblox BubbleChat renderer.
	-- Creates the bubbles ourselves instead of modifying
	-- modern ExperienceChat bubble instances.
	--============================================================*

	local TextService = game:GetService("TextService")
	local Debris = game:GetService("Debris")

	local LocalPlayer = Players.LocalPlayer
	local Camera = workspace.CurrentCamera

	--============================================================*
	-- DISABLE MODERN BUBBLE CHAT
	--============================================================*

	if ExperienceChat then
		pcall(function()
			ExperienceChat.Enabled = false
		end)
	end

	pcall(function()
		local cfg = TextChatService:FindFirstChild("BubbleChatConfiguration")
		if cfg then
			cfg.Enabled = false
		end
	end)

	--============================================================*
	-- SETTINGS
	--============================================================*

	local MAX_BUBBLE_WIDTH = 400
	local MAX_TOTAL_BUBBLE_HEIGHT = 150

	local NEAR_BUBBLE_DISTANCE = 45
	local MAX_BUBBLE_DISTANCE = 80

	local MIN_BUBBLE_LIFETIME = 12
	local MAX_BUBBLE_LIFETIME = 20

	local MIN_BUBBLE_LIFETIME_SELF = 8
	local MAX_BUBBLE_LIFETIME_SELF = 15

	local BUBBLE_FADE_TIME = 1.5

	local MAX_CHAT_MESSAGE_LENGTH = 128

	local ELLIPSES = "..."

	local MAX_CHAT_MESSAGE_LENGTH_EXCLUSIVE =
		MAX_CHAT_MESSAGE_LENGTH
		- #ELLIPSES
		- 1

	local BubbleFont = nil
	pcall(function()
		BubbleFont = Font.fromEnum(Enum.Font.SourceSans)
	end)
	-- FontFace may be unavailable on some mobile executor builds

	local BubbleBackground =
		Color3.fromRGB(
			255,
			255,
			255
		)

	local BubbleTextColor =
		Color3.fromRGB(
			60,
			68,
			75
		)

	local BubbleTextSize = 22

	--============================================================*
	-- TWEEN INFO
	--============================================================*

	local ResizeBubbleTweenInfo =
		TweenInfo.new(
			0.1,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		)

	local ShiftBubblesUpTweenInfo =
		TweenInfo.new(
			0.07,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.Out
		)

	--============================================================*
	-- QUEUES
	--============================================================*

	local ChatBubbleQueues = {}

	-- Most recent bubble is [1].
	-- Oldest bubble is at the end.

	--============================================================*
	-- MESSAGE LENGTH
	--============================================================*

	local function getMessageLength(Message)

		local Success, Length =
			pcall(
				function()

					return
						utf8.len(
							utf8.nfcnormalize(
								Message
							)
						)

				end
			)

		if Success and Length then
			return Length
		end

		return #Message

	end

	--============================================================*
	-- SANITIZE MESSAGE
	--============================================================*

	local function sanitizeChatLine(Message)

		local Length =
			getMessageLength(
				Message
			)

		if
			Length
			<= MAX_CHAT_MESSAGE_LENGTH_EXCLUSIVE
		then

			return Message

		end

		local ByteOffset

		pcall(function()

			ByteOffset =
				utf8.offset(
					Message,
					MAX_CHAT_MESSAGE_LENGTH_EXCLUSIVE
					+ getMessageLength(
						ELLIPSES
					)
					+ 1
				)

		end)

		if not ByteOffset then
			return string.sub(
				Message,
				1,
				MAX_CHAT_MESSAGE_LENGTH_EXCLUSIVE
			)
		end

		return
			string.sub(
				Message,
				1,
				ByteOffset - 1
			)

	end

	--============================================================*
	-- LIFETIME
	--============================================================*

	local function lerpLength(
		Message,
		Minimum,
		Maximum
	)

		local Alpha =
			math.min(
				getMessageLength(
					Message
				) / 75,
				1
			)

		return
			Minimum
			+ (
				Maximum - Minimum
			)
			* Alpha

	end

	--============================================================*
	-- REMOVE SPECIFIC BUBBLE
	--============================================================*

	local function removeBubbleFromQueue(
		Adornee,
		Bubble
	)

		local Queue =
			ChatBubbleQueues[
				Adornee
			]

		if not Queue then
			return
		end

		for Index, Value in ipairs(Queue) do

			if Value == Bubble then

				table.remove(
					Queue,
					Index
				)

				break

			end

		end

		if #Queue == 0 then

			ChatBubbleQueues[
				Adornee
			] = nil

		end

	end

	--============================================================*
	-- REMOVE OLDEST
	--============================================================*

	local function removeOldestFromQueue(
		Adornee
	)

		local Queue =
			ChatBubbleQueues[
				Adornee
			]

		if not Queue then
			return
		end

		local OldestBubble =
			Queue[#Queue]

		if not OldestBubble then
			return
		end

		table.remove(
			Queue,
			#Queue
		)

		if OldestBubble.Parent then

			OldestBubble:Destroy()

		end

	end

	--============================================================*
	-- ADD TO QUEUE
	--============================================================*

	local function addBubbleToQueue(
		Adornee,
		ChatBubbleGui,
		Lifetime
	)

		local Queue =
			ChatBubbleQueues[
				Adornee
			]

		if not Queue then

			Queue = {}

			ChatBubbleQueues[
				Adornee
			] = Queue

			Adornee.Destroying:Connect(
				function()

					ChatBubbleQueues[
						Adornee
					] = nil

				end
			)

		end

		local Gap = 4

		local ChatBubble =
			ChatBubbleGui
				:FindFirstChild(
					"BillboardFrame"
				)
				and ChatBubbleGui
					.BillboardFrame
					:FindFirstChild(
						"ChatBubble"
					)

		local NewBubbleHeight = 0

		if ChatBubble then

			NewBubbleHeight =
				ChatBubble.AbsoluteSize.Y

			if NewBubbleHeight <= 0 then

				NewBubbleHeight =
					ChatBubble.Size.Y.Offset

			end

		end

		local TotalYSpaceUsed =
			NewBubbleHeight

		--====================================================*
		-- SHIFT EXISTING BUBBLES UP
		--====================================================*

		for _, Bubble in ipairs(Queue) do

			if not Bubble.Parent then
				continue
			end

			local BillboardFrame =
				Bubble:FindFirstChild(
					"BillboardFrame"
				)

			if not BillboardFrame then
				continue
			end

			local ExistingBubble =
				BillboardFrame:FindFirstChild(
					"ChatBubble"
				)

			if not ExistingBubble then
				continue
			end

			local ShiftUp =
				NewBubbleHeight
				+ Gap

			local NewPosition =
				BillboardFrame.Position
				- UDim2.fromOffset(
					0,
					ShiftUp
				)

			TweenService:Create(
				BillboardFrame,
				ShiftBubblesUpTweenInfo,
				{
					Position =
						NewPosition
				}
			):Play()

			TotalYSpaceUsed +=
				ExistingBubble.AbsoluteSize.Y

			local ExistingText =
				ExistingBubble:FindFirstChild(
					"BubbleText"
				)

			if ExistingText then

				ExistingText.TextTransparency =
					0.5

			end

		end

		--====================================================*
		-- REMOVE OLDEST WHEN TOO TALL
		--====================================================*

		if
			TotalYSpaceUsed
			> MAX_TOTAL_BUBBLE_HEIGHT
		then

			removeOldestFromQueue(
				Adornee
			)

		end

		table.insert(
			Queue,
			1,
			ChatBubbleGui
		)

		--====================================================*
		-- REMOVE THIS BUBBLE AFTER ITS LIFETIME
		--====================================================*

		task.delay(
			Lifetime
			+ BUBBLE_FADE_TIME,
			function()

				if ChatBubbleGui.Parent then

					removeBubbleFromQueue(
						Adornee,
						ChatBubbleGui
					)

				end

			end
		)

	end

	--============================================================*
	-- CREATE BUBBLE
	--============================================================*

	local function createBubble(
		Adornee,
		Message,
		SentBySelf
	)

		if
			not Adornee
			or not Adornee.Parent
		then

			return

		end

		Message =
			sanitizeChatLine(
				Message
			)

		--====================================================*
		-- BILLBOARD GUI
		--====================================================*

		local ChatBubbleGui =
			Instance.new(
				"BillboardGui"
			)

		ChatBubbleGui.Name =
			"ChatBubbleGui"

		ChatBubbleGui.Size =
			UDim2.fromOffset(
				400,
				250
			)

		ChatBubbleGui.Adornee =
			Adornee

		pcall(function()
			ChatBubbleGui.MaxDistance =
				MAX_BUBBLE_DISTANCE
		end)

		--====================================================*
		-- BILLBOARD FRAME
		--====================================================*

		local BillboardFrame =
			Instance.new(
				"Frame"
			)

		BillboardFrame.Name =
			"BillboardFrame"

		BillboardFrame.AnchorPoint =
			Vector2.new(
				0.5,
				0
			)

		BillboardFrame.BackgroundTransparency =
			1

		BillboardFrame.Position =
			UDim2.fromScale(
				0.5,
				-0.5
			)

		BillboardFrame.Size =
			UDim2.fromScale(
				1,
				1
			)

		BillboardFrame.Parent =
			ChatBubbleGui

		--====================================================*
		-- SMALL TALK BUBBLE
		--====================================================*

		local SmallTalkBubble =
			Instance.new(
				"ImageLabel"
			)

		SmallTalkBubble.Name =
			"SmallTalkBubble"

		SmallTalkBubble.AnchorPoint =
			Vector2.new(
				0.5,
				1
			)

		SmallTalkBubble.BackgroundTransparency =
			1

		SmallTalkBubble.BorderSizePixel =
			0

		SmallTalkBubble.Image =
			"rbxasset://textures/ui/dialog_white.png"

		SmallTalkBubble.ImageColor3 =
			BubbleBackground

		SmallTalkBubble.Position =
			UDim2.fromScale(
				0.5,
				1
			)

		SmallTalkBubble.ScaleType =
			Enum.ScaleType.Slice

		SmallTalkBubble.Size =
			UDim2.fromOffset(
				40,
				30
			)

		SmallTalkBubble.SliceCenter =
			Rect.new(
				5,
				5,
				15,
				15
			)

		SmallTalkBubble.Visible =
			false

		SmallTalkBubble.Parent =
			BillboardFrame

		--====================================================*
		-- SMALL TALK TEXT
		--====================================================*

		local SmallTalkBubbleText =
			Instance.new(
				"TextLabel"
			)

		SmallTalkBubbleText.Name =
			"BubbleText"

		SmallTalkBubbleText.BackgroundTransparency =
			1

		SmallTalkBubbleText.ClipsDescendants =
			true

		SmallTalkBubbleText.FontFace =
			BubbleFont

		SmallTalkBubbleText.Size =
			UDim2.fromScale(
				1,
				1
			)

		SmallTalkBubbleText.Text =
			"..."

		SmallTalkBubbleText.TextColor3 =
			BubbleTextColor

		SmallTalkBubbleText.TextSize =
			BubbleTextSize

		SmallTalkBubbleText.Parent =
			SmallTalkBubble

		local SmallTalkPadding =
			Instance.new(
				"UIPadding"
			)

		SmallTalkPadding.Name =
			"UIPadding"

		SmallTalkPadding.PaddingBottom =
			UDim.new(
				0,
				12
			)

		SmallTalkPadding.PaddingLeft =
			UDim.new(
				0,
				12
			)

		SmallTalkPadding.PaddingRight =
			UDim.new(
				0,
				12
			)

		SmallTalkPadding.PaddingTop =
			UDim.new(
				0,
				12
			)

		SmallTalkPadding.Parent =
			SmallTalkBubbleText

		--====================================================*
		-- SMALL BUBBLE TAIL
		--====================================================*

		local SmallTailFrame =
			Instance.new(
				"Frame"
			)

		SmallTailFrame.Name =
			"ChatBubbleTailFrame"

		SmallTailFrame.BackgroundTransparency =
			1

		SmallTailFrame.Position =
			UDim2.fromScale(
				0.5,
				1
			)

		SmallTailFrame.Size =
			UDim2.fromScale(
				0.5,
				0.5
			)

		SmallTailFrame.SizeConstraint =
			Enum.SizeConstraint.RelativeXX

		SmallTailFrame.Parent =
			SmallTalkBubble

		local SmallTail =
			Instance.new(
				"ImageLabel"
			)

		SmallTail.Name =
			"ChatBubbleTail"

		SmallTail.BackgroundTransparency =
			1

		SmallTail.BorderSizePixel =
			0

		SmallTail.Image =
			"rbxasset://textures/ui/dialog_tail.png"

		SmallTail.ImageColor3 =
			BubbleBackground

		SmallTail.Position =
			UDim2.fromScale(
				-0.5,
				0
			)

		SmallTail.Size =
			UDim2.fromScale(
				1,
				0.5
			)

		SmallTail.Parent =
			SmallTailFrame

		--====================================================*
		-- MAIN BUBBLE
		--====================================================*

		local ChatBubble =
			Instance.new(
				"ImageLabel"
			)

		ChatBubble.Name =
			"ChatBubble"

		ChatBubble.AnchorPoint =
			Vector2.new(
				0.5,
				1
			)

		ChatBubble.BackgroundTransparency =
			1

		ChatBubble.BorderSizePixel =
			0

		ChatBubble.Image =
			"rbxasset://textures/ui/dialog_white.png"

		ChatBubble.ImageColor3 =
			BubbleBackground

		ChatBubble.Position =
			UDim2.fromScale(
				0.5,
				1
			)

		ChatBubble.ScaleType =
			Enum.ScaleType.Slice

		ChatBubble.SliceCenter =
			Rect.new(
				5,
				5,
				15,
				15
			)

		ChatBubble.Visible =
			false

		ChatBubble.Parent =
			BillboardFrame

		--====================================================*
		-- MAIN TEXT
		--====================================================*

		local BubbleText =
			Instance.new(
				"TextLabel"
			)

		BubbleText.Name =
			"BubbleText"

		BubbleText.BackgroundTransparency =
			1

		BubbleText.ClipsDescendants =
			true

		BubbleText.FontFace =
			BubbleFont

		BubbleText.Size =
			UDim2.fromScale(
				1,
				1
			)

		BubbleText.Text =
			""

		BubbleText.TextColor3 =
			BubbleTextColor

		BubbleText.TextSize =
			BubbleTextSize

		BubbleText.TextWrapped =
			true

		BubbleText.Parent =
			ChatBubble

		local UIPadding =
			Instance.new(
				"UIPadding"
			)

		UIPadding.Name =
			"UIPadding"

		UIPadding.PaddingBottom =
			UDim.new(
				0,
				12
			)

		UIPadding.PaddingLeft =
			UDim.new(
				0,
				12
			)

		UIPadding.PaddingRight =
			UDim.new(
				0,
				12
			)

		UIPadding.PaddingTop =
			UDim.new(
				0,
				12
			)

		UIPadding.Parent =
			BubbleText

		--====================================================*
		-- MAIN TAIL
		--====================================================*

		local ChatBubbleTail =
			Instance.new(
				"ImageLabel"
			)

		ChatBubbleTail.Name =
			"ChatBubbleTail"

		ChatBubbleTail.BackgroundTransparency =
			1

		ChatBubbleTail.BorderSizePixel =
			0

		ChatBubbleTail.Image =
			"rbxasset://textures/ui/dialog_tail.png"

		ChatBubbleTail.ImageColor3 =
			BubbleBackground

		ChatBubbleTail.Position =
			UDim2.new(
				0.5,
				-14,
				1,
				0
			)

		ChatBubbleTail.Size =
			UDim2.fromOffset(
				30,
				14
			)

		ChatBubbleTail.Visible =
			false

		ChatBubbleTail.Parent =
			BillboardFrame

		--====================================================*
		-- CALCULATE TEXT SIZE
		--====================================================*

		local TextSizeBounds =
			TextService:GetTextSize(
				Message,
				BubbleText.TextSize,
				BubbleText.Font,
				Vector2.new(
					MAX_BUBBLE_WIDTH,
					math.huge
				)
			)

		local Multiline =
			TextSizeBounds.Y
			> BubbleText.TextSize

		if not Multiline then

			UIPadding.PaddingTop =
				UDim.new(
					0,
					UIPadding.PaddingTop.Offset / 2
				)

			UIPadding.PaddingBottom =
				UDim.new(
					0,
					UIPadding.PaddingBottom.Offset / 2
				)

		end

		local ChatBubbleSize =
			UDim2.fromOffset(
				TextSizeBounds.X
				+ UIPadding.PaddingLeft.Offset
				+ UIPadding.PaddingRight.Offset
				+ 1,

				TextSizeBounds.Y
				+ UIPadding.PaddingTop.Offset
				+ UIPadding.PaddingBottom.Offset
			)

		--====================================================*
		-- START SLIGHTLY BIGGER
		--====================================================*

		ChatBubble.Size =
			UDim2.fromOffset(
				ChatBubbleSize.X.Offset + 10,
				ChatBubbleSize.Y.Offset + 10
			)

		local ResizeTween =
			TweenService:Create(
				ChatBubble,
				ResizeBubbleTweenInfo,
				{
					Size =
						ChatBubbleSize
				}
			)

		ResizeTween:Play()

		task.delay(
			ResizeBubbleTweenInfo.Time,
			function()

				if BubbleText.Parent then

					BubbleText.Text =
						Message

				end

			end
		)

		--====================================================*
		-- OFFSET
		--====================================================*

		local Lifetime

		if SentBySelf then

			ChatBubbleGui.StudsOffset =
				Vector3.new(
					0,
					1.8,
					0
				)

			Lifetime =
				lerpLength(
					Message,
					MIN_BUBBLE_LIFETIME_SELF,
					MAX_BUBBLE_LIFETIME_SELF
				)

		else

			ChatBubbleGui.StudsOffset =
				Vector3.new(
					0,
					2.4,
					0
				)

			Lifetime =
				lerpLength(
					Message,
					MIN_BUBBLE_LIFETIME,
					MAX_BUBBLE_LIFETIME
				)

		end

		--====================================================*
		-- PARENT
		--====================================================*

		ChatBubbleGui.Parent =
			Adornee

		--====================================================*
		-- FADE
		--====================================================*

		task.delay(
			Lifetime,
			function()

				if not ChatBubbleGui.Parent then
					return
				end

				local FadeInfo =
					TweenInfo.new(
						BUBBLE_FADE_TIME,
						Enum.EasingStyle.Linear
					)

				for _, Object in ipairs(
					ChatBubbleGui:GetDescendants()
				) do

					if Object:IsA(
						"ImageLabel"
					) then

						TweenService:Create(
							Object,
							FadeInfo,
							{
								ImageTransparency = 1
							}
						):Play()

					elseif Object:IsA(
						"TextLabel"
					) then

						TweenService:Create(
							Object,
							FadeInfo,
							{
								TextTransparency = 1
							}
						):Play()

					end

				end

			end
		)

		Debris:AddItem(
			ChatBubbleGui,
			Lifetime
			+ BUBBLE_FADE_TIME
			+ 0.1
		)

		addBubbleToQueue(
			Adornee,
			ChatBubbleGui,
			Lifetime
		)

	end

	--============================================================*
	-- RECEIVE TEXTCHAT MESSAGE
	--============================================================*

	TextChatService.MessageReceived:Connect(
		function(
			TextChatMessage
		)

			local TextSource =
				TextChatMessage.TextSource

			-- System messages don't belong
			-- to a player's head.
			if not TextSource then
				return
			end

			local Player =
				Players:GetPlayerByUserId(
					TextSource.UserId
				)

			if not Player then
				return
			end

			local Character =
				Player.Character

			if not Character then
				return
			end

			local Adornee =
				Character:FindFirstChild(
					"Head"
				)

			if not Adornee then

				Adornee =
					Character:FindFirstChild(
						"HumanoidRootPart"
					)

			end

			if not Adornee then

				Adornee =
					Character

			end

			if not Adornee then
				return
			end

			local Message =
				TextChatMessage.Text

			if
				not Message
				or Message == ""
			then
				return
			end

			createBubble(
				Adornee,
				Message,
				Player == LocalPlayer
			)

		end
	)

	--============================================================*
	-- BUBBLE DISTANCE / VISIBILITY
	--============================================================*

	task.spawn(function()

		while true do

			task.wait()

			Camera =
				workspace.CurrentCamera

			if not Camera then
				continue
			end

			for Adornee, Queue in pairs(
				ChatBubbleQueues
			) do

				if
					not Adornee
					or not Adornee.Parent
				then

					ChatBubbleQueues[
						Adornee
					] = nil

					continue

				end

				if #Queue == 0 then
					continue
				end

				local MostRecentChatBubble =
					Queue[1]

				if
					not MostRecentChatBubble
					or not MostRecentChatBubble.Parent
				then

					continue

				end

				local DistanceFromAdornee

				pcall(function()

					DistanceFromAdornee =
						(
							Camera.CFrame.Position
							-
							Adornee:GetPivot().Position
						).Magnitude

				end)

				if not DistanceFromAdornee then
					continue
				end

				for Index, BubbleGui in ipairs(
					Queue
				) do

					if not BubbleGui.Parent then
						continue
					end

					local BillboardFrame =
						BubbleGui:FindFirstChild(
							"BillboardFrame"
						)

					if not BillboardFrame then
						continue
					end

					local MainBubble =
						BillboardFrame:FindFirstChild(
							"ChatBubble"
						)

					local SmallBubble =
						BillboardFrame:FindFirstChild(
							"SmallTalkBubble"
						)

					local MainTail =
						BillboardFrame:FindFirstChild(
							"ChatBubbleTail"
						)

					if
						DistanceFromAdornee
						< NEAR_BUBBLE_DISTANCE
					then

						--================================================*
						-- NEAR
						--================================================*

						if Index == 1 then

							if MainBubble then
								MainBubble.Visible = true
							end

							if MainTail then
								MainTail.Visible = true
							end

						else

							if MainBubble then
								MainBubble.Visible = true
							end

							if MainTail then
								MainTail.Visible = false
							end

						end

						if SmallBubble then
							SmallBubble.Visible = false
						end

						BubbleGui.Enabled =
							true

					elseif
						DistanceFromAdornee
						< MAX_BUBBLE_DISTANCE
						and Index == 1
					then

						--================================================*
						-- MEDIUM DISTANCE
						--================================================*

						if MainBubble then
							MainBubble.Visible = false
						end

						if MainTail then
							MainTail.Visible = false
						end

						if SmallBubble then
							SmallBubble.Visible = true
						end

						BubbleGui.Enabled =
							true

					else

						--================================================*
						-- FAR
						--================================================*

						BubbleGui.Enabled =
							false

					end

				end

			end

		end

	end)

end)

Run(Settings.HideDisplayName, function()

	-- Functions

	local Change = function(Player)

		local Character =
			(
				Player.Character
				or Player.CharacterAdded:Wait()
			)

		local Humanoid =
			(
				Character
				and Character:FindFirstChildOfClass(
					"Humanoid"
				)
			)

		if
			(Humanoid
			and Humanoid.DisplayName
			== Player.DisplayName)
		then

			Humanoid.DisplayName =
				Player.Name

		else

			Character.ChildAdded:Connect(
				function(Humanoid)

					if
						(Humanoid:IsA("Humanoid")
						and Humanoid.DisplayName
						== Player.DisplayName)
					then

						Humanoid.DisplayName =
							Player.Name

					end

				end
			)

		end

	end

	local Joined = function(Player)

		Change(Player)

		Player.CharacterAdded:Connect(
			function()
				Change(Player)
			end
		)

	end

	-- Setup

	for _, Player in next,
		Players:GetPlayers()
	do

		task.spawn(
			Joined,
			Player
		)

	end

	Players.PlayerAdded:Connect(
		Joined
	)

end)

-- TOP BAR
--
-- The old script assumes:
--
--	CoreGui.TopBarApp.TopBarApp
--
-- That hierarchy is not guaranteed to be identical on mobile.
-- Find whatever part actually exists instead of indexing nil.

task.spawn(function()

	local TopBarApp =
		CoreGui:WaitForChild(
			"TopBarApp",
			10
		)

	if not TopBarApp then
		return
	end

	-- Original expected hierarchy.

	local NestedTopBar =
		TopBarApp:FindFirstChild(
			"TopBarApp"
		)

	if NestedTopBar then

		pcall(function()
			Force(
				NestedTopBar,
				"Enabled",
				false
			)
		end)

	end

	-- Some client versions make TopBarApp itself
	-- the ScreenGui that needs disabling.

	if TopBarApp:IsA("ScreenGui") then

		Force(
			TopBarApp,
			"Enabled",
			false
		)

	end

	-- If neither of the above was the actual ScreenGui,
	-- disable any ScreenGui named TopBarApp underneath it.

	for _, Object in ipairs(
		TopBarApp:GetDescendants()
	) do

		if
			Object.Name == "TopBarApp"
			and Object:IsA("ScreenGui")
		then

			Force(
				Object,
				"Enabled",
				false
			)

		end

	end

end)

-- SETTINGS SHIELD
--
-- Do not assume every client has the complete
-- SettingsClippingShield -> SettingsShield -> Modal chain.

task.spawn(function()

	local SettingsClippingShield =
		RobloxGui:WaitForChild(
			"SettingsClippingShield",
			10
		)

	if not SettingsClippingShield then
		return
	end

	local SettingsShield =
		SettingsClippingShield:WaitForChild(
			"SettingsShield",
			10
		)

	if not SettingsShield then
		return
	end

	local Modal =
		SettingsShield:FindFirstChild(
			"Modal"
		)

	if not Modal then

		Modal =
			SettingsShield:WaitForChild(
				"Modal",
				10
			)

	end

	if Modal then

		Set(
			Modal,
			{
				Visible = false,

				Modal = false,
			},
			true
		)

	end

end)

-- CONTROL FRAME
--
-- This is the important mobile fix.
--
-- ControlFrame is part of the old desktop CoreGui setup.
-- Do NOT destroy it on a touch device.
--
-- On PC we keep the original behavior and remove it.

task.spawn(function()

	if IsTouchDevice then
		return
	end

	local ControlFrame =
		RobloxGui:WaitForChild(
			"ControlFrame",
			10
		)

	if ControlFrame then

		ControlFrame:Destroy()

	end

end)

-- MENU ICON
--
-- DISABLED: keep the stock hamburger menu icon.
-- Do not replace it with the tilted Roblox logo (mobile + PC).
-- Also clean up any leftover logo pieces if an older script run created them.

task.spawn(function()
	local function cleanupLogo(root)
		if not root then return end
		for _, obj in ipairs(root:GetDescendants()) do
			if obj.Name == "LegacyLogo" or obj.Name == "LegacyLogoBackdrop" then
				pcall(function() obj:Destroy() end)
			end
		end
	end
	for _ = 1, 10 do
		pcall(function()
			cleanupLogo(CoreGui)
			if typeof(LegacyGui) == "Instance" then
				cleanupLogo(LegacyGui)
			end
			local nrg = CoreGui:FindFirstChild("NewRobloxGui")
			if nrg then cleanupLogo(nrg) end
		end)
		task.wait(0.5)
	end
end)

-- EMOTES
--
-- Transferred from 2017-2019M:
--   * the topbar emote button (white icon, blue while the wheel is open)
--   * clicking it opens / closes the native emote wheel
--   * Period + B key binds
--   * RobloxGui is only enabled while the wheel is open, then hidden
--     again so the modern Roblox UI stays disabled

task.spawn(function()

	local LocalPlayer = Players.LocalPlayer

	local GuiService = game:GetService("GuiService")

	local ContextActionService = game:GetService("ContextActionService")

	local IconNormalColor = Color3.fromRGB(255, 255, 255)
	local IconOpenColor = Color3.fromRGB(0, 162, 255)

	local EmoteIconImage =
		"rbxthumb://type=Asset&id=105861093234336&w=150&h=150"

	--========================================================*
	-- FIND THE TOP BAR CONTAINER
	--========================================================*

	local FindTopBarContainer = function()

		local NewRobloxGui = CoreGui:FindFirstChild("NewRobloxGui")

		local Container =
			NewRobloxGui
			and NewRobloxGui:FindFirstChild("TopBarContainer", true)

		if Container then
			return Container
		end

		if typeof(LegacyGui) == "Instance" then

			Container = LegacyGui:FindFirstChild("TopBarContainer", true)

			if Container then
				return Container
			end

		end

		return CoreGui:FindFirstChild("TopBarContainer", true)

	end

	local TopBarContainer

	local StartTime = os.clock()

	while not TopBarContainer and os.clock() - StartTime < 15 do

		TopBarContainer = FindTopBarContainer()

		if not TopBarContainer then
			task.wait(0.25)
		end

	end

--============================================================*
-- MAKE LEGACY UI BACKGROUNDS CLICK-THROUGH
--============================================================*

local function MakeLegacyBackgroundsClickThrough(root)
	if not root then return end

	local function shouldSkip(obj)
		local n = string.lower(obj.Name or "")
		-- Keep chat, topbar, loadout, and scrolling frames touchable on mobile
		if n:find("chat") or n:find("topbar") or n:find("loadout") or n:find("backpack") then
			return true
		end
		if obj:IsA("ScrollingFrame") or obj:IsA("TextBox") then
			return true
		end
		local p = obj.Parent
		while p and p ~= root do
			local pn = string.lower(p.Name or "")
			if pn:find("chat") or pn:find("topbar") or pn:find("loadout") then
				return true
			end
			p = p.Parent
		end
		return false
	end

	local function apply(obj)
		if not obj:IsA("GuiObject") then return end
		if obj:IsA("GuiButton") or obj:IsA("TextButton") or obj:IsA("ImageButton") then return end
		if shouldSkip(obj) then return end
		obj.Active = false
		pcall(function()
			obj.Modal = false
		end)
	end

	for _, obj in ipairs(root:GetDescendants()) do
		apply(obj)
	end

	root.DescendantAdded:Connect(apply)
end

-- Apply on PC and mobile so GUIs under the topbar receive clicks/touches.
MakeLegacyBackgroundsClickThrough(LegacyGui)

-- TopBarContainer: non-button regions must not block world/game UI clicks
task.spawn(function()
	local function makeTopBarPassClicks(container)
		if not container then return end
		pcall(function()
			if container:IsA("GuiObject") and not container:IsA("GuiButton") then
				container.Active = false
			end
		end)
		for _, obj in ipairs(container:GetDescendants()) do
			if obj:IsA("GuiObject") then
				local isBtn = obj:IsA("GuiButton") or obj:IsA("TextButton") or obj:IsA("ImageButton")
				if not isBtn then
					pcall(function()
						obj.Active = false
						obj.Modal = false
					end)
				end
			end
		end
	end

	local function findTopBar()
		local nrg = CoreGui:FindFirstChild("NewRobloxGui")
		local c = nrg and nrg:FindFirstChild("TopBarContainer", true)
		if not c and typeof(LegacyGui) == "Instance" then
			c = LegacyGui:FindFirstChild("TopBarContainer", true)
		end
		return c or CoreGui:FindFirstChild("TopBarContainer", true)
	end

	for _ = 1, 40 do
		local container = findTopBar()
		if container then
			makeTopBarPassClicks(container)
			container.DescendantAdded:Connect(function()
				task.defer(function()
					makeTopBarPassClicks(container)
				end)
			end)
			break
		end
		task.wait(0.25)
	end
end)

	--========================================================*
	-- BACKPACK STATE (decides where the button sits)
	--========================================================*

	local IsBackpackEnabled = function()

		local Success, Enabled = pcall(function()
			return StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
		end)

		return Success and Enabled

	end

	--========================================================*
	-- CHECK WHETHER THE EMOTE BUTTON SHOULD BE SHOWN
	--========================================================*

	local ShouldShowEmoteButton = function()

		local Character = LocalPlayer.Character

		if not Character then
			Character = LocalPlayer.CharacterAdded:Wait()
		end

		local Humanoid = Character:FindFirstChildOfClass("Humanoid")

		if not Humanoid then
			Humanoid = Character:WaitForChild("Humanoid", 5)
		end

		-- Hide the legacy button for R6 characters.
		if Humanoid and Humanoid.RigType == Enum.HumanoidRigType.R6 then
			return false
		end

		-- Respect experiences that have disabled the native emote menu.
		local Enabled = false

		local Success = pcall(function()
			Enabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu)
		end)

		return Success and Enabled

	end

	--========================================================*
	-- TOP BAR LAYOUT
	--========================================================*
	-- Runs whether or not the emote button exists.
	--
	--   backpack + emote button:  menu | chat | backpack | emotes
	--   backpack only:            menu | chat | backpack
	--   emote button only:        menu | chat | emotes
	--   neither:                  menu | chat
	--
	-- The second chat icon is always hidden. The backpack sits directly
	-- right of the first chat icon, and the emote button directly right
	-- of the backpack.

	local EmoteButton
	local BackpackButton
	local ButtonParent = TopBarContainer
	local BackpackHome
	local LayoutReady = false
	local UpdateLayout

	if TopBarContainer then

		task.spawn(function()

			-- Find the backpack (inventory) button.
			local BackpackWait = os.clock()

			while not BackpackButton and os.clock() - BackpackWait < 5 do

				BackpackButton = TopBarContainer:FindFirstChild("Backpack", true)

				if not BackpackButton then
					task.wait(0.25)
				end

			end

			ButtonParent =
				(BackpackButton and BackpackButton.Parent)
				or TopBarContainer

			-- The backpack's original spot, remembered before it is moved.
			BackpackHome = BackpackButton and BackpackButton.Position

			-- Top level chat buttons in the row, left to right.
			local GetChatButtons = function()

				local Chats = {}

				for _, Child in ipairs(ButtonParent:GetChildren()) do

					if
						Child ~= EmoteButton
						and Child:IsA("GuiObject")
						and Child.Name:lower():find("^chat")
					then

						table.insert(Chats, Child)

					end

				end

				table.sort(Chats, function(A, B)

					return
						(A.Position.X.Scale * 1000 + A.Position.X.Offset)
						< (B.Position.X.Scale * 1000 + B.Position.X.Offset)

				end)

				return Chats

			end

			UpdateLayout = function()

				local HasBackpack =
					BackpackButton ~= nil
					and BackpackButton.Parent ~= nil
					and BackpackButton.Visible ~= false
					and IsBackpackEnabled()

				local Chats = GetChatButtons()
				local FirstChat = Chats[1]
				local SecondChat = Chats[2]

				if SecondChat and SecondChat.Visible then
					SecondChat.Visible = false
				end

				local SLOT = 50 -- minimum exclusive width per button
				local GAP = 4

				local function resolveWidth(btn)
					if not btn then return SLOT end
					local w = btn.Size.X.Offset
					if w <= 0 then w = btn.AbsoluteSize.X end
					if w <= 0 then w = SLOT end
					return math.max(w, SLOT)
				end

				local function baseXFromChat()
					if FirstChat then
						local cw = resolveWidth(FirstChat)
						local p = FirstChat.Position
						local x = p.X.Offset
						if p.X.Scale == 0 and x == 0 and FirstChat.AbsolutePosition.X > 0 and TopBarContainer then
							x = FirstChat.AbsolutePosition.X - TopBarContainer.AbsolutePosition.X
						end
						return p.X.Scale, x + cw + GAP, p.Y.Scale, p.Y.Offset
					end
					return 0, 100, 0, 0
				end

				local scaleX, x, scaleY, y = baseXFromChat()

				if HasBackpack then
					local bw = resolveWidth(BackpackButton)
					BackpackButton.Position = UDim2.new(scaleX, x, scaleY, y)

					if EmoteButton then
						-- ALWAYS place emote strictly after backpack (never same slot)
						EmoteButton.Position = UDim2.new(scaleX, x + bw + GAP, scaleY, y)
					end
				elseif EmoteButton then
					EmoteButton.Position = UDim2.new(scaleX, x, scaleY, y)
				end

				-- Final safety: if both exist and share nearly the same X, shove emote right
				if HasBackpack and EmoteButton then
					local bx = BackpackButton.AbsolutePosition.X
					local ex = EmoteButton.AbsolutePosition.X
					if math.abs(ex - bx) < SLOT * 0.75 then
						local bw = resolveWidth(BackpackButton)
						local bp = BackpackButton.Position
						EmoteButton.Position = UDim2.new(
							bp.X.Scale,
							bp.X.Offset + bw + GAP,
							bp.Y.Scale,
							bp.Y.Offset
						)
					end
				end

			end

			LayoutReady = true

			-- Aggressive reposition for the first few seconds, then steady
			local start = os.clock()
			while true do
				pcall(UpdateLayout)
				if os.clock() - start < 8 then
					task.wait(0.1)
				else
					task.wait(0.5)
				end
			end

		end)

	end

	--========================================================*
	-- EMOTE BUTTON
	--========================================================*

	if not TopBarContainer then

		warn("[Legacy emotes] TopBarContainer not found, no emote button")

	elseif ShouldShowEmoteButton() then

		-- Wait for the layout to know where things go.
		local ReadyWait = os.clock()

		while not LayoutReady and os.clock() - ReadyWait < 8 do
			task.wait(0.1)
		end

		EmoteButton = Instance.new("ImageButton")

		EmoteButton.Name = "Emotes"

		EmoteButton.Size = UDim2.new(0, 50, 0, 36)

		-- Put it in its slot before it appears.
		if UpdateLayout then
			pcall(UpdateLayout)
		end

		EmoteButton.BackgroundTransparency = 1

		-- Keep the clickable button itself transparent and put the icon in a
		-- smaller ImageLabel so it matches the size of the other topbar icons.
		EmoteButton.Image = ""
		EmoteButton.ImageTransparency = 1
		EmoteButton.Active = true
		EmoteButton.AutoButtonColor = false

		local EmoteIcon = Instance.new("ImageLabel")

		EmoteIcon.Name = "Icon"
		EmoteIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		EmoteIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		EmoteIcon.Size = UDim2.fromOffset(23, 27)
		EmoteIcon.BackgroundTransparency = 1
		EmoteIcon.Image = EmoteIconImage
		EmoteIcon.ImageTransparency = 0
		EmoteIcon.ImageColor3 = IconNormalColor
		EmoteIcon.ScaleType = Enum.ScaleType.Stretch
		EmoteIcon.Active = false
		EmoteIcon.ZIndex = 2
		EmoteIcon.Parent = EmoteButton

		EmoteButton.Parent = ButtonParent

		EmoteButton.MouseButton1Click:Connect(function()

			pcall(function()

				local IsOpen = GuiService:GetEmotesMenuOpen()

				if IsOpen then

					-- Clicking again closes it and returns the icon
					-- to its normal color.
					GuiService:SetEmotesMenuOpen(false)

					RobloxGui.Enabled = false

					EmoteIcon.ImageColor3 = IconNormalColor

				else

					StarterGui:SetCoreGuiEnabled(
						Enum.CoreGuiType.EmotesMenu,
						true
					)

					RobloxGui.Enabled = true

					GuiService:SetEmotesMenuOpen(true)

					EmoteIcon.ImageColor3 = IconOpenColor

					-- Stop movement while the emote wheel is open
					task.spawn(function()
						freezeMovementWhileEmoteOpen()
					end)

				end

			end)

		end)

		--====================================================*
		-- WATCH EMOTE WHEEL STATE
		--====================================================*
		-- The native wheel can close because of movement, clicking
		-- elsewhere, selecting an emote, Escape, etc. Always make the
		-- button icon normal whenever the wheel is actually closed.

		task.spawn(function()

			while EmoteButton.Parent do

				task.wait(0.05)

				local IsOpen = false

				pcall(function()
					IsOpen = GuiService:GetEmotesMenuOpen()
				end)

				-- Blue whenever the native emote wheel is open, whether it
				-- was opened by the icon or by the keyboard shortcut.
				if IsOpen then

					EmoteIcon.ImageColor3 = IconOpenColor

				else

					EmoteIcon.ImageColor3 = IconNormalColor

					-- Do not kill RobloxGui while Examine Avatar (inspect) is open
					local inspectOpen = false
					pcall(function()
						inspectOpen = game:GetService("CoreGui"):GetAttribute("LegacyInspectOpen") == true
					end)
					if not inspectOpen then
						pcall(function()
							RobloxGui.Enabled = false
						end)
					end

				end

			end

		end)

	end

	--========================================================*
	-- EMOTE WHEEL: PERIOD KEY (B removed)
	--========================================================*
	-- The legacy UI disables RobloxGui, which also hides the native
	-- EmotesMenu. Temporarily enable RobloxGui only while the wheel
	-- is open, then hide it again after it closes.

	local function freezeMovementWhileEmoteOpen()
		task.spawn(function()
			local Players = game:GetService("Players")
			local lp = Players.LocalPlayer
			local savedWalk, savedJump, savedJumpH = nil, nil, nil
			local hum = nil

			local function grabHumanoid()
				local char = lp.Character
				if char then
					hum = char:FindFirstChildOfClass("Humanoid")
				end
				return hum
			end

			local function freeze()
				hum = grabHumanoid()
				if hum then
					if savedWalk == nil then
						savedWalk = hum.WalkSpeed
						savedJump = hum.JumpPower
						pcall(function() savedJumpH = hum.JumpHeight end)
					end
					hum.WalkSpeed = 0
					pcall(function() hum.JumpPower = 0 end)
					pcall(function() hum.JumpHeight = 0 end)
				end
				pcall(function()
					local ps = lp:FindFirstChild("PlayerScripts")
					local pm = ps and ps:FindFirstChild("PlayerModule")
					if pm then
						local controls = require(pm):GetControls()
						if controls and controls.Disable then
							controls:Disable()
						end
					end
				end)
			end

			local function unfreeze()
				hum = grabHumanoid()
				if hum and savedWalk ~= nil then
					hum.WalkSpeed = savedWalk
					pcall(function() hum.JumpPower = savedJump end)
					pcall(function() if savedJumpH then hum.JumpHeight = savedJumpH end end)
				end
				savedWalk, savedJump, savedJumpH = nil, nil, nil
				pcall(function()
					local ps = lp:FindFirstChild("PlayerScripts")
					local pm = ps and ps:FindFirstChild("PlayerModule")
					if pm then
						local controls = require(pm):GetControls()
						if controls and controls.Enable then
							controls:Enable()
						end
					end
				end)
			end

			while true do
				local open = false
				pcall(function()
					open = GuiService:GetEmotesMenuOpen()
				end)
				if not open then
					unfreeze()
					break
				end
				freeze()
				task.wait(0.05)
			end
		end)
	end

	local OpenLegacyEmoteWheel = function(_, InputState)

		if InputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end

		-- Don't steal the emote keys while typing in chat / text boxes.
		if UserInputService:GetFocusedTextBox() then
			return Enum.ContextActionResult.Pass
		end

		pcall(function()

			StarterGui:SetCoreGuiEnabled(
				Enum.CoreGuiType.EmotesMenu,
				true
			)

			RobloxGui.Enabled = true

			GuiService:SetEmotesMenuOpen(true)

		end)

		freezeMovementWhileEmoteOpen()

		return Enum.ContextActionResult.Sink

	end

	ContextActionService:BindActionAtPriority(
		"LegacyEmoteWheel",
		OpenLegacyEmoteWheel,
		false,
		4000,
		Enum.KeyCode.Period
	)

	-- Once the native wheel closes, hide RobloxGui again so the
	-- modern Roblox UI stays disabled like before.
	-- Never do this while Examine Avatar (inspect) is open.
	while true do

		task.wait(0.1)

		local IsOpen = false
		local inspectOpen = false

		pcall(function()
			IsOpen = GuiService:GetEmotesMenuOpen()
		end)
		pcall(function()
			inspectOpen = game:GetService("CoreGui"):GetAttribute("LegacyInspectOpen") == true
		end)

		if not IsOpen and not inspectOpen then

			pcall(function()
				RobloxGui.Enabled = false
			end)

		end

	end

end)


-- MOVE GAME GUI OUT OF THE TOP BAR
--
-- Game UI sitting at the very top of the screen ends up under the
-- legacy top bar and its drop shadow. Anything in PlayerGui whose
-- top edge is inside that band is pushed down below it.
-- Re-checked twice a second, so UI that gets recreated or
-- repositioned by the game is handled too.

task.spawn(function()

	local MoveGameGui = true

	-- Height of the top bar + its drop shadow, in pixels.
	-- Raise this if UI is still covered.
	local TopBarHeight = 36

	-- Extra space left under the bar.
	local Padding = 6

	-- ScreenGui names to leave alone.
	local Ignored = {
		Chat = true,
		BubbleChat = true,
	}

	if not MoveGameGui then
		return
	end

	local LocalPlayer = Players.LocalPlayer

	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	local Target = TopBarHeight + Padding

	local Process

	Process = function(Object, ScreenHeight, Depth)

		if not Object:IsA("GuiObject") or not Object.Visible then
			return
		end

		local Size = Object.AbsoluteSize

		if Size.X <= 0 or Size.Y <= 0 then
			return
		end

		-- Big containers: look at what is inside them instead.
		if Size.Y >= ScreenHeight * 0.5 then

			if Depth < 4 then

				for _, Child in ipairs(Object:GetChildren()) do
					Process(Child, ScreenHeight, Depth + 1)
				end

			end

			return

		end

		local Top = Object.AbsolutePosition.Y

		-- Parked above the screen on purpose (slide-in menus etc).
		if Top < -2 then
			return
		end

		if Top < TopBarHeight then

			Object.Position =
				Object.Position
				+ UDim2.fromOffset(0, Target - Top)

		end

	end

	while task.wait(0.5) do

		for _, Gui in ipairs(PlayerGui:GetChildren()) do

			if
				Gui:IsA("ScreenGui")
				and Gui.Enabled
				and not Ignored[Gui.Name]
				and Gui ~= LegacyGui
				and not Gui:FindFirstChild("TopBarContainer", true)
			then

				pcall(function()

					local ScreenHeight = Gui.AbsoluteSize.Y

					if ScreenHeight <= 0 then
						return
					end

					for _, Child in ipairs(Gui:GetChildren()) do
						Process(Child, ScreenHeight, 1)
					end

				end)

			end

		end

	end

end)



-- Hide stray modern top-bar Roblox / icon images near the menu & chat
task.spawn(function()
	local function hideStrayLogos(root)
		if not root then return end
		for _, obj in ipairs(root:GetDescendants()) do
			if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.Image ~= "" then
				local y = obj.AbsolutePosition.Y
				local x = obj.AbsolutePosition.X
				if y < 60 and x < 200 then
					local img = string.lower(obj.Image)
					local name = string.lower(obj.Name)
					if name:find("logo") or name:find("roblox") or img:find("roblox")
						or img:find("84036832993951") or name:find("icon") and img:find("rbxthumb") then
						-- Do not hide the intentional Legacy menu logo or chat button icons
						if obj.Name ~= "LegacyLogo" and obj.Name ~= "Icon" and not obj:FindFirstAncestor("Chat") then
							if not name:find("chat") and not name:find("backpack") and not name:find("emote") then
								pcall(function()
									obj.ImageTransparency = 1
									obj.Visible = false
								end)
							end
						end
					end
				end
			end
		end
	end
	for _ = 1, 20 do
		pcall(function()
			hideStrayLogos(CoreGui:FindFirstChild("TopBarApp"))
			hideStrayLogos(CoreGui:FindFirstChild("NewRobloxGui"))
			if typeof(LegacyGui) == "Instance" then
				hideStrayLogos(LegacyGui)
			end
		end)
		task.wait(0.5)
	end
end)

-- LEAVE / RESET CONFIRMATION PAGES
--
-- The "Are you sure you want to leave the game?" and "Are you sure you
-- want to reset your character?" pages of the ESC menu.
--
-- On a touch screen (phones / tablets) they look like the 2021 gui on
-- a phone: the question about a third of the way down, the blue
-- "Leave" / "Reset" button and the grey "Don't" button side by side
-- under it, wide and centred. Changing the menu's own question and
-- buttons does not work there (the menu keeps its own layout), so a
-- copy of them is drawn on top in the 2021 spot, sliding in and out
-- with the page, while the menu's own ones are hidden. Tapping a copied
-- button runs the menu's real button, so they do exactly what they did
-- before.
--
-- On PC the Leave page copies the Reset page's layout, and the first
-- button of each page stays blue.
--
-- The pages are found by their text, wherever the menu keeps them.

local MATCH_LEAVE_TO_RESET = true
local FIRST_BUTTON_BLUE = true
local MOBILE_LAYOUT_LIKE_2021 = true

-- 2021 mobile layout, as fractions of the screen height (measured on
-- the 2021 gui on a 2340x1080 phone).
local MobileLayout = {
	QuestionCenterY = 0.311, -- middle of the question line
	QuestionHeight = 0.12,
	QuestionTextSize = 0.0515, -- only used if the text can't be measured
	ButtonTop = 0.4565,
	ButtonWidth = 0.5315,
	ButtonHeight = 0.1148,
	ButtonGap = 0.1361, -- space between the two buttons
	ButtonTextSize = 0.0375, -- only used if the text can't be measured
	MaxScreenWidth = 0.92, -- never wider than this part of the screen

	-- How far the button's frame reaches past the button you see, in
	-- pixels on a 1080 px tall screen (measured on the last screenshots:
	-- the frame was 27 px wider and taller than the button showing).
	FaceMargin = { Left = 15, Right = 13, Top = 6, Bottom = 22 },

	-- The text is sized so it is as wide as in the 2021 images (fractions
	-- of the screen height): "Are you sure you want to leave the game?"
	-- is 1052 px wide and "Leave" 104 px on a 1080 px tall screen.
	QuestionSample = "Are you sure you want to leave the game?",
	QuestionSampleWidth = 1.015,
	ButtonSample = "Leave",
	ButtonSampleWidth = 0.1065,
}

task.spawn(function()

	if not (MATCH_LEAVE_TO_RESET or FIRST_BUTTON_BLUE or MOBILE_LAYOUT_LIKE_2021) then
		return
	end

	local GuiService = game:GetService("GuiService")

	local VirtualInputManager

	pcall(function()
		VirtualInputManager = game:GetService("VirtualInputManager")
	end)

	local BlueButton = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButtonSelected.png"
	local GreyButton = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButton.png"

	local Questions = {
		leave = { question = "leave the game", confirm = "leave" },
		reset = { question = "reset your character", confirm = "reset" },
	}

	local SetIfDifferent = function(Object, Property, Value)
		pcall(function()
			if Object[Property] ~= Value then
				Object[Property] = Value
			end
		end)
	end

	local TextOf = function(Object)

		local Success, Text = pcall(function()
			return Object.Text
		end)

		if Success and type(Text) == "string" then
			return (Text:lower():match("^%s*(.-)%s*$"))
		end

		return nil

	end

	local KindOf = function(Object)

		if not Object:IsA("TextLabel") then
			return nil
		end

		local Text = TextOf(Object)

		if not Text then
			return nil
		end

		for Kind, Info in pairs(Questions) do
			if Text:find(Info.question, 1, true) then
				return Kind
			end
		end

		return nil

	end

	-- The page a question sits on, and its two buttons.
	local FindParts = function(Question, Kind)

		local Page = Question.Parent

		if not (Page and Page:IsA("GuiBase2d")) then
			return nil
		end

		local Word = Questions[Kind].confirm
		local Confirm, Cancel

		for _, Object in ipairs(Page:GetDescendants()) do

			if
				Object:IsA("GuiButton")
				and not (Confirm and Confirm:IsAncestorOf(Object))
				and not (Cancel and Cancel:IsAncestorOf(Object))
			then

				local Texts = { TextOf(Object) }

				for _, Child in ipairs(Object:GetDescendants()) do

					local Text = (Child:IsA("TextLabel") or Child:IsA("TextButton")) and TextOf(Child)

					if Text then
						table.insert(Texts, Text)
					end

				end

				for _, Text in ipairs(Texts) do

					if Text == Word then
						Confirm = Confirm or Object
					elseif Text:find("^don") and Text:find(Word, 1, true) then
						Cancel = Cancel or Object
					end

				end

			end

		end

		if not Confirm then
			return nil
		end

		return { Kind = Kind, page = Page, question = Question, confirm = Confirm, cancel = Cancel }

	end

	local StillValid = function(Parts)
		return Parts.question.Parent == Parts.page
			and KindOf(Parts.question) == Parts.Kind
			and Parts.confirm:IsDescendantOf(Parts.page)
	end

	--========================================================*
	-- OVERLAY (touch screens): the 2021 copy is drawn here
	--========================================================*

	local Overlay = Instance.new("ScreenGui")

	Overlay.Name = "Legacy2021ConfirmPage"
	Overlay.ResetOnSpawn = false
	Overlay.IgnoreGuiInset = true
	Overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Overlay.DisplayOrder = 1000
	Overlay.Enabled = false

	pcall(function()
		Overlay.ScreenInsets = Enum.ScreenInsets.None
	end)

	pcall(function()
		Overlay.Parent = CoreGui
	end)

	if not Overlay.Parent then
		pcall(function()
			Overlay.Parent = gethui and gethui()
		end)
	end

	if not Overlay.Parent then
		pcall(function()
			Overlay.Parent = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
		end)
	end

	--========================================================*
	-- FINDING THE PAGES
	--========================================================*

	-- [question label] = { Kind, page, question, confirm, cancel }
	local Tracked = {}

	local Consider = function(Object)

		if Tracked[Object] or not Object:IsA("TextLabel") or Object:IsDescendantOf(Overlay) then
			return
		end

		local Kind = KindOf(Object)

		if not Kind then
			return
		end

		local Success, Parts = pcall(FindParts, Object, Kind)

		if Success and Parts then
			Tracked[Object] = Parts
			print("[Legacy] " .. Kind .. " page found:", Parts.page:GetFullName())
		end

	end

	local Scan = function(Root)

		if typeof(Root) ~= "Instance" then
			return
		end

		Consider(Root)

		for _, Object in ipairs(Root:GetDescendants()) do
			if Object:IsA("TextLabel") then
				Consider(Object)
			end
		end

	end

	local Have = function(Kind)

		for _, Parts in pairs(Tracked) do
			if Parts.Kind == Kind then
				return true
			end
		end

		return false

	end

	-- Pages the menu keeps off screen: its module records, and the
	-- objects with no parent.
	local HiddenRoots = function()

		local Roots = {}

		pcall(function()

			local Records = Environment().__rbxm_suite_modules

			if type(Records) ~= "table" then
				return
			end

			local AddPage = function(Value)
				if type(Value) == "table" and typeof(rawget(Value, "Page")) == "Instance" then
					table.insert(Roots, rawget(Value, "Page"))
				end
			end

			for Module, Record in pairs(Records) do

				if
					typeof(Module) == "Instance"
					and type(Record) == "table"
					and (
						Module.Name == "LeaveGame"
						or Module.Name == "ResetCharacter"
						or Module.Name == "SettingsHub"
					)
				then

					local Data = rawget(Record, "data")

					AddPage(Data)

					local Hub = type(Data) == "table" and rawget(Data, "Instance")

					if type(Hub) == "table" then
						for _, Value in pairs(Hub) do
							AddPage(Value)
						end
					end

				end

			end

		end)

		pcall(function()

			if type(getnilinstances) ~= "function" then
				return
			end

			for _, Object in ipairs(getnilinstances()) do
				if typeof(Object) == "Instance" and Object:IsA("GuiObject") then
					table.insert(Roots, Object)
				end
			end

		end)

		return Roots

	end

	-- Right away when a page is built or put on screen.
	local Watch = function(Root)

		if typeof(Root) ~= "Instance" then
			return
		end

		pcall(function()

			Root.DescendantAdded:Connect(function(Object)

				if Object:IsA("TextLabel") then
					Consider(Object)
					task.defer(Consider, Object)
					task.delay(0.25, Consider, Object)
				end

			end)

		end)

	end

	Watch(CoreGui)

	if typeof(LegacyGui) == "Instance" and not LegacyGui:IsDescendantOf(CoreGui) then
		Watch(LegacyGui)
	end

	--========================================================*
	-- THE 2021 COPY
	--========================================================*

	local Copies = {} -- [Parts] = { Holder, Question, Buttons }
	local Saved = {} -- [Parts] = the menu's own look, while hidden

	local StripConstraints = function(Object)

		for _, Descendant in ipairs(Object:GetDescendants()) do

			if
				Descendant:IsA("UISizeConstraint")
				or Descendant:IsA("UIAspectRatioConstraint")
				or Descendant:IsA("UITextSizeConstraint")
				or Descendant:IsA("UIScale")
				or Descendant:IsA("LuaSourceContainer")
			then
				Descendant:Destroy()
			end

		end

	end

	-- Used only if the menu's button can't be copied.
	local BuildButton = function(Text, Blue)

		local Button = Instance.new("ImageButton")

		Button.BackgroundTransparency = 1
		Button.Image = Blue and BlueButton or GreyButton
		Button.ScaleType = Enum.ScaleType.Slice
		Button.SliceCenter = Rect.new(8, 6, 46, 44)

		local Label = Instance.new("TextLabel")

		Label.BackgroundTransparency = 1
		Label.Size = UDim2.new(1, 0, 1, -8)
		Label.Font = Enum.Font.SourceSansBold
		Label.TextColor3 = Color3.new(1, 1, 1)
		Label.Text = Text
		Label.Parent = Button

		return Button

	end

	-- Run the menu's real button, as if it was tapped.
	local Fire = function(Button)

		for _, Name in ipairs({ "MouseButton1Click", "Activated" }) do

			local Fired = false

			if getconnections then

				pcall(function()

					for _, Connection in ipairs(getconnections(Button[Name])) do

						if Connection.Function then
							task.spawn(Connection.Function)
							Fired = true
						elseif Connection.Fire then
							task.spawn(pcall, Connection.Fire, Connection)
							Fired = true
						end

					end

				end)

			elseif firesignal then

				Fired = pcall(firesignal, Button[Name])

			end

			if Fired then
				return true
			end

		end

		return false

	end

	local Restore = function(Parts)

		local Look = Saved[Parts]

		if not Look then
			return
		end

		Saved[Parts] = nil

		SetIfDifferent(Parts.question, "TextTransparency", Look.TextTransparency)
		SetIfDifferent(Parts.question, "TextStrokeTransparency", Look.TextStrokeTransparency)
		SetIfDifferent(Parts.confirm, "Visible", true)

		if Parts.cancel then
			SetIfDifferent(Parts.cancel, "Visible", true)
		end

	end

	local HideOriginals = function(Parts)

		if not Saved[Parts] then
			Saved[Parts] = {
				TextTransparency = Parts.question.TextTransparency,
				TextStrokeTransparency = Parts.question.TextStrokeTransparency,
			}
		end

		SetIfDifferent(Parts.question, "TextTransparency", 1)
		SetIfDifferent(Parts.question, "TextStrokeTransparency", 1)
		SetIfDifferent(Parts.confirm, "Visible", false)

		if Parts.cancel then
			SetIfDifferent(Parts.cancel, "Visible", false)
		end

	end

	local LastPress = 0
	local ShowRealUntil = 0

	local Press = function(Parts, Original)

		if os.clock() - LastPress < 0.4 then
			return
		end

		LastPress = os.clock()

		if Fire(Original) then
			return
		end

		-- No way to run it directly: show the real button for a moment
		-- and tap it.
		if not VirtualInputManager then
			warn("[Legacy] can't press the menu's button on this executor")
			return
		end

		ShowRealUntil = os.clock() + 0.5

		task.spawn(function()

			Restore(Parts)

			RunService.RenderStepped:Wait()

			local Root = Original:FindFirstAncestorWhichIsA("ScreenGui")
			local Inset = (Root and not Root.IgnoreGuiInset) and GuiService:GetGuiInset() or Vector2.zero
			local Center = Original.AbsolutePosition + Original.AbsoluteSize / 2 + Inset

			pcall(function()
				VirtualInputManager:SendMouseButtonEvent(Center.X, Center.Y, 0, true, game, 0)
				task.wait(0.05)
				VirtualInputManager:SendMouseButtonEvent(Center.X, Center.Y, 0, false, game, 0)
			end)

		end)

	end

	local MakeCopy = function(Parts)

		local Holder = Instance.new("Frame")

		Holder.Name = Parts.Kind
		Holder.BackgroundTransparency = 1
		Holder.Size = UDim2.fromScale(1, 1)
		Holder.Active = false
		Holder.Visible = false
		Holder.Parent = Overlay

		local Question = Instance.new("TextLabel")

		Question.Name = "Question"
		Question.BackgroundTransparency = 1
		Question.Active = false
		Question.Font = Enum.Font.SourceSansBold
		Question.TextColor3 = Color3.new(1, 1, 1)
		Question.TextWrapped = true
		Question.TextScaled = false
		Question.TextXAlignment = Enum.TextXAlignment.Center
		Question.TextYAlignment = Enum.TextYAlignment.Center

		pcall(function()
			Question.FontFace = Parts.question.FontFace
		end)

		pcall(function()
			Question.TextColor3 = Parts.question.TextColor3
		end)

		Question.Parent = Holder

		local Buttons = {}

		for Index, Original in ipairs({ Parts.confirm, Parts.cancel or false }) do

			if Original then

				local Blue = Index == 1 and FIRST_BUTTON_BLUE

				local Success, Copy = pcall(function()
					return Original:Clone()
				end)

				if Success and Copy then

					StripConstraints(Copy)

					if Copy:IsA("ImageButton") then
						if Blue then
							Copy.Image = BlueButton
						elseif Copy.Image == BlueButton then
							Copy.Image = GreyButton
						end
					end

				else

					local Text = TextOf(Original) or ""

					for _, Child in ipairs(Original:GetDescendants()) do
						if Child:IsA("TextLabel") and Child.Text ~= "" then
							Text = Child.Text
							break
						end
					end

					Copy = BuildButton(Text, Blue)

				end

				Copy.Name = Index == 1 and "Confirm" or "Cancel"
				Copy.AnchorPoint = Vector2.zero
				Copy.Visible = true
				Copy.Active = true

				pcall(function()
					Copy.Selectable = false
				end)

				Copy.Parent = Holder

				Copy.Activated:Connect(function()
					Press(Parts, Original)
				end)

				-- Flashes blue while it is pressed, like the menu's own
				-- buttons (so "Don't Leave" / "Don't Reset" go blue too),
				-- and stays blue a moment after a quick tap so it shows.
				if Copy:IsA("ImageButton") then

					local Normal = Copy.Image
					local Token = 0
					local PressedAt = 0

					local IsPointer = function(Input)
						return Input.UserInputType == Enum.UserInputType.Touch
							or Input.UserInputType == Enum.UserInputType.MouseButton1
					end

					local Release = function()

						local Mine = Token

						task.delay(math.max(0, 0.2 - (os.clock() - PressedAt)), function()
							if Token == Mine then
								SetIfDifferent(Copy, "Image", Normal)
							end
						end)

					end

					Copy.InputBegan:Connect(function(Input)

						if IsPointer(Input) then
							Token = Token + 1
							PressedAt = os.clock()
							SetIfDifferent(Copy, "Image", BlueButton)
						end

					end)

					Copy.InputEnded:Connect(function(Input)

						if IsPointer(Input) then
							Release()
						end

					end)

					Copy.MouseLeave:Connect(Release)

				end

				table.insert(Buttons, Copy)

			end

		end

		return { Holder = Holder, Question = Question, Buttons = Buttons }

	end

	local IsOnScreen = function(Parts)

		local Question = Parts.question
		local Root = Question:FindFirstAncestorWhichIsA("LayerCollector")

		if not (Root and Root:IsDescendantOf(game)) then
			return false
		end

		if Root:IsA("ScreenGui") and not Root.Enabled then
			return false
		end

		local Current = Question

		while Current and Current ~= Root do

			if Current:IsA("GuiObject") and not Current.Visible then
				return false
			end

			Current = Current.Parent

		end

		local Camera = workspace.CurrentCamera
		local Screen = Camera and Camera.ViewportSize or Vector2.new(1, 1)
		local Position, Size = Question.AbsolutePosition, Question.AbsoluteSize

		return Size.X > 0 and Size.Y > 0
			and Position.X + Size.X > 0 and Position.X < Screen.X
			and Position.Y + Size.Y > 0 and Position.Y < Screen.Y

	end

	-- How far the page is from where it rests (the menu slides pages in
	-- and out): the copy is moved by the same amount, so it slides with
	-- the page and stops in the 2021 spot.
	local Rest = setmetatable({}, { __mode = "k" })
	local Last = setmetatable({}, { __mode = "k" })
	local Still = setmetatable({}, { __mode = "k" })

	local SlideOffset = function(Page, ScreenWidth)

		local Position = Page.AbsolutePosition
		local Parent = Page.Parent

		if Last[Page] and (Position - Last[Page]).Magnitude < 0.5 then
			Still[Page] = (Still[Page] or 0) + 1
		else
			Still[Page] = 0
		end

		Last[Page] = Position

		local Across =
			(Parent and Parent:IsA("GuiBase2d"))
			and Position.X - Parent.AbsolutePosition.X
			or 0

		-- Not moving for a few frames, and on screen: that's its rest.
		if Still[Page] >= 5 and math.abs(Across) < ScreenWidth * 0.25 then
			Rest[Page] = Position
		end

		if Rest[Page] then
			return Position - Rest[Page]
		end

		return Vector2.new(Across, 0)

	end

	local TextService = game:GetService("TextService")

	-- The biggest whole TextSize at which Text is no wider than Width.
	local FitSize = function(Text, Font, Width)

		local Low, High = 8, 120

		while Low < High do

			local Mid = math.ceil((Low + High) / 2)

			local Success, Bounds = pcall(
				TextService.GetTextSize,
				TextService,
				Text,
				Mid,
				Font,
				Vector2.new(10000, 10000)
			)

			if not Success then
				return nil
			end

			if Bounds.X > Width then
				High = Mid - 1
			else
				Low = Mid
			end

		end

		return Low

	end

	local Fitted = {}

	local TextSizes = function(Parts, H)

		local L = MobileLayout
		local Key = tostring(H)

		if Fitted[Key] then
			return Fitted[Key][1], Fitted[Key][2]
		end

		local QuestionFont, ButtonFont = Enum.Font.SourceSansBold, Enum.Font.SourceSansBold

		pcall(function()
			QuestionFont = Parts.question.Font
		end)

		pcall(function()
			for _, Child in ipairs(Parts.confirm:GetDescendants()) do
				if Child:IsA("TextLabel") and Child.Text ~= "" then
					ButtonFont = Child.Font
					break
				end
			end
		end)

		local Question = FitSize(L.QuestionSample, QuestionFont, H * L.QuestionSampleWidth)
			or math.floor(H * L.QuestionTextSize + 0.5)

		local Button = FitSize(L.ButtonSample, ButtonFont, H * L.ButtonSampleWidth)
			or math.floor(H * L.ButtonTextSize + 0.5)

		Fitted[Key] = { Question, Button }

		print("[Legacy] 2021 page text sizes for a screen " .. Key .. " tall: question " .. Question .. ", buttons " .. Button)

		return Question, Button

	end

	local LayOut = function(Parts, Copy)

		local Camera = workspace.CurrentCamera

		if not Camera then
			return false
		end

		-- The whole display, which is what this overlay covers. (The
		-- camera's viewport leaves out the notch / rounded-corner
		-- gutters, about 100 px each side on a phone, which put
		-- everything about 100 px left of where it is in 2021.)
		local W, H = Overlay.AbsoluteSize.X, Overlay.AbsoluteSize.Y

		if W <= 0 or H <= 0 then
			W, H = Camera.ViewportSize.X, Camera.ViewportSize.Y
		end

		if W <= 0 or H <= 0 then
			return false
		end

		local Offset = SlideOffset(Parts.page, W)

		if math.abs(Offset.X) >= W or math.abs(Offset.Y) >= H then
			return false
		end

		local L = MobileLayout

		SetIfDifferent(Copy.Holder, "Position", UDim2.fromOffset(math.floor(Offset.X + 0.5), math.floor(Offset.Y + 0.5)))

		-- Question
		local QuestionWidth = W * L.MaxScreenWidth
		local QuestionHeight = H * L.QuestionHeight

		SetIfDifferent(Copy.Question, "Size", UDim2.fromOffset(math.floor(QuestionWidth), math.floor(QuestionHeight)))
		SetIfDifferent(Copy.Question, "Position", UDim2.fromOffset(
			math.floor((W - QuestionWidth) / 2),
			math.floor(H * L.QuestionCenterY - QuestionHeight / 2)
		))
		SetIfDifferent(Copy.Question, "Text", Parts.question.Text)
		local QuestionSize, ButtonSize = TextSizes(Parts, H)

		SetIfDifferent(Copy.Question, "TextSize", math.clamp(QuestionSize, 1, 100))

		-- Buttons: wide, side by side, centred under the question.
		local ButtonWidth = H * L.ButtonWidth
		local ButtonHeight = H * L.ButtonHeight
		local Gap = H * L.ButtonGap

		local Total = ButtonWidth * 2 + Gap
		local MaxTotal = W * L.MaxScreenWidth

		if Total > MaxTotal then
			local Shrink = MaxTotal / Total
			ButtonWidth = ButtonWidth * Shrink
			Gap = Gap * Shrink
			Total = MaxTotal
		end

		local Left = (W - Total) / 2
		local Top = H * L.ButtonTop
		local TextSize = math.clamp(ButtonSize, 1, 100)

		for Index, Button in ipairs(Copy.Buttons) do

			-- ButtonWidth x ButtonHeight is the button you see. Its picture
			-- has a see-through edge and a shadow, so the frame holding
			-- it is bigger than that by the margins.
			local Scale = H / 1080
			local Margin = L.FaceMargin
			local FaceLeft = Left + (Index - 1) * (ButtonWidth + Gap)

			SetIfDifferent(Button, "Position", UDim2.fromOffset(
				math.floor(FaceLeft - Margin.Left * Scale + 0.5),
				math.floor(Top - Margin.Top * Scale + 0.5)
			))
			SetIfDifferent(Button, "Size", UDim2.fromOffset(
				math.floor(ButtonWidth + (Margin.Left + Margin.Right) * Scale + 0.5),
				math.floor(ButtonHeight + (Margin.Top + Margin.Bottom) * Scale + 0.5)
			))

			for _, Child in ipairs(Button:GetDescendants()) do
				if Child:IsA("TextLabel") then
					SetIfDifferent(Child, "TextScaled", false)
					SetIfDifferent(Child, "TextSize", TextSize)
				end
			end

			if Button:IsA("TextButton") and Button.Text ~= "" then
				SetIfDifferent(Button, "TextScaled", false)
				SetIfDifferent(Button, "TextSize", TextSize)
			end

		end

		-- Just above the menu.
		local Root = Parts.question:FindFirstAncestorWhichIsA("ScreenGui")

		if Root then
			SetIfDifferent(Overlay, "DisplayOrder", Root.DisplayOrder + 1)
		end

		return true

	end

	--========================================================*
	-- LOOKING FOR THE PAGES
	--========================================================*

	-- A regular look in case one is missed. The whole CoreGui only a few
	-- times at the start; the hidden places every 5 seconds until both
	-- pages are known.
	task.spawn(function()

		local Started, LastHidden = os.clock(), -math.huge
		local FullScans, NextFull = { 0, 5, 15, 30 }, 1

		while true do

			pcall(Scan, LegacyGui)
			pcall(Scan, CoreGui:FindFirstChild("NewRobloxGui"))

			if NextFull <= #FullScans and os.clock() - Started >= FullScans[NextFull] then
				NextFull = NextFull + 1
				pcall(Scan, CoreGui)
			end

			if not (Have("leave") and Have("reset")) and os.clock() - LastHidden >= 5 then

				LastHidden = os.clock()

				for _, Root in ipairs(HiddenRoots()) do
					pcall(Scan, Root)
				end

			end

			-- Forget pages that are gone.
			for Question, Parts in pairs(Tracked) do

				if not StillValid(Parts) then

					Restore(Parts)

					if Copies[Parts] then
						pcall(function()
							Copies[Parts].Holder:Destroy()
						end)
						Copies[Parts] = nil
					end

					Tracked[Question] = nil

				end

			end

			task.wait(1)

		end

	end)

	--========================================================*
	-- EVERY FRAME
	--========================================================*

	local CopyProps = function(From, To, Props)
		for _, Prop in ipairs(Props) do
			pcall(function()
				local Value = From[Prop]
				if To[Prop] ~= Value then
					To[Prop] = Value
				end
			end)
		end
	end

	local MakeBlue = function(Button)
		pcall(function()
			if Button:IsA("ImageButton") and Button.Image ~= BlueButton then
				Button.Image = BlueButton
			end
		end)
	end

	local MatchLeaveToReset = function(Leave, Reset)

		CopyProps(Reset.page, Leave.page, { "Size" })

		CopyProps(Reset.question, Leave.question, {
			"AnchorPoint", "Position", "Size", "TextSize", "TextScaled", "TextWrapped",
			"TextXAlignment", "TextYAlignment",
		})

		for _, Pair in ipairs({ { Leave.confirm, Reset.confirm }, { Leave.cancel, Reset.cancel } }) do

			local Mine, Theirs = Pair[1], Pair[2]

			if Mine and Theirs then

				if Theirs.Parent == Reset.question and Mine.Parent ~= Leave.question then
					Mine.Parent = Leave.question
				elseif Theirs.Parent == Reset.page and Mine.Parent ~= Leave.page then
					Mine.Parent = Leave.page
				end

				CopyProps(Theirs, Mine, { "AnchorPoint", "Position", "Size" })

			end

		end

	end

	RunService.RenderStepped:Connect(function()

		-- PC
		if not (MOBILE_LAYOUT_LIKE_2021 and IsTouchDevice) then

			local Leave, Reset

			for _, Parts in pairs(Tracked) do

				if Parts.Kind == "leave" then
					Leave = Leave or Parts
				else
					Reset = Reset or Parts
				end

				if FIRST_BUTTON_BLUE then
					MakeBlue(Parts.confirm)
				end

			end

			if MATCH_LEAVE_TO_RESET and Leave and Reset then
				pcall(MatchLeaveToReset, Leave, Reset)
			end

			return

		end

		-- Touch screen: the page on screen gets the 2021 copy.
		local Shown

		for _, Parts in pairs(Tracked) do

			local OnScreen = false

			if not Shown then
				local Success, Result = pcall(IsOnScreen, Parts)
				OnScreen = Success and Result
			end

			if OnScreen then
				Shown = Parts
			else
				Restore(Parts)
			end

		end

		for Parts, Copy in pairs(Copies) do
			if Parts ~= Shown then
				SetIfDifferent(Copy.Holder, "Visible", false)
			end
		end

		if not Shown then
			SetIfDifferent(Overlay, "Enabled", false)
			return
		end

		if not Copies[Shown] then
			local Success, Copy = pcall(MakeCopy, Shown)
			if not Success then
				warn("[Legacy] couldn't build the 2021 " .. Shown.Kind .. " page:", Copy)
				return
			end
			Copies[Shown] = Copy
		end

		local Copy = Copies[Shown]

		SetIfDifferent(Overlay, "Enabled", true)

		local Success, Placed = pcall(LayOut, Shown, Copy)

		if not (Success and Placed) then
			SetIfDifferent(Copy.Holder, "Visible", false)
			Restore(Shown)
			return
		end

		SetIfDifferent(Copy.Holder, "Visible", true)
		SetIfDifferent(Overlay, "Enabled", true)

		if os.clock() >= ShowRealUntil then
			HideOriginals(Shown)
		else
			Restore(Shown)
		end

	end)

end)

-- Set by the 2017 chat notification bubble section below once it has
-- found the top bar's own unread counter; the chat icon's extra badge
-- then stays hidden so there is only one.
local NativeChatCounter = false

-- The 2017 chat notification badge, as on the 2017 top bar: a solid
-- red circle with a white bold number, a bit over half the width of
-- the chat icon, overlapping the icon's top-right corner. Sized and
-- placed as fractions of the icon, so it fits whatever size the icon
-- is drawn at.
-- Measured against the 2017 top bar on a phone, next to this one.
local Legacy2017Badge = {
	Color = Color3.fromRGB(246, 66, 74), -- read off the 2017 recording
	TextColor = Color3.new(1, 1, 1),
	Size = 0.478, -- of the icon's width
	CenterX = 0.902, -- of the icon's width, from its left edge
	CenterY = 0.16, -- of the icon's height, from its top edge
	TextHeight = 1.07, -- number box, of the circle (the number is ~55% of it)
	TextWidth = 0.86, -- room for "99+" before it shrinks
	TextCenterY = 0.39, -- the 2017 number sits a little above the middle

	-- The 2017 drop shadow (compared with the 2017 crop): not an outline
	-- but a wide, very soft halo that sits mostly underneath the circle
	-- and fades out about 7 px below it. Five stacked circles, each
	-- a little bigger and fainter: size (of the badge), see-through.
	ShadowLayers = {
		{ Size = 1.02, Transparency = 0.93 },
		{ Size = 1.06, Transparency = 0.94 },
		{ Size = 1.11, Transparency = 0.95 },
		{ Size = 1.17, Transparency = 0.96 },
		{ Size = 1.24, Transparency = 0.97 },
	},
	ShadowOffsetX = -0.02, -- of the badge's size
	ShadowOffsetY = 0.06,
}

local MakeLegacy2017Badge = function(Icon, Name)

	-- The badge is a see-through holder: showing, hiding and placing it
	-- moves the shadow and the red circle together.
	local Badge = Instance.new("Frame")

	Badge.Name = Name
	Badge.AnchorPoint = Vector2.new(0.5, 0.5)
	Badge.Position = UDim2.fromScale(Legacy2017Badge.CenterX, Legacy2017Badge.CenterY)
	Badge.Size = UDim2.fromScale(Legacy2017Badge.Size, Legacy2017Badge.Size)
	Badge.SizeConstraint = Enum.SizeConstraint.RelativeXX
	Badge.BackgroundTransparency = 1
	Badge.BorderSizePixel = 0
	Badge.Active = false
	Badge.Visible = false
	Badge.ZIndex = Icon.ZIndex + 10

	-- Drop shadow, underneath.
	for Index, Layer in ipairs(Legacy2017Badge.ShadowLayers) do

		local Shadow = Instance.new("Frame")

		Shadow.Name = "Shadow" .. Index
		Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		Shadow.Position = UDim2.fromScale(0.5 + Legacy2017Badge.ShadowOffsetX, 0.5 + Legacy2017Badge.ShadowOffsetY)
		Shadow.Size = UDim2.fromScale(Layer.Size, Layer.Size)
		Shadow.BackgroundColor3 = Color3.new(0, 0, 0)
		Shadow.BackgroundTransparency = Layer.Transparency
		Shadow.BorderSizePixel = 0
		Shadow.Active = false
		Shadow.ZIndex = Icon.ZIndex + 9

		local ShadowCorner = Instance.new("UICorner")
		ShadowCorner.CornerRadius = UDim.new(1, 0)
		ShadowCorner.Parent = Shadow

		Shadow.Parent = Badge

	end

	-- The red circle.
	local Face = Instance.new("Frame")

	Face.Name = "Face"
	Face.AnchorPoint = Vector2.new(0.5, 0.5)
	Face.Position = UDim2.fromScale(0.5, 0.5)
	Face.Size = UDim2.fromScale(1, 1)
	Face.BackgroundColor3 = Legacy2017Badge.Color
	Face.BackgroundTransparency = 0
	Face.BorderSizePixel = 0
	Face.Active = false
	Face.ZIndex = Icon.ZIndex + 10

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(1, 0)
	Corner.Parent = Face

	Face.Parent = Badge

	local Label = Instance.new("TextLabel")

	Label.Name = "Amount"
	Label.AnchorPoint = Vector2.new(0.5, 0.5)
	Label.Position = UDim2.fromScale(0.5, Legacy2017Badge.TextCenterY)
	Label.Size = UDim2.fromScale(Legacy2017Badge.TextWidth, Legacy2017Badge.TextHeight)
	Label.BackgroundTransparency = 1
	Label.Text = ""
	Label.TextColor3 = Legacy2017Badge.TextColor
	Label.TextStrokeTransparency = 1
	Label.Font = Enum.Font.SourceSansBold
	Label.TextScaled = true
	Label.TextXAlignment = Enum.TextXAlignment.Center
	Label.TextYAlignment = Enum.TextYAlignment.Center
	Label.ZIndex = Icon.ZIndex + 11
	Label.Parent = Face

	-- The badge hangs over the icon's edge: don't let anything crop it.
	local Ancestor = Icon

	while Ancestor and Ancestor:IsA("GuiObject") do

		pcall(function()
			Ancestor.ClipsDescendants = false
		end)

		Ancestor = Ancestor.Parent

	end

	Badge.Parent = Icon

	return Badge, Label

end

-- CHAT ICON
--
-- Uses the same stock Roblox chat textures as 2017-2019M_Topbar
-- (Chat.png / ChatDown.png) on the Legacy topbar chat button,
-- instead of the custom embedded speech-bubble PNG.

task.spawn(function()

	local chatOpenId = "rbxasset://textures/ui/Chat/Chat.png"
	local chatCloseId = "rbxasset://textures/ui/Chat/ChatDown.png"

	-- Find the top bar.
	local Container

	local StartTime = os.clock()

	while not Container and os.clock() - StartTime < 15 do

		local NewRobloxGui = CoreGui:FindFirstChild("NewRobloxGui")

		Container =
			NewRobloxGui
			and NewRobloxGui:FindFirstChild("TopBarContainer", true)

		if not Container and typeof(LegacyGui) == "Instance" then
			Container = LegacyGui:FindFirstChild("TopBarContainer", true)
		end

		Container = Container or CoreGui:FindFirstChild("TopBarContainer", true)

		if not Container then
			task.wait(0.25)
		end

	end

	if not Container then
		warn("[Legacy chat icon] TopBarContainer not found")
		return
	end

	-- Find the first chat button: the left-most top level object
	-- whose name starts with "Chat".
	local IsChat = function(Object)
		return Object:IsA("GuiObject") and Object.Name:lower():find("^chat") ~= nil
	end

	local FindFirstChat = function()

		local Chats = {}

		for _, Object in ipairs(Container:GetDescendants()) do

			if IsChat(Object) then

				local Inside = false
				local Parent = Object.Parent

				while Parent and Parent ~= Container do

					if IsChat(Parent) then
						Inside = true
						break
					end

					Parent = Parent.Parent

				end

				if not Inside then
					table.insert(Chats, Object)
				end

			end

		end

		table.sort(Chats, function(A, B)
			return A.AbsolutePosition.X < B.AbsolutePosition.X
		end)

		return Chats[1]

	end

	local Chat

	StartTime = os.clock()

	while not Chat and os.clock() - StartTime < 10 do

		Chat = FindFirstChat()

		if not Chat then
			task.wait(0.25)
		end

	end

	if not Chat then
		warn("[Legacy chat icon] chat button not found")
		return
	end

	-- The icon is the largest image on the chat button.
	local Icon
	local BestArea = 0

	local Candidates = Chat:GetDescendants()

	table.insert(Candidates, Chat)

	for _, Object in ipairs(Candidates) do

		if
			(Object:IsA("ImageLabel") or Object:IsA("ImageButton"))
			and Object.Image ~= ""
		then

			local Area = Object.AbsoluteSize.X * Object.AbsoluteSize.Y

			if Area > BestArea then
				Icon = Object
				BestArea = Area
			end

		end

	end

	if not Icon and (Chat:IsA("ImageLabel") or Chat:IsA("ImageButton")) then
		Icon = Chat
	end

	if not Icon then
		warn("[Legacy chat icon] no icon image found on", Chat:GetFullName())
		return
	end

	print("[Legacy chat icon] using 2017-2019M stock icon on:", Icon:GetFullName())

	-- Stock chat textures (same as 2017-2019M_Topbar)
	Set(Icon, {
		Image = chatOpenId,
		ImageRectOffset = Vector2.zero,
		ImageRectSize = Vector2.zero,
		ImageTransparency = 0,
		ScaleType = Enum.ScaleType.Fit,
	}, true)

	-- Closed = white, open / focused = blue
	local NormalColor = Color3.new(1, 1, 1)
	local OpenColor = Color3.fromRGB(0, 162, 255)

	-- Chat starts open with the welcome line, so icon starts blue
	local ChatOpen = true
	local LastToggle = 0

	--========================================================*
	-- UNREAD NOTIFICATION BADGE
	--========================================================*

	-- The 2017 red badge (see MakeLegacy2017Badge above). Only used
	-- when the top bar has no unread counter of its own; otherwise the
	-- 2017 chat notification bubble section draws it on that counter.

	local UnreadCount = 0

	for _, Object in ipairs(Chat:GetDescendants()) do

		if Object:IsA("GuiObject") and Object.Name:lower():find("badge") then
			Set(Object, { Visible = false }, true)
		end

	end

	local Badge, BadgeLabel = MakeLegacy2017Badge(Icon, "LegacyChatBadge")

	local UpdateBadge = function()

		if NativeChatCounter or ChatOpen or UnreadCount <= 0 then
			Badge.Visible = false
			return
		end

		Badge.Visible = true

		BadgeLabel.Text =
			UnreadCount >= 100 and "99+" or tostring(UnreadCount)

	end

	local OnMessage = function()

		if ChatOpen then
			return
		end

		UnreadCount = UnreadCount + 1

		UpdateBadge()

	end

	local UsingLegacyChat = false

	pcall(function()
		UsingLegacyChat =
			TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService
	end)

	if UsingLegacyChat then

		local Hook = function(Player)

			Player.Chatted:Connect(function()

				if Player ~= Players.LocalPlayer then
					OnMessage()
				end

			end)

		end

		for _, Player in ipairs(Players:GetPlayers()) do
			Hook(Player)
		end

		Players.PlayerAdded:Connect(Hook)

	else

		TextChatService.MessageReceived:Connect(function(Message)

			local Source = Message.TextSource

			if Source and Source.UserId == Players.LocalPlayer.UserId then
				return
			end

			OnMessage()

		end)

	end

	local Paint = function()
		-- Always use the same icon asset; only tint blue/white.
		-- Mixing ChatDown.png + blue tint caused the wrong blue shade.
		if Icon.Image ~= chatOpenId then
			Icon.Image = chatOpenId
		end
		local want = ChatOpen and OpenColor or NormalColor
		if Icon.ImageColor3 ~= want then
			Icon.ImageColor3 = want
		end
	end

	Paint()

	-- Do not re-Paint on every ImageColor3 change (causes wrong blue / feedback loops).
	-- Only re-assert the white/blue icon image if something else overwrites it.
	Icon:GetPropertyChangedSignal("Image"):Connect(function()
		if Icon.Image ~= chatOpenId then
			Icon.Image = chatOpenId
		end
	end)

	local SetState = function(IsOpen, Source)

		if IsOpen == ChatOpen then
			return
		end

		ChatOpen = IsOpen

		print("[Legacy chat icon] chat open:", IsOpen, Source)

		Paint()

		if IsOpen then
			UnreadCount = 0
		end

		UpdateBadge()

	end

	local Toggle = function(Source)

		if os.clock() - LastToggle < 0.25 then
			return
		end

		LastToggle = os.clock()

		SetState(not ChatOpen, Source)

	end

	-- Follow the chat itself when possible. Guessing from presses on
	-- the button drifts: a press that starts on the button's padding
	-- or slides off it, or a tap held past the toggle debounce, flips
	-- the icon without the chat opening or closing, leaving it white
	-- while the chat is open. The chat module knows whether its window
	-- is shown and whether its bar is focused, so read that instead.
	local ChatModule

	pcall(function()

		local NewRobloxGui = CoreGui:FindFirstChild("NewRobloxGui")
		local Modules = NewRobloxGui and NewRobloxGui:FindFirstChild("Modules")
		local ChatScript = Modules and Modules:FindFirstChild("Chat")

		if ChatScript then

			local Result = Suite.require(ChatScript)

			if typeof(Result) == "table" and Result.GetVisibility then
				ChatModule = Result
			end

		end

	end)

	if ChatModule then

		local Sync = function(Source)

			local Success, IsOpen = pcall(function()

				local Focused = false

				pcall(function()
					Focused = ChatModule:IsFocused() == true
				end)

				return ChatModule:GetVisibility() == true or Focused

			end)

			if Success then
				SetState(IsOpen, Source)
			end

		end

		for _, Name in ipairs({ "VisibilityStateChanged", "ChatBarFocusChanged" }) do

			local Signal = ChatModule[Name]

			if Signal then

				pcall(function()
					Signal:connect(function()
						task.defer(Sync, Name)
					end)
				end)

			end

		end

		Sync("init")

		-- In case a change happens without a signal.
		task.spawn(function()

			while Icon.Parent do

				Sync("poll")

				task.wait(0.2)

			end

		end)

		return

	end

	warn("[Legacy chat icon] chat module not found, guessing state from clicks")

	for _, Object in ipairs(Chat:GetDescendants()) do

		if Object:IsA("GuiButton") then

			Object.Activated:Connect(function()
				Toggle("click")
			end)

		end

	end

	if Chat:IsA("GuiButton") then

		Chat.Activated:Connect(function()
			Toggle("click")
		end)

	end

	Chat.InputBegan:Connect(function(Input)

		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Toggle("input")
		end

	end)

	-- Slash focuses the chat bar: always show open (blue) icon.
	-- Do not require not GameProcessed; focusing the bar often sets it.
	UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if Input.KeyCode == Enum.KeyCode.Slash then
			SetState(true, "slash")
		end
	end)

	-- Also blue while the chat bar TextBox is focused; white when unfocused
	-- if the chat window itself is not considered open.
	task.spawn(function()
		while Icon.Parent do
			local box = UserInputService:GetFocusedTextBox()
			if box then
				local name = string.lower(box.Name or "")
				local parentName = box.Parent and string.lower(box.Parent.Name or "") or ""
				if name:find("chat") or parentName:find("chat") or name:find("input") then
					if not ChatOpen then
						SetState(true, "textbox")
					end
				end
			end
			task.wait(0.15)
		end
	end)

	local GetChatWindow = function()

		local Roots = { CoreGui, Players.LocalPlayer:FindFirstChild("PlayerGui") }

		if typeof(LegacyGui) == "Instance" then
			table.insert(Roots, LegacyGui)
		end

		for _, Root in ipairs(Roots) do

			local Window = Root:FindFirstChild("Chat")

			if
				Window
				and Window ~= Chat
				and not Window:IsDescendantOf(Container)
				and not Container:IsDescendantOf(Window)
			then
				return Window
			end

		end

	end

	local IsWindowOpen = function(Window)

		if Window:IsA("ScreenGui") then
			return Window.Enabled
		elseif Window:IsA("GuiObject") then
			return Window.Visible
		elseif Window:FindFirstChild("Frame") then
			return Window.Frame.Visible
		end

	end

	-- Chat usually starts open with the welcome message: keep icon blue.
	-- Still resync if we can detect the window.
	task.defer(function()
		SetState(true, "init-default")
		for _ = 1, 30 do
			local Window = GetChatWindow()
			if Window ~= nil then
				local open = IsWindowOpen(Window)
				if open then
					SetState(true, "init")
				end
				-- Do not force closed on init; welcome message means chat is active
				break
			end
			task.wait(0.1)
		end
	end)

	task.spawn(function()

		local LastPolled

		while Icon.Parent do

			local Window = GetChatWindow()
			local Polled = Window and IsWindowOpen(Window)

			if Polled ~= nil and Polled ~= LastPolled then

				SetState(Polled, "window")

				LastPolled = Polled

			end

			task.wait(0.25)

		end

	end)

end)


-- 2017 CHAT NOTIFICATION BUBBLE
--
-- The 2019 top bar has its own unread counter on the chat button, and
-- it looks off. It is replaced by the 2017 badge (MakeLegacy2017Badge
-- above: solid red circle, white bold number, over the icon's top-right
-- corner). The top bar keeps counting and deciding when it shows; the
-- 2017 badge shows the same number at the same moments, and the 2019
-- counter itself is no longer drawn. While it exists, the chat icon
-- section's own badge stays hidden so there is only one.
--
-- The counter is found by what it shows: a small label with a number
-- on (or next to) a chat button.

task.spawn(function()

	local OurNames = {
		LegacyChatBadge = true,
		Legacy2017Bubble = true,
	}

	local IsOurs = function(Object)

		local Current = Object

		while Current do

			if OurNames[Current.Name] then
				return true
			end

			Current = Current.Parent

		end

		return false

	end

	local FindContainer = function()

		local NewRobloxGui = CoreGui:FindFirstChild("NewRobloxGui")

		local Container =
			NewRobloxGui
			and NewRobloxGui:FindFirstChild("TopBarContainer", true)

		if not Container and typeof(LegacyGui) == "Instance" then
			Container = LegacyGui:FindFirstChild("TopBarContainer", true)
		end

		return Container or CoreGui:FindFirstChild("TopBarContainer", true)

	end

	local Container

	local StartTime = os.clock()

	while not Container and os.clock() - StartTime < 20 do

		Container = FindContainer()

		if not Container then
			task.wait(0.25)
		end

	end

	if not Container then
		warn("[Legacy chat bubble] TopBarContainer not found")
		return
	end

	local IsCount = function(Text)
		return type(Text) == "string"
			and (Text:match("^%d+%+?$") ~= nil or Text == "!")
	end

	-- Chat buttons: objects whose name starts with "Chat".
	local ChatButtons = function()

		local List = {}

		for _, Object in ipairs(Container:GetDescendants()) do

			if
				Object:IsA("GuiObject")
				and Object.Name:lower():find("^chat")
				and not IsOurs(Object)
			then
				table.insert(List, Object)
			end

		end

		return List

	end

	local NearChat = function(Label, Chats)

		local Center = Label.AbsolutePosition + Label.AbsoluteSize / 2

		for _, Chat in ipairs(Chats) do

			local Position, Size = Chat.AbsolutePosition, Chat.AbsoluteSize

			if
				Size.X > 0
				and Center.X >= Position.X - 24
				and Center.X <= Position.X + Size.X + 24
				and Center.Y >= Position.Y - 24
				and Center.Y <= Position.Y + Size.Y + 24
			then
				return true
			end

		end

		return false

	end

	local SetIfDifferent = function(Object, Property, Value)
		pcall(function()
			if Object[Property] ~= Value then
				Object[Property] = Value
			end
		end)
	end

	-- The small frame / image the number sits on (never the chat icon).
	local LooksLikeCounter = function(Object)

		if not (Object and Object:IsA("GuiObject")) then
			return false
		end

		local Name = Object.Name:lower()

		if Name:find("counter") or Name:find("badge") or Name:find("unread") or Name:find("notif") then
			return true
		end

		if Name:find("chat") or Name:find("icon") then
			return false
		end

		if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then

			local Image = Object.Image:lower()

			if Image:find("counter") or Image:find("badge") then
				return true
			end

			if Image:find("chat") then
				return false
			end

		end

		local Size = Object.AbsoluteSize

		return Size.X > 0 and Size.X <= 26 and Size.Y <= 26

	end

	-- The chat icon the counter belongs to: the first image above it
	-- that is bigger than it.
	local FindIcon = function(Counter)

		local Current = Counter.Parent

		while Current and Current ~= Container and Current:IsA("GuiObject") do

			if
				(Current:IsA("ImageLabel") or Current:IsA("ImageButton"))
				and Current.Image ~= ""
				and Current.AbsoluteSize.X > Counter.AbsoluteSize.X * 1.2
			then
				return Current
			end

			Current = Current.Parent

		end

		local Parent = Counter.Parent

		return Parent and Parent:IsA("GuiObject") and Parent or nil

	end

	local HideOurBadge = function()

		for _, Object in ipairs(Container:GetDescendants()) do

			if Object.Name == "LegacyChatBadge" and Object:IsA("GuiObject") then
				SetIfDifferent(Object, "Visible", false)
			end

		end

	end

	-- One entry per 2019 counter: { Counter, Label, Icon, Badge, BadgeLabel }
	local Replaced = {}
	local Known = setmetatable({}, { __mode = "k" })

	local Replace = function(Label)

		local Counter = LooksLikeCounter(Label.Parent) and Label.Parent or Label

		if Known[Counter] then
			return
		end

		local Icon = FindIcon(Counter)

		if not Icon then
			return
		end

		Known[Counter] = true

		local Badge, BadgeLabel = MakeLegacy2017Badge(Icon, "Legacy2017Bubble")

		table.insert(Replaced, {
			Counter = Counter,
			Label = Label,
			Icon = Icon,
			Badge = Badge,
			BadgeLabel = BadgeLabel,
		})

		NativeChatCounter = true

		HideOurBadge()

		print("[Legacy chat bubble] 2017 badge on:", Icon:GetFullName(), "for", Counter:GetFullName())

	end

	-- Look for counters a few times a second (the top bar can build
	-- or rebuild one at any time).
	task.spawn(function()

		while Container.Parent do

			pcall(function()

				local Chats = ChatButtons()

				for _, Object in ipairs(Container:GetDescendants()) do

					if
						(Object:IsA("TextLabel") or Object:IsA("TextButton"))
						and not IsOurs(Object)
						and IsCount(Object.Text)
						and Object.AbsoluteSize.Y <= 30
						and NearChat(Object, Chats)
					then
						Replace(Object)
					end

				end

			end)

			task.wait(0.25)

		end

	end)

	-- Shown when the 2019 counter would be: it and everything between
	-- it and the icon visible, with a number above 0.
	local IsShown = function(Entry)

		local Text = Entry.Label.Text

		if not IsCount(Text) or Text == "0" then
			return false
		end

		local Current = Entry.Label

		while Current and Current ~= Entry.Icon do

			if Current:IsA("GuiObject") and not Current.Visible then
				return false
			end

			Current = Current.Parent

		end

		return true

	end

	-- Every frame: the 2019 counter stays invisible and the 2017 badge
	-- follows it.
	RunService.RenderStepped:Connect(function()

		local Index = 1

		while Index <= #Replaced do

			local Entry = Replaced[Index]
			local Counter, Label, Badge = Entry.Counter, Entry.Label, Entry.Badge

			if not (Counter.Parent and Label.Parent and Badge.Parent) then

				pcall(function()
					Badge:Destroy()
				end)

				Known[Counter] = nil

				table.remove(Replaced, Index)

				continue

			end

			-- The 2019 counter: nothing of it drawn.
			for _, Object in ipairs({ Counter, table.unpack(Counter:GetDescendants()) }) do

				if Object:IsA("GuiObject") then
					SetIfDifferent(Object, "BackgroundTransparency", 1)
				end

				if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
					SetIfDifferent(Object, "ImageTransparency", 1)
				elseif Object:IsA("TextLabel") or Object:IsA("TextButton") then
					SetIfDifferent(Object, "TextTransparency", 1)
					SetIfDifferent(Object, "TextStrokeTransparency", 1)
				elseif Object:IsA("UIStroke") then
					SetIfDifferent(Object, "Enabled", false)
				end

			end

			-- The 2017 badge.
			local Shown = IsShown(Entry)

			SetIfDifferent(Badge, "Visible", Shown)

			if Shown then
				SetIfDifferent(Entry.BadgeLabel, "Text", Label.Text)
			end

			SetIfDifferent(Badge, "ZIndex", Entry.Icon.ZIndex + 10)
			SetIfDifferent(Entry.BadgeLabel, "ZIndex", Entry.Icon.ZIndex + 11)

			Index = Index + 1

		end

	end)

end)

-- CHAT HISTORY
--
-- The legacy chat only keeps the last 60 messages per channel, so
-- you can't scroll back far. This raises that limit.

task.spawn(function()

	-- How many messages to keep per channel.
	local HistoryLength = 1000

	local Roots = {
		game:GetService("Chat"),
		CoreGui,
		Players.LocalPlayer:WaitForChild("PlayerGui"),
	}

	if typeof(LegacyGui) == "Instance" then
		table.insert(Roots, LegacyGui)
	end

	local Patched = {}

	local Apply = function()

		for _, Root in ipairs(Roots) do

			for _, Object in ipairs(Root:GetDescendants()) do

				if
					Object:IsA("ModuleScript")
					and Object.Name == "ChatSettings"
					and not Patched[Object]
				then

					local Success, Settings = pcall(require, Object)

					if Success and typeof(Settings) == "table" then

						Settings.MessageHistoryLengthPerChannel = HistoryLength

						Patched[Object] = true

						print(
							"[Legacy chat history] limit raised:",
							Object:GetFullName()
						)

					end

				end

			end

		end

	end

	-- The chat can load after this script, so keep looking for a while.
	for _ = 1, 30 do

		pcall(Apply)

		task.wait(2)

	end

	if next(Patched) == nil then
		warn("[Legacy chat history] no ChatSettings module found")
	end

end)


-- CHAT AUTO SCROLL
--
-- Scrolls the chat window to the newest message whenever
-- someone chats, even if you had scrolled up.

task.spawn(function()

	local Roots = {
		CoreGui,
		Players.LocalPlayer:WaitForChild("PlayerGui"),
	}

	if typeof(LegacyGui) == "Instance" then
		table.insert(Roots, LegacyGui)
	end

	local Hooked = {}

	local ScrollToBottom = function(Scroller)

		if not Scroller.Parent then
			return
		end

		local Bottom = Scroller.AbsoluteCanvasSize.Y - Scroller.AbsoluteWindowSize.Y

		Scroller.CanvasPosition = Vector2.new(
			Scroller.CanvasPosition.X,
			math.max(0, Bottom)
		)

	end

	local IsChatScroller = function(Object)

		return
			Object:IsA("ScrollingFrame")
			and (
				Object.Name == "Scroller"
				or Object:FindFirstAncestor("Frame_MessageLogDisplay") ~= nil
				or Object:FindFirstAncestor("ChatChannelParentFrame") ~= nil
			)

	end

	local Hook = function(Scroller)

		Hooked[Scroller] = true

		print("[Legacy chat scroll] hooked:", Scroller:GetFullName())

		-- A new message makes the canvas taller.
		Scroller:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()

			task.defer(ScrollToBottom, Scroller)

		end)

		Scroller.ChildAdded:Connect(function()

			task.defer(ScrollToBottom, Scroller)

		end)

		ScrollToBottom(Scroller)

	end

	-- Chat windows get created and recreated, so keep looking.
	task.spawn(function()

		while true do

			for _, Root in ipairs(Roots) do

				for _, Object in ipairs(Root:GetDescendants()) do

					if not Hooked[Object] and IsChatScroller(Object) then
						pcall(Hook, Object)
					end

				end

			end

			task.wait(1)

		end

	end)

	-- Also nudge every chat window when a message comes in.
	pcall(function()

		TextChatService.MessageReceived:Connect(function()

			task.delay(0.1, function()

				for Scroller in next, Hooked do
					pcall(ScrollToBottom, Scroller)
				end

			end)

		end)

	end)

end)