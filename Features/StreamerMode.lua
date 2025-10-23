local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local MemStorageService = game:GetService("MemStorageService")
local VIM = Instance.new("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local Maid = getgenv().Maid
local robloxRequre = getgenv().require

local MaleNames = robloxRequre(ReplicatedStorage.Info.NameGenerator.FirstName.Male)
local EtreanNames = robloxRequre(ReplicatedStorage.Info.NameGenerator.LastName.Etrean)

getgenv().StreamerMode = StreamerMode or {}
StreamerMode.Cache = {}
StreamerMode.HookedConnections = {}
StreamerMode.CachedConnections = {}

function StreamerMode.HookConnections(Connection, Source, Function, GetOriginalFunction)
    local OriginalFunction

    local Success, Error = pcall(function()
        local Connections = getconnections(Connection)
        table.insert(CachedConnections, Connections)
        for i,v in pairs(Connections) do
            if v.Thread and getstateenv(v.Thread).script == Source then
                v:Disable()
                OriginalFunction = v.Function
            end
        end
    end)

    if not Success then
        for i,v in pairs(StreamerMode.CachedConnections) do
            for i2,v2 in pairs(v) do
                if v2.Thread and getstateenv(v2.Thread).script == Source then
                    v2:Disable()
                    OriginalFunction = v2.Function
                end
            end
        end
    end
    
    if Function then
        table.insert(StreamerMode.HookedConnections, Connection.Connect(Connection,function(...)
            if GetOriginalFunction and OriginalFunction then
                Function(OriginalFunction, ...)
            else
                Function(...)
            end
        end))
    end
end

function StreamerMode.UnhookConnections()
    for i,v in pairs(StreamerMode.CachedConnections) do
        for i2,v2 in pairs(v) do
            v2:Enable()
        end
    end
end

function StreamerMode.GenerateName()
    local FN = MaleNames[math.random(#MaleNames)]
    local LN = EtreanNames[math.random(#EtreanNames)]

    return FN .. " " .. LN
end

function StreamerMode.GetSettings()
    return {
        HideGuilds = Toggles.StreamerModeHideGuilds.Value,
        HideRegion = Toggles.StreamerModeHideRegion.Value,
        HideServerAge = Toggles.StreamerModeHideAge.Value,
        Username = Options.StreamerModeName.Value,
        GuildName = Options.StreamerModeGuild.Value,
        RandomizeName = Toggles.RandomizeName.Value
    }
end

function StreamerMode.PlayerAdded(Player)
    local Settings = StreamerMode.GetSettings()
    local GeneratedName = StreamerMode.GenerateName()

    StreamerMode.Cache[Player] = {
        Original = {
            FirstName = Player:GetAttribute("FirstName"),
            LastName = Player:GetAttribute("LastName"),
            CharacterName = Player:GetAttribute("CharacterName"),
            Guild = Player:GetAttribute("Guild")
        },
        CharacterName = GeneratedName,
        FirstName = GeneratedName:split(" ")[1],
        LastName = GeneratedName:split(" ")[2]
    }

    if Settings.RandomizeName then
        Player:SetAttribute("CharacterName", GeneratedName)
        Player:SetAttribute("FirstName", GeneratedName:split(" ")[1])
        Player:SetAttribute("LastName", GeneratedName:split(" ")[2])
        Player:SetAttribute("Guild", "")
        StreamerMode.RandomizeName()
    end
end

function StreamerMode.LiveAdded(Function, Character)
    local IsPlayer = Players:GetPlayerFromCharacter(Character)
    if not IsPlayer then
        return
    end
    
    local Humanoid = Character:WaitForChild("Humanoid", 9e9)
    if not Humanoid then
        return
    end

    local Settings = StreamerMode.GetSettings()
    if not Settings.RandomizeName then
        return Function(Character)
    end

    if not StreamerMode.Cache[IsPlayer] then
        return Function(Character)
    end
    
    Function(Character)
end

function StreamerMode.RefreshLeaderboard()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local LeaderboardGui = PlayerGui:WaitForChild("LeaderboardGui")

    for i,v in pairs(LeaderboardGui.MainFrame.ScrollingFrame:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end

    LeaderboardGui.LeaderboardClient.Disabled = true
    task.wait()
    LeaderboardGui.LeaderboardClient.Disabled = false
end

function StreamerMode.RandomizeName()
    local Settings = StreamerMode.GetSettings()
    if not Settings.RandomizeName then

        for i,v in pairs(Players:GetPlayers()) do
            if v == LocalPlayer or not StreamerMode.Cache[v] then continue end
            local PlayerInfo = StreamerMode.Cache[v]
            v:SetAttribute("CharacterName", PlayerInfo.Original.CharacterName)
            v:SetAttribute("FirstName", PlayerInfo.Original.FirstName)
            v:SetAttribute("LastName", PlayerInfo.Original.LastName)
            if Settings.HideGuilds then
                v:SetAttribute("Guild", "")
            else
                v:SetAttribute("Guild", PlayerInfo.Original.Guild)
            end
        end

        return
    end

    for i,v in pairs(Players:GetPlayers()) do
        if v == LocalPlayer or not StreamerMode.Cache[v] then continue end
        local PlayerInfo = StreamerMode.Cache[v]
        v:SetAttribute("CharacterName", PlayerInfo.CharacterName)
        v:SetAttribute("FirstName", PlayerInfo.FirstName)
        v:SetAttribute("LastName", PlayerInfo.LastName)
        if Settings.HideGuilds then
            v:SetAttribute("Guild", "")
        else
            v:SetAttribute("Guild", PlayerInfo.Original.Guild)
        end
    end
end

function StreamerMode.Init()
    if not MemStorageService:HasItem("StreamerModeName") then
        MemStorageService:SetItem("StreamerModeName", StreamerMode.GenerateName())
    end

    StarterGui:WaitForChild("WorldInfo").ResetOnSpawn = false
    StarterGui:WaitForChild("LeaderboardGui").ResetOnSpawn = false

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local WorldInfo = PlayerGui:WaitForChild("WorldInfo")
    local LeaderboardGui = PlayerGui:WaitForChild("LeaderboardGui")
    local JournalFrame = PlayerGui:WaitForChild("BackpackGui"):WaitForChild("JournalFrame")
    WorldInfo.ResetOnSpawn = false
    LeaderboardGui.ResetOnSpawn = false

    StreamerMode.HookConnections(workspace.Live.ChildAdded, LeaderboardGui.LeaderboardClient, StreamerMode.LiveAdded, true)
    StreamerMode.HookConnections(ReplicatedStorage.Requests.LevelChanged.OnClientEvent, WorldInfo.WorldInfoClient)

    local PlayerInfo = ReplicatedStorage.Requests.Get:InvokeServer("Level") or {}
	local Level = PlayerInfo.Level or 0

    Maid.LevelChanged = ReplicatedStorage.Requests.LevelChanged.OnClientEvent:Connect(function(lvl)
        Level = lvl
    end)

    Maid.StreamerMode_Heartbeat = RunService.Heartbeat:Connect(function()
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local KillGUI = PlayerGui:FindFirstChild("KillGUI")

        if KillGUI then
            for _, instance in next, KillGUI do
                if instance.Name ~= "Confirm" and not instance:IsA("LocalScript") then
                    instance:Destroy()
                end
            end
        end

        local JournalFrame = PlayerGui:WaitForChild("BackpackGui"):WaitForChild("JournalFrame")
        local WorldInfo = PlayerGui:WaitForChild("WorldInfo")
        local InfoFrame = WorldInfo:FindFirstChild("InfoFrame")
        local CharacterInfo = InfoFrame:FindFirstChild("CharacterInfo")
        local ServerInfo = InfoFrame:FindFirstChild("ServerInfo")
        local GameInfo = InfoFrame:FindFirstChild("GameInfo")
        local AgeInfo = InfoFrame:FindFirstChild("AgeInfo")
        local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

        if not CharacterInfo or not ServerInfo or not GameInfo or not AgeInfo then
            return
        end

        local Spoof_Name = MemStorageService:GetItem("StreamerModeName")
        local Spoof_Guild
        local Settings = StreamerMode.GetSettings()

        if Settings.Username ~= "" then
            Spoof_Name = Settings.Username
        end

        if Settings.GuildName ~= "" then
            Spoof_Guild = Settings.GuildName
        end

        if Humanoid then
            Humanoid.DisplayName = Spoof_Name
        end

        LocalPlayer:SetAttribute("CharacterName", Spoof_Name)
		LocalPlayer:SetAttribute("FirstName", Spoof_Name)
		LocalPlayer:SetAttribute("LastName", "")
		LocalPlayer:SetAttribute("Guild", Spoof_Guild)
		
		CharacterInfo.Character.Text = Spoof_Name
		AgeInfo.Visible = not Settings.HideServerAge
		CharacterInfo.Slot.Text = ("[Lvl.%i]"):format(Level)
		ServerInfo.ServerTitle.Visible = false
        ServerInfo.ServerRegion.Visible = not Settings.HideRegion
		
		JournalFrame.CharacterName.Text = Spoof_Name
    end)

    for i,v in pairs(Players:GetPlayers()) do
        if v == LocalPlayer then continue end
        task.spawn(StreamerMode.PlayerAdded,v)
    end

    Maid.StreamerPlayerAdded = Players.PlayerAdded:Connect(function(Player)
        if Player == LocalPlayer then return end
        task.spawn(StreamerMode.PlayerAdded,Player)
    end)

    for i,v in pairs(LeaderboardGui.MainFrame.ScrollingFrame:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end

    task.wait(.1)

    LeaderboardGui.LeaderboardClient.Disabled = true
    WorldInfo.WorldInfoClient.Disabled = true
    task.wait()
    LeaderboardGui.LeaderboardClient.Disabled = false
    WorldInfo.WorldInfoClient.Disabled = false
end

function StreamerMode.Revert()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local WorldInfo = PlayerGui:WaitForChild("WorldInfo")
    local LeaderboardGui = PlayerGui:WaitForChild("LeaderboardGui")
    local JournalFrame = PlayerGui:WaitForChild("BackpackGui"):WaitForChild("JournalFrame")
    local InfoFrame = WorldInfo:FindFirstChild("InfoFrame")

    StreamerMode.UnhookConnections()
    
    if Maid.StreamerMode_Heartbeat then
        Maid.StreamerMode_Heartbeat = nil
    end

    if Maid.StreamerPlayerAdded then
        Maid.StreamerPlayerAdded = nil
    end

    for i,v in pairs(StreamerMode.HookedConnections) do
        v:Disconnect()
    end

    for i,v in pairs(LeaderboardGui.MainFrame.ScrollingFrame:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end

    for i,v in pairs(Players:GetPlayers()) do
        if v == LocalPlayer then continue end
        task.spawn(function()
            local CachedData = StreamerMode.Cache[v]
            if not CachedData then
                return
            end

            v:SetAttribute("CharacterName", CachedData.Original.CharacterName)
            v:SetAttribute("FirstName", CachedData.Original.FirstName)
            v:SetAttribute("LastName", CachedData.Original.LastName)
            v:SetAttribute("Guild", CachedData.Original.Guild)
        end)
    end
    
    task.wait(.1)
    
    local PlayerInfo = ReplicatedStorage.Requests.Get:InvokeServer("FirstName", "LastName", "CharacterKey", "Level") or {}
    local CharacterName = PlayerInfo.FirstName .. " " .. PlayerInfo.LastName

    LocalPlayer:SetAttribute("CharacterName", CharacterName)
    LocalPlayer:SetAttribute("FirstName", PlayerInfo.FirstName)
    LocalPlayer:SetAttribute("LastName", PlayerInfo.LastName)
    
    InfoFrame.CharacterInfo.Character.Text = CharacterName
    InfoFrame.AgeInfo.Visible = true
    InfoFrame.CharacterInfo.Slot.Text = PlayerInfo.CharacterKey:gsub("user_", "") .. (" [Lvl.%i]"):format(PlayerInfo.Level)
    InfoFrame.ServerInfo.ServerTitle.Visible = true
    InfoFrame.ServerInfo.ServerRegion.Visible = true
    JournalFrame.CharacterName.Text = CharacterName

    LeaderboardGui.LeaderboardClient.Disabled = true
    WorldInfo.WorldInfoClient.Disabled = true
    task.wait()
    LeaderboardGui.LeaderboardClient.Disabled = false
    WorldInfo.WorldInfoClient.Disabled = false
end

return StreamerMode