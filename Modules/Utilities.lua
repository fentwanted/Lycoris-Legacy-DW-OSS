local module = {}
local Inputs = {}

local VIM = Instance.new("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local HttpService = game:GetService('HttpService')
local UniqueSessionId = HttpService:GenerateGUID(false)

local EffectReplicator = getgenv().require(ReplicatedStorage:WaitForChild("EffectReplicator"))
local Signal = require("Signal")

local alp = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
function module.DecodeBase64(data)
	return LPH_NO_VIRTUALIZE(function()
		data = string.gsub(data, "[^" .. alp .. "=]", "")
		return (
			data:gsub(".", function(x)
				if x == "=" then
					return ""
				end
				local r, f = "", (alp:find(x) - 1)
				for i = 6, 1, -1 do
					r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
				end
				return r
			end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
				if #x ~= 8 then
					return ""
				end
				local c = 0
				for i = 1, 8 do
					c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
				end
				return string.char(c)
			end)
		)
	end)()
end

function module.CheckVoidwalker(Target)
	local Backpack = Target:WaitForChild("Backpack", 9e9)

	repeat
		task.wait()
	until CollectionService:HasTag(Backpack, "Loaded")

	if not Toggles.NotifyVoidwalker.Value then
		return
	end

	if Backpack:WaitForChild("Talent:Voidwalker Contract", 10) then
		getgenv().Library:Notify(Target:GetAttribute("CharacterName") .. " is a voidwalker ", 15)
	end
end

function module.CheckVoidwalkers()
	for _, v in pairs(Players:GetPlayers()) do
		SecureSpawn(module.CheckVoidwalker, v)
	end
end

function module.CheckLegendaryWeapon(Target, v)
	return LPH_NO_VIRTUALIZE(function()
		if not v:IsA("Tool") or not v:FindFirstChild("Rarity") or not v:FindFirstChild("WeaponData") then
			return
		end

		if Target == Players.LocalPlayer then
			return
		end

		if v.Rarity.Value ~= "Mythic" then
			return
		end

		if
			game.HttpService:JSONDecode(
				module.DecodeBase64(v.WeaponData.Value):sub(1, #module.DecodeBase64(v.WeaponData.Value) - 2)
			).SoulBound
		then
			return
		end

		if not Toggles.NotifyMythic.Value then
			return
		end

		local TargetName = Target:GetAttribute("CharacterName") or "N/A"
		local Name = v.Name:split("$")[1]
		local Quality = v:FindFirstChild("Quality")
				and v.Quality.Value ~= 0
				and (" [%i Star/s]"):format(v.Quality.Value)
			or ""
		local Enchant = v:FindFirstChild("Enchant")
				and v.Enchant.Value ~= ""
				and (" [Enchant: %s]"):format(v.Enchant.Value)
			or ""

		getgenv().Library:Notify(TargetName .. " has " .. Name .. Quality .. Enchant, 15)
	end)()
end

function module.CheckLegendaryWeapons()
	for _, v in pairs(Players:GetPlayers()) do
		for _, item in pairs(v.Backpack:GetChildren()) do
			SecureSpawn(module.CheckLegendaryWeapon, v, item)
		end
	end
end

function module.Analytics(DiscordId)
	print("analytics [1/3]")
	local MarkerWorkspace = ReplicatedStorage:WaitForChild("MarkerWorkspace")
	local AreaMarkers = MarkerWorkspace:WaitForChild("AreaMarkers")
	local SERVER_REGION = ReplicatedStorage:WaitForChild("SERVER_REGION")
	local SERVER_AGE = ReplicatedStorage:WaitForChild("SERVER_AGE")
	local SERVER_NAME = ReplicatedStorage:WaitForChild("SERVER_NAME")
	local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	local Humanoid = Character:WaitForChild("Humanoid")
	local CharacterData = ReplicatedStorage:WaitForChild("Requests")
		:WaitForChild("Get")
		:InvokeServer("CharacterKey", "Level") or {}
	print("analytics [2/3]")
	local NearestAreaMarker = nil
	local NearestDistance = math.huge
	local PlayerPosition = HumanoidRootPart.Position

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
	print("analytics [3/3]")
	local cachedPlayerData = CachedPlayersData[Players.LocalPlayer]
	-- REDACTED FOR PRIVACY
	print("analytics 1 [1/3]")
	-- Check if he is a mod...
	module.CheckLocalPlayerMod(DiscordId)
	print("analytics 1 [2/3]")
	-- Track for blacklisted words in messages...
	task.spawn(function()
		getgenv().Maid:GiveTask(
			ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("OnMessageDoneFiltering").OnClientEvent:Connect(function(MessageData)
				module.CheckBlacklistedWords(MessageData, DiscordId)
			end)
		)
	end)
	print("analytics 1 [3/3]")
	-- Warn...
	warn("Loaded Analytics")
end

function module.CheckBlacklistedWords(MessageData, DiscordId)
	-- Get player...
	local SpeakingPlayer = Players:FindFirstChild(MessageData.FromSpeaker)

	-- Blacklisted words list...
	local BlacklistedWordsList = {
		"clipped",
		"banned",
		"ban",
		"mod",
		"clip",
		"cheater",
		"hacker",
		"exploiter",
		"exploit",
		"exploiting",
		"hack",
		"cheat",
		"exploit",
		"report",
		string.lower(Player.Name),
	}

	-- Check for blacklisted words...
	local FoundBlacklistedWords = {}

	-- Loop through content...
	for _, BlacklistedWord in next, BlacklistedWordsList do
		if not string.match(string.lower(MessageData.Message), BlacklistedWord) then
			continue
		end

		FoundBlacklistedWords[#FoundBlacklistedWords + 1] = BlacklistedWord
	end

	-- Check if there is any blacklisted words...
	if #FoundBlacklistedWords <= 0 then
		return
	end

	-- Get character & humanoid...
	local SpeakingCharacter = SpeakingPlayer and SpeakingPlayer.Character or nil
	local SpeakingHumanoid = SpeakingCharacter and SpeakingCharacter:FindFirstChild("Humanoid") or nil
	local IsUs = SpeakingPlayer == Player
	local CharacterName = SpeakingHumanoid and SpeakingHumanoid.DisplayName or "N/A"
	if IsUs and getgenv().OriginalDisplayName then
		CharacterName = getgenv().OriginalDisplayName
	end

	-- Log message...
	-- REDACTED FOR PRIVACY
end

local function GetAdvancedRank(userid)
	local api = "https://groups.roblox.com/v2/users/%i/groups/roles?includeLocked=true"

	local url = api:format(userid)
	local response = nil

	while true do
		response = request({
			Url = url,
			Method = "GET",
			Headers = {
				["Content-Type"] = "application/json",
			},
		})

		if response.Success and response.Body then
			break
		end

		warn("Failed to get advanced rank, retrying...")

		task.wait(30)
	end

	warn("Checking advanced rank...")

	local ismod, rank = false, nil
	local body = game:GetService("HttpService"):JSONDecode(response.Body).data

	for i, v in pairs(body) do
		local groupid = v.group.id
		if groupid ~= 5212858 then
			continue
		end
		if v.role.rank <= 0 then
			continue
		end

		ismod = true
		rank = v.role.name
	end

	return ismod, rank
end

function module.CheckLocalPlayerMod(DiscordId)
	if not Player or Player.Parent == nil then
		return
	end

	local IsMod, Rank = GetAdvancedRank(Player.UserId)
	local Player_Name = Player:GetAttribute("CharacterName") or Player.Name
	if not IsMod then
		return warn(Player.Name, "Player is not a high ranking user")
	end

	-- REDACTED FOR PRIVACY
end

function module.GetModRank(Player)
	-- Notification database...
	local NotifDB = {}

	-- Listen for mod status...
	local IsMod, Rank = GetAdvancedRank(Player.UserId)
	local Player_Name = Player:GetAttribute("CharacterName") or Player.Name -- Backup

	if not IsMod then
		return warn(Player.Name, "Player is not a high ranking user")
	end

	-- Check if player exists...
	if not Player or Player.Parent == nil then
		return warn(Player.Name, "This player does not have a proper parent or does not exist")
	end

	-- Check if we should notify...
	if not Toggles.NotifyMod.Value then
		return warn(Player.Name, "Player is a mod, but we're not going to notify it")
	end

	getgenv().MODDETECTED = true

	NotifDB[Player.Name] = getgenv().Library:Notify(Player_Name .. " is a " .. Rank)

	local soundy = Instance.new("Sound", game:GetService("CoreGui"))
	soundy.SoundId = "rbxassetid://247824088"
	soundy.PlaybackSpeed = 1
	soundy.Volume = 5
	soundy.Playing = true
	soundy:Play()

	task.wait(3)

	soundy:Destroy()

	getgenv().Maid[Player.Name .. "ancestry"] = Player.AncestryChanged:Connect(function()
		NotifDB[Player.Name]()
		NotifDB[Player.Name] = nil
	end)
end

function module.GetCharacter()
	return LPH_NO_VIRTUALIZE(function()
		local Character = Player.Character
		local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
		local Humanoid = Character and Character:FindFirstChild("Humanoid")
		local CharacterHandler = Character and Character:FindFirstChild("CharacterHandler")
		local InputClient = CharacterHandler and CharacterHandler:FindFirstChild("InputClient")
		if not RootPart or not Humanoid or not CharacterHandler or not InputClient then
			return
		end

		return Character, RootPart, Humanoid, CharacterHandler, InputClient
	end)()
end

function module.CharacterCheck()
	return LPH_NO_VIRTUALIZE(function()
		local Character, RootPart, Humanoid, CharacterHandler, InputClient = module.GetCharacter()
		if not Character or not RootPart or not Humanoid or not CharacterHandler or not InputClient then
			return
		end

		return true
	end)()
end

function module.GetTouchingParts(_, Part)
	return LPH_NO_VIRTUALIZE(function()
		local Connect_ret = Part.Touched:Connect(function() end)
		local TouchingParts = Part:GetTouchingParts()
		Connect_ret:Disconnect()
		return TouchingParts
	end)()
end

function module.NewBodyMover(Class)
	return LPH_NO_VIRTUALIZE(function()
		local BodyMover = Instance.new(Class)
		CollectionService:AddTag(BodyMover, "AllowedBM")

		return BodyMover
	end)()
end

function module:GetInput(Key)
	return LPH_NO_VIRTUALIZE(function()
		if not Inputs[Key:lower()] then
			return
		end

		return true
	end)()
end

function module:InAir()
	return LPH_NO_VIRTUALIZE(function()
		local _, _, Humanoid = module.GetCharacter()

		if not Humanoid then return false end

		if EffectReplicator:FindEffect("Swimming") then
			return false
		end

		local State = Humanoid:GetState()
		if State == Enum.HumanoidStateType.Freefall or State == Enum.HumanoidStateType.Jumping then
			return true
		end

		if EffectReplicator:FindEffect("AirBorne") then
			return true
		end

		return false
	end)()
end

function module.FindNearestEntity(Distance)
	return LPH_NO_VIRTUALIZE(function()
		local Character, RootPart = module.GetCharacter()
		if not Character or not RootPart then
			return
		end

		local Distance = Distance or 150
		local Target

		for _, v in pairs(module.EntityList) do
			if not v:FindFirstChild("HumanoidRootPart") then
				continue
			end
			if not v:FindFirstChild("Humanoid") then
				continue
			end
			if v:FindFirstChild("Torso") and v.Torso:FindFirstChild("RagdollAttach") then
				continue
			end
			if v ~= Character and (v.HumanoidRootPart.Position - RootPart.Position).Magnitude < Distance then
				Distance = (v.HumanoidRootPart.Position - RootPart.Position).Magnitude
				Target = v
			end
		end

		return Target
	end)()
end

function module.GetRGBFromColor3(v)
	return math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255)
end

local function GetStats(Text)
    local result = {}

    for match in string.gmatch(Text, "[^;]+") do
        match = match:match("^%s*(.-)%s*$")
    
        if not match:find("<font") then
            local value, key = match:match("^%+([%d%.]+)%%?%s*(.*)$")
            if value and key then
                key = key:gsub("%s+", " ")
                result[key] = tonumber(value)
            end
        end
    end

    return result
end

function module.AutoLoot(v)
	task.spawn(function()
		if not Toggles.AutoLoot.Value then
			return
		end

		if not v:GetAttribute('LootData') then
			return
		end

		local Loots = {}
		local ChoicePrompt = v
		local LootData = HttpService:JSONDecode(ChoicePrompt:GetAttribute('LootData'))
		local ChoiceFrame = ChoicePrompt:FindFirstChild("ChoiceFrame")
		local ChoiceEvent = ChoicePrompt:FindFirstChild("Choice")

		local LootFilters = getgenv().Options.AutoLootFilters.Value
		if typeof(LootFilters) == "string" then
			LootFilters = { LootFilters }
		end

		local LootTypes = getgenv().Options.AutoLootTypes.Value
		if typeof(LootTypes) == "string" then
			LootTypes = { LootTypes }
		end

		for i, v in next, LootData do
			local Passed = not Toggles.AutoLootFilter.Value and not Toggles.AutoLootType.Value and not Toggles.AutoLootStats.Value

			local PassedLootType = false
			if Toggles.AutoLootType.Value then
				for i,_ in pairs(LootTypes) do
					if i == v.eqp_slot then
						PassedLootType = true
						Passed = true
					end
				end
			end

			local isLegendary = false
			local PassedRarity = false
			if Toggles.AutoLootFilter.Value then
				for i,_ in pairs(LootFilters) do
					if i == v.color then
						isLegendary = (i == "Legendary")
						PassedRarity = true
						Passed = true
					end
				end
			end

			local PassedStats = false
			local StatsInfo = v.rich_stats and GetStats(v.rich_stats) or {}

			if Toggles.AutoLootStats.Value then
				for _, v in pairs({"HP", "ETH", "PEN", "SAN", "ELM Armor", "PHY Armor", "Monster DMG", "Monster Armor"}) do
					local Val = getgenv().Options["Loot_" .. v].Value
					if Val == "" or Val == "0" or Val == 0 then continue end

					if not StatsInfo[v] then
						continue
					end
	
					if StatsInfo[v] >= tonumber(Val) then
						PassedStats = true
						continue
					end
				end
			end

			if Toggles.AutoLootConditionalOr.Value then
				Passed = Passed or PassedRarity or PassedLootType or PassedStats
			else
				if Toggles.AutoLootType.Value then
					Passed = Passed and PassedLootType
				end

				if Toggles.AutoLootFilter.Value then
					Passed = Passed and PassedRarity
				end

				if Toggles.AutoLootStats.Value then
					Passed = Passed and PassedStats
				end
			end

			if Toggles.LootMedallion.Value then
				Passed = Toggles.LootMedallion.Value and v:WaitForChild("Title").Text == "Kyrsan Medallion"
				if Passed then
					ChoiceEvent:FireServer("LOOT_ALL")
					break
				end
			end

			if Toggles.LootGems.Value then
				Passed = Toggles.LootGems.Value and v:WaitForChild("Title").Text:match("Gem") or isLegendary
			end

			if Passed then
				table.insert(Loots, v.text)
			end
		end

		for i, v in next, Loots do
			task.wait(0.15)
			repeat
				ChoiceEvent:FireServer(v)
				task.wait(0.2)
			until not ChoicePrompt or not ChoicePrompt.Options:FindFirstChild(v)
		end

		task.wait(1)

		if Toggles.AutoCloseChest.Value then
			firesignal(ChoiceFrame.Exit.MouseButton1Click)
		end
	end)
end

local Casting = false
function module.AutoWisp(v)
	LPH_NO_VIRTUALIZE(function()
		if not Toggles.AutoWisp.Value then
			return
		end

		local _, _, _, CharacterHandler = module.GetCharacter()
		if not CharacterHandler then
			return
		end

		if Casting then
			repeat
				task.wait()
			until not Casting
		end

		Casting = true

		local Symbol = v:WaitForChild("TextLabel")
		task.wait(0.1)--Symbol.Text
		CharacterHandler.Requests.SpellCheck:FireServer(Symbol.Text, Player:GetMouse().Hit)
		task.wait(.05)
		Casting = false
	end)()
end

function module.GetNearestCharacter()
	return LPH_NO_VIRTUALIZE(function()
		local Character, RootPart = module.GetCharacter()
		if not Character or not RootPart then
			return
		end

		local Distance = 150
		local Target

		for _, v in pairs(workspace.Live:GetChildren()) do
			local Character = v
			if not Character or Character == Player.Character then
				continue
			end

			local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
			if not HumanoidRootPart then
				continue
			end

			if (HumanoidRootPart.Position - RootPart.Position).Magnitude < Distance then
				Distance = (HumanoidRootPart.Position - RootPart.Position).Magnitude
				Target = v
			end
		end

		return Target
	end)()
end

getgenv().Maid:GiveTask(UserInputService.InputBegan:Connect(LPH_NO_VIRTUALIZE(function(input, gpe)
	if gpe then
		return
	end

	if input.KeyCode then
		Inputs[input.KeyCode.Name:lower()] = true
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Inputs["m1"] = true
	end
end)))

getgenv().Maid:GiveTask(UserInputService.InputEnded:Connect(LPH_NO_VIRTUALIZE(function(input, gpe)
	if gpe then
		return
	end

	if input.KeyCode then
		Inputs[input.KeyCode.Name:lower()] = false
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Inputs["m1"] = false
	end
end)))

module.EntityList = {}
module.EntityAdded = Signal.new()
module.EntityRemoved = Signal.new()

getgenv().Maid:GiveTask(workspace.Live.ChildAdded:Connect(LPH_NO_VIRTUALIZE(function(Entity)
	if table.find(module.EntityList, Entity) then
		return
	end

	table.insert(module.EntityList, Entity)

	getgenv().Maid:GiveTask(Entity.ChildAdded:Connect(function(v)
		if v.Name ~= "HumanoidRootPart" then
			return
		end

		module.EntityAdded:Fire(Entity)
	end))

	getgenv().Maid:GiveTask(Entity.ChildRemoved:Connect(function(v)
		if v.Name ~= "HumanoidRootPart" or not table.find(module.EntityList, Entity) then
			return
		end

		table.remove(module.EntityList, table.find(module.EntityList, Entity))
		module.EntityRemoved:Fire(Entity)
	end))

	if Entity:FindFirstChild("HumanoidRootPart") then
		module.EntityAdded:Fire(Entity)
	end
end)))

SecureCall(LPH_NO_VIRTUALIZE(function()
	for _, v in pairs(workspace.Live:GetChildren()) do
		if table.find(module.EntityList, v) then
			continue
		end

		SecureSpawn(function()
			v:WaitForChild("Humanoid", 9e9)
			table.insert(module.EntityList, v)
			v:WaitForChild("HumanoidRootPart", 9e9)
			module.EntityAdded:Fire(v)
		end)
	end
end))

module.VIM = Instance.new("VirtualInputManager")
module.NoStunEffects = {
	"Stun",
	"LightAttack",
	"Action",
	"MobileAction",
	"OffhandAttack",
}
module.RollChecks = {
	"CarryObject",
	"UsingSpell",
	"NoAttack",
	"Dodged",
	"NoRoll",
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
	"Pinned",
}
module.AnimLogBlacklist = {
	"roll",
	"stun",
	"dodge",
	"draw",
	"shake",
	"idle",
	"parry",
	"newparried",
	"block",
	"backup",
	"run",
	"walk",
	"wall",
	"dash",
	"spit",
	"vault",
	"slide",
	"hit",
	"stagger",
	"spit",
	"action",
	"drop",
	"knock",
	"pinned",
	"execute",
	"wakeup",
	"backflip",
	"dark soul",
	"carried",
}

return module
