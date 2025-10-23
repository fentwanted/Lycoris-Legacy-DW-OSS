local function SaveRetrieve(url)
	local Result = nil

	repeat
		Result = grabBody(url)
		if not Result then
			task.wait(3)
		end
	until Result ~= nil

	return Result
end

local VIM = Instance.new("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

local Maid = getgenv().Maid
local robloxRequire = getgenv().require

local WeaponDatabase = {}
local MobDatabase = {}

local EffectLog = {} do
	function EffectLog:FindEffect(Class)
		for _,v in pairs(EffectLog) do
			if typeof(v) == "function" then continue end
			if v.Class == Class then
				return v
			end
		end
	end
end

local HitboxModule = require("Modules/Deepwoken/Hitbox")
local RequireMaid = require("Modules/Maid")
local EffectHandler = robloxRequire(ReplicatedStorage:WaitForChild("EffectReplicator"))

task.spawn(function()
	for _, Anim in pairs(game:GetService("ReplicatedStorage").Assets.Anims.Weapon:GetChildren()) do
		for _, v in pairs(Anim:GetDescendants()) do
			if v:IsA("Animation") and ( v.Name:match("Slash") or v.Name:match("AerialStab") or v.Name:match("Uppercut") or v.Name:match("Whip") )
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
			if v:IsA("Animation") then
				MobDatabase[v.AnimationId] = {
					Name = v.Name,
					AnimName = Anim.Name,
				}
			end
		end
	end
end)

local BlacklistedAnims = {}
local BlacklistedDescName = {"ShakeBlock","Equip","Stunned","Idle","Block","Parry","Execute","Walk","Crawl","TrueParry1","TrueParry2"}
local BlacklistedNames = {"FallAnim","TrueStunBreak","Jump","HitAnim1","HitAnim2","HitAnim3","ShakeBlock","DropAnim","New2handedParry","Wakeup","AirDash","FlintlockBlock","Block1","newParried","NewHitAnim1","Block2","stagger","ParryTest","2handedblock","2handedtrueparry","2handalternateparry","Guardchill","GuardIdle1","FlintlockIdle","SpearBlockShake"}
task.spawn(function()
	for i,v in pairs(game:GetService("ReplicatedStorage").Assets.Anims:GetDescendants()) do
		if v:IsDescendantOf(game:GetService("ReplicatedStorage").Assets.Anims.Weapon) and not table.find(BlacklistedDescName,v.Name) then
			continue
		end
		if v:IsDescendantOf(game:GetService("ReplicatedStorage").Assets.Anims.Mobs) and not table.find(BlacklistedDescName,v.Name) then
			continue
		end
		if v:IsA("Animation") then
			table.insert(BlacklistedAnims, v.AnimationId)
		end
	end
end)

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

local function DebugNotify(self, Message)
	if self.Range and self.Range < 50 and Toggles.ParryNotifs.Value then
		Library:Notify(Message, 2)
	end
end

local function GetWeaponType(AnimationId)
	local Anim = WeaponDatabase[AnimationId]
	if Anim then
		return Anim.Name, Anim.AnimName
	end
	return nil
end

local function IndicateHighlight()
	if not Toggles.VisualizeHitbox.Value then
		return
	end

	local Indicator = Instance.new("Highlight")
	Indicator.Adornee = Character
	Indicator.FillColor = Color3.fromRGB(90, 127, 230)
	Indicator.OutlineColor = Color3.fromRGB(90, 127, 230)
	Indicator.OutlineTransparency = 0
	Indicator.FillTransparency = 0.5
	Indicator.Parent = workspace.Thrown

	game:GetService("TweenService"):Create(Indicator, TweenInfo.new(0.3), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	game.Debris:AddItem(Indicator, 0.3)
end

local function CreateHitbox(self, Range, HitboxPreset)
	local Indicator = HitboxModule.new(self.Character.HumanoidRootPart, Enum.PartType.Block)

	task.delay(.1, function()
		if not Toggles.VisualizeHitbox.Value then
			return
		end
		Indicator.Transparency = 0.5
		game:GetService("TweenService"):Create(Indicator, TweenInfo.new(0.2), { Transparency = 1 }):Play()
	end)

	if HitboxPreset and HitboxPreset.X then
		local m = Options.HitboxMultiplier.Value
		Indicator.Weld.C0 = CFrame.new(0, HitboxPreset.YSet, -HitboxPreset.ZSet)
		Indicator.Size = Vector3.new(HitboxPreset.X*m, HitboxPreset.Y*m, HitboxPreset.Z*m)
	else
		Indicator.Size = Vector3.new(Range, Range, Range)
	end

	local Hitted = HitboxModule.scan(Indicator, Character)
	game.Debris:AddItem(Indicator, 0.25)

	return Hitted
end

local function MakeBaseHitbox(self, Range, HitboxPreset)
	local Indicator = HitboxModule.new(self.Character.HumanoidRootPart, Enum.PartType.Block)

	task.delay(.1, function()
		if not Toggles.VisualizeHitbox.Value then
			return
		end
		Indicator.Transparency = 0.5
	end)

	if HitboxPreset and HitboxPreset.X then
		Indicator.Weld.C0 = CFrame.new(0, HitboxPreset.YSet, -HitboxPreset.ZSet)
		Indicator.Size = Vector3.new(HitboxPreset.X, HitboxPreset.Y, HitboxPreset.Z)
	else
		Indicator.Size = Vector3.new(Range, Range, Range)
	end

	return Indicator
end

local function toAssetNumber(AssetId)
	return tonumber(AssetId:sub(14, 40))
end

local function LogAnimation(AnimationId)
	pcall(function()
		local Name = game:GetService("MarketplaceService"):GetProductInfo(toAssetNumber(AnimationId)).Name:gsub(" ", "_")

		if table.find(BlacklistedAnims, AnimationId) or table.find(LoggedAnimations, Name .. " " .. toAssetNumber(AnimationId)) or not Toggles.LogAnimations.Value
		then
			return
		end

		if table.find(BlacklistedNames, Name) then
			return
		end

		table.insert(LoggedAnimations, Name .. " " .. toAssetNumber(AnimationId))

		Options.LoggedAnimations.Values = LoggedAnimations
		Options.LoggedAnimations:SetValues(LoggedAnimations)
	end)
end

local function GetBodyParts(Character)
	return Character and Character:FindFirstChild("HumanoidRootPart"), Character and Character:FindFirstChild("Humanoid")
end

local function CalculatedWait(waittime)
	local num = waittime
	local Ping = game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000
	num = num - ( Ping * ( Options.PingAdjustment.Value / 100 ) )
	return num
end

local function CanFeint()
	local FeintCooldown = EffectLog:FindEffect("FeintCool")
	local MidAttack = EffectLog:FindEffect("MidAttack")
	if MidAttack and (tick() - MidAttack.Time) > 0.45 then
		return
	end

	if FeintCooldown then
		return
	end

	return true
end

local function AttemptFeint(IgnoreCD)
	if not CanFeint() and not IgnoreCD then
		-- will be a toggle soon, just for debugging
		--Dodge(true)
		return
	end

	if Toggles.AutoParryDebug.Value then
		return
	end

	VIM:SendMouseButtonEvent(1, 1, 1, true, game, 1)
	task.wait()
	VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)

	task.delay(.2	, function()
		VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)
	end)
end

local function IsAttacking(checkMantra)
    return EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack", true) or (checkMantra and EffectHandler:FindEffect("UsingSpell", true))
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
	if Toggles.BlockInputNotifs.Value then
		if Value then
			DebugNotify({Range = 0}, "Blocking Input [Start]")
		else
			DebugNotify({Range = 0}, "Blocking Input [End]")
		end
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

local function Dodge(ForceBlatant)
	local dodgeRemote = getgenv().DodgeRemote

	if EffectHandler:FindEffect("Parry") then
		return
	end

	if Toggles.AutoParryDebug.Value then
		return
	end
	
	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	if Toggles.BlatantRoll.Value or ForceBlatant then
		dodgeRemote:FireServer("roll", nil, nil, false)

        for _, v in pairs(EffectHandler.Effects) do
            if table.find({
				"UsingSpell",
				"NoAttack",
				"Dodged",
				"PreventRoll",
				"Stun",
				"Action",
				"Carried",
				"MobileAction",
				"PreventAction",
				"LightAttack",
				"Blocking",
				"ClientSlide",
				"NoParkour",
				"Knocked",
				"Unconscious",
			}, rawget(v, "Class")) then
                rawset(EffectHandler.Effects, v.Disabled, true)
                task.delay(0.15, function()
                    rawset(EffectHandler.Effects, v.Disabled, false)
                end)
            end
        end
	end

	VIM:SendKeyEvent(true, "Q", false, game)

	if Toggles.RollCancel.Value then
		task.delay(Options.RollCancelDelay.Value / 1000, AttemptFeint, true)
	end

	task.wait(0.05)

	VIM:SendKeyEvent(false, "Q", false, game)
end

local function Parry()
	local blockRemote = getgenv().BlockRemote
	local unblockRemote = getgenv().UnblockRemote

	if Toggles.AutoParryDebug.Value then
		return
	end

	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	if IsAttacking() and Toggles.AutoFeint.Value then
		AttemptFeint()
	end

	local loopAmount = math.floor(_G.playerFPS * 0.1) + 1
	loopAmount = loopAmount >= 12 and 12 or loopAmount

	local callAmount = math.ceil(12 / loopAmount)

	for _ = 1, loopAmount do
		for _ = 1, callAmount do
			blockRemote:FireServer()
		end
		task.wait()
	end

	unblockRemote:FireServer()
end

local function HasHeavyHands(self)
	local found = false
	for _,v in pairs(self.Character:GetChildren()) do
		if v:GetAttribute('EquipmentRef') == "Heavy Hands Ring" then
			found = true
			break
		end
	end

	return found
end

local function DeepCopyTable(tab)
	local newTab = {}

	for k, v in pairs(tab) do
		if type(v) == "table" then
			newTab[k] = DeepCopyTable(v)
		else
			newTab[k] = v
		end
	end

	return newTab
end

local function GetConfig(self, AnimationID, Speed)
	local AnimationName, WeaponType = GetWeaponType(AnimationID)
	local AnimationConfig = getgenv().Config[AnimationID]

    if AnimationConfig then
        AnimationConfig = DeepCopyTable(AnimationConfig)
    end

	if not AnimationConfig and WeaponType then
		if not WeaponConfig[WeaponType] then
			return warn("No Animation Config or M1 Config for weapon type: " .. WeaponType)
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

		local HandWeapon = self.Character:FindFirstChild("RightHand") and self.Character:FindFirstChild("RightHand"):FindFirstChild("HandWeapon")
		if HandWeapon and (AnimationName:match("Slash") or AnimationName:match("Whip")) then
			AnimationConfig.Range = HandWeapon.Stats.Length.Value * 2
		end

		if WeaponType == "Dagger" and HandWeapon then
			AnimationConfig.Range = math.clamp(HandWeapon.Stats.Length.Value * 2.3, 15, 23)
		end

		if ParryAmount == 0 or not ParryAmount then
			ParryAmount = 1
		else
			ParryAmount = ParryAmount + 1
		end
	end

    if -- hivelord
		table.find({
			"rbxassetid://5064195992",
			"rbxassetid://5067090007",
			"rbxassetid://5067105317",
		}, AnimationID)
		and self.Character:FindFirstChild("Weapon")
		and self.Character:FindFirstChild("Weapon").Weapon.Value == "Hivelord's Hubris"
	then
		AnimationConfig.Wait = 500
		if AnimationID == "rbxassetid://5067090007" then
			AnimationConfig.Range = 40
		    AnimationConfig.Wait = 450
		end
	end

	if -- Flareblood Kamas
		table.find({
			"rbxassetid://12106091136",
			"rbxassetid://12106093579",
			"rbxassetid://12106095892",
		}, AnimationID)
		and self.Character:FindFirstChild("Weapon")
		and self.Character:FindFirstChild("Weapon").Weapon.Value == "Flareblood Kamas"
	then
		AnimationConfig.Wait = 200
	end

	if
		(self.Character:FindFirstChild("Enchant:Nemesis") or (self.Player and self.Player.Backpack:FindFirstChild("Enchant:Nemesis"))) and AnimationID == "rbxassetid://7827886914"
	then
		AnimationConfig.Wait = 300
		AnimationConfig.Range = 40
	end

	if HasHeavyHands(self) and AnimationName and (AnimationName:match('Stab') or AnimationName:match('Slash')) then
		AnimationConfig.Wait = AnimationConfig.Wait * 1.2
	end

	if Toggles.DodgeVent.Value and AnimationID == "rbxassetid://9657469282" then
		AnimationConfig.Roll = true
	end

	--- Primadon Punt
	if AnimationID == "rbxassetid://6438111139" then
		AnimationConfig.Wait = Speed > 1 and 600 or 765
	end

	--- Primadon Stomp
	if AnimationID == "rbxassetid://9225098544" then
		AnimationConfig.Wait = Speed > 1 and 360 or 490
	end

	--- Primadon Triple
	if AnimationID == "rbxassetid://6432260013" then
		AnimationConfig.Wait = Speed > 1 and 490 or 545
		AnimationConfig.RepeatParryDelay = Speed > 1 and 270 or 450
	end


	return AnimationConfig
end

local function onCharacterAdded(NewCharacter)
	Character = NewCharacter
	RootPart = NewCharacter:WaitForChild("HumanoidRootPart")
	Humanoid = NewCharacter:WaitForChild("Humanoid")

	Character:WaitForChild('CharacterHandler')

	repeat
		task.wait()
	until not Character:FindFirstChild("LeftClick", true)

	EffectHandler.EffectAdded:Connect(function(Effect)
		EffectLog[Effect.ID] = {Class = Effect.Class, Time = tick()}
	end)

	EffectHandler.EffectRemoving:Connect(function(Effect)
		EffectLog[Effect.ID] = nil
	end)
end

local AutoParry = {} do
	AutoParry.Mobs = {}
	function AutoParry.new(Target)
		if AutoParry.Mobs[Target] then
			return
		end

		local self = setmetatable({}, {__index = AutoParry})
		self.Character = Target
		self.Player = Players:GetPlayerFromCharacter(Target)
		self.Humanoid = Target:WaitForChild("Humanoid", 9e9)
		self.Feinting = false
		self.Mob = Target.Name:sub(1,1) == "."
		self.Maid = RequireMaid.new()

		AutoParry.Mobs[Target] = self

		Target.AncestryChanged:Connect(function()
			if not Target:IsDescendantOf(game) then
				self.Maid:DoCleaning()
				AutoParry.Mobs[Target] = nil
			end
		end)

		self:Setup()

		return self
	end
	function AutoParry:Setup()
		task.spawn(function() self:CheckFeint() end)

		self.Maid.AnimationPlayed = self.Humanoid.AnimationPlayed:Connect(function(AnimationTrack)
			self:AnimationPlayed(AnimationTrack)
		end)
	end
	function AutoParry:CheckFeint()
		local HumanoidRootPart = self.Character:WaitForChild("HumanoidRootPart", 9e9)
		if not AutoParry.Mobs[self.Character] then
			return
		end

		self.HitLanded = {}
		self.Maid.HitAdded = self.Character.DescendantAdded:Connect(function(v)
			if
				v.Name ~= "PunchBlood"
				and v.Name ~= "PunchEffect"
				and v.Name ~= "BloodSpray"
				and not (v:IsA("ParticleEmitter") and v.Texture == "rbxassetid://7216855595")
			then
				return
			end

			local id = table.insert(self.HitLanded, {})
			task.delay(0.2, function()
				table.remove(self.HitLanded, id)
			end)
		end)

		self.Maid.FeintChildAdded = HumanoidRootPart.ChildAdded:Connect(function(v)
			if not v:IsA("Sound") or v.SoundId ~= "rbxassetid://4954198253" then
				return
			end

			if Toggles.ReactFeint.Value then 
				return print("reacted feint")
			end

			if self.Character and self.Character == Players.LocalPlayer.Character and Players.LocalPlayer.Character then
				return
			end

			self.Feinting = true

			if (self.Range and self.Range <= 15) then
				DebugNotify(self, "Entity [" .. self.Character.Name .. "] Rolled On Feint (Main)")

				task.delay(Options.RollOnFeintDelay.Value / 1000, function()
					if not Toggles.RollOnFeint.Value then
						return
					end

					if not self:CheckFacing() then
						return
					end

					if EffectHandler:FindEffect("NoRoll") then
						return
					end

					DebugNotify(self, "Entity [" .. self.Character.Name .. "] Rolled On Feint (Main)")

					Dodge()
				end)
			end

			task.wait(v.TimeLength)

			self.Feinting = false
		end)
	end
	function AutoParry:CheckFacing()
		local UserRootPart = RootPart
		local RootPart = self.Character:FindFirstChild("HumanoidRootPart")
		if not RootPart or not UserRootPart then
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
	function AutoParry:CanParry(WaitTime, LastSecond)
		local AnimationTrack = self.CurrentTrack
		local Target = self.Character
		local T_RootPart, T_Humanoid = GetBodyParts(Target)
		local Anim_Config = GetConfig(self, AnimationTrack.Animation.AnimationId, AnimationTrack.Speed)

		if not Toggles.AutoParryV2.Value then
			return
		end

		if not T_RootPart or not T_Humanoid then
			return
		end

		if not RootPart or not Humanoid then
			DebugNotify(self, "Cancelled [Dead 2]")
			return
		end

		if not Anim_Config then
			--DebugNotify(self, "Cancelled [No Conf]")
			return
		end

		if LastSecond and (EffectHandler:FindEffect("Parry") or EffectHandler:FindEffect("Dodge")) then
			DebugNotify(self, "Cancelled [Has Frame]")
			return
		end

		if (not Toggles.ReactFeint.Value) and (not AnimationTrack.IsPlaying and WaitTime <= AnimationTrack.Length) then
			DebugNotify(self, "Cancelled [Not Playing]")
			return
		end

		if (RootPart.Position - T_RootPart.Position).Magnitude > Anim_Config.Range * 1.5 then
			--DebugNotify(self, "Cancelled [Far]")
			return
		end

		if T_Humanoid.Health <= 0 then
			DebugNotify(self, "Cancelled [Dead]")
			return
		end

		if Target.Parent ~= workspace.Live then
			DebugNotify(self, "Cancelled [Parent]")
			return
		end

		if (not Toggles.ReactFeint.Value) and self.Feinting then
			DebugNotify(self, "Cancelled [Feinting]")
			return
		end

		if Toggles.HitsCancelAP.Value and #self.HitLanded > 0 and (Target:FindFirstChild('HumanController') or self.Player) then
			DebugNotify(self, "Cancelled [Hit]")
			return
		end

		if Target:FindFirstChild("Target") and Target.Target.Value ~= Character and not Toggles.IgnoreTarget.Value then
			return
		end

		if AnimationTrack.Animation.AnimationId == "rbxassetid://9657469282" and not (Toggles.ParryVent.Value or Toggles.DodgeVent.Value) then
			return
		end

		if iswindowactive and (not iswindowactive() and Toggles.BlockAPIfUnfocused.Value) then
			return
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.F) and Toggles.BlockAPIfHoldingF.Value then
			return
		end

		return true
	end
	function AutoParry:AnimationPlayed(AnimationTrack)
		Character = Player.Character
		RootPart = Character and Character:WaitForChild("HumanoidRootPart")
		Humanoid = Character and Character:WaitForChild("Humanoid")

		if AnimationTrack.Priority == Enum.AnimationPriority.Core then
			return
		end

		if AnimationTrack.WeightTarget <= 0.05 then
			return
		end

		if not self.Mob and MobDatabase[AnimationTrack.Animation.AnimationId] ~= nil then
			return
		end

		if self.Range and self.Range < Options.LogAnimations_Range.Value then
			task.spawn(LogAnimation,AnimationTrack.Animation.AnimationId)
		end

		if not Toggles.AutoParryV2.Value then
			return
		end

		if not self.Mob and Options.AutoParryTarget.Value ~= "Players" and Options.AutoParryTarget.Value ~= "All" then
			return
		end

		if self.Player and self.Player == Players.LocalPlayer and not Toggles.ParrySelfAnimations.Value then
			return
		end

		if not Character then return end

		local Whitelists = Options.AutoParryWhitelist.Value
		if Whitelists and Whitelists ~= "" then
			if typeof(Whitelists) == "string" then
				Whitelists = { Whitelists }
			end
		end

		if typeof(Whitelists) == "table" and Whitelists[self.Character.Name] then
			return
		end

		if Toggles.AutoParryIgnoreFriends.Value and self.Player and getgenv().FriendsCache and getgenv().FriendsCache[self.Player] then
			return
		end

		local HumanoidRootPart = GetBodyParts(self.Character)
		if HumanoidRootPart and RootPart then
			self.Range = (RootPart.Position - HumanoidRootPart.Position).Magnitude
		end

		local ID = HttpService:GenerateGUID(false)
		local Config = GetConfig(self, AnimationTrack.Animation.AnimationId, AnimationTrack.Speed)
		if not Config then
			return
		end

		if not Config.Wait then
			return print("No Config Wait Time", AnimationTrack.Animation.AnimationId, Config.Name)
		end

		local WaitTime = CalculatedWait(Config.Wait) / 1000
		local RepeatWait = Config.RepeatParryDelay and CalculatedWait(Config.RepeatParryDelay) / 1000

		WaitTime = WaitTime + (Options.AutoParryOffset.Value / 1000)
		RepeatWait = RepeatWait and RepeatWait + (Options.RepeatOffset.Value / 1000)

		WaitTime = WaitTime + 0.07
		RepeatWait = RepeatWait and RepeatWait + 0.12

		self.CurrentTrack = AnimationTrack

		self.Maid[AnimationTrack] = task.spawn(function()
			SetBlockInput(ID, true, Config.Roll)

			if not self:CanParry(WaitTime) then
				SetBlockInput(ID, false, Config.Roll)
				return
			end

			-- check if we are attacking
			if IsAttacking() and Toggles.AutoFeint.Value then
				-- attempt to feint and block input
				AttemptFeint()
			end

			task.delay(WaitTime / 2, function()
				-- check if we are still attacking
				if IsAttacking() and Toggles.AutoFeint.Value then
					AttemptFeint()
				end
			end)

			local Hitted = false
			task.delay(WaitTime - 0.1, function()
				Hitted = CreateHitbox(self, Config.Range, Config.Hitbox)
			end)

			DebugNotify(self, string.format("Waiting %s ["..tostring(WaitTime) .. "]", Config.Name))
			task.wait(WaitTime)

			if AnimationTrack ~= self.CurrentTrack then
				-- release input and cancel ap
				SetBlockInput(ID, false, Config.Roll)
				return
			end

			if Config.Delay and not Hitted then
				local Cancel = false
				local Hitbox = MakeBaseHitbox(self, Config.Range, Config.Hitbox)

				repeat
					if AnimationTrack ~= self.CurrentTrack then
						--rconsoleprint("diff track")
						SetBlockInput(ID, false, Config.Roll)
						Cancel = true
						break
					end

					if not AnimationTrack.IsPlaying then
						--rconsoleprint("no longer playing")
						SetBlockInput(ID, false, Config.Roll)
						Cancel = true
						break
					end

					Hitted = HitboxModule.scan(Hitbox, Character)
					--rconsoleprint("scanning")

					task.wait(.09)
				until Hitted or Cancel

				game.Debris:AddItem(Hitbox, 0.05)
			end

			if not self:CanParry(WaitTime, true) or (not Hitted and not Toggles.AutoParryDebug.Value) or not self:CheckFacing() then
				-- release input and cancel ap
				SetBlockInput(ID, false, Config.Roll)
				return
			end

			if Config.Roll then
				DebugNotify(self, "Attempting Roll")
				IndicateHighlight()
				Dodge()
			else
				if EffectHandler:FindEffect("ParryCool") then
					if Toggles.RollOnParryCDDelay.Value then
						task.wait(Options.RollOnParryCDDelaySlider.Value / 1000)
					end
					DebugNotify(self, "Attempting Roll [ParryCD]")
					IndicateHighlight()
					Dodge()
					return
				end

				DebugNotify(self, "Attempting Parry")--.. tostring(Hitted)
				IndicateHighlight()
				Parry()
			end

			if Config.RepeatParryAmount then
				for i = 1, Config.RepeatParryAmount do
					local Hitted = false

					task.delay(RepeatWait - 0.08, function()
						Hitted = CreateHitbox(self, Config.Range, Config.Hitbox)
					end)

					task.wait(RepeatWait)

					if not self:CanParry(WaitTime) or (not Hitted and not Toggles.AutoParryDebug.Value) then
						-- wait a bit and go to next parry
						task.wait(.09)
						continue
					end

					-- if parry on cd and roll isn't we use roll
					if EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value then
						DebugNotify(self, "Attempting Roll [Repeated]")
						IndicateHighlight()
						Dodge()
					else
						DebugNotify(self, "Attempting Parry [Repeated]")
						IndicateHighlight()
						Parry()
					end
				end
			end

			if Config.RepeatUntilAnimationEnd then
				repeat
					local Hitted = false

					task.delay(RepeatWait - 0.08, function()
						Hitted = CreateHitbox(self, Config.Range, Config.Hitbox)
					end)

					task.wait(RepeatWait)

					if not self:CanParry(WaitTime) or (not Hitted and not Toggles.AutoParryDebug.Value) then
						-- wait a bit and go to next parry
						task.wait(.09)
						continue
					end

					-- if parry on cd and roll isn't we use roll
					if EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value then
						DebugNotify(self, "Attempting Roll [Repeated]")
						IndicateHighlight()
						Dodge()
					else
						DebugNotify(self, "Attempting Parry [Repeated]")
						IndicateHighlight()
						Parry()
					end
				until not AnimationTrack.IsPlaying
			end

			task.wait((Options.BlockInputDelay.Value or 150) / 1000)

			-- release input
			SetBlockInput(ID, false, Config.Roll)
		end)
	end
end

Maid.AP_RewriteChar = Player.CharacterAdded:Connect(onCharacterAdded)
if Character then
	onCharacterAdded(Character)
end

Maid.AP_RewriteChildAdded = task.spawn(function()
	while task.wait(1) do
		for i, v in next, workspace.Live:GetChildren() do
			task.spawn(AutoParry.new, v)
		end
	end
end)

Maid.AutoParryRewrite = function()
	for i,v in pairs(AutoParry.Mobs) do
		v.Maid:DoCleaning()
	end
end