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

local EffectLog = {}
do
	function EffectLog:FindEffect(Class)
		for _, v in pairs(EffectLog) do
			if typeof(v) == "function" then
				continue
			end
			if v.Class == Class then
				return v
			end
		end
	end
end

local RequireMaid = require("Modules/Maid")
local EffectHandler = robloxRequire(ReplicatedStorage:WaitForChild("EffectReplicator"))

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
	if Toggles.ParryNotifs.Value then
		Library:Notify(Message, 2)
	end
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

	game:GetService("TweenService")
		:Create(Indicator, TweenInfo.new(0.3), { FillTransparency = 1, OutlineTransparency = 1 })
		:Play()
	game.Debris:AddItem(Indicator, 0.3)
end

local function CalculatedWait(waittime)
	local num = waittime
	local Ping = game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000
	num = num - (Ping * (Options.PingAdjustment.Value / 100))
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

	task.delay(0.2, function()
		VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)
	end)
end

local function IsAttacking(checkMantra)
	return EffectHandler:FindEffect("LightAttack", true)
		or EffectHandler:FindEffect("MidAttack", true)
		or (checkMantra and EffectHandler:FindEffect("UsingSpell", true))
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
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end
	
	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end

	if Toggles.BlatantRoll.Value or ForceBlatant then
		dodgeRemote:FireServer("roll", nil, nil, false)

		for _, v in pairs(EffectHandler.Effects) do
			if
				table.find({
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
				}, rawget(v, "Class"))
			then
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

local AutoParry = {}
do
	AutoParry.Projectile = {}
	function AutoParry.new(Target)
		Character = Player.Character
		RootPart = Character and Character:WaitForChild("HumanoidRootPart")
		Humanoid = Character and Character:WaitForChild("Humanoid")

		if AutoParry.Projectile[Target] then
			return
		end

        if not Target:IsA("BasePart") and not Target:IsA("Attachment") then
			return
		end

		if Target.Name == "Part" or Target.Name == "Attachment" then
			return
		end

		local self = setmetatable({}, { __index = AutoParry })
		self.Character = Target
		self.Maid = RequireMaid.new()

		AutoParry.Projectile[Target] = self

		self.Maid.AncestryChanged = Target.AncestryChanged:Connect(function()
			if Target.Parent == nil then
				self.Maid:DoCleaning()
				AutoParry.Projectile[Target] = nil
			end
		end)

		local ProjectileConfig = ProjectileConfigs[Target.Name]
        if not ProjectileConfig then
            return
        end

		local MinRange = ProjectileConfig.MinRange
		local MaxRange = ProjectileConfig.MaxRange

		if not MaxRange and not MinRange then
			MinRange = 0
			MaxRange = ProjectileConfig.Range
		end
	
		if not MinRange or not MaxRange then
			return DebugNotify(self, "Blocked projectile - range is not setup")
		end

		local CurrentRange = (Target.Position - RootPart.Position).Magnitude
		if CurrentRange <= MinRange then
			return DebugNotify(self, "Blocked projectile - range is below minimum")
		end
		
		if CurrentRange >= MaxRange * 10 then
			return
		end

		DebugNotify(self, string.format("Waiting for projectile %s to be in distance", Target.Name))
	
		while task.wait() do
			CurrentRange = (Target.Position - RootPart.Position).Magnitude

            if not AutoParry.Projectile[Target] then
                return
            end

            if CurrentRange >= MaxRange * 10 then
                return
            end

			if CurrentRange <= MaxRange then
				break
			end
		end

		self:Run()

		return self
	end
	function AutoParry:CheckFacing()
		local UserRootPart = RootPart
		local TargetRootPart = self.Character
		if not TargetRootPart or not UserRootPart then
			return
		end

		local DeltaOnTargetToLocal = (UserRootPart.Position - TargetRootPart.Position).Unit
		local DeltaOnLocalToTarget = (TargetRootPart.Position - UserRootPart.Position).Unit
		local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1
		local LocalToTargetResult = TargetRootPart.CFrame.LookVector:Dot(DeltaOnLocalToTarget) <= -0.1

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
	function AutoParry:CanParry()
		local Target = self.Character

		if not Toggles.AutoParryV2.Value then
			return
		end

		if not RootPart or not Humanoid then
			return
		end

		if EffectHandler:FindEffect("Parry") or EffectHandler:FindEffect("Dodge") or EffectHandler:FindEffect("DodgedFrame") or EffectHandler:FindEffect("AutoParry") or EffectHandler:FindEffect('GenerousParry') then
			return
		end

		if not Target.Parent or not Target:IsDescendantOf(game) then
			return
		end

		return true
	end
	function AutoParry:Run()
		if not self.Character then return end
		
		if self.Character.Name == "Part" or self.Character.Name == "Attachment" then
			return
		end

		if (self.Character.Position - RootPart.Position).Magnitude < Options.LogProjectiles_Range.Value then
			task.spawn(getgenv().logProjectile, Character.Name)
		end

		if not Toggles.AutoParryV2.Value then
			return
		end

		local ID = HttpService:GenerateGUID(false)
		local Config = ProjectileConfigs[self.Character.Name]
		if not Config then
			return
		end

		local WaitTime = CalculatedWait(Config.Wait) / 1000
		local RepeatWait = Config.RepeatParryDelay and CalculatedWait(Config.RepeatParryDelay) / 1000

		WaitTime = WaitTime + (Options.AutoParryOffset.Value / 1000)
		RepeatWait = RepeatWait and RepeatWait + (Options.RepeatOffset.Value / 1000)

		WaitTime = WaitTime + 0.07
		RepeatWait = RepeatWait and RepeatWait + 0.12

		AutoParry.CurrentPart = self.Character

		self.Maid[self.Character] = task.spawn(function()
			-- check if we are attacking
			if IsAttacking() and Toggles.AutoFeint.Value then
				-- attempt to feint and block input
				AttemptFeint()
			end

			SetBlockInput(ID, true, Config.Roll)

			task.delay(WaitTime / 2, function()
				-- check if we are still attacking
				if IsAttacking() and Toggles.AutoFeint.Value then
					AttemptFeint()
				end
			end)

			DebugNotify(self, string.format("Waiting %s [" .. tostring(WaitTime) .. "]", Config.Name))
			task.wait(WaitTime)

			if not self:CanParry() or not self:CheckFacing() then
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
					DebugNotify(self, "Attempting Roll [ParryCD]")
					IndicateHighlight()
					Dodge()
					return
				end

				DebugNotify(self, "Attempting Parry") --.. tostring(Hitted)
				IndicateHighlight()
				Parry()
			end

			if Config.RepeatParryAmount then
				for i = 1, Config.RepeatParryAmount do
					task.wait(RepeatWait)

					if not self:CanParry() then
						-- wait a bit and go to next parry
						task.wait(0.09)
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

			task.wait((Options.BlockInputDelay.Value or 150) / 1000)

			-- release input
			SetBlockInput(ID, false, Config.Roll)
		end)
	end
end

Maid.AP_RewriteThrown = workspace.Thrown.DescendantAdded:Connect(AutoParry.new)
for i, v in next, workspace.Thrown:GetDescendants() do
	task.spawn(AutoParry.new, v)
end

Maid.AutoParryRewriteThrown = function()
	for i, v in pairs(AutoParry.Projectile) do
		v.Maid:DoCleaning()
	end
end

local function onCharacterAdded(NewCharacter)
	Character = NewCharacter
	RootPart = NewCharacter:WaitForChild("HumanoidRootPart")
	Humanoid = NewCharacter:WaitForChild("Humanoid")
end

Maid.AP_RewriteChar = Player.CharacterAdded:Connect(onCharacterAdded)
if Character then
	onCharacterAdded(Character)
end