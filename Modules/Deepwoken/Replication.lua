local l_ReplicatedStorage_0 = game:GetService("ReplicatedStorage")
local Player = game:GetService('Players').LocalPlayer
local script = l_ReplicatedStorage_0.ClientEffectModules.Replication.Replication
local v2 = getgenv().require(l_ReplicatedStorage_0.Modules.Lib)

local UpdateList = {}
local v152 = {
    DamageReadout = function(v80)
        local root = v80.root
        local msg = v80.msg
        local color = v80.col
        if typeof(msg) == "number" then
            msg = v2.format("%.02f", msg)
        end
        local v84 = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1) * 2
        local v85 = script.DamageSplash:Clone()
        v85.Adornee = root
        v85.Size = UDim2.new(2.5, 0, 0.5, 0)
        v85.StudsOffsetWorldSpace = v84
        v85.TextLabel.Text = msg
        if color then
            v85.TextLabel.TextColor3 = color
        end
        v85.Parent = workspace.Thrown

        game.TweenService:Create(v85, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
            Size = UDim2.new(5, 0, 1, 0)
        }):Play()

        game.TweenService:Create(v85, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            StudsOffsetWorldSpace = v84 + Vector3.new(0, 10, 0, 0)
        }):Play()

        task.delay(3, function() --[[ Line: 323 ]]
            if v85:FindFirstChild("TextLabel") then
                game.TweenService:Create(v85.TextLabel, TweenInfo.new(2), {
                    TextTransparency = 1
                }):Play()
                if v85.TextLabel:FindFirstChild("UIStroke") then
                    game.TweenService:Create(v85.TextLabel.UIStroke, TweenInfo.new(2), {
                        Transparency = 1
                    }):Play()
                end
            end
        end)

        game.ReplicatedStorage.Debris:Fire(v85, 5)
    end,
    ClearTrackers = function(_)
        for _, v in next, game.CollectionService:GetTagged("HealthTracker") do
            v:Destroy()
        end
    end,
    HealthTracker = function(sum)
		---@type Model
        local Character = sum.Character

        if UpdateList[Character] then
            return
        end

		---@type Humanoid
        local Humanoid = Character and Character:FindFirstChild("Humanoid")
        if not Humanoid then
            return
        else
			---@type BasePart
            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
			if not HumanoidRootPart then return end

            ---@type Player
            local TargetPlayer = game.Players:GetPlayerFromCharacter(Character)
            if TargetPlayer == Player then
                return
            end

            UpdateList[Character] = true

            Character.Destroying:Once(function()
                pcall(function()
                    UpdateList[Character] = nil
                end)
            end)

            HumanoidRootPart.Destroying:Once(function()
                pcall(function()
                    UpdateList[Character] = nil
                end)
            end)

            ---@type BillboardGui
            local HasTracker = HumanoidRootPart:FindFirstChild("Tracker")
            if HasTracker then
                HasTracker:Destroy()
            end

            ---@type BillboardGui
            local Tracker = script.Tracker:Clone()
            Tracker.Parent = HumanoidRootPart
            Tracker:AddTag("HealthTracker")

            ---@type RBXScriptConnection
            local Connection = nil
            local function update()
                if not Connection then
                    return
                elseif not Character.Parent or not HumanoidRootPart.Parent then
                    Connection:Disconnect()
                    pcall(function()
                        UpdateList[Character] = nil
                    end)
                    return
                elseif not Tracker:FindFirstChild("TextLabel") then
                    Connection:Disconnect()
                    pcall(function()
                        UpdateList[Character] = nil
                    end)
                    return
                else
                    local Format = ("%* [%i/%i] [%i]\n%*%%")
                    if TargetPlayer then
                        Format = ("%* [%i/%i] [%i]\n[Ping: %i] %s\n%*%%")
                    end

                    local DangerTime = Humanoid:GetAttribute('DangerExpiration') or -1
                    local ServerTime = workspace:GetServerTimeNow()
                    local TimeLeft = math.ceil(DangerTime - ServerTime)
                    local EstimateTime
                    if TimeLeft >= 60 then
                        EstimateTime = os.date("%Mm %Ss", TimeLeft)
                    else
                        EstimateTime = os.date("%Ss", TimeLeft)
                    end
                    
                    local Name = Humanoid:GetAttribute('CharacterName') or Character:GetAttribute('MOB_rich_name') or Character.Name
                    local MidHP = Humanoid.Health / Humanoid.MaxHealth
                    local Percentage = string.format("%.01f", MidHP * 100)
                    local Distance = Player:DistanceFromCharacter(HumanoidRootPart.Position) or -1
                    local Type = ''

                    if Character:GetAttribute('State') then
                        Type = 'mob'
                    end

                    if TargetPlayer then
                        Type = 'player'
                    end
                    
                    if Character.Parent == workspace.NPCs then
                        Type = 'npc'
                    end

                    if not Toggles['Esp_'..Type].Value then
                        Tracker.Enabled = false
                        return
                    end

                    local Text
                    if TargetPlayer then
                        local Ping = Character:GetAttribute("AveragePing") or -1
                        Text = Format:format(Name, Humanoid.Health, Humanoid.MaxHealth, Distance, Ping, (DangerTime > 0 and '[Danger: '..EstimateTime..']') or '', Percentage)
                    else
                        Text = Format:format(Name, Humanoid.Health, Humanoid.MaxHealth, Distance, Percentage)
                    end

                    Tracker.MaxDistance = Options['Esp_' .. Type].Value
                    Tracker.Enabled = true
                    Tracker.TextLabel.Text = Text
                    Tracker.TextLabel.TextColor3 = Options['EspColor_' .. Type].Value
                    return
                end
            end

            Connection = Humanoid.Changed:Connect(update)
            update()
            return
        end
    end,
    ToggleHealth = function(sum)
        local Hide = sum.Hide
        local Humanoid = sum.Character:FindFirstChild("Humanoid")
        if Humanoid and not Hide then
            Humanoid.HealthDisplayDistance = 100
            Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
            Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
            return
        else
            if Humanoid and Hide then
                Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
                Humanoid.HealthDisplayDistance = 0
                Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
            end
            return
        end
    end
}
return v152
