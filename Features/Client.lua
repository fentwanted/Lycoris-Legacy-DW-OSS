-- vsc qol
local getgenv = getgenv
local Toggles = Toggles

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = cloneref(game:GetService("Players"))
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local MemStorageService = game:GetService("MemStorageService")
local VIM = Instance.new("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Mouse = cloneref(LocalPlayer):GetMouse()
local Camera = workspace.CurrentCamera
Mouse.TargetFilter = workspace.Thrown

local IsChime = game.PlaceId == 6832944305

getgenv().Features = {}
getgenv().CachedPlayersData = {}

local EffectReplicator = getgenv().require(ReplicatedStorage:WaitForChild("EffectReplicator"))

---@module Modules/Deepwoken/KeyHandler
local KeyHandler = require("Modules/Deepwoken/KeyHandler")

---@module Features/Wipe
local Wipe = require("Features/Wipe")

---@module Features/StreamerMode
local StreamerMode = require("Features/StreamerMode")

---@module Modules/Utilities
local Utilities = require("Modules/Utilities")

local ControlModule = require("ControlModule")
local RequireMaid = require("Modules/Maid")
local Maid = RequireMaid.new()

getgenv().FeaturesMaid = Maid

local Character = LocalPlayer.Character
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

local LeftClick
local RightClick
local ServerSlide
local ServerSlideStop
local TalentPickerData
local CurrentChainFrame
local CurrentSanityFrame
local CurrentStack = 0
local HasPerfectStack = false

local StatsGui = StarterGui:WaitForChild("StatsGui")
local SurvivalStats = StatsGui and StatsGui:WaitForChild("SurvivalStats")
local StomachFrame = SurvivalStats and SurvivalStats:WaitForChild("Stomach")

local SanityFrame = StomachFrame:Clone()
SanityFrame.Name = "SanityFrame"
SanityFrame.Position = StomachFrame.Position + UDim2.new(UDim.new(0, 24), UDim.new(0, 0))
SanityFrame.Visible = false

local SanitySlider = SanityFrame:WaitForChild("Slider")
if SanitySlider then
	SanitySlider.BackgroundColor3 = Color3.fromRGB(12, 12, 187)
	SanitySlider.Size = UDim2.new(UDim.new(1, 0), UDim.new(0, 0))
end

local ChainFrame = SanityFrame:Clone()
ChainFrame.Name = "ChainFrame"
ChainFrame.Position = SanityFrame.Position + UDim2.new(UDim.new(0, 24), UDim.new(0, 0))
ChainFrame.Visible = false

local ChainSlider = ChainFrame:WaitForChild("Slider")
if ChainSlider then
	ChainSlider.BackgroundColor3 = Color3.fromRGB(154, 67, 211)
	ChainSlider.Size = UDim2.new(UDim.new(1, 0), UDim.new(0, 0))
end

local function GetPlayer(name)
	for i, v in pairs(Players:GetPlayers()) do
		if v.Name:lower() == name:lower() then
			return v
		end
	end
end

local function getlocation(chr)
	if Players:GetPlayerFromCharacter(chr) then
		local area = ReplicatedStorage.MarkerWorkspace:FindPartOnRayWithWhitelist(
			Ray.new(chr:GetPivot().p, Vector3.new(0, 5000, 0)),
			{ ReplicatedStorage.MarkerWorkspace.AreaMarkers }
		)
		if area then
			return area.Parent.Name
		else
			return "The Aratel/Etrean Sea"
		end
	end
end

local function talentPicker()
	local ChoiceFrame = LocalPlayer.PlayerGui:WaitForChild("TalentGui"):WaitForChild("ChoiceFrame")

	for _, v in pairs(ChoiceFrame:GetChildren()) do
		if not v:IsA("TextButton") then
			continue
		end

		local CardFrame = v:FindFirstChild("CardFrame")
		if not CardFrame then
			continue
		end

		local Invalid = false
		if
			not TalentPickerData
			or not Toggles.TalentPicker.Value
			or not TalentPickerData.talents
			or not table.find(TalentPickerData.talents, string.gsub(v.Name, "^%s*(.-)%s*$", "%1"))
		then
			Invalid = true
		end

		CardFrame.BorderColor3 = Color3.new(255, 0, 0)
		CardFrame.BorderSizePixel = Invalid and 0 or 10
	end
end

local CurrentlyViewing = nil
local function AddToView(v)
	local LastHoveredName = nil

	Maid:GiveTask(v.Player.Changed:Connect(function()
		local Player = v:WaitForChild("Player", 9e9)

		if not GetPlayer(Player.Text) then
			return
		end

		LastHoveredName = Player.Text

		Player.Text = Toggles.StreamerMode.Value and "Lycoris On Top" or Player.Text
	end))

	Maid[v] = v.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if CurrentlyViewing == LastHoveredName then
				CurrentlyViewing = LocalPlayer.Name
			else
				CurrentlyViewing = LastHoveredName
			end

			local Char = GetPlayer(CurrentlyViewing).Character
			if not Char then
				return
			end

			if not Char:FindFirstChild("HumanoidRootPart") then
				local Position = Char:GetAttribute('MapPos') + Vector3.new(0,Char:GetPivot().X,0)
				task.spawn(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, Char:GetPivot().p)
				task.spawn(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, Position)
				getgenv().Library:Notify("Player not loaded, last known area: " .. getlocation(Char), 2)
			else
				getgenv().Library:Notify("Viewing: " .. Players[Char.Name]:GetAttribute("CharacterName"), 1.5)
			end

			if Maid.CameraSubjectView then
				Maid.CameraSubjectView = nil
				warn("removed subject signal")
			end

			if Char == Character then
				game:GetService("CollectionService"):RemoveTag(LocalPlayer, "ForcedSubject")
				workspace.CurrentCamera.CameraSubject = Character
				return
			end

			game:GetService("CollectionService"):AddTag(LocalPlayer, "ForcedSubject")
			workspace.CurrentCamera.CameraSubject = Char
		end
	end)
end

local function SpawnNewFrame(FrameNumber)
	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local PlayerStatsGui = PlayerGui:WaitForChild("StatsGui")
	local PlayerSurvivalStats = PlayerStatsGui:WaitForChild("SurvivalStats")
	local Stomach = PlayerSurvivalStats:FindFirstChild("Stomach")
	local StomachVisible = Stomach and Stomach.Visible or true

	local function OnAncestorChange()
		if not CurrentSanityFrame or not CurrentSanityFrame:IsDescendantOf(game) then
			SpawnNewFrame(1)
		end

		if not CurrentChainFrame or not CurrentChainFrame:IsDescendantOf(game) then
			SpawnNewFrame(2)
		end
	end

	if FrameNumber == 1 then
		CurrentSanityFrame = SanityFrame:Clone()
		CurrentSanityFrame.Parent = PlayerSurvivalStats
		CurrentSanityFrame.Visible = Toggles.SanityCounter.Value and StomachVisible
		Maid:GiveTask(CurrentSanityFrame)
		Maid:GiveTask(CurrentSanityFrame.AncestryChanged:Connect(OnAncestorChange))
	end

	if FrameNumber == 2 then
		CurrentChainFrame = ChainFrame:Clone()
		CurrentChainFrame.Parent = PlayerSurvivalStats
		CurrentChainFrame.Visible = Toggles.PerfectStack.Value and StomachVisible
		Maid:GiveTask(CurrentChainFrame)
		Maid:GiveTask(CurrentChainFrame.AncestryChanged:Connect(OnAncestorChange))
	end
end

-- save iteration
local iteration = 1

-- get weapon anims
local weaponAnims = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Anims"):WaitForChild("Weapon")

-- invoke anim list
local invokeAnimList = weaponAnims:GetDescendants()

-- invoked animation tracks
local invokedAnimationTracks = {}

-- current timestamp
local invokeTimestamp = 0

-- invoke anims
local function invokeAnims()
	-- get our animator
	local animator = Humanoid:WaitForChild("Animator", 9e9)

	local function getRandomValues(n)
		local values = {}
		for _ = 1, n do
			values[#values+1] = invokeAnimList[math.random(1, #invokeAnimList)]
		end
		return values
	end

	-- invoke anims
	for _, invokeAnim in next, getRandomValues(10) do
		if typeof(invokeAnim) ~= "Instance" or not invokeAnim:IsA("Animation") then
			continue
		end

		-- load animation
		local success, animationTrack = pcall(animator.LoadAnimation, animator, invokeAnim)
		if not success then
			break
		end

		-- play, make it never end, and make it essentially invisible because it's priority is too low
		animationTrack:Play()

		if Toggles.VisibleAPBreaker and not Toggles.VisibleAPBreaker.Value then
			animationTrack:AdjustWeight(0.0001, 0)
		end

		-- save
		invokedAnimationTracks[#invokedAnimationTracks + 1] = animationTrack
	end
end

-- stop anims
local function stopAnims()
	for _, animationTrack in next, invokedAnimationTracks do
		pcall(animationTrack.Stop, animationTrack)
	end
end

local function apBreakerLoop()
	-- don't do anything if our feature isn't enabled
	if not Toggles.APBreaker.Value then
		return
	end

	-- check if we're on timeout...
	if (os.clock() - invokeTimestamp) < 0.1 then
		return
	end

	-- check if we should invoke
	local shouldInvoke = (iteration % 2) == 1

	-- start invoking
	if shouldInvoke then
		invokeAnims()
	else
		stopAnims()
	end

	-- set timestamp
	invokeTimestamp = os.clock()

	-- increase
	iteration = iteration + 1
end

local function onPlayerAdded(Player)
	task.spawn(Utilities.GetModRank, Player)
	task.spawn(Utilities.CheckVoidwalker, Player)

	local Backpack = Player:WaitForChild("Backpack")
	local PlayerList = {}

	for _, v in pairs(Players:GetPlayers()) do
		if v == Players.LocalPlayer then
			continue
		end
		table.insert(PlayerList, v.Name)
	end

	Options.TPMobToTarget.Values = PlayerList
	Options.TPMobToTarget:SetValues(PlayerList)
	
	Options.ExportBuildPlayer.Values = PlayerList
	Options.ExportBuildPlayer:SetValues(PlayerList)

	repeat
		task.wait()
	until game:GetService("CollectionService"):HasTag(Backpack, "Loaded")

	task.spawn(Utilities.GetModRank, Player)
	task.spawn(Utilities.CheckVoidwalker, Player)

	Options.AutoParryWhitelist.Values = PlayerList
	Options.AutoParryWhitelist:SetValues(PlayerList)
	
	Options.ExportBuildPlayer.Values = PlayerList
	Options.ExportBuildPlayer:SetValues(PlayerList)

	for i, v in pairs(Backpack:GetChildren()) do
		task.spawn(Utilities.CheckLegendaryWeapon, Player, v)
	end

	Maid[Player.Name .. "backpackadded"] = Backpack.ChildAdded:Connect(function(v)
		task.spawn(Utilities.CheckLegendaryWeapon, Player, v)
	end)

	getgenv().FriendsCache = getgenv().FriendsCache or {}
	getgenv().FriendsCache[Player] = Players.LocalPlayer:IsFriendsWith(Player.UserId) == true and true or false
end

function CheckFacing(self)
	local UserRootPart = RootPart
	local RootPart = self.Character:FindFirstChild("HumanoidRootPart")
	if not RootPart or not UserRootPart then
		return
	end

	local DeltaOnTargetToLocal = (UserRootPart.Position - RootPart.Position).Unit
	local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1

	return TargetToLocalResult
end

local dashcastglobalcd = false
local dashcastcustomcd = {}
local function DashCasting(custom_cd, sec)
	if not Character or not RootPart or not Humanoid or not Character:FindFirstChild("Agility") then
		return
	end

	local nearest = Utilities.GetNearestCharacter()
	if not nearest then
		return
	end

	if not CheckFacing({Character = nearest}) then
		return
	end

	if (nearest.HumanoidRootPart.Position - RootPart.Position).Magnitude < 8 then
		return
	end

	if dashcastglobalcd then
		return
	else
		if not custom_cd then
			dashcastglobalcd = true
			task.delay(Options.DashCasting_CD.Value, function()
				dashcastglobalcd = false
			end)
		end
	end

	if custom_cd then
		if dashcastcustomcd[custom_cd] then
			return
		else
			dashcastcustomcd[custom_cd] = true
			task.delay(sec, function()
				dashcastcustomcd[custom_cd] = nil
			end)
		end
	end
	
	local Agility = Character:FindFirstChild("Agility").Value
	local LookAtVect = CFrame.new(RootPart.Position, nearest.HumanoidRootPart.Position).LookVector
	local Velocity = Agility * 0.5 * 1 + 60

	if RootPart:FindFirstChildOfClass("BodyVelocity") then
		RootPart:FindFirstChildOfClass("BodyVelocity").Parent = nil
	end

	local BodyVelocity = Instance.new("BodyVelocity")
	game.CollectionService:AddTag(BodyVelocity, "AllowedBM")
	BodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
	BodyVelocity.Velocity = LookAtVect * Velocity * 1.25
	BodyVelocity.Parent = RootPart
	BodyVelocity.Name = "Mover"

	game.Debris:AddItem(BodyVelocity, 0.1)
end

getgenv().DashcastFunction = DashCasting

local function onCharacterAdded(NewCharacter)
	Character = NewCharacter
	RootPart = Character:WaitForChild("HumanoidRootPart")
	Humanoid = Character:WaitForChild("Humanoid")

	repeat
		task.wait()
	until Character:FindFirstChild("Requests", true) and not Character:FindFirstChild("LeftClick", true) and not Character:FindFirstChild("ServerSlide", true) and not Character:FindFirstChild("ServerSlideStop", true)
	task.wait(0.5)

	LeftClick = KeyHandler.GetKey("LeftClick")
	RightClick = KeyHandler.GetKey("RightClick")
	ServerSlide = KeyHandler.GetKey("ServerSlide")
	ServerSlideStop = KeyHandler.GetKey("ServerSlideStop")

	getgenv().LeftClickRemote = LeftClick
	getgenv().RightClickRemote = RightClick
	getgenv().BlockRemote = KeyHandler.GetKey("Block")
	getgenv().UnblockRemote = KeyHandler.GetKey("Unblock")
	getgenv().DodgeRemote = KeyHandler.GetKey("Dodge")
	getgenv().StopDodgeRemote = KeyHandler.GetKey("StopDodge")

	-- Sanity...
	local Sanity = Character:WaitForChild("Sanity")

	-- Modify sanity counter...
	local function ModifySanityCounter(Value)
		-- Check for sanity frame...
		if not CurrentSanityFrame then
			return
		end

		-- Get slider...
		local Slider = CurrentSanityFrame:FindFirstChild("Slider")
		if not Slider then
			return
		end

		-- Modify slider...
		local SliderPercentage = 1 - Value / Sanity.MaxValue
		Slider.Size = UDim2.new(UDim.new(1.0, 0.0), UDim.new(math.min(SliderPercentage, 1.0), 0.0))
	end

	-- Modify stack...
	local function ModifyStack(Stack)
		-- Set stack...
		CurrentStack = Stack

		-- Check for chain frame...
		if not CurrentChainFrame then
			return
		end

		-- Get slider...
		local Slider = CurrentChainFrame:FindFirstChild("Slider")
		if not Slider then
			return
		end

		-- Modify slider...
		local SliderPercentage = CurrentStack / 20
		Slider.Size = UDim2.new(UDim.new(1.0, 0.0), UDim.new(math.min(SliderPercentage, 1.0), 0.0))
	end

	do -- Auto Wisp
		if Maid.WispFunc then
			Maid.WispFunc = nil
		end
		Maid.WispFunc = LocalPlayer.PlayerGui.SpellGui.SpellFrame.Symbols.ChildAdded:Connect(Utilities.AutoWisp)
	end

	do -- Auto Loot
		if Maid.AutoLootChild then
			Maid.AutoLootChild = nil
		end
		Maid.AutoLootChild = LocalPlayer.PlayerGui.ChildAdded:Connect(Utilities.AutoLoot)
	end

	do -- Sanity Counter
		if Maid.SanityCounter then
			Maid.SanityCounter = nil
		end

		ModifySanityCounter(Sanity.Value)
		Maid.SanityCounter = Sanity.Changed:Connect(ModifySanityCounter)
	end

	do -- Talent Picker
		if Maid.TalentListener then
			Maid.TalentListener = nil
		end

		Maid.TalentListener = RunService.Heartbeat:Connect(talentPicker)
	end

	do -- Player View
		local PlayerFrame = LocalPlayer.PlayerGui:WaitForChild("LeaderboardGui").MainFrame.ScrollingFrame
		local function onFrameAdded(v)
			if not v:IsA("Frame") then
				return
			end
			task.spawn(AddToView, v)
		end

		if Maid.PlayerFrameConnection then
			Maid.PlayerFrameConnection = nil
		end
		Maid.PlayerFrameConnection = PlayerFrame.ChildAdded:Connect(onFrameAdded)

		for _, v in pairs(PlayerFrame:GetChildren()) do
			onFrameAdded(v)
		end
	end

	do -- Effect Handler
		local SaveTime = {}
		getgenv().EffectHandlerHash = EffectReplicator:GetEffectsHash()
		
		EffectReplicator.EffectRemoving:Connect(function(Effect)
			EffectHandlerHash = EffectReplicator:GetEffectsHash()
			if Effect.Class == "PerfectStack" then
				ModifyStack(0)
				HasPerfectStack = false
			end
			if Toggles.EffectLog.Value then
				warn("[Class]: " .. Effect.Class .. "\n[Timeout]: " .. tick() - (SaveTime[Effect.ID] or tick()))
			end
		end)

		local Mantra 
		
		if Maid.MantraCounter then
			Maid.MantraCounter = nil
		end

		Maid.MantraCounter = task.spawn(function()
			while true do
				for i,v in pairs(LocalPlayer.Backpack:GetChildren()) do
					if v.Name:match("Mantra:") and not v.Name:match("Recalled") then
						Mantra = v
						break
					end
				end
				task.wait(4)
			end
		end)
		
		EffectReplicator.EffectAdded:Connect(function(Effect)
			SaveTime[Effect.ID] = tick()
			EffectHandlerHash = EffectReplicator:GetEffectsHash()

			if Toggles.EffectLog.Value then
				print("[Class]: " .. Effect.Class .. "\n[Value]: " .. tostring(Effect.Value))
			end
			if Effect.Class == "LightAttack" and Toggles.FastSwing.Value then
				rawset(Effect, "Disabled", true)
			end
			if Effect.Class == "OverrideSpeed" and Toggles.FeintFlourish.Value then
				task.wait(.07)

				if not EffectReplicator:FindEffect("MidAttack") then
					return
				end

				if not Mantra or not Humanoid or EffectReplicator:FindEffect("FeintCool") then
					return
				end
				
				print("[FeintFlourish]: Using Mantra")

				Humanoid:EquipTool(Mantra)

				task.wait(.09)

				print("[FeintFlourish]: Feinting Mantra")
				
				RightClick:FireServer({
					Left = true,
					Right = true,
					W = false,
					A = false,
					S = false,
					D = false,
				})
			end
			if Effect.Class == "Burning" and Toggles.AntiFire.Value then
				ServerSlide:FireServer(true)
				task.wait(.3)
				ServerSlideStop:FireServer()
			end
			if (Effect.Class == "NoJump" or Effect.Class == "NoJumpAlt") and Toggles.NoJumpCooldown.Value then
				rawset(Effect, "Disabled", true)
			end
			if Effect.Class == "ClientDodge" and Toggles.AutoRollCancel.Value then
				EffectReplicator:CreateEffect("Feint"):Debris(.1)
			end
			if Effect.Class == "UsingSpell" and Toggles.AutoPerfectCast.Value then
				local holdm1 = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
				VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
				task.wait()
				VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
				if holdm1 then
					task.wait()
					VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
				end
			end
			if Effect.Class == "UsingSpell" and Toggles.DashCasting.Value then
				DashCasting()
			end
			if Effect.Class == "PerfectionCool" and HasPerfectStack then
				ModifyStack(CurrentStack + 1)
			end
			if Effect.Class == "PerfectStack" then
				ModifyStack(Effect.Value)
				HasPerfectStack = true
			end
			if table.find({ "Knocked", "Ragdoll" }, Effect.Class) and Toggles.RagdollCancel.Value then
				VIM:SendMouseButtonEvent(1, 1, 1, true, game, 1)
				task.wait()
				VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)
			end
			if Effect.Class == "Speed"  and Effect.Value < 0 and Toggles.NoSpeedDebuff.Value then
				rawset(Effect, "Value", 0)
			end
			if Effect.Class == "BeingWinded" and Toggles.AntiWind.Value then
				rawset(EffectReplicator.Effects, Effect.ID, nil)
			end
			if Effect.Class == "SpeedOverride"  and Effect.Value < 14 and Toggles.NoSpeedDebuff.Value then
				rawset(EffectReplicator.Effects, Effect.ID, nil)
			end
			if (Effect.Class == "RollCancelFatigue" or Effect.Class == "DownComesTheClaw") then
				if Toggles.NoRollFatigue.Value then
					rawset(EffectReplicator.Effects, Effect.ID, nil)
				end
			end
			if Effect.Class == "SHDash" and not EffectReplicator:FindEffect('SHDashMediumCD') then
				-- if Toggles.AutoFlowState.Value then
				-- 	local FlowState = LocalPlayer.Backpack:FindFirstChild("Talent:Flow State")
				-- 	if not FlowState then
				-- 		return
				-- 	end

				-- 	Humanoid:EquipTool(FlowState)
				-- end
			end
			if (Effect.Class == "Feint" or Effect.Class == "ClientFeint") then
				if Toggles.ExtendRollCancel.Value and Humanoid and not EffectReplicator:FindEffect('ExtendedRoll') and EffectReplicator:FindEffect('ClientDodge') then
					EffectReplicator:CreateEffect('ExtendedRoll'):Debris(.3)
					local MoveDirection = Humanoid.MoveDirection
					
					---@type BodyVelocity
					local bv = Utilities.NewBodyMover("BodyVelocity")
					bv.MaxForce = Vector3.new(50000, 0, 50000)
					bv.Velocity = MoveDirection * 70
					
					for i,v in pairs(Character:GetDescendants()) do
						if v.Name == 'Mover' or v.Name == 'EasyCancel' then
							v:Destroy()
						end
					end

					bv.Parent = RootPart
	
					game:GetService('Debris'):AddItem(bv, 0.12)
				end
			end
		end)
	end
end

local function LerpToGoal(Goal, StayUntilFinished, Yield)
	local BindableEvent = Instance.new("BindableEvent")
	local Finished = false
	local Cancelled = false do
		BindableEvent.Event:Connect(function()
			Cancelled = true
		end)
	end

	task.spawn(function()
		local Distance = (RootPart.Position - Goal).Magnitude
	
		local StartPos = CFrame.new(RootPart.Position)
		local FinalCF
		local Speed = 1.1
	
		for i = 0, Distance, Speed do
			if Cancelled then break end
	
			local Progress = i/Distance
			local VertCF = CFrame.new(Goal)
			local LerpCF = StartPos:Lerp(VertCF, Progress) * CFrame.new(0,2,0)
			
			local RayResult = workspace:Raycast(LerpCF.Position, LerpCF.UpVector*-800, RaycastParams.new({
				FilterType = Enum.RaycastFilterType.Exclude,
				FilterDescendantsInstances = { Character }
			}))
	
			local GotPosition = RayResult and RayResult.Position or LerpCF.Position
	
			if not RayResult.Instance then
				GotPosition = LerpCF.Position
			end
	
			local Position = GotPosition
			local LinearPos = Vector3.new(VertCF.X, Position.Y, VertCF.Z)
			FinalCF = CFrame.new(Position, LinearPos) * CFrame.new(0,-9.5,0) * CFrame.Angles(0,0,math.rad(180))
	
			RootPart.Velocity = Vector3.zero
			RootPart.CFrame = FinalCF
			task.wait()
		end
	
		if StayUntilFinished then
			repeat
				if Cancelled then break end
				RootPart.Velocity = Vector3.zero
				RootPart.CFrame = FinalCF
				task.wait()
			until game:GetService("MemStorageService"):HasTag("FinishedTween")
	
			if game:GetService("MemStorageService"):HasTag("FinishedTween") then
				game:GetService("MemStorageService"):RemoveTag("FinishedTween")
			end
		else
			RootPart.Velocity = Vector3.zero
			RootPart.CFrame = CFrame.new(Goal)
		end

		Finished = true
	end)

	if Yield then
		repeat
			task.wait()
		until Finished
	end

	return BindableEvent
end

local function SetTweenFinished()
	game:GetService("MemStorageService"):AddTag("FinishedTween")
end

function Features.Fly()
	if not Toggles.Fly.Value then
		Maid.FlyBV = nil
		Maid.FlyConnect = nil
		return
	end

	Maid.FlyBV = Utilities.NewBodyMover("BodyVelocity")
	Maid.FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	Maid.FlyConnect = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(deltaTime)
		if Toggles.PVPMode.Value then
			Maid.FlyBV.Parent = nil
			return
		end

		if Toggles.ChimeSafety.Value and IsChime then
			Maid.FlyBV.Parent = nil
			return
		end

		if not RootPart then
			return
		end

		local bv = RootPart:FindFirstChildOfClass("BodyVelocity")
		if bv and bv ~= Maid.FlyBV then
			bv.Parent = nil
		end

		local Velocity = Camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * Options.FlySpeed.Value)

		if Utilities:GetInput("space") then
			Velocity = Velocity + Vector3.new(0, Options.FlyUpSpeed.Value, 0)
		end

		Maid.FlyBV.Parent = RootPart
		Maid.FlyBV.Velocity = Velocity
	end))
end

local CurrentTween = nil
local ActiveBloodJar = nil
local ActivePodium = nil

local function resetTween()
	if not CurrentTween then
		return
	end

	CurrentTween:Pause()
	CurrentTween:Cancel()
	CurrentTween = nil
end

local function tweenToBloodJars(ChaserEntity)
	-- Check for blood jar...
	if
		not ActiveBloodJar
		or (ActiveBloodJar and not ActiveBloodJar.Value)
		or (ActiveBloodJar and ActiveBloodJar.Value and not ActiveBloodJar.Value.Parent)
	then
		-- Set to Chaser's active blood jar
		ActiveBloodJar = ChaserEntity.HumanoidRootPart:FindFirstChild("BloodJar")
	end

	-- Check for blood jar...
	if not ActiveBloodJar then
		-- Reset tween...
		return resetTween()
	end

	-- Get part...
	local Part = ActiveBloodJar.Value.Parent:FindFirstChildOfClass("Part")
	if not Part then
		-- Reset active blood jar...
		ActiveBloodJar = nil

		-- Reset tween...
		return resetTween()
	end

	-- Check if we already have a tween...
	if CurrentTween then
		return
	end

	-- Get distance...
	local Distance = (Part.Position - RootPart.Position).Magnitude

	-- Tween...
	CurrentTween = game:GetService("TweenService"):Create(RootPart, TweenInfo.new(Distance / 80), {
		CFrame = CFrame.new(Part.Position),
	})
	CurrentTween:Play()
	CurrentTween.Completed:Connect(function()
		CurrentTween = nil
	end)
end

local function tweenToAltars(Floor1Stuff)
	-- Get first empty altar...
	local function getFirstEmptyAltar()
		-- Loop stuff...
		for _, instance in next, Floor1Stuff:GetChildren() do
			-- Check for altar...
			if instance.Name ~= "Altar" or not instance:IsA("Model") then
				continue
			end

			-- Check if not empty...
			if instance:FindFirstChild("BoneSpear") then
				continue
			end

			-- Return altar...
			return instance
		end
	end

	-- Check for active podium...
	if not ActivePodium then
		-- Get first empty altar...
		local firstEmptyAltar = getFirstEmptyAltar()

		-- Check if it doesn't exist...
		if not firstEmptyAltar then
			return
		end

		-- Set active podium...
		ActivePodium = firstEmptyAltar
	end

	-- Check if the empty podium has a spear in it now...
	-- If so, reset the tween...
	if ActivePodium:FindFirstChild("BoneSpear") then
		return resetTween()
	end

	-- Check if we already have a tween...
	if CurrentTween then
		return
	end

	-- Get distance...
	local Distance = (ActivePodium:GetPivot().Position - RootPart.Position).Magnitude

	-- Tween...
	CurrentTween = game:GetService("TweenService"):Create(RootPart, TweenInfo.new(Distance / 80), {
		CFrame = CFrame.new(ActivePodium:GetPivot().Position),
	})
	CurrentTween:Play()
	CurrentTween.Completed:Connect(function()
		CurrentTween = nil
	end)
end

local function tweenToObjective()
	-- Get chaser...
	local ChaserEntity = workspace.Live:FindFirstChild(".chaser")

	-- Get boss room...
	local BossRoom = workspace:FindFirstChild("TrueAvatarBossRoom")
	local Floor1Stuff = BossRoom and BossRoom:FindFirstChild("Floor1Stuff") or nil

	-- Check if tweening is off...
	if not Toggles.TweenToObjective.Value or not Options.TweenToObjectiveKeybind:GetState() then
		-- Reset tween...
		return resetTween()
	end

	-- Ethiron room, we'll probably want to move towards the altars...
	if Floor1Stuff then
		tweenToAltars(Floor1Stuff)
	end

	-- Chaser is alive, we'll probably want to move towards blood jars...
	if ChaserEntity then
		tweenToBloodJars(ChaserEntity)
	end
end

function Features.Speedhack()
	if not Toggles.Speedhack.Value then
		Maid.Speedhack = nil
		return
	end

	Maid.Speedhack = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		if Toggles.PVPMode.Value or Toggles.Fly.Value then
			return
		end
		
		if Toggles.ChimeSafety.Value and IsChime then
			return
		end

		if not RootPart or not Humanoid then
			return
		end

		RootPart.Velocity = RootPart.Velocity * Vector3.new(0, 1, 0)
		if Humanoid.MoveDirection.Magnitude > 0 then
			RootPart.Velocity = RootPart.Velocity + Humanoid.MoveDirection.Unit * Options.Speedhack.Value
		end
	end))
end

function Features.AutoFish()
	if not Toggles.AutoFish.Value then
		Maid.DangerListener = nil
		Maid.AutoFishRemoteListener = nil
		Maid.AutoFishThrownListener = nil
		return
	end

	Maid.AutoFishThrownListener = workspace.Thrown.ChildAdded:Connect(function(child)
		if not child:WaitForChild("Lid", 10) or not Toggles.AutoFish.Value then
			return
		end

		if
			(child:FindFirstChild("Lid").Position - Character.HumanoidRootPart.Position).Magnitude >= 15
			or not Toggles.AutoFishNotify.Value
			or Options.AutoFishWebhook.Value == ""
		then
			return
		end

		-- interact with chest until we get a prompt
		repeat
			fireproximityprompt(child:WaitForChild("InteractPrompt"))
			task.wait()
		until LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt")

		-- pools
		local Pools = {}
		local ConstructWord = "Chest Pools: \n "
		local Prompt = LocalPlayer.PlayerGui:WaitForChild("ChoicePrompt")

		-- chest collection
		repeat
			for i, v in next, Prompt.ChoiceFrame.Options:GetChildren() do
				-- skip non text button
				if not v:IsA("TextButton") then
					continue
				end

				-- parse
				if v.Name:match("$") and #v.Name:split("$")[1] < 24 then
					if not Pools[v.Name] then
						local text = v:WaitForChild("Stats") and v.Stats.ContentText or "N/A"
						if text:match("Dolor amet") then
							text = "N/A"
						end
						Pools[v.Name] = text
					end
				else
					if not Pools[v:WaitForChild("Title").Text] then
						local text = v:WaitForChild("Stats") and v.Stats.ContentText or "N/A"
						if text:match("Dolor amet") then
							text = "N/A"
						end
						Pools[v:WaitForChild("Title").Text] = text
					end
				end

				-- grab
				firesignal(v.MouseButton1Click)
			end
			task.wait()
		until not Prompt:FindFirstChild("ChoiceFrame")

		-- construct message
		for i, v in pairs(Pools) do
			i = i:split("$") and i:split("$")[1] or i
			ConstructWord = ConstructWord .. ("`[%s]: [%s]` \n"):format(i, v)
		end

		-- send to webhook
		request({
			Url = Options.AutoFishWebhook.Value,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({
				content = ConstructWord,
			}),
		})
	end)

	local FishingRod = Character:FindFirstChild("Fishing Rod") or LocalPlayer.Backpack:FindFirstChild("Fishing Rod")
	local RemoteEvent = FishingRod:WaitForChild("FishinScript"):WaitForChild("RemoteEvent")
	local ActiveDirection = 'a'
	local Caught = false
	local SuccessBob = false

	local function CatchFish()
		if not Toggles.AutoFish.Value then
			return
		end

		getgenv().Library:Notify("Attempting to fish", 2)

		if FishingRod and FishingRod.Parent then
			Humanoid:EquipTool(FishingRod)
			task.wait(0.5)
			VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
			task.wait(Options.AutoFishDelay.Value)
			VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
		else
			getgenv().Library:Notify("No Fishing Rod was found. cancelling autofish", 3)
		end
	end

	Maid.DangerListener = EffectReplicator.EffectAdded:Connect(function(Effect)
		if Effect.Class ~= 'Danger' then
			return
		end
		
		getgenv().Library:Notify("Attempting to kill danger mob", 2)

		while EffectReplicator:FindEffect("Danger") and Character do
			if not Character:FindFirstChild("Weapon") then
				Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Weapon"))
				task.wait(0.2)
			end

			LeftClick:FireServer(false, Mouse.Hit, {
				["W"] = false,
				["A"] = false,
				["S"] = false,
				["D"] = false,
				["Right"] = false,
				["Left"] = false,
				ctrl = false,
			})

			task.wait(.15)
		end

		task.wait(.5)

		CatchFish()
	end)

	Maid.AutoFishRemoteListener = RemoteEvent.OnClientEvent:Connect(function(arg, dir)
		if arg == 'dir' then
			ActiveDirection = dir
		end
		if arg == 'caught' then
			getgenv().Library:Notify("Caught fish", 2)
			Caught = true
		end
		if arg == 'hooked' then
			while not Caught do
				RemoteEvent:FireServer('m1', {
					a = ActiveDirection == 'a',
					s = ActiveDirection == 's',
					d = ActiveDirection == 'd'
				})
				task.wait(.05)
			end

			Caught = false
			SuccessBob = false

			task.wait(.5)

			CatchFish()
		end
		if arg == 'bobby' then
			SuccessBob = true
		end
	end)

	CatchFish()
end

function Features.NoClip()
	if not Toggles.NoClip.Value then
		Maid.NoClip = nil

		if not Humanoid then
			return
		end

		Humanoid:ChangeState("Physics")
		task.wait()
		Humanoid:ChangeState("RunningNoPhysics")

		return
	end

	Maid.NoClip = RunService.Stepped:Connect(function()
		if not RootPart then
			return
		end
		
		if Toggles.ChimeSafety.Value and IsChime then
			return
		end

		local Knocked = EffectReplicator:FindEffect("Knocked")
		local disablenoclip = Toggles.disableNoClipWhenKnocked.Value or Toggles.PVPMode.Value

		for _, v in pairs(Character:GetDescendants()) do
			if not v:IsA("BasePart") then
				continue
			end

			v.CanCollide = disablenoclip and Knocked
		end
	end)
end

function Features.InfJump()
	if not Toggles.InfJump.Value then
		Maid.InfJump = nil
		return
	end

	Maid.InfJump = UserInputService.InputBegan:Connect(LPH_NO_VIRTUALIZE(function(input, gpe)
		if gpe then
			return
		end

		if not RootPart or not Humanoid then
			return
		end

		if input.KeyCode == Enum.KeyCode.Space then
			while UserInputService:IsKeyDown(Enum.KeyCode.Space) do
				if Toggles.PVPMode.Value then
					task.wait()
					return
				end

				if Toggles.ChimeSafety.Value and IsChime then
					task.wait()
					return
				end

				local bv = RootPart:FindFirstChildOfClass("BodyVelocity")
					or RootPart:FindFirstChildOfClass("BodyPosition")
				if bv and bv ~= Maid.FlyBV then
					bv.Parent = nil
				end

				RootPart.Velocity = RootPart.Velocity * Vector3.new(1, 0, 1)
				RootPart.Velocity = RootPart.Velocity + Vector3.new(0, Options.InfJump.Value, 0)
				task.wait()
			end
		end
	end))
end

function Features.NoFog()
	if not Toggles.NoFog.Value then
		Maid.NoFog = nil
		return
	end

	Maid.NoFog = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		game.Lighting.FogStart = 10000000000
		game.Lighting.FogEnd = 10000000000
		if game.Lighting:FindFirstChildOfClass("Atmosphere") then
			game.Lighting:FindFirstChildOfClass("Atmosphere").Density = 0
		end
	end))
end

local playerBlindFold = nil
function Features.NoBlind()
	if not Toggles.NoBlind.Value then
		Maid.NoBlind = nil

		if playerBlindFold then
			playerBlindFold.Parent = LocalPlayer.Backpack
			playerBlindFold = nil
		end

		return
	end

	Maid.NoBlind = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		local SanityDoF = game:GetService('Lighting'):FindFirstChild('SanityDoF')
		local SanityCorrect = game:GetService('Lighting'):FindFirstChild('SanityCorrect')
		if SanityDoF then
			SanityDoF.Enabled = false
		end
		if SanityCorrect then
			SanityCorrect.Enabled = false
		end

		local backpack = LocalPlayer:FindFirstChild("Backpack")
		if not backpack then
			return
		end

		local blindFold = backpack:FindFirstChild("Talent:Blinded") or backpack:FindFirstChild("Flaw:Blind")
		if not blindFold then
			return
		end

		blindFold.Parent = nil
		playerBlindFold = blindFold
	end))
end

local LastBlurSize = 0
function Features.NoBlur()
	if not Toggles.NoBlur.Value then
		Maid.NoBlur = nil

		game.Lighting.GenericBlur.Size = LastBlurSize
		LastBlurSize = 0

		return
	end

	LastBlurSize = game.Lighting.GenericBlur.Size

	Maid.NoBlur = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		game.Lighting.GenericBlur.Size = 0
	end))
end

function Features.FullBright()
	if not Toggles.FullBright.Value then
		game.Lighting.GlobalShadows = true
		Maid.FullBright = nil
		return
	end

	Maid.FullBright = RunService.Heartbeat:Connect(function()
		game.Lighting.GlobalShadows = false
	end)
end

function Features.M1Hold()
	if not Toggles.M1Hold.Value then
		Maid.M1Hold = nil
		return
	end

	local function canAttack()
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			and LeftClick
			and ((Toggles.BlockInput.Value and Status and not Status.Busy) or not Toggles.BlockInput.Value)
	end

	Maid.M1Hold = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		if not canAttack() then
			return
		end

		if not RootPart or not Humanoid then
			return
		end

		if not Utilities:GetInput("m1") or EffectReplicator:FindEffect("UsingSpell") then
			return
		end

		local Character = Utilities.GetCharacter()

		local Properties = {
			["W"] = false,
			["A"] = false,
			["S"] = false,
			["D"] = false,
			["Right"] = false,
			["Left"] = false,
			ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl),
		}

		if
			Character
			and Character:FindFirstChild("RightHand")
			and Character:FindFirstChild("LeftHand")
			and Character.RightHand:FindFirstChild("Gun", true)
			and Character.LeftHand:FindFirstChild("Gun", true)
		then
			repeat
				task.wait()
			until not EffectReplicator:FindEffect("LightAttack")

			repeat
				task.wait()
				LeftClick:FireServer(Utilities:InAir(), Mouse.Hit, Properties)
				if not canAttack() then
					break
				end
			until EffectReplicator:FindEffect("LightAttack")

			if not canAttack() then
				return
			end

			repeat
				task.wait()
			until not EffectReplicator:FindEffect("LightAttack")

			if not canAttack() then
				return
			end

			repeat
				task.wait()
				RightClick:FireServer(Utilities:InAir(), Mouse.Hit, Properties)
				if not canAttack() then
					break
				end
			until EffectReplicator:FindEffect("LightAttack")
		else
			LeftClick:FireServer(Utilities:InAir(), Mouse.Hit, Properties)
		end
	end))
end

local FastSwingClass = { "LightAttack", "HeavyAttack", "OffhandAttack" }
function Features.FastSwing()
	if not Toggles.FastSwing.Value then
		Maid.FastSwing = nil
		return
	end

	if not RootPart then
		return
	end

	Maid.FastSwing = EffectReplicator.EffectAdded:Connect(LPH_NO_VIRTUALIZE(function(v)
		if table.find(FastSwingClass, v.Class) then
			rawset(EffectReplicator.Effects, v.ID, nil)
		end
	end))
end

function Features.NoStun()
	if not Toggles.NoStun.Value then
		Maid.NoStun = nil
		return
	end

	repeat
		task.wait()
	until LeftClick

	Maid.NoStun = EffectReplicator.EffectAdded:Connect(LPH_NO_VIRTUALIZE(function(v)
		if table.find(Utilities.NoStunEffects, v.Class) then
			rawset(EffectReplicator.Effects, v.ID, nil)
		end
	end))
end

local TalentSelect = {}
function Features.TalentSpoofer()
	local Talents = Options.TalentList.Value
	if typeof(Talents) == "string" then
		Talents = { Talents }
	end

	for _, v in pairs(TalentSelect) do
		if not table.find(Talents, v.Name) then
			TalentSelect[v] = nil
			v:Destroy()
		end
	end

	if Talents[1] == "" then
		return
	end

	for v, _ in pairs(Talents) do
		if not LocalPlayer.Backpack:FindFirstChild(v) then
			local talent = Instance.new("Folder")
			talent.Name = v
			talent.Parent = LocalPlayer.Backpack
			TalentSelect[talent] = talent
		end
	end
end

local StreamerModeEnabled = false
function Features.StreamerMode()
	if not Toggles.StreamerMode.Value then
		if StreamerModeEnabled then
			StreamerModeEnabled = false
			StreamerMode.Revert()
		end

		return
	end

	StreamerModeEnabled = true
	StreamerMode.Init()
end

function Features.RandomizeName()
	if not Toggles.StreamerMode.Value then
		return
	end

	StreamerMode.RandomizeName()
end

function Features.StreamerModeHideGuilds()
	if not Toggles.StreamerMode.Value then
		return
	end

	StreamerMode.RandomizeName()
end

function Features.AutoSprint()
	if not Toggles.AutoSprint.Value then
		Maid.AutoSprint = nil
		return
	end

	if not RootPart then
		return
	end

	local moveKeys = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.D }
	local LastPressed = 0

	Maid.AutoSprint = UserInputService.InputBegan:Connect(LPH_NO_VIRTUALIZE(function(input, gpe)
		if gpe or tick() - LastPressed < 0.1 then
			return
		end

		if table.find(moveKeys, input.KeyCode) then
			LastPressed = tick()
			VIM:SendKeyEvent(UserInputService:IsKeyDown(input.KeyCode), input.KeyCode, false, game)
		end
	end))
end

function Features.M1RollCancel()
	if not Toggles.M1RollCancel.Value then
		Maid.M1RollCancel = nil
		return
	end

	Maid.M1RollCancel = UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and EffectReplicator:FindEffect('ClientDodge') then
			EffectReplicator:CreateEffect("Feint"):Debris(.1)
			task.wait(.05)
			LeftClick:FireServer(Utilities:InAir(), Mouse.Hit, {
				["W"] = false,
				["A"] = false,
				["S"] = false,
				["D"] = false,
				["Right"] = false,
				["Left"] = false,
				ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl),
			})
		end
	end)
end

local AttachTarget = nil
function Features.AttachToBack()
	if not Toggles.AttachToBack.Value then
		Maid.AttachToBack = nil
		return
	end

	Maid.AttachToBack = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		if not AttachTarget then
			AttachTarget = Utilities.FindNearestEntity(200)
		end

		if not RootPart or not AttachTarget then
			return
		end

		local TargetPrimary = AttachTarget.HumanoidRootPart
		local lerp_to = TargetPrimary.CFrame * CFrame.new(0, Options.ATBHeight.Value, Options.ATBRange.Value)
		RootPart.CFrame = RootPart.CFrame:Lerp(lerp_to, 0.3)
	end))
end

local OriginalAgility
function Features.AgilitySpoof()
	if not Toggles.AgilitySpoof.Value then
		if OriginalAgility then
			Character.Agility.Value = OriginalAgility
			OriginalAgility = nil
		end

		Maid.AgilitySpoof = nil
		return
	end

	Maid.AgilitySpoof = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		local Agility = Character and Character:FindFirstChild("Agility")

		if not RootPart or not Humanoid or not Agility then
			return
		end

		if not OriginalAgility then
			OriginalAgility = Agility.Value
		end

		Agility.Value = math.max(0, math.ceil(Options.AgilitySpoof.Value / 2))
	end))
end

function Features.PlayerProximity()
	if not Toggles.PlayerProximity.Value then
		Maid.PlayerProximity = nil
		return
	end

	local NotifDB = {}
	Maid.PlayerProximity = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		if not RootPart or not Humanoid then
			return
		end

		for _, T_Character in pairs(Utilities.EntityList) do
			local v = Players:GetPlayerFromCharacter(T_Character)
			if not v then
				continue
			end

			if not NotifDB[T_Character.Name .. "AC"] then
				NotifDB[T_Character.Name .. "AC"] = T_Character.AncestryChanged:Connect(function()
					if not T_Character or (T_Character.Parent == nil and NotifDB[T_Character]) then
						NotifDB[T_Character]()
						NotifDB[T_Character] = nil
						NotifDB[T_Character.Name .. "AC"]:Disconnect()
					end
				end)
			end

			local T_RootPart = T_Character and T_Character:FindFirstChild("HumanoidRootPart")
			if T_RootPart and v ~= LocalPlayer then
				if
					(RootPart.Position - T_RootPart.Position).Magnitude < Options.PlayerProximity.Value
					and not NotifDB[T_Character]
				then
					if
						v.Backpack:FindFirstChild("Talent:Voidwalker Contract")
						and not NotifDB[T_Character.Name .. "VW"]
					then
						NotifDB[T_Character.Name .. "VW"] = getgenv().Library:Notify("A Voidwalker is nearby.")
						task.delay(5, function()
							NotifDB[T_Character.Name .. "VW"]()
						end)
					end

					NotifDB[T_Character] = getgenv().Library:Notify(v:GetAttribute("CharacterName") .. " is nearby")
					if Toggles.AutoPVPMode.Value then
						Toggles.PVPMode:SetValue(true)
					end
				end

				if
					(RootPart.Position - T_RootPart.Position).Magnitude > (Options.PlayerProximity.Value + 100)
					and NotifDB[T_Character]
				then
					NotifDB[T_Character]()
					getgenv().Library:Notify(v:GetAttribute("CharacterName") .. " is no longer nearby", 2.5)
					NotifDB[T_Character] = nil
					if Toggles.AutoPVPMode.Value then
						Toggles.PVPMode:SetValue(false)
					end
				end
			end
		end
	end))
end

local function GetKnockedOwnershipItem()
	local selected = nil
	for i, v in pairs(LocalPlayer.Backpack:GetChildren()) do
		if not v.Name:match("Talent") and v:IsA("Tool") and v:FindFirstChildOfClass("BasePart") then
			selected = v
		end
	end
	if not selected then
		selected = LocalPlayer.Backpack:FindFirstChild("Weapon") or LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Weapon")
	end
	return selected
end

local ownershipItem = GetKnockedOwnershipItem()
local ownershipActive = false
local ownershipTick = tick()

function Features.KnockedOwnership()
	if not Toggles.KnockedOwnership.Value then
		Maid.KnockedOwnership = nil
		return
	end

	Maid.KnockedOwnership = RunService.Heartbeat:Connect(function(deltaTime)
		if not RootPart or not Humanoid or not Character or (Character and not Character:FindFirstChild("Torso")) then
			return
		end

		if not EffectReplicator:FindEffect("Knocked") or RootPart.ReceiveAge == 0 then
			return
		end

		if not ownershipItem then
			ownershipItem = GetKnockedOwnershipItem()
		end

		if not ownershipItem then
			return
		end
		
		if Toggles.ChimeSafety.Value and IsChime then
			return
		end

		if tick() - ownershipTick > 0.15 and not Toggles.PVPMode.Value then
			if
				ownershipItem.Parent == Character
				and EffectReplicator:FindEffect("Knocked")
				and RootPart.ReceiveAge ~= 0
			then
				Humanoid:UnequipTools()
				ownershipActive = true
			elseif
				ownershipItem.Parent == LocalPlayer.Backpack
				and EffectReplicator:FindEffect("Knocked")
				and RootPart.ReceiveAge ~= 0
			then
				ownershipItem.Parent = Character
				ownershipTick = tick()
				ownershipActive = true
			end

			if not Character.Torso:FindFirstChild("RagdollAttach") and ownershipActive then
				local Weapon = LocalPlayer.Backpack:FindFirstChild("Weapon")
				if Weapon then
					Humanoid:UnequipTools()
					Weapon.Parent = Character
				end
				ownershipActive = false
			end
		end
	end)
end

---------------------------------------------------------------------------------- VOID MOBS ----------------------------------------------------------------------------------
local function CheckConnectedParts()
	local Passed = true
	if not RootPart or not Character:FindFirstChild("Torso") then
		return false
	end

	for i, v in pairs(RootPart:GetConnectedParts()) do
		if v:IsDescendantOf(workspace.Live) and not v:IsDescendantOf(Character) then
			Passed = false
			break
		end
	end

	for i, v in pairs(Character.Torso:GetConnectedParts()) do
		if v:IsDescendantOf(workspace.Live) and not v:IsDescendantOf(Character) then
			Passed = false
			break
		end
	end

	return Passed
end

local oldsettings = {
	ThrottleAdjustTime = settings().Physics.ThrottleAdjustTime,
	AllowSleep = settings().Physics.AllowSleep,
	EagerBulkExecution = settings().Rendering.EagerBulkExecution,
}

function Features.ShowNetworkOwner()
	if not Toggles.ShowNetworkOwner.Value then
		settings().Physics.AreOwnersShown = false
		return
	end

	settings().Physics.AreOwnersShown = true
end

local PhysicsService = cloneref(game:GetService("PhysicsService"))
local NetworkBV = Instance.new("BodyVelocity")
NetworkBV.Velocity = workspace.StreamingEnabled and Vector3.new(0, -8000, 0) or Vector3.new(0, -100, 0)
NetworkBV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
NetworkBV.P = 1/0
NetworkBV.Name = 'NetworkRetainer'

pcall(function()
    PhysicsService:RegisterCollisionGroup("VoidMobs")
    PhysicsService:CollisionGroupSetCollidable("VoidMobs", "Default", false)
    PhysicsService:CollisionGroupSetCollidable("VoidMobs", "VoidMobs", false)
    PhysicsService:CollisionGroupSetCollidable("VoidMobs", "Player", false)
    PhysicsService:CollisionGroupSetCollidable("VoidMobs", "WalkThrough", false)
end)

local BVs = {}

local function retainPart(v)
    if v:IsA('BasePart') and not v:FindFirstChild('NetworkRetainer') then
        local BV = NetworkBV:Clone()
        BV.Parent = v

		table.insert(BVs, BV)
    end
end

--- Replication Part & PeerId
local clientPart = Instance.new('Part', workspace)
local PeerId = gethiddenproperty(clientPart, "NetworkOwnerV3")
clientPart:Destroy()

---Check for network ownership (legacy)
---@param part BasePart
---@return boolean
local function legacyNetworkOwnership(part)
    return not part.Anchored and part.ReceiveAge == 0 and part.Velocity.Magnitude > 0
end

---Check for network ownership
---@param part BasePart
---@return boolean
local function hasNetworkOwnership(part)
    local success, ID = pcall(function()
        return gethiddenproperty(part, "NetworkOwnerV3")
    end)

    if not success then
        return legacyNetworkOwnership(part)
    end
    
    return ID == PeerId
end

function Features.VoidMobs()
	if not Toggles.VoidMobs.Value then
		Maid.VoidMobs = nil
		settings().Physics.AllowSleep = oldsettings.AllowSleep
		for i, v in pairs(BVs) do
			v:Destroy()
			table.remove(BVs, i)
		end
		return
	end
	
	settings().Physics.AllowSleep = false

	Maid.VoidMobs = RunService.Heartbeat:Connect(function(_)
		if not RootPart or not Humanoid then
			return
		end

		sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
		sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
		
		local voidmode = workspace.FallenPartsDestroyHeight + 100
		local velchange = Vector3.new(0, -12000, 0)

		for _, v in pairs(workspace.Live:GetChildren()) do
			if
				v ~= LocalPlayer.Character
				and v:FindFirstChild("HumanoidRootPart")
				and not v:FindFirstChild("InteractPrompt")
				and (not Players:GetPlayerFromCharacter(v) or Toggles.VoidOnPlayerPickUp.Value)
				and CheckConnectedParts()
			then
				local Character = v
				local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
				local IsEthiron = Character.Name:match(".avatar")

				if IsEthiron then
					voidmode = workspace.FallenPartsDestroyHeight - 500
					velchange = Vector3.new(12,12,12)
				end
				
				for _, v in pairs(Character:GetChildren()) do
					retainPart(v)

					if HumanoidRootPart and hasNetworkOwnership(HumanoidRootPart) then
						local cf = HumanoidRootPart.CFrame
						HumanoidRootPart.Velocity = velchange
						HumanoidRootPart.CFrame = CFrame.new(cf.X, voidmode, cf.Z)
						sethiddenproperty(HumanoidRootPart, "NetworkIsSleeping", false)
					end

					if v:IsA('BasePart') then
						if v:FindFirstChild('ControlVel') then
							v:FindFirstChild('ControlVel'):Destroy()
						end
						
						if v:FindFirstChild('SafetyBV') then
							v:FindFirstChild('SafetyBV'):Destroy()
						end
						
						if v:FindFirstChild('Holder') and v:FindFirstChild('Holder'):IsA('BodyMover') then
							v:FindFirstChild('Holder'):Destroy()
						end
						
						if not IsEthiron then
							v.CanCollide = false
							v.CollisionGroup = 'VoidMobs'
						end

						if hasNetworkOwnership(v) then
							if IsEthiron then
								local NetworkRetainer = v:FindFirstChild('NetworkRetainer')
								NetworkRetainer.Velocity = Vector3.new(0, -500, 0)
							end

							local cf = v.CFrame
							v.Velocity = velchange
							v.CFrame = CFrame.new(cf.X, voidmode, cf.Z)

							sethiddenproperty(v, "NetworkIsSleeping", false)
						end
					end
				end
			end
		end
	end)
end
---------------------------------------------------------------------------------- VOID MOBS END ----------------------------------------------------------------------------------	

local KB_Archive = {}
local SW_Archive = {}
function Features.NoKillBricks()
	if not Toggles.NoKillBricks.Value then
		Maid.KillBricks = nil

		for i, v in pairs(SW_Archive) do
			table.remove(SW_Archive, i)
			v.Parent = workspace.Layer2Floor1
		end

		for i, v in pairs(KB_Archive) do
			table.remove(KB_Archive, i)
			v.Parent = workspace
		end

		return
	end

	Maid.KillBricks = workspace.ChildAdded:Connect(function(v)
		if v.Name == "KillBrick" or v.Name == "KillPlane" then
			table.insert(KB_Archive, v)
			v.Parent = nil
		end
		if v.Name:match("Chasm") and v:FindFirstChildOfClass('TouchTransmitter') then
			table.insert(KB_Archive, v)
			v.Parent = nil
		end
	end)

	for _, v in pairs(workspace:GetChildren()) do
		if v.Name == "KillBrick" or v.Name == "KillPlane" then
			table.insert(KB_Archive, v)
			v.Parent = nil
		end
	end
	
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:match("Chasm") and v:FindFirstChildOfClass('TouchTransmitter') then
			table.insert(KB_Archive, v)
			v.Parent = nil
		end
	end

	if workspace:FindFirstChild("Layer2Floor1") then
		for _, v in pairs(workspace.Layer2Floor1:GetChildren()) do
			if v.Name == "SuperWall" then
				table.insert(SW_Archive, v)
				v.Parent = nil
			end
		end
	end
end

function Features.TpToGround()
	if not Toggles.TpToGround.Value then
		return
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { workspace.Live, workspace.NPCs }
	params.FilterType = Enum.RaycastFilterType.Blacklist

	if not RootPart or not RootPart.Parent then
		return
	end

	local floor = workspace:Raycast(RootPart.Position, Vector3.new(0, -1000, 0), params)
	if not floor or not floor.Instance then
		return
	end

	local isKillBrick = false

	for _, v in pairs(KB_Archive) do
		if floor.Instance == v.part then
			isKillBrick = true
			break
		end
	end

	if isKillBrick then
		return
	end

	local pos = (RootPart.Position.Y - floor.Position.Y)
	RootPart.CFrame = RootPart.CFrame * CFrame.new(0, -pos + 3, 0)
	RootPart.Velocity = RootPart.Velocity * Vector3.new(1, 0, 1)
end

local Modif_Archive = {}
function Features.NoEchoMod()
	if not Toggles.NoEchoMod.Value then
		for i, v in pairs(Modif_Archive) do
			table.remove(Modif_Archive, i)
			v.Parent = LocalPlayer.Backpack
		end
		return
	end

	repeat
		task.wait(0.5)
	until game:GetService("CollectionService"):HasTag(LocalPlayer.Backpack, "Loaded")

	for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
		if v.Name:match("EchoMod:") then
			table.insert(Modif_Archive, v)
			v.Parent = nil
		end
	end
end

function Features.SanityCounter()
	if not CurrentSanityFrame then
		return
	end

	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local PlayerStatsGui = PlayerGui:WaitForChild("StatsGui")
	local PlayerSurvivalStats = PlayerStatsGui:WaitForChild("SurvivalStats")
	local Stomach = PlayerSurvivalStats:FindFirstChild("Stomach")
	local StomachVisible = Stomach and Stomach.Visible or true
	CurrentSanityFrame.Visible = Toggles.SanityCounter.Value and StomachVisible
	if CurrentChainFrame then
		CurrentChainFrame.Position = (not CurrentSanityFrame.Visible) and CurrentSanityFrame.Position
			or CurrentSanityFrame.Position + UDim2.new(UDim.new(0, 24), UDim.new(0, 0))
	end
end

function Features.PerfectStack()
	if not CurrentChainFrame then
		return
	end

	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local PlayerStatsGui = PlayerGui:WaitForChild("StatsGui")
	local PlayerSurvivalStats = PlayerStatsGui:WaitForChild("SurvivalStats")
	local Stomach = PlayerSurvivalStats:FindFirstChild("Stomach")
	local StomachVisible = Stomach and Stomach.Visible or true
	CurrentChainFrame.Visible = Toggles.PerfectStack.Value and StomachVisible
	if CurrentSanityFrame then
		CurrentChainFrame.Position = (not CurrentSanityFrame.Visible) and CurrentSanityFrame.Position
			or CurrentSanityFrame.Position + UDim2.new(UDim.new(0, 24), UDim.new(0, 0))
	end
end

getgenv().vec3scale = Vector3.new(0, 9e9, 0)
local replicarootpart = nil
function Features.AIBreaker()
	if not Toggles.AIBreaker.Value then
		if not Maid.AIBreaker then
			return
		end

		local fakerootpart = RootPart
		local realrootpart = replicarootpart
		Maid.AIBreaker = nil

		RootPart = realrootpart

		fakerootpart.RootJoint.Part0 = nil
		fakerootpart:Destroy()
		replicarootpart = nil

		realrootpart.RootJoint.Part0 = realrootpart
		realrootpart.Parent = Character
		return
	end

	Maid.AIBreaker = RunService.Heartbeat:Connect(function(deltaTime)
		if not Humanoid or not RootPart then
			return
		end

		if Toggles.AIBreaker2.Value then
			getgenv().vec3scale = Vector3.new(0, -1e5, 0)
		else
			getgenv().vec3scale = Vector3.new(0, 9e9, 0)
		end

		if replicarootpart == nil then
			local fakerootpart = RootPart:Clone()
			local realrootpart = RootPart

			RootPart = fakerootpart
			replicarootpart = realrootpart

			realrootpart.RootJoint.Part0 = nil
			realrootpart.Parent = Humanoid

			fakerootpart.RootJoint.Part0 = RootPart
			fakerootpart.Parent = Character
		end

		local realrootpart = replicarootpart
		local fakerootpart = RootPart

		if realrootpart:FindFirstChildOfClass("BodyVelocity") then
			realrootpart:FindFirstChildOfClass("BodyVelocity").Parent = fakerootpart
		end

		if realrootpart:FindFirstChildOfClass("BodyPosition") then
			realrootpart:FindFirstChildOfClass("BodyPosition").Parent = fakerootpart
		end

		if realrootpart:FindFirstChildOfClass("Weld") then
			realrootpart:FindFirstChildOfClass("Weld").Parent = fakerootpart
			if realrootpart:FindFirstChildOfClass("Weld").Part0 == realrootpart then
				realrootpart:FindFirstChildOfClass("Weld").Part0 = fakerootpart
			end
			if realrootpart:FindFirstChildOfClass("Weld").Part1 == realrootpart then
				realrootpart:FindFirstChildOfClass("Weld").Part1 = fakerootpart
			end
		end

		realrootpart.CFrame = fakerootpart.CFrame

		local v = realrootpart
		local oldVel = v.Velocity
		v.Velocity = v.Velocity * vec3scale
		task.wait()
		v.Velocity = oldVel
	end)
end


local function BasicRetain(v)
	if v:IsA('BasePart') and not v:FindFirstChild('NetworkRetainer') then
        local BV = NetworkBV:Clone()
		BV.Velocity = Vector3.new(0, 0, 0)
        BV.Parent = v

		table.insert(BVs, BV)
    end
end

function Features.TPMob()
	if not Toggles.TPMob.Value then
		Maid.TPMob = nil
		return
	end

	Maid.TPMob = RunService.Heartbeat:Connect(function(deltaTime)
		if not RootPart or not Humanoid then
			return
		end

		sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
		sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)

		for _, v in pairs(workspace.Live:GetChildren()) do
			if
				v ~= LocalPlayer.Character
				and v:FindFirstChild("HumanoidRootPart")
				and (not Players:GetPlayerFromCharacter(v) or Toggles.VoidOnPlayerPickUp.Value)
				and CheckConnectedParts()
			then
				local Character = v
				local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
				for _, v in pairs(Character:GetChildren()) do
					retainPart(v)

					if HumanoidRootPart and hasNetworkOwnership(HumanoidRootPart) then
						HumanoidRootPart.Velocity = Vector3.new(14,14,14)
						HumanoidRootPart.CFrame = RootPart.CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)
						sethiddenproperty(HumanoidRootPart, "NetworkIsSleeping", false)
					end

					if v:IsA('BasePart') then
						if v:FindFirstChild('ControlVel') then
							v:FindFirstChild('ControlVel'):Destroy()
						end
						
						if v:FindFirstChild('SafetyBV') then
							v:FindFirstChild('SafetyBV'):Destroy()
						end
						
						if v:FindFirstChild('SwimBV') then
							v:FindFirstChild('SwimBV'):Destroy()
						end
						
						if v:FindFirstChild('Holder') and v:FindFirstChild('Holder'):IsA('BodyMover') then
							v:FindFirstChild('Holder'):Destroy()
						end

						if hasNetworkOwnership(v) then
							v.Velocity = Vector3.new(14,14,14)
							v.CFrame = RootPart.CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)

							sethiddenproperty(v, "NetworkIsSleeping", false)
						end
					end
				end
			end
		end
	end)
end

function Features.TPMobCamera()
	if not Toggles.TPMobCamera.Value then
		Maid.TPMobCamera = nil
		return
	end

	Maid.TPMobCamera = RunService.Heartbeat:Connect(function(deltaTime)
		if not RootPart or not Humanoid then
			return
		end

		local Camera = workspace.CurrentCamera

		sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
		sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)

		if Toggles.FreecamOnly.Value and not LocalPlayer:HasTag('FreecamEnabled') then
			return
		end

		for _, v in pairs(workspace.Live:GetChildren()) do
			if
				v ~= LocalPlayer.Character
				and v:FindFirstChild("HumanoidRootPart")
				and (not Players:GetPlayerFromCharacter(v) or Toggles.VoidOnPlayerPickUp.Value)
				and CheckConnectedParts()
			then
				local Character = v
				local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
				for _, v in pairs(Character:GetChildren()) do
					retainPart(v)

					if HumanoidRootPart and hasNetworkOwnership(HumanoidRootPart) then
						HumanoidRootPart.Velocity = Vector3.new(14,14,14)
						HumanoidRootPart.CFrame = Camera.CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)
						sethiddenproperty(HumanoidRootPart, "NetworkIsSleeping", false)
					end

					if v:IsA('BasePart') then
						if v:FindFirstChild('ControlVel') then
							v:FindFirstChild('ControlVel'):Destroy()
						end
						
						if v:FindFirstChild('SafetyBV') then
							v:FindFirstChild('SafetyBV'):Destroy()
						end
						
						if v:FindFirstChild('SwimBV') then
							v:FindFirstChild('SwimBV'):Destroy()
						end
						
						if v:FindFirstChild('Holder') and v:FindFirstChild('Holder'):IsA('BodyMover') then
							v:FindFirstChild('Holder'):Destroy()
						end

						if hasNetworkOwnership(v) then
							v.Velocity = Vector3.new(14,14,14)
							v.CFrame = Camera.CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)

							sethiddenproperty(v, "NetworkIsSleeping", false)
						end
					end
				end
			end
		end
	end)
end

function Features.TalentPickerBuilderUrl()
	local BuilderId = string.match(Options.TalentPickerBuilderUrl.Value, "https://deepwoken.co/builder%?id=(.+)")
	if not BuilderId then
		return
	end

	local ApiUrl = ("https://api.deepwoken.co/build?id=%s"):format(BuilderId)
	local Response = request({ Url = ApiUrl, Method = "GET", Headers = { ["Content-Type"] = "application/json" } })

	if not Response or not Response.Success or not Response.Body then
		return Library:Notify("Invalid Builder Url", 2.0)
	end

	TalentPickerData = game:GetService("HttpService"):JSONDecode(Response.Body)
end

function Features.TPMobToTarget()
	if not Toggles.TPMobToTarget.Value then
		Maid.TPMobToTarget = nil
		return
	end

	Maid.TPMobToTarget = RunService.Heartbeat:Connect(function(deltaTime)
		if not RootPart or not Humanoid then
			return
		end

		sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
		sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)

		local LocalPlayer_Name = Options.TPMobToTarget.Value ~= "" and Options.TPMobToTarget.Value or LocalPlayer.Name
		local Target = Players:FindFirstChild(LocalPlayer_Name)

		if not Target.Character then
			return
		end

		if not Target.Character:FindFirstChild("HumanoidRootPart") then
			task.spawn(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, Target.Character:GetPivot().Position, 1)
			return
		end

		for _, v in pairs(workspace.Live:GetChildren()) do
			if
				v ~= LocalPlayer.Character
				and v:FindFirstChild("HumanoidRootPart")
				and (not Players:GetPlayerFromCharacter(v) or Toggles.VoidOnPlayerPickUp.Value)
				and CheckConnectedParts()
			then
				local Character = v
				local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
				for _, v in pairs(Character:GetChildren()) do
					retainPart(v)

					if HumanoidRootPart and hasNetworkOwnership(HumanoidRootPart) then
						HumanoidRootPart.Velocity = Vector3.new(14,14,14)
						HumanoidRootPart.CFrame = Target.Character:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)
						sethiddenproperty(HumanoidRootPart, "NetworkIsSleeping", false)
					end

					if v:IsA('BasePart') then
						if v:FindFirstChild('ControlVel') then
							v:FindFirstChild('ControlVel'):Destroy()
						end
						
						if v:FindFirstChild('SafetyBV') then
							v:FindFirstChild('SafetyBV'):Destroy()
						end
						
						if v:FindFirstChild('SwimBV') then
							v:FindFirstChild('SwimBV'):Destroy()
						end
						
						if v:FindFirstChild('Holder') and v:FindFirstChild('Holder'):IsA('BodyMover') then
							v:FindFirstChild('Holder'):Destroy()
						end

						if hasNetworkOwnership(v) then
							v.Velocity = Vector3.new(14,14,14)
							v.CFrame = Target.Character:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)

							sethiddenproperty(v, "NetworkIsSleeping", false)
						end
					end
				end
			end
		end
	end)
end

local MemStoreService = game:GetService("MemStorageService")
function Features.AutoMaestro()
	if not Toggles.AutoMaestro.Value then
		if not Maid.AutoMaestro then
			return
		end
		Maid.AutoMaestro = nil
		return
	end

	repeat
		task.wait()
	until Character and RootPart and LeftClick

	Library:Toggle()

	if MemStoreService:HasItem("AutoMaestroFight") then
		MemStoreService:RemoveItem("AutoMaestroFight")

		local Maestro

		repeat
			Maestro = workspace.Live:FindFirstChild(".evengarde1")
			task.wait(1.5)
		until Maestro

		local InteractPrompt = Maestro:WaitForChild("InteractPrompt", 7)
		local DialogueFrame = LocalPlayer.PlayerGui:WaitForChild("DialogueGui"):WaitForChild("DialogueFrame")

		if InteractPrompt or not EffectReplicator:FindEffect("Danger") then
			TweenService:Create(RootPart, TweenInfo.new(0.6), {
				CFrame = Maestro.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0),
			}):Play()

			task.wait(1)

			repeat
				fireproximityprompt(InteractPrompt)
				task.wait(1)
			until DialogueFrame.Visible

			VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
			task.wait()
			VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)
		end

		if not Toggles.AIBreaker.Value then
			Toggles.AIBreaker.Value = true
			task.wait()
			Features.AIBreaker()
		end

		if not Toggles.VoidMobs.Value and Toggles.VoidMaestro.Value then
			Toggles.VoidMobs.Value = true
			task.wait()
			Features.VoidMobs()
		end

		Toggles.AIBreaker2:SetValue(true)

		local Weapon = Character and Character:FindFirstChild("Weapon") or LocalPlayer.Backpack:FindFirstChild("Weapon")
		Humanoid:EquipTool(Weapon)

		task.spawn(function()
			repeat
				task.wait(0.3)
			until not DialogueFrame.Visible

			if Toggles.MaestroUseCritical.Value then
				VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
				task.wait(0.1)
				VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game)
				task.wait(0.3)
			end
		end)

		Maid.AutoMaestro = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
			if not workspace.Live:FindFirstChild(".evengarde1") then
				Maid.AutoMaestro = nil
			end

			local MaestroHRP = Maestro:FindFirstChild("HumanoidRootPart")

			if not MaestroHRP then
				return
			end

			local Properties = {
				["W"] = false,
				["A"] = false,
				["S"] = false,
				["D"] = false,
				["Right"] = false,
				["Left"] = false,
				ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl),
			}

			if (MaestroHRP.Position - RootPart.Position).Magnitude < 16 then
				if Toggles.MaestroUseCritical.Value then
					VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
					task.wait(0.1)
					VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game)
					task.wait(0.3)
				end
				LeftClick:FireServer(Utilities:InAir(), Mouse.Hit, Properties)
			end

			local cf = MaestroHRP.CFrame * CFrame.new(0, 0, -3)
			Humanoid:MoveTo(cf.p)
		end))

		local Looted = {}
		ReplicatedStorage.Requests.ToolSplash.OnClientEvent:Connect(function(Tool, Amount)
			local Quantity = Tool:FindFirstChild("Quantity")
			local Name = Tool.Name:match("$") and Tool.Name:split("$")[1] or Tool.Name
			Amount = Amount or Quantity and Quantity.Value or 1
			if not Looted[Name] then
				Looted[Name] = Amount
			else
				Looted[Name] = Looted[Tool] + 1
			end
		end)

		repeat
			task.wait(0.1)
		until not workspace.Live:FindFirstChild(".evengarde1")

		local Chest = workspace.Thrown:WaitForChild("Model")
		Chest:WaitForChild("RootPart")

		VIM:SendKeyEvent(true, Enum.KeyCode.W, false, game)
		task.wait(0.1)
		VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)

		repeat
			local cf = Chest.RootPart.CFrame * CFrame.new(0, 3.5, 0)
			Humanoid:MoveTo(cf.p)
			Character:PivotTo(cf)
			task.wait(1)
			fireproximityprompt(Chest:WaitForChild("InteractPrompt"))
		until LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt")

		repeat
			task.wait(0.1)
		until not LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt")

		repeat
			task.wait(0.1)
		until workspace:FindFirstChild("DungeonExit")
		local DungeonExit = workspace:FindFirstChild("DungeonExit")

		local BaseTemplate = "Maestro Farm Loot, Date: " .. os.date("%x %X") .. "\n"
		local ConstructWord = BaseTemplate
		for i,v in pairs(Looted) do
			ConstructWord = ConstructWord .. i .. (" x%i"):format(v) .. "\n"
		end

		if ConstructWord == BaseTemplate then
			ConstructWord = BaseTemplate .. "Nothing"
		end

		if Options.AutoMaestroWebhook.Value ~= "" then
			request({
				Url = Options.AutoMaestroWebhook.Value,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = game.HttpService:JSONEncode({
					content = "```" .. ConstructWord .. "```",
				}),
			})
		end

		repeat
			Character:PivotTo(DungeonExit.CFrame)
			task.wait(1)
		until not Character or Character.Parent ~= workspace.Live

		MemStoreService:SetItem("AutoMaestroStart", "true")
		return
	end

	local Maestro

	repeat
		Maestro = workspace.NPCs:FindFirstChild("Maestro Evengarde Rest")
		task.wait(1)
	until Maestro and Maestro:FindFirstChild("HumanoidRootPart")

	local InteractPrompt = Maestro:FindFirstChild("InteractPrompt")
	local DialogueFrame = LocalPlayer.PlayerGui:WaitForChild("DialogueGui"):WaitForChild("DialogueFrame")

	repeat
		task.wait(1)
		Humanoid:MoveTo(Maestro.HumanoidRootPart.Position)
	until (RootPart.Position - Maestro.HumanoidRootPart.Position).Magnitude < 20

	repeat
		fireproximityprompt(InteractPrompt)
		task.wait(1)
	until DialogueFrame.Visible

	MemStoreService:SetItem("AutoMaestroFight", "true")

	VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
	task.wait()
	VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)

	MemStoreService:SetItem("AutoMaestroStart", "true")
end

function Features.AutoCharisma()
	if not Toggles.AutoCharisma.Value then
		Maid.AutoCharisma = nil
		return
	end

	local Book_Name = "How to Make Friends"
	local Book = LocalPlayer.Backpack:FindFirstChild(Book_Name) or Character and Character:FindFirstChild(Book_Name)
	if Book then
		Humanoid:EquipTool(Book)
		task.wait(0.5)
		VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
		task.wait()
		VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
	end

	local function getStatMax()
		local MaxStat = Options.CharismaCap.Value ~= "" and tonumber(Options.CharismaCap.Value) or 100

		if MaxStat == 0 then
			MaxStat = 100
		end

		local CurrentStat = tonumber(Character:GetAttribute("Stat_Charisma"))
		if CurrentStat >= MaxStat then
			return
		end

		return true
	end

	Maid.AutoCharisma = LocalPlayer.PlayerGui.ChildAdded:Connect(function(v)
		local ChoiceFrame = v:FindFirstChild("ChoiceFrame")
		if v.Name ~= "ChoicePrompt" or not ChoiceFrame then
			print("nun charisma")
			return
		end

		local DescSheet = ChoiceFrame and ChoiceFrame:FindFirstChild("DescSheet") or nil
		local GuiOptions = ChoiceFrame and ChoiceFrame:FindFirstChild("Options") or nil
		local ChoiceEvent = v:FindFirstChild("ChatChoice")
		print("charisma", DescSheet, GuiOptions)
		if not DescSheet and not GuiOptions then
			if not getStatMax() then
				Humanoid:UnequipTools()
				Maid.AutoCharisma = nil
				Toggles.AutoCharisma:SetValue(false)
				Library:Notify("[Charisma AutoFarm]: Reached Target")
				print("blocked stat")
				return
			end

			local Desc = ChoiceFrame:FindFirstChild("Desc")
			local Text = string.split(Desc.Text, "\n")
			local RealText = string.sub(Text[2], 2, -2)
			task.wait(0.5)
			print("charisma", RealText)
			ChoiceEvent:InvokeServer(RealText)
			task.wait(0.5)

			if not getStatMax() then
				Humanoid:UnequipTools()
				Maid.AutoCharisma = nil
				Toggles.AutoCharisma:SetValue(false)
				Library:Notify("[Charisma AutoFarm]: Reached Target")
				return
			end

			VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
			task.wait()
			VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
		end
	end)
end

function Features.AutoMath()
	if not Toggles.AutoMath.Value then
		Maid.AutoMath = nil
		return
	end

	local Book_Name = "Math Textbook"
	local Book = LocalPlayer.Backpack:FindFirstChild(Book_Name) or Character and Character:FindFirstChild(Book_Name)
	if Book then
		Humanoid:EquipTool(Book)
		task.wait(0.5)
		VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
		task.wait()
		VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
	end

	local function getStatMax()
		local MaxStat = Options.IntelCap.Value ~= "" and tonumber(Options.IntelCap.Value) or 100

		if MaxStat == 0 then
			MaxStat = 100
		end

		local CurrentStat = tonumber(Character:GetAttribute("Stat_Intelligence"))
		if CurrentStat >= MaxStat then
			return
		end

		return true
	end

	Maid.AutoMath = LocalPlayer.PlayerGui.ChildAdded:Connect(function(v)
		local ChoiceFrame = v:FindFirstChild("ChoiceFrame")
		if v.Name ~= "ChoicePrompt" or not ChoiceFrame then
			print("choice prompt math block fr")
			return
		end

		if not getStatMax() then
			Humanoid:UnequipTools()
			Maid.AutoMath = nil
			Toggles.AutoMath:SetValue(false)
			print("math block fr")
			Library:Notify("[Intelligence AutoFarm]: Reached Target")
			return
		end

		local DescSheet = ChoiceFrame and ChoiceFrame:FindFirstChild("DescSheet") or nil
		local Options = ChoiceFrame and ChoiceFrame:FindFirstChild("Options") or nil
		local ChoiceEvent = v:FindFirstChild("Choice")
		local Desc = DescSheet:FindFirstChild("Desc")
		local Operation
	
		if Desc.Text:lower():match("plus") then
			Operation = "plus"
		elseif Desc.Text:lower():match("divided") then
			Operation = "div"
		elseif Desc.Text:lower():match("minus") then
			Operation = "min"
		elseif Desc.Text:lower():match("times") then
			Operation = "mult"
		end

		local Text = string.split(Desc.Text, " ")
		local Num1, Num2 = Text[3], string.gsub(Text[5], "?", "")

		local Solved
		if Operation == "mult" then
			Solved = tonumber(Num1) * tonumber(Num2)
		elseif Operation == "min" then
			Solved = tonumber(Num1) - tonumber(Num2)
		elseif Operation == "plus" then
			Solved = tonumber(Num1) + tonumber(Num2)
		elseif Operation == "div" then
			Num1, Num2 = Text[3], string.gsub(Text[6], "?", "")
			Solved = tonumber(Num1) / tonumber(Num2)
		end

		local Table = {}
		local Buttons = {}

		task.wait(0.05)
	
		for _, Child in pairs(Options:GetChildren()) do
			print(Child, Child.Name)
			if Child:IsA("TextButton") then
				if not tonumber(Child.Text) then
					print("Skipping", Child.Text, "Not a number cuh")
					continue
				end
				local dif = math.abs((tonumber(Child.Text) - Solved))
				warn("Added to table", Child.Text, dif)
				table.insert(Table, dif)
				Buttons[dif] = Child.Name
			end
		end

		table.sort(Table, function(a, b)
			return a < b
		end)
		local Num = Table[1]
		if not Num then
			return warn("No num lol")
		end
		print("automath", Num, Operation)
		task.wait(0.5)
		ChoiceEvent:FireServer(Buttons[Num])
		task.wait(0.5)

		if not getStatMax() then
			Humanoid:UnequipTools()
			Maid.AutoMath = nil
			Toggles.AutoMath:SetValue(false)
			print("math block fr 1")
			Library:Notify("[Intelligence AutoFarm]: Reached Target")
			return
		end

		VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
		task.wait()
		VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
	end)
end

local function FindNearestMob()
	local Mob = nil
	local Distance = 1000
	for _, v in pairs(workspace.Live:GetChildren()) do
		if not v:FindFirstChild("HumanoidRootPart") then
			continue
		end
		if not v:FindFirstChild("Humanoid") then
			continue
		end
		if v:GetAttribute("MOB_species") == 'Human' then
			continue
		end
		if v ~= Character and (v.HumanoidRootPart.Position - RootPart.Position).Magnitude < Distance then
			Distance = (v.HumanoidRootPart.Position - RootPart.Position).Magnitude
			Mob = v
		end
	end

	return Mob
end

local function GetFood()
	local Food = nil
	for i, v in pairs(LocalPlayer.Backpack:GetChildren()) do
		if v:FindFirstChild("Food") and v.Name ~= "Canteen" then
			Food = v
			break
		end
	end
	return Food
end

local function InVoidsea()
	local m_RealmInfo = getgenv().require(ReplicatedStorage.Info.RealmInfo)
	local t_CurrentWorld = m_RealmInfo.CurrentWorld
	local Position = RootPart.Position
	local Area = ReplicatedStorage.MarkerWorkspace:FindPartOnRayWithWhitelist(
		Ray.new(Position, Vector3.new(0, 5000, 0)),
		{ ReplicatedStorage.MarkerWorkspace.AreaMarkers }
	)
	Area = Area and Area.Parent.Name or nil
	local MapCentre = ReplicatedStorage:FindFirstChild("MAP_CENTRE") and ReplicatedStorage.MAP_CENTRE.Value
		or Vector3.new()
	local MAP_BOUNDS = ReplicatedStorage:FindFirstChild("MAP_BOUNDS") and ReplicatedStorage.MAP_BOUNDS.Value
		or Vector3.new(20000, 0, 20000)
	local v67 = Position - MapCentre
	local v68 = Position.y < -100 and t_CurrentWorld == "Depths" or false
	local v69
	if not EffectReplicator:FindEffect("InGuildBase") then
		v69 = not v68
			and (
				(math.abs(v67.x) > MAP_BOUNDS.x or math.abs(v67.z) > MAP_BOUNDS.z)
					and (not Area or Area ~= "The Floating Keep")
				or false
			)
	else
		v69 = false
	end
	return v69
end

local AstralNotified = false
function Features.AutoAstral()
	if not Toggles.AutoAstral.Value then
		if not Maid.AutoAstral then
			return
		end
		Maid.AutoAstral = nil
		Maid.AstralBV = nil
		return
	end

	if not InVoidsea() then
		Library:Notify("You must be in the voidsea before activating this feature.", 5)
		return
	end

	Maid.AstralBV = Utilities.NewBodyMover("BodyVelocity")
	Maid.AstralBV.MaxForce = Vector3.new(9e9, 0, 9e9)
	Maid.AutoAstral = RunService.Heartbeat:Connect(function(deltaTime)
		if not RootPart or not Humanoid or not Character then
			return
		end

		if not Character:FindFirstChild("Stomach") or not Character:FindFirstChild("Water") then
			return
		end

		if MODDETECTED then
			getgenv().MODDETECTED = nil
			ServerHopFunction()
			return
		end

		if not InVoidsea() then
			Library:Notify("Player is outside of voidsea, cancelling autofarm.", 5)
			Toggles.AutoAstral.Value = false
			Maid.AutoAstral = nil
			Maid.AstralBV = nil
			return
		end

		local Carnivore = Toggles.AstralCarnivore.Value
		local Stomach = Character:FindFirstChild("Stomach")
		local Water = Character:FindFirstChild("Water")

		local FoodPercentage = Stomach.Value / Stomach.MaxValue
		local WaterPercentage = Water.Value / Water.MaxValue

		if
			FoodPercentage <= (Options.AstralHungerLevel.Value / 100)
			and WaterPercentage <= (Options.AstralWaterLevel.Value / 100)
		then
			local Mob = FindNearestMob()
			local Tool = Character:FindFirstChildOfClass("Tool")
			local Food = Tool and Tool:FindFirstChild("Food") and Tool or GetFood()
			if Carnivore and Mob then
				if not Character:FindFirstChild("Weapon") then
					Humanoid:EquipTool(LocalPlayer.Backpack.Weapon)
				end

				if (Mob.HumanoidRootPart.Position - RootPart.Position).Magnitude < 20 then
					Maid.AstralBV.Parent = nil
					if not EffectReplicator:FindEffect("LightAttack", true) then
						LeftClick:FireServer(Utilities:InAir(), Mouse.Hit, {
							["W"] = false,
							["A"] = false,
							["S"] = false,
							["D"] = false,
							["Right"] = false,
							["Left"] = false,
							ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl),
						})
					end

					if not EffectReplicator:FindEffect("CriticalCool") then
						VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
						task.wait(0.1)
						VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game)
					end
				else
					local LookCF = CFrame.new(RootPart.Position, Mob.HumanoidRootPart.Position)
					Maid.AstralBV.Velocity = LookCF.LookVector * 60
					Maid.AstralBV.Parent = RootPart
				end

				return
			elseif (not Carnivore or (Carnivore and not Mob)) and Food then
				if not Character:FindFirstChild(Food.Name) then
					Humanoid:EquipTool(Food)
				end

				task.wait(0.3)

				if
					FoodPercentage <= (Options.AstralHungerLevel.Value / 100)
					and WaterPercentage <= (Options.AstralWaterLevel.Value / 100)
				then
					return
				end

				VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
				task.wait()
				VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
			end
		end

		local BellMeteor = nil
		for _, v in pairs(workspace.Thrown:GetChildren()) do
			if v.Name == "BellMeteor" and (v:GetPivot().p - RootPart.Position).Magnitude < 1200 then
				BellMeteor = v
				break
			else
				continue
			end
		end

		if not BellMeteor or (BellMeteor and (BellMeteor:GetPivot().p - RootPart.Position).Magnitude > 1200) then
			AstralNotified = false
			Maid.AstralBV.Velocity = RootPart.CFrame.LookVector * (60 + Options.AstralSpeed.Value)
			Maid.AstralBV.Parent = RootPart
			return
		end

		if BellMeteor then
			Library:Notify("ASTRAL IS IN THE SERVER", 2)
		end

		if
			(BellMeteor:GetPivot().p - RootPart.Position).Magnitude < 1200
			and not AstralNotified
			and Toggles.NotifyAstral.Value
		then
			AstralNotified = true
			request({
				Url = Options.AstralWebhook.Value,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = game:GetService("HttpService"):JSONEncode({
					content = "@everyone ASTRAL BELL METEOR SPAWNED.",
				}),
			})
		end

		if (BellMeteor:GetPivot().p - RootPart.Position).Magnitude < 350 then
			Maid.AstralBV.Parent = nil
			return
		end

		local LookCF = CFrame.new(RootPart.Position, BellMeteor:GetPivot().p)
		Maid.AstralBV.Velocity = LookCF.LookVector * 60
		Maid.AstralBV.Parent = RootPart
	end)
end

local Chests = {}
local CollectionService = game:GetService("CollectionService")

local function onChestAdded(v)
	if not CollectionService:HasTag(v, "Chest") then
		return
	end
	if table.find(Chests, v) then
		return
	end

	table.insert(Chests, v)

	v.AncestryChanged:Connect(function()
		if v.Parent == workspace.Thrown then
			return
		end

		table.remove(Chests, table.find(Chests, v))
	end)
end

function Features.AnimationBlocker()
	if not Toggles.AnimationBlocker.Value then
		Maid.AnimationBlocker = nil
		return
	end

	Maid.AnimationBlocker = Humanoid:WaitForChild("Animator").AnimationPlayed:Connect(function(animationTrack)
		animationTrack:Stop()
	end)
end

function Features.AutoOpenChest()
	if not Toggles.AutoOpenChest.Value then
		Maid.AutoOpenChest = nil
		Maid.AutoOpenChestChild = nil
		return
	end

	for _, v in pairs(workspace.Thrown:GetChildren()) do
		onChestAdded(v)
	end

	Maid.AutoOpenChestChild = workspace.Thrown.ChildAdded:Connect(onChestAdded)
	Maid.AutoOpenChest = task.spawn(function()
		while task.wait() do
			local Distance, Prompt = 12

			for _, v in pairs(Chests) do
				if not v:FindFirstChild("Lid") then
					continue
				end
				if not v:FindFirstChild("InteractPrompt") then
					continue
				end
				if not CollectionService:HasTag(v, "ClosedChest") then
					continue
				end
				if (v.Lid.Position - RootPart.Position).Magnitude >= Distance then
					continue
				end
				Distance = (v.Lid.Position - RootPart.Position).Magnitude
				Prompt = v.InteractPrompt
			end

			if not Prompt then
				continue
			end
			if LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt") then
				continue
			end

			repeat
				fireproximityprompt(Prompt)
				task.wait(0.3)
			until LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt")
				or not Prompt
				or (Prompt.Parent:GetPivot().p - RootPart.Position).Magnitude > 14

			if LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt") then
				warn("Opened Chest")
			end
		end
	end)
end

local HitboxModule = require("Modules/Deepwoken/Hitbox")
function Features.VisualizeHitbox()
	if not Toggles.VisualizeHitbox.Value then
		Maid.VisualizeHitbox = nil
		Maid.HitboxPart = nil
		return
	end

	Maid.HitboxPart = HitboxModule.new(RootPart, Enum.PartType[Options.HitboxShape.Value])

	Maid.VisualizeHitbox = RunService.Heartbeat:Connect(function()
		if not Maid.HitboxPart then
			return
		end

		local Offset_Y = tonumber(Options.Hitbox_YSet.Value)
		local Offset_Z = tonumber(Options.Hitbox_ZSet.Value)

		Maid.HitboxPart.Transparency = Toggles.UsePresetHitbox.Value and 0.9 or 1
		Maid.HitboxPart.CFrame = RootPart.CFrame
		Maid.HitboxPart.Shape = Enum.PartType[Options.HitboxShape.Value]
		Maid.HitboxPart.Size = Vector3.new(Options.Hitbox_X.Value, Options.Hitbox_Y.Value, Options.Hitbox_Z.Value)

		if not Offset_Y or not Offset_Z then
			return
		end

		Maid.HitboxPart.Weld.C0 = CFrame.new(0, Offset_Y, -Offset_Z)
	end)
end

function Features.JetRunAttack()
	if not Toggles.JetRunAttack.Value then
		if Maid.JetRunAttack then
			Maid.JetRunAttack.Disabled = true
		end

		return
	end

	if not Maid.JetRunAttack then
		Maid.JetRunAttack = EffectReplicator:CreateEffect("ForceMomentum", {Value = 10})
	else
		Maid.JetRunAttack.Disabled = false
	end
end

function Features.RunAttack()
	if not Toggles.RunAttack.Value then
		local ServerSprint = Character and Character:FindFirstChild("ServerSprint", true)
		if ServerSprint then
			ServerSprint:FireServer(false)
		end
		return
	end

	local ServerSprint = Character and Character:FindFirstChild("ServerSprint", true)
	if ServerSprint then
		ServerSprint:FireServer(true)
	end
end

function Features.AntiWind()
	if not Toggles.AntiWind.Value then
		Maid.AntiWind = nil
		return
	end

	Maid.AntiWind = RunService.Heartbeat:Connect(function()
		if not RootPart then
			return
		end

		if RootPart:FindFirstChild("WindPusher") then
			RootPart:FindFirstChild("WindPusher").Parent = nil
		end

		local StrongWindPos = EffectReplicator:FindEffect("StrongWind") and EffectReplicator:FindEffect("StrongWind").Value
		local StrongWind = StrongWindPos and workspace.Thrown:FindFirstChild("WindSide")
		
		if StrongWind then
			local cf = CFrame.new(Vector3.new(), StrongWindPos)
			local WindPosition = CFrame.new(workspace.CurrentCamera.CFrame.p) * cf * CFrame.new(3, -5, 50)
			local LookCF = CFrame.new(RootPart.Position, WindPosition.Position)
			RootPart.CFrame = CFrame.new(LookCF.X, RootPart.Position.Y, LookCF.Z)
		end
	end)
end

function Features.PriorityDodgeFrame()
	if not Toggles.PriorityDodgeFrame.Value then
		Maid.PriorityDodgeFrame = nil
		return
	end

	Maid.PriorityDodgeFrame = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		if input.KeyCode == Enum.KeyCode.Q and EffectReplicator:FindEffect("Blocking") then
			local dodgeRemote = getgenv().DodgeRemote
			local unblockRemote = getgenv().UnblockRemote

			if not dodgeRemote or not unblockRemote then
				return
			end

			unblockRemote:FireServer()
			task.wait()
			dodgeRemote:FireServer("roll", nil, nil, false)
		end
	end)
end

function Features.RemoveLootAllCD()
	if not Toggles.RemoveLootAllCD.Value then
		local v1 = getgenv().require(ReplicatedStorage.Info.RealmInfo)
		v1.IsInstanced = false
		return
	end

	local v1 = getgenv().require(ReplicatedStorage.Info.RealmInfo)
	v1.IsInstanced = true
end

function Features.RemoveZoomLimit()
	if not Toggles.RemoveZoomLimit.Value then
		game.Players.LocalPlayer.CameraMaxZoomDistance = 20
		return
	end

	game.Players.LocalPlayer.CameraMaxZoomDistance = 490
end

function Features.ChatSpy()
	local SquadBark = ReplicatedStorage.Requests:WaitForChild("SquadBark")

	if not Toggles.ChatSpy.Value then
		if not Maid.ChatSpy then return end
		for i,v in pairs(Maid.ChatSpy) do
			v:Disconnect()
		end
		
		Maid.ChatSpy = nil
		return
	end

	Maid.ChatSpy = {}
	for i,plr in pairs(Players:GetPlayers()) do
		Maid.ChatSpy[plr] = plr.Chatted:Connect(function(msg)
			if plr == LocalPlayer then
				return
			end

			for i,v in pairs(getconnections(SquadBark.OnClientEvent)) do
				if not v.Function then continue end
				v.Function(msg, {source = plr.Character, author = plr})
			end
		end)
	end
end

local function lazyfix(name)
	name = name:gsub(' ','')

	local result = ''
	for i,v in pairs(name:split('')) do
		result = result .. ' ' .. v
	end

	return result
end

function Features.ShowAllMap()
	if not Toggles.ShowAllMap.Value then
		Maid.ShowAllMap = nil
		return
	end

	task.spawn(function()
		repeat task.wait() until RootPart

		local MapPointerFunc
		for _,v in pairs(getgc(true)) do
			if typeof(v) ~= "function" then continue end
			if iscclosure(v) or isexecutorclosure(v) then continue end
			local info = debug.getinfo(v)
			local scr_name = info.source
			local encode_constant = HttpService:JSONEncode(debug.getconstants(v))
			if scr_name:match('MapClient') and encode_constant:match('CharacterName') then
				MapPointerFunc = v
				warn('Found mappointerfunc '..tostring(v))
			end
		end
		
		if not MapPointerFunc then
			return
		end
		
		local function addtomap(v)
			if v == LocalPlayer.Character then return end
			if not Players:GetPlayerFromCharacter(v) then return end
			local Humanoid = v:FindFirstChild('Humanoid')

			if Humanoid and Humanoid:GetAttribute('CharacterName') then
				local org = Humanoid:GetAttribute('CharacterName')
				Humanoid:SetAttribute('CharacterName', lazyfix(org))
				task.delay(.5, function()
					Humanoid:SetAttribute('CharacterName', org)
				end)
			end

			SecureCall(MapPointerFunc, v)
		end
		
		for i,v in pairs(workspace.Live:GetChildren()) do
			addtomap(v)
		end
	
		Maid.ShowAllMap = workspace.Live.ChildAdded:Connect(addtomap)
	end)
end

local PromptTag = 'InteractProxPrompt'

---@param Prompt ProximityPrompt
local function ExtendDistance(Prompt)
	if not Prompt:IsA('ProximityPrompt') then
		return
	end
	
	local ActivationDistance = Prompt.MaxActivationDistance
	Prompt:SetAttribute('OldActivationDistance', ActivationDistance)
	Prompt.MaxActivationDistance = ActivationDistance * 2
end

---@param Prompt ProximityPrompt
local function RevertDistance(Prompt)
	if not Prompt:IsA('ProximityPrompt') or not Prompt:GetAttribute('OldActivationDistance') then
		return
	end
	
	local ActivationDistance = Prompt:GetAttribute('OldActivationDistance')
	Prompt:SetAttribute('OldActivationDistance', nil)
	Prompt.MaxActivationDistance = ActivationDistance
end

function Features.ExtendPromptDistance()
	if not Toggles.ExtendPromptDistance.Value then
		Maid.ExtendPromptDistance = nil
		for _, Prompt in pairs(CollectionService:GetTagged(PromptTag)) do
			SecureSpawn(RevertDistance, Prompt)
		end
		return
	end

	Maid.ExtendPromptDistanceAdded = CollectionService:GetInstanceAddedSignal(PromptTag):Connect(ExtendDistance)

	for _, Prompt in pairs(CollectionService:GetTagged(PromptTag)) do
		SecureSpawn(ExtendDistance, Prompt)
	end
end

function Features.NotifyVoidEvents()
	if not Toggles.NotifyVoidEvents.Value then
		Maid.NotifyVoidEvents = nil
		return
	end

	---@param event Model
	Maid.NotifyVoidEvents = workspace.ChildAdded:Connect(function(event)
		if event:GetAttribute('ChestPool') == 'VoidseaChest' then
			local EventName = event.Name
			local EventMobs = event:GetAttribute('MobSpawn')
			
			local message = "A Voidsea Event spawned @everyone\nEventType: %s\nEventMobs:%s"
			message = message:format(EventName, EventMobs)

			Toggles.AutoAstral:SetValue(false)

			if EventMobs:match('mudskipper') then
				Toggles.VoidMobs:SetValue(true)
			else
				Toggles.VoidMobs:SetValue(false)
			end
			
			Library:Notify('Voidsea Event spawned', 5)
		end
	end)
end

---@module Modules/Deepwoken/Replication
local Replication = require("Modules/Deepwoken/Replication")
function Features.CustomESP()
	if not Toggles.CustomESP.Value then
		Replication.ClearTrackers()
		return
	end

	local function OnLiveAdded(child)
		local HumanoidRootPart = child:WaitForChild("HumanoidRootPart", 9e9)
		if not HumanoidRootPart then
			return
		end

		Replication.HealthTracker({
			Character = child
		})
	end

	for _, v in pairs(workspace.Live:GetChildren()) do
		SecureSpawn(OnLiveAdded, v)
	end
	
	for _, v in pairs(workspace.NPCs:GetChildren()) do
		SecureSpawn(OnLiveAdded, v)
	end
end

function Features.AutoRefreshESP()
	if not Toggles.AutoRefreshESP.Value then
		Maid.AutoRefreshESP = nil
		return
	end

	Maid.AutoRefreshESP = task.spawn(function()
		while Toggles.AutoRefreshESP.Value do
			task.wait(Options.AutoRefreshESP.Value)
			SecureCall(getgenv().Maid.ESP)
			task.wait(3)
			SecureCall(getgenv().StartESP)
		end
	end)
end

local function cleanUpTalentPicker()
	local TalentGui = LocalPlayer.PlayerGui:FindFirstChild("TalentGui")
	if not TalentGui then
		return
	end

	local ChoiceFrame = TalentGui:FindFirstChild("ChoiceFrame")
	if not ChoiceFrame then
		return
	end

	for _, v in pairs(ChoiceFrame:GetChildren()) do
		if not v:IsA("TextButton") then
			continue
		end

		local CardFrame = v:FindFirstChild("CardFrame")
		if not CardFrame then
			continue
		end

		CardFrame.BorderSizePixel = 0
	end
end

task.spawn(function()
	repeat
		task.wait()
	until getgenv().SouLoaded

	do -- Get stream around players when we're spectating them
		Maid:GiveTask(RunService.PreRender:Connect(function()
			if not workspace.CurrentCamera.CameraSubject then
				return
			end

			if workspace.CurrentCamera.CameraSubject.Parent == LocalPlayer.Character then
				return
			end

			if not workspace.CurrentCamera.CameraSubject.Parent then
				return
			end

			if not workspace.CurrentCamera.CameraSubject.Parent:IsA("Model") then
				return
			end

			if workspace.StreamingEnabled then
				task.spawn(
					LocalPlayer.RequestStreamAroundAsync,
					LocalPlayer,
					workspace.CurrentCamera.CameraSubject.Parent:GetPivot().Position,
					1
				)
			end
		end))
	end
	
	do -- Damage Indicator & Custom ESP
		local CharList = {}

		---@param child Model
		local function OnLiveAdded(child)
			---@type Humanoid
			local HumanoidRootPart = child:WaitForChild("HumanoidRootPart", 9e9)
			if not HumanoidRootPart then
				return
			end

			local Humanoid = child:WaitForChild("Humanoid", 9e9)
			if not Humanoid or CharList[Humanoid] then
				return
			end
			
			local LastHP = Humanoid.Health
			CharList[child] = true

			child.Destroying:Once(function()
				pcall(function()
					CharList[child] = nil
				end)
			end)
			
			HumanoidRootPart.Destroying:Once(function()
				pcall(function()
					CharList[child] = nil
				end)
			end)

			Maid:GiveTask(Humanoid.HealthChanged:Connect(function()
				local HP = Humanoid.Health

				local Color = Color3.fromRGB(255, 0, 0)
				local diff = HP - LastHP
				if diff >= 0 then
					Color = Color3.fromRGB(0, 255, 0)
				end
				
				LastHP = HP

				if diff >= -0.5 and diff <= 0.5 then
					return
				end

				if Toggles.DamageIndicator.Value and child.Parent == workspace.Live then
					Replication.DamageReadout({
						root = HumanoidRootPart,
						msg = diff,
						col = Color
					})
				end
			end))

			if Toggles.CustomESP.Value then
				Replication.HealthTracker({
					Character = child
				})
			end
		end

		Maid:GiveTask(workspace.Live.ChildAdded:Connect(OnLiveAdded))
		Maid:GiveTask(workspace.NPCs.ChildAdded:Connect(OnLiveAdded))

		for _, v in pairs(workspace.Live:GetChildren()) do
			SecureSpawn(OnLiveAdded, v)
		end
		
		for _, v in pairs(workspace.NPCs:GetChildren()) do
			SecureSpawn(OnLiveAdded, v)
		end
	end

	do -- Constant tween
		Maid:GiveTask(RunService.PreSimulation:Connect(tweenToObjective))
	end

	do -- AP breaker
		Maid:GiveTask(RunService.PreRender:Connect(apBreakerLoop))
	end

	do -- onAdded Connections
		Maid.PlayerAdded = Players.PlayerAdded:Connect(onPlayerAdded)
		for _, v in pairs(Players:GetPlayers()) do
			SecureSpawn(onPlayerAdded, v)
		end

		Maid:GiveTask(LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
		if LocalPlayer.Character then
			SecureSpawn(onCharacterAdded, LocalPlayer.Character)
		end
	end

	do -- Clean-up talent picker
		Maid.TalentPicker = cleanUpTalentPicker
	end

	do -- Clean-up streamer mode
		Maid.StreamerMode = function()
			StreamerMode.Revert()
		end
	end

	SecureSpawn(SpawnNewFrame, 1)
	SecureSpawn(SpawnNewFrame, 2)

	do -- Rapier NPC
		local Common_Name = {'Treasurer','Banker','Antiquarian','Gunsmith','Barber','Blacksmith','Mystic','Guild Librarian','Eiris','Guild Chef','Artisan'}
		Maid:GiveTask(workspace.NPCs.ChildAdded:Connect(function(v)
			if table.find(Common_Name, v.Name) then
				return
			end
			if not Toggles.NotifyNPC.Value then return end
			Library:Notify("NEW NPC Added: "..v.Name .. '. Please check NPC ESP for its location', 5)
		end))

		Maid:GiveTask(workspace.Live.ChildAdded:Connect(function(v)
			if v.Name:lower():match('ministrycache') then
				if not Toggles.NotifyNPC.Value then return end
				Library:Notify("Deepspindle Mob has spawned", 5)
			end
		end))

		for i,v in pairs(workspace.NPCs:GetChildren()) do
			if v.Name:lower():match('ministrycache') or v.Name:lower():match('silhuett') then
				if not Toggles.NotifyNPC.Value then return end
				Library:Notify("Silhuett NPC is in the server", 5)
			end
		end
		
		for i,v in pairs(workspace.Live:GetChildren()) do
			if v.Name:lower():match('ministrycache') then
				if not Toggles.NotifyNPC.Value then return end
				Library:Notify("Deepspindle mob is in the server", 5)
			end
		end
	end
end)

getgenv().Maid.FeaturesMaid = Maid

return Features
