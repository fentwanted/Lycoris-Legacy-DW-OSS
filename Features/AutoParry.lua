local function GetBodyParts(Character)
	return Character and Character:FindFirstChild("HumanoidRootPart"),
		Character and Character:FindFirstChild("Humanoid")
end

local EffectHandlerLogs = {}
local VIM = Instance.new("VirtualInputManager")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local EffectHandler = getgenv().require(ReplicatedStorage:WaitForChild("EffectReplicator"))
local Maid = getgenv().Maid

getgenv().ProjectileConfigs = {}
getgenv().SoundConfigs = {}
local Utilities = require("Modules/Utilities")
local KeyHandler = require("Modules/Deepwoken/KeyHandler")

if not _G.playerFPS then -- so it dont run multiple time when u reexec
	_G.playerFPS = 0
	task.spawn(function()
		local i = 0
		local fps = 0
		while true do
			fps = fps + 1
			i = i + task.wait()
			if i >= 1 then
				_G.playerFPS = fps
				fps = 0
				i = 0
			end
		end
	end)
end

local function Dodge()
	if not Toggles.AutoParry.Value and not Toggles.AutoParryV2.Value then
		return
	end
	
	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	local dodgeRemote = getgenv().DodgeRemote

	if EffectHandler:FindEffect("Parry") then
		return
	end

	for _, v in pairs(EffectHandler.Effects) do
		if table.find(Utilities.RollChecks, rawget(v, "Class")) then
			rawset(EffectHandler.Effects, v.Disabled, true)
			task.delay(0.15, function()
				rawset(EffectHandler.Effects, v.Disabled, false)
			end)
		end
	end

	if Toggles.BlatantRoll.Value then
		dodgeRemote:FireServer("roll", nil, nil, false)
		return
	end

	VIM:SendKeyEvent(true, "Q", false, game)
	if Toggles.RollCancel.Value then
		task.spawn(function()
			task.wait(Options.RollCancelDelay.Value / 1000)
			if not EffectHandler:FindEffect("LightAttack") then
				mouse2click()
			end
		end)
	end
	task.wait(0.1)
	VIM:SendKeyEvent(false, "Q", false, game)
end

local function Parry()
	if not Toggles.AutoParry.Value and not Toggles.AutoParryV2.Value then
		return
	end
	
	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	local blockRemote = getgenv().BlockRemote
	local unblockRemote = getgenv().UnblockRemote

	if
		(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
		and Toggles.AutoFeint.Value
	then
		mouse2click()
	end

	local loopAmount = math.floor(_G.playerFPS * 0.1) + 1
	loopAmount = loopAmount >= 12 and 12 or loopAmount
	local callAmount = math.ceil(12 / loopAmount)

	if
		(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
			and not EffectHandler:FindEffect("NoRoll")
		or not EffectHandler:FindEffect("Equipped")
	then
		if Toggles.RollOnParryCDDelay.Value then
			task.wait(Options.RollOnParryCDDelaySlider.Value / 1000)
		end
		Dodge()
		return
	end

	local st = tick()
	for _ = 1, loopAmount do
		for _ = 1, callAmount do
			blockRemote:FireServer()
		end
		task.wait()
	end

	task.wait()

	unblockRemote:FireServer()
end

local function RawParry()
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end

	local loopAmount = math.floor(_G.playerFPS * 0.1) + 1
	loopAmount = loopAmount >= 12 and 12 or loopAmount
	
	local blockRemote = getgenv().BlockRemote
	local unblockRemote = getgenv().UnblockRemote

	local callAmount = math.ceil(12 / loopAmount)

	for _ = 1, loopAmount do
		for _ = 1, callAmount do
			blockRemote:FireServer()
		end
		task.wait()
	end

	task.wait()

	unblockRemote:FireServer()
end

local oldwarn = warn
local function warn(Message, Duration)
	if not Toggles.AutoParry.Value then return end
	if not Toggles.ParryNotifs.Value then
		return
	end
	getgenv().Library:Notify(Message, Duration or 1.5)
end

local WeaponDatabase = {}
local MobDatabase = {}
task.spawn(function()
	for _, Anim in pairs(game:GetService("ReplicatedStorage").Assets.Anims.Weapon:GetChildren()) do
		for _, v in pairs(Anim:GetDescendants()) do
			if
				v:IsA("Animation")
				and (
					v.Name:match("Slash")
					or v.Name:match("AerialStab")
					or v.Name:match("Uppercut")
					or v.Name:match("Whip")
				)
			then
				WeaponDatabase[v.AnimationId] = {
					Name = v.Name,
					AnimName = Anim.Name,
				}
			end
		end
	end
	for _, Anim in pairs(game:GetService("ReplicatedStorage").Assets.Anims.Mobs:GetChildren()) do
		for _, v in pairs(Anim:GetDescendants()) do
			if v:IsA("Animation") and v.Name ~= "RunningAttack" then
				MobDatabase[v.AnimationId] = {
					Name = v.Name,
					AnimName = Anim.Name,
				}
			end
		end
	end
end)

local function GetWeaponType(Animation)
	local Anim = WeaponDatabase[Animation.AnimationId]
	if Anim then
		return Anim.Name, Anim.AnimName
	end
	return nil
end

local function IsMobAnimation(Animation)
	return MobDatabase[Animation.AnimationId] ~= nil
end

getgenv().WeaponConfig = {
	Dagger = 200,
	Rapier = 150,
	Flintlock = 150,
	Karate = 200,
	LanternKarate = 320,
	PurpleCloud = 300,
	["Jus Karita"] = 200,
	["Legion Kata"] = 200,
	Sword = 300,
	TestSword = 300,
	DualSword = 300,
	Rifle = 250,
	Spear = 320,
	Mace = 250,
	FirstLight = 350,
	Scythe = 350,
	Railblade = 350,
	Greataxe = 350,
	Greatstaff = 350,
	Greathammer = 350,
	Greatsword = 350,
	BigIron = 350,
	ImperialStaff = 300,
	PyreKeeper = 350,
	Inferno = 300,
}

local blacklisted = {
	"rbxassetid://5808247302",
	"rbxassetid://180435792",
	"rbxassetid://10380978324",
	"rbxassetid://5554732065",
	"rbxassetid://6010566363",
}
local blacklistedsounds = {
	"rbxassetid://4340253186",
	"rbxassetid://6084644097",
}
local blacklistedsoundname = {
	"Audio/sliding",
	"unsheathe2",
	"altswish",
	"sheathe",
	"punch2",
	"steam",
	"menuhover4",
	"roll",
}
local blacklistedprojectiles = {
	"RainTop",
	"ArmsEquipment__Torso",
	"LegsEquipment__Opposite",
	"FaceEquipment",
	"Finger",
	"TorsoEquipment",
	"ArmsEquipment",
	"LegsEquipment",
	"Torso",
	"Head",
	"Right Arm",
	"Left Arm",
	"Left Leg",
	"NewDirt",
	"Right Leg",
	"FallDirt",
	"MovementLines",
}
local blacklistedname = {
	"saber",
	"sprint",
	"airdash",
	"dropanim",
	"fallanim",
	"walk",
	"idle",
	"movement",
	"roll",
	"draw",
	"block",
	"parry",
	"shakeblock",
	"spit",
	"vault",
	"slide",
	"hit",
	"stagger",
	"knock",
	"pinned",
	"execute",
	"run",
	"parried",
}
local AnimsDB = game:GetService("ReplicatedStorage").Assets.Anims

for _, v in pairs(AnimsDB:GetChildren()) do
	if v:IsDescendantOf(AnimsDB.Movement) or v:IsDescendantOf(AnimsDB.Gestures) and v:IsA("Animation") then
		table.insert(blacklisted, v.AnimationId)
	end
end

getgenv().LoggedAnimations = {}
getgenv().LoggedProjectiles = {}
getgenv().LoggedSounds = {}

local function toAssetNumber(AssetId)
	return tonumber(AssetId:sub(14, 40))
end

local function LogProjectile(ProjectileName)
	pcall(function()
		if
			table.find(blacklistedprojectiles, ProjectileName)
			or table.find(LoggedProjectiles, ProjectileName)
			or not Toggles.LogProjectiles.Value
		then
			return
		end

		table.insert(LoggedProjectiles, ProjectileName)

		Options.LoggedProjectiles.Values = LoggedProjectiles
		Options.LoggedProjectiles:SetValues(LoggedProjectiles)
	end)
end

local function LogSound(SoundId)
	pcall(function()
		local Name = game:GetService("MarketplaceService"):GetProductInfo(toAssetNumber(SoundId)).Name:gsub(" ", "_")

		if
			table.find(blacklistedsounds, SoundId)
			or table.find(LoggedSounds, Name .. " " .. toAssetNumber(SoundId))
			or not Toggles.LogSounds.Value
		then
			return
		end

		for _, v in pairs(blacklistedsoundname) do
			if Name:lower():match(v) then
				return
			end
		end

		table.insert(LoggedSounds, Name .. " " .. toAssetNumber(SoundId))

		Options.LoggedSounds.Values = LoggedSounds
		Options.LoggedSounds:SetValues(LoggedSounds)
	end)
end

local function LogAnimation(AnimationId)
	pcall(function()
		local Name =
			game:GetService("MarketplaceService"):GetProductInfo(toAssetNumber(AnimationId)).Name:gsub(" ", "_")

		if
			table.find(blacklisted, AnimationId)
			or table.find(LoggedAnimations, Name .. " " .. toAssetNumber(AnimationId))
			or not Toggles.LogAnimations.Value
		then
			return
		end

		for _, v in pairs(blacklistedname) do
			if Name:lower():match(v) then
				return
			end
		end

		table.insert(LoggedAnimations, Name .. " " .. toAssetNumber(AnimationId))

		Options.LoggedAnimations.Values = LoggedAnimations
		Options.LoggedAnimations:SetValues(LoggedAnimations)
	end)
end

local function DebugNotify(self, Message)
	--print(self.Range, Message, self.Character.Name)
	if self.Range and self.Range < 50 then
		Library:Notify(Message, 2)
	end
end

local function SetBlockInput(ID, Value, Priority)
	-- see if we already have block input running, and check if we should overwrite it cause of Roll only attacks
	if Status.Busy and ID ~= Status.ID and not Priority then
		return
	end

	-- see if current is a roll only or not
	if Priority and Status.Priority and ID ~= Status.ID then
		return
	end

	-- replace the current block input ID if it's settings to false
	if Status.ID and Status.Busy == Value then
		Status.ID = nil
		Status.Maid = nil
	end

	Status.ID = ID
	if Value then
		--DebugNotify({Range = 0}, "Blocking Input [Start]")
	else
		--DebugNotify({Range = 0}, "Blocking Input [End]")
	end

	Status.Maid = Maid:GiveTask(task.spawn(function()
		Status.Busy = Value

		-- incase something fucked it up and just doesnt remove the busy status
		task.wait(2.5)

		-- see if its still the same id
		if Status.ID ~= ID then
			return
		end

		Status.Priority = false
		Status.Busy = false
		Status.ID = nil
		Status.Maid = nil
	end))

	if Status.Priority and not Value then
		Status.Priority = false
	end
end

local function FeintCheck(Character)
	local RootPart = Character:WaitForChild("HumanoidRootPart", 9e9)
	local Sounds = RootPart:FindFirstChild("Sounds")
	local Feint = Sounds and Sounds:FindFirstChild("Feint")
	if not Status[Character] then
		return
	end
	if Feint then
		Status[Character].Maid[Character.Name .. "_feintcheck"] = Feint.Played:Connect(function()
			local PlayerRoot, _ = GetBodyParts(Player.Character)

			if (PlayerRoot.Position - RootPart.Position).Magnitude > 25 then
				return
			end

			if Character == Player.Character then
				return
			end

			if not Toggles.AutoParry.Value then
				return
			end

			if (RootPart.CFrame.Position - Player.Character:GetPivot().Position).Magnitude > 50 then
				return
			end
			
			if Toggles.ReactFeint.Value then
				return
			end

			Status[Character].Feinted = true
			task.delay(0.15, function()
				Status[Character].Feinted = false
			end)

			warn("Entity [" .. Character.Name .. "] Caught Feinting (Main)", 1.5)

			if Toggles.RollOnFeint.Value and not EffectHandler:FindEffect("NoRoll") then
				warn("Entity [" .. Character.Name .. "] Rolled On Feint (Main)", 1.5)
				Dodge()
			end
		end)

		Status[Character].Maid[Character.Name .. "_feintcheck_ended"] = Feint.Ended:Connect(function()
			Status[Character].Feinted = false
		end)
	end

	Status[Character].Maid[Character.Name .. "_feintcheck_added"] = RootPart.ChildAdded:Connect(function(v)
		if not v:IsA("Sound") or v.Name ~= "Feint" then
			return
		end

		if not Toggles.AutoParry.Value then
			return
		end
		
		if Toggles.ReactFeint.Value then
			return
		end

		Status[Character].Feinted = true

		task.delay(0.15, function()
			Status[Character].Feinted = false
		end)

		if (RootPart.CFrame.Position - Player.Character:GetPivot().Position).Magnitude > 50 then
			return
		end

		warn("Entity [" .. Character.Name .. "] Caught Feinting (Backup)", 1.5)

		if Toggles.RollOnFeint.Value and not EffectHandler:FindEffect("NoRoll") then
			warn("Entity [" .. Character.Name .. "] Rolled On Feint (Backup)", 1.5)
			Dodge()
		end
	end)
end

local RequireMaid = require("Modules/Maid")
local function Register(Character)
	if Status[Character] then
		return
	end

	Status[Character] = {
		Maid = RequireMaid.new(),
	}

	Maid[Character.Name .. "_Maid"] = Status[Character].Maid

	local IsMob = Character.Name:sub(1, 1) == "."
	local Humanoid = Character:WaitForChild("Humanoid", 9e9)
	task.spawn(FeintCheck, Character)

	Status[Character].Maid[Character.Name .. "_removal"] = Character.ChildRemoved:Connect(function(child)
		if child.Name == "Humanoid" then
			Status[Character].Maid:DoCleaning()
			Status[Character] = nil
		end
	end)

	local function mandatoryChecks()
		if not Toggles.AutoParry.Value then
			return
		end

		local RootPart = Character:FindFirstChild("HumanoidRootPart")
		if not RootPart then
			return
		end

		local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)
		if not UserRootPart or not UserHumanoid then
			return
		end

		if (RootPart.Position - UserRootPart.Position).Magnitude > 1000 then
			return
		end

		return true
	end

	local function CheckFacing()
		local RootPart = Character:FindFirstChild("HumanoidRootPart")
		local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)
		if not UserRootPart or not UserHumanoid then
			return
		end

		local DeltaOnTargetToLocal = (UserRootPart.Position - RootPart.Position).Unit
		local DeltaOnLocalToTarget = (RootPart.Position - UserRootPart.Position).Unit
		local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1
		local LocalToTargetResult = RootPart.CFrame.LookVector:Dot(DeltaOnLocalToTarget) <= -0.1

		if Toggles.TargetFaceYou.Value and not Toggles.FacingTarget.Value then
			return LocalToTargetResult
		end

		if Toggles.FacingTarget.Value and not Toggles.TargetFaceYou.Value then
			return TargetToLocalResult
		end

		if Toggles.TargetFaceYou.Value and Toggles.FacingTarget.Value then
			return TargetToLocalResult and LocalToTargetResult
		end

		return true
	end

	local function SanityCheck(Range, ID, AnimationConfig)
		local RootPart = Character:FindFirstChild("HumanoidRootPart")
		local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)
		if not UserRootPart or not UserHumanoid then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if not Humanoid or not RootPart then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		local Torso = Character:FindFirstChild("Torso")
		if Torso and Torso:FindFirstChild("Bone") and Torso.Bone:IsA("BasePart") then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if Status[Character].Feinted then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			Status[Character].Feinted = false
			return
		end

		if (RootPart.Position - UserRootPart.Position).Magnitude > Range then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		local particle = Character and Character:FindFirstChild("MegalodauntBroken", true)
		if particle and particle:IsA("ParticleEmitter") and particle.Enabled then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		return true
	end

	local function SetFeint()
		Status[Character].Feinted = true
		task.delay(0.1, function()
			Status[Character].Feinted = false
		end)
	end

	local function AutoParryInit(AnimationTrack)
		local RootPart = Character:FindFirstChild("HumanoidRootPart")
		if AnimationTrack.Priority == Enum.AnimationPriority.Core then
			return
		end

		if Toggles.AutoParryV2.Value then
			return
		end

		-- nice AP blocker bro.
		if AnimationTrack.WeightTarget <= 0.01 then
			return
		end

		if not IsMob and IsMobAnimation(AnimationTrack.Animation) then
			return
		end

		if not mandatoryChecks() then
			return
		end

		local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)

		if
			Toggles.LogAnimations.Value
			and (RootPart.Position - UserRootPart.Position).Magnitude <= Options.LogAnimations_Range.Value
		then
			LogAnimation(AnimationTrack.Animation.AnimationId)
		end

		if not IsMob and Options.AutoParryTarget.Value ~= "Players" and Options.AutoParryTarget.Value ~= "All" then
			return
		end

		if (RootPart.Position - UserRootPart.Position).Magnitude > 600 then
			return
		end

		local Whitelists = Options.AutoParryWhitelist.Value
		if Whitelists and Whitelists ~= "" then
			if typeof(Whitelists) == "string" then
				Whitelists = { Whitelists }
			end
		end

		if typeof(Whitelists) == "table" and Whitelists[Character.Name] then
			return
		end

		local AnimationConfig = Config[AnimationTrack.Animation.AnimationId]
		local Ping = (game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000)
			* (Options.PingAdjustment.Value / 100)

		local AnimationName, WeaponType = GetWeaponType(AnimationTrack.Animation)
		if WeaponType and not AnimationConfig then
			if not WeaponConfig[WeaponType] then
				warn("Weapon Type Not Found: " .. WeaponType, 1.5)
				return
			end

			AnimationConfig = {
				Name = AnimationName,
				Range = AnimationName == "AerialStab" and 30 or 20,
				Wait = AnimationName == "AerialStab" and WeaponConfig[WeaponType] + 0.1 or WeaponConfig[WeaponType],
				Delay = false,
				DelayDistance = 0,
				RepeatParryAmount = 0,
				RepeatParryDelay = 0,
				Roll = false,
				DefaultWeapon = true,
			}

			local HandWeapon = Character:FindFirstChild("RightHand")
				and Character:FindFirstChild("RightHand"):FindFirstChild("HandWeapon")
			if HandWeapon and (AnimationName:match("Slash") or AnimationName:match("Whip")) then
				AnimationConfig.Range = HandWeapon.Stats.Length.Value * 2
			end

			if WeaponType == "Dagger" then
				AnimationConfig.Range = math.clamp(HandWeapon.Stats.Length.Value * 2.3, 15, 23)
			end

			if Toggles.AutoParryV3 and not Toggles.AutoParryV3.Value then
				return
			end
		end

		if not AnimationConfig then
			if Character == Player.Character and not Toggles.LogPlayerAnimations.Value then
				return
			end
			return
		end

		if Character == Player.Character and not Toggles.ParrySelfAnimations.Value then
			return
		end

		if
			Character:FindFirstChild("Target")
			and Character.Target.Value ~= Player.Character
			and not Toggles.IgnoreTarget.Value
		then
			return
		end

		if
			AnimationTrack.Animation.AnimationId == "rbxassetid://9657469282"
			and not (Toggles.ParryVent.Value or Toggles.DodgeVent.Value)
		then
			return
		end

		local isPlayer = Players:GetPlayerFromCharacter(Character)
		local WaitTime = AnimationConfig.Wait
		local Delay = AnimationConfig.Delay
		local DelayDistance = AnimationConfig.DelayDistance
		local ParryAmount = AnimationConfig.RepeatParryAmount or 0
		local Roll = not Toggles.ParryOnly.Value and AnimationConfig.Roll or false
		local RepeatDelay = AnimationConfig.RepeatParryDelay or 0
		local RepeatUntilAnimationEnd = AnimationConfig.RepeatUntilAnimationEnd or false
		local Range = AnimationConfig.Range
		local st = tick()

		if Toggles.DodgeVent.Value and AnimationTrack.Animation.AnimationId == "rbxassetid://9657469282" then
			Roll = true
		end

		if not AnimationConfig.DefaultWeapon and WaitTime > 0 and not AnimationConfig.IgnoreCustom then
			WaitTime = WaitTime + 120
		end

		if not AnimationConfig.DefaultWeapon and RepeatDelay > 0 and not AnimationConfig.IgnoreCustom then
			RepeatDelay = RepeatDelay + 120
		end

		if ParryAmount == 0 then
			ParryAmount = 1
		else
			ParryAmount = ParryAmount + 1
		end

		if -- Hivelord Hubris
			table.find({
				"rbxassetid://5064195992",
				"rbxassetid://5067090007",
				"rbxassetid://5067105317",
			}, AnimationTrack.Animation.AnimationId)
			and Character:FindFirstChild("Weapon")
			and Character:FindFirstChild("Weapon").Weapon.Value == "Hivelord's Hubris"
		then
			if AnimationTrack.Animation.AnimationId == "rbxassetid://5067090007" then
				Range = 40
			end

			WaitTime = 500
		end

		if -- Flareblood Kamas
			table.find({
				"rbxassetid://12106091136",
				"rbxassetid://12106093579",
				"rbxassetid://12106095892",
			}, AnimationTrack.Animation.AnimationId)
			and Character:FindFirstChild("Weapon")
			and Character:FindFirstChild("Weapon").Weapon.Value == "Flareblood Kamas"
		then
			WaitTime = 200
		end

		if
			(
				Character:FindFirstChild("Enchant:Nemesis")
				or (isPlayer and isPlayer.Backpack:FindFirstChild("Enchant:Nemesis"))
			) and AnimationTrack.Animation.AnimationId == "rbxassetid://7827886914"
		then
			WaitTime = 610
			Range = 40
		end

		if AnimationConfig.Name == "Uppercut" then
			Range = 30
		end

		if Character:FindFirstChild("SilentheartTorso") and AnimationConfig.Name == "Uppercut" then
			Range = 60
		end

		local AnimName = AnimationConfig.Name
		if AnimationTrack.Speed > 1 then
			--[{"rbxassetid://6432260013":{"RepeatParryDelay":410,"CustomConfig":true,"Range":100,"Wait":390,"DelayDistance":0,"Roll":false,"RepeatParryAmount":2,"Name":"PrimaTriple","Delay":false,"selfid":"rbxassetid://6432260013"}}]
			--[{"rbxassetid://6347657585":{"RepeatParryDelay":0,"CustomConfig":true,"Range":100,"Wait":400,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"PrimaStomp1","Delay":false,"selfid":"rbxassetid://6347657585"}}]
			--[{"rbxassetid://6438111139":{"RepeatParryDelay":0,"CustomConfig":true,"Range":100,"Wait":600,"DelayDistance":0,"Roll":true,"RepeatParryAmount":0,"Name":"PrimaPunt","Delay":false,"selfid":"rbxassetid://6438111139"}}]
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6438111139" then
				WaitTime = 750
				AnimName = "Rage_" .. AnimName
			end
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6347657585" then
				WaitTime = 550
				AnimName = "Rage_" .. AnimName
			end
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6432260013" then
				RepeatDelay = 530
				WaitTime = 390 + 150
				AnimName = "Rage_" .. AnimName
			end
		else
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6438111139" then
				WaitTime = WaitTime + 150
			end
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6347657585" then
				WaitTime = WaitTime + 150
			end
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6432260013" then
				RepeatDelay = RepeatDelay + 300
				WaitTime = WaitTime + 300
			end
		end

		WaitTime = WaitTime + Options.AutoParryOffset.Value
		RepeatDelay = RepeatDelay + Options.AutoParryOffset.Value

		local Cancelled = false
		local WaitTimePing = (WaitTime / 1000) - Ping
		local CalculatedTime = string.format("%.2f", WaitTimePing)
		if CalculatedTime:sub(-3) == ".00" then
			CalculatedTime = string.format("%.0f", CalculatedTime)
		end

		local ID = HttpService:GenerateGUID(false)
		SetBlockInput(ID, true, AnimationConfig.Roll)

		if Roll then
			if
				(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
				and Toggles.AutoFeint.Value
			then
				if
					(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
					or not EffectHandler:FindEffect("UsingSpell")
				then
					mouse2click()
				end
			end
		end

		task.delay(WaitTimePing / 4, function()
			if not SanityCheck(Range, ID, AnimationConfig) then
				SetBlockInput(ID, false, AnimationConfig.Roll)
				Cancelled = true
				return
			end

			if not AnimationTrack.IsPlaying then
				SetFeint()
				SetBlockInput(ID, false, AnimationConfig.Roll)
				Cancelled = true
				return
			end
		end)

		task.delay(WaitTimePing / 2, function()
			if not SanityCheck(Range, ID, AnimationConfig) then
				SetBlockInput(ID, false, AnimationConfig.Roll)
				Cancelled = true
				return
			end

			if not AnimationTrack.IsPlaying then
				SetFeint()
				SetBlockInput(ID, false, AnimationConfig.Roll)
				Cancelled = true
				return
			end
		end)

		warn("Waiting " .. AnimationConfig.Name .. " [" .. WaitTimePing .. "]", 1.5)
		task.wait(WaitTimePing)

		if Cancelled then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if not SanityCheck(Range, ID, AnimationConfig) then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if Delay then
			local s_tick = tick()
			repeat
				task.wait()
			until (RootPart.Position - UserRootPart.Position).Magnitude <= DelayDistance or tick() - s_tick > 2.5
		end

		if not SanityCheck(Range, ID, AnimationConfig) then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if not CheckFacing() then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if EffectHandler:FindEffect("ParryCool") and EffectHandler:FindEffect("NoRoll") and Roll then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if
			(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
				and not EffectHandler:FindEffect("NoRoll")
			or not EffectHandler:FindEffect("Equipped")
		then
			Roll = true
		end

		if
			(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
			and Toggles.AutoFeint.Value
		then
			if
				(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
				or not EffectHandler:FindEffect("UsingSpell")
			then
				mouse2click()
			end
		end

		local ShouldRoll = math.random(0, 100) <= Options.RollPercentage.Value
		if ShouldRoll and not EffectHandler:FindEffect("NoRoll") and not Roll then
			Roll = true
		end

		local ShouldParry = math.random(0, 100) <= Options.ParryChance.Value
		if not Roll and not ShouldParry then
			return
		end

		if Roll then
			if not SanityCheck(Range, ID, AnimationConfig) then
				SetBlockInput(ID, false, AnimationConfig.Roll)
				return
			end

			task.spawn(Dodge)

			warn("Dodging " .. AnimationConfig.Name .. " [" .. CalculatedTime .. "]", 1.5)

			task.wait(0.31)
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		local function InnerParry(i)
			if not SanityCheck(Range, ID, AnimationConfig) then
				return
			end

			if not CheckFacing() then
				return
			end

			if EffectHandlerLogs.Stun then
				return
			end

			if
				(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
					and not EffectHandler:FindEffect("NoRoll")
				or not EffectHandler:FindEffect("Equipped")
			then
				task.spawn(Dodge)
			end

			if not EffectHandler:FindEffect("ParryCool") then
				task.spawn(Parry)
			end

			warn("Parrying " .. AnimationConfig.Name .. " [" .. CalculatedTime .. "]", 1.5)

			task.wait(i ~= ParryAmount and (RepeatDelay / 1000) or 0)
		end

		if RepeatUntilAnimationEnd then
			repeat
				if not Character or not Character:IsDescendantOf(game) then
					break
				end

				if not mandatoryChecks() then
					break
				end

				InnerParry()

				task.wait()
			until not AnimationTrack.IsPlaying
		else
			for i = 1, ParryAmount do
				InnerParry(i)
			end
		end

		task.wait(Roll and 0.5 or 0.15)

		SetBlockInput(ID, false, AnimationConfig.Roll)
	end

	Status[Character].Maid[Character.Name .. "_AnimationPlayed"] = Humanoid.AnimationPlayed:Connect(AutoParryInit)
end

local function RegisterSound(Character)
	if Status[Character] then
		return
	end

	if not Character:IsA("Sound") then
		return
	end

	if not Character.Parent then
		return
	end

	Status[Character] = {
		Maid = RequireMaid.new(),
	}

	Maid[Character.Name .. "_Maid"] = Status[Character].Maid

	Status[Character].Maid[Character.Name .. "_removal"] = Character.AncestryChanged:Connect(function(_)
		if Character and Character:IsDescendantOf(game) then
			return
		end

		Status[Character].Maid:DoCleaning()
		Status[Character] = nil
	end)

	local function AutoParryInit(SoundId)
		local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)
		if not UserRootPart or not UserHumanoid then
			return
		end

		local CurrentPosition = UserRootPart.Position

		if Character.Parent:IsA("BasePart") then
			CurrentPosition = Character.Parent.Position
		end

		local RootPart = Character.Parent:FindFirstChild("HumanoidRootPart")
		if Character.Parent:IsA("Model") and RootPart then
			CurrentPosition = RootPart.Position
		end

		if
			Toggles.LogSounds.Value
			and (CurrentPosition - UserRootPart.Position).Magnitude <= Options.LogSounds_Range.Value
		then
			LogSound(SoundId)
		end

		local SoundConfig = SoundConfigs[SoundId]
		if not SoundConfig then
			return
		end

		local WaitTime = SoundConfig.Wait
		local Delay = SoundConfig.Delay
		local DelayDistance = SoundConfig.DelayDistance
		local ParryAmount = SoundConfig.RepeatParryAmount or 0
		local Roll = not Toggles.ParryOnly.Value and SoundConfig.Roll or false
		local RepeatDelay = SoundConfig.RepeatParryDelay or 0
		local Range = SoundConfig.Range

		Status[Character] = {
			Maid = RequireMaid.new(),
		}

		Maid[Character.Name .. "_Maid"] = Status[Character].Maid

		Status[Character].Maid[Character.Name .. "_removal"] = Character.AncestryChanged:Connect(function(_)
			if not Character or not Character:IsDescendantOf(game) then
				return
			end

			Status[Character].Maid:DoCleaning()
			Status[Character] = nil
		end)

		local function mandatoryChecks()
			if not Toggles.AutoParry.Value then
				return
			end

			if (CurrentPosition - UserRootPart.Position).Magnitude > 1000 then
				return
			end

			return true
		end

		local function CheckFacing()
			if not UserRootPart or not UserHumanoid then
				return
			end

			local DeltaOnTargetToLocal = (UserRootPart.Position - CurrentPosition).Unit
			local DeltaOnLocalToTarget = (CurrentPosition - UserRootPart.Position).Unit
			local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1
			local LocalToTargetResult = Character.Parent.CFrame.LookVector:Dot(DeltaOnLocalToTarget) <= -0.1

			if Toggles.TargetFaceYou.Value and not Toggles.FacingTarget.Value then
				return TargetToLocalResult
			end

			if Toggles.FacingTarget.Value and not Toggles.TargetFaceYou.Value then
				return LocalToTargetResult
			end

			if Toggles.TargetFaceYou.Value and Toggles.FacingTarget.Value then
				return TargetToLocalResult and LocalToTargetResult
			end

			return true
		end

		local function SanityCheck(ID)
			if not UserRootPart or not UserHumanoid then
				return
			end

			if (CurrentPosition - UserRootPart.Position).Magnitude > Range then
				return
			end

			return true
		end

		if not mandatoryChecks() then
			return
		end

		if (CurrentPosition - UserRootPart.Position).Magnitude > 600 then
			return
		end

		local Ping = (game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000)
			* (Options.PingAdjustment.Value / 100)
		local st = tick()
		if ParryAmount == 0 then
			ParryAmount = 1
		else
			ParryAmount = ParryAmount + 1
		end

		WaitTime = WaitTime + Options.AutoParryOffset.Value
		RepeatDelay = RepeatDelay + Options.AutoParryOffset.Value

		local Cancelled = false
		local WaitTimePing = (WaitTime / 1000) - Ping
		local CalculatedTime = string.format("%.2f", WaitTimePing)
		if CalculatedTime:sub(-3) == ".00" then
			CalculatedTime = string.format("%.0f", CalculatedTime)
		end

		local ID = HttpService:GenerateGUID(false)

		if Roll then
			if
				(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
				and Toggles.AutoFeint.Value
			then
				if
					(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
					or not EffectHandler:FindEffect("UsingSpell")
				then
					mouse2click()
				end
			end
		end

		task.delay(WaitTimePing / 4, function()
			if not SanityCheck() then
				Cancelled = true
				return
			end
		end)

		task.delay(WaitTimePing / 2, function()
			if not SanityCheck() then
				Cancelled = true
				return
			end
		end)

		warn("Waiting " .. SoundConfig.Name .. " [" .. WaitTimePing .. "]", 1.5)
		task.wait(WaitTimePing)

		if Cancelled then
			return
		end

		if not SanityCheck() then
			return
		end

		if Delay then
			local s_tick = tick()
			repeat
				task.wait()
			until (CurrentPosition - UserRootPart.Position).Magnitude <= DelayDistance or tick() - s_tick > 2.5
		end

		if not SanityCheck() then
			return
		end

		if not CheckFacing() then
			return
		end

		if EffectHandler:FindEffect("ParryCool") and EffectHandler:FindEffect("NoRoll") and Roll then
			return
		end

		if
			(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
				and not EffectHandler:FindEffect("NoRoll")
			or not EffectHandler:FindEffect("Equipped")
		then
			Roll = true
		end

		if
			(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
			and Toggles.AutoFeint.Value
		then
			if
				(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
				or not EffectHandler:FindEffect("UsingSpell")
			then
				mouse2click()
			end
		end

		local ShouldRoll = math.random(0, 100) <= Options.RollPercentage.Value
		if ShouldRoll and not EffectHandler:FindEffect("NoRoll") and not Roll then
			Roll = true
		end

		local ShouldParry = math.random(0, 100) <= Options.ParryChance.Value
		if not Roll and not ShouldParry then
			return
		end

		if Roll then
			if not SanityCheck() then
				return
			end

			task.spawn(Dodge)

			warn("Dodging " .. SoundConfig.Name .. " [" .. CalculatedTime .. "]", 1.5)

			task.wait(0.31)
			return
		end

		for i = 1, ParryAmount do
			if not SanityCheck() then
				break
			end

			if not CheckFacing() then
				return
			end

			if EffectHandlerLogs.Stun then
				break
			end

			if
				(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
					and not EffectHandler:FindEffect("NoRoll")
				or not EffectHandler:FindEffect("Equipped")
			then
				task.spawn(Dodge)
			end

			if not EffectHandler:FindEffect("ParryCool") then
				task.spawn(Parry)
			end

			task.wait(i ~= ParryAmount and (RepeatDelay / 1000) or 0)
		end

		task.wait(Roll and 0.5 or 0.15)
	end

	Status[Character].Maid[Character.Name .. "_SoundPlayed"] = Character.Played:Connect(AutoParryInit)
end

local function RegisterProjectile(Character)
	if Status[Character] then
		return
	end

	if not Character:IsA("BasePart") and not Character:IsA("Attachment") then
		return
	end

	if Character.Name == "Part" or Character.Name == "Attachment" then
		return
	end

	local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)
	if not UserRootPart or not UserHumanoid then
		return
	end

	if
		Toggles.LogProjectiles.Value
		and (Character.Position - UserRootPart.Position).Magnitude <= Options.LogProjectiles_Range.Value
	then
		LogProjectile(Character.Name)
	end

	local ProjectileConfig = ProjectileConfigs[Character.Name]
	if not ProjectileConfig then
		return
	end

	local WaitTime = ProjectileConfig.Wait
	local ParryAmount = ProjectileConfig.RepeatParryAmount or 0
	local Roll = not Toggles.ParryOnly.Value and ProjectileConfig.Roll or false
	local RepeatDelay = ProjectileConfig.RepeatParryDelay or 0
	local MinRange = ProjectileConfig.MinRange
	local MaxRange = ProjectileConfig.MaxRange
	local ID = HttpService:GenerateGUID(false)

	-- Handle range if there is no max / min range
	if not MaxRange and not MinRange then
		MinRange = 0
		MaxRange = ProjectileConfig.Range
	end

	Status[Character] = {
		Maid = RequireMaid.new(),
	}

	Maid[Character.Name .. "_Maid"] = Status[Character].Maid

	Status[Character].Maid[Character.Name .. "_removal"] = Character.AncestryChanged:Connect(function(_)
		if not Character or not Character:IsDescendantOf(game) then
			return
		end

		Status[Character].Maid:DoCleaning()
		Status[Character] = nil
	end)

	local function mandatoryChecks()
		if not Toggles.AutoParry.Value then
			return
		end

		if (Character.Position - UserRootPart.Position).Magnitude > 1000 then
			return
		end

		return true
	end

	local function CheckFacing()
		if not UserRootPart or not UserHumanoid then
			return
		end

		local DeltaOnTargetToLocal = (UserRootPart.Position - Character.Position).Unit
		local DeltaOnLocalToTarget = (Character.Position - UserRootPart.Position).Unit
		local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1
		local LocalToTargetResult = Character.CFrame.LookVector:Dot(DeltaOnLocalToTarget) <= -0.1

		if Toggles.TargetFaceYou.Value and not Toggles.FacingTarget.Value then
			return TargetToLocalResult
		end

		if Toggles.FacingTarget.Value and not Toggles.TargetFaceYou.Value then
			return LocalToTargetResult
		end

		if Toggles.TargetFaceYou.Value and Toggles.FacingTarget.Value then
			return TargetToLocalResult and LocalToTargetResult
		end

		return true
	end

	local function SanityCheck(ID)
		if not UserRootPart or not UserHumanoid then
			SetBlockInput(ID, false, false)
			return
		end

		local CurrentRange = (Character.Position - UserRootPart.Position).Magnitude
		if CurrentRange < MinRange or CurrentRange > MaxRange then
			SetBlockInput(ID, false, false)
			return
		end

		return true
	end

	local function AutoParryInit()
		if not mandatoryChecks() then
			return
		end

		if (Character.Position - UserRootPart.Position).Magnitude > 600 then
			return
		end

		local Ping = (game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000)
			* (Options.PingAdjustment.Value / 100)
		local st = tick()
		if ParryAmount == 0 then
			ParryAmount = 1
		else
			ParryAmount = ParryAmount + 1
		end

		WaitTime = WaitTime + Options.AutoParryOffset.Value
		RepeatDelay = RepeatDelay + Options.AutoParryOffset.Value

		local Cancelled = false
		local WaitTimePing = (WaitTime / 1000) - Ping
		local CalculatedTime = string.format("%.2f", WaitTimePing)
		if CalculatedTime:sub(-3) == ".00" then
			CalculatedTime = string.format("%.0f", CalculatedTime)
		end

		SetBlockInput(ID, true, false)

		if Roll then
			if
				(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
				and Toggles.AutoFeint.Value
			then
				if
					(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
					or not EffectHandler:FindEffect("UsingSpell")
				then
					mouse2click()
				end
			end
		end

		task.delay(WaitTimePing / 4, function()
			if not SanityCheck() then
				SetBlockInput(ID, false, false)
				Cancelled = true
				return
			end
		end)

		task.delay(WaitTimePing / 2, function()
			if not SanityCheck() then
				SetBlockInput(ID, false, false)
				Cancelled = true
				return
			end
		end)

		warn("Waiting " .. ProjectileConfig.Name .. " [" .. WaitTimePing .. "]", 1.5)
		task.wait(WaitTimePing)

		if Cancelled then
			SetBlockInput(ID, false, false)
			return
		end

		if not SanityCheck() then
			SetBlockInput(ID, false, false)
			return
		end

		if not CheckFacing() then
			SetBlockInput(ID, false, false)
			return
		end

		if EffectHandler:FindEffect("ParryCool") and EffectHandler:FindEffect("NoRoll") and Roll then
			SetBlockInput(ID, false, false)
			return
		end

		if
			(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
				and not EffectHandler:FindEffect("NoRoll")
			or not EffectHandler:FindEffect("Equipped")
		then
			Roll = true
		end

		if
			(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
			and Toggles.AutoFeint.Value
		then
			if
				(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
				or not EffectHandler:FindEffect("UsingSpell")
			then
				mouse2click()
			end
		end

		local ShouldRoll = math.random(0, 100) <= Options.RollPercentage.Value
		if ShouldRoll and not EffectHandler:FindEffect("NoRoll") and not Roll then
			Roll = true
		end

		local ShouldParry = math.random(0, 100) <= Options.ParryChance.Value
		if not Roll and not ShouldParry then
			return
		end

		if Roll then
			if not SanityCheck() then
				SetBlockInput(ID, false, false)
				return
			end

			task.spawn(Dodge)

			warn("Dodging " .. ProjectileConfig.Name .. " [" .. CalculatedTime .. "]", 1.5)

			task.wait(0.31)
			SetBlockInput(ID, false, false)
			return
		end

		for i = 1, ParryAmount do
			if not SanityCheck() then
				break
			end

			if not CheckFacing() then
				return
			end

			if EffectHandlerLogs.Stun then
				break
			end

			if
				(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
					and not EffectHandler:FindEffect("NoRoll")
				or not EffectHandler:FindEffect("Equipped")
			then
				task.spawn(Dodge)
			end

			if not EffectHandler:FindEffect("ParryCool") then
				task.spawn(Parry)
			end

			task.wait(i ~= ParryAmount and (RepeatDelay / 1000) or 0)
		end

		task.wait(Roll and 0.5 or 0.15)
	end

	if not MinRange or not MaxRange then
		return warn("Blocked projectile - range is not setup", 1.5)
	end

	local CurrentRange = (Character.Position - UserRootPart.Position).Magnitude
	if CurrentRange <= MinRange then
		return warn("Blocked projectile - range is below minimum", 1.5)
	end

	while task.wait() do
		CurrentRange = (Character.Position - UserRootPart.Position).Magnitude
		if CurrentRange >= MinRange and CurrentRange <= MaxRange then
			break
		end
	end

	AutoParryInit()

	SetBlockInput(ID, false, false)

	if Status[Character] and Status[Character].Maid then
		Status[Character].Maid:DoCleaning()
		Status[Character] = nil
	end
end

local function pingWait(n)
	local Ping = (game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000)
		* (Options.PingAdjustment.Value / 100)
	return task.wait(n - Ping)
end

local function checkRange(range, part)
	local myRootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if not myRootPart or not part then
		return false
	end

	if typeof(part) == "Vector3" then
		part = { Position = part }
	end

	return (myRootPart.Position - part.Position).Magnitude <= range
end

local function checkRangeFromPing(obj, rangeCheck, speed)
	local myRootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if not myRootPart then
		return false
	end

	local distance = (obj.Position - myRootPart.Position).Magnitude
	local playerPing = game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() * 2

	distance = (obj.Position - myRootPart.Position).Magnitude
	distance = distance - speed * (playerPing / 1000)

	return distance <= rangeCheck, distance, playerPing / speed
end

local function OnCharacterAdded(Character)
	Character:WaitForChild("HumanoidRootPart", 9e9)
	task.wait(1)
	Maid[Character.Name .. "__EffectAdded"] = EffectHandler.EffectAdded:Connect(function(effect)
		if effect.Class == "Stun" then
			EffectHandlerLogs.Stun = true
			task.delay(0.12, function()
				EffectHandlerLogs.Stun = false
			end)
		end
	end)
	if Character ~= Players.LocalPlayer.Character then
		Maid[Character.Name .. "__ProjectileDescendantAdded"] = Character.DescendantAdded:Connect(RegisterProjectile)
		for i, v in next, Character:GetDescendants() do
			task.spawn(RegisterProjectile, v)
		end
		Maid[Character.Name .. "__SoundDescendantAdded"] = Character.DescendantAdded:Connect(RegisterSound)
		for i, v in next, Character:GetDescendants() do
			task.spawn(RegisterSound, v)
		end
	end
end

getgenv().RawParry = RawParry
getgenv().Parry = Parry
getgenv().Dodge = Dodge
getgenv().pingWait = pingWait
getgenv().logProjectile = LogProjectile
getgenv().logSound = LogSound
getgenv().checkRange = checkRange
getgenv().checkRangeFromPing = checkRangeFromPing

require("Modules/Deepwoken/CustomConfigs")

Maid.AutoParryChildAdded = workspace.Live.ChildAdded:Connect(Register)
for i, v in next, workspace.Live:GetChildren() do
	task.spawn(Register, v)
end

Maid.AutoParryThrown = workspace.Thrown.DescendantAdded:Connect(RegisterProjectile)
for i, v in next, workspace.Thrown:GetDescendants() do
	task.spawn(RegisterProjectile, v)
end

Maid.AutoParrySounds = workspace.DescendantAdded:Connect(RegisterSound)
for i, v in next, workspace:GetDescendants() do
	task.spawn(RegisterSound, v)
end

Maid.AutoParryCharAdded = Player.CharacterAdded:Connect(OnCharacterAdded)
if Player.Character then
	OnCharacterAdded(Player.Character)
end
