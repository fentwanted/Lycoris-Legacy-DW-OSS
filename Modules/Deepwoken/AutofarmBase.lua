local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService('PathfindingService')
local Players = game:GetService("Players")

local Player = Players.LocalPlayer ---@type Player
local Character = Player.Character ---@type Model
local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid") ---@type Humanoid
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart") ---@type BasePart

---@module Decompiled/EffectReplicator
local EffectReplicator = getgenv().require(ReplicatedStorage:WaitForChild("EffectReplicator"))
local FinishedTween = false

local RayParams = RaycastParams.new()
RayParams.FilterDescendantsInstances = { workspace.Map }
RayParams.FilterType = Enum.RaycastFilterType.Include

---@type Path
local Path = PathfindingService:CreatePath({
    WaypointSpacing = 4,
    AgentHeight = 6,
    AgentRadius = 2,
    AgentCanJump = true,
    Costs = {
        KillZone = 1e999,
        Pavement = 0.75,
        Concrete = 0.75,
        WoodPlanks = 0.75,
        Wood = 0.9,
        Mud = 0.9,
        Grass = 1.05
    }
})

local functionCache = {}

---@param NewCharacter Model
local function CharacterAdded(NewCharacter)
    Character = NewCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    functionCache = {}
end

---@return function
local GetFunction = (function(Name)
    if functionCache[Name] then
        return functionCache[Name]
    end
    for i,v in pairs(getgc()) do
        if typeof(v) ~= 'function' then continue end
        if iscclosure(v) or isexecutorclosure(v) then continue end
        local info = debug.getinfo(v)
        if info.name == Name then
            functionCache[Name] = v
            return v
        end
    end
end)

local Jumping = false
local function FakeJump()
	task.spawn(function()
        if not RootPart then
            return
        end
    
        if not Humanoid then
            return
        end
    
        repeat
            task.wait()
        until not Jumping and Humanoid.FloorMaterial ~= Enum.Material.Air
    
        Jumping = true
        Humanoid.Jump = true
        RootPart.Velocity = RootPart.CFrame.UpVector * Humanoid.JumpPower * 1.2
        
        task.delay(.2, function()
            Jumping = false
        end)
    
        local func = GetFunction('VaultCheck')
        if not func then
            return warn("VaultCheck function not found.")
        end
        
        setthreadidentity(2)
        func()
        setthreadidentity(7)
        
        task.delay(.2, function()
            setthreadidentity(2)
            func()
            setthreadidentity(7)
    
            task.wait(.05)
            
            local func = GetFunction('WallCheck')
            if not func then
                return warn("WallCheck function not found.")
            end
            
            setthreadidentity(2)
            func()
            setthreadidentity(7)
        end)
    end)
end

---@param Toggle boolean
local function Sprint(Toggle)
    task.spawn(function()
        if EffectReplicator:FindEffect('Sprinting') and Toggle then
            return
        end

        local func = GetFunction('Sprint')
        if not func then
            return warn("Sprint function not found.")
        end
    
        local HoldUpv = debug.getupvalues(func)[15]
        setthreadidentity(2)

        HoldUpv.W = Toggle
        func(Toggle)

        setthreadidentity(7)
    end)
end

---@param Goal Vector3
---@param Yield boolean
---@param UseRaycast boolean
local function LerpToPosition(Goal, Yield, UseRaycast)
	local Distance = (RootPart.Position - Goal).Magnitude
	
	local StartPos = CFrame.new(RootPart.Position)
	local Speed = 1.1
	local FinalCF

	for i = 0, Distance, Speed do
		local Progress = i/Distance
		local VertCF = CFrame.new(Goal)
		local LerpCF = StartPos:Lerp(VertCF, Progress)
		
		local RayResult
        if UseRaycast then
            RayResult = workspace:Raycast(LerpCF.Position, LerpCF.UpVector*-800, RayParams)
        end
        
		local Position = (RayResult and RayResult.Position) or LerpCF.Position
		local LinearPos = Vector3.new(VertCF.X, Position.Y, VertCF.Z)
		FinalCF = CFrame.new(Position, LinearPos)

		RootPart.Velocity = Vector3.zero
		RootPart.CFrame = FinalCF
		task.wait()
	end

	if Yield then
		repeat
			RootPart.Velocity = Vector3.zero
			RootPart.CFrame = FinalCF
			task.wait()
		until FinishedTween

        FinishedTween = false
	end
end

---@param Goal Vector3
---@param Yield boolean
local function PathfindToPosition(Goal, Yield)
	local Finished = false

	task.spawn(function()
		local PathBlocked = false
		local Distance = Player:DistanceFromCharacter(Goal)

		Path.Blocked:Connect(function()
			Path:ComputeAsync(RootPart.Position, Goal)
			PathBlocked = true
		end)

		repeat
			task.wait(.5)
			PathBlocked = false
			Path:ComputeAsync(RootPart.Position, Goal)
			Distance = Player:DistanceFromCharacter(Goal)

			if Path.Status ~= Enum.PathStatus.Success then
                Sprint(true)
                
				Humanoid:MoveTo(Goal)

                if RootPart.Velocity.Magnitude < 1 then
                    ---@type RaycastResult
                    local RayResult = workspace:Raycast(RootPart.Position, RootPart.CFrame.LookVector*8, RayParams)
                    if RayResult and RayResult.Instance then
                        FakeJump()
                    end
                end
				continue
			end

			local Waypoints = Path:GetWaypoints()
			for i,v in pairs(Waypoints) do
				repeat
                    Humanoid:MoveTo(v.Position)

                    Sprint(true)
                    
                    if RootPart.Velocity.Magnitude < 1 then
                        ---@type RaycastResult
                        local RayResult = workspace:Raycast(RootPart.Position, RootPart.CFrame.LookVector*8, RayParams)
                        if RayResult and RayResult.Instance then
                            FakeJump()
                        end
                    end

					task.wait()
				until PathBlocked or Player:DistanceFromCharacter(v.Position) < 6

				if PathBlocked then
					PathBlocked = false
					break
				else
					local AltWaypoint = Waypoints[i-1]
					if v.Action == Enum.PathWaypointAction.Jump or (AltWaypoint and AltWaypoint.Action == Enum.PathWaypointAction.Jump) then
						FakeJump()
					end
				end
			end
		until Distance < 8
        
        Sprint(false)

		Finished = true
	end)

	if Yield then
		repeat
			task.wait(.5)
		until Finished
	end

	return
end

---@param Toggle boolean
local function FinishTween(Toggle)
    FinishedTween = Toggle
end

task.delay(2, function()
    PathfindToPosition(Player:GetMouse().Hit.Position)
end)

if Player.Character then
    CharacterAdded(Player.Character)
end

Player.CharacterAdded:Connect(CharacterAdded)

return {
    Sprint = Sprint,
    CharacterAdded = CharacterAdded,
    LerpToPosition = LerpToPosition,
    FinishTween = FinishTween,
    PathfindToPosition = PathfindToPosition
}