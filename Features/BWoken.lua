local NSFW = {}
local Maid = getgenv().FeaturesMaid
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function requireNSFW(object)
	-- Get custom asset...
	local customAssetSuccess, customAsset = pcall(getcustomasset, object)
	if not customAssetSuccess or not customAsset then
		return nil
	end

	-- Clone object...
	local clonedObject = game:GetObjects(customAsset)[1]:Clone()

	-- Load it...
	local loadedProto = loadstring(clonedObject.Source, clonedObject.Name)

	-- Override environment...
	getfenv(loadedProto).script = clonedObject
	getfenv(loadedProto).getsynasset = getcustomasset
	getfenv(loadedProto).require = function(what)
		return requireNSFW(what)
	end

	-- Obtain result & if we succeeded...
	local requireSuccess, requireResult = pcall(function()
		return loadedProto()
	end)

	-- Check for failure...
	if not requireSuccess then
		return warn(requireResult)
	end

	-- Return...
	return requireResult
end

local TrackedRigs = {}
local SpringClass = nil
local RaceData = nil
local DressUp = nil
local GenderCalculator = nil

local function applyBoobNonP(Model, A, HumanoidRootPart)
	local OGC02 = A.C0

	local Torso = HumanoidRootPart.Parent.Torso

	local AssSpring = SpringClass.new(Vector3.new(0, 0, 0))
	AssSpring.Target = Vector3.new(3, 3, 3)
	AssSpring.Velocity = Vector3.new(0, 0, 0)
	AssSpring.Speed = 10
	AssSpring.Damper = 0.1

	local OGR = Torso.RotVelocity
	local OGP = Torso.Position

	return function(_, d)
		if not Model.Parent or not HumanoidRootPart.Parent or not HumanoidRootPart.Parent.Parent then
			Model:Destroy()
			AssSpring = nil
			return
		end

		local CURRP = Torso.Position
		local CurrRot = Torso.RotVelocity

		AssSpring:TimeSkip(d)
		AssSpring:Impulse((OGP - CURRP) + Vector3.new(0, 0, (OGR - CurrRot).Y / 4))
		A.C0 = OGC02
			* CFrame.Angles(
				math.rad(3 * AssSpring.Velocity.Y),
				math.rad(3 * AssSpring.Velocity.X),
				math.rad(2 * AssSpring.Velocity.Z)
			)

		OGR = CurrRot
		OGP = CURRP
	end
end

local function applyBoobP(Model, P, A, HumanoidRootPart)
	local OGC0 = P.C0
	local OGC02 = A.C0

	local Torso = HumanoidRootPart.Parent.Torso

	local BreastSpring = SpringClass.new(Vector3.new(0, 0, 0))
	BreastSpring.Target = Vector3.new(3, 3, 3)
	BreastSpring.Velocity = Vector3.new(0, 0, 0)
	BreastSpring.Speed = 10
	BreastSpring.Damper = 0.2

	local AssSpring = SpringClass.new(Vector3.new(0, 0, 0))
	AssSpring.Target = Vector3.new(3, 3, 3)
	AssSpring.Velocity = Vector3.new(0, 0, 0)
	AssSpring.Speed = 10
	AssSpring.Damper = 0.1

	local OGR = Torso.RotVelocity
	local OGP = Torso.Position

	return function(_, d)
		if not Model.Parent or not HumanoidRootPart.Parent or not HumanoidRootPart.Parent.Parent then
			Model:Destroy()
			AssSpring = nil
			BreastSpring = nil
			return
		end

		local CURRP = Torso.Position
		local CurrRot = Torso.RotVelocity

		BreastSpring:TimeSkip(d)
		BreastSpring:Impulse((OGP - CURRP) + Vector3.new((OGR - CurrRot).Y / 4), 0, 0)
		P.C0 = OGC0 * CFrame.Angles(math.rad(10 * BreastSpring.Velocity.Y), math.rad(5 * BreastSpring.Velocity.X), 0)
		AssSpring:TimeSkip(d)
		AssSpring:Impulse((OGP - CURRP) + Vector3.new(0, 0, (OGR - CurrRot).Y / 4))
		A.C0 = OGC02
			* CFrame.Angles(
				math.rad(3 * AssSpring.Velocity.Y),
				math.rad(3 * AssSpring.Velocity.X),
				math.rad(2 * AssSpring.Velocity.Z)
			)

		OGR = CurrRot
		OGP = CURRP
	end
end

local function applyBoobPhysics(Model, HumanoidRootPart)
	local P = Model:FindFirstChild("BoobJ", true)
	local A = Model:FindFirstChild("BJ", true)
	return P and applyBoobP(Model, P, A, HumanoidRootPart) or applyBoobNonP(Model, A, HumanoidRootPart)
end

local function cleanupRigs()
	for Index, TrackedRig in next, TrackedRigs do
		-- Get model...
		local Model = TrackedRig.Rig.Parent

		-- Destroy rig...
		TrackedRig.Rig:Destroy()

		-- Restore transparency...
		pcall(function()
			Model["Left Leg"].Transparency = 0
			Model["Right Leg"].Transparency = 0
			Model["Torso"].Transparency = 0
			Model["Right Arm"].Transparency = 0
			Model["Left Arm"].Transparency = 0
		end)

		-- Remove rig...
		TrackedRigs[Index] = nil
		TrackedRig = nil
	end
end

local function applyNSFWToModel(Model, ApplyPhysics)
	-- Get model name...
	local Player = Players:FindFirstChild(Model.Name)
	local HumanoidRootPart = Model:WaitForChild("HumanoidRootPart", 9e9)
	local Torso = Model:WaitForChild("Torso", 9e9)
	local ModelHumanoid = Model:FindFirstChild("Humanoid", 9e9)

	-- Skip rigs we don't want...
	if Model:FindFirstChild("CustomRig") or (ModelHumanoid and ModelHumanoid.RigType == Enum.HumanoidRigType.R15) then
		return
	end

	-- Check for existence...
	if not HumanoidRootPart then
		return
	end

	-- Use model name...
	local Name = Model.Name

	-- Check if we have a display name, use that instead...
	if string.len(ModelHumanoid.DisplayName) > 1 then
		Name = ModelHumanoid.DisplayName
	end

	-- Save first name...
	local FirstName = Name

	-- First name calculation...
	if string.find(FirstName, " ") then
		FirstName = string.sub(Name, 1, string.find(FirstName, " ") - 1)
	end

	-- Get race, scales, and gender...
	local Race = RaceData:GetRaceFromSkinTone(Torso.Color)
	local Scales = RaceData:ScaleViaNameAndRace(Name, Race)
	local Gender = GenderCalculator:DetermineGender(Model, ((Player and FirstName) or nil))

	-- Calculate scaling...
	local CurrentScale = Toggles.SizeEntityAuto.Value
			and { Ass = Options.AssSize.Value, Breasts = Options.BoobsSize.Value, Dick = Options.CrotchSize.Value }
		or Scales

	-- Create new rig...
	local NewRig = Toggles.UtilizeGender.Value and Gender == 0 and DressUp:ApplyMaleBody(RaceData, Model, CurrentScale)
		or DressUp:ApplyFemBody(RaceData, Model, CurrentScale)

	-- Handle ass visibility...
	if not Toggles.ShowEntityAss.Value and NewRig.T.RT:FindFirstChild("Butt") then
		NewRig.T.RT.Butt["Left Cheek"].Transparency = 1
		NewRig.T.RT.Butt["Right Cheek"].Transparency = 1
		NewRig.T.RT.Butt["Left Cheek"].Shirt.Transparency = 1
		NewRig.T.RT.Butt["Right Cheek"].Shirt.Transparency = 1
		NewRig.T.RT.Butt["Left Cheek"].Pants.Transparency = 1
		NewRig.T.RT.Butt["Right Cheek"].Pants.Transparency = 1
	end

	-- Handle boobs visibility...
	if not Toggles.ShowEntityBoobs.Value and NewRig.T.RT:FindFirstChild("Bust") then
		NewRig.T.RT.Bust.Shirt.Transparency = 1
		NewRig.T.RT.Bust.Pants.Transparency = 1
		NewRig.T.RT.Bust.VisualBust.Transparency = 1
		NewRig.T.RT.Bust.VisualBust.Are.Transparency = 1
	end

	-- Handle crotch visibility...
	if not Toggles.ShowEntityCrotch.Value and NewRig.T.RT:FindFirstChild("Groin") then
		NewRig.T.RT.Groin.Shirt.Transparency = 1
		NewRig.T.RT.Groin.Pants.Transparency = 1
		NewRig.T.RT.Groin.Transparency = 1
	end

	-- Tracked rig table...
	local TrackedRig = {
		Rig = NewRig,
	}

	-- Apply physics...
	if ApplyPhysics then
		TrackedRig.BoobPhysics = applyBoobPhysics(NewRig, HumanoidRootPart)
	end

	-- Track our rig...
	TrackedRigs[#TrackedRigs + 1] = TrackedRig

	-- Return rig...
	return NewRig
end

function NSFW.EntityNSFW()
	-- Setup requires
	if not SpringClass then
		SpringClass = requireNSFW("BoobWokenData/SpringClass.rbxm")
	end

	if not RaceData then
		RaceData = requireNSFW("BoobWokenData/RaceModule.rbxm")
	end

	if not DressUp then
		DressUp = requireNSFW("BoobWokenData/DressUpCharacter.rbxm")
	end

	if not GenderCalculator then
		GenderCalculator = requireNSFW("BoobWokenData/CalculateGender.rbxm")
	end

	-- Check for modules...
	if not SpringClass or not RaceData or not DressUp or not GenderCalculator then
		return getgenv().Library:Notify("Boobwoken failed to load, not all modules were found!", 3)
	end

	-- Check if it's disabled...
	if not Toggles.EntityNSFW.Value then
		-- Clean up maid...
		Maid.LiveNSFWAdded = nil
		Maid.LiveNSFWRemoving = nil
		Maid.LiveNSFWAdded = nil
		Maid.LiveNSFWRemoving = nil
		Maid.NSFWPhysics = nil

		-- Clean up rigs...
		cleanupRigs()

		-- Return...
		return
	end

	-- Credits...
	getgenv().Library:Notify("Boobwoken enabled, all modules found!", 6)
	getgenv().Library:Notify(
		"Support the creators: .gg/AEakrtHQX8 | twitter.com/Geno_Dev | Incognito (hookfunction)",
		6
	)

	-- Add NSFW...
	local function AddNSFWInstance(Instance, Physics)
		-- Check model...
		if not Instance:IsA("Model") then
			return
		end

		-- Add rig...
		SecureSpawn(applyNSFWToModel, Instance, Physics)
	end

	-- Remove NSFW
	local function RemoveNSFWInstance(Instance)
		for Index, TrackedRig in next, TrackedRigs do
			-- Get rig...
			local Rig = TrackedRig.Rig

			-- Check if the parent is the instance...
			if Rig.Parent ~= Instance then
				continue
			end

			-- Destroy rig...
			Rig:Destroy()

			-- Remove rig...
			TrackedRigs[Index] = nil
		end
	end

	-- Add to current living...
	for _, Entity in pairs(workspace.Live:GetChildren()) do
		AddNSFWInstance(Entity, true)
	end

	-- Add to current NPCs...
	for _, NPC in pairs(workspace.NPCs:GetChildren()) do
		AddNSFWInstance(NPC, true)
	end

	-- Track live added...
	Maid.LiveNSFWAdded = workspace.Live.ChildAdded:Connect(function(Instance)
		AddNSFWInstance(Instance, false)
	end)

	-- Track live removing...
	Maid.LiveNSFWRemoved = workspace.Live.ChildRemoved:Connect(function(Instance)
		RemoveNSFWInstance(Instance)
	end)

	-- Track NPCs added...
	Maid.LiveNSFWAdded = workspace.NPCs.ChildAdded:Connect(function(Instance)
		AddNSFWInstance(Instance, false)
	end)

	-- Track NPCs removing...
	Maid.LiveNSFWRemoving = workspace.NPCs.ChildRemoved:Connect(function(Instance)
		RemoveNSFWInstance(Instance)
	end)

	-- Handle physics...
	Maid.NSFWPhysics = RunService.Stepped:Connect(function(...)
		for _, TrackedRig in next, TrackedRigs do
			-- Skip if there's no physics to handle...
			if not TrackedRig.BoobPhysics then
				continue
			end

			-- Handle physics...
			TrackedRig.BoobPhysics(...)
		end
	end)
end

function NSFW.BoobsSize()
	-- Check if auto scaling on...
	if Toggles.SizeEntityAuto.Value then
		return
	end

	-- Scale...
	for _, TrackedRig in next, TrackedRigs do
		local Rig = TrackedRig.Rig
		local RT = Rig.T.RT
		if not RT:FindFirstChild("Bust") then
			continue
		end

		DressUp.ScalingFunctions:BreastScaler(TrackedRig.Rig, Options.BoobsSize.Value)
	end
end

function NSFW.AssSize()
	-- Check if auto scaling on...
	if Toggles.SizeEntityAuto.Value then
		return
	end

	-- Scale...
	for _, TrackedRig in next, TrackedRigs do
		local Rig = TrackedRig.Rig
		local RT = Rig.T.RT
		if not RT:FindFirstChild("Butt") then
			continue
		end

		DressUp.ScalingFunctions:AssScaler(TrackedRig.Rig, Options.AssSize.Value)
	end
end

function NSFW.CrotchSize()
	-- Check if auto scaling on...
	if Toggles.SizeEntityAuto.Value then
		return
	end

	-- Scale...
	for _, TrackedRig in next, TrackedRigs do
		local Rig = TrackedRig.Rig
		local RT = Rig.T.RT
		if not RT:FindFirstChild("Crotch") then
			continue
		end

		DressUp.ScalingFunctions:CrotchScaler(TrackedRig.Rig, Options.CrotchSize.Value)
	end
end

function NSFW.SizeEntityAuto()
	-- Check if on...
	if not Toggles.SizeEntityAuto.Value then
		return
	end

	-- Auto size...
	for _, TrackedRig in next, TrackedRigs do
		-- Get rig...
		local Rig = TrackedRig.Rig
		if not Rig.Parent or not Rig:FindFirstChild("T") then
			continue
		end

		-- Get torso...
		local Torso = Rig.Parent:WaitForChild("Torso")
		local ModelHumanoid = Rig.Parent:FindFirstChildOfClass("Humanoid")

		-- Use model name...
		local Name = Rig.Parent.Name

		-- Check if we have a display name, use that instead...
		if ModelHumanoid.DisplayName and string.len(ModelHumanoid.DisplayName) > 1 then
			Name = ModelHumanoid.DisplayName
		end

		-- Calculate data...
		local Race = RaceData:GetRaceFromSkinTone(Torso.Color)
		local Scales = RaceData:ScaleViaNameAndRace(Name, Race)
		local RT = Rig.T.RT

		-- Scale...
		if RT:FindFirstChild("Crotch") then
			DressUp.ScalingFunctions:CrotchScaler(Rig, Scales.Dick)
		end

		if RT:FindFirstChild("Bust") then
			DressUp.ScalingFunctions:BreastScaler(Rig, Scales.Breasts)
		end

		if RT:FindFirstChild("Butt") then
			DressUp.ScalingFunctions:AssScaler(Rig, Scales.Ass)
		end
	end
end

function NSFW.UseEntityGender()
	for Index, TrackedRig in next, TrackedRigs do
		-- Get rig & model & humanoid...
		local Rig = TrackedRig.Rig
		local Model = Rig.Parent
		if not Model then
			continue
		end

		-- Get humanoid...
		local ModelHumanoid = Model:FindFirstChildOfClass("Humanoid")
		if not ModelHumanoid or not ModelHumanoid.DisplayName then
			continue
		end

		-- Check based on gender...
		if Toggles.UseEntityGender.Value then
			-- Use model name...
			local Name = Model.Name

			-- Check if we have a display name, use that instead...
			if string.len(ModelHumanoid.DisplayName) > 1 then
				Name = ModelHumanoid.DisplayName
			end

			-- Save first name...
			local FirstName = Name

			-- First name calculation...
			if string.find(FirstName, " ") then
				FirstName = string.sub(Name, 1, string.find(FirstName, " ") - 1)
			end

			-- Calculate gender...
			local Gender =
				GenderCalculator:DetermineGender(Model, ((Players:FindFirstChild(Model.Name) and FirstName) or nil))

			-- Check if we're male and we have a female rig...
			if Gender == 0 and Rig.Name == "FemRig" then
				-- Destroy rig...
				Rig:Destroy()

				-- Destroy rig...
				TrackedRigs[Index] = nil

				-- Re-apply to model...
				SecureSpawn(applyNSFWToModel, Model, not (Model.Parent.Name == "NPCs" or false))
			end
		else
			-- Check for anything that's not a female rig...
			if Rig.Name ~= "FemRig" then
				-- Destroy rig...
				Rig:Destroy()

				-- Destroy rig...
				TrackedRigs[Index] = nil

				-- Re-apply to model...
				SecureSpawn(applyNSFWToModel, Model, not (Model.Parent.Name == "NPCs" or false))
			end
		end
	end
end

function NSFW.ShowEntityBoobs()
	for _, TrackedRig in next, TrackedRigs do
		local Rig = TrackedRig.Rig
		if not Rig:FindFirstChild("T") then
			continue
		end

		local RT = Rig.T.RT
		if not RT then
			continue
		end

		local Transparency = Toggles.ShowEntityBoobs.Value and 0 or 1
		if not RT:FindFirstChild("Bust") then
			continue
		end

		RT.Bust.Shirt.Transparency = Transparency
		RT.Bust.Pants.Transparency = Transparency
		RT.Bust.VisualBust.Transparency = Transparency
		RT.Bust.VisualBust.Are.Transparency = Transparency
	end
end

function NSFW.ShowEntityAss()
	for _, TrackedRig in next, TrackedRigs do
		local Rig = TrackedRig.Rig
		if not Rig:FindFirstChild("T") then
			continue
		end

		local RT = Rig.T.RT
		if not RT then
			continue
		end

		local Transparency = Toggles.ShowEntityAss.Value and 0 or 1
		if not RT:FindFirstChild("Butt") then
			continue
		end

		RT.Butt["Left Cheek"].Transparency = Transparency
		RT.Butt["Right Cheek"].Transparency = Transparency
		RT.Butt["Left Cheek"].Shirt.Transparency = Transparency
		RT.Butt["Right Cheek"].Shirt.Transparency = Transparency
		RT.Butt["Left Cheek"].Pants.Transparency = Transparency
		RT.Butt["Right Cheek"].Pants.Transparency = Transparency
	end
end

function NSFW.ShowEntityCrotch()
	for _, TrackedRig in next, TrackedRigs do
		local Rig = TrackedRig.Rig
		if not Rig:FindFirstChild("T") then
			continue
		end

		local RT = Rig.T.RT
		if not RT then
			continue
		end

		local Transparency = Toggles.ShowEntityCrotch.Value and 0 or 1
		if not RT:FindFirstChild("Groin") then
			continue
		end

		RT.Groin.Shirt.Transparency = Transparency
		RT.Groin.Pants.Transparency = Transparency
		RT.Groin.Transparency = Transparency
	end
end

do -- Boobwoken cleanup
	Maid:GiveTask(cleanupRigs)
end

-- Return NSFW
return NSFW
