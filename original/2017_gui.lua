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

local RobloxGui = CoreGui:WaitForChild("RobloxGui")

local ExperienceChat = CoreGui:WaitForChild("ExperienceChat")

local ChatBubbles = ExperienceChat:WaitForChild("bubbleChat")

local IsTouchDevice = UserInputService.TouchEnabled

-- Types

export type Properties = { [string]: any }

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

ExperienceChat.Enabled = false

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
		-- â””â”€ BlackFrame
		--    â”œâ”€ GraphicsFrame
		--    â”‚  â””â”€ LoadingImage
		--    â”‚
		--    â””â”€ InfoFrame
		--       â”œâ”€ UiMessageFrame
		--       â”‚  â””â”€ UiMessage
		--       â”œâ”€ CreatorLabel
		--       â”œâ”€ PlaceLabel
		--       â””â”€ PlaceIcon
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

		-- Use the 2017â€“2022 tilted Roblox icon
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
				"letsafe/something@v1.0.0",
				"Legacy2017.rbxm"
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

-- Setup

local LegacyGui =
	Suite.require(Legacy):Start(
		Settings.Year,
		Settings.SafeChat
	)

RobloxGui.Enabled = false

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

	pcall(function()
		ExperienceChat.Enabled = false
	end)

	pcall(function()
		TextChatService.BubbleChatConfiguration.Enabled = false
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

	local BubbleFont =
		Font.fromEnum(
			Enum.Font.SourceSans
		)

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

-- PLAYERS PAGE BUTTONS
--
-- Report flags:
--
--	* The legacy Players page adds a new flag to each row every time
--	  the page is shown and never removes the old one. The stacked
--	  copies make the flag look darker and darker, and every copy
--	  keeps reacting while the page animates, which makes the menu
--	  lag more each time it opens. Only one flag per row is kept.
--
--	* The flag's own handler does nothing. Tapping it now switches to
--	  the Report tab, sets "Game or Player?" to Player and picks that
--	  player, firing each button's click handler exactly once.
--
--	* Your own row has no flag, since you can't report yourself. It
--	  stays hidden when the menu reopens or the tab changes.
--
-- "Add Friend" falls back to the friend request prompt when the
-- legacy button didn't send a request.
--
-- The Report tab's dropdowns ("Which Player?", "Type Of Abuse") and
-- the entries in their lists go back from blue to grey when you let
-- go, like in 2017.

task.spawn(function()

	local Hooked = setmetatable({}, { __mode = "k" })

	local LocalPlayer = Players.LocalPlayer

	local Busy = false

	local GetText = function(Object: Instance)

		if Object:IsA("TextLabel") or Object:IsA("TextButton") then
			return Object.Text
		end

		return nil

	end

	local HasText = function(Object: Instance, Text: string)

		if GetText(Object) == Text then
			return true
		end

		for _, Descendant in ipairs(Object:GetDescendants()) do

			if GetText(Descendant) == Text then
				return true
			end

		end

		return false

	end

	-- The text a button shows itself, ignoring anything nested deeper.

	local OwnText = function(Button: GuiButton)

		if Button:IsA("TextButton") and Button.Text ~= "" then
			return Button.Text
		end

		local Label = Button:FindFirstChildWhichIsA("TextLabel")

		return Label and Label.Text or nil

	end

	local IsShown = function(Object: Instance)

		local Current = Object

		while Current and Current ~= LegacyGui do

			if Current:IsA("GuiObject") and not Current.Visible then
				return false
			end

			Current = Current.Parent

		end

		return Current == LegacyGui

	end

	local Notify = function(Text: string)

		pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = "Report",
				Text = Text,
				Duration = 5
			})
		end)

	end

	-- Player rows show the player's name (or display name)
	-- somewhere inside the row frame. Only look two levels up so
	-- buttons on other pages are never mistaken for a player row.

	local FindRowPlayer = function(Button: GuiButton)

		local Row = Button.Parent

		for _ = 1, 2 do

			if not Row or Row == LegacyGui then
				return nil
			end

			-- Exact labels first so "Bob" never claims "Bob2"'s row.

			for _, Player in ipairs(Players:GetPlayers()) do

				if
					HasText(Row, Player.Name)
					or HasText(Row, Player.DisplayName)
					or HasText(Row, "@" .. Player.Name)
				then
					return Player, Row
				end

			end

			for _, Player in ipairs(Players:GetPlayers()) do

				if Row.Name:find(Player.Name, 1, true) then
					return Player, Row
				end

			end

			Row = Row.Parent

		end

		return nil

	end

	-- Only buttons on the escape menu's Players page count. That page
	-- holds the "Leave Game" button. The top bar also shows your name
	-- (next to "Account: 13+") but must never be touched.

	local IsOnPlayersPage = function(Button: GuiButton)

		local Current = Button.Parent

		for _ = 1, 4 do

			if not Current or Current == LegacyGui then
				return false
			end

			if Current.Name:lower():find("topbar") then
				return false
			end

			for _, Descendant in ipairs(Current:GetDescendants()) do

				local Text = GetText(Descendant)

				if Text and Text:sub(1, 8) == "Account:" then
					return false
				end

			end

			if HasText(Current, "Leave Game") then
				return true
			end

			Current = Current.Parent

		end

		return false

	end

	-- The flag is the only icon-only button in a player row.

	local IsFlag = function(Object: GuiButton)

		if Object.Name:lower():find("tab") then
			return false
		end

		if Object:IsA("TextButton") and Object.Text ~= "" then
			return false
		end

		for _, Descendant in ipairs(Object:GetDescendants()) do

			local Text = GetText(Descendant)

			if Text and Text ~= "" then
				return false
			end

		end

		return Object.Name:lower():find("report") ~= nil
			or Object:IsA("ImageButton")
			or Object:FindFirstChildWhichIsA("ImageLabel") ~= nil

	end

	-- Stacked copies

	local RemoveDuplicateIcons = function(Flag: GuiButton)

		local Seen = {}

		for _, Child in ipairs(Flag:GetChildren()) do

			if Child:IsA("ImageLabel") then

				local Key = Child.Name .. "|" .. Child.Image

				if Seen[Key] then
					Seen[Key]:Destroy()
				end

				Seen[Key] = Child

			end

		end

	end

	-- Called on the newest flag in a row; older copies go.

	local RemoveDuplicateFlags = function(Flag: GuiButton)

		local Row = Flag.Parent

		if not Row then
			return
		end

		for _, Sibling in ipairs(Row:GetChildren()) do

			if
				Sibling ~= Flag
				and Sibling:IsA("GuiButton")
				and (
					Sibling.Name == Flag.Name
					or (Sibling.Position == Flag.Position and Sibling.Size == Flag.Size)
				)
				and IsFlag(Sibling)
			then
				Sibling:Destroy()
			end

		end

		RemoveDuplicateIcons(Flag)

	end

	-- Own row
	--
	-- You can't report yourself, so your own row has no flag. The menu
	-- shows flags again when the page reopens or the tab changes and
	-- can fill rows in after the flag, so check again whenever the flag
	-- is shown or the row's text changes.

	local HiddenOwn = setmetatable({}, { __mode = "k" })

	local WatchOwnFlag = function(Flag: GuiButton)

		local Update = function()

			if not Flag.Parent then
				return
			end

			local Player = FindRowPlayer(Flag)

			if Player == LocalPlayer then

				if Flag.Visible then
					HiddenOwn[Flag] = true
					Flag.Visible = false
				end

			elseif Player and HiddenOwn[Flag] then

				-- The row now belongs to someone else.

				HiddenOwn[Flag] = nil
				Flag.Visible = true

			end

		end

		-- Again at the end of the frame, in case the menu changes the
		-- row right after.

		local Check = function()
			Update()
			task.defer(Update)
		end

		local Connections = {}

		local WatchText = function(Object: Instance)

			if Object:IsA("TextLabel") or Object:IsA("TextButton") then
				table.insert(Connections, Object:GetPropertyChangedSignal("Text"):Connect(Check))
			end

		end

		table.insert(Connections, Flag:GetPropertyChangedSignal("Visible"):Connect(Check))

		table.insert(Connections, Flag.AncestryChanged:Connect(Check))

		local _, Row = FindRowPlayer(Flag)

		if Row then

			for _, Descendant in ipairs(Row:GetDescendants()) do
				WatchText(Descendant)
			end

			table.insert(Connections, Row.DescendantAdded:Connect(function(Descendant)
				WatchText(Descendant)
				Check()
			end))

		end

		Flag.Destroying:Connect(function()

			for _, Connection in ipairs(Connections) do
				Connection:Disconnect()
			end

		end)

		Check()

	end

	-- Pressed look
	--
	-- In 2017 a dropdown (and each entry in its list) turned blue only
	-- while your finger was on it and went back to grey when you let
	-- go. The port leaves it blue: it keeps the dropdown "selected" (a
	-- gamepad highlight that means nothing on a touch screen) and the
	-- finger lifting isn't always noticed. So:
	--
	--	* drop that selection when it lands on one of these buttons
	--	  while you're using touch,
	--	* put the normal image back when a touch on the button ends, and
	--	* on touch, put it back whenever it turns blue while nothing is
	--	  pressing it.
	--
	-- Only the image and its tint are restored; greyed-out states use
	-- transparency and are left alone.

	local GuiService = game:GetService("GuiService")

	local NormalLooks = setmetatable({}, { __mode = "k" })

	local Pressed = setmetatable({}, { __mode = "k" })

	local LookProperties = { "Image", "ImageColor3" }

	local IsPointer = function(Input: InputObject)

		return Input.UserInputType == Enum.UserInputType.Touch
			or Input.UserInputType == Enum.UserInputType.MouseButton1

	end

	local UsingTouch = function()
		return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
	end

	local Restore = function(Button: GuiButton)

		local Look = NormalLooks[Button]

		if not Look or Pressed[Button] or not Button.Parent then
			return
		end

		for _, Entry in ipairs(Look) do

			local Object, Property, Value = Entry[1], Entry[2], Entry[3]

			if Object.Parent and Object[Property] ~= Value then
				Object[Property] = Value
			end

		end

	end

	local RestoreSoon = function(Button: GuiButton)
		task.delay(0.1, Restore, Button)
		task.delay(0.5, Restore, Button)
	end

	local SaveLook = function(Button: GuiButton)

		local Look = {}

		for _, Object in ipairs({ Button, table.unpack(Button:GetChildren()) }) do

			if Object == Button or Object:IsA("ImageLabel") then

				for _, Property in ipairs(LookProperties) do

					local Success, Value = pcall(function()
						return Object[Property]
					end)

					if Success then

						table.insert(Look, { Object, Property, Value })

						Object:GetPropertyChangedSignal(Property):Connect(function()

							if not Pressed[Button] and UsingTouch() then
								RestoreSoon(Button)
							end

						end)

					end

				end

			end

		end

		NormalLooks[Button] = Look

		Button.InputBegan:Connect(function(Input)

			if not IsPointer(Input) then
				return
			end

			local Token = {}

			Pressed[Button] = Token

			-- In case the lift is never reported.

			task.delay(3, function()

				if Pressed[Button] == Token then
					Pressed[Button] = nil
					Restore(Button)
				end

			end)

		end)

		Button.InputEnded:Connect(function(Input)

			if IsPointer(Input) then
				Pressed[Button] = nil
				RestoreSoon(Button)
			end

		end)

		Button.MouseLeave:Connect(function()
			Pressed[Button] = nil
			RestoreSoon(Button)
		end)

	end

	UserInputService.InputEnded:Connect(function(Input)

		if not IsPointer(Input) then
			return
		end

		for Button in pairs(NormalLooks) do
			Pressed[Button] = nil
			RestoreSoon(Button)
		end

	end)

	pcall(function()

		GuiService:GetPropertyChangedSignal("SelectedCoreObject"):Connect(function()

			local Selected = GuiService.SelectedCoreObject

			if not Selected or not NormalLooks[Selected] or not UsingTouch() then
				return
			end

			task.defer(function()

				pcall(function()

					if GuiService.SelectedCoreObject == Selected then
						GuiService.SelectedCoreObject = nil
					end

				end)

				RestoreSoon(Selected)

			end)

		end)

	end)

	-- Run a button's own click handler once, like a single tap.

	local Click = function(Button: GuiButton)

		for _, Signal in ipairs({ "MouseButton1Click", "Activated" }) do

			local Fired = false

			if getconnections then

				pcall(function()

					for _, Connection in ipairs(getconnections(Button[Signal])) do

						if Connection.Function then

							task.spawn(Connection.Function)

							Fired = true

						end

					end

				end)

			elseif firesignal then

				Fired = pcall(firesignal, Button[Signal])

			end

			if Fired then
				return true
			end

		end

		return false

	end

	local FindReportTab = function()

		local Fallback = nil

		for _, Object in ipairs(LegacyGui:GetDescendants()) do

			if Object:IsA("GuiButton") then

				local Name = Object.Name:lower()

				if Name:find("report") and Name:find("tab") then
					return Object
				end

				if not Fallback and HasText(Object, "Report") and Object.Parent then

					for _, Sibling in ipairs(Object.Parent:GetChildren()) do

						if Sibling ~= Object and Sibling:IsA("GuiButton") and HasText(Sibling, "Players") then
							Fallback = Object
							break
						end

					end

				end

			end

		end

		return Fallback

	end

	-- The settings row that owns a label such as "Game or Player?".

	local WaitForRow = function(LabelText: string, Timeout: number)

		local Start = os.clock()

		repeat

			for _, Object in ipairs(LegacyGui:GetDescendants()) do

				if GetText(Object) == LabelText and IsShown(Object) then
					return Object.Parent
				end

			end

			task.wait(0.05)

		until os.clock() - Start > Timeout

		return nil

	end

	local SelectPlayerMode = function(Row: Instance)

		local Current = nil

		for _, Object in ipairs(Row:GetDescendants()) do

			local Text = GetText(Object)

			if (Text == "Game" or Text == "Player") and IsShown(Object) then

				local Parent = Object.Parent

				if Parent and Parent:IsA("GuiObject") then

					local Center = Object.AbsolutePosition.X + Object.AbsoluteSize.X / 2

					local Left = Parent.AbsolutePosition.X

					if Center >= Left and Center <= Left + Parent.AbsoluteSize.X then
						Current = Text
					end

				end

			end

		end

		if Current ~= "Game" then
			return
		end

		local Right = Row:FindFirstChild("RightButton", true)

		if Right and Right:IsA("GuiButton") then
			Click(Right)
		end

	end

	-- Pick the player's entry in the "Which Player?" list directly,
	-- without opening the list.

	local SelectPlayer = function(Player: Player)

		for _, Object in ipairs(LegacyGui:GetDescendants()) do

			if Object:IsA("GuiButton") and OwnText(Object) == Player.Name then

				local Current = Object.Parent

				while Current and Current ~= LegacyGui do

					if Current.Name:lower():find("dropdown") then
						Click(Object)
						return
					end

					Current = Current.Parent

				end

			end

		end

	end

	local Report = function(Player: Player)

		if Busy then
			return
		end

		Busy = true

		local Success = pcall(function()

			local Tab = FindReportTab()

			if not Tab or not Click(Tab) then
				error("report tab unavailable")
			end

			-- Let the page finish sliding in before touching it.

			task.wait(0.35)

			local ModeRow = WaitForRow("Game or Player?", 1)

			if not ModeRow then
				return
			end

			SelectPlayerMode(ModeRow)

			task.wait(0.25)

			SelectPlayer(Player)

		end)

		if not Success then
			Notify(`Open the Report tab to report {Player.Name}`)
		end

		task.delay(0.5, function()
			Busy = false
		end)

	end

	-- Add Friend fallback

	local SendFriendRequest = function(Button: GuiButton, Player: Player)

		-- Give the legacy handler a chance first; it relabels the
		-- button once the request goes out.

		task.wait(1)

		if not HasText(Button, "Add Friend") or Player.Parent ~= Players then
			return
		end

		local Success = pcall(function()
			LocalPlayer:RequestFriendship(Player)
		end)

		if not Success then

			pcall(function()
				StarterGui:SetCore("PromptSendFriendRequest", Player)
			end)

		end

	end

	local Hook = function(Object: Instance)

		if Hooked[Object] or not Object:IsA("GuiButton") then
			return
		end

		-- Buttons and rows can be filled in after they are parented.

		task.defer(function()

			if Hooked[Object] or not (IsFlag(Object) or HasText(Object, "Add Friend")) then
				return
			end

			for _ = 1, 10 do

				if Hooked[Object] or not Object.Parent or FindRowPlayer(Object) then
					break
				end

				task.wait(0.1)

			end

			if
				Hooked[Object]
				or not Object.Parent
				or not FindRowPlayer(Object)
				or not IsOnPlayersPage(Object)
			then
				return
			end

			local Flag = IsFlag(Object)

			if not Flag and not HasText(Object, "Add Friend") then
				return
			end

			Hooked[Object] = true

			if Flag then

				RemoveDuplicateFlags(Object)

				Object.ChildAdded:Connect(function()
					task.defer(RemoveDuplicateIcons, Object)
				end)

				WatchOwnFlag(Object)

			end

			Object.Activated:Connect(function()

				local Player = FindRowPlayer(Object)

				if not Player or Player.Parent ~= Players or Player == LocalPlayer then
					return
				end

				if Flag then
					Report(Player)
				else
					SendFriendRequest(Object, Player)
				end

			end)

		end)

	end

	-- Dropdowns and their list entries are named after (or sit inside)
	-- the dropdown's frames and show text.

	local HookListEntry = function(Object: Instance)

		if NormalLooks[Object] or not Object:IsA("GuiButton") then
			return
		end

		-- Saved once the entry is built, before anyone touches it.

		task.defer(function()

			local Text = Object.Parent and OwnText(Object)

			if NormalLooks[Object] or not Text or Text == "" then
				return
			end

			-- An untouched dropdown still says "Choose One".

			if Text == "Choose One" then
				SaveLook(Object)
				return
			end

			local Current = Object

			while Current and Current ~= LegacyGui do

				if Current.Name:lower():find("dropdown") then
					SaveLook(Object)
					return
				end

				Current = Current.Parent

			end

		end)

	end

	for _, Object in ipairs(LegacyGui:GetDescendants()) do
		Hook(Object)
		HookListEntry(Object)
	end

	LegacyGui.DescendantAdded:Connect(function(Object)
		Hook(Object)
		HookListEntry(Object)
	end)

end)

-- MOBILE CHAT "..." BUTTON
--
-- On a touch device the top bar has two chat buttons: the eye opens
-- and closes the chat window, and "..." is for typing. The port made
-- "..." a keyboard-only bar that never showed the chat window (and
-- closed the window if it was open).
--
-- Now "..." works like it did in 2017:
--
--	* With the window closed, "..." opens it and starts typing, so the
--	  eye and "..." both turn blue.
--	* With the window open, "..." just starts typing in it.
--	* When you stop typing, "..." goes back to white and the window
--	  stays open with the eye still blue. Tap the eye to close it.

task.spawn(function()

	if not IsTouchDevice then
		return
	end

	local Modules = LegacyGui:WaitForChild("Modules", 10)

	local ChatScript = Modules and Modules:WaitForChild("Chat", 10)

	if not ChatScript then
		return
	end

	local Success, ChatModule = pcall(Suite.require, ChatScript)

	if
		not Success
		or type(ChatModule) ~= "table"
		or type(ChatModule.FocusChatBarFromMobileEllipsis) ~= "function"
	then
		return
	end

	ChatModule.FocusChatBarFromMobileEllipsis = function(self)

		-- Showing the window also turns off the keyboard-only bar, so
		-- the focus below types into the window's own chat bar.

		if not self:GetVisibility() then
			self:SetVisible(true)
		end

		self:FocusChatBar()

	end

end)