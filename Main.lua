repeat task.wait() until game:IsLoaded()

if getgenv().SouLoaded or getgenv().ExecutedLycoris then
	return warn("Lycoris is already loaded.")
end

getgenv().ExecutedLycoris = true

if not LPH_OBFUSCATED then
	loadstring([[getgenv().LPH_NO_VIRTUALIZE = function(...) return ... end]])()
end

getgenv().SecureCall = function(f, ...)
	local Args = { ... }
	if typeof(f) ~= "function" then
		warn("[ SecureCall ] function expected got " .. typeof(f))
		return
	end

	local Success, Error = pcall(f, ...)
	if not Success and Error then
		local traceback = debug.traceback()
		warn("Exception found: " .. Error .. ", Traceback: " .. traceback)
	end

	return Success, Error
end

getgenv().SecureSpawn = function(f, ...)
	task.spawn(SecureCall, f, ...)
end

getgenv().grabBody = function(Url)
    return request({
		Url = Url,
		Method = "GET"
	}).Body
end

local old_warn; old_warn = hookfunction(warn, newcclosure(function(...) -- block annoying output from deepwoken
	local warn1 = select(1, ...)
	if typeof(warn1) == 'string' and warn1:match('couldnt play') then
		return
	end

	return old_warn(...)
end))

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

SecureCall(function()
	getgenv().Status = Status or { Busy = false }
	getgenv().Config = require("Modules/Deepwoken/V2Configs")

	local did_queue = false
	local MemStoreService = game:GetService("MemStorageService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CollectionService = game:GetService("CollectionService")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	local isRealTester = not script_key
	local IsPaidUser = true

	if isfolder('Lycoris') then
		makefolder('Lycoris')
	end

	if game.PlaceId == 4111023553 then
		warn("Script Only run in Main-Game (script has been queued on teleport.)")
		local UserId = tostring(LocalPlayer.UserId)
		local ServerHopSlot = MemStoreService:HasItem("ServerHop") and MemStoreService:GetItem("ServerHop")
		local ServerHopJobId = MemStoreService:HasItem("ServerHopJobId") and MemStoreService:GetItem("ServerHopJobId")

		if ServerHopSlot then
			warn("Attempting to server hop")

			local StartMenu = ReplicatedStorage:WaitForChild("Requests"):WaitForChild("StartMenu")
			local SelectedSlot = ReplicatedStorage:WaitForChild("SlotData"):FindFirstChild(UserId):WaitForChild(ServerHopSlot, 5)
			local Realm = SelectedSlot:FindFirstChild("Realm").Value
			if Realm == "???" then
				Realm = "EtreanLuminant"
			end
			if Realm:find("The Depths") then
				Realm = "Depths"
			end
			if Realm:find("The Eastern") then
				Realm = "EastLuminant"
			end
			local ValidRealm = ReplicatedStorage:WaitForChild("Servers"):WaitForChild(Realm):FindFirstChild(ServerHopJobId, true)
			if not ValidRealm and ServerHopJobId ~= "" then
				warn("JobId is in a different realm. cancelling")
				MemStoreService:RemoveItem("ServerHop")
				return
			end

			warn("Teleporting to selected server")
			StartMenu.Start:FireServer(ServerHopSlot, { PrivateTest = false })

			task.wait(0.5)

			if ServerHopJobId ~= "" then
				warn("USING JOB ID", ServerHopJobId)
				StartMenu.PickServer:FireServer(ServerHopJobId)
			else
				warn("NOT USING JOB ID")
				StartMenu.PickServer:FireServer("none")
			end

			MemStoreService:RemoveItem("ServerHop")
		end

		return
	end

	local KeyHandler = require("Modules/Deepwoken/KeyHandler")
	local oldDestroy, OldNameCall, OldNewIndex, OldFireServer, OldUnreliFireServer = KeyHandler:Penetrate()

	local RequireMaid = require("Modules/Maid")
	getgenv().Maid = RequireMaid.new()

	local Interface = require("Modules/Interface")
	local Configs = require("Modules/Configs")
	local Wipe = require("Features/Wipe")
	require("aescbc")()
	local AutoParryBuilder = require("Modules/Deepwoken/AutoParryBuilder")
	local Tab, LycorisConnect, Library, SaveManager, ThemeManager = Interface.Tab, Interface.Maid, Interface.Library, Interface.SaveManager, Interface.ThemeManager

	local AutoParryTab = Tab.new("Combat")
	local MiscTab = Tab.new("Misc")
	local AutoFarmTab = Tab.new("AutoFarm")
	local EspTab = Tab.new("ESP")
	local KeybindsTab = Tab.new("Keybinds")
	local UISettings = Tab.new("UI Settings")

	getgenv().ESPTab = EspTab
	
	local AutoFarmGroupBox = AutoFarmTab:newGroupBox("AutoFarm")
	local MaestroGroupBox = AutoFarmTab:newGroupBox("Maestro", true)
	
	local MovementGroupBox = MiscTab:newGroupBox("Movement")
	local NotifierGroupBox = MiscTab:newGroupBox("Notifier")
	local AutoLootGroupBox = MiscTab:newGroupBox("AutoLoot")
	local StreamerGroupBox = MiscTab:newGroupBox("Streamer Mode")
	local AntiquarianGroupBox = MiscTab:newGroupBox("Antiquarian")

	local ClientGroupBox = MiscTab:newGroupBox("Client", true)
	local QoLGroupBox = MiscTab:newGroupBox("Quality Of Life", true)
	local NetworkGroupBox = MiscTab:newGroupBox("Network Utilities", true)
	local ServerHopGroupBox = MiscTab:newGroupBox("Teleport Utilities", true)
	local RemovalGroupBox = MiscTab:newGroupBox("Removals", true)
	--local BoobwokenGroupBox = MiscTab:newGroupBox("Boobwoken", true)

	local CombatGroupBox = AutoParryTab:newGroupBox("Auto Parry")
	local EspGroupBox = EspTab:newGroupBox("Esp")

	local function AddGenericESP(Name, ShowHealthbar)
		local DisplayName = Name:gsub("_", " ")
		local PlayerEspGroupBox = EspTab:newGroupBox(DisplayName .. " ESP")
		PlayerEspGroupBox:newToggle("Esp_" .. Name:lower(),	"Enabled",	false,	("ESP for %s."):format(DisplayName .. "s"))
		PlayerEspGroupBox:newToggle("EspDistance_" .. Name:lower(), "Show Distance", false, "Enable Distance for esp.")
		if ShowHealthbar then
			PlayerEspGroupBox:newToggle("EspBox_" .. Name:lower(), "Show Boxes", false, "Enable boxes for esp.")
			PlayerEspGroupBox:newToggle(	"EspHealth_" .. Name:lower(),		"Show Healthbar",		false,		"Enable Healthbar for esp."		)
			PlayerEspGroupBox:newToggle("EspTracer_" .. Name:lower(), "Show Tracer", false, "Enable Tracer for esp.")
		end
		PlayerEspGroupBox:newSlider("Esp_" .. Name:lower(), "Distance", 2000, 0, 20000, 0, true)
		PlayerEspGroupBox:newColorPicker("EspColor_" .. Name:lower(), DisplayName, Color3.fromRGB(255, 255, 255))
	end

	local function AddCustomESP(Name, Folder, CheckCallback)
		local CustomEspGroup = EspTab:newGroupBox(Name .. " ESP", true)
		CustomEspGroup:newToggle("Esp_" .. Name:lower(), "Enabled", false, ("Enable Custom ESP %s."):format(Name))
		CustomEspGroup:newSlider("Esp_" .. Name:lower(), "Distance", 2000, 0, 20000, 0, true)
		CustomEspGroup:newColorPicker("EspColor_" .. Name:lower(), Name, Color3.fromRGB(255, 255, 255))
		for i, v in next, Folder:GetChildren() do
			if not CheckCallback(v) then
				continue
			end
			CustomEspGroup:newToggle(Name .. "Esp_" .. v.Name, v.Name, false, "ESP for " .. v.Name)
		end
	end

	local LocalPlayerTags = CollectionService:GetTags(LocalPlayer)
	local HasEmotePack1 = LocalPlayerTags and LocalPlayerTags["EmotePack1"]
	local HasEmotePack2 = LocalPlayerTags and LocalPlayerTags["EmotePack2"]
	local HasMetalBadge = LocalPlayerTags and LocalPlayerTags["MetalBadge"]

	local function CleanEmotes()
		if not HasEmotePack1 then
			CollectionService:RemoveTag(LocalPlayer, "EmotePack1")
		end

		if not HasEmotePack2 then
			CollectionService:RemoveTag(LocalPlayer, "EmotePack2")
		end

		if not HasMetalBadge then
			CollectionService:RemoveTag(LocalPlayer, "MetalBadge")
		end
	end

	local function UnlockEmotes(Toggle)
		local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
		local GestureGui = PlayerGui and PlayerGui:FindFirstChild("GestureGui")

		if not GestureGui then
			return
		end

		if not Toggle then
			return CleanEmotes()
		end

		if not HasEmotePack1 then
			CollectionService:AddTag(LocalPlayer, "EmotePack1")
		end

		if not HasEmotePack2 then
			CollectionService:AddTag(LocalPlayer, "EmotePack2")
		end

		if not HasMetalBadge then
			CollectionService:AddTag(LocalPlayer, "MetalBadge")
		end

		for _, v in pairs(GestureGui.MainFrame.GestureScroll:GetChildren()) do
			if v:IsA("TextLabel") then
				v:Destroy()
			end
		end

		GestureGui.GestureClient.Enabled = false
		GestureGui.GestureClient.Enabled = true
	end

	local function InstantLog()
		local oldkeybind = Options.InstantLog.Value
		task.wait(0.1)
		if oldkeybind ~= Options.InstantLog.Value then
			return
		end
		ReplicatedStorage.Requests.ReturnToMenu:FireServer()
		local Prompt = LocalPlayer.PlayerGui:WaitForChild("ChoicePrompt", 3)
		if Prompt then
			Prompt.Choice:FireServer(true)
		end
	end

	local function ServerHop()
		local GuiService = game:GetService("GuiService")
		local StarterGui = game:GetService("StarterGui")
		local CoreGui = game:GetService("CoreGui")
		local VirtualInputManager = Instance.new("VirtualInputManager")

		MemStoreService:SetItem("ServerHop", LocalPlayer:GetAttribute("DataSlot"))
		MemStoreService:SetItem("ServerHopJobId", Options.ServerHopJobId.Value)
		
		if Toggles.BlockUser.Value then
			for _, v in pairs(Players:GetPlayers()) do
				if v == LocalPlayer then
					continue
				end

				local FriendsWith = LocalPlayer.IsFriendsWith
				local IsFriend = pcall(FriendsWith, LocalPlayer, v.UserId)
				if IsFriend then
					continue
				end

				local BlockedUIDs = StarterGui:GetCore("GetBlockedUserIds")
				local LastBlocked = #BlockedUIDs

				GuiService:ClearError()

				repeat
					task.wait()
					StarterGui:SetCore("PromptBlockPlayer", v)

					local Confirm = CoreGui.RobloxGui.PromptDialog.ContainerFrame:FindFirstChild("ConfirmButton")
					if not Confirm then
						break
					end

					local Pos = Confirm.AbsolutePosition + Vector2.new(40, 40)
					VirtualInputManager:SendMouseButtonEvent(Pos.X, Pos.Y, 0, false, game, 1)
					task.wait()
					VirtualInputManager:SendMouseButtonEvent(Pos.X, Pos.Y, 0, true, game, 1)
				until #StarterGui:GetCore("GetBlockedUserIds") ~= LastBlocked

				break
			end
		end

		InstantLog()
	end

	local function ExportBuild()
		local SelectedPlayer = Options.ExportBuildPlayer.Value
		if not SelectedPlayer or SelectedPlayer == "" or typeof(SelectedPlayer) ~= "string" then
			print('selected player is nil')
			print(SelectedPlayer)
			return
		end

		local Attunements = {"Galebreather", "Flamecharmer", "Shadowcaster", "Ironsinger", "Frostdrawer", "Thundercaller"}
		local Target = Players:FindFirstChild(SelectedPlayer)
		
		local function GetPlayerLevel()
			local Character = Target.Character

			if not Character then
				return 0
			end

			local attributes = Character:GetAttributes()
			local count = 0
	
			for i, v in next, attributes do
				if not string.match(i, "Stat_") then
					continue
				end
				count = count + v
			end
	
			return math.clamp(math.floor(count / 315 * 20), 1, 20)
		end

		local Talents = ""
		local Mantras = ""
		local Attunement = ""
		local Stats = ""
		local Oath = "Pathfinder"
		local Bell = "N/A"
		local Weapon = "N/A"
		local Power = tostring((GetPlayerLevel()))

		for i,v in pairs(Target.Backpack:GetChildren()) do
			local NameTalent = v.Name:gsub("Talent:", "")

			if v.Name:match("Talent:") and not v.Name:match("Oath") then
				Talents = Talents .. NameTalent .. "\n"
			end
			if v.Name:match("Mantra:") and not v.Name:match("RecalledMantra") then
				Mantras = Mantras .. v.Name:split('{{')[2]:gsub('}}', '') .. "\n"
			end
			if v.Name:match("Oath:") then
				Oath = v.Name:gsub("Talent:Oath: ", "")
			end
			if v.Name:match("Resonance:") then
				Bell = v.Name:gsub("Resonance:", "")
			end
			if table.find(Attunements, NameTalent) then
				Attunement = NameTalent
			end
			if v:IsA('Tool') and v:FindFirstChild('Weapon') then
				Weapon = v.Weapon.Value
			end
		end

		for i,v in pairs(Target.Character and Target.Character:GetAttributes() or {}) do
			if i:match("Stat_") then
				Stats = Stats .. i:gsub("Stat_", "") .. ": " .. v .. "\n"
			end
		end
		
		if Weapon == "N/A" and Target.Character and Target.Character:FindFirstChild("Weapon") then
			Weapon = Target.Character.Weapon.Weapon.Value
		end

		local function ConstructBuild()
			local TotalString = ""
			TotalString = TotalString .. "Player: " .. Target.Name .. "\n\n"
			TotalString = TotalString .. "Oath: " .. Oath .. "\n"
			TotalString = TotalString .. "Bell: " .. Bell .. "\n"
			TotalString = TotalString .. "Weapon: " .. Weapon .. "\n"
			TotalString = TotalString .. "Power: " .. Power .. "\n"
			TotalString = TotalString .. "Attunement: " .. Attunement .. "\n\n"
			TotalString = TotalString .. "Stats:\n" .. Stats .. "\n\n"
			TotalString = TotalString .. "Mantras:\n" .. Mantras .. "\n\n"
			TotalString = TotalString .. "Talents:\n" .. Talents

			return TotalString
		end

		local BuildInfo = ConstructBuild()
		writefile("Lycoris_Export_" .. Target.Name .. ".txt", BuildInfo)

		Library:Notify("Successfully Exported Build to your workspace folder", 3)
	end

	local function TeleportToEastern()
		local firetouchinterest = firetouchinterest or firetouchtransmitter
		local CF = CFrame.new(-2632.8, 628.6, -6707.9)
		
		repeat
			task.spawn(function()
				LocalPlayer:RequestStreamAroundAsync(CF.Position, 1000)
			end)
			task.wait(1)
		until workspace:FindFirstChild("RealmTeleporter")

		local REALMTP = workspace.RealmTeleporter
		local Holder = Instance.new('Model')
		Holder.Parent = workspace
		REALMTP.Parent = Holder

		Holder.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

		for i = 1,10 do
			LocalPlayer.Character:PivotTo(REALMTP.CFrame)
			firetouchinterest(REALMTP, LocalPlayer.Character.HumanoidRootPart, 0)
			task.wait()
		end
	end
	
	-- AntiquarianGroupBox:newToggle("Sell_NoEnchants", "No Enchants", false, "Only sell non enchants.")
	-- AntiquarianGroupBox:newToggle("Sell_OnlyEnchants", "Only Enchants", false, "Only sell Enchants.")
	-- AntiquarianGroupBox:newToggle("Sell_Below3Stars", "Only < 3 Stars", false, "Only sell items below 3 stars.")
	-- AntiquarianGroupBox:newDropdown("Sell_Filters", "Bulk Sell Filters", Configs.SellFilters, "", false, "Bulk Sell Filters.")

	local function BulkSell()
		local Sell_Filters = Options.Sell_Filters.Value
		local Tools = {}
		local Filtered = {}
		
		local function getToolType(v8) -- Decompiled code from Deepwoken
			local v9 = 999;
			if v8:FindFirstChild("Weapon") then
				return 0;
			elseif not (not v8:FindFirstChild("Mantra") and not v8:FindFirstChild("Spec")) or v8:FindFirstChild("Artifact") then
				return 3;
			elseif v8:FindFirstChild("Talent") then
				return 1;
			elseif v8:FindFirstChild("Relic") then
				return 17;
			elseif v8:FindFirstChild("Utility") then
				return 4;
			else
				if v8:FindFirstChild("Equipment") then
					v9 = 10;
					if game:GetService('CollectionService'):HasTag(v8, "Enchanted") then
						return 9;
					end;
				elseif v8:FindFirstChild("WeaponTool") then
					v9 = 8;
					if game:GetService('CollectionService'):HasTag(v8, "Enchanted") then
						return 7;
					end;
				elseif v8:FindFirstChild("Food") then
					return 18;
				elseif v8:FindFirstChild("BookItem") then
					return 19;
				elseif v8:FindFirstChild("Training") then
					return 5;
				elseif v8:FindFirstChild("Potion") then
					return 6;
				elseif v8:FindFirstChild("Schematic") or v8:FindFirstChild("CraftSchematic") then
					return 11;
				elseif v8:FindFirstChild("Ingredient") or v8:FindFirstChild("CraftingIngredient") then
					return 14;
				elseif v8:FindFirstChild("SpellIngredient") or v8:FindFirstChild("RecalledMantra") then
					return 15;
				elseif v8:FindFirstChild("QuestItem") then
					return 12;
				elseif v8:FindFirstChild("Treasure") or v8:FindFirstChild("Loot") then
					return 16;
				elseif v8:FindFirstChild("Item") then
					v9 = 13;
				end;
				return v9;
			end;
		end;
		
		for i,v in pairs(LocalPlayer.Backpack:GetChildren()) do
			if not v:IsA('Tool') then continue end
			if not v:FindFirstChild('Sellable') and not v:FindFirstChild('Droppable') then continue end
			table.insert(Tools, v)
		end
		
		if not Toggles.Sell_Filter.Value then
			Sell_Filters = {}
			for i,v in pairs(Configs.SellFilters) do
				Sell_Filters[v] = true
			end
		end
		
		for i,_ in pairs(Sell_Filters) do
			local Category = LocalPlayer.PlayerGui:FindFirstChild(i, true)
			if not Category then print(i,'not found') continue end
			for _,v in pairs(Tools) do
				local FindName = string.format("%03i", getToolType(v)) .. v.Name
				if table.find(Filtered, v) then print('alr found') continue end
				if not Category:FindFirstChild(FindName, true) and not Category:FindFirstChild(v.Name, true) then print(v.Name, FindName, 'fail category') continue end
				if v:GetAttribute('Enchant') and Toggles.Sell_NoEnchants.Value then print(v.Name, 'fail no enchant') continue end
				if not v:GetAttribute('Enchant') and Toggles.Sell_OnlyEnchants.Value then print(v.Name, 'fail only enchant') continue end
				if (not v:GetAttribute('Quality') or v:GetAttribute('Quality') == 3) and Toggles.Sell_Below3Stars.Value then print(v.Name, 'fail quality') continue end
				
				table.insert(Filtered, v)
				print('added',v.Name)
			end
		end

		local SellItem = KeyHandler.GetKey("SellItem")
		SellItem:FireServer("BatchSell", Filtered)
	end
	
	if not script_key then
		AntiquarianGroupBox:newToggle("Sell_NoEnchants", "No Enchants", false, "Only sell non enchants.")
		AntiquarianGroupBox:newToggle("Sell_OnlyEnchants", "Only Enchants", false, "Only sell Enchants.")
		AntiquarianGroupBox:newToggle("Sell_Below3Stars", "Only < 3 Stars", false, "Only sell items below 3 stars.")
		AntiquarianGroupBox:newToggle("Sell_Filter", "Use Filters", false, "Use Category Filter.")
		AntiquarianGroupBox:newDropdown("Sell_Filters", "Bulk Sell Filters", Configs.SellFilters, "", true, "Bulk Sell Filters.")
		AntiquarianGroupBox:newButton("Bulk Sell", BulkSell, false, "Automatically wipe and go to character selection menu.")
	end

	getgenv().ServerHopFunction = ServerHop

	MovementGroupBox:newToggle("Fly", "Fly", false, "Allow the user to fly.")
	MovementGroupBox:newSlider("FlySpeed", "Fly Speed", 100, 50, 450, 0, true)
	MovementGroupBox:newSlider("FlyUpSpeed", "Fly Space Speed", 100, 50, 200, 0, true)
	MovementGroupBox:newToggle("Speedhack", "Speedhack", false, "Allow the user to walk faster.")
	MovementGroupBox:newSlider("Speedhack", "Speedhack Speed", 100, 15, 250, 0, true)
	MovementGroupBox:newToggle("InfJump", "Infinite Jump", false, "wee i jump inf.")
	MovementGroupBox:newSlider("InfJump", "Jump Power", 150, 50, 500, 0, true)
	MovementGroupBox:newToggle("NoClip", "No Clip", false, "Allow the user to phase thru walls.")
	MovementGroupBox:newToggle("disableNoClipWhenKnocked","Disable NoClip on Ragdoll",false,"Disables NoClip When Knocked")
	MovementGroupBox:newToggle("KnockedOwnership", "Knocked Ownership", false, "Allow movement while knocked.")
	MovementGroupBox:newToggle("AutoSprint", "Auto Sprint", false, "Automatically sprint.")
	MovementGroupBox:newToggle("AgilitySpoof", "Agility Spoofer", false, "Spoof your agility level.")
	MovementGroupBox:newSlider("AgilitySpoof", "Agility Level", 30, 15, 400, 0, true)
	MovementGroupBox:newToggle("TweenToObjective","Tween to Objective",false,"Teleport you to chaser blood jars & ethiron altars.")

	NotifierGroupBox:newToggle("NotifyNPC","Notify Added NPCs",false,"Notifies you when a NPC is recently added.")
	NotifierGroupBox:newToggle("NotifyMythic","Mythic Weapon Notifier",false,"Notifies you when a person has a legendary weapon.")
	NotifierGroupBox:newToggle("NotifyVoidwalker","Voidwalker Notifier",false,"Notifies you when a voidwalker joined.")
	NotifierGroupBox:newToggle("NotifyMod", "Mod Notifier", true, "Notifies you when a moderator joined.")

	ServerHopGroupBox:newToggle("BlockUser", "Block User on Server Hop", false, "Block a random person on server hop.")
	ServerHopGroupBox:newTextbox("ServerHopJobId", "Job Id (Optional)", false, "", false, "JobId to teleport to.", "")
	ServerHopGroupBox:newButton("Server Hop", ServerHop, false, "Server hop to a random server.")

	ClientGroupBox:newToggle("PVPMode", "PVP Mode", false, "Disable Fly,Speedhack and Knocked Ownership.")
	ClientGroupBox:newToggle("PlayerProximity", "Player Proximity", false, "Notifies when a player is nearby.")
	ClientGroupBox:newToggle("PlayerProximityVW","Proximity Only Voidwalker",false,"Notifies only when voidwalker is nearby.")
	ClientGroupBox:newSlider("PlayerProximity", "Player Proximity Distance", 350, 50, 1000, 0)
	ClientGroupBox:newToggle("ShowAllMap", "Show Players on Map", false, "Show everyone's location on the map. [Press M]")
	--ClientGroupBox:newToggle("ChatSpy", "Player Chat Spy", false, "Send other player's chat to you.")
	ClientGroupBox:newToggle("RemoveLootAllCD", "Remove Loot All CD", false, "Removes Loot All CD on Chests.")
	ClientGroupBox:newToggle("ExtendPromptDistance", "Extend Interact Dist", false, "Extend Interact Prompts Distance.")
	ClientGroupBox:newToggle("TpToGround", "TP To Ground", false, "Ignore this, it's only to be used with keybind.")
	ClientGroupBox:newToggle("TalentSpoofer", "Spoof Talents", false, "Spoof Talents (Client Sided)")
	ClientGroupBox:newDropdown("TalentList", "Talent Lists", Configs.TalentSpoof, "", true, "List of Talents")
	ClientGroupBox:newToggle("TalentPicker", "Highlight Builder Talents", false, "Highlight Builder Talents")
	ClientGroupBox:newTextbox("TalentPickerBuilderUrl", "Builder URL", false, "", false, "Talent Picker Builder URL", "")
	if IsPaidUser then
		ClientGroupBox:newToggle("AnimationBlocker", "Animation Blocker", false, "Block Animations")
		ClientGroupBox:newToggle("APBreaker", "Auto Parry Breaker", false, "Block Auto Parry With Misleading Animations")
		ClientGroupBox:newToggle("VisibleAPBreaker", "AP Breaker Visibility", false, "Show AP Breaker To Others")
	end
	ClientGroupBox:newDropdown("ExportBuildPlayer", "Build Target", {}, "", false, "List of Talents")
	ClientGroupBox:newButton("Export Selected Build", ExportBuild, false, "Export the Selected Player's Build.")
	ClientGroupBox:newButton("Respawn", function()
		LocalPlayer.Character:PivotTo(LocalPlayer.Character:GetPivot() * CFrame.new(0,10000000,0))
	end, false, "Respawn safely (will not clear danger).")

	-- - list todo for blast -
    -- 1. echo farm

	StreamerGroupBox:newToggle("StreamerMode", "Streamer Mode", false, "Hide your identity and server info.")
	StreamerGroupBox:newToggle("RandomizeName", "Randomize All Names", false, "Randomize streamer mode names.")
	StreamerGroupBox:newToggle("StreamerModeHideRegion", "Hide Server Region", false, "Hide Server Region.")
	StreamerGroupBox:newToggle("StreamerModeHideAge", "Hide Server Age", false, "Hide Server Age.")
	StreamerGroupBox:newToggle("StreamerModeHideGuilds", "Hide Player Guild", false, "Hide every player's guild.")
	StreamerGroupBox:newTextbox("StreamerModeName","Streamer Mode Name",false,"Buy Lycoris",false,"Spoof name for Streamer Mode.","Lord Regent")
	StreamerGroupBox:newTextbox("StreamerModeGuild","Streamer Mode Guild",false,"Lycoris On Top",false,"Spoof guild for Streamer Mode.","Lycoris Community")
	StreamerGroupBox:newDropdown("StreamerModeRank", "Rank Spoof", {'Godseeker','Grandmaster','Master','W Rank', "Normal"}, "", false, "List of Ranks")

	Options.StreamerModeRank:OnChanged(function()
		task.spawn(function()
			repeat
				task.wait()
			until LocalPlayer.Character and LocalPlayer.Character.Parent == workspace.Live
	
			local Ranks = {Godseeker = 'Red', Grandmaster = 'Gold', Master = 'Silver', ['W Rank'] = 'Deep'}
			local LDClient = LocalPlayer.PlayerGui.LeaderboardGui.LeaderboardClient
			local Rank = Options.StreamerModeRank.Value
			
			local PlayerFrame
			for i,v in pairs(LocalPlayer.PlayerGui.LeaderboardGui.MainFrame.ScrollingFrame:GetChildren()) do
				if v:FindFirstChild('Player') and v.Player.Text == LocalPlayer:GetAttribute('CharacterName') then
					PlayerFrame = v
					break
				end
			end
	
			if not PlayerFrame then
				return print('playerframe not fiouund')
			end
	
			if PlayerFrame.Player:FindFirstChild('EloGradient') then
				PlayerFrame.Player.EloGradient:Destroy()
			end
	
			if not Ranks[Rank] then
				return print('rank not foundd')
			end
			
			local EloGradient = LDClient:FindFirstChild(Ranks[Rank]):Clone()
			EloGradient.Name = "EloGradient"
			EloGradient.Parent = PlayerFrame.Player
		end)
	end)

	AutoLootGroupBox:newToggle("AutoLoot", "Auto Loot", false, "Automatically loot chests that are opened.")
	AutoLootGroupBox:newToggle("LootMedallion", "Only Loot Medallions", false, "Make AutoLoot only take medallions.")
	AutoLootGroupBox:newToggle("LootGems", "Only Loot Gems", false, "Make AutoLoot only take gems.")
	AutoLootGroupBox:newToggle("AutoOpenChest", "Auto Open Chest", false, "Automatically open chest when nearby.")
	AutoLootGroupBox:newToggle("AutoCloseChest", "Auto Close Chest", false, "Automatically close chest when done looting.")
	AutoLootGroupBox:newToggle("AutoLootFilter", "Filter Auto Loot", false, "Filter Loot that will be taken from chests.")
	AutoLootGroupBox:newToggle("AutoLootStats", "Filter Loot Stats", false, "Filter Loot Stats that will be taken from chests.")
	AutoLootGroupBox:newToggle("AutoLootType", "Filter Loot Type", false, "Filter Loot Types that will be taken from chests.")
	AutoLootGroupBox:newToggle("AutoLootConditionalOr", "Filter If Any Are True", false, "Loot filters will loot as long as any of the conditions are met.")
	AutoLootGroupBox:newDropdown("AutoLootFilters", "Filter Lists", Configs.LootFilters, "", true, "Auto Loot Filters")
	AutoLootGroupBox:newDropdown("AutoLootTypes", "Filter Types", Configs.LootTypes, "", true, "Auto Loot Types")
	AutoLootGroupBox:newLabel("Legendary: Purple\n Mythic: Greenish blue")
	AutoLootGroupBox:newLabel("")
	AutoLootGroupBox:newLabel("Auto Loot Stats Filter")
	if IsPaidUser then
		AutoLootGroupBox:newTextbox("Loot_HP","Health",true,0,false,"Minimum Health to loot.","0")
		AutoLootGroupBox:newTextbox("Loot_PHY Armor","Physical Resistance",true,0,false,"Minimum Phys Armor to loot.","0")
		AutoLootGroupBox:newTextbox("Loot_Monster DMG","Monster Damage",true,0,false,"Minimum Monster DMG to loot.","0")
		AutoLootGroupBox:newTextbox("Loot_Monster Armor","Monster Resistance",true,0,false,"Minimum Monster Armor to loot.","0")
		AutoLootGroupBox:newTextbox("Loot_ELM Armor","Elemental Resistance",true,0,false,"Minimum Element Armor to loot.","0")
		AutoLootGroupBox:newTextbox("Loot_PEN","Penetration",true,0,false,"Minimum PEN to loot.","0")
		AutoLootGroupBox:newTextbox("Loot_ETH","Ether",true,0,false,"Minimum Ether to loot.","0")
		AutoLootGroupBox:newTextbox("Loot_SAN","Sanity",true,0,false,"Minimum Sanity to loot.","0")
	end

	if IsPaidUser then
		MaestroGroupBox:newToggle("AutoMaestro","Auto Maestro Fight",false,"You need to atleast do maestro once before using this.")
		MaestroGroupBox:newToggle("MaestroUseCritical","Use Critical",false,"useful for gremorian longspear void.")
		MaestroGroupBox:newToggle("VoidMaestro","Void Maestro [GremorSpear Needed]",false,"self explanatory.")
		MaestroGroupBox:newTextbox("AutoMaestroWebhook","Discord Webhook",false,"",false,"Send a notification specified webhook.","https://discord.com/api/webhooks/xxxx")
	end

	if isRealTester then
		 NetworkGroupBox:newToggle("ShowNetworkOwner", "Show Network Owners", false, "Show Object's Network Ownership.")
	end
	NetworkGroupBox:newToggle("VoidMobs", "Void Mobs", false, "Void mobs within your network ownership.")
	NetworkGroupBox:newToggle("VoidOnPlayerPickUp", "Void On Player Pick Up", false, "Void players that are picked up.")
	NetworkGroupBox:newToggle("AIBreaker", "Pathfind Breaker", false, "Break humanoid mob pathfinding.")
	NetworkGroupBox:newToggle("AIBreaker2", "Bring Mob", false, "Bring humanoid mob ai. [turn on pathfind breaker]")
	NetworkGroupBox:newToggle("TPMob", "TP Mobs To Self", false, "Bring available mob to the specified position.")
	NetworkGroupBox:newToggle("TPMobCamera", "TP Mobs To Camera", false, "Bring available mob to the Camera position.")
	NetworkGroupBox:newToggle("FreecamOnly", "Freecam Only", false, "Only enable if freecam is enabled.")
	NetworkGroupBox:newToggle("TPMobToTarget","TP Mobs To Target",false,"Bring available mob to the selected player.")
	NetworkGroupBox:newDropdown("TPMobToTarget", "TP Mob Target", {}, "All", false, "target for tp mobs")
	NetworkGroupBox:newSlider("TPMobRange", "TP Mob Range", -5, -60, 60, 0)
	NetworkGroupBox:newSlider("TPMobHeight", "TP Mob Height", 0, -60, 60, 0)

	QoLGroupBox:newKeybind("InstantLog", "Insta Log Keybind", "N/A", InstantLog)
	QoLGroupBox:newToggle("AutoPVPMode","Auto PVP Mode",false,"Automatically enable PVP Mode when someone is nearby. PLAYER PROXIMITY REQUIRED")
	QoLGroupBox:newToggle("AutoWisp", "Auto Wisp", false, "you wisp.")
	QoLGroupBox:newToggle("RemoveZoomLimit", "Unlock Zoom Distance", false, "Unlock the Zoom limit.")
	QoLGroupBox:newToggle("UnlockEmotes", "Unlock Emotes", false, "Unlock All Emotes.", UnlockEmotes)
	QoLGroupBox:newToggle("RagdollCancel", "Auto Ragdoll Cancel", false, "Automatically cancel ragdolls when possible.")
	QoLGroupBox:newToggle("AutoPerfectCast", "Auto Perfect Cast", false, "Automatically press m1 while casting mantra.")
	QoLGroupBox:newToggle("ShowKeybind", "Show Keybinds", false, "", function(Toggle) Library.KeybindFrame.Visible = Toggle end)
	QoLGroupBox:newToggle("DamageIndicator", "Damage Indicator", false, "Show when a mob/player took damage.")
	QoLGroupBox:newToggle("DIShowMinor","Show Minor Difference",false,"Show damage indicator even at small differences.")
	QoLGroupBox:newToggle("PerfectStack","Chain of Perfection Counter",false,"Show how much perfection stack you have.")
	QoLGroupBox:newToggle("SanityCounter", "Sanity Counter", false, "Show how much sanity you have.")

	if not script_key then
		QoLGroupBox:newToggle("EffectLog", "Log EffectHandler", false, "")
	end

	QoLGroupBox:newButton("Teleport to Eastern", TeleportToEastern, false, "Do not use if failed after 3 attempts.")
	QoLGroupBox:newButton("Remove Textures", function()
		for _, v in pairs(workspace.Map:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Material = Enum.Material.SmoothPlastic
			end
		end
		getgenv().Maid.FPSBoostTexture = workspace.Map.DescendantAdded:Connect(function(v)
			if v:IsA("BasePart") then
				v.Material = Enum.Material.SmoothPlastic
			end
		end)
	end, false, "NOTE: this is 1x usage, once you turn this on, you can't turn it off until you leave the game.")

	AutoFarmGroupBox:newToggle("AutoCharisma","Auto Charisma Farm",false,"Automatically Copies the text for the charisma book.")
	AutoFarmGroupBox:newTextbox("CharismaCap","Max Charisma",true,0,false,"Amount of charisma to reach before stopping.","75")
	AutoFarmGroupBox:newToggle("AutoMath","Auto Intelligence",false,"Automatically notifies the answer for the math question.")
	AutoFarmGroupBox:newTextbox("IntelCap","Max Intelligence",true,0,false,"Amount of intel to reach before stopping.","75")
	AutoFarmGroupBox:newToggle("AutoFish", "Auto Fish", false, "Automatically fish for u.")
	AutoFarmGroupBox:newSlider("AutoFishDelay", "Hold Delay", 0.1, 0, 0.5, 1)
	AutoFarmGroupBox:newToggle("AutoFishKill","Auto Fish Kill Muds",false,"Automatically kill mudskipper if caught one.")
	AutoFarmGroupBox:newToggle("AutoFishNotify","Auto Fish Notifier",false,"Send you a notification when you got a chest.")
	AutoFarmGroupBox:newTextbox("AutoFishWebhook","Auto Fish Webhook",false,"",false,"Send the loot info to specified webhook.","https://discord.com/api/webhooks/xxxx")
	AutoFarmGroupBox:newToggle("AttachToBack", "Attach To Back", false, "Attach to nearest entity.")
	AutoFarmGroupBox:newSlider("ATBRange", "ATB Range", 5, -30, 30, 0)
	AutoFarmGroupBox:newSlider("ATBHeight", "ATB Height", 0, -30, 30, 0)
	if IsPaidUser then
		AutoFarmGroupBox:newButton("Start Echo Farm", Wipe.EchoFarm, false, "Automatically cook food and wipe. (expects all modifiers to be turned on)")
		AutoFarmGroupBox:newButton("Start Auto Wipe", Wipe.Automate, false, "Automatically wipe for u. (animal king)")
		AutoFarmGroupBox:newButton("Suicide",Wipe.Suicide,false,"Automatically suicide and lose a life.")
		AutoFarmGroupBox:newButton("Wipe Character",Wipe.WipeCharacter,false,"Automatically wipe and go to character selection menu.")
	end

	RemovalGroupBox:newToggle("NoEchoMod", "No Echo Modifiers", false, "Remove Echo Modifiers.")
	RemovalGroupBox:newToggle("NoKillBricks", "Remove KillBricks", false, "Removes Void and SuperWalls.")
	RemovalGroupBox:newToggle("NoStun", "No Stun", false, "Disable stuns.")
	RemovalGroupBox:newToggle("NoSpeedDebuff", "No Speed Debuff", false, "Disable any incoming Speed Debuffs.")
	RemovalGroupBox:newToggle("NoFallDamage", "No Fall Damage", false, "Prevent you from taking fall damage.")
	RemovalGroupBox:newToggle("NoAcid", "Anti Acid", false, "Prevent you from taking damage from acids.")
	RemovalGroupBox:newToggle("AntiFire", "Anti Fire", false, "Automatically remove fire when inflicted by one.")
	RemovalGroupBox:newToggle("AntiWind", "Anti Wind", false, "Removes the Layer 2 Wind.")
	RemovalGroupBox:newToggle("NoFog", "No Fog", false, "Removes fog.")
	RemovalGroupBox:newToggle("NoBlind", "No Blind", false, "Removes blindness flaw.")
	RemovalGroupBox:newToggle("NoBlur", "No Blur", false, "Removes blur from the lighting effects.")
	RemovalGroupBox:newToggle("NoJumpCooldown", "No Jump Cooldown", false, "Prevent you from getting jump CD.")
	RemovalGroupBox:newToggle("FullBright", "Full Bright", false, "Remove shadows.")
	RemovalGroupBox:newSlider("FullBright", "Full Bright Scale", 0, 0, 100, 0)

	CombatGroupBox:newToggle("AutoParry", "Auto Parry (beta)", false, "Parry automatically when attacked.")
	if IsPaidUser then
		CombatGroupBox:newToggle("AutoParryV2", "Auto Parry V2", false, "In heavy development, can not be used with AutoParry V1.")
	end
	CombatGroupBox:newSlider("HitboxMultiplier", "Hitbox Size Multiplier [AP V2]", 1, 0, 2, 1)
	CombatGroupBox:newSlider("RepeatOffset", "Repeat Parry Offset (ms) [AP V2]", 0, -1000, 1000, 0)
	if not script_key then
		CombatGroupBox:newToggle("AutoParryV3", "Auto Parry V3", false, "this is in early development. only works on m1s, it also disables APV1 M1 AP")
	end
	CombatGroupBox:newSlider("AutoParryOffset", "Timing Offset (ms)", 0, -1000, 1000, 0)
	CombatGroupBox:newSlider("PingAdjustment", "Ping Adjustment", 75, 0, 100, 0)
	CombatGroupBox:newToggle("AutoParryAdapt","Adaptive Auto Parry",false,"Auto Parry will try to adapt when it's not accurate. this is heavily experimental, should not be used.")
	CombatGroupBox:newToggle("IgnoreTarget", "Ignore Mob Target", false, "Parry even if the mob isn't targeting you.")
	CombatGroupBox:newToggle("RollOnParryCD","Roll On Parry CD",false,"Automatically roll when ur parry is on cooldown.")
	CombatGroupBox:newToggle("RollOnParryCDDelay", "Roll On Parry CD Delay", false, "Delay the roll fallback on parry cd.")
	CombatGroupBox:newSlider("RollOnParryCDDelaySlider", "Roll On Parry CD Delay (ms)", 50, 0, 500, 0)
	CombatGroupBox:newSlider("ParryChance", "Parry Chance", 100, 0, 100, 0)
	CombatGroupBox:newSlider("RollPercentage", "Roll Instead Of Parry Chance", 1, 0, 100, 0)
	CombatGroupBox:newToggle("ParryOnDodge", "Parry on Dodge", false, "Parry while dodging.")
	CombatGroupBox:newToggle("ParryOnly","Parry Only",false,"Parry unparriable attacks, only use this if you have ignition deepdelver.")
	CombatGroupBox:newToggle("ParryVent", "Parry Vent", false, "Parry Vents automatically.")
	CombatGroupBox:newToggle("DodgeVent", "Dodge Vent", false, "Dodge Vents instead of parrying.")
	CombatGroupBox:newToggle("BlockInput", "Block Input (beta)", false, "makes m1 hold not mess up ap.")
	CombatGroupBox:newSlider("BlockInputDelay", "Block Input Delay (ms) [AP V2]", 150, 0, 500, 0)
	CombatGroupBox:newToggle("M1Hold", "M1 Hold", false, "Automatically m1 when you are holding left click.")
	CombatGroupBox:newToggle("BlockInputOnUnfocused", "Block AP if Unfocused", false, "Block AP Input if the Roblox Window is not focused / active.")
	CombatGroupBox:newToggle("BlockInputOnF", "Block AP on F Hold", false, "Block AP Input while holding F.")
	CombatGroupBox:newToggle("ReactFeint", "React Feint", false, "React to feint on Auto Parry.")
	CombatGroupBox:newToggle("AutoFeint", "Auto Feint", false, "Automatically feint while trying to parry.")
	CombatGroupBox:newToggle("AutoFeintMantra", "Auto Feint Mantra", false, "Automatically feint mantra.")
	CombatGroupBox:newToggle("HitsCancelAP", "Hits Cancel AP", false, "Cancel AP when hit effects are detected on people.")
	CombatGroupBox:newToggle("BlockAPIfHoldingF", "Block AP If Holding F", false, "Block AP if you are holding F.")
	CombatGroupBox:newToggle("BlockAPIfUnfocused", "Block AP If Unfocused", false, "Block AP if you are unfocused.")
	CombatGroupBox:newToggle("BlatantRoll", "Blatant Roll", false, "Bypass checks and roll whenever possible.")
	CombatGroupBox:newToggle("RollCancel", "Roll Cancel", false, "Automatically roll cancel.")
	CombatGroupBox:newSlider("RollCancelDelay", "Roll Cancel Delay", 1, 50, 300, 0)
	CombatGroupBox:newToggle("RollOnFeint", "Roll on Feint", false, "Automatically roll on feint.")
	CombatGroupBox:newSlider("RollOnFeintDelay", "Roll on Feint Delay", 0.1, 0, 0.3, 1)
	CombatGroupBox:newToggle("FacingTarget", "Check if facing target", false, "Checks if you are facing the target.")
	CombatGroupBox:newToggle("TargetFaceYou","Check if target facing you",false,"Checks if the target is facing you.")
	CombatGroupBox:newDropdown("AutoParryTarget","Auto Parry Target",{ "Players", "Mobs", "All" },"All",false,"Auto Parry target filter.")
	CombatGroupBox:newDropdown("AutoParryWhitelist","Auto Parry Whitelist",{},"All",true,"Auto Parry Whitelist. (make ap not work for the ppl included)")
	CombatGroupBox:newToggle("AutoParryIgnoreFriends", "Auto Parry Ignore Friends", false, "Don't auto-parry people in your friends list.")
	CombatGroupBox:newToggle("ParryNotifs", "Parry Notifications", false, "Notify when Auto Parry is acting.")
	CombatGroupBox:newToggle("BlockInputNotifs", "Block Input Notifications", false, "Block Input Notifications.")

	local PVPAddons = AutoParryTab:newGroupBox("PVP Addons", true)
	PVPAddons:newToggle("ChimeSafety", "Chime Safety", false, "Automatically disable all movement exploits on chime.")
	PVPAddons:newToggle("DashCasting", "Dash Casting", false, "Dash after using a mantra for speedboost.")
	PVPAddons:newSlider("DashCasting_CD", "Dash Cast Cooldown (second)", 0.2, 0, 3, 1)
	PVPAddons:newToggle("RunningDashCasting", "Dash Cast Running Attacks", false, "Dash after doing a running attack.")
	PVPAddons:newToggle("UppercutDashCasting", "Dash Cast Uppercuts", false, "Dash after doing an uppercut.")
	PVPAddons:newToggle("DashCastCustom", "Dash Cast Filter", false, "Only Dash Cast on certain mantra.")
	PVPAddons:newToggle("OnlyDashForward", "Only Dashcast Forward", false, "Only Dash Cast forward.")
	PVPAddons:newToggle("PriorityDodgeFrame", "Priority Dodge Frame", false, "Remove block frame when attempting to dodge")
	PVPAddons:newToggle("NoRollFatigue", "No Roll Fatigue", false, "Remove 2x Roll Cancel Fatigue.")
	PVPAddons:newToggle("ExtendRollCancel", "Extend Roll Cancel", false, "Extend roll cancel distance.")
	PVPAddons:newToggle("M1RollCancel", "Roll Cancel M1", false, "Automatically Roll Cancel if you M1 mid roll.")
	PVPAddons:newToggle("AutoRollCancel", "Auto Roll Cancel", false, "Automatically Roll Cancel when you roll.")
	PVPAddons:newToggle("FastSwing", "Fast Swing", false, "Removes client endlag from m1.")
	PVPAddons:newToggle("FeintFlourish", "Feint Flourish", false, "Allow you to Feint Flourish / last of m1.")
	PVPAddons:newToggle("JetRunAttack","Momentum Spoof",false,"Gives maximum momentum when you run.")
	PVPAddons:newToggle("RunAttack","Spam Running Attack",false,"very cool feature.")

	if IsPaidUser then
		local AnimationAPLoggerBox = AutoParryTab:newGroupBox("Animation AP Logger", true)
		AnimationAPLoggerBox:newDropdown("LoggedAnimations","Logged Animations",{},"",false,"List of the Logged Animations."	)
		AnimationAPLoggerBox:newToggle("LogAnimations", "Log Animations", false, "Log Played Animations.")
		AnimationAPLoggerBox:newToggle("LogPlayerAnimations", "Log Self Animations", false, "Log Played Animations by you.")
		AnimationAPLoggerBox:newToggle("ParrySelfAnimations","Parry Self Animations",false,"Parry Played Animations by player."	)
		AnimationAPLoggerBox:newToggle("AutoParryDebug","Auto Parry Debug",false,"Only show when hitboxes are being played, parryselfanim needed.")
		AnimationAPLoggerBox:newSlider("LogAnimations_Range", "Log Animation Range", 100, 0, 2000, 0)
	
		local CommunityAPBox = AutoParryTab:newGroupBox("Community Config Editor", true)
		CommunityAPBox:newDropdown("CommunityConfig_List", "Config List", {}, "", false, "List of Community Configs.")
		CommunityAPBox:newTextbox("CommunityConfig_Range", "Range", true, 20, false, "MaxRange of the config.", "20")
		CommunityAPBox:newTextbox("CommunityConfig_Delay","Delay (ms)",true,150,false,"The Delay before it parries (in ms).","150"	)
		CommunityAPBox:newTextbox("CommunityConfig_ParryAmount","Repeat Parry Amount",true,1,false,"The Amount of Parry it will do after the first parry.","1"	)
		CommunityAPBox:newTextbox("CommunityConfig_ParryDelay","Repeat Parry Delay (ms)",true,0,false,"The Amount of Parry it will do after delay.","150"	)
		CommunityAPBox:newTextbox("CommunityConfig_AnimationId","Animation ID",true,0,false,"The AnimationID of the attack.","1234567890"	)
		CommunityAPBox:newTextbox("CommunityConfig_Name","Config Nickname",false,1,false,"The nickname of the config.","Swing1"	)
		CommunityAPBox:newToggle("CommunityConfig_Roll", "Roll instead of parry", false, "Roll instead of parrying.")
		CommunityAPBox:newToggle("CommunityConfig_RepeatUntilAnimationEnd", "Repeat Until Animation End",false,"Repeat parries until the animation ends.")
		CommunityAPBox:newToggle("CommunityConfig_Delay","Delay until close distance",false,"Roll instead of parrying."	)
		CommunityAPBox:newSlider("CommunityConfig_DelayDistance", "Delay Distance", 0, 0, 300, 0)
		CommunityAPBox:newButton("Clear Anim Logs",AutoParryBuilder.ClearAnimLogs,false,"Clear the Logged Animations"	)
		CommunityAPBox:newButton("Copy AnimationId", AutoParryBuilder.CopyAnim, false, "Copy the Selected AnimationId")
		CommunityAPBox:newButton("Export Config",AutoParryBuilder.CreateConfig,false,"Export the current config into Lycoris/Deepwoken/Configs"	)
		CommunityAPBox:newButton("Refresh Config",AutoParryBuilder.RefreshConfig,false,"Refreshes community configs."	)
		CommunityAPBox:newButton("Unload Config",AutoParryBuilder.UnloadConfig,false, "Unload selected community configs."	)
		if not script_key then
			CommunityAPBox:newButton("Decode Config", AutoParryBuilder.DecodeConfig, false, "Decode selected community configs." )
			CommunityAPBox:newButton("Compile All Configs", AutoParryBuilder.CompileConfigs, false, "compile every configs loaded into one. [THIS DECODES THEM, DON'T SHARE OUTSIDE OF TESTER]" )
		end
		if isRealTester then
			CommunityAPBox:newButton("Compile All Configs (ENC)", AutoParryBuilder.CompileConfigsEncrypted, false, "Encrypted compiled configs, shareable." )
		end
		
		local HitboxVisualizer = AutoParryTab:newGroupBox("Hitbox Visualizer", true)
		HitboxVisualizer:newToggle("UsePresetHitbox", "Use Preset Hitbox", false, "Use Preset Hitbox to customize config hitbox.")
		HitboxVisualizer:newToggle("VisualizeHitbox", "Visualize Hitbox", false, "Show Hitbox to customize config hitbox.")
		HitboxVisualizer:newSlider("Hitbox_Z", "Length", 0, 0, 300, 1)
		HitboxVisualizer:newSlider("Hitbox_X", "Width", 0, 0, 300, 1)
		HitboxVisualizer:newSlider("Hitbox_Y", "Height", 0, 0, 300, 1)
		HitboxVisualizer:newSlider("Hitbox_YSet", "Height Offset", 0, -200, 200, 1)
		HitboxVisualizer:newSlider("Hitbox_ZSet", "Length Offset", 0, -200, 200, 1)
		HitboxVisualizer:newDropdown("HitboxShape", "Hitbox Shape", {"Block", "Ball", "Cylinder"}, "Block", false, "Shape of the Hitbox, lol.")
	
		Options.CommunityConfig_List:OnChanged(AutoParryBuilder.ConfigChanged)
		Options.LoggedAnimations:OnChanged(AutoParryBuilder.LoggedAnimationChanged)
	
		local ProjectileAPLoggerBox = AutoParryTab:newGroupBox("Projectile AP Logger", true)
		ProjectileAPLoggerBox:newDropdown("LoggedProjectiles","Logged Projectiles",{},"",false,"List of the Logged Projectiles."	)
		ProjectileAPLoggerBox:newToggle("LogProjectiles", "Log Projectiles", false, "Log Played Projectiles.")
		ProjectileAPLoggerBox:newSlider("LogProjectiles_Range", "Log Projectile Range", 100, 0, 2000, 0)
	
		local ProjectileAPBox = AutoParryTab:newGroupBox("Projectile Config Editor", true)
		ProjectileAPBox:newDropdown("ProjectileConfig_List", "Config List", {}, "", false, "List of Projectile Configs.")
		ProjectileAPBox:newTextbox("ProjectileConfig_MinRange", "Minimum Range", true, 10, false, "Minimum range of projectile.", "10")
		ProjectileAPBox:newTextbox("ProjectileConfig_MaxRange", "Maximum Range", true, 20, false, "Max range of projectile.", "20")
		ProjectileAPBox:newTextbox("ProjectileConfig_Delay","Delay (ms)",true,150,false,"The Delay before it parries (in ms).","150"	)
		ProjectileAPBox:newTextbox("ProjectileConfig_ParryAmount","Repeat Parry Amount",true,1,false,"The Amount of Parry it will do after the first parry.","1"	)
		ProjectileAPBox:newTextbox("ProjectileConfig_ParryDelay","Repeat Parry Delay (ms)",true,0,false,"The Amount of Parry it will do after delay.","150"	)
		ProjectileAPBox:newTextbox("ProjectileConfig_ProjectileName","Projectile Name",false,1,false,"The Name of the projectile.","Part1"	)
		ProjectileAPBox:newTextbox("ProjectileConfig_Name","Config Nickname",false,1,false,"The nickname of the config.","Lol"	)
		ProjectileAPBox:newToggle("ProjectileConfig_Roll", "Roll instead of parry", false, "Roll instead of parrying.")
		ProjectileAPBox:newButton("Clear Projectile Logs",AutoParryBuilder.ClearProjectileLogs,false,"Clear the Logged Projectiles"	)
		ProjectileAPBox:newButton("Copy Projectile Name", AutoParryBuilder.CopyProjectile, false, "Copy the Selected Projectile Name")
		ProjectileAPBox:newButton("Export Config",AutoParryBuilder.CreateProjectileConfig,false,"Export the current projectile config into Lycoris/Deepwoken/ProjectileConfigs"	)
		ProjectileAPBox:newButton("Refresh Config",AutoParryBuilder.RefreshProjectileConfig,false,"Refreshes projectile configs."	)
		if not script_key then
			ProjectileAPBox:newButton("Decode Config", AutoParryBuilder.DecodeProjectileConfig, false, "Decode selected community configs." )
		end
	
		Options.ProjectileConfig_List:OnChanged(AutoParryBuilder.ProjectileConfigChanged)
		Options.LoggedProjectiles:OnChanged(AutoParryBuilder.LoggedProjectileChanged)
	
		local SoundAPLoggerBox = AutoParryTab:newGroupBox("Sound AP Logger", true)
		SoundAPLoggerBox:newDropdown("LoggedSounds","Logged Sounds",{},"",false,"List of the Logged Sounds."	)
		SoundAPLoggerBox:newToggle("LogSounds", "Log Sounds", false, "Log Played Sounds.")
		SoundAPLoggerBox:newSlider("LogSounds_Range", "Log Sounds Range", 100, 0, 2000, 0)
	
		local SoundAPBox = AutoParryTab:newGroupBox("Sound Config Editor", true)
		SoundAPBox:newDropdown("SoundConfig_List", "Config List", {}, "", false, "List of Sound Configs.")
		SoundAPBox:newTextbox("SoundConfig_Range", "Range", true, 20, false, "MaxRange of the config.", "20")
		SoundAPBox:newTextbox("SoundConfig_Delay","Delay (ms)",true,150,false,"The Delay before it parries (in ms).","150"	)
		SoundAPBox:newTextbox("SoundConfig_ParryAmount","Repeat Parry Amount",true,1,false,"The Amount of Parry it will do after the first parry.","1"	)
		SoundAPBox:newTextbox("SoundConfig_ParryDelay","Repeat Parry Delay (ms)",true,0,false,"The Amount of Parry it will do after delay.","150"	)
		SoundAPBox:newTextbox("SoundConfig_SoundId","Sound Id",false,1,false,"The Id of the sound.","12345678910"	)
		SoundAPBox:newTextbox("SoundConfig_Name","Config Nickname",false,1,false,"The nickname of the config.","Lol"	)
		SoundAPBox:newToggle("SoundConfig_Roll", "Roll instead of parry", false, "Roll instead of parrying.")
		SoundAPBox:newToggle("SoundConfig_Delay","Delay until close distance",false,"Roll instead of parrying."	)
		SoundAPBox:newSlider("SoundConfig_DelayDistance", "Delay Distance", 0, 0, 300, 0)
		SoundAPBox:newButton("Clear Sound Logs",AutoParryBuilder.ClearSoundLogs,false,"Clear the Logged Sounds"	)
		SoundAPBox:newButton("Copy Sound Id", AutoParryBuilder.CopySound, false, "Copy the Selected Sound Id")
		SoundAPBox:newButton("Export Config",AutoParryBuilder.CreateSoundConfig,false,"Export the current sound config into Lycoris/Deepwoken/SoundConfigs"	)
		SoundAPBox:newButton("Refresh Config",AutoParryBuilder.RefreshSoundConfig,false,"Refreshes sound configs."	)
		if not script_key then
			SoundAPBox:newButton("Decode Config", AutoParryBuilder.DecodeSoundConfig, false, "Decode selected community configs." )
		end
	
		Options.SoundConfig_List:OnChanged(AutoParryBuilder.SoundConfigChanged)
		Options.LoggedSounds:OnChanged(AutoParryBuilder.LoggedSoundChanged)
	
		local CustomAPBox = AutoParryTab:newGroupBox("Internal Config Editor", false)
		CustomAPBox:newDropdown("Config_List", "Custom AP Configs", {}, "", false, "List of AutoParry Configs.")
		CustomAPBox:newToggle("Config_Roll", "Roll instead of parry", false, "Roll instead of parrying.")
		CustomAPBox:newSlider("Config_Range", "Range", 0, 0, 1500, 0)
		CustomAPBox:newTextbox("Config_Delay", "Delay", true, 1, false, "The Delay before it parries (in ms).", "150")
		CustomAPBox:newTextbox( "Config_ParryAmount", "Repeat Parry Amount", true, 1, false, "The Amount of Parry it will do after the first parry.", "1"	)
		CustomAPBox:newTextbox( "Config_ParryDelay", "Repeat Parry Delay", true, 0, false, "The Delay of each Parry after the first parry.", "0.1"	)
		CustomAPBox:newTextbox( "Config_Name", "Config Nickname", false, 1, false, "The nickname of the config.", "MediumSwing_1"	)
		CustomAPBox:newToggle("Config_Delay", "Delay until close distance", false, "Roll instead of parrying.")
		CustomAPBox:newSlider("Config_DelayDistance", "Distance", 0, 0, 300, 0)
		CustomAPBox:newButton("Save Config", AutoParryBuilder.SaveConfigInternal, false, "Export the modified configs into Lycoris/Deepwoken/Configs"	)
		Options.Config_List:OnChanged(AutoParryBuilder.ConfigListChanged)
	
		local M1ConfigBox = AutoParryTab:newGroupBox("Internal M1 Configs", true)	
		M1ConfigBox:newDropdown("M1Config_List", "Config List", {}, "", false, "List of M1 Configs.")
		M1ConfigBox:newTextbox("M1Config_Delay", "Delay", true, 1, false, "The Delay before it parries (in ms).", "150")
		M1ConfigBox:newButton("Save Config", AutoParryBuilder.SaveM1Config, false, "Export the modified configs into Lycoris/Deepwoken/M1Configs"	)
		Options.M1Config_List:OnChanged(AutoParryBuilder.M1ConfigListChanged)
	end

	EspGroupBox:newToggle("ESPEnabled", "ESP Enabled", false, "Enable / Disable ESP")
	EspGroupBox:newToggle("CustomESP", "Custom ESP", false, "A Lua version of ESP, recommended for Chime.")
	EspGroupBox:newKeybind("ESPKeybind", "ESP Keybind", "N/A", "ESPEnabled")
	EspGroupBox:newDropdown("ESPFont", "ESP Fonts", Configs.Fonts, "Code", false, "List of ESP Fonts.")
	EspGroupBox:newButton("Refresh ESP", function()
		print('refreshing esp')
		SecureCall(getgenv().Maid.ESP)
		task.wait(3)
		print('starting esp')
		SecureCall(getgenv().StartESP)
	end, false, "Refresh ESP (use this when game gets too laggy)")
	EspGroupBox:newToggle("AutoRefreshESP", "Auto Refresh ESP", false, "Automatically Refresh ESP")
	EspGroupBox:newSlider("AutoRefreshESP", "Refresh Delay", 60, 20, 120, 0, true)
	EspGroupBox:newToggle("FastESP", "Fast ESP", false, "Make the esp appear faster. (might cause fps issues)")
	EspGroupBox:newSlider("EspTextSize", "Text Size", 10, 1, 20, 0, true)
	EspGroupBox:newSlider("EspTracerSize", "Tracer Size", 2, 1, 5, 0, true)
	EspGroupBox:newSlider("EspTracerOffset", "Tracer Y Offset", 2, -5, 5, 0, true)

	if not script_key then
		local To1Groupbox = AutoFarmTab:newGroupBox("Trial of One",true)
		To1Groupbox:newToggle("AutoTo1", "Auto Trial of One", false, "Automatically do Trial of One [Lone Warrior origin required]")
		To1Groupbox:newToggle("AutoStats", "Auto Input Stats", false, "Automatically input the required stat for the build")
		To1Groupbox:newToggle("AutoTalents", "Auto Get Talents", false, "Automatically take the required talents for the build")
		To1Groupbox:newLabel("Attribute Stats")
		To1Groupbox:newTextbox("Stat_Strength","Max Strength",true,0,false,"Amount of Strength to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Fortitude","Max Fortitude",true,0,false,"Amount of Fortitude to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Agility","Max Agility",true,0,false,"Amount of Agility to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Willpower","Max Willpower",true,0,false,"Amount of Willpower to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Intelligence","Max Intelligence",true,0,false,"Amount of Intelligence to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Charisma","Max Charisma",true,0,false,"Amount of Charisma to reach before stopping.","0")
		To1Groupbox:newLabel("Weapon Stats")
		To1Groupbox:newTextbox("Stat_LightWeapon","Max Light Weapon",true,0,false,"Amount of Light Point to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_MediumWeapon","Max Medium Weapon",true,0,false,"Amount of Medium Point to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_HeavyWeapon","Max Heavy Weapon",true,0,false,"Amount of Heavy Point to reach before stopping.","0")
		To1Groupbox:newLabel("Attunement Stats")
		To1Groupbox:newTextbox("Stat_Flamecharm","Max Flamecharm",true,0,false,"Amount of Flamecharm Point to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Frostdraw","Max Frostdraw",true,0,false,"Amount of Frostdraw Point to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Galebreathe","Max Galebreathe",true,0,false,"Amount of Galebreathe Point to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Thundercall","Max Thundercall",true,0,false,"Amount of Thundercall Point to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Shadowcast","Max Shadowcast",true,0,false,"Amount of Shadowcast Point to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Ironsing","Max Ironsing",true,0,false,"Amount of Ironsing Point to reach before stopping.","0")
		To1Groupbox:newLabel("Trait Stats")
		To1Groupbox:newTextbox("Stat_Vitality","Max Vitality",true,0,false,"Amount of Vitality to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Erudition","Max Erudition",true,0,false,"Amount of Erudition to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Songchant","Max Songchant",true,0,false,"Amount of Songchant to reach before stopping.","0")
		To1Groupbox:newTextbox("Stat_Proficiency","Max Proficiency",true,0,false,"Amount of Proficiency to reach before stopping.","0")
		To1Groupbox:newLabel("Priority Talents")
		To1Groupbox:newToggle("PriorityLegendary", "Prioritize Legendary Talents", false, "Take legendary talents first over other")
		To1Groupbox:newToggle("PriorityHealth", "Prioritize HP Talents", false, "Take HP talents first over other")
		To1Groupbox:newDropdown("PriorityTalents", "Priority Talents", Configs.TalentData, "", true, "List of Talents to prioritize over.")
	end

	local AstralGroupbox = AutoFarmTab:newGroupBox("Astral AutoFarm")
	AstralGroupbox:newToggle("AutoAstral", "Auto Astral Farm", false, "Food / Carnivore required, must be in voidsea before activating")
	AstralGroupbox:newSlider("AstralSpeed", "Astral Speed", 100, 5, 190, 0, true)
	AstralGroupbox:newToggle("AstralCarnivore", "Use Carnivore", false, "Kill nearby mobs when hungry instead of eating food")
	AstralGroupbox:newSlider("AstralHungerLevel", "Hunger Level", 33, 0, 100, 0, true)
	AstralGroupbox:newSlider("AstralWaterLevel", "Water Level", 33, 0, 100, 0, true)
	AstralGroupbox:newToggle("AstralWhirlpool", "ServerHop near Whirlpool", false, "Automatically server hop when a whirlpool is nearby")
	AstralGroupbox:newToggle("NotifyAstral", "Notify on Astral spawn", false, "Automatically send a notification when astral spawned")
	AstralGroupbox:newToggle("NotifyVoidEvents", "Notify Voidsea Event", false, "Automatically send a notification when VOIDSEA event spawned")
	AstralGroupbox:newTextbox("AstralWebhook","Discord Webhook",false,"",false,"Send a notification specified webhook.","https://discord.com/api/webhooks/xxxx")

	-- Universal
	AddGenericESP("Player", true)
	AddGenericESP("Mob", true)
	AddGenericESP("NPC")
	AddGenericESP("Chest")
	AddCustomESP("Area", ReplicatedStorage:WaitForChild("MarkerWorkspace"):WaitForChild("AreaMarkers"), function(v)
		return (not v.Name:match("'s Base") and v:FindFirstChild("AreaMarker"))
	end)

	-- Overworld
	AddGenericESP("JobBoard")
	AddGenericESP("Artifact")
	AddGenericESP("Whirlpool")
	AddGenericESP("Explosive")
	AddGenericESP("Owl")
	AddGenericESP("Door")
	AddGenericESP("Banner")

	-- Layer 2
	AddGenericESP("Obelisk")
	AddCustomESP("Ingredient", ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Ingredients"), function(v)
		return (v.Name:match("Galewax") and v)
	end)

	-- Battle Royale
	if IsPaidUser then
		AddGenericESP("Armor_Brick")
		AddGenericESP("Bell_Meteor")
		AddGenericESP("Rare_Obelisk")
		AddGenericESP("Heal_Brick")
		AddGenericESP("Mantra_Obelisk")
		AddGenericESP("BR_Weapon")
	end

	-- god forsaken you
	-- whart
	-- BoobwokenGroupBox:newLabel("BLASTBREAN ADDED THIS NOT SOU")
	-- BoobwokenGroupBox:newToggle("EntityNSFW","NSFW on Entities",false,"NPCS and Players have Boobs, Ass, and Crotch.")
	-- BoobwokenGroupBox:newToggle("SizeEntityAuto", "Automatic Entity Sizing", false, "Apply NSFW size based on factors.")
	-- BoobwokenGroupBox:newToggle("UseEntityGender", "Use Entity Gender", false, "Apply NSFW rig based on gender.")
	-- BoobwokenGroupBox:newToggle("ShowEntityBoobs", "Show Boobs", false, "Show Boobs on Entities.")
	-- BoobwokenGroupBox:newSlider("BoobsSize", "Boobs Size", 1.0, 0.0, 1.0, 2, true)
	-- BoobwokenGroupBox:newToggle("ShowEntityAss", "Show Ass", false, "Show Ass on Entities.")
	-- BoobwokenGroupBox:newSlider("AssSize", "Ass Size", 1.0, 0.0, 1.0, 2, true)
	-- BoobwokenGroupBox:newToggle("ShowEntityCrotch", "Show Crotch", false, "Show Crotch on Entities.")
	-- BoobwokenGroupBox:newSlider("CrotchSize", "Crotch Size", 1.0, 0.0, 1.0, 2, true)

	local MovementKeybinds = KeybindsTab:newGroupBox("Keybinds")
	MovementKeybinds:newKeybind("FlyKeybind", "Fly", "N/A", "Fly")
	MovementKeybinds:newKeybind("SpeedhackKeybind", "Speedhack", "N/A", "Speedhack")
	MovementKeybinds:newKeybind("TpToGroundKey", "TP To Ground", "N/A", "TpToGround")
	MovementKeybinds:newKeybind("NoclipKeybind", "No Clip", "N/A", "NoClip")
	MovementKeybinds:newKeybind("InfJumpKeybind", "Inf Jump", "N/A", "InfJump")
	MovementKeybinds:newKeybind("KnockedOwnershipKeybind", "Knocked Ownership", "N/A", "KnockedOwnership")
	MovementKeybinds:newKeybind("TweenToObjectiveKeybind", "Tween To Objective", "N/A", "TweenToObjective")
	MovementKeybinds:newKeybind("PVPModeKeybind", "PVP Mode", "N/A", "PVPMode")
	MovementKeybinds:newKeybind("AutoParryKeybind", "Auto Parry", "N/A", "AutoParry")
	MovementKeybinds:newKeybind("AutoParryV2Keybind", "Auto Parry V2", "N/A", "AutoParryV2")
	MovementKeybinds:newKeybind("JetRunAtk", "Jetstriker Momentum", "N/A", "JetRunAttack")
	MovementKeybinds:newKeybind("VMKey", "Void Mobs", "N/A", "VoidMobs")
	MovementKeybinds:newKeybind("AIBreakerKey", "Pathfind Breaker", "N/A", "AIBreaker")
	AutoFarmGroupBox:newKeybind("ATBKey", "Attach To Back", "N/A", "AttachToBack")

	local MenuGroup = UISettings.Tab:AddLeftGroupbox("Menu")
	MenuGroup:AddButton("Unload", function()
		warn("Unloading UI")

		for i, v in pairs(Toggles) do
			if not Interface.ClientFeature[i] or not v.Value then
				continue
			end
	
			v:SetValue(false)

			task.wait()

			Interface.ClientFeature[i]()
		end

		getgenv().Maid:DoCleaning()
		LycorisConnect:DoCleaning()

		if isfunctionhooked and restorefunction then
			if isfunctionhooked(getrawmetatable(game).__newindex) then
				restorefunction(getrawmetatable(game).__newindex)
			end
			if isfunctionhooked(getrawmetatable(game).__namecall) then
				restorefunction(getrawmetatable(game).__namecall)
			end
			if isfunctionhooked(Instance.new("RemoteEvent").FireServer) then
				restorefunction(Instance.new("RemoteEvent").FireServer)
			end
			if isfunctionhooked(Instance.new("UnreliableRemoteEvent").FireServer) then
				restorefunction(Instance.new("UnreliableRemoteEvent").FireServer)
			end
			if isfunctionhooked(game.Destroy) then
				restorefunction(game.Destroy)
			end
		else
			hookfunction(getrawmetatable(game).__newindex, OldNewIndex)
			hookfunction(Instance.new("RemoteEvent").FireServer, OldFireServer)
			hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, OldUnreliFireServer)
			hookfunction(getrawmetatable(game).__namecall, OldNameCall)
			hookfunction(game.Destroy, oldDestroy)
		end

		getgenv().SouLoaded = nil
		getgenv().ExecutedLycoris = false
		Library.Unloaded = true

		warn("Unloaded")
		Library:Unload()
	end)

	MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "LeftAlt", NoUI = true, Text = "Menu keybind" })
	Library.ToggleKeybind = Options.MenuKeybind
	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)

	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({})
	ThemeManager:SetFolder("Lycoris")
	SaveManager:SetFolder("Lycoris/Deepwoken")
	SaveManager:BuildConfigSection(UISettings.Tab)
	ThemeManager:ApplyToTab(UISettings.Tab)
	SaveManager:LoadAutoloadConfig()

	print("Loaded Lycoris 1.0")

	getgenv().SouLoaded = true

	if not LocalPlayer.Character or (LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("CharacterHandler")) then
		repeat
			task.wait(1)
			if MemStoreService:HasItem("AutoMaestroStart") or MemStoreService:HasItem("WipeCharacterStart") then
				ReplicatedStorage.Requests.StartMenu.Start:FireServer()
				print("attempting to start menu")
			end
		until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("CharacterHandler")

		task.wait(3)
	end

	if (MemStoreService:HasItem("AutoWipe") or MemStoreService:HasItem("AutoEcho")) and LocalPlayer.PlayerGui:FindFirstChild("CharacterCreator") then
		local EchoRemote = ReplicatedStorage.Requests.MetaModifier
		local Modifiers = getgenv().require(ReplicatedStorage.Info.MetaData).Modifiers

		for i,v in pairs(Modifiers) do
			EchoRemote:FireServer(i)
			task.wait(.5)
		end

		repeat
			ReplicatedStorage:WaitForChild("Requests"):WaitForChild("CharacterCreator"):WaitForChild("FinishCreation"):InvokeServer()
			task.wait(0.5)
		until not LocalPlayer.PlayerGui:FindFirstChild("CharacterCreator")
	end

	require("Features/ESP")

	if MemStoreService:HasItem("WipeCharacter") then
		Wipe.WipeCharacter()
	end

	if MemStoreService:HasItem("AutoWipe") and not MemStoreService:HasItem("WipeCharacter") then
		Wipe.WipeCharacter()
	end

	if MemStoreService:HasItem("AutoEcho") then
		Wipe.EchoFarm()
	end

	require("Features/AutoParry")
	require("Features/AutoParryRewritten")
	require("Features/AutoParryRewrittenProjectile")
	require("Features/AutoParryRewrittenSound")
	require("Features/ExperimentalAP")
	require("Features/Freecam")
	require("Modules/Utilities").Analytics(LRM_LinkedDiscordID)
end)
