local Hitbox = {}

local Part = Instance.new("Part")
Part.Size = Vector3.zero
Part.Anchored = false
Part.CanCollide = false
Part.Massless = true
Part.Color = Color3.fromRGB(255, 0 ,0)
Part.Material = Enum.Material.Neon
Part.Shape = Enum.PartType.Block
Part.Transparency = 1

local Weld = Instance.new("Weld")
Weld.Part1 = Part
Weld.Parent = Part

local function getParent()
	local parent = workspace:GetChildren()[math.random(#workspace:GetChildren())]

	if parent.Name == "Live" then
		repeat
			parent = workspace:GetChildren()[math.random(#workspace:GetChildren())]
			task.wait()
		until parent.Name ~= "Live"
	end

	return parent
end

function Hitbox.new(RootPart, Shape)
	if not RootPart then return end
    local HitboxPart = Part:Clone()
    HitboxPart.CFrame = RootPart.CFrame
    HitboxPart.Shape = Shape
    HitboxPart.Weld.Part0 = RootPart
    HitboxPart.Parent = getParent()

    return HitboxPart
end

function Hitbox.scan(HitboxPart, Character)
	if Toggles.AutoParryDebug.Value then
		return
	end

    local Hitted = false
	
	for i = 1, 5 do
		local Connect_ret = HitboxPart.Touched:Connect(function() end)
		local TouchingParts = HitboxPart:GetTouchingParts()
		Connect_ret:Disconnect()
	
		for i,v in pairs(TouchingParts) do
			if v.Parent == Character then
				Hitted = true
				break
			end
		end

		if Hitted then
			break
		end

		task.wait()
	end

	return Hitted
end

return Hitbox