local Wipe = {}

local MemStorageService = game:GetService("MemStorageService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local WorkspaceService = game:GetService("Workspace")

local EffectReplicatorModule = ReplicatedStorage:WaitForChild("EffectReplicator")
local EffectReplicator = getgenv().require(EffectReplicatorModule)

local KeyHandler = require("Modules/Deepwoken/KeyHandler")
local RealmInfo = getgenv().require(ReplicatedStorage:WaitForChild("Info"):WaitForChild("RealmInfo"))
local CurrentRealm = RealmInfo.PlaceIDs[game.PlaceId]
local MarkerWorkspace = ReplicatedStorage:WaitForChild("MarkerWorkspace")
local AreaMarkers = MarkerWorkspace:WaitForChild("AreaMarkers")

local VIM = Instance.new("VirtualInputManager")
local MoveDirectionConnection = nil

local function SetMoveDirectionStepped(dt)
	game.Players.LocalPlayer:Move(Vector3.new(1, 1, 1), false)
end

function Wipe.Suicide()
	local FallDamage = KeyHandler.GetKey("FallDamage")
	if not FallDamage then
		return print("suicide brah - no fall damage")
	end

	local Character = Players.LocalPlayer.Character
	if not Character then
		return print("suicide brah - no character")
	end

	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
	if not Humanoid then
		return print("suicide brah - no humanoid")
	end

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	if not HumanoidRootPart then
		return print("suicide brah - no root")
	end

	-- check if there's a highlight on us - we have spawn FF & we are immortal...
	local SpawnFF = EffectReplicator:FindEffect("SpawnFF")
	local Immortal = EffectReplicator:FindEffect("Immortal")
	if SpawnFF or Immortal then
		HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + Vector3.new(0, 10, 0)
		if not MoveDirectionConnection then
			MoveDirectionConnection = RunService.RenderStepped:Connect(SetMoveDirectionStepped)
		end
		return
	end

	if MoveDirectionConnection then
		MoveDirectionConnection:Disconnect()
		MoveDirectionConnection = nil
	end

	-- fall damage NOW!
	FallDamage:FireServer(Humanoid.Health + Humanoid.MaxHealth, false)
	print("fall damage for", Humanoid.Health + Humanoid.MaxHealth)
end

function Wipe.NonDepthsStage()
	-- Set memory storage
	MemStorageService:SetItem("WipeCharacterStart", "true")
	MemStorageService:SetItem("WipeCharacter", "true")

	-- Die till we go to depths
	while task.wait(0.5) do
		Wipe.Suicide()
		print("looping for depths tp")
	end
end

function Wipe.GetNearestAreaMarker(HumanoidRootPart)
	local PlayerPosition = HumanoidRootPart.Position
	local NearestAreaMarker = nil
	local NearestDistance = math.huge

	for _, AreaMarker in next, AreaMarkers:GetDescendants() do
		if not AreaMarker:IsA("Part") then
			continue
		end

		local DistanceToAreaMarker = (PlayerPosition - AreaMarker.Position).Magnitude
		if DistanceToAreaMarker < NearestDistance or not NearestAreaMarker then
			NearestAreaMarker = AreaMarker
			NearestDistance = DistanceToAreaMarker
		end
	end

	return NearestAreaMarker
end

function Wipe.DepthsStage()
	local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 3)
	if not HumanoidRootPart then
		return print("depths stage - no root")
	end

	-- Die till we go to fragments of self
	while task.wait(0.5) do
		Character = Players.LocalPlayer.Character
		if not Character then
			continue
		end

		HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
		if not HumanoidRootPart then
			continue
		end

		local NearestAreaMarker = Wipe.GetNearestAreaMarker(HumanoidRootPart)
		if NearestAreaMarker.Parent.Name == "Fragments of Self" then
			print("broke we are now in fragments")
			break
		end

		Wipe.Suicide()
		print("looping fragments", NearestAreaMarker.Parent.Name)
	end

	-- Check if anyone is at fragments of self
	for _, Player in next, Players:GetChildren() do
		if Player == Players.LocalPlayer then
			continue
		end

		local PlayerCharacter = Player.Character
		if not PlayerCharacter then
			continue
		end

		local PlayerRoot = PlayerCharacter:FindFirstChild("HumanoidRootPart")
		if not PlayerRoot then
			continue
		end

		if Wipe.GetNearestAreaMarker(PlayerRoot).Parent.Name == "Fragments of Self" then
			print("hopping cause", Player.Name, "in fragments")
			MemStorageService:SetItem("WipeCharacterStart", "true")
			MemStorageService:SetItem("WipeCharacter", "true")
			return ServerHopFunction()
		end
	end

	-- Get self npc
	local SelfNPC = WorkspaceService.NPCs:FindFirstChild("Self", 3)
	if not SelfNPC then
		return print("tf, no self npc")
	end

	-- Get self npc root
	local SelfNPCRoot = SelfNPC:WaitForChild("HumanoidRootPart", 3)
	if not SelfNPCRoot then
		return print("tf, no self root")
	end

	-- Get interact prompt
	local InteractPrompt = SelfNPC:WaitForChild("InteractPrompt", 3)
	if not InteractPrompt then
		return print("tf, no self interaction")
	end

	-- Get dialogue frame...
	local DialogueFrame = Players.LocalPlayer.PlayerGui:WaitForChild("DialogueGui"):WaitForChild("DialogueFrame")

	-- Get distance...
	local Distance = (SelfNPCRoot.Position - HumanoidRootPart.Position).Magnitude

	-- Tween...
	local CurrentTween = game:GetService("TweenService"):Create(HumanoidRootPart, TweenInfo.new(Distance / 80), {
		CFrame = CFrame.new(SelfNPCRoot.Position),
	})
	CurrentTween:Play()
	print("playing tween lol")
	CurrentTween.Completed:Connect(function()
		MemStorageService:SetItem("WipeCharacterStart", "true")
		MemStorageService:RemoveItem("WipeCharacter")
		print("completed")
		-- One option...
		local function OneOption()
			VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
			task.wait()
			VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)
		end

		-- Keep pressing one & enabling proximity if we need to...
		while task.wait(0.1) do
			if not DialogueFrame.Visible then
				fireproximityprompt(InteractPrompt)
				print("enabled proximity!!!")
			end
			OneOption()
			print("keep pressing 1 till we hop!!")
		end
	end)
end

function Wipe.WipeCharacter()
	print("wipe character")
	return CurrentRealm ~= "Depths" and Wipe.NonDepthsStage() or Wipe.DepthsStage()
end

function Wipe.Automate()
	MemStorageService:SetItem("AutoWipe", "true")
	Wipe.WipeCharacter()
	print("auto wipe")
end

-- lol mvoe me i was too lazty wtfffffffffffffffffffff
function Wipe.EchoFarm()
	if MemStorageService:HasItem("WipeCharacter") then
		return
	end

	local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	if not HumanoidRootPart then
		return print("no echo root bruh")
	end

	local Humanoid = Character:WaitForChild("Humanoid")
	if not Humanoid then
		return print("no echo humanod bruh")
	end

	local function IsPlayerNear(Position)
		for _, Player in next, game:GetService("Players"):GetPlayers() do
			if Player == Players.LocalPlayer then
				continue
			end

			local Char = Player.Character
			if not Char then
				continue
			end

			local RootPart = Char:FindFirstChild("HumanoidRootPart")
			if not RootPart then
				continue
			end

			if (Position - RootPart.Position).Magnitude <= 200 then
				return true
			end
		end

		return false
	end

	local function FindNearestIngredient(IngredientName)
		local BestIngredient = nil
		local BestDistance = nil

		for _, Ingredient in next, game:GetService("Workspace"):WaitForChild("Ingredients"):GetChildren() do
			if Ingredient.Name ~= IngredientName then
				continue
			end

			if not Ingredient:IsA("BasePart") then
				continue
			end

			if IsPlayerNear(Ingredient.Position) then
				continue
			end

			local CurrentDistance = (HumanoidRootPart.Position - Ingredient.Position).Magnitude
			if not BestIngredient or CurrentDistance < BestDistance then
				BestDistance = CurrentDistance
				BestIngredient = Ingredient
			end
		end

		return BestIngredient
	end

	local function GetIngrendient(IngredientName)
		local NearestIngredient = FindNearestIngredient(IngredientName)
		if not NearestIngredient then
			return
		end

		local Distance = (NearestIngredient.Position - HumanoidRootPart.Position).Magnitude
		local IngredientTween = game:GetService("TweenService"):Create(HumanoidRootPart, TweenInfo.new(Distance / 80), {
			CFrame = CFrame.new(NearestIngredient.Position),
		})
		IngredientTween:Play()
		IngredientTween.Completed:Wait()

		local InteractPrompt = NearestIngredient:WaitForChild("InteractPrompt", 3)
		if not InteractPrompt then
			return print("tf, no ingredient interaction")
		end

		repeat
			fireproximityprompt(InteractPrompt)
			task.wait(0.1)
		until not NearestIngredient or not NearestIngredient:IsDescendantOf(game)
	end

	local function SitAtNearestCampfire()
		local BestCampfire = nil
		local BestDistance = nil

		for _, Thrown in next, game:GetService("Workspace"):WaitForChild("Thrown"):GetChildren() do
			if Thrown.Name ~= "Campfire" or not Thrown:IsA("Model") then
				continue
			end

			if not Thrown:FindFirstChild("InteractPrompt") then
				continue
			end

			if IsPlayerNear(Thrown:GetPivot().Position) then
				continue
			end

			local Distance = (Thrown:GetPivot().Position - HumanoidRootPart.Position).Magnitude
			if not BestCampfire or Distance <= BestDistance then
				BestCampfire = Thrown
				BestDistance = Distance
			end
		end

		if not BestCampfire then
			return false
		end

		local Distance = (BestCampfire:GetPivot().Position - HumanoidRootPart.Position).Magnitude
		local NearestCampfireTween = game:GetService("TweenService")
			:Create(HumanoidRootPart, TweenInfo.new(Distance / 80), {
				CFrame = CFrame.new(BestCampfire:GetPivot().Position),
			})
		NearestCampfireTween:Play()
		NearestCampfireTween.Completed:Wait()

		local InteractPrompt = BestCampfire:WaitForChild("InteractPrompt", 3)
		if not InteractPrompt then
			return print("tf, no campfire interaction")
		end

		repeat
			fireproximityprompt(InteractPrompt)
			task.wait(0.1)
		until EffectReplicator:FindEffect("Resting")

		return true
	end

	local function CookBrownDentSoup()
		local ohTable1 = {
			["Browncap"] = true,
			["Dentifilo"] = true,
		}

		game:GetService("ReplicatedStorage"):WaitForChild("Requests"):WaitForChild("Craft"):InvokeServer(ohTable1)

		local ChoicePrompt = Players.LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt")
		if ChoicePrompt then
			ChoicePrompt:WaitForChild("Choice"):InvokeServer(1)
		end
	end

	local function CheckIngredient(IngredientName)
		if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild(IngredientName) then
			return true
		end
		return Players.LocalPlayer.Backpack:FindFirstChild(IngredientName)
	end

	while not CheckIngredient("Browncap") or not CheckIngredient("Dentifilo") do
		if not CheckIngredient("Browncap") then
			print("attempting to get browncap bruh")
			GetIngrendient("Browncap")
		end
		if not CheckIngredient("Dentifilo") then
			print("attempting to get dentifilo")
			GetIngrendient("Dentifilo")
		end
		task.wait(0.2)
	end

	repeat
		task.wait(2)
	until SitAtNearestCampfire() ~= false

	repeat
		CookBrownDentSoup()
		task.wait(0.2)
	until Players.LocalPlayer.Backpack:FindFirstChild("Mushroom Soup")

	MemStorageService:SetItem("AutoEcho", "true")

	Wipe.WipeCharacter()
end

return Wipe