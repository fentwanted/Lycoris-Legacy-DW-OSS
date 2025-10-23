local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local isLayer2 = ReplicatedStorage:FindFirstChild('LAYER2_DUNGEON')
local Parry = getgenv().Parry
local Parry = getgenv().Parry
local Dodge = getgenv().Dodge
local pingWait = getgenv().pingWait
local checkRange = getgenv().checkRange
local checkRangeFromPing = getgenv().checkRangeFromPing
local Status = getgenv().Status
local Maid = getgenv().Maid
local RawParry = getgenv().RawParry
local EffectHandler = getgenv().require(ReplicatedStorage:FindFirstChild('EffectReplicator'))

local Player = Players.LocalPlayer

if (game.PlaceId == 8668476218) then
	local chaserBeamDebounce = true
	if isLayer2 then
		if Maid.autoParryLayer2DescAdded then Maid.autoParryLayer2DescAdded = nil end
		Maid.autoParryLayer2DescAdded = workspace.DescendantAdded:Connect(function(obj)
			if not Toggles.AutoParry.Value and not Toggles.AutoParryV2.Value then
				return
			end
			if (obj.Name == 'BloodTendrilBeam') then -- Chaser Beam
				if (not chaserBeamDebounce) then return end
				chaserBeamDebounce = false
				Status.Busy = true
	
				task.delay(0.1, function() chaserBeamDebounce = true end)
				pingWait(0.55)
				Parry()
				Status.Busy = false
			elseif (obj.Name == 'PerilousAttack') and workspace.Live:FindFirstChild(".chaser") then -- Chaser Explosion
				Status.Busy = true

				pingWait(0.6)
				Dodge()

				Status.Busy = false
			elseif (obj.Name == 'SpikeStabEff') then -- Chaser Explosion
				Status.Busy = true

				pingWait(0.6)

				if (not checkRange(20, obj)) then Status.Busy = true return end

				Parry()

				Status.Busy = false
			elseif (obj.Name == 'ParticleEmitter3' and string.find(obj:GetFullName(), 'avatar')) then -- Avatar Beam
				pingWait(0.75)
	
				local avatar = obj.Parent.Parent.Parent
				local target = avatar and avatar:FindFirstChild('Target')
	
				if (target and target.Value ~= Player.Character) then return end
	
				Status.Busy = true
				repeat
					if (target and target.Value ~= Player.Character) then Status.Busy = false task.wait(.5) return end
					Status.Busy = true
					RawParry()
					task.wait(0.1)
				until not obj.Parent or not obj.Enabled

				Status.Busy = false
			elseif (obj.Name == 'GrabPart') then -- Avatar Blind Ball
				repeat
					task.wait()
				until not obj.Parent or checkRange(20, obj)
				if (not obj.Parent) then return end

				Dodge()
			end
		end)
	else
		local lastParryAt = 0
		local spawnedAt
		if Maid.autoParryOrb then
			Maid.autoParryOrb = nil
		end
		Maid.autoParryOrb = game:GetService("RunService").RenderStepped:Connect(function(dt)
			local myRootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
			if (not myRootPart) then return end
			local myPosition = myRootPart.Position
	
			for _, v in pairs(workspace.Thrown:GetChildren()) do
				if (not spawnedAt) then
					spawnedAt = tick()
				end
	
				if (v.Name == 'ArdourBall2' and tick() - spawnedAt >= 3) then
					local distance = (myPosition - v.Position).Magnitude
	
					if (distance <= 15 and tick() - lastParryAt >= 0.1) then
						lastParryAt = tick()
						Parry()
						break
					end
				end
			end
		end)
	end
end
--14531935090
if Maid.autoParrySlotBall then Maid.autoParrySlotBall = nil end
Maid.autoParrySlotBall = workspace.Thrown.ChildAdded:Connect(function(obj)
	task.wait()
	if not Toggles.AutoParry.Value and not Toggles.AutoParryV2.Value then
		return
	end
	local myRootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if (not myRootPart) then return end

	if (obj.Name == 'SlotBall') then
		repeat
			task.wait()
		until (obj.Position - myRootPart.Position).Magnitude <= 20 or not obj.Parent

		if (not obj.Parent) then
			return warn('Object got destroyed')
		end

		Parry()
	elseif (obj.Name == 'BoulderProjectile' and (myRootPart.Position - obj.Position).Magnitude < 500) then
		repeat
			task.wait()
		until (obj.Position - myRootPart.Position).Magnitude <= 30 or not obj.Parent
		if (not obj.Parent) then return end
		Dodge()
	elseif (obj.Name == 'SpearPart' and (myRootPart.Position - obj.Position).Magnitude < 600) then
		-- Grand Javelin Long Range
		if (myRootPart.Position - obj.Position).Magnitude <= 35 then return end
		repeat
			task.wait()
		until (obj.Position - myRootPart.Position).Magnitude <= 80 or not obj.Parent
		if (not obj.Parent) then return end
		Parry()
	elseif (obj.Name == 'StrikeIndicator' and (myRootPart.Position - obj.Position).Magnitude < 10) then
		pingWait(0.2)
		Parry()
	elseif ((obj.Name == 'WindSlashProjectile' or obj.Name == 'WindSlashProjectileBig') and (myRootPart.Position - obj.Position).Magnitude < 200) then
		if (myRootPart.Position - obj.Position).Magnitude <= 10 then return end
		repeat
			task.wait()
		until checkRange(10, obj) or not obj.Parent
		if (not obj.Parent) then return end
		Parry()
	elseif (obj.Name == 'IceDagger' and not checkRange(20, obj)) and not EffectHandler:FindEffect('UsingSpell') then
		local rocketPropulsion = obj:WaitForChild('RocketPropulsion', 10)
		if (not rocketPropulsion or rocketPropulsion.Target ~= myRootPart) then return end

		repeat
			task.wait()
		until not obj.Parent or checkRange(10, obj)
		if (not obj.Parent) then return end

		Parry()
	elseif (obj.Name == 'WindProjectile' and not checkRange(20, obj)) and not EffectHandler:FindEffect('UsingSpell') then
		repeat
			task.wait()
		until checkRange(80, obj) or not obj.Parent
		if (not obj.Parent) then return end

		Parry()
	elseif (obj.Name == 'WindKickBrick' and not checkRange(15, obj)) and not EffectHandler:FindEffect('UsingSpell') then
		-- Tornado Kick

		repeat
			task.wait()
		until checkRange(40, obj) or not obj.Parent
		if (not obj.Parent) then return end
		Parry()
	elseif (obj.Name == 'SeekerOrb') then
		-- Shadow Seeker
		local rocketPropulsion = obj:WaitForChild('RocketPropulsion', 10)
		if (not rocketPropulsion or rocketPropulsion.Target ~= myRootPart) then return end
		repeat
			task.wait()
		until not obj.Parent or checkRange(2, obj)
		if (checkRange(2, obj)) then
			Parry()
		end
	elseif (obj.Name == 'Beam') then
		-- Arc Beam
		local endPart = obj:WaitForChild('End', 10)
		if (not endPart) then return end

		repeat task.wait() until checkRange(30, endPart) or not obj.Parent
		if (not obj.Parent) then print('Despawned') return end

		Parry()
	elseif (obj.Name == 'DiskPart' and checkRange(100, obj)) and not EffectHandler:FindEffect('UsingSpell') then
		-- Sinister Halo
		repeat task.wait() until checkRange(20, obj) or not obj.Parent
		if (not obj.Parent) then print('Despawned') return end

		pingWait(0.3)
		Parry()
		task.wait(0.3)
		if (not checkRange(15, obj)) then return end
		Parry()
	elseif (obj.Name == 'Bubble' and not Player:WaitForChild("Backpack"):FindFirstChild("Enchant:Tears of the Edenkite") and checkRange(30, obj)) then -- we love bubbles from tears :3
		repeat task.wait() until checkRange(10, obj) or not obj.Parent
		if (not obj.Parent) then return end

		Parry()
	elseif (obj.Name == 'BloodtideProjectile' and checkRange(80, obj)) then -- we love bloodtide r
		repeat task.wait() until checkRangeFromPing(obj, 30, 50) or not obj.Parent
		if (not obj.Parent) then return end

		Parry()
	elseif ((obj.Name == 'IceBird' or obj.Name == 'IceBirdRed') and checkRange(30, obj)) and not EffectHandler:FindEffect('UsingSpell') then -- we love flocks
		repeat task.wait() until checkRange(15, obj) or not obj.Parent
		if (not obj.Parent) then return end

		Parry()
	elseif (obj.Name == 'BoneSpear') then -- Avatar Bone Throw
		pingWait(0.5)

		if (isLayer2) then
			repeat
				task.wait()
			until not obj.Parent or checkRangeFromPing(obj, 30, 175)
		else
			repeat
				task.wait()
			until not obj.Parent or checkRange(30, obj)
		end

		if (not obj.Parent) then return end
		Parry()
	end
end)

local effectsList = {}

effectsList.DisplayThornsRed = function(effectData) -- Umbral Knight
    if effectData.Character ~= Player.Character then
        return
    end
    Parry()
end

effectsList.DisplayThorns = function(effectData) --Providence Thorns
    if effectData.Character ~= Player.Character then
        return
    end
    pingWait(effectData.Time - effectData.Window)
    Parry()
end

effectsList.OwlDisperse = function(effectData)
    local target = effectData.Character and effectData.Character:FindFirstChild("Target")
    if not target or target.Value ~= Player.Character then
        return
    end

    --print("owl disperse!")

    local startedAt = tick()
    local duration = effectData.Duration

    task.wait(duration / 3)

    while tick() - startedAt <= duration + 0.3 do
        task.spawn(function()
            Parry()
        end)
        task.wait(0.2)
    end
    --print("owl disperse finished")
end

local function getCaster(data)
    if not data then
        return
    end
    local caster
    for _, v in next, data do
        if typeof(v) ~= "Instance" or v.Parent ~= workspace.Live or v == Player.Character then
            continue
        end
        return v
    end
    return caster
end

local warneds = {}
getgenv().Maid.AutoParryEffect = ReplicatedStorage.Requests.ClientEffect.OnClientEvent:Connect(function(effectName, effectData)
			if not Toggles.AutoParry.Value and not Toggles.AutoParryV2.Value then
				return
			end

			local caster = getCaster(effectData)

			if caster then
				local AutoParryMode = Options.AutoParryTarget.Value
				local isPlayer = Players:FindFirstChild(caster.Name)

				if AutoParryMode ~= "All" then
					if AutoParryMode == 'Guild' and isPlayer and isPlayer:GetAttribute("Guild") ~= Player:GetAttribute("Guild") then
						return
					end
	
					if AutoParryMode == 'Mobs' and isPlayer then
						return
					end
	
					if AutoParryMode == 'Players' and not isPlayer then
						return
					end
				end
			end

			if not effectsList then
				require("Modules/Deepwoken/CustomConfigs")
				getgenv().Library:Notify('AutoParry EffectList not found.', 4)
				return
			end

			local f = effectsList[effectName]

			if f then
				f(effectData, effectName)
			else
				if not warneds[effectName] then
					warneds[effectName] = true
				end
			end
		end
	)