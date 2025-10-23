--!nocheck

type Character = Model & {Humanoid: Humanoid, HumanoidRootPart: BasePart}
type Humanoid_Fix = Humanoid & AnimationController

-- // Script Services \\

local PathfindingService = game:GetService('PathfindingService')
local HttpService = game:GetService('HttpService')

-- // Modules \\

local function compareWaypoints(oldWaypoint, Waypoint1: {PathWaypoint})
	if #Waypoint1 ~= #oldWaypoint then
		return
	end
	for i,v in next, Waypoint1 do
		if (v.Position - oldWaypoint[i].Position).Magnitude > 3 then
			return
		end
	end
	return true
end

local module = {}

function module.new(Mob: Model)
	local self = {}
	self.Mob = Mob
	self.Humanoid = Mob.Humanoid
	self.RootPart = Mob.HumanoidRootPart
	self.Active = false
	self.Path = PathfindingService:CreatePath({
		WaypointSpacing = 5,
		AgentHeight = 6,
		AgentCanJump = true,
	}) :: Path

	return setmetatable(self, {__index = module})
end

function module:Stop()
	self.Active = false
end

function module:Run(Target: Part | Vector3 | CFrame)
	if self.Active then
		return
	end

	self.Active = true

	self.WaypointID = HttpService:GenerateGUID(false)

	while self.Active do
		local Path = self.Path :: Path
		local Humanoid = self.Humanoid
		local RootPart = self.RootPart
		local LegCF = RootPart.CFrame*CFrame.new(0,-2.8,0)
		local FrontCF = RootPart.CFrame*CFrame.new(0,0,-1.7)
		local FrontCF2 = RootPart.CFrame*CFrame.new(0,0,-2.1)
		local FrontCF3 = RootPart.CFrame*CFrame.new(0,0,-4.5)
		local HeadCF = RootPart.CFrame*CFrame.new(0,6,0)
		local RLeg = RootPart.CFrame*CFrame.new(1,0,0)*CFrame.new(0,0,-.25)
		local LLeg = RootPart.CFrame*CFrame.new(-1,0,0)*CFrame.new(0,0,-.25)

		if not Humanoid or not RootPart then
			self.Active = false
			break
		end

		local Position = Target
		if typeof(Target) == "CFrame" or typeof(Target) == "Instance" then
			Position = Target.Position
		end

		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Include
		Params.FilterDescendantsInstances = { workspace.Map }

		task.desynchronize()

		local targetTaller = Position.Y > RootPart.Position.Y
		local parkourGround = workspace:Raycast(FrontCF.p,FrontCF.UpVector*-10,Params)
		local parkourGround2 = workspace:Raycast(FrontCF2.p,FrontCF2.UpVector*-10,Params)
		local parkourGround3 = workspace:Raycast(FrontCF3.p,FrontCF3.UpVector*-10,Params)
		local frontGround = workspace:Raycast(RLeg.p,RLeg.UpVector*-10,Params)
		local frontGround2 = workspace:Raycast(LLeg.p,LLeg.UpVector*-10,Params)
		local shouldJump = workspace:Raycast(LegCF.p,LegCF.LookVector*2.5,Params)
		local visionObscured = workspace:Raycast(HeadCF.p,HeadCF.LookVector*2,Params)
		local shouldReallyJump = shouldJump and shouldJump.Instance.CanCollide and not Humanoid.Jump and not visionObscured
		local shouldJumpParkour = (parkourGround or parkourGround2 or parkourGround3) and not frontGround and not frontGround2 and not Humanoid.Jump and not visionObscured
		local originPosition = targetTaller and not Humanoid.Jump and RootPart.Position + Vector3.new(0,2,0) or RootPart.Position
		local grounded = workspace:Raycast(RootPart.Position,RootPart.CFrame.UpVector*-20,Params)

		task.synchronize()

		Humanoid.Jump = shouldJumpParkour or shouldReallyJump
		if Humanoid.FloorMaterial == Enum.Material.Air and grounded then
			originPosition = grounded.Position
			originPosition += Vector3.new(0,3,0)
		end

		Path:ComputeAsync(originPosition, Position)

		if Path.Status == Enum.PathStatus.Success then
			self.WaypointID = HttpService:GenerateGUID(false)
			local ourWaypoint = self.WaypointID
			task.spawn(function()
				task.synchronize()
				local Waypoints = Path:GetWaypoints() :: {PathWaypoint}
				if not self.oldWaypoint then
					self.oldWaypoint = Waypoints
				end

				for i,v in next,Waypoints do
					if not compareWaypoints(self.oldWaypoint, Waypoints) then
						self.oldWaypoint = Waypoints
					end

					if Humanoid.FloorMaterial == Enum.Material.Air then
						local LastWaypoint = 2
						Humanoid:MoveTo(Waypoints[LastWaypoint].Position)
					else
						Humanoid:MoveTo(v.Position)
					end

					--print('Humanoid Moving to Point:',i)
					while (RootPart.Position-v.Position).Magnitude > 4.5 and self.Active do
						if ourWaypoint ~= self.WaypointID then
							break
						end
						if not compareWaypoints(self.oldWaypoint, Waypoints) then
							break
						end
						task.wait()
					end

					if ourWaypoint ~= self.WaypointID then
						break
					end

					if not self.Active then
						break
					end
				end
			end)
		elseif Path.Status == Enum.PathStatus.NoPath then
			--print('path not found..')
		end
	end
end

return module