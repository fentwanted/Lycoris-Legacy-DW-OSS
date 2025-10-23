-- Bundled by luabundle {"luaVersion":"5.1","version":"1.6.0"}
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
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

end)
__bundle_register("Modules/Utilities", function(require, _LOADED, __bundle_register, __bundle_modules)
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

end)
__bundle_register("Signal", function(require, _LOADED, __bundle_register, __bundle_modules)
return (function()
	local freeRunnerThread = nil

local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread()
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
	return setmetatable({
		_connected = true,
		_signal = signal,
		_fn = fn,
		_next = false,
	}, Connection)
end

function Connection:Disconnect()
	self._connected = false
	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

setmetatable(Connection, {
	__index = function(tb, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(tb, key, value)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end
})

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_handlerListHead = false,
	}, Signal)
end

function Signal:Connect(fn)
	local connection = Connection.new(self, fn)
	if self._handlerListHead then
		connection._next = self._handlerListHead
		self._handlerListHead = connection
	else
		self._handlerListHead = connection
	end
	return connection
end

function Signal:DisconnectAll()
	self._handlerListHead = false
end

function Signal:Fire(...)
	local item = self._handlerListHead
	while item do
		if item._connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
				coroutine.resume(freeRunnerThread)
			end
			task.spawn(freeRunnerThread, item._fn, ...)
		end
		item = item._next
	end
end

function Signal:Wait()
	local waitingCoroutine = coroutine.running()
	local cn;
	cn = self:Connect(function(...)
		cn:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end

function Signal:Once(fn)
	local cn;
	cn = self:Connect(function(...)
		if cn._connected then
			cn:Disconnect()
		end
		fn(...)
	end)
	return cn
end

setmetatable(Signal, {
	__index = function(tb, key)
		error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(tb, key, value)
		error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end
})

return Signal
end)()
end)
__bundle_register("Features/Freecam", function(require, _LOADED, __bundle_register, __bundle_modules)
local speed = 0
local player = game:GetService("Players")
while not player.LocalPlayer do player.Changed:wait() end
player = player.LocalPlayer
local camera = workspace.CurrentCamera

local RS  = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local Spring = loadstring(game:HttpGet('https://raw.githubusercontent.com/Roblox/Core-Scripts/refs/heads/master/CoreScriptsRoot/Modules/Server/FreeCamera/Spring.lua'))()
local Maid = loadstring(game:HttpGet('https://raw.githubusercontent.com/Roblox/Core-Scripts/refs/heads/master/CoreScriptsRoot/Modules/Server/FreeCamera/Maid.lua'))()

local WasGuiVisible = {}
function ToggleGui(on)
	if not on then
		WasGuiVisible["PointsNotificationsActive"] = StarterGui:GetCore("PointsNotificationsActive")
		WasGuiVisible["BadgesNotificationsActive"] = StarterGui:GetCore("BadgesNotificationsActive")
		WasGuiVisible["Health"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health)
		WasGuiVisible["Backpack"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
		WasGuiVisible["PlayerList"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
		WasGuiVisible["Chat"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
	end

	local function GuiOn(name)
		if on == false then
			return false
		end
		if WasGuiVisible[name] ~= nil then
			return WasGuiVisible[name]
		end
		return true
	end

	StarterGui:SetCore("PointsNotificationsActive", GuiOn("PointsNotificationsActive"))
	StarterGui:SetCore("BadgesNotificationsActive", GuiOn("BadgesNotificationsActive"))

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, GuiOn("Health"))
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, GuiOn("Backpack"))
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, GuiOn("PlayerList"))
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, GuiOn("Chat"))
end

------------------------------------------------

local DEF_FOV = 70
local NM_ZOOM = math.tan(DEF_FOV * math.pi/360)
local LVEL_GAIN = Vector3.new(1, 0.75, 1)
local RVEL_GAIN = Vector2.new(0.85, 1)/128
local FVEL_GAIN = -330
local DEADZONE = 0.125
local FOCUS_OFFSET = CFrame.new(0, 0, -16)

local DIRECTION_LEFT = 1
local DIRECTION_RIGHT = 2
local DIRECTION_FORWARD = 3
local DIRECTION_BACKWARD = 4
local DIRECTION_UP = 5
local DIRECTION_DOWN = 6

local KEY_MAPPINGS = {
	[DIRECTION_LEFT] = {Enum.KeyCode.A, Enum.KeyCode.H},
	[DIRECTION_RIGHT] = {Enum.KeyCode.D, Enum.KeyCode.K},
	[DIRECTION_FORWARD] = {Enum.KeyCode.W, Enum.KeyCode.U},
	[DIRECTION_BACKWARD] = {Enum.KeyCode.S, Enum.KeyCode.J},
	[DIRECTION_UP] = {Enum.KeyCode.E, Enum.KeyCode.I},
	[DIRECTION_DOWN] = {Enum.KeyCode.Q, Enum.KeyCode.Y},
}

------------------------------------------------

local screenGuis = {}
local freeCamEnabled = false
local letterBoxEnabled = true

local stateRot = Vector2.new()
local panDeltaGamepad = Vector2.new()
local panDeltaMouse = Vector2.new()

local velSpring = Spring.new(7/9, 1/3, 1, Vector3.new())
local rotSpring = Spring.new(7/9, 1/3, 1, Vector2.new())
local fovSpring = Spring.new(2,   1/3, 1, 0)

local gp_x  = 0
local gp_z  = 0
local gp_l1 = 0
local gp_r1 = 0
local rate_fov = 0

local SpeedModifier = 1

------------------------------------------------

local function Clamp(x, min, max)
	return x < min and min or x > max and max or x
end

local function GetChar()
	local character = player.Character
	if character then
		return character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("Torso")
	end
end

local function InputCurve(x)
	local s = math.abs(x)
	if s > DEADZONE then
		s = 0.255000975*(2^(2.299113817*s) - 1)
		return x > 0 and (s > 1 and 1 or s) or (s > 1 and -1 or -s)
	end
	return 0
end

------------------------------------------------

local function ProcessInput(input, processed)
	local userInputType = input.UserInputType
	if userInputType == Enum.UserInputType.Gamepad1 then
		local keycode = input.KeyCode
		if keycode == Enum.KeyCode.Thumbstick2 then
			local pos = input.Position
			panDeltaGamepad = Vector2.new(InputCurve(pos.y), InputCurve(-pos.x))*7
		elseif keycode == Enum.KeyCode.Thumbstick1 then
			local pos = input.Position
			gp_x = InputCurve(pos.x)
			gp_z = InputCurve(-pos.y)
		elseif keycode == Enum.KeyCode.ButtonL2 then
			gp_l1 = input.Position.z
		elseif keycode == Enum.KeyCode.ButtonR2 then
			gp_r1 = input.Position.z
		end
	elseif userInputType == Enum.UserInputType.MouseWheel then
		rate_fov = input.Position.Z
	end
end

UIS.InputChanged:Connect(ProcessInput)
UIS.InputEnded:Connect(ProcessInput)
UIS.InputBegan:Connect(ProcessInput)

------------------------------------------------

local function IsDirectionDown(direction)
	for i = 1, #KEY_MAPPINGS[direction] do
		if UIS:IsKeyDown(KEY_MAPPINGS[direction][i]) then
			return true
		end
	end
	return false
end

local UpdateFreecam do
	local dt = 1/60
	RS.RenderStepped:Connect(function(_dt)
		dt = _dt
	end)

	function UpdateFreecam()
		local camCFrame = camera.CFrame

		local kx = (IsDirectionDown(DIRECTION_RIGHT) and 1 or 0) - (IsDirectionDown(DIRECTION_LEFT) and 1 or 0)
		local ky = (IsDirectionDown(DIRECTION_UP) and 1 or 0) - (IsDirectionDown(DIRECTION_DOWN) and 1 or 0)
		local kz = (IsDirectionDown(DIRECTION_BACKWARD) and 1 or 0) - (IsDirectionDown(DIRECTION_FORWARD) and 1 or 0)
		local km = (kx * kx) + (ky * ky) + (kz * kz)
		if km > 1e-15 then
			km = ((UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) and 1/1.5 or 1)/math.sqrt(km)
			kx = kx * km
			ky = ky * km
			kz = kz * km
		end

		local dx = kx + gp_x
		local dy = ky + gp_r1 - gp_l1
		local dz = kz + gp_z

		velSpring.t = Vector3.new(dx, dy, dz) * SpeedModifier
		rotSpring.t = panDeltaMouse + panDeltaGamepad
		fovSpring.t = Clamp(fovSpring.t + dt * rate_fov*FVEL_GAIN, 5, 120)

		local fov  = fovSpring:Update(dt)
		local dPos = velSpring:Update(dt) * LVEL_GAIN
		local dRot = rotSpring:Update(dt) * (RVEL_GAIN * math.tan(fov * math.pi/360) * NM_ZOOM)

		rate_fov = 0
		panDeltaMouse = Vector2.new()

		stateRot = stateRot + dRot
		stateRot = Vector2.new(Clamp(stateRot.x, -3/2, 3/2), stateRot.y)

		local c = CFrame.new(camCFrame.p) * CFrame.Angles(0, stateRot.y, 0) * CFrame.Angles(stateRot.x, 0, 0) * CFrame.new(dPos)

		camera.CFrame = c
		camera.Focus = c*FOCUS_OFFSET
		camera.FieldOfView = fov

        task.spawn(function()
            player:RequestStreamAroundAsync(camera.CFrame.p, 10)
        end)
	end
end

------------------------------------------------

local function Panned(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Delta
		panDeltaMouse = Vector2.new(-delta.y, -delta.x)
	end
end

------------------------------------------------

local function EnterFreecam()
    player:AddTag('FreezeCamera')
    player:AddTag('FreecamEnabled')
	ToggleGui(false)
	UIS.MouseIconEnabled = false
	Maid:Mark(UIS.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			local conn = UIS.InputChanged:Connect(Panned)
			repeat
				input = UIS.InputEnded:wait()
			until input.UserInputType == Enum.UserInputType.MouseButton2 or not freeCamEnabled
			panDeltaMouse = Vector2.new()
			panDeltaGamepad = Vector2.new()
			conn:Disconnect()
			if freeCamEnabled then
				UIS.MouseBehavior = Enum.MouseBehavior.Default
			end
		elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			SpeedModifier = 10
		end
	end))

	Maid:Mark(UIS.InputEnded:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			SpeedModifier = 1
		end
	end))

	camera.CameraType = Enum.CameraType.Scriptable

	local hum, hrp = GetChar()
	if hrp then
		hrp.Anchored = true
	end
	if hum then
		hum.WalkSpeed = 0
		Maid:Mark(hum.Jumping:Connect(function(active)
			if active then
				hum.Jumping = false
			end
		end))
	end

	velSpring.t, velSpring.v, velSpring.x = Vector3.new(), Vector3.new(), Vector3.new()
	rotSpring.t, rotSpring.v, rotSpring.x = Vector2.new(), Vector2.new(), Vector2.new()
	fovSpring.t, fovSpring.v, fovSpring.x = camera.FieldOfView, 0, camera.FieldOfView

	local camCFrame = camera.CFrame
	local lookVector = camCFrame.lookVector.unit

	stateRot = Vector2.new(
		math.asin(lookVector.y),
		math.atan2(-lookVector.z, lookVector.x) - math.pi/2
	)
	panDeltaMouse = Vector2.new()

	local playerGui = player:WaitForChild("PlayerGui")
	for _, obj in next, playerGui:GetChildren() do
		if obj:IsA("ScreenGui") and obj.Enabled then
			obj.Enabled = false
			screenGuis[obj] = true
		end
	end
	RS:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, UpdateFreecam)
	freeCamEnabled = true
end

local function ExitFreecam()
    player:RemoveTag('FreezeCamera')
    player:RemoveTag('FreecamEnabled')
	freeCamEnabled = false
	UIS.MouseIconEnabled = true
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	Maid:Sweep()
	RS:UnbindFromRenderStep("Freecam")
	local hum, hrp = GetChar()
	if hum then
		hum.WalkSpeed = 16
	end
	if hrp then
		hrp.Anchored = false
	end
	camera.FieldOfView = DEF_FOV
	camera.CameraType = Enum.CameraType.Custom
	for obj in next, screenGuis do
		obj.Enabled = true
	end
	screenGuis = {}
	ToggleGui(true)
end

------------------------------------------------

UIS.InputBegan:Connect(function(input, processed)
	if not processed then
        if freeCamEnabled and input.KeyCode == Enum.KeyCode.F then
            ExitFreecam()
        end
		if input.KeyCode == Enum.KeyCode.P then
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
				if freeCamEnabled then
					ExitFreecam()
				else
					EnterFreecam()
				end
			end
		elseif input.KeyCode == Enum.KeyCode.L and freeCamEnabled and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			letterBoxEnabled = not letterBoxEnabled
		end
	end
end)
end)
__bundle_register("Features/ExperimentalAP", function(require, _LOADED, __bundle_register, __bundle_modules)
-- getgenv().Debug_V3 = true

-- if Debug_V3 then
--     local RequireMaid = loadstring(grabBody("https://pub-f9d62e10bb734a6b946b1f82f2cf676a.r2.dev/Maid.lua"))()
--     getgenv().Maid = Maid or RequireMaid.new()
-- end

-- if Maid.AutoParryV3 then
--     Maid.AutoParryV3()
-- end

-- local Services = {
--     Players = game:GetService("Players"),
--     RunService = game:GetService("RunService"),
--     ReplicatedStorage = game:GetService("ReplicatedStorage"),
--     HttpService = game:GetService("HttpService"),
--     MarketplaceService = game:GetService("MarketplaceService"),
--     UserInputService = game:GetService("UserInputService"),
--     Lighting = game:GetService("Lighting"),
--     ReplicatedFirst = game:GetService("ReplicatedFirst"),
--     ServerStorage = game:GetService("ServerStorage"),
--     Debris = game:GetService("Debris"),
--     TweenService = game:GetService("TweenService"),
--     CollectionService = game:GetService("CollectionService"),
--     ContentProvider = game:GetService("ContentProvider"),
--     LogService = game:GetService("LogService"),
--     VIM = Instance.new("VirtualInputManager")
-- }

-- local EffectReplicator = getgenv().require(Services.ReplicatedStorage.EffectReplicator)
-- local KeyHandler = Debug_V3 and {GetKey = function() end} or require('Modules/Deepwoken/KeyHandler')
-- local Maid = getgenv().Maid
-- local Remotes = {}
-- local AnimationCache = {}

-- local Player = Services.Players.LocalPlayer
-- local Character = Player.Character or Player.CharacterAdded:Wait()
-- local Humanoid = Character:WaitForChild("Humanoid")
-- local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- local Unloaded = false

-- -- // Base Functions

-- local function print(...)
--     if not Toggles.AutoParryV3.Value then return end

--     local comp_text = "[AutoParry V3] "
--     for _,v in pairs({...}) do
--         comp_text = comp_text .. v .. "  "
--     end
--     return Library:Notify(comp_text, 1.3)
-- end

-- local function debugprint(...)
--     if not Toggles.AutoParryV3.Value then return end

--     getrenv().print("[AutoParry V3] ", ...)
-- end

-- local function Visualize()
--     if not Toggles.AutoParryV3.Value then return end

-- 	local Indicator = Instance.new("Highlight")
-- 	Indicator.Adornee = Character
-- 	Indicator.FillColor = Color3.fromRGB(90, 127, 230)
-- 	Indicator.OutlineColor = Color3.fromRGB(90, 127, 230)
-- 	Indicator.OutlineTransparency = 0
-- 	Indicator.FillTransparency = 0.5
-- 	Indicator.Parent = workspace.Thrown

-- 	game:GetService("TweenService"):Create(Indicator, TweenInfo.new(0.3), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
-- 	game.Debris:AddItem(Indicator, 0.3)
-- end

-- -- // Input Manager (Feinting, Blocking, Dodging, Parry)

-- local Inputs = {}
-- function Inputs.M2()
--     if not Toggles.AutoParryV3.Value then return end

--     Services.VIM:SendMouseButtonEvent(1, 1, 1, true, game, 1)
-- 	task.wait(.02)
-- 	Services.VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)
-- end

-- function Inputs.Unblock()
--     if not Toggles.AutoParryV3.Value then return end

--     if not Remotes.Unblock then
--         Services.VIM:SendKeyEvent(false, "F", false, game)
--         return
--     end

--     for _ = 1,12 do
--         Remotes.Unblock:FireServer()
--     end
-- end

-- function Inputs.Block()
--     if not Toggles.AutoParryV3.Value then return end

--     if not Remotes.Block then
--         Services.VIM:SendKeyEvent(true, "F", false, game)
--         return
--     end

--     for _ = 1,21 do
--         Remotes.Block:FireServer()
--     end
-- end

-- function Inputs.Dodge(Blatant)
--     if not Toggles.AutoParryV3.Value then return end

--     if Remotes.Dodge then
--         Remotes.Dodge:FireServer("roll", nil, nil, false)
--     end

--     Services.VIM:SendKeyEvent(true, "Q", false, game)

--     task.wait(.05)

--     Services.VIM:SendKeyEvent(false, "Q", false, game)
--     Inputs.M2()
-- end

-- function Inputs.Parry()
--     if not Toggles.AutoParryV3.Value then return end

--     task.spawn(Visualize)
--     Inputs.Block()
--     Inputs.Unblock()
-- end

-- -- // Task Manager (Thread Handling, etc)

-- local Tasks = {}
-- Tasks.__index = Tasks
-- Tasks.Cache = {}

-- function Tasks:Cancel()
--     local Cache = Tasks.Cache[self.Parent]
--     if not Cache then return end

--     for i,v in pairs(Cache) do
--         if not v.Cancellable then continue end
--         task.cancel(v.Thread)
--         table.remove(Tasks.Cache[self.Parent], i)
--     end
-- end

-- function Tasks:Create(Callback, Cancellable)
--     local Task = {}
--     Task.Thread = task.spawn(Callback)
--     Task.Cancellable = Cancellable or true
--     Task.Parent = self.Parent

--     table.insert(Tasks.Cache[self.Parent], Task)

--     return Task
-- end

-- function Tasks.new(Character)
--     local self = {}
--     self.Parent = Character

--     Tasks.Cache[Character] = Tasks.Cache[Character] or {}

--     return setmetatable(self, Tasks)
-- end

-- -- // Autoparry Functions

-- local AutoParry = {}
-- AutoParry.__index = AutoParry
-- AutoParry.Entities = {}

-- function AutoParry:IsSlashAnim(AnimationId)
--     return AnimationCache[AnimationId]
-- end

-- function AutoParry:GetConfig(AnimationId)
--     local Config = getgenv().V3_Configs or {}
--     return Config[AnimationId]
-- end

-- function AutoParry:GetDistance(Distance)
--     Distance = Distance or 0

--     if not self.Character:FindFirstChild('HumanoidRootPart') then
--         return
--     end

--     if not HumanoidRootPart then
--         return
--     end
    
-- 	local Pass = (HumanoidRootPart.Position - self.Character.HumanoidRootPart.Position).Magnitude <= Distance
-- 	if not Pass then
-- 		debugprint('Distance Check Failed', Distance, tostring((HumanoidRootPart.Position - self.Character.HumanoidRootPart.Position).Magnitude))
-- 	end

--     return Pass
-- end

-- function AutoParry:UpdateWeapon(v)
--     if v.Name ~= 'HandWeapon' and v.Name ~= 'WeldedBack' then
--         return
--     end

--     self.HandWeapon = v
--     self.Stats = {}

--     for _,v in pairs(v:WaitForChild('Stats'):GetChildren()) do
--         if v:IsA("BaseValue") then
--             self.Stats[v.Name] = v.Value
--         end
--     end

--     self.WeaponType = self.HandWeapon.Type.Value
--     self.RangeDiv = self.WeaponType == 'Dagger' and 2 or 1
--     self.WeaponRange = (self.Stats.Length or 6.5) * 2 / self.RangeDiv
--     self.WeaponRange = self.WeaponRange or 6
--     self.WeaponRange = math.clamp(self.WeaponRange,3.5,16)
-- end

-- function AutoParry:WeaponHandle()
--     local WeaponAdded = self.Character.DescendantAdded:Connect(function(v)
--         task.wait() -- incase they change the weapon name after adding it to char

--         self:UpdateWeapon(v)
--     end)

--     table.insert(self.Connections, WeaponAdded)

--     local Weapon = self.Character:FindFirstChild('HandWeapon', true) or self.Character:FindFirstChild('WeldedBack', true)
--     if not Weapon then return end

--     self:UpdateWeapon(Weapon)
-- end

-- local ParryCueCache = {}
-- function AutoParry:HasParryCue()
--     local HasParryCue = false

--     for _,v in pairs(self.Character.HumanoidRootPart:GetChildren()) do
--         if v.Name:match('REP_SOUND') and not ParryCueCache[v] then
--             ParryCueCache[v] = true
--             HasParryCue = true
--             break
--         end
--     end

--     return HasParryCue
-- end

-- function AutoParry:FeintHandle(Sound)
--     local SoundPlayed = Sound.Played:Connect(function()
--         if not AutoParry.Tasks[self.Character] then return end

--         print('Feint Method [1]')
--         self.Tasks:Cancel()
--     end)
    
--     local SoundStopped = Sound.Destroying:Connect(function()
--         if not AutoParry.Tasks[self.Character] then return end
--         if not Sound.PlayOnRemove then return end

--         print('Feint Method [1.5]')
--         self.Tasks:Cancel()
--     end)

--     table.insert(self.Connections, SoundPlayed)
--     table.insert(self.Connections, SoundStopped)

--     if Sound.IsPlaying and AutoParry.Tasks[self.Character] then
--         self.Tasks:Cancel()
        
--         print('Feint Method [0]')
--     end
-- end

-- function AutoParry:SanityCheck(Distance)
--     local RagdollBone = self.Character:FindFirstChild('Torso') and self.Character.Torso:FindFirstChild('Bone') and self.Character.Torso.Bone:IsA('BasePart')
--     local ArmorBroken = self.Character:FindFirstChild("MegalodauntBroken", true)
--     local T_Humanoid = self.Character:FindFirstChild('Humanoid')
--     local T_RootPart = self.Character:FindFirstChild('HumanoidRootPart')
    
--     if not T_Humanoid or not T_RootPart then return print('0') end
--     if not Humanoid or not HumanoidRootPart then return print('1') end

--     if RagdollBone then return print('2') end -- Ragdoll / Knocked
--     if ArmorBroken and ArmorBroken.Enabled then return print('3') end -- Mobs Armor Broken
--     if self.BlockBroken then return print('4') end -- Block Broken
--     if not self:GetDistance(Distance) then return print('5') end -- Distance Check

--     return true
-- end

-- function AutoParry:Setup()
--     local AnimPlayed = self.Humanoid.AnimationPlayed:Connect(function(AnimationTrack)
--         local AnimationId = AnimationTrack.Animation.AnimationId
--         local IsSlashAnim = self:IsSlashAnim(AnimationId)
--         local AnimationConfig = self:GetConfig(AnimationId)
--         local Priority = AnimationTrack.Priority
--         local LastTimePosition = 0
--         local Thread
--         local Pass = false

--         if Priority == Enum.AnimationPriority.Core then return end
--         if Priority == Enum.AnimationPriority.Idle then return end
--         if Priority == Enum.AnimationPriority.Movement then return end
--         if not AnimationConfig and not IsSlashAnim then return end
--         if not self.Character:FindFirstChild("HumanoidRootPart") then return end
--         if not self.Character then return end
--         -- TODO: Make a new thread that will do all the checks, and wait until config parry time
--         -- PLAN: If animation timeposition changed / feint sound triggered, cancel the thread. eliminating it from attempting a parry.
--         -- IF: New animation played, after the last animation with config got feinted, it will try to wait for the new animation to parry.
--         -- POSSIBLE SANITY CHECKS: Feint sound cue, Animation TimePosition < LastTimePosition, Animation.IsPlaying being false.
--         -- Basic Checks: Distance, Direction, ParryCD, RollCD.

--         self.Tasks:Cancel()
--         task.wait()
--         Thread = self.Tasks:Create(function()
--             if IsSlashAnim then
--                 debugprint('M1 Detected')

--                 local Tick = tick()
--                 LastTimePosition = AnimationTrack.TimePosition

--                 while true do
--                     if self:HasParryCue() then print('ParryCue Found') Pass = true break end
--                     if not AnimationTrack.IsPlaying then print('Feint Method [2]') break end
--                     if AnimationTrack.TimePosition < LastTimePosition then print('Feint Method [3]') break end
--                     LastTimePosition = AnimationTrack.TimePosition
--                     task.wait()
--                 end

--                 if not Pass or self:SanityCheck(self.WeaponRange) ~= true then return end

--                 debugprint('Parry Attempt. took:', tick() - Tick)
                
--                 Inputs.Parry()
--                 Thread.Cancellable = false

--                 task.wait(1)
--                 return
--             end

--             -- Base Configs (Mantras, Mobs, etc)
--             LastTimePosition = AnimationTrack.TimePosition

--             while true do
--                 if self:HasParryCue() then print('ParryCue Found') Pass = true break end
--                 if not AnimationTrack.IsPlaying then print('Feint Method [2]') break end
--                 if AnimationTrack.TimePosition < LastTimePosition then print('Feint Method [3]') break end
--                 LastTimePosition = AnimationTrack.TimePosition
--                 task.wait()
--             end

--             if not Pass or self:SanityCheck(self.WeaponRange) ~= true then return end
--             Thread.Cancellable = false

--             for i = 1, AnimationConfig.ParryAmount do
--                 if not AnimationTrack.IsPlaying then break end
--                 if AnimationTrack.TimePosition < LastTimePosition then print('Feint Method [3]') break end
--                 if i ~= 1 and self:SanityCheck(self.WeaponRange) ~= true then continue end
--                 Thread.Cancellable = false

--                 Inputs.Parry()
                
--                 Thread.Cancellable = true
--                 task.wait(AnimationConfig.ParryDelay)
--             end
            
--             Thread.Cancellable = true
--         end, true)
--     end)

--     local FeintCheck_1 = self.Character.DescendantAdded:Connect(function(v)
--         if v.Name ~= 'Feint' then return end

--         self:FeintHandle(v)
--     end)

--     local BreakMeter, BreakConnection = self.Character:FindFirstChild('BreakMeter')
--     if BreakMeter then
--         self.Posture = 0

--         BreakConnection = BreakMeter.Changed:Connect(function() -- handle if they're blockbroken
--             local NewValue = BreakMeter.Value
--             if self.Posture >= BreakMeter.MaxValue and NewValue == 0 then
--                 self.BlockBroken = true
--                 task.delay(.8, function()
--                     self.BlockBroken = false
--                 end)
--             end

--             self.Posture = NewValue
--         end)
--     end

--     self:WeaponHandle()

--     table.insert(self.Connections, AnimPlayed)
--     table.insert(self.Connections, FeintCheck_1)

--     if BreakConnection then
--         table.insert(self.Connections, BreakConnection)
--     end
-- end

-- function AutoParry.new(Target)
--     if AutoParry.Entities[Target] then
--         return AutoParry.Entities[Target]
--     end

--     if Target == Player.Character then
--         return
--     end

--     debugprint('Waiting for:', Target.Name)

--     AutoParry.Entities[Target] = true -- assign this first.
--     local Humanoid = Target:WaitForChild("Humanoid", 9e9)

--     if Unloaded then
--         AutoParry.Entities[Target] = nil
--         debugprint('Unloaded, returning', Target.Name)
--         return
--     end

--     local self = setmetatable({
--         Character = Target,
--         IsMob = Target.Name:sub(1,1) == '.',
--         IsPlayer = Services.Players:GetPlayerFromCharacter(Target),
--         Humanoid = Humanoid,
--         Connections = {},
--         Tasks = Tasks.new(Target)
--     }, AutoParry)

--     AutoParry.Entities[Target] = self
--     self:Setup()

--     return self
-- end

-- -- // Variable Handling

-- local function CharacterAdded(v)
--     Character = v
--     Humanoid = Character:WaitForChild("Humanoid")
--     HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

--     Character:WaitForChild('CharacterHandler')
--     EffectReplicator:WaitForContainer()

--     Remotes.RightClick = RightClickRemote or KeyHandler.GetKey('RightClick')
--     Remotes.Unblock = UnblockRemote or KeyHandler.GetKey('Unblock')
--     Remotes.Block = BlockRemote or KeyHandler.GetKey('Block')
--     Remotes.Dodge = DodgeRemote or KeyHandler.GetKey('Dodge')
--     Remotes.RightClickRelease = Character.CharacterHandler:WaitForChild('Requests'):WaitForChild('RightClickRelease')
-- end

-- Player.CharacterAdded:Connect(CharacterAdded)

-- if Player.Character then
--     CharacterAdded(Player.Character)
-- end

-- -- // Add AutoParry

-- for _,v in pairs(workspace.Live:GetChildren()) do
--     task.spawn(AutoParry.new, v)
-- end

-- Maid.AutoParryV3_Added = workspace.Live.ChildAdded:Connect(AutoParry.new)

-- -- // Cache Anims

-- local M1Anims = {'AerialStab', 'Slash', 'Uppercut', 'RunningAttack'}
-- local function match(Name)
--     local found = false
--     for _,str in pairs(M1Anims) do
--         if Name:match(str) then
--             found = true
--         end
--     end

--     return found
-- end

-- task.spawn(function()
--     for _,v in pairs(Services.ReplicatedStorage.Assets.Anims.Weapon:GetDescendants()) do
--         if not match(v.Name) then continue end

--         AnimationCache[v.AnimationId] = true
--     end
-- end)

-- -- // Unloading

-- Maid.AutoParryV3 = function()
--     for _,v in pairs(AutoParry.Entities) do
--         if typeof(v) ~= 'table' then
--            continue
--         end

--         for _,c in pairs(v.Connections) do
--             c:Disconnect()
--         end
--     end

--     Maid.AutoParryV3_Added:Disconnect()
--     Maid.AutoParryV3 = nil
-- end
end)
__bundle_register("Features/AutoParryRewrittenSound", function(require, _LOADED, __bundle_register, __bundle_modules)
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

local VIM = Instance.new("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

local Maid = getgenv().Maid
local robloxRequire = getgenv().require

local EffectLog = {}
do
	function EffectLog:FindEffect(Class)
		for _, v in pairs(EffectLog) do
			if typeof(v) == "function" then
				continue
			end
			if v.Class == Class then
				return v
			end
		end
	end
end

local RequireMaid = require("Modules/Maid")
local EffectHandler = robloxRequire(ReplicatedStorage:WaitForChild("EffectReplicator"))

if not _G.playerFPS then -- so it dont run multiple time when u reexec
	_G.playerFPS = 0
	task.spawn(function()
		local i = 0
		local fps = 0
		while true do
			fps = fps + 1
			i = i + task.wait()
			if i >= 1 then
				_G.playerFPS = fps
				fps = 0
				i = 0
			end
		end
	end)
end

local function DebugNotify(self, Message)
	if Toggles.ParryNotifs.Value then
		Library:Notify(Message, 2)
	end
end

local function IndicateHighlight()
	if not Toggles.VisualizeHitbox.Value then
		return
	end

	local Indicator = Instance.new("Highlight")
	Indicator.Adornee = Character
	Indicator.FillColor = Color3.fromRGB(90, 127, 230)
	Indicator.OutlineColor = Color3.fromRGB(90, 127, 230)
	Indicator.OutlineTransparency = 0
	Indicator.FillTransparency = 0.5
	Indicator.Parent = workspace.Thrown

	game:GetService("TweenService")
		:Create(Indicator, TweenInfo.new(0.3), { FillTransparency = 1, OutlineTransparency = 1 })
		:Play()
	game.Debris:AddItem(Indicator, 0.3)
end

local function CalculatedWait(waittime)
	local num = waittime
	local Ping = game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000
	num = num - (Ping * (Options.PingAdjustment.Value / 100))
	return num
end

local function CanFeint()
	local FeintCooldown = EffectLog:FindEffect("FeintCool")
	local MidAttack = EffectLog:FindEffect("MidAttack")
	if MidAttack and (tick() - MidAttack.Time) > 0.45 then
		return
	end

	if FeintCooldown then
		return
	end

	return true
end

local function AttemptFeint(IgnoreCD)
	if not CanFeint() and not IgnoreCD then
		-- will be a toggle soon, just for debugging
		--Dodge(true)
		return
	end

	if Toggles.AutoParryDebug.Value then
		return
	end

	VIM:SendMouseButtonEvent(1, 1, 1, true, game, 1)
	task.wait()
	VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)

	task.delay(0.2, function()
		VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)
	end)
end

local function IsAttacking(checkMantra)
	return EffectHandler:FindEffect("LightAttack", true)
		or EffectHandler:FindEffect("MidAttack", true)
		or (checkMantra and EffectHandler:FindEffect("UsingSpell", true))
end

local function SetBlockInput(ID, Value, Priority)
	-- see if we already have block input running, and check if we should overwrite it cause of Roll only attacks
	if Status.Busy and ID ~= Status.ID and not Priority then
		return
	end

	-- see if current is a roll only or not
	if Priority and Status.Priority and ID ~= Status.ID then
		return
	end

	-- replace the current block input ID if it's settings to false
	if Status.ID and Status.Busy == Value then
		Status.ID = nil
		Status.Maid = nil
	end

	Status.ID = ID
	if Toggles.BlockInputNotifs.Value then
		if Value then
			DebugNotify({Range = 0}, "Blocking Input [Start]")
		else
			DebugNotify({Range = 0}, "Blocking Input [End]")
		end
	end

	Status.Maid = Maid:GiveTask(task.spawn(function()
		Status.Busy = Value

		-- incase something fucked it up and just doesnt remove the busy status
		task.wait(2.5)

		-- see if its still the same id
		if Status.ID ~= ID then
			return
		end

		Status.Priority = false
		Status.Busy = false
		Status.ID = nil
		Status.Maid = nil
	end))

	if Status.Priority and not Value then
		Status.Priority = false
	end
end

local function Dodge(ForceBlatant)
	local dodgeRemote = getgenv().DodgeRemote

	if EffectHandler:FindEffect("Parry") then
		return
	end
	
	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end

	if Toggles.AutoParryDebug.Value then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	if Toggles.BlatantRoll.Value or ForceBlatant then
		dodgeRemote:FireServer("roll", nil, nil, false)

		for _, v in pairs(EffectHandler.Effects) do
			if
				table.find({
					"UsingSpell",
					"NoAttack",
					"Dodged",
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
				}, rawget(v, "Class"))
			then
				rawset(EffectHandler.Effects, v.Disabled, true)
				task.delay(0.15, function()
					rawset(EffectHandler.Effects, v.Disabled, false)
				end)
			end
		end
	end

	VIM:SendKeyEvent(true, "Q", false, game)

	if Toggles.RollCancel.Value then
		task.delay(Options.RollCancelDelay.Value / 1000, AttemptFeint, true)
	end

	task.wait(0.05)

	VIM:SendKeyEvent(false, "Q", false, game)
end

local function Parry()
	local blockRemote = getgenv().BlockRemote
	local unblockRemote = getgenv().UnblockRemote

	if Toggles.AutoParryDebug.Value then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end
	
	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end

	if IsAttacking() and Toggles.AutoFeint.Value then
		AttemptFeint()
	end

	local loopAmount = math.floor(_G.playerFPS * 0.1) + 1
	loopAmount = loopAmount >= 12 and 12 or loopAmount

	local callAmount = math.ceil(12 / loopAmount)

	for _ = 1, loopAmount do
		for _ = 1, callAmount do
			blockRemote:FireServer()
		end
		task.wait()
	end

	unblockRemote:FireServer()
end

local function DeepCopyTable(tab)
	local newTab = {}

	for k, v in pairs(tab) do
		if type(v) == "table" then
			newTab[k] = DeepCopyTable(v)
		else
			newTab[k] = v
		end
	end

	return newTab
end

local AutoParry = {}
do
	AutoParry.Sounds = {}
	function AutoParry.new(Target)
		Character = Player.Character
		RootPart = Character and Character:WaitForChild("HumanoidRootPart")
		Humanoid = Character and Character:WaitForChild("Humanoid")

		if AutoParry.Sounds[Target] then
			return
		end

        if not Target:IsA("Sound") then
            return
        end

        if not Target.Parent then
            return
        end

		local self = setmetatable({}, { __index = AutoParry })
		self.Character = Target
		self.Maid = RequireMaid.new()

		AutoParry.Sounds[Target] = self

		self.Maid.AncestryChanged = Target.AncestryChanged:Connect(function()
			if Target.Parent == nil then
				self.Maid:DoCleaning()
				AutoParry.Sounds[Target] = nil
			end
		end)

		self.Maid.Played = Target.Played:Connect(function()
            self:Run()
		end)

		return self
	end
	function AutoParry:CheckFacing()
		local UserRootPart = RootPart
        local RootPart = UserRootPart

		if Character.Parent:IsA("BasePart") then
			RootPart = self.Character.Parent
		end

		local TargetRootPart = self.Character.Parent:FindFirstChild("HumanoidRootPart")
		if Character.Parent:IsA("Model") and TargetRootPart then
			RootPart = TargetRootPart
		end

		if not RootPart or not UserRootPart then
			return
		end

		local DeltaOnTargetToLocal = (UserRootPart.Position - RootPart.Position).Unit
		local DeltaOnLocalToTarget = (RootPart.Position - UserRootPart.Position).Unit
		local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1
		local LocalToTargetResult = RootPart.CFrame.LookVector:Dot(DeltaOnLocalToTarget) <= -0.1

		if Toggles.TargetFaceYou.Value and not Toggles.FacingTarget.Value then
			return LocalToTargetResult
		end

		if Toggles.FacingTarget.Value and not Toggles.TargetFaceYou.Value then
			return TargetToLocalResult
		end

		if Toggles.TargetFaceYou.Value and Toggles.FacingTarget.Value then
			return TargetToLocalResult and LocalToTargetResult
		end

		return true
	end
	function AutoParry:CanParry()
		local Target = self.Character

		if not Toggles.AutoParryV2.Value then
			return
		end

		if not RootPart or not Humanoid then
			return
		end

		if EffectHandler:FindEffect("Parry") or EffectHandler:FindEffect("Dodge") then
			--DebugNotify(self, "Cancelled [Has Frame]")
			return
		end

		if not Target.Parent or not Target:IsDescendantOf(game) then
			--DebugNotify(self, "Cancelled [Parent]")
			return
		end

		return true
	end
	function AutoParry:Run()
		if not Character or not Character.Parent then return end
		if not RootPart or not Humanoid then return end
        local CurrentPosition = RootPart.Position

		if Character.Parent:IsA("BasePart") then
			CurrentPosition = self.Character.Parent.Position
		end

		local TargetRootPart = self.Character.Parent:FindFirstChild("HumanoidRootPart")
		if Character.Parent:IsA("Model") and TargetRootPart then
			CurrentPosition = TargetRootPart.Position
		end

        if (CurrentPosition - RootPart.Position).Magnitude <= Options.LogSounds_Range.Value then
            task.spawn(getgenv().logSound, self.Character.SoundId)
        end

		if not Toggles.AutoParryV2.Value then
			return
		end

		local ID = HttpService:GenerateGUID(false)
		local Config = SoundConfigs[self.Character.SoundId]
		if not Config then
			return
		end

		local WaitTime = CalculatedWait(Config.Wait) / 1000
		local RepeatWait = Config.RepeatParryDelay and CalculatedWait(Config.RepeatParryDelay) / 1000

		WaitTime = WaitTime + (Options.AutoParryOffset.Value / 1000)
		RepeatWait = RepeatWait and RepeatWait + (Options.RepeatOffset.Value / 1000)

		WaitTime = WaitTime + 0.07
		RepeatWait = RepeatWait and RepeatWait + 0.12

		self.CurrentSound = self.Character

		self.Maid[self.Character] = task.spawn(function()
			-- check if we are attacking
			if IsAttacking() and Toggles.AutoFeint.Value then
				-- attempt to feint and block input
				AttemptFeint()
			end

			SetBlockInput(ID, true, Config.Roll)

			task.delay(WaitTime / 2, function()
				-- check if we are still attacking
				if IsAttacking() and Toggles.AutoFeint.Value then
					AttemptFeint()
				end
			end)

			DebugNotify(self, string.format("Waiting %s [" .. tostring(WaitTime) .. "]", Config.Name))
			task.wait(WaitTime)

			if self.Character ~= self.CurrentSound then
				-- release input and cancel ap
				SetBlockInput(ID, false, Config.Roll)
				return
			end

			if not self:CanParry() or not self:CheckFacing() then
				-- release input and cancel ap
				SetBlockInput(ID, false, Config.Roll)
				return
			end

			if Config.Roll then
				DebugNotify(self, "Attempting Roll")
				IndicateHighlight()
				Dodge()
			else
				if EffectHandler:FindEffect("ParryCool") then
					DebugNotify(self, "Attempting Roll [ParryCD]")
					IndicateHighlight()
					Dodge()
					return
				end

				DebugNotify(self, "Attempting Parry") --.. tostring(Hitted)
				IndicateHighlight()
				Parry()
			end

			if Config.RepeatParryAmount then
				for i = 1, Config.RepeatParryAmount do
					task.wait(RepeatWait)

					if not self:CanParry() then
						-- wait a bit and go to next parry
						task.wait(0.09)
						continue
					end

					-- if parry on cd and roll isn't we use roll
					if EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value then
						DebugNotify(self, "Attempting Roll [Repeated]")
						IndicateHighlight()
						Dodge()
					else
						DebugNotify(self, "Attempting Parry [Repeated]")
						IndicateHighlight()
						Parry()
					end
				end
			end

			task.wait((Options.BlockInputDelay.Value or 150) / 1000)

			-- release input
			SetBlockInput(ID, false, Config.Roll)
		end)
	end
end

Maid.AP_RewriteSoundDescendantAdded = workspace.DescendantAdded:Connect(AutoParry.new)
for i, v in next, workspace:GetDescendants() do
	task.spawn(AutoParry.new, v)
end

Maid.AutoParryRewriteSound = function()
	for i, v in pairs(AutoParry.Sounds) do
		v.Maid:DoCleaning()
	end
end

local function onCharacterAdded(NewCharacter)
	Character = NewCharacter
	RootPart = NewCharacter:WaitForChild("HumanoidRootPart")
	Humanoid = NewCharacter:WaitForChild("Humanoid")
end

Maid.AP_RewriteChar = Player.CharacterAdded:Connect(onCharacterAdded)
if Character then
	onCharacterAdded(Character)
end
end)
__bundle_register("Modules/Maid", function(require, _LOADED, __bundle_register, __bundle_modules)
return (function()
	local Maid = {}
	Maid.ClassName = "Maid"

	function Maid.new()
		return setmetatable({
			_tasks = {},
		}, Maid)
	end

	function Maid.isMaid(value)
		return type(value) == "table" and value.ClassName == "Maid"
	end

	function Maid:__index(index)
		if Maid[index] then
			return Maid[index]
		else
			return self._tasks[index]
		end
	end

	function Maid:__newindex(index, newTask)
		if Maid[index] ~= nil then
			error(("'%s' is reserved"):format(tostring(index)), 2)
		end

		local tasks = self._tasks
		local oldTask = tasks[index]

		if oldTask == newTask then
			return
		end

		tasks[index] = newTask

		if oldTask then
			if type(oldTask) == "function" then
				oldTask()
			elseif typeof(oldTask) == "RBXScriptConnection" then
				oldTask:Disconnect()
			elseif typeof(oldTask) == "thread" then
				task.cancel(oldTask)
			elseif oldTask.Destroy then
				oldTask:Destroy()
			end
		end
	end

	function Maid:GiveTask(task)
		if not task then
			error("Task cannot be false or nil", 2)
		end

		local taskId = #self._tasks + 1
		self[taskId] = task

		if type(task) == "table" and not task.Destroy then
			warn("[Maid.GiveTask] - Gave table task without .Destroy\n\n" .. debug.traceback())
		end

		return taskId
	end

	function Maid:GivePromise(promise)
		if not promise:IsPending() then
			return promise
		end

		local newPromise = promise.resolved(promise)
		local id = self:GiveTask(newPromise)

		newPromise:Finally(function()
			self[id] = nil
		end)

		return newPromise
	end

	function Maid:DoCleaning()
		local tasks = self._tasks

		for index, task in pairs(tasks) do
			if typeof(task) == "RBXScriptConnection" then
				tasks[index] = nil
				task:Disconnect()
			end
		end

		local index, task = next(tasks)
		while task ~= nil do
			tasks[index] = nil
			if type(task) == "function" then
				task()
			elseif typeof(task) == "RBXScriptConnection" then
				task:Disconnect()
			elseif typeof(task) == "thread" then
				getgenv().task.cancel(task)
			elseif task.Destroy then
				task:Destroy()
			end
			index, task = next(tasks)
		end
	end

	Maid.Destroy = Maid.DoCleaning

	return Maid
end)()
end)
__bundle_register("Features/AutoParryRewrittenProjectile", function(require, _LOADED, __bundle_register, __bundle_modules)
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

local VIM = Instance.new("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

local Maid = getgenv().Maid
local robloxRequire = getgenv().require

local EffectLog = {}
do
	function EffectLog:FindEffect(Class)
		for _, v in pairs(EffectLog) do
			if typeof(v) == "function" then
				continue
			end
			if v.Class == Class then
				return v
			end
		end
	end
end

local RequireMaid = require("Modules/Maid")
local EffectHandler = robloxRequire(ReplicatedStorage:WaitForChild("EffectReplicator"))

if not _G.playerFPS then -- so it dont run multiple time when u reexec
	_G.playerFPS = 0
	task.spawn(function()
		local i = 0
		local fps = 0
		while true do
			fps = fps + 1
			i = i + task.wait()
			if i >= 1 then
				_G.playerFPS = fps
				fps = 0
				i = 0
			end
		end
	end)
end

local function DebugNotify(self, Message)
	if Toggles.ParryNotifs.Value then
		Library:Notify(Message, 2)
	end
end

local function IndicateHighlight()
	if not Toggles.VisualizeHitbox.Value then
		return
	end

	local Indicator = Instance.new("Highlight")
	Indicator.Adornee = Character
	Indicator.FillColor = Color3.fromRGB(90, 127, 230)
	Indicator.OutlineColor = Color3.fromRGB(90, 127, 230)
	Indicator.OutlineTransparency = 0
	Indicator.FillTransparency = 0.5
	Indicator.Parent = workspace.Thrown

	game:GetService("TweenService")
		:Create(Indicator, TweenInfo.new(0.3), { FillTransparency = 1, OutlineTransparency = 1 })
		:Play()
	game.Debris:AddItem(Indicator, 0.3)
end

local function CalculatedWait(waittime)
	local num = waittime
	local Ping = game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000
	num = num - (Ping * (Options.PingAdjustment.Value / 100))
	return num
end

local function CanFeint()
	local FeintCooldown = EffectLog:FindEffect("FeintCool")
	local MidAttack = EffectLog:FindEffect("MidAttack")
	if MidAttack and (tick() - MidAttack.Time) > 0.45 then
		return
	end

	if FeintCooldown then
		return
	end

	return true
end

local function AttemptFeint(IgnoreCD)
	if not CanFeint() and not IgnoreCD then
		-- will be a toggle soon, just for debugging
		--Dodge(true)
		return
	end

	if Toggles.AutoParryDebug.Value then
		return
	end

	VIM:SendMouseButtonEvent(1, 1, 1, true, game, 1)
	task.wait()
	VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)

	task.delay(0.2, function()
		VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)
	end)
end

local function IsAttacking(checkMantra)
	return EffectHandler:FindEffect("LightAttack", true)
		or EffectHandler:FindEffect("MidAttack", true)
		or (checkMantra and EffectHandler:FindEffect("UsingSpell", true))
end

local function SetBlockInput(ID, Value, Priority)
	-- see if we already have block input running, and check if we should overwrite it cause of Roll only attacks
	if Status.Busy and ID ~= Status.ID and not Priority then
		return
	end

	-- see if current is a roll only or not
	if Priority and Status.Priority and ID ~= Status.ID then
		return
	end

	-- replace the current block input ID if it's settings to false
	if Status.ID and Status.Busy == Value then
		Status.ID = nil
		Status.Maid = nil
	end

	Status.ID = ID
	if Toggles.BlockInputNotifs.Value then
		if Value then
			DebugNotify({Range = 0}, "Blocking Input [Start]")
		else
			DebugNotify({Range = 0}, "Blocking Input [End]")
		end
	end


	Status.Maid = Maid:GiveTask(task.spawn(function()
		Status.Busy = Value

		-- incase something fucked it up and just doesnt remove the busy status
		task.wait(2.5)

		-- see if its still the same id
		if Status.ID ~= ID then
			return
		end

		Status.Priority = false
		Status.Busy = false
		Status.ID = nil
		Status.Maid = nil
	end))

	if Status.Priority and not Value then
		Status.Priority = false
	end
end

local function Dodge(ForceBlatant)
	local dodgeRemote = getgenv().DodgeRemote

	if EffectHandler:FindEffect("Parry") then
		return
	end

	if Toggles.AutoParryDebug.Value then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end
	
	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end

	if Toggles.BlatantRoll.Value or ForceBlatant then
		dodgeRemote:FireServer("roll", nil, nil, false)

		for _, v in pairs(EffectHandler.Effects) do
			if
				table.find({
					"UsingSpell",
					"NoAttack",
					"Dodged",
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
				}, rawget(v, "Class"))
			then
				rawset(EffectHandler.Effects, v.Disabled, true)
				task.delay(0.15, function()
					rawset(EffectHandler.Effects, v.Disabled, false)
				end)
			end
		end
	end

	VIM:SendKeyEvent(true, "Q", false, game)

	if Toggles.RollCancel.Value then
		task.delay(Options.RollCancelDelay.Value / 1000, AttemptFeint, true)
	end

	task.wait(0.05)

	VIM:SendKeyEvent(false, "Q", false, game)
end

local function Parry()
	local blockRemote = getgenv().BlockRemote
	local unblockRemote = getgenv().UnblockRemote

	if Toggles.AutoParryDebug.Value then
		return
	end
	
	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	if IsAttacking() and Toggles.AutoFeint.Value then
		AttemptFeint()
	end

	local loopAmount = math.floor(_G.playerFPS * 0.1) + 1
	loopAmount = loopAmount >= 12 and 12 or loopAmount

	local callAmount = math.ceil(12 / loopAmount)

	for _ = 1, loopAmount do
		for _ = 1, callAmount do
			blockRemote:FireServer()
		end
		task.wait()
	end

	unblockRemote:FireServer()
end

local function DeepCopyTable(tab)
	local newTab = {}

	for k, v in pairs(tab) do
		if type(v) == "table" then
			newTab[k] = DeepCopyTable(v)
		else
			newTab[k] = v
		end
	end

	return newTab
end

local AutoParry = {}
do
	AutoParry.Projectile = {}
	function AutoParry.new(Target)
		Character = Player.Character
		RootPart = Character and Character:WaitForChild("HumanoidRootPart")
		Humanoid = Character and Character:WaitForChild("Humanoid")

		if AutoParry.Projectile[Target] then
			return
		end

        if not Target:IsA("BasePart") and not Target:IsA("Attachment") then
			return
		end

		if Target.Name == "Part" or Target.Name == "Attachment" then
			return
		end

		local self = setmetatable({}, { __index = AutoParry })
		self.Character = Target
		self.Maid = RequireMaid.new()

		AutoParry.Projectile[Target] = self

		self.Maid.AncestryChanged = Target.AncestryChanged:Connect(function()
			if Target.Parent == nil then
				self.Maid:DoCleaning()
				AutoParry.Projectile[Target] = nil
			end
		end)

		local ProjectileConfig = ProjectileConfigs[Target.Name]
        if not ProjectileConfig then
            return
        end

		local MinRange = ProjectileConfig.MinRange
		local MaxRange = ProjectileConfig.MaxRange

		if not MaxRange and not MinRange then
			MinRange = 0
			MaxRange = ProjectileConfig.Range
		end
	
		if not MinRange or not MaxRange then
			return DebugNotify(self, "Blocked projectile - range is not setup")
		end

		local CurrentRange = (Target.Position - RootPart.Position).Magnitude
		if CurrentRange <= MinRange then
			return DebugNotify(self, "Blocked projectile - range is below minimum")
		end
		
		if CurrentRange >= MaxRange * 10 then
			return
		end

		DebugNotify(self, string.format("Waiting for projectile %s to be in distance", Target.Name))
	
		while task.wait() do
			CurrentRange = (Target.Position - RootPart.Position).Magnitude

            if not AutoParry.Projectile[Target] then
                return
            end

            if CurrentRange >= MaxRange * 10 then
                return
            end

			if CurrentRange <= MaxRange then
				break
			end
		end

		self:Run()

		return self
	end
	function AutoParry:CheckFacing()
		local UserRootPart = RootPart
		local TargetRootPart = self.Character
		if not TargetRootPart or not UserRootPart then
			return
		end

		local DeltaOnTargetToLocal = (UserRootPart.Position - TargetRootPart.Position).Unit
		local DeltaOnLocalToTarget = (TargetRootPart.Position - UserRootPart.Position).Unit
		local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1
		local LocalToTargetResult = TargetRootPart.CFrame.LookVector:Dot(DeltaOnLocalToTarget) <= -0.1

		if Toggles.TargetFaceYou.Value and not Toggles.FacingTarget.Value then
			return LocalToTargetResult
		end

		if Toggles.FacingTarget.Value and not Toggles.TargetFaceYou.Value then
			return TargetToLocalResult
		end

		if Toggles.TargetFaceYou.Value and Toggles.FacingTarget.Value then
			return TargetToLocalResult and LocalToTargetResult
		end

		return true
	end
	function AutoParry:CanParry()
		local Target = self.Character

		if not Toggles.AutoParryV2.Value then
			return
		end

		if not RootPart or not Humanoid then
			return
		end

		if EffectHandler:FindEffect("Parry") or EffectHandler:FindEffect("Dodge") or EffectHandler:FindEffect("DodgedFrame") or EffectHandler:FindEffect("AutoParry") or EffectHandler:FindEffect('GenerousParry') then
			return
		end

		if not Target.Parent or not Target:IsDescendantOf(game) then
			return
		end

		return true
	end
	function AutoParry:Run()
		if not self.Character then return end
		
		if self.Character.Name == "Part" or self.Character.Name == "Attachment" then
			return
		end

		if (self.Character.Position - RootPart.Position).Magnitude < Options.LogProjectiles_Range.Value then
			task.spawn(getgenv().logProjectile, Character.Name)
		end

		if not Toggles.AutoParryV2.Value then
			return
		end

		local ID = HttpService:GenerateGUID(false)
		local Config = ProjectileConfigs[self.Character.Name]
		if not Config then
			return
		end

		local WaitTime = CalculatedWait(Config.Wait) / 1000
		local RepeatWait = Config.RepeatParryDelay and CalculatedWait(Config.RepeatParryDelay) / 1000

		WaitTime = WaitTime + (Options.AutoParryOffset.Value / 1000)
		RepeatWait = RepeatWait and RepeatWait + (Options.RepeatOffset.Value / 1000)

		WaitTime = WaitTime + 0.07
		RepeatWait = RepeatWait and RepeatWait + 0.12

		AutoParry.CurrentPart = self.Character

		self.Maid[self.Character] = task.spawn(function()
			-- check if we are attacking
			if IsAttacking() and Toggles.AutoFeint.Value then
				-- attempt to feint and block input
				AttemptFeint()
			end

			SetBlockInput(ID, true, Config.Roll)

			task.delay(WaitTime / 2, function()
				-- check if we are still attacking
				if IsAttacking() and Toggles.AutoFeint.Value then
					AttemptFeint()
				end
			end)

			DebugNotify(self, string.format("Waiting %s [" .. tostring(WaitTime) .. "]", Config.Name))
			task.wait(WaitTime)

			if not self:CanParry() or not self:CheckFacing() then
				-- release input and cancel ap
				SetBlockInput(ID, false, Config.Roll)
				return
			end

			if Config.Roll then
				DebugNotify(self, "Attempting Roll")
				IndicateHighlight()
				Dodge()
			else
				if EffectHandler:FindEffect("ParryCool") then
					DebugNotify(self, "Attempting Roll [ParryCD]")
					IndicateHighlight()
					Dodge()
					return
				end

				DebugNotify(self, "Attempting Parry") --.. tostring(Hitted)
				IndicateHighlight()
				Parry()
			end

			if Config.RepeatParryAmount then
				for i = 1, Config.RepeatParryAmount do
					task.wait(RepeatWait)

					if not self:CanParry() then
						-- wait a bit and go to next parry
						task.wait(0.09)
						continue
					end

					-- if parry on cd and roll isn't we use roll
					if EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value then
						DebugNotify(self, "Attempting Roll [Repeated]")
						IndicateHighlight()
						Dodge()
					else
						DebugNotify(self, "Attempting Parry [Repeated]")
						IndicateHighlight()
						Parry()
					end
				end
			end

			task.wait((Options.BlockInputDelay.Value or 150) / 1000)

			-- release input
			SetBlockInput(ID, false, Config.Roll)
		end)
	end
end

Maid.AP_RewriteThrown = workspace.Thrown.DescendantAdded:Connect(AutoParry.new)
for i, v in next, workspace.Thrown:GetDescendants() do
	task.spawn(AutoParry.new, v)
end

Maid.AutoParryRewriteThrown = function()
	for i, v in pairs(AutoParry.Projectile) do
		v.Maid:DoCleaning()
	end
end

local function onCharacterAdded(NewCharacter)
	Character = NewCharacter
	RootPart = NewCharacter:WaitForChild("HumanoidRootPart")
	Humanoid = NewCharacter:WaitForChild("Humanoid")
end

Maid.AP_RewriteChar = Player.CharacterAdded:Connect(onCharacterAdded)
if Character then
	onCharacterAdded(Character)
end
end)
__bundle_register("Features/AutoParryRewritten", function(require, _LOADED, __bundle_register, __bundle_modules)
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

local VIM = Instance.new("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

local Maid = getgenv().Maid
local robloxRequire = getgenv().require

local WeaponDatabase = {}
local MobDatabase = {}

local EffectLog = {} do
	function EffectLog:FindEffect(Class)
		for _,v in pairs(EffectLog) do
			if typeof(v) == "function" then continue end
			if v.Class == Class then
				return v
			end
		end
	end
end

local HitboxModule = require("Modules/Deepwoken/Hitbox")
local RequireMaid = require("Modules/Maid")
local EffectHandler = robloxRequire(ReplicatedStorage:WaitForChild("EffectReplicator"))

task.spawn(function()
	for _, Anim in pairs(game:GetService("ReplicatedStorage").Assets.Anims.Weapon:GetChildren()) do
		for _, v in pairs(Anim:GetDescendants()) do
			if v:IsA("Animation") and ( v.Name:match("Slash") or v.Name:match("AerialStab") or v.Name:match("Uppercut") or v.Name:match("Whip") )
			then
				WeaponDatabase[v.AnimationId] = {
					Name = v.Name,
					AnimName = Anim.Name,
				}
			end
		end
	end

	for _, Anim in pairs(game:GetService("ReplicatedStorage").Assets.Anims.Mobs:GetChildren()) do
		for _, v in pairs(Anim:GetDescendants()) do
			if v:IsA("Animation") then
				MobDatabase[v.AnimationId] = {
					Name = v.Name,
					AnimName = Anim.Name,
				}
			end
		end
	end
end)

local BlacklistedAnims = {}
local BlacklistedDescName = {"ShakeBlock","Equip","Stunned","Idle","Block","Parry","Execute","Walk","Crawl","TrueParry1","TrueParry2"}
local BlacklistedNames = {"FallAnim","TrueStunBreak","Jump","HitAnim1","HitAnim2","HitAnim3","ShakeBlock","DropAnim","New2handedParry","Wakeup","AirDash","FlintlockBlock","Block1","newParried","NewHitAnim1","Block2","stagger","ParryTest","2handedblock","2handedtrueparry","2handalternateparry","Guardchill","GuardIdle1","FlintlockIdle","SpearBlockShake"}
task.spawn(function()
	for i,v in pairs(game:GetService("ReplicatedStorage").Assets.Anims:GetDescendants()) do
		if v:IsDescendantOf(game:GetService("ReplicatedStorage").Assets.Anims.Weapon) and not table.find(BlacklistedDescName,v.Name) then
			continue
		end
		if v:IsDescendantOf(game:GetService("ReplicatedStorage").Assets.Anims.Mobs) and not table.find(BlacklistedDescName,v.Name) then
			continue
		end
		if v:IsA("Animation") then
			table.insert(BlacklistedAnims, v.AnimationId)
		end
	end
end)

if not _G.playerFPS then -- so it dont run multiple time when u reexec
	_G.playerFPS = 0
	task.spawn(function()
		local i = 0
		local fps = 0
		while true do
			fps = fps + 1
			i = i + task.wait()
			if i >= 1 then
				_G.playerFPS = fps
				fps = 0
				i = 0
			end
		end
	end)
end

local function DebugNotify(self, Message)
	if self.Range and self.Range < 50 and Toggles.ParryNotifs.Value then
		Library:Notify(Message, 2)
	end
end

local function GetWeaponType(AnimationId)
	local Anim = WeaponDatabase[AnimationId]
	if Anim then
		return Anim.Name, Anim.AnimName
	end
	return nil
end

local function IndicateHighlight()
	if not Toggles.VisualizeHitbox.Value then
		return
	end

	local Indicator = Instance.new("Highlight")
	Indicator.Adornee = Character
	Indicator.FillColor = Color3.fromRGB(90, 127, 230)
	Indicator.OutlineColor = Color3.fromRGB(90, 127, 230)
	Indicator.OutlineTransparency = 0
	Indicator.FillTransparency = 0.5
	Indicator.Parent = workspace.Thrown

	game:GetService("TweenService"):Create(Indicator, TweenInfo.new(0.3), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	game.Debris:AddItem(Indicator, 0.3)
end

local function CreateHitbox(self, Range, HitboxPreset)
	local Indicator = HitboxModule.new(self.Character.HumanoidRootPart, Enum.PartType.Block)

	task.delay(.1, function()
		if not Toggles.VisualizeHitbox.Value then
			return
		end
		Indicator.Transparency = 0.5
		game:GetService("TweenService"):Create(Indicator, TweenInfo.new(0.2), { Transparency = 1 }):Play()
	end)

	if HitboxPreset and HitboxPreset.X then
		local m = Options.HitboxMultiplier.Value
		Indicator.Weld.C0 = CFrame.new(0, HitboxPreset.YSet, -HitboxPreset.ZSet)
		Indicator.Size = Vector3.new(HitboxPreset.X*m, HitboxPreset.Y*m, HitboxPreset.Z*m)
	else
		Indicator.Size = Vector3.new(Range, Range, Range)
	end

	local Hitted = HitboxModule.scan(Indicator, Character)
	game.Debris:AddItem(Indicator, 0.25)

	return Hitted
end

local function MakeBaseHitbox(self, Range, HitboxPreset)
	local Indicator = HitboxModule.new(self.Character.HumanoidRootPart, Enum.PartType.Block)

	task.delay(.1, function()
		if not Toggles.VisualizeHitbox.Value then
			return
		end
		Indicator.Transparency = 0.5
	end)

	if HitboxPreset and HitboxPreset.X then
		Indicator.Weld.C0 = CFrame.new(0, HitboxPreset.YSet, -HitboxPreset.ZSet)
		Indicator.Size = Vector3.new(HitboxPreset.X, HitboxPreset.Y, HitboxPreset.Z)
	else
		Indicator.Size = Vector3.new(Range, Range, Range)
	end

	return Indicator
end

local function toAssetNumber(AssetId)
	return tonumber(AssetId:sub(14, 40))
end

local function LogAnimation(AnimationId)
	pcall(function()
		local Name = game:GetService("MarketplaceService"):GetProductInfo(toAssetNumber(AnimationId)).Name:gsub(" ", "_")

		if table.find(BlacklistedAnims, AnimationId) or table.find(LoggedAnimations, Name .. " " .. toAssetNumber(AnimationId)) or not Toggles.LogAnimations.Value
		then
			return
		end

		if table.find(BlacklistedNames, Name) then
			return
		end

		table.insert(LoggedAnimations, Name .. " " .. toAssetNumber(AnimationId))

		Options.LoggedAnimations.Values = LoggedAnimations
		Options.LoggedAnimations:SetValues(LoggedAnimations)
	end)
end

local function GetBodyParts(Character)
	return Character and Character:FindFirstChild("HumanoidRootPart"), Character and Character:FindFirstChild("Humanoid")
end

local function CalculatedWait(waittime)
	local num = waittime
	local Ping = game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000
	num = num - ( Ping * ( Options.PingAdjustment.Value / 100 ) )
	return num
end

local function CanFeint()
	local FeintCooldown = EffectLog:FindEffect("FeintCool")
	local MidAttack = EffectLog:FindEffect("MidAttack")
	if MidAttack and (tick() - MidAttack.Time) > 0.45 then
		return
	end

	if FeintCooldown then
		return
	end

	return true
end

local function AttemptFeint(IgnoreCD)
	if not CanFeint() and not IgnoreCD then
		-- will be a toggle soon, just for debugging
		--Dodge(true)
		return
	end

	if Toggles.AutoParryDebug.Value then
		return
	end

	VIM:SendMouseButtonEvent(1, 1, 1, true, game, 1)
	task.wait()
	VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)

	task.delay(.2	, function()
		VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)
	end)
end

local function IsAttacking(checkMantra)
    return EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack", true) or (checkMantra and EffectHandler:FindEffect("UsingSpell", true))
end

local function SetBlockInput(ID, Value, Priority)
	-- see if we already have block input running, and check if we should overwrite it cause of Roll only attacks
	if Status.Busy and ID ~= Status.ID and not Priority then
		return
	end

	-- see if current is a roll only or not
	if Priority and Status.Priority and ID ~= Status.ID then
		return
	end

	-- replace the current block input ID if it's settings to false
	if Status.ID and Status.Busy == Value then
		Status.ID = nil
		Status.Maid = nil
	end

	Status.ID = ID
	if Toggles.BlockInputNotifs.Value then
		if Value then
			DebugNotify({Range = 0}, "Blocking Input [Start]")
		else
			DebugNotify({Range = 0}, "Blocking Input [End]")
		end
	end

	Status.Maid = Maid:GiveTask(task.spawn(function()
		Status.Busy = Value

		-- incase something fucked it up and just doesnt remove the busy status
		task.wait(2.5)

		-- see if its still the same id
		if Status.ID ~= ID then
			return
		end

		Status.Priority = false
		Status.Busy = false
		Status.ID = nil
		Status.Maid = nil
	end))

	if Status.Priority and not Value then
		Status.Priority = false
	end
end

local function Dodge(ForceBlatant)
	local dodgeRemote = getgenv().DodgeRemote

	if EffectHandler:FindEffect("Parry") then
		return
	end

	if Toggles.AutoParryDebug.Value then
		return
	end
	
	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	if Toggles.BlatantRoll.Value or ForceBlatant then
		dodgeRemote:FireServer("roll", nil, nil, false)

        for _, v in pairs(EffectHandler.Effects) do
            if table.find({
				"UsingSpell",
				"NoAttack",
				"Dodged",
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
			}, rawget(v, "Class")) then
                rawset(EffectHandler.Effects, v.Disabled, true)
                task.delay(0.15, function()
                    rawset(EffectHandler.Effects, v.Disabled, false)
                end)
            end
        end
	end

	VIM:SendKeyEvent(true, "Q", false, game)

	if Toggles.RollCancel.Value then
		task.delay(Options.RollCancelDelay.Value / 1000, AttemptFeint, true)
	end

	task.wait(0.05)

	VIM:SendKeyEvent(false, "Q", false, game)
end

local function Parry()
	local blockRemote = getgenv().BlockRemote
	local unblockRemote = getgenv().UnblockRemote

	if Toggles.AutoParryDebug.Value then
		return
	end

	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	if IsAttacking() and Toggles.AutoFeint.Value then
		AttemptFeint()
	end

	local loopAmount = math.floor(_G.playerFPS * 0.1) + 1
	loopAmount = loopAmount >= 12 and 12 or loopAmount

	local callAmount = math.ceil(12 / loopAmount)

	for _ = 1, loopAmount do
		for _ = 1, callAmount do
			blockRemote:FireServer()
		end
		task.wait()
	end

	unblockRemote:FireServer()
end

local function HasHeavyHands(self)
	local found = false
	for _,v in pairs(self.Character:GetChildren()) do
		if v:GetAttribute('EquipmentRef') == "Heavy Hands Ring" then
			found = true
			break
		end
	end

	return found
end

local function DeepCopyTable(tab)
	local newTab = {}

	for k, v in pairs(tab) do
		if type(v) == "table" then
			newTab[k] = DeepCopyTable(v)
		else
			newTab[k] = v
		end
	end

	return newTab
end

local function GetConfig(self, AnimationID, Speed)
	local AnimationName, WeaponType = GetWeaponType(AnimationID)
	local AnimationConfig = getgenv().Config[AnimationID]

    if AnimationConfig then
        AnimationConfig = DeepCopyTable(AnimationConfig)
    end

	if not AnimationConfig and WeaponType then
		if not WeaponConfig[WeaponType] then
			return warn("No Animation Config or M1 Config for weapon type: " .. WeaponType)
		end

		AnimationConfig = {
			Name = AnimationName,
			Range = AnimationName == "AerialStab" and 30 or 20,
			Wait = AnimationName == "AerialStab" and WeaponConfig[WeaponType] + 0.1 or WeaponConfig[WeaponType],
			Delay = false,
			DelayDistance = 0,
			RepeatParryAmount = 0,
			RepeatParryDelay = 0,
			Roll = false,
			DefaultWeapon = true,
		}

		local HandWeapon = self.Character:FindFirstChild("RightHand") and self.Character:FindFirstChild("RightHand"):FindFirstChild("HandWeapon")
		if HandWeapon and (AnimationName:match("Slash") or AnimationName:match("Whip")) then
			AnimationConfig.Range = HandWeapon.Stats.Length.Value * 2
		end

		if WeaponType == "Dagger" and HandWeapon then
			AnimationConfig.Range = math.clamp(HandWeapon.Stats.Length.Value * 2.3, 15, 23)
		end

		if ParryAmount == 0 or not ParryAmount then
			ParryAmount = 1
		else
			ParryAmount = ParryAmount + 1
		end
	end

    if -- hivelord
		table.find({
			"rbxassetid://5064195992",
			"rbxassetid://5067090007",
			"rbxassetid://5067105317",
		}, AnimationID)
		and self.Character:FindFirstChild("Weapon")
		and self.Character:FindFirstChild("Weapon").Weapon.Value == "Hivelord's Hubris"
	then
		AnimationConfig.Wait = 500
		if AnimationID == "rbxassetid://5067090007" then
			AnimationConfig.Range = 40
		    AnimationConfig.Wait = 450
		end
	end

	if -- Flareblood Kamas
		table.find({
			"rbxassetid://12106091136",
			"rbxassetid://12106093579",
			"rbxassetid://12106095892",
		}, AnimationID)
		and self.Character:FindFirstChild("Weapon")
		and self.Character:FindFirstChild("Weapon").Weapon.Value == "Flareblood Kamas"
	then
		AnimationConfig.Wait = 200
	end

	if
		(self.Character:FindFirstChild("Enchant:Nemesis") or (self.Player and self.Player.Backpack:FindFirstChild("Enchant:Nemesis"))) and AnimationID == "rbxassetid://7827886914"
	then
		AnimationConfig.Wait = 300
		AnimationConfig.Range = 40
	end

	if HasHeavyHands(self) and AnimationName and (AnimationName:match('Stab') or AnimationName:match('Slash')) then
		AnimationConfig.Wait = AnimationConfig.Wait * 1.2
	end

	if Toggles.DodgeVent.Value and AnimationID == "rbxassetid://9657469282" then
		AnimationConfig.Roll = true
	end

	--- Primadon Punt
	if AnimationID == "rbxassetid://6438111139" then
		AnimationConfig.Wait = Speed > 1 and 600 or 765
	end

	--- Primadon Stomp
	if AnimationID == "rbxassetid://9225098544" then
		AnimationConfig.Wait = Speed > 1 and 360 or 490
	end

	--- Primadon Triple
	if AnimationID == "rbxassetid://6432260013" then
		AnimationConfig.Wait = Speed > 1 and 490 or 545
		AnimationConfig.RepeatParryDelay = Speed > 1 and 270 or 450
	end


	return AnimationConfig
end

local function onCharacterAdded(NewCharacter)
	Character = NewCharacter
	RootPart = NewCharacter:WaitForChild("HumanoidRootPart")
	Humanoid = NewCharacter:WaitForChild("Humanoid")

	Character:WaitForChild('CharacterHandler')

	repeat
		task.wait()
	until not Character:FindFirstChild("LeftClick", true)

	EffectHandler.EffectAdded:Connect(function(Effect)
		EffectLog[Effect.ID] = {Class = Effect.Class, Time = tick()}
	end)

	EffectHandler.EffectRemoving:Connect(function(Effect)
		EffectLog[Effect.ID] = nil
	end)
end

local AutoParry = {} do
	AutoParry.Mobs = {}
	function AutoParry.new(Target)
		if AutoParry.Mobs[Target] then
			return
		end

		local self = setmetatable({}, {__index = AutoParry})
		self.Character = Target
		self.Player = Players:GetPlayerFromCharacter(Target)
		self.Humanoid = Target:WaitForChild("Humanoid", 9e9)
		self.Feinting = false
		self.Mob = Target.Name:sub(1,1) == "."
		self.Maid = RequireMaid.new()

		AutoParry.Mobs[Target] = self

		Target.AncestryChanged:Connect(function()
			if not Target:IsDescendantOf(game) then
				self.Maid:DoCleaning()
				AutoParry.Mobs[Target] = nil
			end
		end)

		self:Setup()

		return self
	end
	function AutoParry:Setup()
		task.spawn(function() self:CheckFeint() end)

		self.Maid.AnimationPlayed = self.Humanoid.AnimationPlayed:Connect(function(AnimationTrack)
			self:AnimationPlayed(AnimationTrack)
		end)
	end
	function AutoParry:CheckFeint()
		local HumanoidRootPart = self.Character:WaitForChild("HumanoidRootPart", 9e9)
		if not AutoParry.Mobs[self.Character] then
			return
		end

		self.HitLanded = {}
		self.Maid.HitAdded = self.Character.DescendantAdded:Connect(function(v)
			if
				v.Name ~= "PunchBlood"
				and v.Name ~= "PunchEffect"
				and v.Name ~= "BloodSpray"
				and not (v:IsA("ParticleEmitter") and v.Texture == "rbxassetid://7216855595")
			then
				return
			end

			local id = table.insert(self.HitLanded, {})
			task.delay(0.2, function()
				table.remove(self.HitLanded, id)
			end)
		end)

		self.Maid.FeintChildAdded = HumanoidRootPart.ChildAdded:Connect(function(v)
			if not v:IsA("Sound") or v.SoundId ~= "rbxassetid://4954198253" then
				return
			end

			if Toggles.ReactFeint.Value then 
				return print("reacted feint")
			end

			if self.Character and self.Character == Players.LocalPlayer.Character and Players.LocalPlayer.Character then
				return
			end

			self.Feinting = true

			if (self.Range and self.Range <= 15) then
				DebugNotify(self, "Entity [" .. self.Character.Name .. "] Rolled On Feint (Main)")

				task.delay(Options.RollOnFeintDelay.Value / 1000, function()
					if not Toggles.RollOnFeint.Value then
						return
					end

					if not self:CheckFacing() then
						return
					end

					if EffectHandler:FindEffect("NoRoll") then
						return
					end

					DebugNotify(self, "Entity [" .. self.Character.Name .. "] Rolled On Feint (Main)")

					Dodge()
				end)
			end

			task.wait(v.TimeLength)

			self.Feinting = false
		end)
	end
	function AutoParry:CheckFacing()
		local UserRootPart = RootPart
		local RootPart = self.Character:FindFirstChild("HumanoidRootPart")
		if not RootPart or not UserRootPart then
			return
		end

		local DeltaOnTargetToLocal = (UserRootPart.Position - RootPart.Position).Unit
		local DeltaOnLocalToTarget = (RootPart.Position - UserRootPart.Position).Unit
		local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1
		local LocalToTargetResult = RootPart.CFrame.LookVector:Dot(DeltaOnLocalToTarget) <= -0.1

		if Toggles.TargetFaceYou.Value and not Toggles.FacingTarget.Value then
			return LocalToTargetResult
		end

		if Toggles.FacingTarget.Value and not Toggles.TargetFaceYou.Value then
			return TargetToLocalResult
		end

		if Toggles.TargetFaceYou.Value and Toggles.FacingTarget.Value then
			return TargetToLocalResult and LocalToTargetResult
		end

		return true
	end
	function AutoParry:CanParry(WaitTime, LastSecond)
		local AnimationTrack = self.CurrentTrack
		local Target = self.Character
		local T_RootPart, T_Humanoid = GetBodyParts(Target)
		local Anim_Config = GetConfig(self, AnimationTrack.Animation.AnimationId, AnimationTrack.Speed)

		if not Toggles.AutoParryV2.Value then
			return
		end

		if not T_RootPart or not T_Humanoid then
			return
		end

		if not RootPart or not Humanoid then
			DebugNotify(self, "Cancelled [Dead 2]")
			return
		end

		if not Anim_Config then
			--DebugNotify(self, "Cancelled [No Conf]")
			return
		end

		if LastSecond and (EffectHandler:FindEffect("Parry") or EffectHandler:FindEffect("Dodge")) then
			DebugNotify(self, "Cancelled [Has Frame]")
			return
		end

		if (not Toggles.ReactFeint.Value) and (not AnimationTrack.IsPlaying and WaitTime <= AnimationTrack.Length) then
			DebugNotify(self, "Cancelled [Not Playing]")
			return
		end

		if (RootPart.Position - T_RootPart.Position).Magnitude > Anim_Config.Range * 1.5 then
			--DebugNotify(self, "Cancelled [Far]")
			return
		end

		if T_Humanoid.Health <= 0 then
			DebugNotify(self, "Cancelled [Dead]")
			return
		end

		if Target.Parent ~= workspace.Live then
			DebugNotify(self, "Cancelled [Parent]")
			return
		end

		if (not Toggles.ReactFeint.Value) and self.Feinting then
			DebugNotify(self, "Cancelled [Feinting]")
			return
		end

		if Toggles.HitsCancelAP.Value and #self.HitLanded > 0 and (Target:FindFirstChild('HumanController') or self.Player) then
			DebugNotify(self, "Cancelled [Hit]")
			return
		end

		if Target:FindFirstChild("Target") and Target.Target.Value ~= Character and not Toggles.IgnoreTarget.Value then
			return
		end

		if AnimationTrack.Animation.AnimationId == "rbxassetid://9657469282" and not (Toggles.ParryVent.Value or Toggles.DodgeVent.Value) then
			return
		end

		if iswindowactive and (not iswindowactive() and Toggles.BlockAPIfUnfocused.Value) then
			return
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.F) and Toggles.BlockAPIfHoldingF.Value then
			return
		end

		return true
	end
	function AutoParry:AnimationPlayed(AnimationTrack)
		Character = Player.Character
		RootPart = Character and Character:WaitForChild("HumanoidRootPart")
		Humanoid = Character and Character:WaitForChild("Humanoid")

		if AnimationTrack.Priority == Enum.AnimationPriority.Core then
			return
		end

		if AnimationTrack.WeightTarget <= 0.05 then
			return
		end

		if not self.Mob and MobDatabase[AnimationTrack.Animation.AnimationId] ~= nil then
			return
		end

		if self.Range and self.Range < Options.LogAnimations_Range.Value then
			task.spawn(LogAnimation,AnimationTrack.Animation.AnimationId)
		end

		if not Toggles.AutoParryV2.Value then
			return
		end

		if not self.Mob and Options.AutoParryTarget.Value ~= "Players" and Options.AutoParryTarget.Value ~= "All" then
			return
		end

		if self.Player and self.Player == Players.LocalPlayer and not Toggles.ParrySelfAnimations.Value then
			return
		end

		if not Character then return end

		local Whitelists = Options.AutoParryWhitelist.Value
		if Whitelists and Whitelists ~= "" then
			if typeof(Whitelists) == "string" then
				Whitelists = { Whitelists }
			end
		end

		if typeof(Whitelists) == "table" and Whitelists[self.Character.Name] then
			return
		end

		if Toggles.AutoParryIgnoreFriends.Value and self.Player and getgenv().FriendsCache and getgenv().FriendsCache[self.Player] then
			return
		end

		local HumanoidRootPart = GetBodyParts(self.Character)
		if HumanoidRootPart and RootPart then
			self.Range = (RootPart.Position - HumanoidRootPart.Position).Magnitude
		end

		local ID = HttpService:GenerateGUID(false)
		local Config = GetConfig(self, AnimationTrack.Animation.AnimationId, AnimationTrack.Speed)
		if not Config then
			return
		end

		if not Config.Wait then
			return print("No Config Wait Time", AnimationTrack.Animation.AnimationId, Config.Name)
		end

		local WaitTime = CalculatedWait(Config.Wait) / 1000
		local RepeatWait = Config.RepeatParryDelay and CalculatedWait(Config.RepeatParryDelay) / 1000

		WaitTime = WaitTime + (Options.AutoParryOffset.Value / 1000)
		RepeatWait = RepeatWait and RepeatWait + (Options.RepeatOffset.Value / 1000)

		WaitTime = WaitTime + 0.07
		RepeatWait = RepeatWait and RepeatWait + 0.12

		self.CurrentTrack = AnimationTrack

		self.Maid[AnimationTrack] = task.spawn(function()
			SetBlockInput(ID, true, Config.Roll)

			if not self:CanParry(WaitTime) then
				SetBlockInput(ID, false, Config.Roll)
				return
			end

			-- check if we are attacking
			if IsAttacking() and Toggles.AutoFeint.Value then
				-- attempt to feint and block input
				AttemptFeint()
			end

			task.delay(WaitTime / 2, function()
				-- check if we are still attacking
				if IsAttacking() and Toggles.AutoFeint.Value then
					AttemptFeint()
				end
			end)

			local Hitted = false
			task.delay(WaitTime - 0.1, function()
				Hitted = CreateHitbox(self, Config.Range, Config.Hitbox)
			end)

			DebugNotify(self, string.format("Waiting %s ["..tostring(WaitTime) .. "]", Config.Name))
			task.wait(WaitTime)

			if AnimationTrack ~= self.CurrentTrack then
				-- release input and cancel ap
				SetBlockInput(ID, false, Config.Roll)
				return
			end

			if Config.Delay and not Hitted then
				local Cancel = false
				local Hitbox = MakeBaseHitbox(self, Config.Range, Config.Hitbox)

				repeat
					if AnimationTrack ~= self.CurrentTrack then
						--rconsoleprint("diff track")
						SetBlockInput(ID, false, Config.Roll)
						Cancel = true
						break
					end

					if not AnimationTrack.IsPlaying then
						--rconsoleprint("no longer playing")
						SetBlockInput(ID, false, Config.Roll)
						Cancel = true
						break
					end

					Hitted = HitboxModule.scan(Hitbox, Character)
					--rconsoleprint("scanning")

					task.wait(.09)
				until Hitted or Cancel

				game.Debris:AddItem(Hitbox, 0.05)
			end

			if not self:CanParry(WaitTime, true) or (not Hitted and not Toggles.AutoParryDebug.Value) or not self:CheckFacing() then
				-- release input and cancel ap
				SetBlockInput(ID, false, Config.Roll)
				return
			end

			if Config.Roll then
				DebugNotify(self, "Attempting Roll")
				IndicateHighlight()
				Dodge()
			else
				if EffectHandler:FindEffect("ParryCool") then
					if Toggles.RollOnParryCDDelay.Value then
						task.wait(Options.RollOnParryCDDelaySlider.Value / 1000)
					end
					DebugNotify(self, "Attempting Roll [ParryCD]")
					IndicateHighlight()
					Dodge()
					return
				end

				DebugNotify(self, "Attempting Parry")--.. tostring(Hitted)
				IndicateHighlight()
				Parry()
			end

			if Config.RepeatParryAmount then
				for i = 1, Config.RepeatParryAmount do
					local Hitted = false

					task.delay(RepeatWait - 0.08, function()
						Hitted = CreateHitbox(self, Config.Range, Config.Hitbox)
					end)

					task.wait(RepeatWait)

					if not self:CanParry(WaitTime) or (not Hitted and not Toggles.AutoParryDebug.Value) then
						-- wait a bit and go to next parry
						task.wait(.09)
						continue
					end

					-- if parry on cd and roll isn't we use roll
					if EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value then
						DebugNotify(self, "Attempting Roll [Repeated]")
						IndicateHighlight()
						Dodge()
					else
						DebugNotify(self, "Attempting Parry [Repeated]")
						IndicateHighlight()
						Parry()
					end
				end
			end

			if Config.RepeatUntilAnimationEnd then
				repeat
					local Hitted = false

					task.delay(RepeatWait - 0.08, function()
						Hitted = CreateHitbox(self, Config.Range, Config.Hitbox)
					end)

					task.wait(RepeatWait)

					if not self:CanParry(WaitTime) or (not Hitted and not Toggles.AutoParryDebug.Value) then
						-- wait a bit and go to next parry
						task.wait(.09)
						continue
					end

					-- if parry on cd and roll isn't we use roll
					if EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value then
						DebugNotify(self, "Attempting Roll [Repeated]")
						IndicateHighlight()
						Dodge()
					else
						DebugNotify(self, "Attempting Parry [Repeated]")
						IndicateHighlight()
						Parry()
					end
				until not AnimationTrack.IsPlaying
			end

			task.wait((Options.BlockInputDelay.Value or 150) / 1000)

			-- release input
			SetBlockInput(ID, false, Config.Roll)
		end)
	end
end

Maid.AP_RewriteChar = Player.CharacterAdded:Connect(onCharacterAdded)
if Character then
	onCharacterAdded(Character)
end

Maid.AP_RewriteChildAdded = task.spawn(function()
	while task.wait(1) do
		for i, v in next, workspace.Live:GetChildren() do
			task.spawn(AutoParry.new, v)
		end
	end
end)

Maid.AutoParryRewrite = function()
	for i,v in pairs(AutoParry.Mobs) do
		v.Maid:DoCleaning()
	end
end
end)
__bundle_register("Modules/Deepwoken/Hitbox", function(require, _LOADED, __bundle_register, __bundle_modules)
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
end)
__bundle_register("Features/AutoParry", function(require, _LOADED, __bundle_register, __bundle_modules)
local function GetBodyParts(Character)
	return Character and Character:FindFirstChild("HumanoidRootPart"),
		Character and Character:FindFirstChild("Humanoid")
end

local EffectHandlerLogs = {}
local VIM = Instance.new("VirtualInputManager")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local EffectHandler = getgenv().require(ReplicatedStorage:WaitForChild("EffectReplicator"))
local Maid = getgenv().Maid

getgenv().ProjectileConfigs = {}
getgenv().SoundConfigs = {}
local Utilities = require("Modules/Utilities")
local KeyHandler = require("Modules/Deepwoken/KeyHandler")

if not _G.playerFPS then -- so it dont run multiple time when u reexec
	_G.playerFPS = 0
	task.spawn(function()
		local i = 0
		local fps = 0
		while true do
			fps = fps + 1
			i = i + task.wait()
			if i >= 1 then
				_G.playerFPS = fps
				fps = 0
				i = 0
			end
		end
	end)
end

local function Dodge()
	if not Toggles.AutoParry.Value and not Toggles.AutoParryV2.Value then
		return
	end
	
	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	local dodgeRemote = getgenv().DodgeRemote

	if EffectHandler:FindEffect("Parry") then
		return
	end

	for _, v in pairs(EffectHandler.Effects) do
		if table.find(Utilities.RollChecks, rawget(v, "Class")) then
			rawset(EffectHandler.Effects, v.Disabled, true)
			task.delay(0.15, function()
				rawset(EffectHandler.Effects, v.Disabled, false)
			end)
		end
	end

	if Toggles.BlatantRoll.Value then
		dodgeRemote:FireServer("roll", nil, nil, false)
		return
	end

	VIM:SendKeyEvent(true, "Q", false, game)
	if Toggles.RollCancel.Value then
		task.spawn(function()
			task.wait(Options.RollCancelDelay.Value / 1000)
			if not EffectHandler:FindEffect("LightAttack") then
				mouse2click()
			end
		end)
	end
	task.wait(0.1)
	VIM:SendKeyEvent(false, "Q", false, game)
end

local function Parry()
	if not Toggles.AutoParry.Value and not Toggles.AutoParryV2.Value then
		return
	end
	
	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end
	
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	local blockRemote = getgenv().BlockRemote
	local unblockRemote = getgenv().UnblockRemote

	if
		(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
		and Toggles.AutoFeint.Value
	then
		mouse2click()
	end

	local loopAmount = math.floor(_G.playerFPS * 0.1) + 1
	loopAmount = loopAmount >= 12 and 12 or loopAmount
	local callAmount = math.ceil(12 / loopAmount)

	if
		(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
			and not EffectHandler:FindEffect("NoRoll")
		or not EffectHandler:FindEffect("Equipped")
	then
		if Toggles.RollOnParryCDDelay.Value then
			task.wait(Options.RollOnParryCDDelaySlider.Value / 1000)
		end
		Dodge()
		return
	end

	local st = tick()
	for _ = 1, loopAmount do
		for _ = 1, callAmount do
			blockRemote:FireServer()
		end
		task.wait()
	end

	task.wait()

	unblockRemote:FireServer()
end

local function RawParry()
	if Toggles.BlockInputOnF.Value and UserInputService:IsKeyDown(Enum.KeyCode.F) then
		return
	end

	if Toggles.BlockInputOnUnfocused.Value and not iswindowactive() then
		return
	end

	local loopAmount = math.floor(_G.playerFPS * 0.1) + 1
	loopAmount = loopAmount >= 12 and 12 or loopAmount
	
	local blockRemote = getgenv().BlockRemote
	local unblockRemote = getgenv().UnblockRemote

	local callAmount = math.ceil(12 / loopAmount)

	for _ = 1, loopAmount do
		for _ = 1, callAmount do
			blockRemote:FireServer()
		end
		task.wait()
	end

	task.wait()

	unblockRemote:FireServer()
end

local oldwarn = warn
local function warn(Message, Duration)
	if not Toggles.AutoParry.Value then return end
	if not Toggles.ParryNotifs.Value then
		return
	end
	getgenv().Library:Notify(Message, Duration or 1.5)
end

local WeaponDatabase = {}
local MobDatabase = {}
task.spawn(function()
	for _, Anim in pairs(game:GetService("ReplicatedStorage").Assets.Anims.Weapon:GetChildren()) do
		for _, v in pairs(Anim:GetDescendants()) do
			if
				v:IsA("Animation")
				and (
					v.Name:match("Slash")
					or v.Name:match("AerialStab")
					or v.Name:match("Uppercut")
					or v.Name:match("Whip")
				)
			then
				WeaponDatabase[v.AnimationId] = {
					Name = v.Name,
					AnimName = Anim.Name,
				}
			end
		end
	end
	for _, Anim in pairs(game:GetService("ReplicatedStorage").Assets.Anims.Mobs:GetChildren()) do
		for _, v in pairs(Anim:GetDescendants()) do
			if v:IsA("Animation") and v.Name ~= "RunningAttack" then
				MobDatabase[v.AnimationId] = {
					Name = v.Name,
					AnimName = Anim.Name,
				}
			end
		end
	end
end)

local function GetWeaponType(Animation)
	local Anim = WeaponDatabase[Animation.AnimationId]
	if Anim then
		return Anim.Name, Anim.AnimName
	end
	return nil
end

local function IsMobAnimation(Animation)
	return MobDatabase[Animation.AnimationId] ~= nil
end

getgenv().WeaponConfig = {
	Dagger = 200,
	Rapier = 150,
	Flintlock = 150,
	Karate = 200,
	LanternKarate = 320,
	PurpleCloud = 300,
	["Jus Karita"] = 200,
	["Legion Kata"] = 200,
	Sword = 300,
	TestSword = 300,
	DualSword = 300,
	Rifle = 250,
	Spear = 320,
	Mace = 250,
	FirstLight = 350,
	Scythe = 350,
	Railblade = 350,
	Greataxe = 350,
	Greatstaff = 350,
	Greathammer = 350,
	Greatsword = 350,
	BigIron = 350,
	ImperialStaff = 300,
	PyreKeeper = 350,
	Inferno = 300,
}

local blacklisted = {
	"rbxassetid://5808247302",
	"rbxassetid://180435792",
	"rbxassetid://10380978324",
	"rbxassetid://5554732065",
	"rbxassetid://6010566363",
}
local blacklistedsounds = {
	"rbxassetid://4340253186",
	"rbxassetid://6084644097",
}
local blacklistedsoundname = {
	"Audio/sliding",
	"unsheathe2",
	"altswish",
	"sheathe",
	"punch2",
	"steam",
	"menuhover4",
	"roll",
}
local blacklistedprojectiles = {
	"RainTop",
	"ArmsEquipment__Torso",
	"LegsEquipment__Opposite",
	"FaceEquipment",
	"Finger",
	"TorsoEquipment",
	"ArmsEquipment",
	"LegsEquipment",
	"Torso",
	"Head",
	"Right Arm",
	"Left Arm",
	"Left Leg",
	"NewDirt",
	"Right Leg",
	"FallDirt",
	"MovementLines",
}
local blacklistedname = {
	"saber",
	"sprint",
	"airdash",
	"dropanim",
	"fallanim",
	"walk",
	"idle",
	"movement",
	"roll",
	"draw",
	"block",
	"parry",
	"shakeblock",
	"spit",
	"vault",
	"slide",
	"hit",
	"stagger",
	"knock",
	"pinned",
	"execute",
	"run",
	"parried",
}
local AnimsDB = game:GetService("ReplicatedStorage").Assets.Anims

for _, v in pairs(AnimsDB:GetChildren()) do
	if v:IsDescendantOf(AnimsDB.Movement) or v:IsDescendantOf(AnimsDB.Gestures) and v:IsA("Animation") then
		table.insert(blacklisted, v.AnimationId)
	end
end

getgenv().LoggedAnimations = {}
getgenv().LoggedProjectiles = {}
getgenv().LoggedSounds = {}

local function toAssetNumber(AssetId)
	return tonumber(AssetId:sub(14, 40))
end

local function LogProjectile(ProjectileName)
	pcall(function()
		if
			table.find(blacklistedprojectiles, ProjectileName)
			or table.find(LoggedProjectiles, ProjectileName)
			or not Toggles.LogProjectiles.Value
		then
			return
		end

		table.insert(LoggedProjectiles, ProjectileName)

		Options.LoggedProjectiles.Values = LoggedProjectiles
		Options.LoggedProjectiles:SetValues(LoggedProjectiles)
	end)
end

local function LogSound(SoundId)
	pcall(function()
		local Name = game:GetService("MarketplaceService"):GetProductInfo(toAssetNumber(SoundId)).Name:gsub(" ", "_")

		if
			table.find(blacklistedsounds, SoundId)
			or table.find(LoggedSounds, Name .. " " .. toAssetNumber(SoundId))
			or not Toggles.LogSounds.Value
		then
			return
		end

		for _, v in pairs(blacklistedsoundname) do
			if Name:lower():match(v) then
				return
			end
		end

		table.insert(LoggedSounds, Name .. " " .. toAssetNumber(SoundId))

		Options.LoggedSounds.Values = LoggedSounds
		Options.LoggedSounds:SetValues(LoggedSounds)
	end)
end

local function LogAnimation(AnimationId)
	pcall(function()
		local Name =
			game:GetService("MarketplaceService"):GetProductInfo(toAssetNumber(AnimationId)).Name:gsub(" ", "_")

		if
			table.find(blacklisted, AnimationId)
			or table.find(LoggedAnimations, Name .. " " .. toAssetNumber(AnimationId))
			or not Toggles.LogAnimations.Value
		then
			return
		end

		for _, v in pairs(blacklistedname) do
			if Name:lower():match(v) then
				return
			end
		end

		table.insert(LoggedAnimations, Name .. " " .. toAssetNumber(AnimationId))

		Options.LoggedAnimations.Values = LoggedAnimations
		Options.LoggedAnimations:SetValues(LoggedAnimations)
	end)
end

local function DebugNotify(self, Message)
	--print(self.Range, Message, self.Character.Name)
	if self.Range and self.Range < 50 then
		Library:Notify(Message, 2)
	end
end

local function SetBlockInput(ID, Value, Priority)
	-- see if we already have block input running, and check if we should overwrite it cause of Roll only attacks
	if Status.Busy and ID ~= Status.ID and not Priority then
		return
	end

	-- see if current is a roll only or not
	if Priority and Status.Priority and ID ~= Status.ID then
		return
	end

	-- replace the current block input ID if it's settings to false
	if Status.ID and Status.Busy == Value then
		Status.ID = nil
		Status.Maid = nil
	end

	Status.ID = ID
	if Value then
		--DebugNotify({Range = 0}, "Blocking Input [Start]")
	else
		--DebugNotify({Range = 0}, "Blocking Input [End]")
	end

	Status.Maid = Maid:GiveTask(task.spawn(function()
		Status.Busy = Value

		-- incase something fucked it up and just doesnt remove the busy status
		task.wait(2.5)

		-- see if its still the same id
		if Status.ID ~= ID then
			return
		end

		Status.Priority = false
		Status.Busy = false
		Status.ID = nil
		Status.Maid = nil
	end))

	if Status.Priority and not Value then
		Status.Priority = false
	end
end

local function FeintCheck(Character)
	local RootPart = Character:WaitForChild("HumanoidRootPart", 9e9)
	local Sounds = RootPart:FindFirstChild("Sounds")
	local Feint = Sounds and Sounds:FindFirstChild("Feint")
	if not Status[Character] then
		return
	end
	if Feint then
		Status[Character].Maid[Character.Name .. "_feintcheck"] = Feint.Played:Connect(function()
			local PlayerRoot, _ = GetBodyParts(Player.Character)

			if (PlayerRoot.Position - RootPart.Position).Magnitude > 25 then
				return
			end

			if Character == Player.Character then
				return
			end

			if not Toggles.AutoParry.Value then
				return
			end

			if (RootPart.CFrame.Position - Player.Character:GetPivot().Position).Magnitude > 50 then
				return
			end
			
			if Toggles.ReactFeint.Value then
				return
			end

			Status[Character].Feinted = true
			task.delay(0.15, function()
				Status[Character].Feinted = false
			end)

			warn("Entity [" .. Character.Name .. "] Caught Feinting (Main)", 1.5)

			if Toggles.RollOnFeint.Value and not EffectHandler:FindEffect("NoRoll") then
				warn("Entity [" .. Character.Name .. "] Rolled On Feint (Main)", 1.5)
				Dodge()
			end
		end)

		Status[Character].Maid[Character.Name .. "_feintcheck_ended"] = Feint.Ended:Connect(function()
			Status[Character].Feinted = false
		end)
	end

	Status[Character].Maid[Character.Name .. "_feintcheck_added"] = RootPart.ChildAdded:Connect(function(v)
		if not v:IsA("Sound") or v.Name ~= "Feint" then
			return
		end

		if not Toggles.AutoParry.Value then
			return
		end
		
		if Toggles.ReactFeint.Value then
			return
		end

		Status[Character].Feinted = true

		task.delay(0.15, function()
			Status[Character].Feinted = false
		end)

		if (RootPart.CFrame.Position - Player.Character:GetPivot().Position).Magnitude > 50 then
			return
		end

		warn("Entity [" .. Character.Name .. "] Caught Feinting (Backup)", 1.5)

		if Toggles.RollOnFeint.Value and not EffectHandler:FindEffect("NoRoll") then
			warn("Entity [" .. Character.Name .. "] Rolled On Feint (Backup)", 1.5)
			Dodge()
		end
	end)
end

local RequireMaid = require("Modules/Maid")
local function Register(Character)
	if Status[Character] then
		return
	end

	Status[Character] = {
		Maid = RequireMaid.new(),
	}

	Maid[Character.Name .. "_Maid"] = Status[Character].Maid

	local IsMob = Character.Name:sub(1, 1) == "."
	local Humanoid = Character:WaitForChild("Humanoid", 9e9)
	task.spawn(FeintCheck, Character)

	Status[Character].Maid[Character.Name .. "_removal"] = Character.ChildRemoved:Connect(function(child)
		if child.Name == "Humanoid" then
			Status[Character].Maid:DoCleaning()
			Status[Character] = nil
		end
	end)

	local function mandatoryChecks()
		if not Toggles.AutoParry.Value then
			return
		end

		local RootPart = Character:FindFirstChild("HumanoidRootPart")
		if not RootPart then
			return
		end

		local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)
		if not UserRootPart or not UserHumanoid then
			return
		end

		if (RootPart.Position - UserRootPart.Position).Magnitude > 1000 then
			return
		end

		return true
	end

	local function CheckFacing()
		local RootPart = Character:FindFirstChild("HumanoidRootPart")
		local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)
		if not UserRootPart or not UserHumanoid then
			return
		end

		local DeltaOnTargetToLocal = (UserRootPart.Position - RootPart.Position).Unit
		local DeltaOnLocalToTarget = (RootPart.Position - UserRootPart.Position).Unit
		local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1
		local LocalToTargetResult = RootPart.CFrame.LookVector:Dot(DeltaOnLocalToTarget) <= -0.1

		if Toggles.TargetFaceYou.Value and not Toggles.FacingTarget.Value then
			return LocalToTargetResult
		end

		if Toggles.FacingTarget.Value and not Toggles.TargetFaceYou.Value then
			return TargetToLocalResult
		end

		if Toggles.TargetFaceYou.Value and Toggles.FacingTarget.Value then
			return TargetToLocalResult and LocalToTargetResult
		end

		return true
	end

	local function SanityCheck(Range, ID, AnimationConfig)
		local RootPart = Character:FindFirstChild("HumanoidRootPart")
		local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)
		if not UserRootPart or not UserHumanoid then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if not Humanoid or not RootPart then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		local Torso = Character:FindFirstChild("Torso")
		if Torso and Torso:FindFirstChild("Bone") and Torso.Bone:IsA("BasePart") then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if Status[Character].Feinted then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			Status[Character].Feinted = false
			return
		end

		if (RootPart.Position - UserRootPart.Position).Magnitude > Range then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		local particle = Character and Character:FindFirstChild("MegalodauntBroken", true)
		if particle and particle:IsA("ParticleEmitter") and particle.Enabled then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		return true
	end

	local function SetFeint()
		Status[Character].Feinted = true
		task.delay(0.1, function()
			Status[Character].Feinted = false
		end)
	end

	local function AutoParryInit(AnimationTrack)
		local RootPart = Character:FindFirstChild("HumanoidRootPart")
		if AnimationTrack.Priority == Enum.AnimationPriority.Core then
			return
		end

		if Toggles.AutoParryV2.Value then
			return
		end

		-- nice AP blocker bro.
		if AnimationTrack.WeightTarget <= 0.01 then
			return
		end

		if not IsMob and IsMobAnimation(AnimationTrack.Animation) then
			return
		end

		if not mandatoryChecks() then
			return
		end

		local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)

		if
			Toggles.LogAnimations.Value
			and (RootPart.Position - UserRootPart.Position).Magnitude <= Options.LogAnimations_Range.Value
		then
			LogAnimation(AnimationTrack.Animation.AnimationId)
		end

		if not IsMob and Options.AutoParryTarget.Value ~= "Players" and Options.AutoParryTarget.Value ~= "All" then
			return
		end

		if (RootPart.Position - UserRootPart.Position).Magnitude > 600 then
			return
		end

		local Whitelists = Options.AutoParryWhitelist.Value
		if Whitelists and Whitelists ~= "" then
			if typeof(Whitelists) == "string" then
				Whitelists = { Whitelists }
			end
		end

		if typeof(Whitelists) == "table" and Whitelists[Character.Name] then
			return
		end

		local AnimationConfig = Config[AnimationTrack.Animation.AnimationId]
		local Ping = (game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000)
			* (Options.PingAdjustment.Value / 100)

		local AnimationName, WeaponType = GetWeaponType(AnimationTrack.Animation)
		if WeaponType and not AnimationConfig then
			if not WeaponConfig[WeaponType] then
				warn("Weapon Type Not Found: " .. WeaponType, 1.5)
				return
			end

			AnimationConfig = {
				Name = AnimationName,
				Range = AnimationName == "AerialStab" and 30 or 20,
				Wait = AnimationName == "AerialStab" and WeaponConfig[WeaponType] + 0.1 or WeaponConfig[WeaponType],
				Delay = false,
				DelayDistance = 0,
				RepeatParryAmount = 0,
				RepeatParryDelay = 0,
				Roll = false,
				DefaultWeapon = true,
			}

			local HandWeapon = Character:FindFirstChild("RightHand")
				and Character:FindFirstChild("RightHand"):FindFirstChild("HandWeapon")
			if HandWeapon and (AnimationName:match("Slash") or AnimationName:match("Whip")) then
				AnimationConfig.Range = HandWeapon.Stats.Length.Value * 2
			end

			if WeaponType == "Dagger" then
				AnimationConfig.Range = math.clamp(HandWeapon.Stats.Length.Value * 2.3, 15, 23)
			end

			if Toggles.AutoParryV3 and not Toggles.AutoParryV3.Value then
				return
			end
		end

		if not AnimationConfig then
			if Character == Player.Character and not Toggles.LogPlayerAnimations.Value then
				return
			end
			return
		end

		if Character == Player.Character and not Toggles.ParrySelfAnimations.Value then
			return
		end

		if
			Character:FindFirstChild("Target")
			and Character.Target.Value ~= Player.Character
			and not Toggles.IgnoreTarget.Value
		then
			return
		end

		if
			AnimationTrack.Animation.AnimationId == "rbxassetid://9657469282"
			and not (Toggles.ParryVent.Value or Toggles.DodgeVent.Value)
		then
			return
		end

		local isPlayer = Players:GetPlayerFromCharacter(Character)
		local WaitTime = AnimationConfig.Wait
		local Delay = AnimationConfig.Delay
		local DelayDistance = AnimationConfig.DelayDistance
		local ParryAmount = AnimationConfig.RepeatParryAmount or 0
		local Roll = not Toggles.ParryOnly.Value and AnimationConfig.Roll or false
		local RepeatDelay = AnimationConfig.RepeatParryDelay or 0
		local RepeatUntilAnimationEnd = AnimationConfig.RepeatUntilAnimationEnd or false
		local Range = AnimationConfig.Range
		local st = tick()

		if Toggles.DodgeVent.Value and AnimationTrack.Animation.AnimationId == "rbxassetid://9657469282" then
			Roll = true
		end

		if not AnimationConfig.DefaultWeapon and WaitTime > 0 and not AnimationConfig.IgnoreCustom then
			WaitTime = WaitTime + 120
		end

		if not AnimationConfig.DefaultWeapon and RepeatDelay > 0 and not AnimationConfig.IgnoreCustom then
			RepeatDelay = RepeatDelay + 120
		end

		if ParryAmount == 0 then
			ParryAmount = 1
		else
			ParryAmount = ParryAmount + 1
		end

		if -- Hivelord Hubris
			table.find({
				"rbxassetid://5064195992",
				"rbxassetid://5067090007",
				"rbxassetid://5067105317",
			}, AnimationTrack.Animation.AnimationId)
			and Character:FindFirstChild("Weapon")
			and Character:FindFirstChild("Weapon").Weapon.Value == "Hivelord's Hubris"
		then
			if AnimationTrack.Animation.AnimationId == "rbxassetid://5067090007" then
				Range = 40
			end

			WaitTime = 500
		end

		if -- Flareblood Kamas
			table.find({
				"rbxassetid://12106091136",
				"rbxassetid://12106093579",
				"rbxassetid://12106095892",
			}, AnimationTrack.Animation.AnimationId)
			and Character:FindFirstChild("Weapon")
			and Character:FindFirstChild("Weapon").Weapon.Value == "Flareblood Kamas"
		then
			WaitTime = 200
		end

		if
			(
				Character:FindFirstChild("Enchant:Nemesis")
				or (isPlayer and isPlayer.Backpack:FindFirstChild("Enchant:Nemesis"))
			) and AnimationTrack.Animation.AnimationId == "rbxassetid://7827886914"
		then
			WaitTime = 610
			Range = 40
		end

		if AnimationConfig.Name == "Uppercut" then
			Range = 30
		end

		if Character:FindFirstChild("SilentheartTorso") and AnimationConfig.Name == "Uppercut" then
			Range = 60
		end

		local AnimName = AnimationConfig.Name
		if AnimationTrack.Speed > 1 then
			--[{"rbxassetid://6432260013":{"RepeatParryDelay":410,"CustomConfig":true,"Range":100,"Wait":390,"DelayDistance":0,"Roll":false,"RepeatParryAmount":2,"Name":"PrimaTriple","Delay":false,"selfid":"rbxassetid://6432260013"}}]
			--[{"rbxassetid://6347657585":{"RepeatParryDelay":0,"CustomConfig":true,"Range":100,"Wait":400,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"PrimaStomp1","Delay":false,"selfid":"rbxassetid://6347657585"}}]
			--[{"rbxassetid://6438111139":{"RepeatParryDelay":0,"CustomConfig":true,"Range":100,"Wait":600,"DelayDistance":0,"Roll":true,"RepeatParryAmount":0,"Name":"PrimaPunt","Delay":false,"selfid":"rbxassetid://6438111139"}}]
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6438111139" then
				WaitTime = 750
				AnimName = "Rage_" .. AnimName
			end
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6347657585" then
				WaitTime = 550
				AnimName = "Rage_" .. AnimName
			end
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6432260013" then
				RepeatDelay = 530
				WaitTime = 390 + 150
				AnimName = "Rage_" .. AnimName
			end
		else
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6438111139" then
				WaitTime = WaitTime + 150
			end
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6347657585" then
				WaitTime = WaitTime + 150
			end
			if AnimationTrack.Animation.AnimationId == "rbxassetid://6432260013" then
				RepeatDelay = RepeatDelay + 300
				WaitTime = WaitTime + 300
			end
		end

		WaitTime = WaitTime + Options.AutoParryOffset.Value
		RepeatDelay = RepeatDelay + Options.AutoParryOffset.Value

		local Cancelled = false
		local WaitTimePing = (WaitTime / 1000) - Ping
		local CalculatedTime = string.format("%.2f", WaitTimePing)
		if CalculatedTime:sub(-3) == ".00" then
			CalculatedTime = string.format("%.0f", CalculatedTime)
		end

		local ID = HttpService:GenerateGUID(false)
		SetBlockInput(ID, true, AnimationConfig.Roll)

		if Roll then
			if
				(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
				and Toggles.AutoFeint.Value
			then
				if
					(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
					or not EffectHandler:FindEffect("UsingSpell")
				then
					mouse2click()
				end
			end
		end

		task.delay(WaitTimePing / 4, function()
			if not SanityCheck(Range, ID, AnimationConfig) then
				SetBlockInput(ID, false, AnimationConfig.Roll)
				Cancelled = true
				return
			end

			if not AnimationTrack.IsPlaying then
				SetFeint()
				SetBlockInput(ID, false, AnimationConfig.Roll)
				Cancelled = true
				return
			end
		end)

		task.delay(WaitTimePing / 2, function()
			if not SanityCheck(Range, ID, AnimationConfig) then
				SetBlockInput(ID, false, AnimationConfig.Roll)
				Cancelled = true
				return
			end

			if not AnimationTrack.IsPlaying then
				SetFeint()
				SetBlockInput(ID, false, AnimationConfig.Roll)
				Cancelled = true
				return
			end
		end)

		warn("Waiting " .. AnimationConfig.Name .. " [" .. WaitTimePing .. "]", 1.5)
		task.wait(WaitTimePing)

		if Cancelled then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if not SanityCheck(Range, ID, AnimationConfig) then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if Delay then
			local s_tick = tick()
			repeat
				task.wait()
			until (RootPart.Position - UserRootPart.Position).Magnitude <= DelayDistance or tick() - s_tick > 2.5
		end

		if not SanityCheck(Range, ID, AnimationConfig) then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if not CheckFacing() then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if EffectHandler:FindEffect("ParryCool") and EffectHandler:FindEffect("NoRoll") and Roll then
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		if
			(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
				and not EffectHandler:FindEffect("NoRoll")
			or not EffectHandler:FindEffect("Equipped")
		then
			Roll = true
		end

		if
			(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
			and Toggles.AutoFeint.Value
		then
			if
				(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
				or not EffectHandler:FindEffect("UsingSpell")
			then
				mouse2click()
			end
		end

		local ShouldRoll = math.random(0, 100) <= Options.RollPercentage.Value
		if ShouldRoll and not EffectHandler:FindEffect("NoRoll") and not Roll then
			Roll = true
		end

		local ShouldParry = math.random(0, 100) <= Options.ParryChance.Value
		if not Roll and not ShouldParry then
			return
		end

		if Roll then
			if not SanityCheck(Range, ID, AnimationConfig) then
				SetBlockInput(ID, false, AnimationConfig.Roll)
				return
			end

			task.spawn(Dodge)

			warn("Dodging " .. AnimationConfig.Name .. " [" .. CalculatedTime .. "]", 1.5)

			task.wait(0.31)
			SetBlockInput(ID, false, AnimationConfig.Roll)
			return
		end

		local function InnerParry(i)
			if not SanityCheck(Range, ID, AnimationConfig) then
				return
			end

			if not CheckFacing() then
				return
			end

			if EffectHandlerLogs.Stun then
				return
			end

			if
				(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
					and not EffectHandler:FindEffect("NoRoll")
				or not EffectHandler:FindEffect("Equipped")
			then
				task.spawn(Dodge)
			end

			if not EffectHandler:FindEffect("ParryCool") then
				task.spawn(Parry)
			end

			warn("Parrying " .. AnimationConfig.Name .. " [" .. CalculatedTime .. "]", 1.5)

			task.wait(i ~= ParryAmount and (RepeatDelay / 1000) or 0)
		end

		if RepeatUntilAnimationEnd then
			repeat
				if not Character or not Character:IsDescendantOf(game) then
					break
				end

				if not mandatoryChecks() then
					break
				end

				InnerParry()

				task.wait()
			until not AnimationTrack.IsPlaying
		else
			for i = 1, ParryAmount do
				InnerParry(i)
			end
		end

		task.wait(Roll and 0.5 or 0.15)

		SetBlockInput(ID, false, AnimationConfig.Roll)
	end

	Status[Character].Maid[Character.Name .. "_AnimationPlayed"] = Humanoid.AnimationPlayed:Connect(AutoParryInit)
end

local function RegisterSound(Character)
	if Status[Character] then
		return
	end

	if not Character:IsA("Sound") then
		return
	end

	if not Character.Parent then
		return
	end

	Status[Character] = {
		Maid = RequireMaid.new(),
	}

	Maid[Character.Name .. "_Maid"] = Status[Character].Maid

	Status[Character].Maid[Character.Name .. "_removal"] = Character.AncestryChanged:Connect(function(_)
		if Character and Character:IsDescendantOf(game) then
			return
		end

		Status[Character].Maid:DoCleaning()
		Status[Character] = nil
	end)

	local function AutoParryInit(SoundId)
		local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)
		if not UserRootPart or not UserHumanoid then
			return
		end

		local CurrentPosition = UserRootPart.Position

		if Character.Parent:IsA("BasePart") then
			CurrentPosition = Character.Parent.Position
		end

		local RootPart = Character.Parent:FindFirstChild("HumanoidRootPart")
		if Character.Parent:IsA("Model") and RootPart then
			CurrentPosition = RootPart.Position
		end

		if
			Toggles.LogSounds.Value
			and (CurrentPosition - UserRootPart.Position).Magnitude <= Options.LogSounds_Range.Value
		then
			LogSound(SoundId)
		end

		local SoundConfig = SoundConfigs[SoundId]
		if not SoundConfig then
			return
		end

		local WaitTime = SoundConfig.Wait
		local Delay = SoundConfig.Delay
		local DelayDistance = SoundConfig.DelayDistance
		local ParryAmount = SoundConfig.RepeatParryAmount or 0
		local Roll = not Toggles.ParryOnly.Value and SoundConfig.Roll or false
		local RepeatDelay = SoundConfig.RepeatParryDelay or 0
		local Range = SoundConfig.Range

		Status[Character] = {
			Maid = RequireMaid.new(),
		}

		Maid[Character.Name .. "_Maid"] = Status[Character].Maid

		Status[Character].Maid[Character.Name .. "_removal"] = Character.AncestryChanged:Connect(function(_)
			if not Character or not Character:IsDescendantOf(game) then
				return
			end

			Status[Character].Maid:DoCleaning()
			Status[Character] = nil
		end)

		local function mandatoryChecks()
			if not Toggles.AutoParry.Value then
				return
			end

			if (CurrentPosition - UserRootPart.Position).Magnitude > 1000 then
				return
			end

			return true
		end

		local function CheckFacing()
			if not UserRootPart or not UserHumanoid then
				return
			end

			local DeltaOnTargetToLocal = (UserRootPart.Position - CurrentPosition).Unit
			local DeltaOnLocalToTarget = (CurrentPosition - UserRootPart.Position).Unit
			local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1
			local LocalToTargetResult = Character.Parent.CFrame.LookVector:Dot(DeltaOnLocalToTarget) <= -0.1

			if Toggles.TargetFaceYou.Value and not Toggles.FacingTarget.Value then
				return TargetToLocalResult
			end

			if Toggles.FacingTarget.Value and not Toggles.TargetFaceYou.Value then
				return LocalToTargetResult
			end

			if Toggles.TargetFaceYou.Value and Toggles.FacingTarget.Value then
				return TargetToLocalResult and LocalToTargetResult
			end

			return true
		end

		local function SanityCheck(ID)
			if not UserRootPart or not UserHumanoid then
				return
			end

			if (CurrentPosition - UserRootPart.Position).Magnitude > Range then
				return
			end

			return true
		end

		if not mandatoryChecks() then
			return
		end

		if (CurrentPosition - UserRootPart.Position).Magnitude > 600 then
			return
		end

		local Ping = (game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000)
			* (Options.PingAdjustment.Value / 100)
		local st = tick()
		if ParryAmount == 0 then
			ParryAmount = 1
		else
			ParryAmount = ParryAmount + 1
		end

		WaitTime = WaitTime + Options.AutoParryOffset.Value
		RepeatDelay = RepeatDelay + Options.AutoParryOffset.Value

		local Cancelled = false
		local WaitTimePing = (WaitTime / 1000) - Ping
		local CalculatedTime = string.format("%.2f", WaitTimePing)
		if CalculatedTime:sub(-3) == ".00" then
			CalculatedTime = string.format("%.0f", CalculatedTime)
		end

		local ID = HttpService:GenerateGUID(false)

		if Roll then
			if
				(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
				and Toggles.AutoFeint.Value
			then
				if
					(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
					or not EffectHandler:FindEffect("UsingSpell")
				then
					mouse2click()
				end
			end
		end

		task.delay(WaitTimePing / 4, function()
			if not SanityCheck() then
				Cancelled = true
				return
			end
		end)

		task.delay(WaitTimePing / 2, function()
			if not SanityCheck() then
				Cancelled = true
				return
			end
		end)

		warn("Waiting " .. SoundConfig.Name .. " [" .. WaitTimePing .. "]", 1.5)
		task.wait(WaitTimePing)

		if Cancelled then
			return
		end

		if not SanityCheck() then
			return
		end

		if Delay then
			local s_tick = tick()
			repeat
				task.wait()
			until (CurrentPosition - UserRootPart.Position).Magnitude <= DelayDistance or tick() - s_tick > 2.5
		end

		if not SanityCheck() then
			return
		end

		if not CheckFacing() then
			return
		end

		if EffectHandler:FindEffect("ParryCool") and EffectHandler:FindEffect("NoRoll") and Roll then
			return
		end

		if
			(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
				and not EffectHandler:FindEffect("NoRoll")
			or not EffectHandler:FindEffect("Equipped")
		then
			Roll = true
		end

		if
			(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
			and Toggles.AutoFeint.Value
		then
			if
				(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
				or not EffectHandler:FindEffect("UsingSpell")
			then
				mouse2click()
			end
		end

		local ShouldRoll = math.random(0, 100) <= Options.RollPercentage.Value
		if ShouldRoll and not EffectHandler:FindEffect("NoRoll") and not Roll then
			Roll = true
		end

		local ShouldParry = math.random(0, 100) <= Options.ParryChance.Value
		if not Roll and not ShouldParry then
			return
		end

		if Roll then
			if not SanityCheck() then
				return
			end

			task.spawn(Dodge)

			warn("Dodging " .. SoundConfig.Name .. " [" .. CalculatedTime .. "]", 1.5)

			task.wait(0.31)
			return
		end

		for i = 1, ParryAmount do
			if not SanityCheck() then
				break
			end

			if not CheckFacing() then
				return
			end

			if EffectHandlerLogs.Stun then
				break
			end

			if
				(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
					and not EffectHandler:FindEffect("NoRoll")
				or not EffectHandler:FindEffect("Equipped")
			then
				task.spawn(Dodge)
			end

			if not EffectHandler:FindEffect("ParryCool") then
				task.spawn(Parry)
			end

			task.wait(i ~= ParryAmount and (RepeatDelay / 1000) or 0)
		end

		task.wait(Roll and 0.5 or 0.15)
	end

	Status[Character].Maid[Character.Name .. "_SoundPlayed"] = Character.Played:Connect(AutoParryInit)
end

local function RegisterProjectile(Character)
	if Status[Character] then
		return
	end

	if not Character:IsA("BasePart") and not Character:IsA("Attachment") then
		return
	end

	if Character.Name == "Part" or Character.Name == "Attachment" then
		return
	end

	local UserRootPart, UserHumanoid = GetBodyParts(Player.Character)
	if not UserRootPart or not UserHumanoid then
		return
	end

	if
		Toggles.LogProjectiles.Value
		and (Character.Position - UserRootPart.Position).Magnitude <= Options.LogProjectiles_Range.Value
	then
		LogProjectile(Character.Name)
	end

	local ProjectileConfig = ProjectileConfigs[Character.Name]
	if not ProjectileConfig then
		return
	end

	local WaitTime = ProjectileConfig.Wait
	local ParryAmount = ProjectileConfig.RepeatParryAmount or 0
	local Roll = not Toggles.ParryOnly.Value and ProjectileConfig.Roll or false
	local RepeatDelay = ProjectileConfig.RepeatParryDelay or 0
	local MinRange = ProjectileConfig.MinRange
	local MaxRange = ProjectileConfig.MaxRange
	local ID = HttpService:GenerateGUID(false)

	-- Handle range if there is no max / min range
	if not MaxRange and not MinRange then
		MinRange = 0
		MaxRange = ProjectileConfig.Range
	end

	Status[Character] = {
		Maid = RequireMaid.new(),
	}

	Maid[Character.Name .. "_Maid"] = Status[Character].Maid

	Status[Character].Maid[Character.Name .. "_removal"] = Character.AncestryChanged:Connect(function(_)
		if not Character or not Character:IsDescendantOf(game) then
			return
		end

		Status[Character].Maid:DoCleaning()
		Status[Character] = nil
	end)

	local function mandatoryChecks()
		if not Toggles.AutoParry.Value then
			return
		end

		if (Character.Position - UserRootPart.Position).Magnitude > 1000 then
			return
		end

		return true
	end

	local function CheckFacing()
		if not UserRootPart or not UserHumanoid then
			return
		end

		local DeltaOnTargetToLocal = (UserRootPart.Position - Character.Position).Unit
		local DeltaOnLocalToTarget = (Character.Position - UserRootPart.Position).Unit
		local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1
		local LocalToTargetResult = Character.CFrame.LookVector:Dot(DeltaOnLocalToTarget) <= -0.1

		if Toggles.TargetFaceYou.Value and not Toggles.FacingTarget.Value then
			return TargetToLocalResult
		end

		if Toggles.FacingTarget.Value and not Toggles.TargetFaceYou.Value then
			return LocalToTargetResult
		end

		if Toggles.TargetFaceYou.Value and Toggles.FacingTarget.Value then
			return TargetToLocalResult and LocalToTargetResult
		end

		return true
	end

	local function SanityCheck(ID)
		if not UserRootPart or not UserHumanoid then
			SetBlockInput(ID, false, false)
			return
		end

		local CurrentRange = (Character.Position - UserRootPart.Position).Magnitude
		if CurrentRange < MinRange or CurrentRange > MaxRange then
			SetBlockInput(ID, false, false)
			return
		end

		return true
	end

	local function AutoParryInit()
		if not mandatoryChecks() then
			return
		end

		if (Character.Position - UserRootPart.Position).Magnitude > 600 then
			return
		end

		local Ping = (game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000)
			* (Options.PingAdjustment.Value / 100)
		local st = tick()
		if ParryAmount == 0 then
			ParryAmount = 1
		else
			ParryAmount = ParryAmount + 1
		end

		WaitTime = WaitTime + Options.AutoParryOffset.Value
		RepeatDelay = RepeatDelay + Options.AutoParryOffset.Value

		local Cancelled = false
		local WaitTimePing = (WaitTime / 1000) - Ping
		local CalculatedTime = string.format("%.2f", WaitTimePing)
		if CalculatedTime:sub(-3) == ".00" then
			CalculatedTime = string.format("%.0f", CalculatedTime)
		end

		SetBlockInput(ID, true, false)

		if Roll then
			if
				(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
				and Toggles.AutoFeint.Value
			then
				if
					(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
					or not EffectHandler:FindEffect("UsingSpell")
				then
					mouse2click()
				end
			end
		end

		task.delay(WaitTimePing / 4, function()
			if not SanityCheck() then
				SetBlockInput(ID, false, false)
				Cancelled = true
				return
			end
		end)

		task.delay(WaitTimePing / 2, function()
			if not SanityCheck() then
				SetBlockInput(ID, false, false)
				Cancelled = true
				return
			end
		end)

		warn("Waiting " .. ProjectileConfig.Name .. " [" .. WaitTimePing .. "]", 1.5)
		task.wait(WaitTimePing)

		if Cancelled then
			SetBlockInput(ID, false, false)
			return
		end

		if not SanityCheck() then
			SetBlockInput(ID, false, false)
			return
		end

		if not CheckFacing() then
			SetBlockInput(ID, false, false)
			return
		end

		if EffectHandler:FindEffect("ParryCool") and EffectHandler:FindEffect("NoRoll") and Roll then
			SetBlockInput(ID, false, false)
			return
		end

		if
			(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
				and not EffectHandler:FindEffect("NoRoll")
			or not EffectHandler:FindEffect("Equipped")
		then
			Roll = true
		end

		if
			(EffectHandler:FindEffect("LightAttack", true) or EffectHandler:FindEffect("MidAttack"))
			and Toggles.AutoFeint.Value
		then
			if
				(EffectHandler:FindEffect("UsingSpell") and Toggles.AutoFeintMantra)
				or not EffectHandler:FindEffect("UsingSpell")
			then
				mouse2click()
			end
		end

		local ShouldRoll = math.random(0, 100) <= Options.RollPercentage.Value
		if ShouldRoll and not EffectHandler:FindEffect("NoRoll") and not Roll then
			Roll = true
		end

		local ShouldParry = math.random(0, 100) <= Options.ParryChance.Value
		if not Roll and not ShouldParry then
			return
		end

		if Roll then
			if not SanityCheck() then
				SetBlockInput(ID, false, false)
				return
			end

			task.spawn(Dodge)

			warn("Dodging " .. ProjectileConfig.Name .. " [" .. CalculatedTime .. "]", 1.5)

			task.wait(0.31)
			SetBlockInput(ID, false, false)
			return
		end

		for i = 1, ParryAmount do
			if not SanityCheck() then
				break
			end

			if not CheckFacing() then
				return
			end

			if EffectHandlerLogs.Stun then
				break
			end

			if
				(EffectHandler:FindEffect("ParryCool") and Toggles.RollOnParryCD.Value)
					and not EffectHandler:FindEffect("NoRoll")
				or not EffectHandler:FindEffect("Equipped")
			then
				task.spawn(Dodge)
			end

			if not EffectHandler:FindEffect("ParryCool") then
				task.spawn(Parry)
			end

			task.wait(i ~= ParryAmount and (RepeatDelay / 1000) or 0)
		end

		task.wait(Roll and 0.5 or 0.15)
	end

	if not MinRange or not MaxRange then
		return warn("Blocked projectile - range is not setup", 1.5)
	end

	local CurrentRange = (Character.Position - UserRootPart.Position).Magnitude
	if CurrentRange <= MinRange then
		return warn("Blocked projectile - range is below minimum", 1.5)
	end

	while task.wait() do
		CurrentRange = (Character.Position - UserRootPart.Position).Magnitude
		if CurrentRange >= MinRange and CurrentRange <= MaxRange then
			break
		end
	end

	AutoParryInit()

	SetBlockInput(ID, false, false)

	if Status[Character] and Status[Character].Maid then
		Status[Character].Maid:DoCleaning()
		Status[Character] = nil
	end
end

local function pingWait(n)
	local Ping = (game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() / 1000)
		* (Options.PingAdjustment.Value / 100)
	return task.wait(n - Ping)
end

local function checkRange(range, part)
	local myRootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if not myRootPart or not part then
		return false
	end

	if typeof(part) == "Vector3" then
		part = { Position = part }
	end

	return (myRootPart.Position - part.Position).Magnitude <= range
end

local function checkRangeFromPing(obj, rangeCheck, speed)
	local myRootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if not myRootPart then
		return false
	end

	local distance = (obj.Position - myRootPart.Position).Magnitude
	local playerPing = game:GetService("Stats"):WaitForChild("PerformanceStats"):WaitForChild("Ping"):GetValue() * 2

	distance = (obj.Position - myRootPart.Position).Magnitude
	distance = distance - speed * (playerPing / 1000)

	return distance <= rangeCheck, distance, playerPing / speed
end

local function OnCharacterAdded(Character)
	Character:WaitForChild("HumanoidRootPart", 9e9)
	task.wait(1)
	Maid[Character.Name .. "__EffectAdded"] = EffectHandler.EffectAdded:Connect(function(effect)
		if effect.Class == "Stun" then
			EffectHandlerLogs.Stun = true
			task.delay(0.12, function()
				EffectHandlerLogs.Stun = false
			end)
		end
	end)
	if Character ~= Players.LocalPlayer.Character then
		Maid[Character.Name .. "__ProjectileDescendantAdded"] = Character.DescendantAdded:Connect(RegisterProjectile)
		for i, v in next, Character:GetDescendants() do
			task.spawn(RegisterProjectile, v)
		end
		Maid[Character.Name .. "__SoundDescendantAdded"] = Character.DescendantAdded:Connect(RegisterSound)
		for i, v in next, Character:GetDescendants() do
			task.spawn(RegisterSound, v)
		end
	end
end

getgenv().RawParry = RawParry
getgenv().Parry = Parry
getgenv().Dodge = Dodge
getgenv().pingWait = pingWait
getgenv().logProjectile = LogProjectile
getgenv().logSound = LogSound
getgenv().checkRange = checkRange
getgenv().checkRangeFromPing = checkRangeFromPing

require("Modules/Deepwoken/CustomConfigs")

Maid.AutoParryChildAdded = workspace.Live.ChildAdded:Connect(Register)
for i, v in next, workspace.Live:GetChildren() do
	task.spawn(Register, v)
end

Maid.AutoParryThrown = workspace.Thrown.DescendantAdded:Connect(RegisterProjectile)
for i, v in next, workspace.Thrown:GetDescendants() do
	task.spawn(RegisterProjectile, v)
end

Maid.AutoParrySounds = workspace.DescendantAdded:Connect(RegisterSound)
for i, v in next, workspace:GetDescendants() do
	task.spawn(RegisterSound, v)
end

Maid.AutoParryCharAdded = Player.CharacterAdded:Connect(OnCharacterAdded)
if Player.Character then
	OnCharacterAdded(Player.Character)
end

end)
__bundle_register("Modules/Deepwoken/CustomConfigs", function(require, _LOADED, __bundle_register, __bundle_modules)
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
end)
__bundle_register("Modules/Deepwoken/KeyHandler", function(require, _LOADED, __bundle_register, __bundle_modules)
local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local KeyHandler = {}

function KeyHandler:Penetrate()
	local oldDestroy, OldNameCall, OldNewIndex, OldFireServer, OldUnreliFireServer, OldPCall
	pcall(function()
		game:GetService("Players").LocalPlayer.PlayerScripts.ClientActor.ClientManager.Enabled = false
	end)

	warn("Test")

	if not shared.GetKey then
		warn("No shared GetKey")
		return Player:Kick("Failed to penetrate Anticheat, There is no GetKey from loader!")
	end

	warn("Sigma")

	local Success, Response = SecureCall(function()
		local Character = Player.Character
		local CharacterHandler = Character and Character:FindFirstChild("CharacterHandler", math.huge)

		Player.CharacterAdded:Connect(function(character)
			Character = character
			CharacterHandler = character:WaitForChild("CharacterHandler", math.huge)
		end)

		local function LocalAnim(Args)
			return SecureCall(LPH_NO_VIRTUALIZE(function()
				local Gestures = game:GetService("ReplicatedStorage").Assets.Anims.Gestures
				local Gesture = Gestures:FindFirstChild(Args[1])
				local Humanoid = Player.Character and Player.Character:WaitForChild("Humanoid")
				local EffectHandler = getgenv().require(game.ReplicatedStorage.EffectReplicator)
				if not Humanoid or EffectHandler:FindEffect("Gesturing") then
					return
				end

				-- Create effects...
				local act1 = EffectHandler:CreateEffect("Action")
				local act2 = EffectHandler:CreateEffect("Gesturing")
				local act3 = EffectHandler:CreateEffect("MobileAction")

				-- Stop animations...
				for i, v in pairs(Humanoid:GetPlayingAnimationTracks()) do
					if v.Animation.Parent == Gestures then
						v:Stop()
					end
				end
				
				-- Animation...
				Humanoid:LoadAnimation(Gesture):Play()
				
				-- Stop...
				repeat
					task.wait()
				until Humanoid.MoveDirection.Magnitude > 0

				task.wait(.5)

				-- Remove effects...
				act1:Remove()
				act2:Remove()
				act3:Remove()

				-- Stop animations...
				for i, v in pairs(Humanoid:GetPlayingAnimationTracks()) do
					if v.Animation.Parent == Gestures then
						v:Stop()
					end
				end
			end))
		end

		local r32_0 = game:GetService("ReplicatedStorage")
		local r44_0 = r32_0:WaitForChild("Requests", 999999999999)
		local banRemotes = {}
		local banRemoteCount = 0
	
		for i,v in next, r44_0:GetChildren() do
			local hasChangedConnection = #getconnections(v.Changed)
			if hasChangedConnection >= 1 then
				banRemoteCount = banRemoteCount + 1
			end
		end

		warn("Sigma 2: " .. banRemoteCount)

		if banRemoteCount ~= 2 then
			return Player:Kick("Anticheat has less or more than two ban remotes?")
		end

		local function onNameCall(Self, ...)
			local Args = { ... }

			if not checkcaller() then
				local method = getnamecallmethod()

				if Self == RunService and method == "IsStudio" then
					return true
				end

				if banRemotes[Self] then
					return
				end

				if Self.Name == "AcidCheck" and (SouLoaded and Toggles.NoAcid.Value) then
					return
				end

				if typeof(Args[1]) == "number" and typeof(Args[2]) == "boolean" and (SouLoaded and Toggles.NoFallDamage.Value) then
					return
				end
			
				if Self.Name == "Gesture" and SouLoaded and Toggles.UnlockEmotes.Value and Args[1] then
					task.spawn(LocalAnim, Args)
				end
				
				if Self.Name == "ServerSprint" and (Self.ClassName == "UnreliableRemoteEvent" or Self.ClassName == "RemoteEvent") and SouLoaded and Toggles.RunAttack.Value then
					return OldNameCall(Self, true)
				end
			end
			
			if getgenv().LeftClickRemote and Self == getgenv().LeftClickRemote then
				if getgenv().Status and getgenv().Status.Busy and (Toggles and Toggles.BlockInput.Value) then
					return
				end
				if Args[3] and Args[3].ctrl and (Toggles and Toggles.UppercutDashCasting.Value) then
					task.spawn(getgenv().DashcastFunction,"uppercut",1.2)
				end
				if getgenv().EffectHandlerHash.SprintSpeed and (Toggles and Toggles.RunningDashCasting.Value) then
					task.spawn(getgenv().DashcastFunction,"runningattack",1)
				end
			end

			return OldNameCall(Self, ...)
		end

		local function onFireServer(Self, ...)
			local Args = { ... }
			
			if not checkcaller() then
				if banRemotes[Self] then
					return
				end
			end
			
			if getgenv().LeftClickRemote and Self == getgenv().LeftClickRemote then
				if getgenv().Status and getgenv().Status.Busy and (Toggles and Toggles.BlockInput.Value) then
					return
				end
				if Args[3] and Args[3].ctrl and (Toggles and Toggles.UppercutDashCasting.Value) then
					task.spawn(getgenv().DashcastFunction,"uppercut",1.2)
				end
				if getgenv().EffectHandlerHash.SprintSpeed and (Toggles and Toggles.RunningDashCasting.Value) then
					task.spawn(getgenv().DashcastFunction,"runningattack",1)
				end
			end

			return OldFireServer(Self, ...)
		end
		
		local function onUnreliFireServer(Self, ...)
			if not checkcaller() then
				if banRemotes[Self] then
					return
				end
			end

			return OldUnreliFireServer(Self, ...)
		end

		local Lighting = game:GetService('Lighting')
		local function onNewIndex(Self, Index, Value)
			if CharacterHandler and (Self == CharacterHandler and Index == "Parent") then
				return
			end

			if (Self == Lighting and Index == 'Ambient' and (SouLoaded and Toggles.FullBright.Value) ) then
				local value = 5 * 10
				value = value + 100 + Options.FullBright.Value
	
				Value = Color3.fromRGB(value, value, value)
			end

			if Self == Player and Index == "CameraMaxZoomDistance" and SouLoaded and Toggles.RemoveZoomLimit.Value then
				Value = 495
			end

			return OldNewIndex(Self, Index, Value)
		end

		local function onDestroy(Self)
			if CharacterHandler and Self == CharacterHandler then
				return
			end

			return oldDestroy(Self)
		end

		local FireServer = Instance.new("RemoteEvent").FireServer
		local FireServer_Unreliable = Instance.new("UnreliableRemoteEvent").FireServer
		local Destroy = game.Destroy

		--OldPCall = hookfunction(pcall, onPCall)
		oldDestroy = hookfunction(Destroy,newcclosure(onDestroy))
		OldFireServer = hookfunction(FireServer, newcclosure(onFireServer))
		OldUnreliFireServer = hookfunction(FireServer_Unreliable, newcclosure(onUnreliFireServer))
		OldNameCall = hookfunction(getrawmetatable(game).__namecall, newcclosure(onNameCall))
		OldNewIndex = hookfunction(getrawmetatable(game).__newindex, newcclosure(onNewIndex))

		print("Penetrated Anticheat")
	end)

	if not Success then
		Player:Kick("Failed to penetrate Anticheat, please report this to the developer. Error: " .. tostring(Response or "N/A"))
		return
	else
		return oldDestroy, OldNameCall, OldNewIndex, OldFireServer, OldUnreliFireServer
	end
end

function KeyHandler:PenetrateActor()
	
end

function KeyHandler.GetKey(RemoteName)
	return LPH_NO_VIRTUALIZE(function()
		local Remote = shared.GetKey(RemoteName)
		if Remote then
			return Remote
		end
	end)()
end

return KeyHandler

end)
__bundle_register("Features/ESP", function(require, _LOADED, __bundle_register, __bundle_modules)
local RunESP = LPH_NO_VIRTUALIZE(function()
    --require("Modules/Drawing")

    print("esp startup")

	local players = game:GetService("Players")
	local local_player = players.LocalPlayer
	local current_camera = workspace.CurrentCamera
	local RequireMaid = require("Modules/Maid")
    local alreadyadded = {}

	local function floor2(v)
		return Vector2.new(math.floor(v.X), math.floor(v.Y))
	end

	local storage = {}
	local esp_maid = RequireMaid.new()
	local esp = {}

	local function GetColor(CharacterTraits)
		for i, v in next, CharacterTraits do
			if not Options["EspColor_" .. i] then
				continue
			end
			CharacterTraits.Color = Options["EspColor_" .. i].Value
		end
		return CharacterTraits.Color
	end

	local function GetActiveFeats(CharacterTraits)
		local BoxEnabled = false
		local HealthEnabled = false
		local DistanceEnabled = false
		local TracerEnabled = false

		for i, v in next, CharacterTraits do
			if Toggles["EspBox_" .. i] then
				BoxEnabled = BoxEnabled or Toggles["EspBox_" .. i].Value
			end
			if Toggles["EspTracer_" .. i] then
				TracerEnabled = TracerEnabled or Toggles["EspTracer_" .. i].Value
			end
			if Toggles["EspHealth_" .. i] then
				HealthEnabled = HealthEnabled or Toggles["EspHealth_" .. i].Value
			end
			if Toggles["EspDistance_" .. i] then
				DistanceEnabled = DistanceEnabled or Toggles["EspDistance_" .. i].Value
			end
		end

		return BoxEnabled, HealthEnabled, DistanceEnabled, TracerEnabled
	end

	do
		esp.__index = esp
        local cache = {}
		---@param Character Model
		function esp.new(Character)
			if Character == local_player.Character or cache[Character] then
				return
			end
			
			if storage[Character] then
				return
			end

			if alreadyadded[Character] then
				return
			end

            cache[Character] = true
			alreadyadded[Character] = true

			local self = setmetatable({}, esp)
			self.Active = true
			self.Character = Character

			-- apply tags...
			self:apply_tags()

			-- don't setup if there is no tag setup...
			if
				not self.mob
				and not self.player
				and not self.ingredient
				and not self.npc
				and not self.whirlpool
				and not self.mantra_obelisk
				and not self.explosive
				and not self.armor_brick
				and not self.chest
				and not self.artifact
				and not self.owl
				and not self.bell_meteor
				and not self.rare_obelisk
				and not self.obelisk
				and not self.heal_brick
				and not self.area
				and not self.banner
				and not self.door
				and not self.br_weapon
                and not self.jobboard
			then
                cache[Character] = nil
				alreadyadded[Character] = nil
				return
			end

			if Character and Character:IsA('Model') then -- so they don't get streamed out
				Character.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
			end

			-- setup character...
            cache[Character] = nil
			self:setup_character()
		end
		function esp:apply_tags()
			return (function()
				self.player = players:GetPlayerFromCharacter(self.Character) or nil
				if self.player then
					local real_guild = CachedPlayersData[self.player] and CachedPlayersData[self.player].OriginalGuild or self.player:GetAttribute("Guild")
					local real_local_guild = CachedPlayersData[local_player] and CachedPlayersData[local_player].OriginalGuild or local_player:GetAttribute("Guild")
					self.friendly = self.player and real_guild == real_local_guild or nil
				end
				self.mob = self.Character.Name:sub(1, 1) == "." or nil
				self.ingredient = self.Character.Parent == workspace.Ingredients or nil
				self.npc = self.Character.Parent == workspace.NPCs or nil
				self.whirlpool = self.Character.Name == "DepthsWhirlpool" or nil
				self.mantra_obelisk = self.Character.Name == "MantraObelisk" or nil
				self.explosive = self.Character.Name == "ExplodeCrate" or nil
				self.armor_brick = self.Character.Name:match("ArmorBrick") or nil
				self.chest = self.Character:FindFirstChild("LootUpdated") or nil
				self.artifact = self.Character.Name == "BigArtifact" or nil
				self.owl = self.Character.Name == "EventFeatherRef" or nil
				self.bell_meteor = self.Character.Name == "BellMeteor" or nil
				self.rare_obelisk = self.Character.Name == "RareObelisk" or nil
				self.heal_brick = self.Character.Name == "HealBrick" or nil
				self.obelisk = self.Character.Name == "Obelisk" or nil
				self.jobboard = self.Character.Name == "JobBoard" or nil
				self.area = self.Character.Parent
						and self.Character.Parent.Parent
						and self.Character.Parent.Parent.Name == "AreaMarkers"
					or nil
				self.banner = self.Character.Name == "GuildBanner" or nil
				self.door = self.Character.Name:match("GuildDoor") or nil
				self.br_weapon = self.Character:IsA("MeshPart")
						and self.Character:FindFirstChild("InteractPrompt")
						and (not self.Character.Name:match("ArmorBrick"))
						and (not self.Character.Name:match("Barrel"))
						and not self.ingredient
					or nil

				if
					self.chest
					or self.whirlpool
					or self.jobboard
					or self.artifact
					or self.obelisk
					or self.armor_brick
					or self.bell_meteor
					or self.rare_obelisk
					or self.heal_brick
					or self.banner
					or self.mantra_obelisk
					or self.br_weapon
				then
					self.use_pivot = true
				end
			end)()
		end
		function esp:find_primarypart()
			return (function()
				if self.chest then
					return nil
				end
				if self.whirlpool then
					return nil
				end
				if self.banner then
					return nil
				end
				if self.artifact then
					return nil
				end
				if self.obelisk or self.rare_obelisk or self.heal_brick or self.bell_meteor then
					return nil
				end
				if self.mantra_obelisk then
					return nil
				end
				if self.br_weapon or self.armor_brick then
					return self.Character
				end
				if self.ingredient or self.area or self.explosive or self.owl or self.door then
					return self.Character
				end
				if self.npc then
					return self.Character:WaitForChild("HumanoidRootPart", 9e9)
				end
				if self.player or self.mob or self.npc then
					self.Humanoid = self.Character:WaitForChild("Humanoid", 9e9)
					return self.Character:WaitForChild("HumanoidRootPart", 9e9)
				end
			end)()
		end
		function esp:setup_character()

			return task.spawn(function()
				if storage[self.Character] then return end

				task.wait(Random.new():NextNumber(0, 0.1))

				if storage[self.Character] then return end

				self.primary_part = self:find_primarypart()
				local primary_box = Drawing.new("Square")
				primary_box.Thickness = 1
				primary_box.Size = Vector2.new(40, 50)
				primary_box.Color = Color3.new(1, 1, 1)
				primary_box.Filled = false
				primary_box.Visible = false
				primary_box.Position = Vector2.new(900, 900)

				local primary_text = Drawing.new("Text")
				primary_text.Text = ""
				primary_text.Color = Color3.new(1, 1, 1)
				primary_text.OutlineColor = Color3.new(0, 0, 0)
				primary_text.Center = true
				primary_text.Outline = true
				primary_text.Position = Vector2.new(900, 900)
				primary_text.Size = 11
				primary_text.Font = Drawing.Fonts.System

				local health_outline = Drawing.new("Line")
				health_outline.Color = Color3.new(0.105882, 0.105882, 0.105882)
				health_outline.Thickness = 16

				local tracer = Drawing.new("Line")
				tracer.Color = Color3.new(0.105882, 0.105882, 0.105882)
				tracer.Thickness = 5

				local health_bar = Drawing.new("Line")
				health_bar.Thickness = 14

				self.primary_text = primary_text
				self.primary_box = primary_box
				self.health_outline = health_outline
				self.health_bar = health_bar
				self.tracer = tracer

				storage[self.Character] = self
				
				if self.player then
					self.player.AncestryChanged:Connect(function()
						if self.player.Parent ~= players then
							self.Active = false
							storage[self.Character or "."] = nil
							alreadyadded[self.Character or "."] = nil
						end
					end)
					self.Character.AncestryChanged:Connect(function()
						if not self.Character or not self.Character:IsDescendantOf(workspace) then
							self.Active = false
							storage[self.Character or "."] = nil
							alreadyadded[self.Character or "."] = nil
						end
					end)
				else
					self.Character.AncestryChanged:Connect(function()
						if not self.Character or not self.Character:IsDescendantOf(workspace) then
							self.Active = false
							storage[self.Character or "."] = nil
							alreadyadded[self.Character or "."] = nil
						end
					end)
				end

				self:update_esp()
			end)
		end
		function esp:visibility_check()
			return (function()
				local Position = self.use_pivot and self.Character:GetPivot().p or self.primary_part.Position
				local _, OnScreen = current_camera:WorldToViewportPoint(Position)
				self.Distance = math.floor((current_camera.CFrame.p - Position).Magnitude)
				local Visible = false

				if self.area and Toggles["AreaEsp_" .. self.Character.Parent.Name] then
					return Toggles.ESPEnabled.Value,
						Toggles["AreaEsp_" .. self.Character.Parent.Name].Value
							and Toggles["Esp_area"].Value
							and self.Distance <= Options["Esp_area"].Value,
						OnScreen
				end

				if self.ingredient and Toggles["IngredientEsp_" .. self.Character.Name] then
					return Toggles.ESPEnabled.Value,
						Toggles["IngredientEsp_" .. self.Character.Name].Value
							and Toggles["Esp_ingredient"].Value
							and self.Distance <= Options["Esp_ingredient"].Value,
						OnScreen
				end

				for i, v in next, self do
					if not Toggles["Esp_" .. i] then
						continue
					end

					Visible = Toggles["Esp_" .. i].Value and self.Distance <= Options["Esp_" .. i].Value
					if Visible then
						break
					end
				end

				return Toggles.ESPEnabled.Value and not Toggles.CustomESP.Value, Visible, OnScreen
			end)()
		end
		function esp:get_name()
			local base_normal_format = "%s [%i/%i]"
			local normal_format = "%s [%i/%i] [%i]"
			local misc_format = "%s [%i]"
			local _, _, DistanceEnabled, _ = GetActiveFeats(self)
			if self.mob then
				self.MaxHealth = math.floor(self.Humanoid.MaxHealth)
				self.Health = math.floor(self.Humanoid.Health)
				return DistanceEnabled
						and normal_format:format(self.Character:GetAttribute("MOB_rich_name"), self.Health, self.MaxHealth, self.Distance)
					or base_normal_format:format(self.Character:GetAttribute("MOB_rich_name"), self.Health, self.MaxHealth)
			end
			if self.player then
				self.MaxHealth = math.floor(self.Humanoid.MaxHealth)
				self.Health = math.floor(self.Humanoid.Health)
				local Power = self.Character:GetAttribute('Level')
				local name = DistanceEnabled
						and normal_format:format(
							self.player:GetAttribute("CharacterName") or "N/A",
							self.Health,
							self.MaxHealth,
							self.Distance
						)
					or base_normal_format:format(self.player:GetAttribute("CharacterName") or "N/A", self.Health, self.MaxHealth)
				return name .. " Power " .. tostring(Power)
			end
			if self.npc or self.ingredient then
				return DistanceEnabled and misc_format:format(self.Character.Name, self.Distance) or self.Character.Name
			end
			if self.area then
				return DistanceEnabled and misc_format:format(self.Character.Parent.Name, self.Distance)
					or self.Character.Parent.Name
			end
			if self.chest then
				return DistanceEnabled and misc_format:format("Chest", self.Distance) or "Chest"
			end
			if self.owl then
				return DistanceEnabled and misc_format:format("Owl", self.Distance) or "Owl"
			end
			if self.whirlpool then
				return DistanceEnabled and misc_format:format("Whirlpool", self.Distance) or "Whirlpool"
			end
			if self.door then
				return DistanceEnabled
						and misc_format:format(self.Character.Name:sub(11, 200) .. " Guild Door", self.Distance)
					or self.Character.Name:sub(11, 200) .. " Guild Door"
			end
			if self.banner then
				return DistanceEnabled and misc_format:format("Guild Banner", self.Distance) or "Guild Banner"
			end
			if self.explosive then
				return DistanceEnabled and misc_format:format("Explosive Crate", self.Distance) or "Explosive Crate"
			end
			if self.obelisk then
				return DistanceEnabled and misc_format:format("Obelisk", self.Distance) or "Obelisk"
			end
			if self.rare_obelisk then
				return DistanceEnabled and misc_format:format("Rare Obelisk", self.Distance) or "Rare Obelisk"
			end
			if self.bell_meteor then
				return DistanceEnabled and misc_format:format("Bell Meteor", self.Distance) or "Ball Meteor"
			end
			if self.heal_brick then
				return DistanceEnabled and misc_format:format("Heal Brick", self.Distance) or "Heal Brick"
			end
			if self.jobboard then
				return DistanceEnabled and misc_format:format("Job Board", self.Distance) or "Job Board"
			end
			if self.armor_brick then
				local billboard_gui = self.Character:FindFirstChild("BillboardGui")
				if not billboard_gui then
					return DistanceEnabled and misc_format:format("Unknown Armor Brick (1)", self.Distance)
						or "Unknown Armor Brick (1)"
				end

				local text_label = billboard_gui:FindFirstChild("TextLabel")
				if not text_label then
					return DistanceEnabled and misc_format:format("Unknown Armor Brick (2)", self.Distance)
						or "Unknown Armor Brick (2)"
				end

				return DistanceEnabled and misc_format:format(text_label.Text, self.Distance) or text_label.Text
			end
			if self.artifact then
				return DistanceEnabled and misc_format:format("Artifact", self.Distance) or "Artifact"
			end
			if self.mantra_obelisk then
				return DistanceEnabled and misc_format:format("Mantra Obelisk", self.Distance) or "Mantra Obelisk"
			end
			if self.br_weapon then
				return DistanceEnabled and misc_format:format(self.Character.Name, self.Distance) or self.Character.Name
			end
		end
		function esp:update_esp()
			debug.profilebegin("ESP_UPDATE")
			while self.Active do
				if not self.Character or (not self.primary_part and not self.use_pivot) then
					self.Active = false
					storage[self.Character or "."] = nil
					alreadyadded[self.Character or "."] = nil
					break
				end
				
				if (self.player or self.mob) and not self.Humanoid then
					self.Active = false
					storage[self.Character or "."] = nil
					alreadyadded[self.Character or "."] = nil
					break
				end

				if self.Humanoid and self.Humanoid.Health <= 0 then
					self.Active = false
					storage[self.Character or "."] = nil
					alreadyadded[self.Character or "."] = nil
					break
				end

				local espenabled, visible, onscreen = self:visibility_check()
				if not espenabled or not visible or not onscreen then
					local esp_priority = self.player
					local refreshrate = not espenabled and 1 or not visible and 0.5 or not onscreen and 0.05
					self.primary_box.Visible = false
					self.primary_text.Visible = false
					self.health_outline.Visible = false
					self.health_bar.Visible = false
					self.tracer.Visible = false
					wait(esp_priority and refreshrate or refreshrate * 2)
					continue
				end

				if self.use_pivot and self.Character and self.Character:IsA("Model") and self.Character.ModelStreamingMode ~= Enum.ModelStreamingMode.Persistent then
					self.Character.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
				end

				local original_pos = self.use_pivot and self.Character:GetPivot().p or self.primary_part.Position
				local vp_pos = current_camera:WorldToViewportPoint(original_pos)
				local head_pos = current_camera:WorldToViewportPoint(original_pos + Vector3.new(0, 3, 0))
				local leg_pos = current_camera:WorldToViewportPoint(original_pos - Vector3.new(0, 0.5, 0))

				local BoxEnabled, HealthEnabled, DistanceEnabled, TracerEnabled = GetActiveFeats(self)
				self.primary_text.Color = GetColor(self)
				self.primary_text.Size = Options.EspTextSize.Value
				self.primary_text.Position = Vector2.new(head_pos.X, head_pos.Y)
				self.primary_text.Text = self:get_name()
				self.primary_text.Font = Drawing.Fonts.System
				self.primary_text.Visible = true

				self.primary_box.Visible = BoxEnabled
				self.primary_box.Filled = false
				self.primary_box.Color = GetColor(self)
				self.primary_box.Size = Vector2.new(1000 / vp_pos.Z, head_pos.Y - leg_pos.Y)
				self.primary_box.Position =
					Vector2.new(vp_pos.X - self.primary_box.Size.X / 2, vp_pos.Y - self.primary_box.Size.Y / 2)

				if TracerEnabled and self.Distance < 550 then
					local TorsoPos, Vis6 = current_camera:WorldToViewportPoint(original_pos)

					if Vis6 then
						self.tracer.Visible = true
						self.tracer.From = Vector2.new(TorsoPos.X, TorsoPos.Y)
						self.tracer.Thickness = Options.EspTracerSize.Value
						self.tracer.To = Vector2.new(
							current_camera.ViewportSize.X / 2,
							current_camera.ViewportSize.Y / Options.EspTracerOffset.Value
						)
						self.tracer.Color = GetColor(self)
					else
						self.tracer.Visible = false
					end
				else
					self.tracer.Visible = false
				end
				if self.Health and HealthEnabled and self.Distance < 300 then
					self.health_outline.Thickness = 123 / self.Distance + 2
					self.health_bar.Thickness = 123 / self.Distance + 1
					self.health_outline.Visible = true
					self.health_bar.Visible = true
					local FRUSTUM_HEIGHT = math.tan(math.rad(current_camera.FieldOfView * 0.5)) * 2 * vp_pos.Z
					local SIZE = current_camera.ViewportSize.Y / FRUSTUM_HEIGHT * Vector2.new(4, 4)
					self.health_outline.From = floor2(Vector2.new(vp_pos.X, vp_pos.Y) - SIZE * 0.5) - Vector2.xAxis * 5
					self.health_outline.To = floor2(Vector2.new(vp_pos.X, vp_pos.Y) - SIZE * Vector2.new(0.5, -0.5))
						- Vector2.xAxis * 5
					self.health_bar.From = self.health_outline.To
					self.health_bar.Color = Color3.new(1, 0.007843, 0.007843)
						:Lerp(Color3.new(0.219607, 1, 0.478431), self.Health / self.MaxHealth)
					self.health_bar.To =
						floor2(self.health_outline.To:Lerp(self.health_outline.From, self.Health / self.MaxHealth))
					self.health_outline.From = self.health_outline.From - Vector2.yAxis
					self.health_outline.To = self.health_outline.To + Vector2.yAxis
				else
					self.health_outline.Visible = false
					self.health_bar.Visible = false
				end
				task.wait(Toggles.FastESP.Value and 0 or 0.05)
			end
			self.tracer.Visible = false
			self.health_outline.Visible = false
			self.health_bar.Visible = false
			self.primary_text.Visible = false
			self.primary_box.Visible = false
		end
		debug.profileend()
	end

	local function scan_folder(Folder, ChildAdded, NameFilter, callback_filter)
		SecureCall(function()
			for i, v in pairs(Folder:GetChildren()) do
				if NameFilter and v.Name ~= NameFilter then
					continue
				end
				if callback_filter and not callback_filter(v) then
					continue
				end
                if alreadyadded[v] then continue end
				SecureSpawn(esp.new, v)
			end
			if ChildAdded then
				esp_maid:GiveTask(Folder.ChildAdded:Connect(function(v)
					if NameFilter and v.Name ~= NameFilter then
						return
					end
					if callback_filter and not callback_filter(v) then
						return
					end
                    if alreadyadded[v] then return end
					SecureSpawn(esp.new, v)
				end))
			end
		end)
	end

    print("esp scan")
    getgenv().ESPLoaded = true
	scan_folder(workspace.Live, true)
	scan_folder(workspace.NPCs, true)
	scan_folder(workspace.Ingredients, true, "Galewax")
	if workspace:FindFirstChild("Layer2Floor2") then
		scan_folder(workspace.Layer2Floor2, true, "Obelisk")
	end
	scan_folder(workspace, true)
	scan_folder(workspace.Thrown, true, nil, function(v)
		if
			v.Name == "EventFeatherRef"
			or v.Name == "PieceofForge"
			or v:FindFirstChild("LootUpdated")
			or v.Name == "ExplodeCrate"
			or v.Name == "BellMeteor"
		then
			return true
		end
		return false
	end)

    local AreaMarkers = game:GetService('ReplicatedStorage'):WaitForChild("MarkerWorkspace"):WaitForChild("AreaMarkers")
    
	for _, v in pairs(AreaMarkers:GetChildren()) do
		if v.Name:match("'s Base") or not v:FindFirstChild("AreaMarker") then
			continue
		end
		SecureSpawn(esp.new, v:FindFirstChild("AreaMarker"))
	end

	task.spawn(function()
		for i, v in pairs(AreaMarkers:GetChildren()) do
			if v.Name:match("'s Base") or not v:FindFirstChild("AreaMarker") then
				continue
			end
			SecureSpawn(esp.new, v:FindFirstChild("AreaMarker"))
		end

		while wait(3) and getgenv().ESPLoaded do
			if workspace:FindFirstChild("Layer2Floor2") then
                scan_folder(workspace.Layer2Floor2, false, "Obelisk")
            end
            scan_folder(workspace, false, nil, function(v)
                if
                    v.Name == 'JobBoard'
                    or v.Name:match('GuildDoor')
                    or v:IsA("MeshPart")
                    and v:FindFirstChild("InteractPrompt")
                    and (not v.Name:match("ArmorBrick"))
                    and (not v.Name:match("Barrel"))
                then
                    return true
                else
                    return false
                end
            end)
            scan_folder(workspace.Thrown, false, nil, function(v)
                if
                    v.Name == "EventFeatherRef"
                    or v.Name == "BigArtifact"
                    or v:FindFirstChild("LootUpdated")
                    or v.Name == "ExplodeCrate"
                    or v.Name == "BellMeteor"
                then
                    return true
                end
                return false
            end)
		end
	end)

    print("esp done")
	getgenv().Maid.ESP = function()
        getgenv().ESPLoaded = nil

		for _, v in pairs(storage) do
			v.Active = false
		end

		cleardrawcache()
		esp_maid:DoCleaning()
	end
end)

getgenv().StartESP = RunESP

return SecureCall(RunESP)
end)
__bundle_register("Modules/Deepwoken/AutoParryBuilder", function(require, _LOADED, __bundle_register, __bundle_modules)
local HttpService = game:GetService("HttpService")

local Builder = {}
local InterfaceHandler = {}

local function cleanup(v)
	v = v:gsub("Deepwoken", "")
	v = v:gsub("Lycoris", "")
	v = v:gsub("ProjectileConfigs", "")
	v = v:gsub("M1Configs", "")
	v = v:gsub("SoundConfigs", "")
	v = v:gsub("Configs", "")

	v = v:gsub("\\", "")
	v = v:gsub("/", "")
	v = v:gsub(".lyc", "")

	return v
end

task.spawn(function()
	repeat
		task.wait()
	until getgenv().Config and getgenv().ProjectileConfigs and getgenv().SoundConfigs

	local TotalConfigsLoaded = 0

	Builder = {
		projectileConfigs = getgenv().ProjectileConfigs,
		soundConfigs = getgenv().SoundConfigs,
		config = getgenv().Config,
		pingWait = getgenv().pingWait,
		checkRange = getgenv().checkRange,
		checkRangeFromPing = getgenv().checkRangeFromPing,
		aes = getgenv().aes,
		aes_key = "lycoris_recoil_encryption_key_HASHed1920003819026004028310023084123000",
		config_path = "/Lycoris/Deepwoken/Configs/",
		config_path2 = "/Lycoris/Deepwoken/Configs",
		config_path3 = "/Lycoris/Deepwoken/M1Configs/",
		config_path4 = "/Lycoris/Deepwoken/M1Configs",
		config_path5 = "/Lycoris/Deepwoken/ProjectileConfigs/",
		config_path6 = "/Lycoris/Deepwoken/ProjectileConfigs",
		config_path7 = "/Lycoris/Deepwoken/SoundConfigs/",
		config_path8 = "/Lycoris/Deepwoken/SoundConfigs"
	}

	for i,v in next, Builder do
		if getexecutorname():match("Swift") or getexecutorname():match("Volcano") or getexecutorname():match("Zenith") then
			if i:match("config_path") then
				Builder[i] = string.format(".%s", v)
			end
		end

		if getexecutorname():match("Wave") or getexecutorname():match("Hydrogen") then
			if i:match("config_path") then
				Builder[i] = string.sub(v, 2, #v)
			end
		end
	end

	if not isfolder("Lycoris/Deepwoken/Configs") then
		makefolder("Lycoris/Deepwoken/Configs")
	end

	if not isfolder("Lycoris/Deepwoken/M1Configs") then
		makefolder("Lycoris/Deepwoken/M1Configs")
	end

	if not isfolder("Lycoris/Deepwoken/ProjectileConfigs") then
		makefolder("Lycoris/Deepwoken/ProjectileConfigs")
	end

	if not isfolder("Lycoris/Deepwoken/SoundConfigs") then
		makefolder("Lycoris/Deepwoken/SoundConfigs")
	end

	function Builder:DecryptConfig(Config) -- this one should use the config name
		local config_file = Builder.config_path .. Config .. ".lyc"
		if not isfile(config_file) then
			Library:Notify("Config file not found: " .. Config .. ".lyc [Decryption]", 2)
			return false
		end

		Config = readfile(config_file)
		return  HttpService:JSONDecode(Builder.aes.decrypt(Builder.aes_key, Config, 16, 2))
	end

	function Builder:DecryptProjectileConfig(Config) -- this one should use the config name
		local config_file = Builder.config_path5 .. Config .. ".lyc"
		if not isfile(config_file) then
			Library:Notify("Config file not found: " .. Config .. ".lyc [ProjectileDecryption]", 2)
			return false
		end

		Config = readfile(config_file)
		return HttpService:JSONDecode(Builder.aes.decrypt(Builder.aes_key, Config, 16, 2))
	end

	function Builder:DecryptSoundConfig(Config) -- this one should use the config name
		local config_file = Builder.config_path7 .. Config .. ".lyc"
		if not isfile(config_file) then
			Library:Notify("Config file not found: " .. Config .. ".lyc [SoundDecryption]", 2)
			return false
		end

		Config = readfile(config_file)
		return HttpService:JSONDecode(Builder.aes.decrypt(Builder.aes_key, Config, 16, 2))
	end

	function Builder:EncryptConfig(Config) -- this one should use the table for animation config
		return Builder.aes.encrypt(Builder.aes_key, HttpService:JSONEncode({ Config }), 16, 2)
	end

	function Builder:GetConfig(Config) -- this one should use the config name
		local config_file = Builder.config_path .. Config .. ".lyc"
		if not isfile(config_file) then
			Library:Notify("Config file not found: " .. Config .. ".lyc [GetConfig]", 2)
			return false
		end

		return readfile(config_file)
	end

	function Builder:CreateConfig(Config, AnimConfig, noNotify) -- this one should use the config name, the table for animation config
		local config_file = Builder.config_path .. Config .. ".lyc"
		-- if isfile(config_file) and not Toggles.OverwriteConfig.Value then
		--     Library:Notify('Config file already exists: ' .. Config .. '.lyc [CreateConfig]',2)
		--     return false
		-- end

		writefile(config_file, Builder:EncryptConfig(AnimConfig))
		if not noNotify then
			Library:Notify("Created Config: " .. Config .. ".lyc", 2)
		end

		Builder:LoadConfig(Config)

		return true
	end

	function Builder:CreateProjectileConfig(Config, ProjectileConfig, noNotify) -- this one should use the config name, the table for animation config
		local config_file = Builder.config_path5 .. Config .. ".lyc"
		-- if isfile(config_file) and not Toggles.OverwriteConfig.Value then
		--     Library:Notify('Config file already exists: ' .. Config .. '.lyc [CreateConfig]',2)
		--     return false
		-- end

		writefile(config_file, Builder:EncryptConfig(ProjectileConfig))
		if not noNotify then
			Library:Notify("Created Config: " .. Config .. ".lyc", 2)
		end

		Builder:LoadProjectileConfig(Config)

		return true
	end

	function Builder:CreateSoundConfig(Config, SoundConfig, noNotify) -- this one should use the config name, the table for animation config
		local config_file = Builder.config_path7 .. Config .. ".lyc"
		-- if isfile(config_file) and not Toggles.OverwriteConfig.Value then
		--     Library:Notify('Config file already exists: ' .. Config .. '.lyc [CreateConfig]',2)
		--     return false
		-- end

		writefile(config_file, Builder:EncryptConfig(SoundConfig))
		if not noNotify then
			Library:Notify("Created Config: " .. Config .. ".lyc", 2)
		end

		Builder:LoadSoundConfig(Config)

		return true
	end

	function Builder:DecodeProjectileConfig(Config, noNotify) -- this one should use the config name
		local config_file = Builder.config_path5 .. Config .. ".lyc"
		local ProjectileConfig = Builder:DecryptConfig(Config)

		writefile(config_file, HttpService:JSONEncode(ProjectileConfig))
		if not noNotify then
			Library:Notify("Decoded Config: " .. Config .. ".lyc", 2)
		end
		return true
	end

	function Builder:DecodeSoundConfig(Config, noNotify) -- this one should use the config name
		local config_file = Builder.config_path7 .. Config .. ".lyc"
		local SoundConfig = Builder:DecryptConfig(Config)

		writefile(config_file, HttpService:JSONEncode(SoundConfig))
		if not noNotify then
			Library:Notify("Decoded Config: " .. Config .. ".lyc", 2)
		end
		return true
	end

	function Builder:DecodeConfig(Config, noNotify) -- this one should use the config name
		local config_file = Builder.config_path .. Config .. ".lyc"
		local AnimConfig = Builder:DecryptConfig(Config)

		writefile(config_file, HttpService:JSONEncode(AnimConfig))
		if not noNotify then
			Library:Notify("Decoded Config: " .. Config .. ".lyc", 2)
		end
		return true
	end

	function Builder:BundleConfig(Configs, ConfigName) -- this one should use the config names in a table
		local Result = {}

		for i, v in pairs(Configs) do
			local config_file = Builder:DecryptConfig(v)
			if not config_file then
				continue
			end

			table.insert(Result, config_file)
		end

		Builder:CreateConfig(ConfigName, Result, true)
		Library:Notify("Config bundled: " .. ConfigName .. ".lyc", 2)
	end

	function Builder:LoadProjectileConfig(Config) -- this one should use the config name
		local config_set = Builder:DecryptProjectileConfig(Config)

		if not config_set then
			Library:Notify("Config file not found: " .. Config .. ".lyc [LoadProjectileConfig]", 4)
			return false
		end

		for _, b in pairs(config_set) do
			for i, v in pairs(b) do
				getgenv().ProjectileConfigs[i] = v
			end
		end

		TotalConfigsLoaded = TotalConfigsLoaded + 1
	end

	function Builder:LoadSoundConfig(Config) -- this one should use the config name
		local config_set = Builder:DecryptSoundConfig(Config)

		if not config_set then
			Library:Notify("Config file not found: " .. Config .. ".lyc [LoadSoundConfig]", 4)
			return false
		end

		for _, b in pairs(config_set) do
			for i, v in pairs(b) do
				getgenv().SoundConfigs[i] = v
			end
		end

		TotalConfigsLoaded = TotalConfigsLoaded + 1
	end

	function Builder:LoadConfig(Config) -- this one should use the config name
		local config_set = Builder:DecryptConfig(Config)

		if not config_set then
			Library:Notify("Config file not found: " .. Config .. ".lyc [LoadConfig]", 4)
			return false
		end

		for _, b in pairs(config_set) do
			for i, v in pairs(b) do
				getgenv().Config[i] = v
			end
		end

		TotalConfigsLoaded = TotalConfigsLoaded + 1
	end

	function Builder:LoadM1Config(Config) -- this one should use the config name
		local config_file = Builder.config_path3 .. Config .. ".lyc"
		if not isfile(config_file) then
			Library:Notify("Config file not found: " .. Config .. ".lyc [Decryption]", 2)
			return false
		end

		local Timing = readfile(config_file)
		getgenv().WeaponConfig[Config] = tonumber(Timing)

		TotalConfigsLoaded = TotalConfigsLoaded + 1
	end

	function Builder:UnloadConfig(Config) -- this one should use the config name
		local config_set = Builder:DecryptConfig(Config)

		if not config_set then
			Library:Notify("Config file not found: " .. Config .. ".lyc [UnloadConfig]", 4)
			return false
		end

		for _, b in pairs(config_set) do
			for i, v in pairs(b) do
				Builder.animTimes[i] = nil
			end
		end

		Library:Notify("Unloaded Config: " .. Config .. ".lyc", 2)
	end

	function Builder:LoadAllConfigs()
		for i, v in pairs(listfiles(Builder.config_path2)) do
			if not v:match(".lyc") then
				continue
			end

			local config_name = cleanup(v)
			Builder:LoadConfig(config_name)
		end

		for i, v in pairs(listfiles(Builder.config_path4)) do
			if not v:match(".lyc") then
				continue
			end

			local config_name = cleanup(v)
			Builder:LoadM1Config(config_name)
		end

		for i, v in pairs(listfiles(Builder.config_path6)) do
			if not v:match(".lyc") then
				continue
			end

			local config_name = cleanup(v)
			Builder:LoadProjectileConfig(config_name)
		end

		for i, v in pairs(listfiles(Builder.config_path8)) do
			if not v:match(".lyc") then
				continue
			end

			local config_name = cleanup(v)
			Builder:LoadSoundConfig(config_name)
		end
	end

	function Builder:CompileAllConfigs()
		local Format = [==[return game:GetService("HttpService"):JSONDecode([[%s]])]==]
		local Configs = HttpService:JSONEncode(getgenv().Config)
		writefile("Lycoris/Deepwoken/V2Configs.lua", Format:format(Configs))
	end
	
	function Builder:CompileAllConfigsEncrypted()
		local lol = {}
		for i,v in next, getgenv().Config do
			table.insert(lol, {
				[i] = v
			})
		end
		local Configs = Builder:EncryptConfig(lol)
		writefile("Lycoris/Deepwoken/CompiledConfigs.lyc", Configs)
	end

	function Builder:RefreshConfigList()
		InterfaceHandler.RefreshConfig()
		InterfaceHandler.RefreshSoundConfig()
		InterfaceHandler.RefreshProjectileConfig()
	end

	task.wait(2)

	Builder:LoadAllConfigs()
	Builder:RefreshConfigList()

	Library:Notify("Loaded " .. TotalConfigsLoaded .. " configs", 2)

	if not script_key then
		writefile("Lycoris/Deepwoken/AnimationConfigs.json", game:GetService("HttpService"):JSONEncode(getgenv().Config))
		writefile("Lycoris/Deepwoken/SoundConfigs.json", game:GetService("HttpService"):JSONEncode(getgenv().SoundConfigs))
		writefile("Lycoris/Deepwoken/ProjectileConfigs.json", game:GetService("HttpService"):JSONEncode(getgenv().ProjectileConfigs))
		Builder:CompileAllConfigsEncrypted()
	end
end)

function InterfaceHandler.CreateConfig()
	if
		Options.CommunityConfig_AnimationId.Value == ""
		or typeof(Options.CommunityConfig_AnimationId.Value) == "boolean"
		or Options.CommunityConfig_AnimationId.Value == nil
	then
		return
	end

	local ConfigPreset = {
		Roll = Toggles.CommunityConfig_Roll.Value or false,
		Delay = Toggles.CommunityConfig_Delay.Value or false,
		RepeatUntilAnimationEnd = Toggles.CommunityConfig_RepeatUntilAnimationEnd.Value or false,
		Wait = tonumber(Options.CommunityConfig_Delay.Value) or 0,
		Range = tonumber(Options.CommunityConfig_Range.Value) or 0,
		RepeatParryDelay = tonumber(Options.CommunityConfig_ParryDelay.Value) or 0,
		RepeatParryAmount = tonumber(Options.CommunityConfig_ParryAmount.Value) or 0,
		DelayDistance = tonumber(Options.CommunityConfig_DelayDistance.Value) or 0,
		Name = Options.CommunityConfig_Name.Value,
		CustomConfig = true,
		selfid = tostring(Options.CommunityConfig_AnimationId.Value),
	}

	if Toggles.UsePresetHitbox.Value then
		ConfigPreset.Hitbox = {
			X = tonumber(Options.Hitbox_X.Value),
			Y = tonumber(Options.Hitbox_Y.Value),
			Z = tonumber(Options.Hitbox_Z.Value),
			YSet = tonumber(Options.Hitbox_YSet.Value),
			ZSet = tonumber(Options.Hitbox_ZSet.Value),
		}
	end

	local Config = {
		["rbxassetid://" .. tostring(Options.CommunityConfig_AnimationId.Value)] = ConfigPreset,
	}

	Builder:CreateConfig(Options.CommunityConfig_Name.Value, Config)
end

function InterfaceHandler.DecodeConfig()
	if
		Options.CommunityConfig_List.Value == ""
		or typeof(Options.CommunityConfig_List.Value) == "boolean"
		or Options.CommunityConfig_List.Value == nil
	then
		return
	end

	Builder:DecodeConfig(Options.CommunityConfig_List.Value)
end

function InterfaceHandler.RefreshConfig()
	local Configs = {}
	for _, v in pairs(listfiles(Builder.config_path2)) do
		if v:match(".lyc") then
			local calc = cleanup(v)
			table.insert(Configs, calc)
		end
	end

	Options.CommunityConfig_List.Values = Configs
	Options.CommunityConfig_List:SetValues()
	Library:Notify("Config list refreshed", 2)
end

function InterfaceHandler.ConfigChanged()
	if
		Options.CommunityConfig_List.Value == ""
		or typeof(Options.CommunityConfig_List.Value) == "boolean"
		or Options.CommunityConfig_List.Value == nil
	then
		return
	end

	local ConfigName = Options.CommunityConfig_List.Value:gsub(".lyc", "")
	local ConfigDecode = Builder:DecryptConfig(ConfigName)
	if not ConfigDecode then
		return
	end

	for i, v in pairs(ConfigDecode[1]) do
		local AnimationConfig = v
		if AnimationConfig then
			local realid = v.selfid or i
			realid = realid:gsub("rbxassetid://", "")
			realid = tonumber(realid)

			local WaitTime = AnimationConfig.Wait or 0
			local Delay = AnimationConfig.Delay or false
			local DelayDistance = AnimationConfig.DelayDistance or 0
			local ParryAmount = AnimationConfig.RepeatParryAmount or 0
			local Roll = AnimationConfig.Roll or false
			local RepeatDelay = AnimationConfig.RepeatParryDelay or 0
			local Range = AnimationConfig.Range or 0
			local RepeatUntilAnimationEnd = AnimationConfig.RepeatUntilAnimationEnd
			local HitboxInfo = AnimationConfig.Hitbox or {}

			-- Custom hitbox YIPPIE
			for i,v in pairs(HitboxInfo) do
				Options['Hitbox_'..i]:SetValue(tonumber(v))
			end

			Toggles.CommunityConfig_Roll:SetValue(Roll)
			Toggles.CommunityConfig_Delay:SetValue(Delay)
			Toggles.CommunityConfig_RepeatUntilAnimationEnd:SetValue(RepeatUntilAnimationEnd and true or false)
			Options.CommunityConfig_Delay:SetValue(WaitTime)
			Options.CommunityConfig_Range:SetValue(Range)
			Options.CommunityConfig_ParryDelay:SetValue(tostring(RepeatDelay))
			Options.CommunityConfig_ParryAmount:SetValue(tostring(ParryAmount))
			Options.CommunityConfig_DelayDistance:SetValue(tostring(DelayDistance))
			Options.CommunityConfig_Name:SetValue(AnimationConfig.Name)
			Options.CommunityConfig_AnimationId:SetValue(realid)
		else
			Library:Notify('Failed to load config for "' .. i .. '"', 4)
		end
	end
end

function InterfaceHandler.LoggedAnimationChanged()
	if
		Options.LoggedAnimations.Value == ""
		or typeof(Options.LoggedAnimations.Value) == "boolean"
		or Options.LoggedAnimations.Value == nil
	then
		return
	end

	local Config = Options.LoggedAnimations.Value:split(" ")
	local AnimationId, Name = Config[2], Config[1]
	Options.CommunityConfig_Name:SetValue(Name)
	Options.CommunityConfig_AnimationId:SetValue(tostring(AnimationId))
end

function InterfaceHandler.ClearAnimLogs()
	Options.LoggedAnimations:SetValues({})
	Options.LoggedAnimations:SetValue()
	getgenv().LoggedAnimations = {}
end

function InterfaceHandler.CopyAnim()
	setclipboard(([[%s]]):format(Options.CommunityConfig_AnimationId.Value))
end

function InterfaceHandler.LoadConfig()
	if
		Options.CommunityConfig_List.Value == ""
		or typeof(Options.CommunityConfig_List.Value) == "boolean"
		or Options.CommunityConfig_List.Value == nil
	then
		return Library:Notify("Please select a config to unload", 2)
	end

	Builder:LoadConfig(Options.CommunityConfig_List.Value)
end

function InterfaceHandler.UnloadConfig()
	if
		Options.CommunityConfig_List.Value == ""
		or typeof(Options.CommunityConfig_List.Value) == "boolean"
		or Options.CommunityConfig_List.Value == nil
	then
		return Library:Notify("Please select a config to unload", 2)
	end

	Builder:UnloadConfig(Options.CommunityConfig_List.Value)
end

function InterfaceHandler.CreateSoundConfig()
	if
		Options.SoundConfig_SoundId.Value == ""
		or typeof(Options.SoundConfig_SoundId.Value) == "boolean"
		or Options.SoundConfig_SoundId.Value == nil
	then
		return
	end

	local Config = {
		["rbxassetid://" .. tostring(Options.SoundConfig_SoundId.Value)] = {
			Roll = Toggles.SoundConfig_Roll.Value or false,
			Delay = Toggles.SoundConfig_Delay.Value or false,
			Wait = tonumber(Options.SoundConfig_Delay.Value) or 0,
			Range = tonumber(Options.SoundConfig_Range.Value) or 0,
			RepeatParryDelay = tonumber(Options.SoundConfig_ParryDelay.Value) or 0,
			RepeatParryAmount = tonumber(Options.SoundConfig_ParryAmount.Value) or 0,
			DelayDistance = tonumber(Options.SoundConfig_DelayDistance.Value) or 0,
			Name = Options.SoundConfig_Name.Value,
			CustomConfig = true,
			selfid = tostring(Options.SoundConfig_SoundId.Value),
		},
	}

	Builder:CreateSoundConfig(Options.SoundConfig_Name.Value, Config)
end

function InterfaceHandler.DecodeSoundConfig()
	if
		Options.SoundConfig_List.Value == ""
		or typeof(Options.SoundConfig_List.Value) == "boolean"
		or Options.SoundConfig_List.Value == nil
	then
		return
	end

	Builder:DecodeSoundConfig(Options.SoundConfig_List.Value)
end

function InterfaceHandler.RefreshSoundConfig()
	local Configs = {}
	for _, v in pairs(listfiles(Builder.config_path7)) do
		if v:match(".lyc") then
			local calc = cleanup(v)
			table.insert(Configs, calc)
		end
	end

	Options.SoundConfig_List.Values = Configs
	Options.SoundConfig_List:SetValues()
	Library:Notify("Config list refreshed", 2)
end

function InterfaceHandler.SoundConfigChanged()
	if
		Options.SoundConfig_List.Value == ""
		or typeof(Options.SoundConfig_List.Value) == "boolean"
		or Options.SoundConfig_List.Value == nil
	then
		return
	end

	local ConfigName = Options.SoundConfig_List.Value:split(" ")[1]:gsub(".lyc", "")
	local ConfigDecode = Builder:DecryptSoundConfig(ConfigName)
	if not ConfigDecode then
		return
	end

	for i, v in pairs(ConfigDecode[1]) do
		local SoundConfig = v
		if SoundConfig then
			local WaitTime = SoundConfig.Wait or 0
			local Delay = SoundConfig.Delay or false
			local DelayDistance = SoundConfig.DelayDistance or 0
			local ParryAmount = SoundConfig.RepeatParryAmount or 0
			local Roll = SoundConfig.Roll or false
			local RepeatDelay = SoundConfig.RepeatParryDelay or 0
			local Range = SoundConfig.Range or 0
			Toggles.SoundConfig_Roll:SetValue(Roll)
			Toggles.SoundConfig_Delay:SetValue(Delay)
			Options.SoundConfig_Delay:SetValue(WaitTime)
			Options.SoundConfig_Range:SetValue(Range)
			Options.SoundConfig_ParryDelay:SetValue(tostring(RepeatDelay))
			Options.SoundConfig_ParryAmount:SetValue(tostring(ParryAmount))
			Options.SoundConfig_DelayDistance:SetValue(tostring(DelayDistance))
			Options.SoundConfig_Name:SetValue(SoundConfig.Name)
			Options.SoundConfig_SoundId:SetValue(tostring(i))
		else
			Library:Notify('Failed to load config for "' .. i .. '"', 4)
		end
	end
end

function InterfaceHandler.LoggedSoundChanged()
	if
		Options.LoggedSounds.Value == ""
		or typeof(Options.LoggedSounds.Value) == "boolean"
		or Options.LoggedSounds.Value == nil
	then
		return
	end

	local Config = Options.LoggedSounds.Value:split(" ")
	local SoundId, Name = Config[2], Config[1]
	Options.SoundConfig_Name:SetValue(Name)
	Options.SoundConfig_SoundId:SetValue(tostring(SoundId))
end

function InterfaceHandler.ClearSoundLogs()
	Options.LoggedSounds:SetValues({})
	Options.LoggedSounds:SetValue()
	getgenv().LoggedSounds = {}
end

function InterfaceHandler.CopySound()
	setclipboard(([[%s]]):format(Options.SoundConfig_SoundId.Value))
end

function InterfaceHandler.CreateProjectileConfig()
	if
		Options.ProjectileConfig_ProjectileName.Value == ""
		or typeof(Options.ProjectileConfig_ProjectileName.Value) == "boolean"
		or Options.ProjectileConfig_ProjectileName.Value == nil
	then
		return
	end

	local Config = {
		[tostring(Options.ProjectileConfig_ProjectileName.Value)] = {
			Roll = Toggles.ProjectileConfig_Roll.Value or false,
			Wait = tonumber(Options.ProjectileConfig_Delay.Value) or 0,
			MaxRange = tonumber(Options.ProjectileConfig_MaxRange.Value) or 0,
			MinRange = tonumber(Options.ProjectileConfig_MinRange.Value) or 0,
			RepeatParryDelay = tonumber(Options.ProjectileConfig_ParryDelay.Value) or 0,
			RepeatParryAmount = tonumber(Options.ProjectileConfig_ParryAmount.Value) or 0,
			Name = Options.ProjectileConfig_Name.Value,
			CustomConfig = true,
			selfid = tostring(Options.ProjectileConfig_ProjectileName.Value),
		},
	}

	Builder:CreateProjectileConfig(Options.ProjectileConfig_Name.Value, Config)
end

function InterfaceHandler.DecodeProjectileConfig()
	if
		Options.ProjectileConfig_List.Value == ""
		or typeof(Options.ProjectileConfig_List.Value) == "boolean"
		or Options.ProjectileConfig_List.Value == nil
	then
		return
	end

	Builder:DecodeProjectileConfig(Options.ProjectileConfig_List.Value)
end

function InterfaceHandler.RefreshProjectileConfig()
	local Configs = {}
	for _, v in pairs(listfiles(Builder.config_path6)) do
		if v:match(".lyc") then
			local calc = cleanup(v)
			table.insert(Configs, calc)
		end
	end

	Options.ProjectileConfig_List.Values = Configs
	Options.ProjectileConfig_List:SetValues()
	Library:Notify("Config list refreshed", 2)
end

function InterfaceHandler.ProjectileConfigChanged()
	if
		Options.ProjectileConfig_List.Value == ""
		or typeof(Options.ProjectileConfig_List.Value) == "boolean"
		or Options.ProjectileConfig_List.Value == nil
	then
		return
	end

	local RealConfigName = Options.ProjectileConfig_List.Value:split(" ")[1]
	local ConfigName = RealConfigName:gsub(".lyc", "")
	local ConfigDecode = Builder:DecryptProjectileConfig(ConfigName)
	if not ConfigDecode then
		return
	end

	for i, v in pairs(ConfigDecode[1]) do
		local ProjectileConfig = v
		if ProjectileConfig then
			local WaitTime = ProjectileConfig.Wait or 0
			local ParryAmount = ProjectileConfig.RepeatParryAmount or 0
			local Roll = ProjectileConfig.Roll or false
			local RepeatDelay = ProjectileConfig.RepeatParryDelay or 0
			local MaxRange = ProjectileConfig.MaxRange or 0
			local MinRange = ProjectileConfig.MinRange or 0
			Toggles.ProjectileConfig_Roll:SetValue(Roll)
			Options.ProjectileConfig_Delay:SetValue(WaitTime)
			Options.ProjectileConfig_MaxRange:SetValue(MaxRange)
			Options.ProjectileConfig_MinRange:SetValue(MinRange)
			Options.ProjectileConfig_ParryDelay:SetValue(tostring(RepeatDelay))
			Options.ProjectileConfig_ParryAmount:SetValue(tostring(ParryAmount))
			Options.ProjectileConfig_Name:SetValue(ProjectileConfig.Name)
			Options.ProjectileConfig_ProjectileName:SetValue(tostring(i))
		else
			Library:Notify('Failed to load config for "' .. i .. '"', 4)
		end
	end
end

function InterfaceHandler.LoggedProjectileChanged()
	if
		Options.LoggedProjectiles.Value == ""
		or typeof(Options.LoggedProjectiles.Value) == "boolean"
		or Options.LoggedProjectiles.Value == nil
	then
		return
	end

	Options.ProjectileConfig_Name:SetValue(Options.LoggedProjectile.Value)
	Options.ProjectileConfig_ProjectileName:SetValue(tostring(Options.LoggedProjectile.Value))
end

function InterfaceHandler.ClearProjectileLogs()
	Options.LoggedProjectiles:SetValues({})
	Options.LoggedProjectiles:SetValue()
	getgenv().LoggedProjectiles = {}
end

function InterfaceHandler.CopyProjectile()
	setclipboard(([[%s]]):format(Options.ProjectileConfig_ProjectileName.Value))
end

function InterfaceHandler.ConfigListChanged()
	if
		Options.Config_List.Value == ""
		or typeof(Options.Config_List.Value) == "boolean"
		or Options.Config_List.Value == nil
	then
		return
	end

	local AnimationConfig = getgenv().Config[Options.Config_List.Value:split(" ")[2]]
	if not AnimationConfig then
		return
	end

	if AnimationConfig then
		local WaitTime = AnimationConfig.Wait or 0
		local Delay = AnimationConfig.Delay or false
		local DelayDistance = AnimationConfig.DelayDistance or 0
		local ParryAmount = AnimationConfig.RepeatParryAmount or 0
		local Roll = AnimationConfig.Roll or false
		local RepeatDelay = AnimationConfig.RepeatParryDelay or 0
		local Range = AnimationConfig.Range or 0

		Toggles.Config_Roll:SetValue(Roll)
		Toggles.Config_Delay:SetValue(Delay)
		Options.Config_Delay:SetValue(WaitTime)
		Options.Config_Range:SetValue(Range)
		Options.Config_ParryDelay:SetValue(tostring(RepeatDelay))
		Options.Config_ParryAmount:SetValue(tostring(ParryAmount))
		Options.Config_DelayDistance:SetValue(tostring(DelayDistance))
		Options.Config_Name:SetValue(AnimationConfig.Name)
		Options.Config_AnimationId:SetValue(tostring(AnimationConfig.selfid))
	else
		Library:Notify('Failed to load config for "' .. Options.Config_List.Value:split(" ")[2] .. '"', 4)
	end
end

function InterfaceHandler.SaveConfigInternal()
	if
		Options.Config_List.Value == ""
		or typeof(Options.Config_List.Value) == "boolean"
		or Options.Config_List.Value == nil
	then
		return
	end

	local AnimId = Options.Config_List.Value:split(" ")[2]
	local ConfigPreset = {
		Roll = Toggles.Config_Roll.Value or false,
		Delay = Toggles.Config_Delay.Value or false,
		Wait = tonumber(Options.Config_Delay.Value) or 0,
		Range = tonumber(Options.Config_Range.Value) or 0,
		RepeatParryDelay = tonumber(Options.Config_ParryDelay.Value) or 0,
		RepeatParryAmount = tonumber(Options.Config_ParryAmount.Value) or 0,
		DelayDistance = tonumber(Options.Config_DelayDistance.Value) or 0,
		Name = Options.Config_Name.Value,
		CustomConfig = true,
		selfid = AnimId,
	}
	
	if Toggles.UsePresetHitbox.Value then
		ConfigPreset.Hitbox = {
			X = tonumber(Options.Hitbox_X.Value),
			Y = tonumber(Options.Hitbox_Y.Value),
			Z = tonumber(Options.Hitbox_Z.Value),
			YSet = tonumber(Options.Hitbox_YSet.Value),
			ZSet = tonumber(Options.Hitbox_ZSet.Value),
		}
	end

	local Config = {
		[AnimId] = ConfigPreset
	}

	Builder:CreateConfig(Options.Config_Name.Value, Config)
end

function InterfaceHandler.SaveM1Config()
	if
		Options.M1Config_List.Value == ""
		or typeof(Options.M1Config_List.Value) == "boolean"
		or Options.M1Config_List.Value == nil
	then
		return
	end

	local WeaponType = Options.M1Config_List.Value
	writefile("Lycoris/Deepwoken/M1Configs/" .. WeaponType .. ".lyc", tostring(Options.M1Config_Delay.Value))

	getgenv().WeaponConfig[WeaponType] = Options.M1Config_Delay.Value

	Library:Notify("Saved M1 Config: " .. WeaponType .. ".lyc", 2)
end

function InterfaceHandler.M1ConfigListChanged()
	if
		Options.M1Config_List.Value == ""
		or typeof(Options.M1Config_List.Value) == "boolean"
		or Options.M1Config_List.Value == nil
	then
		return
	end

	local AnimationConfig = getgenv().WeaponConfig[Options.M1Config_List.Value]
	if AnimationConfig then
		Options.M1Config_Delay:SetValue(AnimationConfig)
	else
		Library:Notify('Failed to load config for "' .. Options.M1Config_List.Value .. '"', 4)
	end
end

function InterfaceHandler.CompileConfigs()
	Builder:CompileAllConfigs()
end

function InterfaceHandler.CompileConfigsEncrypted()
	Builder:CompileAllConfigsEncrypted()
end

InterfaceHandler.Builder = Builder

return InterfaceHandler
end)
__bundle_register("aescbc", function(require, _LOADED, __bundle_register, __bundle_modules)
(function()
	---@diagnostic disable: undefined-global

local function _W(f) return f() end
local bit = bit32;

local gf=_W(function(_ENV, ...)
	local bxor = bit.bxor
	local lshift = bit.lshift

	local n = 0x100
	local ord = 0xff
	local irrPolynom = 0x11b
	local exp = {}
	local log = {}

	local function add(operand1, operand2)
		return bxor(operand1,operand2)
	end

	local function sub(operand1, operand2)
		return bxor(operand1,operand2)
	end

	local function invert(operand)
		if (operand == 1) then
			return 1
		end
		local exponent = ord - log[operand]
		return exp[exponent]
	end

	local function mul(operand1, operand2)
		if (operand1 == 0 or operand2 == 0) then
			return 0
		end

		local exponent = log[operand1] + log[operand2]
		if (exponent >= ord) then
			exponent = exponent - ord
		end
		return  exp[exponent]
	end

	local function div(operand1, operand2)
		if (operand1 == 0)  then
			return 0
		end
		local exponent = log[operand1] - log[operand2]
		if (exponent < 0) then
			exponent = exponent + ord
		end
		return exp[exponent]
	end

	local function printLog()
		for i = 1, n do
			print("log(", i-1, ")=", log[i-1])
		end
	end

	local function printExp()
		for i = 1, n do
			print("exp(", i-1, ")=", exp[i-1])
		end
	end

	local function initMulTable()
		local a = 1

		for i = 0,ord-1 do
			exp[i] = a
			log[a] = i

			a = bxor(lshift(a, 1), a)
			if a > ord then
				a = sub(a, irrPolynom)
			end
		end
	end

	initMulTable()

	return {
		add = add,
		sub = sub,
		invert = invert,
		mul = mul,
		div = dib,
		printLog = printLog,
		printExp = printExp,
	}
end)
util=_W(function(_ENV, ...)
	local bxor = bit.bxor
	local rshift = bit.rshift
	local band = bit.band
	local lshift = bit.lshift

	local sleepCheckIn
	local function byteParity(byte)
		byte = bxor(byte, rshift(byte, 4))
		byte = bxor(byte, rshift(byte, 2))
		byte = bxor(byte, rshift(byte, 1))
		return band(byte, 1)
	end

	local function getByte(number, index)
		if (index == 0) then
			return band(number,0xff)
		else
			return band(rshift(number, index*8),0xff)
		end
	end


	local function putByte(number, index)
		if (index == 0) then
			return band(number,0xff)
		else
			return lshift(band(number,0xff),index*8)
		end
	end

	local function bytesToInts(bytes, start, n)
		local ints = {}
		for i = 0, n - 1 do
			ints[i + 1] =
				putByte(bytes[start + (i*4)], 3) +
				putByte(bytes[start + (i*4) + 1], 2) +
				putByte(bytes[start + (i*4) + 2], 1) +
				putByte(bytes[start + (i*4) + 3], 0)

			if n % 10000 == 0 then sleepCheckIn() end
		end
		return ints
	end

	local function intsToBytes(ints, output, outputOffset, n)
		n = n or #ints
		for i = 0, n - 1 do
			for j = 0,3 do
				output[outputOffset + i*4 + (3 - j)] = getByte(ints[i + 1], j)
			end

			if n % 10000 == 0 then sleepCheckIn() end
		end
		return output
	end

	local function bytesToHex(bytes)
		local hexBytes = ""

		for i,byte in ipairs(bytes) do
			hexBytes = hexBytes .. string.format("%02x ", byte)
		end

		return hexBytes
	end

	local function hexToBytes(bytes)
		local out = {}
		for i = 1, #bytes, 2 do
			out[#out + 1] = tonumber(bytes:sub(i, i + 1), 16)
		end

		return out
	end

	local function toHexString(data)
		local type = type(data)
		if (type == "number") then
			return string.format("%08x",data)
		elseif (type == "table") then
			return bytesToHex(data)
		elseif (type == "string") then
			local bytes = {string.byte(data, 1, #data)}

			return bytesToHex(bytes)
		else
			return data
		end
	end

	local function padByteString(data)
		local dataLength = #data

		local random1 = math.random(0,255)
		local random2 = math.random(0,255)

		local prefix = string.char(random1,
			random2,
			random1,
			random2,
			getByte(dataLength, 3),
			getByte(dataLength, 2),
			getByte(dataLength, 1),
			getByte(dataLength, 0)
		)

		data = prefix .. data

		local paddingLength = math.ceil(#data/16)*16 - #data
		local padding = ""
		for i=1,paddingLength do
			padding = padding .. string.char(math.random(0,255))
		end

		return data .. padding
	end

	local function properlyDecrypted(data)
		local random = {string.byte(data,1,4)}

		if (random[1] == random[3] and random[2] == random[4]) then
			return true
		end

		return false
	end

	local function unpadByteString(data)
		if (not properlyDecrypted(data)) then
			return nil
		end

		local dataLength = putByte(string.byte(data,5), 3)
			+ putByte(string.byte(data,6), 2)
			+ putByte(string.byte(data,7), 1)
			+ putByte(string.byte(data,8), 0)

		return string.sub(data,9,8+dataLength)
	end

	local function xorIV(data, iv)
		for i = 1,16 do
			data[i] = bxor(data[i], iv[i])
		end
	end

	local function increment(data)
		local i = 16
		while true do
			local value = data[i] + 1
			if value >= 256 then
				data[i] = value - 256
				i = (i - 2) % 16 + 1
			else
				data[i] = value
				break
			end
		end
	end

	local push, pull, time = os.queueEvent, coroutine.yield, os.time
	local oldTime = time()
	local function sleepCheckIn() 
	end

	local function getRandomData(bytes)
		local char, random, sleep, insert = string.char, math.random, sleepCheckIn, table.insert
		local result = {}

		for i=1,bytes do
			insert(result, random(0,255))
			if i % 10240 == 0 then sleep() end
		end

		return result
	end

	local function getRandomString(bytes)
		local char, random, sleep, insert = string.char, math.random, sleepCheckIn, table.insert
		local result = {}

		for i=1,bytes do
			insert(result, char(random(0,255)))
			if i % 10240 == 0 then sleep() end
		end

		return table.concat(result)
	end

	return {
		byteParity = byteParity,
		getByte = getByte,
		putByte = putByte,
		bytesToInts = bytesToInts,
		intsToBytes = intsToBytes,
		bytesToHex = bytesToHex,
		hexToBytes = hexToBytes,
		toHexString = toHexString,
		padByteString = padByteString,
		properlyDecrypted = properlyDecrypted,
		unpadByteString = unpadByteString,
		xorIV = xorIV,
		increment = increment,

		sleepCheckIn = sleepCheckIn,

		getRandomData = getRandomData,
		getRandomString = getRandomString,
	}
end)
aes=_W(function(_ENV, ...)
	local putByte = util.putByte
	local getByte = util.getByte

	local ROUNDS = 'rounds'
	local KEY_TYPE = "type"
	local ENCRYPTION_KEY=1
	local DECRYPTION_KEY=2

	local SBox = {}
	local iSBox = {}

	local table0 = {}
	local table1 = {}
	local table2 = {}
	local table3 = {}

	local tableInv0 = {}
	local tableInv1 = {}
	local tableInv2 = {}
	local tableInv3 = {}

	local rCon = {
		0x01000000,
		0x02000000,
		0x04000000,
		0x08000000,
		0x10000000,
		0x20000000,
		0x40000000,
		0x80000000,
		0x1b000000,
		0x36000000,
		0x6c000000,
		0xd8000000,
		0xab000000,
		0x4d000000,
		0x9a000000,
		0x2f000000,
	}

	local function affinMap(byte)
		mask = 0xf8
		result = 0
		for i = 1,8 do
			result = bit.lshift(result,1)

			parity = util.byteParity(bit.band(byte,mask))
			result = result + parity

			lastbit = bit.band(mask, 1)
			mask = bit.band(bit.rshift(mask, 1),0xff)
			if (lastbit ~= 0) then
				mask = bit.bor(mask, 0x80)
			else
				mask = bit.band(mask, 0x7f)
			end
		end

		return bit.bxor(result, 0x63)
	end

	local function calcSBox()
		for i = 0, 255 do
			if (i ~= 0) then
				inverse = gf.invert(i)
			else
				inverse = i
			end
			mapped = affinMap(inverse)
			SBox[i] = mapped
			iSBox[mapped] = i
		end
	end

	local function calcRoundTables()
		for x = 0,255 do
			byte = SBox[x]
			table0[x] = putByte(gf.mul(0x03, byte), 0)
				+ putByte(             byte , 1)
				+ putByte(             byte , 2)
				+ putByte(gf.mul(0x02, byte), 3)
			table1[x] = putByte(             byte , 0)
				+ putByte(             byte , 1)
				+ putByte(gf.mul(0x02, byte), 2)
				+ putByte(gf.mul(0x03, byte), 3)
			table2[x] = putByte(             byte , 0)
				+ putByte(gf.mul(0x02, byte), 1)
				+ putByte(gf.mul(0x03, byte), 2)
				+ putByte(             byte , 3)
			table3[x] = putByte(gf.mul(0x02, byte), 0)
				+ putByte(gf.mul(0x03, byte), 1)
				+ putByte(             byte , 2)
				+ putByte(             byte , 3)
		end
	end

	local function calcInvRoundTables()
		for x = 0,255 do
			byte = iSBox[x]
			tableInv0[x] = putByte(gf.mul(0x0b, byte), 0)
				+ putByte(gf.mul(0x0d, byte), 1)
				+ putByte(gf.mul(0x09, byte), 2)
				+ putByte(gf.mul(0x0e, byte), 3)
			tableInv1[x] = putByte(gf.mul(0x0d, byte), 0)
				+ putByte(gf.mul(0x09, byte), 1)
				+ putByte(gf.mul(0x0e, byte), 2)
				+ putByte(gf.mul(0x0b, byte), 3)
			tableInv2[x] = putByte(gf.mul(0x09, byte), 0)
				+ putByte(gf.mul(0x0e, byte), 1)
				+ putByte(gf.mul(0x0b, byte), 2)
				+ putByte(gf.mul(0x0d, byte), 3)
			tableInv3[x] = putByte(gf.mul(0x0e, byte), 0)
				+ putByte(gf.mul(0x0b, byte), 1)
				+ putByte(gf.mul(0x0d, byte), 2)
				+ putByte(gf.mul(0x09, byte), 3)
		end
	end

	local function rotWord(word)
		local tmp = bit.band(word,0xff000000)
		return (bit.lshift(word,8) + bit.rshift(tmp,24))
	end

	local function subWord(word)
		return putByte(SBox[getByte(word,0)],0)
			+ putByte(SBox[getByte(word,1)],1)
			+ putByte(SBox[getByte(word,2)],2)
			+ putByte(SBox[getByte(word,3)],3)
	end

	local function expandEncryptionKey(key)
		local keySchedule = {}
		local keyWords = math.floor(#key / 4)


		if ((keyWords ~= 4 and keyWords ~= 6 and keyWords ~= 8) or (keyWords * 4 ~= #key)) then
			warn("Invalid key size: " .. tostring(keyWords))
			return nil
		end

		keySchedule[ROUNDS] = keyWords + 6
		keySchedule[KEY_TYPE] = ENCRYPTION_KEY

		for i = 0,keyWords - 1 do
			keySchedule[i] = putByte(key[i*4+1], 3)
				+ putByte(key[i*4+2], 2)
				+ putByte(key[i*4+3], 1)
				+ putByte(key[i*4+4], 0)
		end

		for i = keyWords, (keySchedule[ROUNDS] + 1)*4 - 1 do
			local tmp = keySchedule[i-1]

			if ( i % keyWords == 0) then
				tmp = rotWord(tmp)
				tmp = subWord(tmp)

				local index = math.floor(i/keyWords)
				tmp = bit.bxor(tmp,rCon[index])
			elseif (keyWords > 6 and i % keyWords == 4) then
				tmp = subWord(tmp)
			end

			keySchedule[i] = bit.bxor(keySchedule[(i-keyWords)],tmp)
		end

		return keySchedule
	end

	local function invMixColumnOld(word)
		local b0 = getByte(word,3)
		local b1 = getByte(word,2)
		local b2 = getByte(word,1)
		local b3 = getByte(word,0)

		return putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b1),
			gf.mul(0x0d, b2)),
			gf.mul(0x09, b3)),
			gf.mul(0x0e, b0)),3)
			+ putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b2),
				gf.mul(0x0d, b3)),
				gf.mul(0x09, b0)),
				gf.mul(0x0e, b1)),2)
			+ putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b3),
				gf.mul(0x0d, b0)),
				gf.mul(0x09, b1)),
				gf.mul(0x0e, b2)),1)
			+ putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b0),
				gf.mul(0x0d, b1)),
				gf.mul(0x09, b2)),
				gf.mul(0x0e, b3)),0)
	end

	local function invMixColumn(word)
		local b0 = getByte(word,3)
		local b1 = getByte(word,2)
		local b2 = getByte(word,1)
		local b3 = getByte(word,0)

		local t = bit.bxor(b3,b2)
		local u = bit.bxor(b1,b0)
		local v = bit.bxor(t,u)
		v = bit.bxor(v,gf.mul(0x08,v))
		w = bit.bxor(v,gf.mul(0x04, bit.bxor(b2,b0)))
		v = bit.bxor(v,gf.mul(0x04, bit.bxor(b3,b1)))

		return putByte( bit.bxor(bit.bxor(b3,v), gf.mul(0x02, bit.bxor(b0,b3))), 0)
			+ putByte( bit.bxor(bit.bxor(b2,w), gf.mul(0x02, t              )), 1)
			+ putByte( bit.bxor(bit.bxor(b1,v), gf.mul(0x02, bit.bxor(b0,b3))), 2)
			+ putByte( bit.bxor(bit.bxor(b0,w), gf.mul(0x02, u              )), 3)
	end

	local function expandDecryptionKey(key)
		local keySchedule = expandEncryptionKey(key)
		if (keySchedule == nil) then
			return nil
		end

		keySchedule[KEY_TYPE] = DECRYPTION_KEY

		for i = 4, (keySchedule[ROUNDS] + 1)*4 - 5 do
			keySchedule[i] = invMixColumnOld(keySchedule[i])
		end

		return keySchedule
	end

	local function addRoundKey(state, key, round)
		for i = 0, 3 do
			state[i + 1] = bit.bxor(state[i + 1], key[round*4+i])
		end
	end

	local function doRound(origState, dstState)
		dstState[1] =  bit.bxor(bit.bxor(bit.bxor(
			table0[getByte(origState[1],3)],
			table1[getByte(origState[2],2)]),
			table2[getByte(origState[3],1)]),
			table3[getByte(origState[4],0)])

		dstState[2] =  bit.bxor(bit.bxor(bit.bxor(
			table0[getByte(origState[2],3)],
			table1[getByte(origState[3],2)]),
			table2[getByte(origState[4],1)]),
			table3[getByte(origState[1],0)])

		dstState[3] =  bit.bxor(bit.bxor(bit.bxor(
			table0[getByte(origState[3],3)],
			table1[getByte(origState[4],2)]),
			table2[getByte(origState[1],1)]),
			table3[getByte(origState[2],0)])

		dstState[4] =  bit.bxor(bit.bxor(bit.bxor(
			table0[getByte(origState[4],3)],
			table1[getByte(origState[1],2)]),
			table2[getByte(origState[2],1)]),
			table3[getByte(origState[3],0)])
	end

	local function doLastRound(origState, dstState)
		dstState[1] = putByte(SBox[getByte(origState[1],3)], 3)
			+ putByte(SBox[getByte(origState[2],2)], 2)
			+ putByte(SBox[getByte(origState[3],1)], 1)
			+ putByte(SBox[getByte(origState[4],0)], 0)

		dstState[2] = putByte(SBox[getByte(origState[2],3)], 3)
			+ putByte(SBox[getByte(origState[3],2)], 2)
			+ putByte(SBox[getByte(origState[4],1)], 1)
			+ putByte(SBox[getByte(origState[1],0)], 0)

		dstState[3] = putByte(SBox[getByte(origState[3],3)], 3)
			+ putByte(SBox[getByte(origState[4],2)], 2)
			+ putByte(SBox[getByte(origState[1],1)], 1)
			+ putByte(SBox[getByte(origState[2],0)], 0)

		dstState[4] = putByte(SBox[getByte(origState[4],3)], 3)
			+ putByte(SBox[getByte(origState[1],2)], 2)
			+ putByte(SBox[getByte(origState[2],1)], 1)
			+ putByte(SBox[getByte(origState[3],0)], 0)
	end

	local function doInvRound(origState, dstState)
		dstState[1] =  bit.bxor(bit.bxor(bit.bxor(
			tableInv0[getByte(origState[1],3)],
			tableInv1[getByte(origState[4],2)]),
			tableInv2[getByte(origState[3],1)]),
			tableInv3[getByte(origState[2],0)])

		dstState[2] =  bit.bxor(bit.bxor(bit.bxor(
			tableInv0[getByte(origState[2],3)],
			tableInv1[getByte(origState[1],2)]),
			tableInv2[getByte(origState[4],1)]),
			tableInv3[getByte(origState[3],0)])

		dstState[3] =  bit.bxor(bit.bxor(bit.bxor(
			tableInv0[getByte(origState[3],3)],
			tableInv1[getByte(origState[2],2)]),
			tableInv2[getByte(origState[1],1)]),
			tableInv3[getByte(origState[4],0)])

		dstState[4] =  bit.bxor(bit.bxor(bit.bxor(
			tableInv0[getByte(origState[4],3)],
			tableInv1[getByte(origState[3],2)]),
			tableInv2[getByte(origState[2],1)]),
			tableInv3[getByte(origState[1],0)])
	end

	local function doInvLastRound(origState, dstState)
		dstState[1] = putByte(iSBox[getByte(origState[1],3)], 3)
			+ putByte(iSBox[getByte(origState[4],2)], 2)
			+ putByte(iSBox[getByte(origState[3],1)], 1)
			+ putByte(iSBox[getByte(origState[2],0)], 0)

		dstState[2] = putByte(iSBox[getByte(origState[2],3)], 3)
			+ putByte(iSBox[getByte(origState[1],2)], 2)
			+ putByte(iSBox[getByte(origState[4],1)], 1)
			+ putByte(iSBox[getByte(origState[3],0)], 0)

		dstState[3] = putByte(iSBox[getByte(origState[3],3)], 3)
			+ putByte(iSBox[getByte(origState[2],2)], 2)
			+ putByte(iSBox[getByte(origState[1],1)], 1)
			+ putByte(iSBox[getByte(origState[4],0)], 0)

		dstState[4] = putByte(iSBox[getByte(origState[4],3)], 3)
			+ putByte(iSBox[getByte(origState[3],2)], 2)
			+ putByte(iSBox[getByte(origState[2],1)], 1)
			+ putByte(iSBox[getByte(origState[1],0)], 0)
	end

	local function encrypt(key, input, inputOffset, output, outputOffset)
		inputOffset = inputOffset or 1
		output = output or {}
		outputOffset = outputOffset or 1

		local state = {}
		local tmpState = {}

		if (key[KEY_TYPE] ~= ENCRYPTION_KEY) then
			warn("No encryption key: " .. tostring(key[KEY_TYPE]) .. ", expected " .. ENCRYPTION_KEY)
			return
		end

		state = util.bytesToInts(input, inputOffset, 4)
		addRoundKey(state, key, 0)


		local round = 1
		while (round < key[ROUNDS] - 1) do
			doRound(state, tmpState)
			addRoundKey(tmpState, key, round)
			round = round + 1

			doRound(tmpState, state)
			addRoundKey(state, key, round)
			round = round + 1
		end

		doRound(state, tmpState)
		addRoundKey(tmpState, key, round)
		round = round +1

		doLastRound(tmpState, state)
		addRoundKey(state, key, round)

		return util.intsToBytes(state, output, outputOffset)
	end

	local function decrypt(key, input, inputOffset, output, outputOffset)
		inputOffset = inputOffset or 1
		output = output or {}
		outputOffset = outputOffset or 1

		local state = {}
		local tmpState = {}

		if (key[KEY_TYPE] ~= DECRYPTION_KEY) then
			warn("No decryption key: " .. tostring(key[KEY_TYPE]))
			return
		end

		state = util.bytesToInts(input, inputOffset, 4)
		addRoundKey(state, key, key[ROUNDS])

		local round = key[ROUNDS] - 1
		while (round > 2) do
			doInvRound(state, tmpState)
			addRoundKey(tmpState, key, round)
			round = round - 1

			doInvRound(tmpState, state)
			addRoundKey(state, key, round)
			round = round - 1
		end


		doInvRound(state, tmpState)
		addRoundKey(tmpState, key, round)
		round = round - 1

		doInvLastRound(tmpState, state)
		addRoundKey(state, key, round)

		return util.intsToBytes(state, output, outputOffset)
	end

	calcSBox()
	calcRoundTables()
	calcInvRoundTables()

	return {
		ROUNDS = ROUNDS,
		KEY_TYPE = KEY_TYPE,
		ENCRYPTION_KEY = ENCRYPTION_KEY,
		DECRYPTION_KEY = DECRYPTION_KEY,

		expandEncryptionKey = expandEncryptionKey,
		expandDecryptionKey = expandDecryptionKey,
		encrypt = encrypt,
		decrypt = decrypt,
	}
end)
local buffer=_W(function(_ENV, ...)
	local function new ()
		return {}
	end

	local function addString (stack, s)
		table.insert(stack, s)
	end

	local function toString (stack)
		return table.concat(stack)
	end

	return {
		new = new,
		addString = addString,
		toString = toString,
	}
end)
ciphermode=_W(function(_ENV, ...)
	local public = {}

	local random = math.random
	function public.encryptString(key, data, modeFunction, iv)
		if iv then
			local ivCopy = {}
			for i = 1, 16 do ivCopy[i] = iv[i] end
			iv = ivCopy
		else
			iv = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
		end

		local keySched = aes.expandEncryptionKey(key)
		local encryptedData = buffer.new()

		for i = 1, #data/16 do
			local offset = (i-1)*16 + 1
			local byteData = {string.byte(data,offset,offset +15)}

			iv = modeFunction(keySched, byteData, iv)

			buffer.addString(encryptedData, string.char(unpack(byteData)))
		end

		return buffer.toString(encryptedData)
	end

	function public.encryptECB(keySched, byteData, iv)
		aes.encrypt(keySched, byteData, 1, byteData, 1)
	end

	function public.encryptCBC(keySched, byteData, iv)
		util.xorIV(byteData, iv)
		aes.encrypt(keySched, byteData, 1, byteData, 1)
		return byteData
	end

	function public.encryptOFB(keySched, byteData, iv)
		aes.encrypt(keySched, iv, 1, iv, 1)
		util.xorIV(byteData, iv)
		return iv
	end

	function public.encryptCFB(keySched, byteData, iv)
		aes.encrypt(keySched, iv, 1, iv, 1)
		util.xorIV(byteData, iv)
		return byteData
	end

	function public.encryptCTR(keySched, byteData, iv)
		local nextIV = {}
		for j = 1, 16 do nextIV[j] = iv[j] end

		aes.encrypt(keySched, iv, 1, iv, 1)
		util.xorIV(byteData, iv)

		util.increment(nextIV)

		return nextIV
	end

	function public.decryptString(key, data, modeFunction, iv)
		if iv then
			local ivCopy = {}
			for i = 1, 16 do ivCopy[i] = iv[i] end
			iv = ivCopy
		else
			iv = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
		end

		local keySched
		if modeFunction == public.decryptOFB or modeFunction == public.decryptCFB or modeFunction == public.decryptCTR then
			keySched = aes.expandEncryptionKey(key)
		else
			keySched = aes.expandDecryptionKey(key)
		end

		local decryptedData = buffer.new()

		for i = 1, #data/16 do
			local offset = (i-1)*16 + 1
			local byteData = {string.byte(data,offset,offset +15)}

			iv = modeFunction(keySched, byteData, iv)

			buffer.addString(decryptedData, string.char(unpack(byteData)))
		end

		return buffer.toString(decryptedData)
	end

	function public.decryptECB(keySched, byteData, iv)
		aes.decrypt(keySched, byteData, 1, byteData, 1)
		return iv
	end

	function public.decryptCBC(keySched, byteData, iv)
		local nextIV = {}
		for j = 1, 16 do nextIV[j] = byteData[j] end

		aes.decrypt(keySched, byteData, 1, byteData, 1)
		util.xorIV(byteData, iv)

		return nextIV
	end

	function public.decryptOFB(keySched, byteData, iv)
		aes.encrypt(keySched, iv, 1, iv, 1)
		util.xorIV(byteData, iv)

		return iv
	end

	function public.decryptCFB(keySched, byteData, iv)
		local nextIV = {}
		for j = 1, 16 do nextIV[j] = byteData[j] end

		aes.encrypt(keySched, iv, 1, iv, 1)
		util.xorIV(byteData, iv)

		return nextIV
	end

	public.decryptCTR = public.encryptCTR

	return public
end)
AES128 = 16
AES192 = 24
AES256 = 32

ECBMODE = 1
CBCMODE = 2
OFBMODE = 3
CFBMODE = 4
CTRMODE = 4

local function pwToKey(password, keyLength, iv)
	local padLength = keyLength
	if (keyLength == AES192) then
		padLength = 32
	end

	if (padLength > #password) then
		local postfix = ""
		for i = 1,padLength - #password do
			postfix = postfix .. string.char(0)
		end
		password = password .. postfix
	else
		password = string.sub(password, 1, padLength)
	end

	local pwBytes = {string.byte(password,1,#password)}
	password = ciphermode.encryptString(pwBytes, password, ciphermode.encryptCBC, iv)

	password = string.sub(password, 1, keyLength)

	return {string.byte(password,1,#password)}
end

function encrypt(password, data, keyLength, mode, iv)
	assert(password ~= nil, "Empty password.")
	assert(password ~= nil, "Empty data.")

	local mode = mode or CBCMODE
	local keyLength = keyLength or AES128

	local key = pwToKey(password, keyLength, iv)

	local paddedData = util.padByteString(data)

	if mode == ECBMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptECB, iv)
	elseif mode == CBCMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptCBC, iv)
	elseif mode == OFBMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptOFB, iv)
	elseif mode == CFBMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptCFB, iv)
	elseif mode == CTRMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptCTR, iv)
	else
		warn("Unknown mode", 2)
	end
end



function decrypt(password, data, keyLength, mode, iv)
	local mode = mode or CBCMODE
	local keyLength = keyLength or AES128

	local key = pwToKey(password, keyLength, iv)

	local plain
	if mode == ECBMODE then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptECB, iv)
	elseif mode == CBCMODE then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptCBC, iv)
	elseif mode == OFBMODE then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptOFB, iv)
	elseif mode == CFBMODE then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptCFB, iv)
	elseif mode == CTRMODE then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptCTR, iv)
	else
		warn("Unknown mode", 2)
	end

	result = util.unpadByteString(plain)

	if (result == nil) then
		return nil
	end

	return result
end

getgenv().aes = {
	encrypt = encrypt,
	decrypt = decrypt
}
end)()
end)
__bundle_register("Features/Wipe", function(require, _LOADED, __bundle_register, __bundle_modules)
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
end)
__bundle_register("Modules/Configs", function(require, _LOADED, __bundle_register, __bundle_modules)
return (function()
	local Configs = {}
	Configs.TalentSpoof = {
		"Talent:Speed Emission",
		"Talent:Disbelief",
		"Talent:Endurance Runner",
		"Talent:Spinning Swordsman",
		"Talent:Nightchild",
		"Talent:Aerial Assault",
		"Talent:Moving Fortress",
		"Talent:Swift Rebound",
		"Talent:Blade Dancer",
		"Talent:Defiance",
		"Talent:Triathlete",
		"Talent:Graceful Landing",
		"Talent:Fast Blade",
		"Talent:Gale Leap",
		"Talent:Heavy Haul",
		"Talent:Kick Off",
		"Talent:Scaredy Cat",
		"Talent:Drifting Winds",
		"Talent:Strong Hold",
		"Talent:Tap Dancer",
		"Talent:Navae's Guidance",
		"Talent:Engage",
		"Talent:Seaborne",
	}
	Configs.LootFilters = {
		"Enchant",
		"Relic",
		"Legendary",
		"Mythic",
		"Rare",
		"Uncommon",
		"Common",
	}
	Configs.LootTypes = {
		"Rings",
		"Arms",
		"Boots",
		"Head",
		"Face",
		"Earrings",
		"Schematic",
		"Weapons",
		"Sidearms",
		"Shoulder",
		"Trinkets"
	}
	Configs.Fonts = {}
	Configs.TalentData = {"Shadow Call","Blindseer","Jus Karita","Radiant Dawn","Pathfinder","Public Figure","Whisper","Inferno","Weapon Master","Saboteur","Lancer","Ice Age","Flame Warden","Darksiphon","Artificer","Silencer","Freak of Nature","Beast Slayer","Surgeweaver","Escape Artist","Silvertongue","Pyromancer","Thunder Caster","Mountain Climber","Bulwark","Undying Ember","Lava Serpent","Empath","Merchant","Frost Forger","Shade","Limitbreaker","Champion","Immolator","Gale Duelist","Shadowcast Master","Thief","Grand Pathfinder","Frostdrawer","Soul Converter","Mental Fortress","Galebreather","Vigil of Winds","Frostthorn","Vow of Mastery","Survival Instinct","Omniscient","One Eyed King","Prospector","Vigil Swordsman","Flame Dancer","Thunderblade","Legion Shock Trooper","Galeforce","Miscellaneous","Glassdancer","Seekers of Sound","Unstable Capacitor","Sovereign of Slaughter","Aeromancer","Rampant Static","Duelist","Self-Shocker","Fallen Soul","Starkindred","Cutthroat","Authority Interrogator","The Emperor's Blade","Linkstrider","Charm Caster","Bastion","Cloudwalker","Thundercall Master","Flame Brawler","Flamecharmer","Bruiser","Thunder Brawler","Meditative Trance","Thundercaller","Ministry Prophet","Sturdy Resolve","Nomadic Way","Master","Expert","Adept","Initiate","Hunter","Metallurgist","Tavernkeep","The Divers","Stormblade","Jetstriker","Ignition Union","Critical Specialist","Navaen Nomad","Liberator","Marauder","Ministry Operative","Arcwarder","Drowned Secret","Tactician","Mindbreaker","The Negotiator","Athlete","Heretic","Shieldmaster","Navaen War Chief","Raging Bull","Lone Warrior","Assassin","Death Speaker","Static Weaver","Galebreathe Master","Shipwright","Apex Predator","Great Wall","Frostdraw Master","Amoran Seeker","Angler","Flow","Comrade","Brawler","Murmur","Flamecharm Master","Shadowcaster","Duelist Flame","Warrior","Butterfly","Fish","Waterborne","Protector","Singer","Acrobat","Javelin Lord","Mr Charm","Gale Kata","Master Survivalist","Frozen Warrior","Tower Knight","Metamancer","Ironsinger","Innate","Colossus","Falling Star Guard","Gunslinger","Alchemist","Cryomancer","Scholar of the Cloud","Genius Intellect","Justicar","Archsorcerer","Adept Caster","Thunder God","Oathless","Saint of Blades","Artisan","Trickster","Alley Cat","Aerial Dancer","Iron Will","Forest Hunter","Puppet Master","Ether Adept","Cryoni","Ghost in the Machine","The Demon Blade","Silver Whaler","Wraith","Visionshaper"}
	table.sort(Configs.TalentData, function(a, b)
		return a:lower() < b:lower()
	end)
	for i,v in pairs(Enum.Font:GetEnumItems()) do
		if v.Name =='Unknown' then continue end
		table.insert(Configs.Fonts, v.Name)
	end
	Configs.SellFilters = {
        "Tools",
        "Materials",
        "Books&Schematics",
        "Equipment",
        "Weapons",
        "TrainingGear",
        "Consumables",
        "Miscellaneous",
        "Relics",
        "QuestItems",
        "Tools",
        "Miscellaneous"
    }
    Configs.toolCategory = {}
	for i,v in pairs({
        [0] = "CurrentWeapon", 
        [1] = "Abilities", 
        [3] = "Abilities", 
        [13] = "Tools", 
        [14] = "Materials", 
        [15] = "Materials", 
        [11] = "Books&Schematics", 
        [19] = "Books&Schematics", 
        [10] = "Equipment", 
        [9] = "Equipment", 
        [8] = "Weapons", 
        [7] = "Weapons", 
        [5] = "TrainingGear", 
        [6] = "Consumables", 
        [18] = "Consumables", 
        [16] = "Miscellaneous", 
        [17] = "Relics", 
        [12] = "QuestItems", 
        [4] = "Tools", 
        [999] = "Miscellaneous"
	}) do
		Configs.toolCategory[v] = i
	end

	return Configs
end)()

end)
__bundle_register("Modules/Interface", function(require, _LOADED, __bundle_register, __bundle_modules)
getgenv().Library = require("Modules/Library")
local SaveManager = require("SaveManager")
local ThemeManager = require("ThemeManager")

local RunService = game:GetService("RunService")

local RequireMaid = require("Modules/Maid")
local LycorisConnect = RequireMaid.new()
local ClientFeature = require("Features/Client")
local NSFWFeature = require("Features/BWoken")
warn("Loaded Client Features")

local Window = Library:CreateWindow({
	Title = "Lycoris 1.0",
	Center = true,
	AutoShow = getgenv().silentmode == nil,
	TabPadding = 8,
	MenuFadeTime = 0.1,
})

function ourNotify(text, duration)
end

if getgenv().silentmode then
	Library.Notify = ourNotify
end

local function schedule(ID)
	local read = nil

	local response = function(...)
		read = {...}
	end

	table.insert(scheduler.tasks, { func = ClientFeature[ID], args = {}, callback = response })

	repeat task.wait() until read

	getrenv().print('feature finished', ID)

	return unpack(read)
end

local Groupbox = {}
do
	Groupbox.__index = Groupbox
	function Groupbox:new(Name, Right)
		local self_groupbox = {}
		if not Right then
			self_groupbox.Groupbox = self.Tab:AddLeftGroupbox(Name)
		else
			self_groupbox.Groupbox = self.Tab:AddRightGroupbox(Name)
		end
		setmetatable(self_groupbox, Groupbox)

		return self_groupbox
	end
	function Groupbox:newToggle(ID, Text, Default, Tip, Callback)
		return self.Groupbox:AddToggle(ID, {
			Text = Text,
			Default = Default,
			Tooltip = Tip,
			Callback = function(Value)
				if Callback then
					SecureCall(Callback, Value)
				end

				if ClientFeature[ID] then
					ClientFeature[ID]()
				end

				if NSFWFeature[ID] then
					--NSFWFeature[ID]()
				end
			end,
		})
	end
	function Groupbox:newSlider(ID, Text, Default, Min, Max, Rounding, Compact, Callback)
		return self.Groupbox:AddSlider(ID, {
			Text = Text,
			Default = Default,
			Min = Min,
			Max = Max,
			Rounding = Rounding,
			Compact = Compact,
			Callback = function(Value)
				if Callback then
					SecureCall(Callback, Value)
				end

				if ClientFeature[ID] then
					ClientFeature[ID]()
				end

				if NSFWFeature[ID] then
					--NSFWFeature[ID]()
				end
			end,
		})
	end
	function Groupbox:newDropdown(ID, Text, Values, Default, Multi, Tip, Callback)
		return self.Groupbox:AddDropdown(ID, {
			Values = Values,
			Default = Default,
			Multi = Multi,
			Text = Text,
			Tooltip = Tip,
			Callback = Callback,
		})
	end
	function Groupbox:newTextbox(ID, Text, Numeric, Default, Finished, Tip, Placeholder, Callback)
		self.Groupbox:AddInput(ID, {
			Default = Default,
			Numeric = Numeric,
			Finished = Finished,
			Text = Text,
			Tooltip = Tip,
			Placeholder = Placeholder,
			Callback = function(Value)
				if Callback then
					SecureCall(Callback, Value)
				end

				if ClientFeature[ID] then
					ClientFeature[ID]()
				end
			end,
		})
	end
	function Groupbox:newButton(Text, Func, DoubleClick, Tip)
		return self.Groupbox:AddButton({
			Text = Text,
			Func = Func,
			DoubleClick = DoubleClick,
			Tooltip = Tip,
		})
	end
	function Groupbox:newKeybind(ID, Text, Default, ToggleID, Mode)
		return self.Groupbox:AddLabel(Text):AddKeyPicker(ID, {
			Default = Default,
			NoUI = false,
			Text = Text,
			Mode = Mode,
			Callback = function()
				if typeof(ToggleID) == "function" then
					ToggleID()
				else
					Toggles[ToggleID]:SetValue(not Toggles[ToggleID].Value)
				end
			end,
		})
	end
	function Groupbox:newColorPicker(ID, Text, Default, Callback)
		return self.Groupbox:AddLabel(Text .. " Color"):AddColorPicker(ID, {
			Default = Default or Color3.fromRGB(255, 255, 255),
			Title = Text,
			Transparency = 0,
			Callback = Callback,
		})
	end
	function Groupbox:newLabel(Text)
		return self.Groupbox:AddLabel(Text)
	end
end

local Tab = {}
do
	Tab.__index = Tab
	function Tab:newGroupBox(Name, Right)
		self.GroupBoxes[Name] = Groupbox.new(self, Name, Right)
		return self.GroupBoxes[Name]
	end
	function Tab.new(Name)
		local self = setmetatable({}, Tab)
		self.GroupBoxes = {}
		self.Tab = Window:AddTab(Name)
		return self
	end
end

task.spawn(function()
	for i, v in pairs(Toggles) do
		if not ClientFeature[i] or not v.Value then
			continue
		end

		ClientFeature[i]()
	end
end)

return {
	Tab = Tab,
	Groupbox = Groupbox,
	Library = Library,
	SaveManager = SaveManager,
	ThemeManager = ThemeManager,
	Maid = LycorisConnect,
	ClientFeature = ClientFeature,
}

end)
__bundle_register("Features/BWoken", function(require, _LOADED, __bundle_register, __bundle_modules)
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

end)
__bundle_register("Features/Client", function(require, _LOADED, __bundle_register, __bundle_modules)
-- vsc qol
local getgenv = getgenv
local Toggles = Toggles

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = cloneref(game:GetService("Players"))
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local MemStorageService = game:GetService("MemStorageService")
local VIM = Instance.new("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Mouse = cloneref(LocalPlayer):GetMouse()
local Camera = workspace.CurrentCamera
Mouse.TargetFilter = workspace.Thrown

local IsChime = game.PlaceId == 6832944305

getgenv().Features = {}
getgenv().CachedPlayersData = {}

local EffectReplicator = getgenv().require(ReplicatedStorage:WaitForChild("EffectReplicator"))

---@module Modules/Deepwoken/KeyHandler
local KeyHandler = require("Modules/Deepwoken/KeyHandler")

---@module Features/Wipe
local Wipe = require("Features/Wipe")

---@module Features/StreamerMode
local StreamerMode = require("Features/StreamerMode")

---@module Modules/Utilities
local Utilities = require("Modules/Utilities")

local ControlModule = require("ControlModule")
local RequireMaid = require("Modules/Maid")
local Maid = RequireMaid.new()

getgenv().FeaturesMaid = Maid

local Character = LocalPlayer.Character
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

local LeftClick
local RightClick
local ServerSlide
local ServerSlideStop
local TalentPickerData
local CurrentChainFrame
local CurrentSanityFrame
local CurrentStack = 0
local HasPerfectStack = false

local StatsGui = StarterGui:WaitForChild("StatsGui")
local SurvivalStats = StatsGui and StatsGui:WaitForChild("SurvivalStats")
local StomachFrame = SurvivalStats and SurvivalStats:WaitForChild("Stomach")

local SanityFrame = StomachFrame:Clone()
SanityFrame.Name = "SanityFrame"
SanityFrame.Position = StomachFrame.Position + UDim2.new(UDim.new(0, 24), UDim.new(0, 0))
SanityFrame.Visible = false

local SanitySlider = SanityFrame:WaitForChild("Slider")
if SanitySlider then
	SanitySlider.BackgroundColor3 = Color3.fromRGB(12, 12, 187)
	SanitySlider.Size = UDim2.new(UDim.new(1, 0), UDim.new(0, 0))
end

local ChainFrame = SanityFrame:Clone()
ChainFrame.Name = "ChainFrame"
ChainFrame.Position = SanityFrame.Position + UDim2.new(UDim.new(0, 24), UDim.new(0, 0))
ChainFrame.Visible = false

local ChainSlider = ChainFrame:WaitForChild("Slider")
if ChainSlider then
	ChainSlider.BackgroundColor3 = Color3.fromRGB(154, 67, 211)
	ChainSlider.Size = UDim2.new(UDim.new(1, 0), UDim.new(0, 0))
end

local function GetPlayer(name)
	for i, v in pairs(Players:GetPlayers()) do
		if v.Name:lower() == name:lower() then
			return v
		end
	end
end

local function getlocation(chr)
	if Players:GetPlayerFromCharacter(chr) then
		local area = ReplicatedStorage.MarkerWorkspace:FindPartOnRayWithWhitelist(
			Ray.new(chr:GetPivot().p, Vector3.new(0, 5000, 0)),
			{ ReplicatedStorage.MarkerWorkspace.AreaMarkers }
		)
		if area then
			return area.Parent.Name
		else
			return "The Aratel/Etrean Sea"
		end
	end
end

local function talentPicker()
	local ChoiceFrame = LocalPlayer.PlayerGui:WaitForChild("TalentGui"):WaitForChild("ChoiceFrame")

	for _, v in pairs(ChoiceFrame:GetChildren()) do
		if not v:IsA("TextButton") then
			continue
		end

		local CardFrame = v:FindFirstChild("CardFrame")
		if not CardFrame then
			continue
		end

		local Invalid = false
		if
			not TalentPickerData
			or not Toggles.TalentPicker.Value
			or not TalentPickerData.talents
			or not table.find(TalentPickerData.talents, string.gsub(v.Name, "^%s*(.-)%s*$", "%1"))
		then
			Invalid = true
		end

		CardFrame.BorderColor3 = Color3.new(255, 0, 0)
		CardFrame.BorderSizePixel = Invalid and 0 or 10
	end
end

local CurrentlyViewing = nil
local function AddToView(v)
	local LastHoveredName = nil

	Maid:GiveTask(v.Player.Changed:Connect(function()
		local Player = v:WaitForChild("Player", 9e9)

		if not GetPlayer(Player.Text) then
			return
		end

		LastHoveredName = Player.Text

		Player.Text = Toggles.StreamerMode.Value and "Lycoris On Top" or Player.Text
	end))

	Maid[v] = v.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if CurrentlyViewing == LastHoveredName then
				CurrentlyViewing = LocalPlayer.Name
			else
				CurrentlyViewing = LastHoveredName
			end

			local Char = GetPlayer(CurrentlyViewing).Character
			if not Char then
				return
			end

			if not Char:FindFirstChild("HumanoidRootPart") then
				local Position = Char:GetAttribute('MapPos') + Vector3.new(0,Char:GetPivot().X,0)
				task.spawn(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, Char:GetPivot().p)
				task.spawn(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, Position)
				getgenv().Library:Notify("Player not loaded, last known area: " .. getlocation(Char), 2)
			else
				getgenv().Library:Notify("Viewing: " .. Players[Char.Name]:GetAttribute("CharacterName"), 1.5)
			end

			if Maid.CameraSubjectView then
				Maid.CameraSubjectView = nil
				warn("removed subject signal")
			end

			if Char == Character then
				game:GetService("CollectionService"):RemoveTag(LocalPlayer, "ForcedSubject")
				workspace.CurrentCamera.CameraSubject = Character
				return
			end

			game:GetService("CollectionService"):AddTag(LocalPlayer, "ForcedSubject")
			workspace.CurrentCamera.CameraSubject = Char
		end
	end)
end

local function SpawnNewFrame(FrameNumber)
	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local PlayerStatsGui = PlayerGui:WaitForChild("StatsGui")
	local PlayerSurvivalStats = PlayerStatsGui:WaitForChild("SurvivalStats")
	local Stomach = PlayerSurvivalStats:FindFirstChild("Stomach")
	local StomachVisible = Stomach and Stomach.Visible or true

	local function OnAncestorChange()
		if not CurrentSanityFrame or not CurrentSanityFrame:IsDescendantOf(game) then
			SpawnNewFrame(1)
		end

		if not CurrentChainFrame or not CurrentChainFrame:IsDescendantOf(game) then
			SpawnNewFrame(2)
		end
	end

	if FrameNumber == 1 then
		CurrentSanityFrame = SanityFrame:Clone()
		CurrentSanityFrame.Parent = PlayerSurvivalStats
		CurrentSanityFrame.Visible = Toggles.SanityCounter.Value and StomachVisible
		Maid:GiveTask(CurrentSanityFrame)
		Maid:GiveTask(CurrentSanityFrame.AncestryChanged:Connect(OnAncestorChange))
	end

	if FrameNumber == 2 then
		CurrentChainFrame = ChainFrame:Clone()
		CurrentChainFrame.Parent = PlayerSurvivalStats
		CurrentChainFrame.Visible = Toggles.PerfectStack.Value and StomachVisible
		Maid:GiveTask(CurrentChainFrame)
		Maid:GiveTask(CurrentChainFrame.AncestryChanged:Connect(OnAncestorChange))
	end
end

-- save iteration
local iteration = 1

-- get weapon anims
local weaponAnims = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Anims"):WaitForChild("Weapon")

-- invoke anim list
local invokeAnimList = weaponAnims:GetDescendants()

-- invoked animation tracks
local invokedAnimationTracks = {}

-- current timestamp
local invokeTimestamp = 0

-- invoke anims
local function invokeAnims()
	-- get our animator
	local animator = Humanoid:WaitForChild("Animator", 9e9)

	local function getRandomValues(n)
		local values = {}
		for _ = 1, n do
			values[#values+1] = invokeAnimList[math.random(1, #invokeAnimList)]
		end
		return values
	end

	-- invoke anims
	for _, invokeAnim in next, getRandomValues(10) do
		if typeof(invokeAnim) ~= "Instance" or not invokeAnim:IsA("Animation") then
			continue
		end

		-- load animation
		local success, animationTrack = pcall(animator.LoadAnimation, animator, invokeAnim)
		if not success then
			break
		end

		-- play, make it never end, and make it essentially invisible because it's priority is too low
		animationTrack:Play()

		if Toggles.VisibleAPBreaker and not Toggles.VisibleAPBreaker.Value then
			animationTrack:AdjustWeight(0.0001, 0)
		end

		-- save
		invokedAnimationTracks[#invokedAnimationTracks + 1] = animationTrack
	end
end

-- stop anims
local function stopAnims()
	for _, animationTrack in next, invokedAnimationTracks do
		pcall(animationTrack.Stop, animationTrack)
	end
end

local function apBreakerLoop()
	-- don't do anything if our feature isn't enabled
	if not Toggles.APBreaker.Value then
		return
	end

	-- check if we're on timeout...
	if (os.clock() - invokeTimestamp) < 0.1 then
		return
	end

	-- check if we should invoke
	local shouldInvoke = (iteration % 2) == 1

	-- start invoking
	if shouldInvoke then
		invokeAnims()
	else
		stopAnims()
	end

	-- set timestamp
	invokeTimestamp = os.clock()

	-- increase
	iteration = iteration + 1
end

local function onPlayerAdded(Player)
	task.spawn(Utilities.GetModRank, Player)
	task.spawn(Utilities.CheckVoidwalker, Player)

	local Backpack = Player:WaitForChild("Backpack")
	local PlayerList = {}

	for _, v in pairs(Players:GetPlayers()) do
		if v == Players.LocalPlayer then
			continue
		end
		table.insert(PlayerList, v.Name)
	end

	Options.TPMobToTarget.Values = PlayerList
	Options.TPMobToTarget:SetValues(PlayerList)
	
	Options.ExportBuildPlayer.Values = PlayerList
	Options.ExportBuildPlayer:SetValues(PlayerList)

	repeat
		task.wait()
	until game:GetService("CollectionService"):HasTag(Backpack, "Loaded")

	task.spawn(Utilities.GetModRank, Player)
	task.spawn(Utilities.CheckVoidwalker, Player)

	Options.AutoParryWhitelist.Values = PlayerList
	Options.AutoParryWhitelist:SetValues(PlayerList)
	
	Options.ExportBuildPlayer.Values = PlayerList
	Options.ExportBuildPlayer:SetValues(PlayerList)

	for i, v in pairs(Backpack:GetChildren()) do
		task.spawn(Utilities.CheckLegendaryWeapon, Player, v)
	end

	Maid[Player.Name .. "backpackadded"] = Backpack.ChildAdded:Connect(function(v)
		task.spawn(Utilities.CheckLegendaryWeapon, Player, v)
	end)

	getgenv().FriendsCache = getgenv().FriendsCache or {}
	getgenv().FriendsCache[Player] = Players.LocalPlayer:IsFriendsWith(Player.UserId) == true and true or false
end

function CheckFacing(self)
	local UserRootPart = RootPart
	local RootPart = self.Character:FindFirstChild("HumanoidRootPart")
	if not RootPart or not UserRootPart then
		return
	end

	local DeltaOnTargetToLocal = (UserRootPart.Position - RootPart.Position).Unit
	local TargetToLocalResult = UserRootPart.CFrame.LookVector:Dot(DeltaOnTargetToLocal) <= -0.1

	return TargetToLocalResult
end

local dashcastglobalcd = false
local dashcastcustomcd = {}
local function DashCasting(custom_cd, sec)
	if not Character or not RootPart or not Humanoid or not Character:FindFirstChild("Agility") then
		return
	end

	local nearest = Utilities.GetNearestCharacter()
	if not nearest then
		return
	end

	if not CheckFacing({Character = nearest}) then
		return
	end

	if (nearest.HumanoidRootPart.Position - RootPart.Position).Magnitude < 8 then
		return
	end

	if dashcastglobalcd then
		return
	else
		if not custom_cd then
			dashcastglobalcd = true
			task.delay(Options.DashCasting_CD.Value, function()
				dashcastglobalcd = false
			end)
		end
	end

	if custom_cd then
		if dashcastcustomcd[custom_cd] then
			return
		else
			dashcastcustomcd[custom_cd] = true
			task.delay(sec, function()
				dashcastcustomcd[custom_cd] = nil
			end)
		end
	end
	
	local Agility = Character:FindFirstChild("Agility").Value
	local LookAtVect = CFrame.new(RootPart.Position, nearest.HumanoidRootPart.Position).LookVector
	local Velocity = Agility * 0.5 * 1 + 60

	if RootPart:FindFirstChildOfClass("BodyVelocity") then
		RootPart:FindFirstChildOfClass("BodyVelocity").Parent = nil
	end

	local BodyVelocity = Instance.new("BodyVelocity")
	game.CollectionService:AddTag(BodyVelocity, "AllowedBM")
	BodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
	BodyVelocity.Velocity = LookAtVect * Velocity * 1.25
	BodyVelocity.Parent = RootPart
	BodyVelocity.Name = "Mover"

	game.Debris:AddItem(BodyVelocity, 0.1)
end

getgenv().DashcastFunction = DashCasting

local function onCharacterAdded(NewCharacter)
	Character = NewCharacter
	RootPart = Character:WaitForChild("HumanoidRootPart")
	Humanoid = Character:WaitForChild("Humanoid")

	repeat
		task.wait()
	until Character:FindFirstChild("Requests", true) and not Character:FindFirstChild("LeftClick", true) and not Character:FindFirstChild("ServerSlide", true) and not Character:FindFirstChild("ServerSlideStop", true)
	task.wait(0.5)

	LeftClick = KeyHandler.GetKey("LeftClick")
	RightClick = KeyHandler.GetKey("RightClick")
	ServerSlide = KeyHandler.GetKey("ServerSlide")
	ServerSlideStop = KeyHandler.GetKey("ServerSlideStop")

	getgenv().LeftClickRemote = LeftClick
	getgenv().RightClickRemote = RightClick
	getgenv().BlockRemote = KeyHandler.GetKey("Block")
	getgenv().UnblockRemote = KeyHandler.GetKey("Unblock")
	getgenv().DodgeRemote = KeyHandler.GetKey("Dodge")
	getgenv().StopDodgeRemote = KeyHandler.GetKey("StopDodge")

	-- Sanity...
	local Sanity = Character:WaitForChild("Sanity")

	-- Modify sanity counter...
	local function ModifySanityCounter(Value)
		-- Check for sanity frame...
		if not CurrentSanityFrame then
			return
		end

		-- Get slider...
		local Slider = CurrentSanityFrame:FindFirstChild("Slider")
		if not Slider then
			return
		end

		-- Modify slider...
		local SliderPercentage = 1 - Value / Sanity.MaxValue
		Slider.Size = UDim2.new(UDim.new(1.0, 0.0), UDim.new(math.min(SliderPercentage, 1.0), 0.0))
	end

	-- Modify stack...
	local function ModifyStack(Stack)
		-- Set stack...
		CurrentStack = Stack

		-- Check for chain frame...
		if not CurrentChainFrame then
			return
		end

		-- Get slider...
		local Slider = CurrentChainFrame:FindFirstChild("Slider")
		if not Slider then
			return
		end

		-- Modify slider...
		local SliderPercentage = CurrentStack / 20
		Slider.Size = UDim2.new(UDim.new(1.0, 0.0), UDim.new(math.min(SliderPercentage, 1.0), 0.0))
	end

	do -- Auto Wisp
		if Maid.WispFunc then
			Maid.WispFunc = nil
		end
		Maid.WispFunc = LocalPlayer.PlayerGui.SpellGui.SpellFrame.Symbols.ChildAdded:Connect(Utilities.AutoWisp)
	end

	do -- Auto Loot
		if Maid.AutoLootChild then
			Maid.AutoLootChild = nil
		end
		Maid.AutoLootChild = LocalPlayer.PlayerGui.ChildAdded:Connect(Utilities.AutoLoot)
	end

	do -- Sanity Counter
		if Maid.SanityCounter then
			Maid.SanityCounter = nil
		end

		ModifySanityCounter(Sanity.Value)
		Maid.SanityCounter = Sanity.Changed:Connect(ModifySanityCounter)
	end

	do -- Talent Picker
		if Maid.TalentListener then
			Maid.TalentListener = nil
		end

		Maid.TalentListener = RunService.Heartbeat:Connect(talentPicker)
	end

	do -- Player View
		local PlayerFrame = LocalPlayer.PlayerGui:WaitForChild("LeaderboardGui").MainFrame.ScrollingFrame
		local function onFrameAdded(v)
			if not v:IsA("Frame") then
				return
			end
			task.spawn(AddToView, v)
		end

		if Maid.PlayerFrameConnection then
			Maid.PlayerFrameConnection = nil
		end
		Maid.PlayerFrameConnection = PlayerFrame.ChildAdded:Connect(onFrameAdded)

		for _, v in pairs(PlayerFrame:GetChildren()) do
			onFrameAdded(v)
		end
	end

	do -- Effect Handler
		local SaveTime = {}
		getgenv().EffectHandlerHash = EffectReplicator:GetEffectsHash()
		
		EffectReplicator.EffectRemoving:Connect(function(Effect)
			EffectHandlerHash = EffectReplicator:GetEffectsHash()
			if Effect.Class == "PerfectStack" then
				ModifyStack(0)
				HasPerfectStack = false
			end
			if Toggles.EffectLog.Value then
				warn("[Class]: " .. Effect.Class .. "\n[Timeout]: " .. tick() - (SaveTime[Effect.ID] or tick()))
			end
		end)

		local Mantra 
		
		if Maid.MantraCounter then
			Maid.MantraCounter = nil
		end

		Maid.MantraCounter = task.spawn(function()
			while true do
				for i,v in pairs(LocalPlayer.Backpack:GetChildren()) do
					if v.Name:match("Mantra:") and not v.Name:match("Recalled") then
						Mantra = v
						break
					end
				end
				task.wait(4)
			end
		end)
		
		EffectReplicator.EffectAdded:Connect(function(Effect)
			SaveTime[Effect.ID] = tick()
			EffectHandlerHash = EffectReplicator:GetEffectsHash()

			if Toggles.EffectLog.Value then
				print("[Class]: " .. Effect.Class .. "\n[Value]: " .. tostring(Effect.Value))
			end
			if Effect.Class == "LightAttack" and Toggles.FastSwing.Value then
				rawset(Effect, "Disabled", true)
			end
			if Effect.Class == "OverrideSpeed" and Toggles.FeintFlourish.Value then
				task.wait(.07)

				if not EffectReplicator:FindEffect("MidAttack") then
					return
				end

				if not Mantra or not Humanoid or EffectReplicator:FindEffect("FeintCool") then
					return
				end
				
				print("[FeintFlourish]: Using Mantra")

				Humanoid:EquipTool(Mantra)

				task.wait(.09)

				print("[FeintFlourish]: Feinting Mantra")
				
				RightClick:FireServer({
					Left = true,
					Right = true,
					W = false,
					A = false,
					S = false,
					D = false,
				})
			end
			if Effect.Class == "Burning" and Toggles.AntiFire.Value then
				ServerSlide:FireServer(true)
				task.wait(.3)
				ServerSlideStop:FireServer()
			end
			if (Effect.Class == "NoJump" or Effect.Class == "NoJumpAlt") and Toggles.NoJumpCooldown.Value then
				rawset(Effect, "Disabled", true)
			end
			if Effect.Class == "ClientDodge" and Toggles.AutoRollCancel.Value then
				EffectReplicator:CreateEffect("Feint"):Debris(.1)
			end
			if Effect.Class == "UsingSpell" and Toggles.AutoPerfectCast.Value then
				local holdm1 = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
				VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
				task.wait()
				VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
				if holdm1 then
					task.wait()
					VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
				end
			end
			if Effect.Class == "UsingSpell" and Toggles.DashCasting.Value then
				DashCasting()
			end
			if Effect.Class == "PerfectionCool" and HasPerfectStack then
				ModifyStack(CurrentStack + 1)
			end
			if Effect.Class == "PerfectStack" then
				ModifyStack(Effect.Value)
				HasPerfectStack = true
			end
			if table.find({ "Knocked", "Ragdoll" }, Effect.Class) and Toggles.RagdollCancel.Value then
				VIM:SendMouseButtonEvent(1, 1, 1, true, game, 1)
				task.wait()
				VIM:SendMouseButtonEvent(1, 1, 1, false, game, 1)
			end
			if Effect.Class == "Speed"  and Effect.Value < 0 and Toggles.NoSpeedDebuff.Value then
				rawset(Effect, "Value", 0)
			end
			if Effect.Class == "BeingWinded" and Toggles.AntiWind.Value then
				rawset(EffectReplicator.Effects, Effect.ID, nil)
			end
			if Effect.Class == "SpeedOverride"  and Effect.Value < 14 and Toggles.NoSpeedDebuff.Value then
				rawset(EffectReplicator.Effects, Effect.ID, nil)
			end
			if (Effect.Class == "RollCancelFatigue" or Effect.Class == "DownComesTheClaw") then
				if Toggles.NoRollFatigue.Value then
					rawset(EffectReplicator.Effects, Effect.ID, nil)
				end
			end
			if Effect.Class == "SHDash" and not EffectReplicator:FindEffect('SHDashMediumCD') then
				-- if Toggles.AutoFlowState.Value then
				-- 	local FlowState = LocalPlayer.Backpack:FindFirstChild("Talent:Flow State")
				-- 	if not FlowState then
				-- 		return
				-- 	end

				-- 	Humanoid:EquipTool(FlowState)
				-- end
			end
			if (Effect.Class == "Feint" or Effect.Class == "ClientFeint") then
				if Toggles.ExtendRollCancel.Value and Humanoid and not EffectReplicator:FindEffect('ExtendedRoll') and EffectReplicator:FindEffect('ClientDodge') then
					EffectReplicator:CreateEffect('ExtendedRoll'):Debris(.3)
					local MoveDirection = Humanoid.MoveDirection
					
					---@type BodyVelocity
					local bv = Utilities.NewBodyMover("BodyVelocity")
					bv.MaxForce = Vector3.new(50000, 0, 50000)
					bv.Velocity = MoveDirection * 70
					
					for i,v in pairs(Character:GetDescendants()) do
						if v.Name == 'Mover' or v.Name == 'EasyCancel' then
							v:Destroy()
						end
					end

					bv.Parent = RootPart
	
					game:GetService('Debris'):AddItem(bv, 0.12)
				end
			end
		end)
	end
end

local function LerpToGoal(Goal, StayUntilFinished, Yield)
	local BindableEvent = Instance.new("BindableEvent")
	local Finished = false
	local Cancelled = false do
		BindableEvent.Event:Connect(function()
			Cancelled = true
		end)
	end

	task.spawn(function()
		local Distance = (RootPart.Position - Goal).Magnitude
	
		local StartPos = CFrame.new(RootPart.Position)
		local FinalCF
		local Speed = 1.1
	
		for i = 0, Distance, Speed do
			if Cancelled then break end
	
			local Progress = i/Distance
			local VertCF = CFrame.new(Goal)
			local LerpCF = StartPos:Lerp(VertCF, Progress) * CFrame.new(0,2,0)
			
			local RayResult = workspace:Raycast(LerpCF.Position, LerpCF.UpVector*-800, RaycastParams.new({
				FilterType = Enum.RaycastFilterType.Exclude,
				FilterDescendantsInstances = { Character }
			}))
	
			local GotPosition = RayResult and RayResult.Position or LerpCF.Position
	
			if not RayResult.Instance then
				GotPosition = LerpCF.Position
			end
	
			local Position = GotPosition
			local LinearPos = Vector3.new(VertCF.X, Position.Y, VertCF.Z)
			FinalCF = CFrame.new(Position, LinearPos) * CFrame.new(0,-9.5,0) * CFrame.Angles(0,0,math.rad(180))
	
			RootPart.Velocity = Vector3.zero
			RootPart.CFrame = FinalCF
			task.wait()
		end
	
		if StayUntilFinished then
			repeat
				if Cancelled then break end
				RootPart.Velocity = Vector3.zero
				RootPart.CFrame = FinalCF
				task.wait()
			until game:GetService("MemStorageService"):HasTag("FinishedTween")
	
			if game:GetService("MemStorageService"):HasTag("FinishedTween") then
				game:GetService("MemStorageService"):RemoveTag("FinishedTween")
			end
		else
			RootPart.Velocity = Vector3.zero
			RootPart.CFrame = CFrame.new(Goal)
		end

		Finished = true
	end)

	if Yield then
		repeat
			task.wait()
		until Finished
	end

	return BindableEvent
end

local function SetTweenFinished()
	game:GetService("MemStorageService"):AddTag("FinishedTween")
end

function Features.Fly()
	if not Toggles.Fly.Value then
		Maid.FlyBV = nil
		Maid.FlyConnect = nil
		return
	end

	Maid.FlyBV = Utilities.NewBodyMover("BodyVelocity")
	Maid.FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	Maid.FlyConnect = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(deltaTime)
		if Toggles.PVPMode.Value then
			Maid.FlyBV.Parent = nil
			return
		end

		if Toggles.ChimeSafety.Value and IsChime then
			Maid.FlyBV.Parent = nil
			return
		end

		if not RootPart then
			return
		end

		local bv = RootPart:FindFirstChildOfClass("BodyVelocity")
		if bv and bv ~= Maid.FlyBV then
			bv.Parent = nil
		end

		local Velocity = Camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * Options.FlySpeed.Value)

		if Utilities:GetInput("space") then
			Velocity = Velocity + Vector3.new(0, Options.FlyUpSpeed.Value, 0)
		end

		Maid.FlyBV.Parent = RootPart
		Maid.FlyBV.Velocity = Velocity
	end))
end

local CurrentTween = nil
local ActiveBloodJar = nil
local ActivePodium = nil

local function resetTween()
	if not CurrentTween then
		return
	end

	CurrentTween:Pause()
	CurrentTween:Cancel()
	CurrentTween = nil
end

local function tweenToBloodJars(ChaserEntity)
	-- Check for blood jar...
	if
		not ActiveBloodJar
		or (ActiveBloodJar and not ActiveBloodJar.Value)
		or (ActiveBloodJar and ActiveBloodJar.Value and not ActiveBloodJar.Value.Parent)
	then
		-- Set to Chaser's active blood jar
		ActiveBloodJar = ChaserEntity.HumanoidRootPart:FindFirstChild("BloodJar")
	end

	-- Check for blood jar...
	if not ActiveBloodJar then
		-- Reset tween...
		return resetTween()
	end

	-- Get part...
	local Part = ActiveBloodJar.Value.Parent:FindFirstChildOfClass("Part")
	if not Part then
		-- Reset active blood jar...
		ActiveBloodJar = nil

		-- Reset tween...
		return resetTween()
	end

	-- Check if we already have a tween...
	if CurrentTween then
		return
	end

	-- Get distance...
	local Distance = (Part.Position - RootPart.Position).Magnitude

	-- Tween...
	CurrentTween = game:GetService("TweenService"):Create(RootPart, TweenInfo.new(Distance / 80), {
		CFrame = CFrame.new(Part.Position),
	})
	CurrentTween:Play()
	CurrentTween.Completed:Connect(function()
		CurrentTween = nil
	end)
end

local function tweenToAltars(Floor1Stuff)
	-- Get first empty altar...
	local function getFirstEmptyAltar()
		-- Loop stuff...
		for _, instance in next, Floor1Stuff:GetChildren() do
			-- Check for altar...
			if instance.Name ~= "Altar" or not instance:IsA("Model") then
				continue
			end

			-- Check if not empty...
			if instance:FindFirstChild("BoneSpear") then
				continue
			end

			-- Return altar...
			return instance
		end
	end

	-- Check for active podium...
	if not ActivePodium then
		-- Get first empty altar...
		local firstEmptyAltar = getFirstEmptyAltar()

		-- Check if it doesn't exist...
		if not firstEmptyAltar then
			return
		end

		-- Set active podium...
		ActivePodium = firstEmptyAltar
	end

	-- Check if the empty podium has a spear in it now...
	-- If so, reset the tween...
	if ActivePodium:FindFirstChild("BoneSpear") then
		return resetTween()
	end

	-- Check if we already have a tween...
	if CurrentTween then
		return
	end

	-- Get distance...
	local Distance = (ActivePodium:GetPivot().Position - RootPart.Position).Magnitude

	-- Tween...
	CurrentTween = game:GetService("TweenService"):Create(RootPart, TweenInfo.new(Distance / 80), {
		CFrame = CFrame.new(ActivePodium:GetPivot().Position),
	})
	CurrentTween:Play()
	CurrentTween.Completed:Connect(function()
		CurrentTween = nil
	end)
end

local function tweenToObjective()
	-- Get chaser...
	local ChaserEntity = workspace.Live:FindFirstChild(".chaser")

	-- Get boss room...
	local BossRoom = workspace:FindFirstChild("TrueAvatarBossRoom")
	local Floor1Stuff = BossRoom and BossRoom:FindFirstChild("Floor1Stuff") or nil

	-- Check if tweening is off...
	if not Toggles.TweenToObjective.Value or not Options.TweenToObjectiveKeybind:GetState() then
		-- Reset tween...
		return resetTween()
	end

	-- Ethiron room, we'll probably want to move towards the altars...
	if Floor1Stuff then
		tweenToAltars(Floor1Stuff)
	end

	-- Chaser is alive, we'll probably want to move towards blood jars...
	if ChaserEntity then
		tweenToBloodJars(ChaserEntity)
	end
end

function Features.Speedhack()
	if not Toggles.Speedhack.Value then
		Maid.Speedhack = nil
		return
	end

	Maid.Speedhack = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		if Toggles.PVPMode.Value or Toggles.Fly.Value then
			return
		end
		
		if Toggles.ChimeSafety.Value and IsChime then
			return
		end

		if not RootPart or not Humanoid then
			return
		end

		RootPart.Velocity = RootPart.Velocity * Vector3.new(0, 1, 0)
		if Humanoid.MoveDirection.Magnitude > 0 then
			RootPart.Velocity = RootPart.Velocity + Humanoid.MoveDirection.Unit * Options.Speedhack.Value
		end
	end))
end

function Features.AutoFish()
	if not Toggles.AutoFish.Value then
		Maid.DangerListener = nil
		Maid.AutoFishRemoteListener = nil
		Maid.AutoFishThrownListener = nil
		return
	end

	Maid.AutoFishThrownListener = workspace.Thrown.ChildAdded:Connect(function(child)
		if not child:WaitForChild("Lid", 10) or not Toggles.AutoFish.Value then
			return
		end

		if
			(child:FindFirstChild("Lid").Position - Character.HumanoidRootPart.Position).Magnitude >= 15
			or not Toggles.AutoFishNotify.Value
			or Options.AutoFishWebhook.Value == ""
		then
			return
		end

		-- interact with chest until we get a prompt
		repeat
			fireproximityprompt(child:WaitForChild("InteractPrompt"))
			task.wait()
		until LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt")

		-- pools
		local Pools = {}
		local ConstructWord = "Chest Pools: \n "
		local Prompt = LocalPlayer.PlayerGui:WaitForChild("ChoicePrompt")

		-- chest collection
		repeat
			for i, v in next, Prompt.ChoiceFrame.Options:GetChildren() do
				-- skip non text button
				if not v:IsA("TextButton") then
					continue
				end

				-- parse
				if v.Name:match("$") and #v.Name:split("$")[1] < 24 then
					if not Pools[v.Name] then
						local text = v:WaitForChild("Stats") and v.Stats.ContentText or "N/A"
						if text:match("Dolor amet") then
							text = "N/A"
						end
						Pools[v.Name] = text
					end
				else
					if not Pools[v:WaitForChild("Title").Text] then
						local text = v:WaitForChild("Stats") and v.Stats.ContentText or "N/A"
						if text:match("Dolor amet") then
							text = "N/A"
						end
						Pools[v:WaitForChild("Title").Text] = text
					end
				end

				-- grab
				firesignal(v.MouseButton1Click)
			end
			task.wait()
		until not Prompt:FindFirstChild("ChoiceFrame")

		-- construct message
		for i, v in pairs(Pools) do
			i = i:split("$") and i:split("$")[1] or i
			ConstructWord = ConstructWord .. ("`[%s]: [%s]` \n"):format(i, v)
		end

		-- send to webhook
		request({
			Url = Options.AutoFishWebhook.Value,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({
				content = ConstructWord,
			}),
		})
	end)

	local FishingRod = Character:FindFirstChild("Fishing Rod") or LocalPlayer.Backpack:FindFirstChild("Fishing Rod")
	local RemoteEvent = FishingRod:WaitForChild("FishinScript"):WaitForChild("RemoteEvent")
	local ActiveDirection = 'a'
	local Caught = false
	local SuccessBob = false

	local function CatchFish()
		if not Toggles.AutoFish.Value then
			return
		end

		getgenv().Library:Notify("Attempting to fish", 2)

		if FishingRod and FishingRod.Parent then
			Humanoid:EquipTool(FishingRod)
			task.wait(0.5)
			VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
			task.wait(Options.AutoFishDelay.Value)
			VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
		else
			getgenv().Library:Notify("No Fishing Rod was found. cancelling autofish", 3)
		end
	end

	Maid.DangerListener = EffectReplicator.EffectAdded:Connect(function(Effect)
		if Effect.Class ~= 'Danger' then
			return
		end
		
		getgenv().Library:Notify("Attempting to kill danger mob", 2)

		while EffectReplicator:FindEffect("Danger") and Character do
			if not Character:FindFirstChild("Weapon") then
				Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Weapon"))
				task.wait(0.2)
			end

			LeftClick:FireServer(false, Mouse.Hit, {
				["W"] = false,
				["A"] = false,
				["S"] = false,
				["D"] = false,
				["Right"] = false,
				["Left"] = false,
				ctrl = false,
			})

			task.wait(.15)
		end

		task.wait(.5)

		CatchFish()
	end)

	Maid.AutoFishRemoteListener = RemoteEvent.OnClientEvent:Connect(function(arg, dir)
		if arg == 'dir' then
			ActiveDirection = dir
		end
		if arg == 'caught' then
			getgenv().Library:Notify("Caught fish", 2)
			Caught = true
		end
		if arg == 'hooked' then
			while not Caught do
				RemoteEvent:FireServer('m1', {
					a = ActiveDirection == 'a',
					s = ActiveDirection == 's',
					d = ActiveDirection == 'd'
				})
				task.wait(.05)
			end

			Caught = false
			SuccessBob = false

			task.wait(.5)

			CatchFish()
		end
		if arg == 'bobby' then
			SuccessBob = true
		end
	end)

	CatchFish()
end

function Features.NoClip()
	if not Toggles.NoClip.Value then
		Maid.NoClip = nil

		if not Humanoid then
			return
		end

		Humanoid:ChangeState("Physics")
		task.wait()
		Humanoid:ChangeState("RunningNoPhysics")

		return
	end

	Maid.NoClip = RunService.Stepped:Connect(function()
		if not RootPart then
			return
		end
		
		if Toggles.ChimeSafety.Value and IsChime then
			return
		end

		local Knocked = EffectReplicator:FindEffect("Knocked")
		local disablenoclip = Toggles.disableNoClipWhenKnocked.Value or Toggles.PVPMode.Value

		for _, v in pairs(Character:GetDescendants()) do
			if not v:IsA("BasePart") then
				continue
			end

			v.CanCollide = disablenoclip and Knocked
		end
	end)
end

function Features.InfJump()
	if not Toggles.InfJump.Value then
		Maid.InfJump = nil
		return
	end

	Maid.InfJump = UserInputService.InputBegan:Connect(LPH_NO_VIRTUALIZE(function(input, gpe)
		if gpe then
			return
		end

		if not RootPart or not Humanoid then
			return
		end

		if input.KeyCode == Enum.KeyCode.Space then
			while UserInputService:IsKeyDown(Enum.KeyCode.Space) do
				if Toggles.PVPMode.Value then
					task.wait()
					return
				end

				if Toggles.ChimeSafety.Value and IsChime then
					task.wait()
					return
				end

				local bv = RootPart:FindFirstChildOfClass("BodyVelocity")
					or RootPart:FindFirstChildOfClass("BodyPosition")
				if bv and bv ~= Maid.FlyBV then
					bv.Parent = nil
				end

				RootPart.Velocity = RootPart.Velocity * Vector3.new(1, 0, 1)
				RootPart.Velocity = RootPart.Velocity + Vector3.new(0, Options.InfJump.Value, 0)
				task.wait()
			end
		end
	end))
end

function Features.NoFog()
	if not Toggles.NoFog.Value then
		Maid.NoFog = nil
		return
	end

	Maid.NoFog = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		game.Lighting.FogStart = 10000000000
		game.Lighting.FogEnd = 10000000000
		if game.Lighting:FindFirstChildOfClass("Atmosphere") then
			game.Lighting:FindFirstChildOfClass("Atmosphere").Density = 0
		end
	end))
end

local playerBlindFold = nil
function Features.NoBlind()
	if not Toggles.NoBlind.Value then
		Maid.NoBlind = nil

		if playerBlindFold then
			playerBlindFold.Parent = LocalPlayer.Backpack
			playerBlindFold = nil
		end

		return
	end

	Maid.NoBlind = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		local SanityDoF = game:GetService('Lighting'):FindFirstChild('SanityDoF')
		local SanityCorrect = game:GetService('Lighting'):FindFirstChild('SanityCorrect')
		if SanityDoF then
			SanityDoF.Enabled = false
		end
		if SanityCorrect then
			SanityCorrect.Enabled = false
		end

		local backpack = LocalPlayer:FindFirstChild("Backpack")
		if not backpack then
			return
		end

		local blindFold = backpack:FindFirstChild("Talent:Blinded") or backpack:FindFirstChild("Flaw:Blind")
		if not blindFold then
			return
		end

		blindFold.Parent = nil
		playerBlindFold = blindFold
	end))
end

local LastBlurSize = 0
function Features.NoBlur()
	if not Toggles.NoBlur.Value then
		Maid.NoBlur = nil

		game.Lighting.GenericBlur.Size = LastBlurSize
		LastBlurSize = 0

		return
	end

	LastBlurSize = game.Lighting.GenericBlur.Size

	Maid.NoBlur = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		game.Lighting.GenericBlur.Size = 0
	end))
end

function Features.FullBright()
	if not Toggles.FullBright.Value then
		game.Lighting.GlobalShadows = true
		Maid.FullBright = nil
		return
	end

	Maid.FullBright = RunService.Heartbeat:Connect(function()
		game.Lighting.GlobalShadows = false
	end)
end

function Features.M1Hold()
	if not Toggles.M1Hold.Value then
		Maid.M1Hold = nil
		return
	end

	local function canAttack()
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			and LeftClick
			and ((Toggles.BlockInput.Value and Status and not Status.Busy) or not Toggles.BlockInput.Value)
	end

	Maid.M1Hold = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		if not canAttack() then
			return
		end

		if not RootPart or not Humanoid then
			return
		end

		if not Utilities:GetInput("m1") or EffectReplicator:FindEffect("UsingSpell") then
			return
		end

		local Character = Utilities.GetCharacter()

		local Properties = {
			["W"] = false,
			["A"] = false,
			["S"] = false,
			["D"] = false,
			["Right"] = false,
			["Left"] = false,
			ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl),
		}

		if
			Character
			and Character:FindFirstChild("RightHand")
			and Character:FindFirstChild("LeftHand")
			and Character.RightHand:FindFirstChild("Gun", true)
			and Character.LeftHand:FindFirstChild("Gun", true)
		then
			repeat
				task.wait()
			until not EffectReplicator:FindEffect("LightAttack")

			repeat
				task.wait()
				LeftClick:FireServer(Utilities:InAir(), Mouse.Hit, Properties)
				if not canAttack() then
					break
				end
			until EffectReplicator:FindEffect("LightAttack")

			if not canAttack() then
				return
			end

			repeat
				task.wait()
			until not EffectReplicator:FindEffect("LightAttack")

			if not canAttack() then
				return
			end

			repeat
				task.wait()
				RightClick:FireServer(Utilities:InAir(), Mouse.Hit, Properties)
				if not canAttack() then
					break
				end
			until EffectReplicator:FindEffect("LightAttack")
		else
			LeftClick:FireServer(Utilities:InAir(), Mouse.Hit, Properties)
		end
	end))
end

local FastSwingClass = { "LightAttack", "HeavyAttack", "OffhandAttack" }
function Features.FastSwing()
	if not Toggles.FastSwing.Value then
		Maid.FastSwing = nil
		return
	end

	if not RootPart then
		return
	end

	Maid.FastSwing = EffectReplicator.EffectAdded:Connect(LPH_NO_VIRTUALIZE(function(v)
		if table.find(FastSwingClass, v.Class) then
			rawset(EffectReplicator.Effects, v.ID, nil)
		end
	end))
end

function Features.NoStun()
	if not Toggles.NoStun.Value then
		Maid.NoStun = nil
		return
	end

	repeat
		task.wait()
	until LeftClick

	Maid.NoStun = EffectReplicator.EffectAdded:Connect(LPH_NO_VIRTUALIZE(function(v)
		if table.find(Utilities.NoStunEffects, v.Class) then
			rawset(EffectReplicator.Effects, v.ID, nil)
		end
	end))
end

local TalentSelect = {}
function Features.TalentSpoofer()
	local Talents = Options.TalentList.Value
	if typeof(Talents) == "string" then
		Talents = { Talents }
	end

	for _, v in pairs(TalentSelect) do
		if not table.find(Talents, v.Name) then
			TalentSelect[v] = nil
			v:Destroy()
		end
	end

	if Talents[1] == "" then
		return
	end

	for v, _ in pairs(Talents) do
		if not LocalPlayer.Backpack:FindFirstChild(v) then
			local talent = Instance.new("Folder")
			talent.Name = v
			talent.Parent = LocalPlayer.Backpack
			TalentSelect[talent] = talent
		end
	end
end

local StreamerModeEnabled = false
function Features.StreamerMode()
	if not Toggles.StreamerMode.Value then
		if StreamerModeEnabled then
			StreamerModeEnabled = false
			StreamerMode.Revert()
		end

		return
	end

	StreamerModeEnabled = true
	StreamerMode.Init()
end

function Features.RandomizeName()
	if not Toggles.StreamerMode.Value then
		return
	end

	StreamerMode.RandomizeName()
end

function Features.StreamerModeHideGuilds()
	if not Toggles.StreamerMode.Value then
		return
	end

	StreamerMode.RandomizeName()
end

function Features.AutoSprint()
	if not Toggles.AutoSprint.Value then
		Maid.AutoSprint = nil
		return
	end

	if not RootPart then
		return
	end

	local moveKeys = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.D }
	local LastPressed = 0

	Maid.AutoSprint = UserInputService.InputBegan:Connect(LPH_NO_VIRTUALIZE(function(input, gpe)
		if gpe or tick() - LastPressed < 0.1 then
			return
		end

		if table.find(moveKeys, input.KeyCode) then
			LastPressed = tick()
			VIM:SendKeyEvent(UserInputService:IsKeyDown(input.KeyCode), input.KeyCode, false, game)
		end
	end))
end

function Features.M1RollCancel()
	if not Toggles.M1RollCancel.Value then
		Maid.M1RollCancel = nil
		return
	end

	Maid.M1RollCancel = UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and EffectReplicator:FindEffect('ClientDodge') then
			EffectReplicator:CreateEffect("Feint"):Debris(.1)
			task.wait(.05)
			LeftClick:FireServer(Utilities:InAir(), Mouse.Hit, {
				["W"] = false,
				["A"] = false,
				["S"] = false,
				["D"] = false,
				["Right"] = false,
				["Left"] = false,
				ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl),
			})
		end
	end)
end

local AttachTarget = nil
function Features.AttachToBack()
	if not Toggles.AttachToBack.Value then
		Maid.AttachToBack = nil
		return
	end

	Maid.AttachToBack = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		if not AttachTarget then
			AttachTarget = Utilities.FindNearestEntity(200)
		end

		if not RootPart or not AttachTarget then
			return
		end

		local TargetPrimary = AttachTarget.HumanoidRootPart
		local lerp_to = TargetPrimary.CFrame * CFrame.new(0, Options.ATBHeight.Value, Options.ATBRange.Value)
		RootPart.CFrame = RootPart.CFrame:Lerp(lerp_to, 0.3)
	end))
end

local OriginalAgility
function Features.AgilitySpoof()
	if not Toggles.AgilitySpoof.Value then
		if OriginalAgility then
			Character.Agility.Value = OriginalAgility
			OriginalAgility = nil
		end

		Maid.AgilitySpoof = nil
		return
	end

	Maid.AgilitySpoof = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		local Agility = Character and Character:FindFirstChild("Agility")

		if not RootPart or not Humanoid or not Agility then
			return
		end

		if not OriginalAgility then
			OriginalAgility = Agility.Value
		end

		Agility.Value = math.max(0, math.ceil(Options.AgilitySpoof.Value / 2))
	end))
end

function Features.PlayerProximity()
	if not Toggles.PlayerProximity.Value then
		Maid.PlayerProximity = nil
		return
	end

	local NotifDB = {}
	Maid.PlayerProximity = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
		if not RootPart or not Humanoid then
			return
		end

		for _, T_Character in pairs(Utilities.EntityList) do
			local v = Players:GetPlayerFromCharacter(T_Character)
			if not v then
				continue
			end

			if not NotifDB[T_Character.Name .. "AC"] then
				NotifDB[T_Character.Name .. "AC"] = T_Character.AncestryChanged:Connect(function()
					if not T_Character or (T_Character.Parent == nil and NotifDB[T_Character]) then
						NotifDB[T_Character]()
						NotifDB[T_Character] = nil
						NotifDB[T_Character.Name .. "AC"]:Disconnect()
					end
				end)
			end

			local T_RootPart = T_Character and T_Character:FindFirstChild("HumanoidRootPart")
			if T_RootPart and v ~= LocalPlayer then
				if
					(RootPart.Position - T_RootPart.Position).Magnitude < Options.PlayerProximity.Value
					and not NotifDB[T_Character]
				then
					if
						v.Backpack:FindFirstChild("Talent:Voidwalker Contract")
						and not NotifDB[T_Character.Name .. "VW"]
					then
						NotifDB[T_Character.Name .. "VW"] = getgenv().Library:Notify("A Voidwalker is nearby.")
						task.delay(5, function()
							NotifDB[T_Character.Name .. "VW"]()
						end)
					end

					NotifDB[T_Character] = getgenv().Library:Notify(v:GetAttribute("CharacterName") .. " is nearby")
					if Toggles.AutoPVPMode.Value then
						Toggles.PVPMode:SetValue(true)
					end
				end

				if
					(RootPart.Position - T_RootPart.Position).Magnitude > (Options.PlayerProximity.Value + 100)
					and NotifDB[T_Character]
				then
					NotifDB[T_Character]()
					getgenv().Library:Notify(v:GetAttribute("CharacterName") .. " is no longer nearby", 2.5)
					NotifDB[T_Character] = nil
					if Toggles.AutoPVPMode.Value then
						Toggles.PVPMode:SetValue(false)
					end
				end
			end
		end
	end))
end

local function GetKnockedOwnershipItem()
	local selected = nil
	for i, v in pairs(LocalPlayer.Backpack:GetChildren()) do
		if not v.Name:match("Talent") and v:IsA("Tool") and v:FindFirstChildOfClass("BasePart") then
			selected = v
		end
	end
	if not selected then
		selected = LocalPlayer.Backpack:FindFirstChild("Weapon") or LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Weapon")
	end
	return selected
end

local ownershipItem = GetKnockedOwnershipItem()
local ownershipActive = false
local ownershipTick = tick()

function Features.KnockedOwnership()
	if not Toggles.KnockedOwnership.Value then
		Maid.KnockedOwnership = nil
		return
	end

	Maid.KnockedOwnership = RunService.Heartbeat:Connect(function(deltaTime)
		if not RootPart or not Humanoid or not Character or (Character and not Character:FindFirstChild("Torso")) then
			return
		end

		if not EffectReplicator:FindEffect("Knocked") or RootPart.ReceiveAge == 0 then
			return
		end

		if not ownershipItem then
			ownershipItem = GetKnockedOwnershipItem()
		end

		if not ownershipItem then
			return
		end
		
		if Toggles.ChimeSafety.Value and IsChime then
			return
		end

		if tick() - ownershipTick > 0.15 and not Toggles.PVPMode.Value then
			if
				ownershipItem.Parent == Character
				and EffectReplicator:FindEffect("Knocked")
				and RootPart.ReceiveAge ~= 0
			then
				Humanoid:UnequipTools()
				ownershipActive = true
			elseif
				ownershipItem.Parent == LocalPlayer.Backpack
				and EffectReplicator:FindEffect("Knocked")
				and RootPart.ReceiveAge ~= 0
			then
				ownershipItem.Parent = Character
				ownershipTick = tick()
				ownershipActive = true
			end

			if not Character.Torso:FindFirstChild("RagdollAttach") and ownershipActive then
				local Weapon = LocalPlayer.Backpack:FindFirstChild("Weapon")
				if Weapon then
					Humanoid:UnequipTools()
					Weapon.Parent = Character
				end
				ownershipActive = false
			end
		end
	end)
end

---------------------------------------------------------------------------------- VOID MOBS ----------------------------------------------------------------------------------
local function CheckConnectedParts()
	local Passed = true
	if not RootPart or not Character:FindFirstChild("Torso") then
		return false
	end

	for i, v in pairs(RootPart:GetConnectedParts()) do
		if v:IsDescendantOf(workspace.Live) and not v:IsDescendantOf(Character) then
			Passed = false
			break
		end
	end

	for i, v in pairs(Character.Torso:GetConnectedParts()) do
		if v:IsDescendantOf(workspace.Live) and not v:IsDescendantOf(Character) then
			Passed = false
			break
		end
	end

	return Passed
end

local oldsettings = {
	ThrottleAdjustTime = settings().Physics.ThrottleAdjustTime,
	AllowSleep = settings().Physics.AllowSleep,
	EagerBulkExecution = settings().Rendering.EagerBulkExecution,
}

function Features.ShowNetworkOwner()
	if not Toggles.ShowNetworkOwner.Value then
		settings().Physics.AreOwnersShown = false
		return
	end

	settings().Physics.AreOwnersShown = true
end

local PhysicsService = cloneref(game:GetService("PhysicsService"))
local NetworkBV = Instance.new("BodyVelocity")
NetworkBV.Velocity = workspace.StreamingEnabled and Vector3.new(0, -8000, 0) or Vector3.new(0, -100, 0)
NetworkBV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
NetworkBV.P = 1/0
NetworkBV.Name = 'NetworkRetainer'

pcall(function()
    PhysicsService:RegisterCollisionGroup("VoidMobs")
    PhysicsService:CollisionGroupSetCollidable("VoidMobs", "Default", false)
    PhysicsService:CollisionGroupSetCollidable("VoidMobs", "VoidMobs", false)
    PhysicsService:CollisionGroupSetCollidable("VoidMobs", "Player", false)
    PhysicsService:CollisionGroupSetCollidable("VoidMobs", "WalkThrough", false)
end)

local BVs = {}

local function retainPart(v)
    if v:IsA('BasePart') and not v:FindFirstChild('NetworkRetainer') then
        local BV = NetworkBV:Clone()
        BV.Parent = v

		table.insert(BVs, BV)
    end
end

--- Replication Part & PeerId
local clientPart = Instance.new('Part', workspace)
local PeerId = gethiddenproperty(clientPart, "NetworkOwnerV3")
clientPart:Destroy()

---Check for network ownership (legacy)
---@param part BasePart
---@return boolean
local function legacyNetworkOwnership(part)
    return not part.Anchored and part.ReceiveAge == 0 and part.Velocity.Magnitude > 0
end

---Check for network ownership
---@param part BasePart
---@return boolean
local function hasNetworkOwnership(part)
    local success, ID = pcall(function()
        return gethiddenproperty(part, "NetworkOwnerV3")
    end)

    if not success then
        return legacyNetworkOwnership(part)
    end
    
    return ID == PeerId
end

function Features.VoidMobs()
	if not Toggles.VoidMobs.Value then
		Maid.VoidMobs = nil
		settings().Physics.AllowSleep = oldsettings.AllowSleep
		for i, v in pairs(BVs) do
			v:Destroy()
			table.remove(BVs, i)
		end
		return
	end
	
	settings().Physics.AllowSleep = false

	Maid.VoidMobs = RunService.Heartbeat:Connect(function(_)
		if not RootPart or not Humanoid then
			return
		end

		sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
		sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
		
		local voidmode = workspace.FallenPartsDestroyHeight + 100
		local velchange = Vector3.new(0, -12000, 0)

		for _, v in pairs(workspace.Live:GetChildren()) do
			if
				v ~= LocalPlayer.Character
				and v:FindFirstChild("HumanoidRootPart")
				and not v:FindFirstChild("InteractPrompt")
				and (not Players:GetPlayerFromCharacter(v) or Toggles.VoidOnPlayerPickUp.Value)
				and CheckConnectedParts()
			then
				local Character = v
				local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
				local IsEthiron = Character.Name:match(".avatar")

				if IsEthiron then
					voidmode = workspace.FallenPartsDestroyHeight - 500
					velchange = Vector3.new(12,12,12)
				end
				
				for _, v in pairs(Character:GetChildren()) do
					retainPart(v)

					if HumanoidRootPart and hasNetworkOwnership(HumanoidRootPart) then
						local cf = HumanoidRootPart.CFrame
						HumanoidRootPart.Velocity = velchange
						HumanoidRootPart.CFrame = CFrame.new(cf.X, voidmode, cf.Z)
						sethiddenproperty(HumanoidRootPart, "NetworkIsSleeping", false)
					end

					if v:IsA('BasePart') then
						if v:FindFirstChild('ControlVel') then
							v:FindFirstChild('ControlVel'):Destroy()
						end
						
						if v:FindFirstChild('SafetyBV') then
							v:FindFirstChild('SafetyBV'):Destroy()
						end
						
						if v:FindFirstChild('Holder') and v:FindFirstChild('Holder'):IsA('BodyMover') then
							v:FindFirstChild('Holder'):Destroy()
						end
						
						if not IsEthiron then
							v.CanCollide = false
							v.CollisionGroup = 'VoidMobs'
						end

						if hasNetworkOwnership(v) then
							if IsEthiron then
								local NetworkRetainer = v:FindFirstChild('NetworkRetainer')
								NetworkRetainer.Velocity = Vector3.new(0, -500, 0)
							end

							local cf = v.CFrame
							v.Velocity = velchange
							v.CFrame = CFrame.new(cf.X, voidmode, cf.Z)

							sethiddenproperty(v, "NetworkIsSleeping", false)
						end
					end
				end
			end
		end
	end)
end
---------------------------------------------------------------------------------- VOID MOBS END ----------------------------------------------------------------------------------	

local KB_Archive = {}
local SW_Archive = {}
function Features.NoKillBricks()
	if not Toggles.NoKillBricks.Value then
		Maid.KillBricks = nil

		for i, v in pairs(SW_Archive) do
			table.remove(SW_Archive, i)
			v.Parent = workspace.Layer2Floor1
		end

		for i, v in pairs(KB_Archive) do
			table.remove(KB_Archive, i)
			v.Parent = workspace
		end

		return
	end

	Maid.KillBricks = workspace.ChildAdded:Connect(function(v)
		if v.Name == "KillBrick" or v.Name == "KillPlane" then
			table.insert(KB_Archive, v)
			v.Parent = nil
		end
		if v.Name:match("Chasm") and v:FindFirstChildOfClass('TouchTransmitter') then
			table.insert(KB_Archive, v)
			v.Parent = nil
		end
	end)

	for _, v in pairs(workspace:GetChildren()) do
		if v.Name == "KillBrick" or v.Name == "KillPlane" then
			table.insert(KB_Archive, v)
			v.Parent = nil
		end
	end
	
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:match("Chasm") and v:FindFirstChildOfClass('TouchTransmitter') then
			table.insert(KB_Archive, v)
			v.Parent = nil
		end
	end

	if workspace:FindFirstChild("Layer2Floor1") then
		for _, v in pairs(workspace.Layer2Floor1:GetChildren()) do
			if v.Name == "SuperWall" then
				table.insert(SW_Archive, v)
				v.Parent = nil
			end
		end
	end
end

function Features.TpToGround()
	if not Toggles.TpToGround.Value then
		return
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { workspace.Live, workspace.NPCs }
	params.FilterType = Enum.RaycastFilterType.Blacklist

	if not RootPart or not RootPart.Parent then
		return
	end

	local floor = workspace:Raycast(RootPart.Position, Vector3.new(0, -1000, 0), params)
	if not floor or not floor.Instance then
		return
	end

	local isKillBrick = false

	for _, v in pairs(KB_Archive) do
		if floor.Instance == v.part then
			isKillBrick = true
			break
		end
	end

	if isKillBrick then
		return
	end

	local pos = (RootPart.Position.Y - floor.Position.Y)
	RootPart.CFrame = RootPart.CFrame * CFrame.new(0, -pos + 3, 0)
	RootPart.Velocity = RootPart.Velocity * Vector3.new(1, 0, 1)
end

local Modif_Archive = {}
function Features.NoEchoMod()
	if not Toggles.NoEchoMod.Value then
		for i, v in pairs(Modif_Archive) do
			table.remove(Modif_Archive, i)
			v.Parent = LocalPlayer.Backpack
		end
		return
	end

	repeat
		task.wait(0.5)
	until game:GetService("CollectionService"):HasTag(LocalPlayer.Backpack, "Loaded")

	for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
		if v.Name:match("EchoMod:") then
			table.insert(Modif_Archive, v)
			v.Parent = nil
		end
	end
end

function Features.SanityCounter()
	if not CurrentSanityFrame then
		return
	end

	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local PlayerStatsGui = PlayerGui:WaitForChild("StatsGui")
	local PlayerSurvivalStats = PlayerStatsGui:WaitForChild("SurvivalStats")
	local Stomach = PlayerSurvivalStats:FindFirstChild("Stomach")
	local StomachVisible = Stomach and Stomach.Visible or true
	CurrentSanityFrame.Visible = Toggles.SanityCounter.Value and StomachVisible
	if CurrentChainFrame then
		CurrentChainFrame.Position = (not CurrentSanityFrame.Visible) and CurrentSanityFrame.Position
			or CurrentSanityFrame.Position + UDim2.new(UDim.new(0, 24), UDim.new(0, 0))
	end
end

function Features.PerfectStack()
	if not CurrentChainFrame then
		return
	end

	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local PlayerStatsGui = PlayerGui:WaitForChild("StatsGui")
	local PlayerSurvivalStats = PlayerStatsGui:WaitForChild("SurvivalStats")
	local Stomach = PlayerSurvivalStats:FindFirstChild("Stomach")
	local StomachVisible = Stomach and Stomach.Visible or true
	CurrentChainFrame.Visible = Toggles.PerfectStack.Value and StomachVisible
	if CurrentSanityFrame then
		CurrentChainFrame.Position = (not CurrentSanityFrame.Visible) and CurrentSanityFrame.Position
			or CurrentSanityFrame.Position + UDim2.new(UDim.new(0, 24), UDim.new(0, 0))
	end
end

getgenv().vec3scale = Vector3.new(0, 9e9, 0)
local replicarootpart = nil
function Features.AIBreaker()
	if not Toggles.AIBreaker.Value then
		if not Maid.AIBreaker then
			return
		end

		local fakerootpart = RootPart
		local realrootpart = replicarootpart
		Maid.AIBreaker = nil

		RootPart = realrootpart

		fakerootpart.RootJoint.Part0 = nil
		fakerootpart:Destroy()
		replicarootpart = nil

		realrootpart.RootJoint.Part0 = realrootpart
		realrootpart.Parent = Character
		return
	end

	Maid.AIBreaker = RunService.Heartbeat:Connect(function(deltaTime)
		if not Humanoid or not RootPart then
			return
		end

		if Toggles.AIBreaker2.Value then
			getgenv().vec3scale = Vector3.new(0, -1e5, 0)
		else
			getgenv().vec3scale = Vector3.new(0, 9e9, 0)
		end

		if replicarootpart == nil then
			local fakerootpart = RootPart:Clone()
			local realrootpart = RootPart

			RootPart = fakerootpart
			replicarootpart = realrootpart

			realrootpart.RootJoint.Part0 = nil
			realrootpart.Parent = Humanoid

			fakerootpart.RootJoint.Part0 = RootPart
			fakerootpart.Parent = Character
		end

		local realrootpart = replicarootpart
		local fakerootpart = RootPart

		if realrootpart:FindFirstChildOfClass("BodyVelocity") then
			realrootpart:FindFirstChildOfClass("BodyVelocity").Parent = fakerootpart
		end

		if realrootpart:FindFirstChildOfClass("BodyPosition") then
			realrootpart:FindFirstChildOfClass("BodyPosition").Parent = fakerootpart
		end

		if realrootpart:FindFirstChildOfClass("Weld") then
			realrootpart:FindFirstChildOfClass("Weld").Parent = fakerootpart
			if realrootpart:FindFirstChildOfClass("Weld").Part0 == realrootpart then
				realrootpart:FindFirstChildOfClass("Weld").Part0 = fakerootpart
			end
			if realrootpart:FindFirstChildOfClass("Weld").Part1 == realrootpart then
				realrootpart:FindFirstChildOfClass("Weld").Part1 = fakerootpart
			end
		end

		realrootpart.CFrame = fakerootpart.CFrame

		local v = realrootpart
		local oldVel = v.Velocity
		v.Velocity = v.Velocity * vec3scale
		task.wait()
		v.Velocity = oldVel
	end)
end


local function BasicRetain(v)
	if v:IsA('BasePart') and not v:FindFirstChild('NetworkRetainer') then
        local BV = NetworkBV:Clone()
		BV.Velocity = Vector3.new(0, 0, 0)
        BV.Parent = v

		table.insert(BVs, BV)
    end
end

function Features.TPMob()
	if not Toggles.TPMob.Value then
		Maid.TPMob = nil
		return
	end

	Maid.TPMob = RunService.Heartbeat:Connect(function(deltaTime)
		if not RootPart or not Humanoid then
			return
		end

		sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
		sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)

		for _, v in pairs(workspace.Live:GetChildren()) do
			if
				v ~= LocalPlayer.Character
				and v:FindFirstChild("HumanoidRootPart")
				and (not Players:GetPlayerFromCharacter(v) or Toggles.VoidOnPlayerPickUp.Value)
				and CheckConnectedParts()
			then
				local Character = v
				local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
				for _, v in pairs(Character:GetChildren()) do
					retainPart(v)

					if HumanoidRootPart and hasNetworkOwnership(HumanoidRootPart) then
						HumanoidRootPart.Velocity = Vector3.new(14,14,14)
						HumanoidRootPart.CFrame = RootPart.CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)
						sethiddenproperty(HumanoidRootPart, "NetworkIsSleeping", false)
					end

					if v:IsA('BasePart') then
						if v:FindFirstChild('ControlVel') then
							v:FindFirstChild('ControlVel'):Destroy()
						end
						
						if v:FindFirstChild('SafetyBV') then
							v:FindFirstChild('SafetyBV'):Destroy()
						end
						
						if v:FindFirstChild('SwimBV') then
							v:FindFirstChild('SwimBV'):Destroy()
						end
						
						if v:FindFirstChild('Holder') and v:FindFirstChild('Holder'):IsA('BodyMover') then
							v:FindFirstChild('Holder'):Destroy()
						end

						if hasNetworkOwnership(v) then
							v.Velocity = Vector3.new(14,14,14)
							v.CFrame = RootPart.CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)

							sethiddenproperty(v, "NetworkIsSleeping", false)
						end
					end
				end
			end
		end
	end)
end

function Features.TPMobCamera()
	if not Toggles.TPMobCamera.Value then
		Maid.TPMobCamera = nil
		return
	end

	Maid.TPMobCamera = RunService.Heartbeat:Connect(function(deltaTime)
		if not RootPart or not Humanoid then
			return
		end

		local Camera = workspace.CurrentCamera

		sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
		sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)

		if Toggles.FreecamOnly.Value and not LocalPlayer:HasTag('FreecamEnabled') then
			return
		end

		for _, v in pairs(workspace.Live:GetChildren()) do
			if
				v ~= LocalPlayer.Character
				and v:FindFirstChild("HumanoidRootPart")
				and (not Players:GetPlayerFromCharacter(v) or Toggles.VoidOnPlayerPickUp.Value)
				and CheckConnectedParts()
			then
				local Character = v
				local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
				for _, v in pairs(Character:GetChildren()) do
					retainPart(v)

					if HumanoidRootPart and hasNetworkOwnership(HumanoidRootPart) then
						HumanoidRootPart.Velocity = Vector3.new(14,14,14)
						HumanoidRootPart.CFrame = Camera.CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)
						sethiddenproperty(HumanoidRootPart, "NetworkIsSleeping", false)
					end

					if v:IsA('BasePart') then
						if v:FindFirstChild('ControlVel') then
							v:FindFirstChild('ControlVel'):Destroy()
						end
						
						if v:FindFirstChild('SafetyBV') then
							v:FindFirstChild('SafetyBV'):Destroy()
						end
						
						if v:FindFirstChild('SwimBV') then
							v:FindFirstChild('SwimBV'):Destroy()
						end
						
						if v:FindFirstChild('Holder') and v:FindFirstChild('Holder'):IsA('BodyMover') then
							v:FindFirstChild('Holder'):Destroy()
						end

						if hasNetworkOwnership(v) then
							v.Velocity = Vector3.new(14,14,14)
							v.CFrame = Camera.CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)

							sethiddenproperty(v, "NetworkIsSleeping", false)
						end
					end
				end
			end
		end
	end)
end

function Features.TalentPickerBuilderUrl()
	local BuilderId = string.match(Options.TalentPickerBuilderUrl.Value, "https://deepwoken.co/builder%?id=(.+)")
	if not BuilderId then
		return
	end

	local ApiUrl = ("https://api.deepwoken.co/build?id=%s"):format(BuilderId)
	local Response = request({ Url = ApiUrl, Method = "GET", Headers = { ["Content-Type"] = "application/json" } })

	if not Response or not Response.Success or not Response.Body then
		return Library:Notify("Invalid Builder Url", 2.0)
	end

	TalentPickerData = game:GetService("HttpService"):JSONDecode(Response.Body)
end

function Features.TPMobToTarget()
	if not Toggles.TPMobToTarget.Value then
		Maid.TPMobToTarget = nil
		return
	end

	Maid.TPMobToTarget = RunService.Heartbeat:Connect(function(deltaTime)
		if not RootPart or not Humanoid then
			return
		end

		sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
		sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)

		local LocalPlayer_Name = Options.TPMobToTarget.Value ~= "" and Options.TPMobToTarget.Value or LocalPlayer.Name
		local Target = Players:FindFirstChild(LocalPlayer_Name)

		if not Target.Character then
			return
		end

		if not Target.Character:FindFirstChild("HumanoidRootPart") then
			task.spawn(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, Target.Character:GetPivot().Position, 1)
			return
		end

		for _, v in pairs(workspace.Live:GetChildren()) do
			if
				v ~= LocalPlayer.Character
				and v:FindFirstChild("HumanoidRootPart")
				and (not Players:GetPlayerFromCharacter(v) or Toggles.VoidOnPlayerPickUp.Value)
				and CheckConnectedParts()
			then
				local Character = v
				local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
				for _, v in pairs(Character:GetChildren()) do
					retainPart(v)

					if HumanoidRootPart and hasNetworkOwnership(HumanoidRootPart) then
						HumanoidRootPart.Velocity = Vector3.new(14,14,14)
						HumanoidRootPart.CFrame = Target.Character:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)
						sethiddenproperty(HumanoidRootPart, "NetworkIsSleeping", false)
					end

					if v:IsA('BasePart') then
						if v:FindFirstChild('ControlVel') then
							v:FindFirstChild('ControlVel'):Destroy()
						end
						
						if v:FindFirstChild('SafetyBV') then
							v:FindFirstChild('SafetyBV'):Destroy()
						end
						
						if v:FindFirstChild('SwimBV') then
							v:FindFirstChild('SwimBV'):Destroy()
						end
						
						if v:FindFirstChild('Holder') and v:FindFirstChild('Holder'):IsA('BodyMover') then
							v:FindFirstChild('Holder'):Destroy()
						end

						if hasNetworkOwnership(v) then
							v.Velocity = Vector3.new(14,14,14)
							v.CFrame = Target.Character:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0, Options.TPMobHeight.Value, Options.TPMobRange.Value)

							sethiddenproperty(v, "NetworkIsSleeping", false)
						end
					end
				end
			end
		end
	end)
end

local MemStoreService = game:GetService("MemStorageService")
function Features.AutoMaestro()
	if not Toggles.AutoMaestro.Value then
		if not Maid.AutoMaestro then
			return
		end
		Maid.AutoMaestro = nil
		return
	end

	repeat
		task.wait()
	until Character and RootPart and LeftClick

	Library:Toggle()

	if MemStoreService:HasItem("AutoMaestroFight") then
		MemStoreService:RemoveItem("AutoMaestroFight")

		local Maestro

		repeat
			Maestro = workspace.Live:FindFirstChild(".evengarde1")
			task.wait(1.5)
		until Maestro

		local InteractPrompt = Maestro:WaitForChild("InteractPrompt", 7)
		local DialogueFrame = LocalPlayer.PlayerGui:WaitForChild("DialogueGui"):WaitForChild("DialogueFrame")

		if InteractPrompt or not EffectReplicator:FindEffect("Danger") then
			TweenService:Create(RootPart, TweenInfo.new(0.6), {
				CFrame = Maestro.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0),
			}):Play()

			task.wait(1)

			repeat
				fireproximityprompt(InteractPrompt)
				task.wait(1)
			until DialogueFrame.Visible

			VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
			task.wait()
			VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)
		end

		if not Toggles.AIBreaker.Value then
			Toggles.AIBreaker.Value = true
			task.wait()
			Features.AIBreaker()
		end

		if not Toggles.VoidMobs.Value and Toggles.VoidMaestro.Value then
			Toggles.VoidMobs.Value = true
			task.wait()
			Features.VoidMobs()
		end

		Toggles.AIBreaker2:SetValue(true)

		local Weapon = Character and Character:FindFirstChild("Weapon") or LocalPlayer.Backpack:FindFirstChild("Weapon")
		Humanoid:EquipTool(Weapon)

		task.spawn(function()
			repeat
				task.wait(0.3)
			until not DialogueFrame.Visible

			if Toggles.MaestroUseCritical.Value then
				VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
				task.wait(0.1)
				VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game)
				task.wait(0.3)
			end
		end)

		Maid.AutoMaestro = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
			if not workspace.Live:FindFirstChild(".evengarde1") then
				Maid.AutoMaestro = nil
			end

			local MaestroHRP = Maestro:FindFirstChild("HumanoidRootPart")

			if not MaestroHRP then
				return
			end

			local Properties = {
				["W"] = false,
				["A"] = false,
				["S"] = false,
				["D"] = false,
				["Right"] = false,
				["Left"] = false,
				ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl),
			}

			if (MaestroHRP.Position - RootPart.Position).Magnitude < 16 then
				if Toggles.MaestroUseCritical.Value then
					VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
					task.wait(0.1)
					VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game)
					task.wait(0.3)
				end
				LeftClick:FireServer(Utilities:InAir(), Mouse.Hit, Properties)
			end

			local cf = MaestroHRP.CFrame * CFrame.new(0, 0, -3)
			Humanoid:MoveTo(cf.p)
		end))

		local Looted = {}
		ReplicatedStorage.Requests.ToolSplash.OnClientEvent:Connect(function(Tool, Amount)
			local Quantity = Tool:FindFirstChild("Quantity")
			local Name = Tool.Name:match("$") and Tool.Name:split("$")[1] or Tool.Name
			Amount = Amount or Quantity and Quantity.Value or 1
			if not Looted[Name] then
				Looted[Name] = Amount
			else
				Looted[Name] = Looted[Tool] + 1
			end
		end)

		repeat
			task.wait(0.1)
		until not workspace.Live:FindFirstChild(".evengarde1")

		local Chest = workspace.Thrown:WaitForChild("Model")
		Chest:WaitForChild("RootPart")

		VIM:SendKeyEvent(true, Enum.KeyCode.W, false, game)
		task.wait(0.1)
		VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)

		repeat
			local cf = Chest.RootPart.CFrame * CFrame.new(0, 3.5, 0)
			Humanoid:MoveTo(cf.p)
			Character:PivotTo(cf)
			task.wait(1)
			fireproximityprompt(Chest:WaitForChild("InteractPrompt"))
		until LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt")

		repeat
			task.wait(0.1)
		until not LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt")

		repeat
			task.wait(0.1)
		until workspace:FindFirstChild("DungeonExit")
		local DungeonExit = workspace:FindFirstChild("DungeonExit")

		local BaseTemplate = "Maestro Farm Loot, Date: " .. os.date("%x %X") .. "\n"
		local ConstructWord = BaseTemplate
		for i,v in pairs(Looted) do
			ConstructWord = ConstructWord .. i .. (" x%i"):format(v) .. "\n"
		end

		if ConstructWord == BaseTemplate then
			ConstructWord = BaseTemplate .. "Nothing"
		end

		if Options.AutoMaestroWebhook.Value ~= "" then
			request({
				Url = Options.AutoMaestroWebhook.Value,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = game.HttpService:JSONEncode({
					content = "```" .. ConstructWord .. "```",
				}),
			})
		end

		repeat
			Character:PivotTo(DungeonExit.CFrame)
			task.wait(1)
		until not Character or Character.Parent ~= workspace.Live

		MemStoreService:SetItem("AutoMaestroStart", "true")
		return
	end

	local Maestro

	repeat
		Maestro = workspace.NPCs:FindFirstChild("Maestro Evengarde Rest")
		task.wait(1)
	until Maestro and Maestro:FindFirstChild("HumanoidRootPart")

	local InteractPrompt = Maestro:FindFirstChild("InteractPrompt")
	local DialogueFrame = LocalPlayer.PlayerGui:WaitForChild("DialogueGui"):WaitForChild("DialogueFrame")

	repeat
		task.wait(1)
		Humanoid:MoveTo(Maestro.HumanoidRootPart.Position)
	until (RootPart.Position - Maestro.HumanoidRootPart.Position).Magnitude < 20

	repeat
		fireproximityprompt(InteractPrompt)
		task.wait(1)
	until DialogueFrame.Visible

	MemStoreService:SetItem("AutoMaestroFight", "true")

	VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
	task.wait()
	VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)

	MemStoreService:SetItem("AutoMaestroStart", "true")
end

function Features.AutoCharisma()
	if not Toggles.AutoCharisma.Value then
		Maid.AutoCharisma = nil
		return
	end

	local Book_Name = "How to Make Friends"
	local Book = LocalPlayer.Backpack:FindFirstChild(Book_Name) or Character and Character:FindFirstChild(Book_Name)
	if Book then
		Humanoid:EquipTool(Book)
		task.wait(0.5)
		VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
		task.wait()
		VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
	end

	local function getStatMax()
		local MaxStat = Options.CharismaCap.Value ~= "" and tonumber(Options.CharismaCap.Value) or 100

		if MaxStat == 0 then
			MaxStat = 100
		end

		local CurrentStat = tonumber(Character:GetAttribute("Stat_Charisma"))
		if CurrentStat >= MaxStat then
			return
		end

		return true
	end

	Maid.AutoCharisma = LocalPlayer.PlayerGui.ChildAdded:Connect(function(v)
		local ChoiceFrame = v:FindFirstChild("ChoiceFrame")
		if v.Name ~= "ChoicePrompt" or not ChoiceFrame then
			print("nun charisma")
			return
		end

		local DescSheet = ChoiceFrame and ChoiceFrame:FindFirstChild("DescSheet") or nil
		local GuiOptions = ChoiceFrame and ChoiceFrame:FindFirstChild("Options") or nil
		local ChoiceEvent = v:FindFirstChild("ChatChoice")
		print("charisma", DescSheet, GuiOptions)
		if not DescSheet and not GuiOptions then
			if not getStatMax() then
				Humanoid:UnequipTools()
				Maid.AutoCharisma = nil
				Toggles.AutoCharisma:SetValue(false)
				Library:Notify("[Charisma AutoFarm]: Reached Target")
				print("blocked stat")
				return
			end

			local Desc = ChoiceFrame:FindFirstChild("Desc")
			local Text = string.split(Desc.Text, "\n")
			local RealText = string.sub(Text[2], 2, -2)
			task.wait(0.5)
			print("charisma", RealText)
			ChoiceEvent:InvokeServer(RealText)
			task.wait(0.5)

			if not getStatMax() then
				Humanoid:UnequipTools()
				Maid.AutoCharisma = nil
				Toggles.AutoCharisma:SetValue(false)
				Library:Notify("[Charisma AutoFarm]: Reached Target")
				return
			end

			VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
			task.wait()
			VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
		end
	end)
end

function Features.AutoMath()
	if not Toggles.AutoMath.Value then
		Maid.AutoMath = nil
		return
	end

	local Book_Name = "Math Textbook"
	local Book = LocalPlayer.Backpack:FindFirstChild(Book_Name) or Character and Character:FindFirstChild(Book_Name)
	if Book then
		Humanoid:EquipTool(Book)
		task.wait(0.5)
		VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
		task.wait()
		VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
	end

	local function getStatMax()
		local MaxStat = Options.IntelCap.Value ~= "" and tonumber(Options.IntelCap.Value) or 100

		if MaxStat == 0 then
			MaxStat = 100
		end

		local CurrentStat = tonumber(Character:GetAttribute("Stat_Intelligence"))
		if CurrentStat >= MaxStat then
			return
		end

		return true
	end

	Maid.AutoMath = LocalPlayer.PlayerGui.ChildAdded:Connect(function(v)
		local ChoiceFrame = v:FindFirstChild("ChoiceFrame")
		if v.Name ~= "ChoicePrompt" or not ChoiceFrame then
			print("choice prompt math block fr")
			return
		end

		if not getStatMax() then
			Humanoid:UnequipTools()
			Maid.AutoMath = nil
			Toggles.AutoMath:SetValue(false)
			print("math block fr")
			Library:Notify("[Intelligence AutoFarm]: Reached Target")
			return
		end

		local DescSheet = ChoiceFrame and ChoiceFrame:FindFirstChild("DescSheet") or nil
		local Options = ChoiceFrame and ChoiceFrame:FindFirstChild("Options") or nil
		local ChoiceEvent = v:FindFirstChild("Choice")
		local Desc = DescSheet:FindFirstChild("Desc")
		local Operation
	
		if Desc.Text:lower():match("plus") then
			Operation = "plus"
		elseif Desc.Text:lower():match("divided") then
			Operation = "div"
		elseif Desc.Text:lower():match("minus") then
			Operation = "min"
		elseif Desc.Text:lower():match("times") then
			Operation = "mult"
		end

		local Text = string.split(Desc.Text, " ")
		local Num1, Num2 = Text[3], string.gsub(Text[5], "?", "")

		local Solved
		if Operation == "mult" then
			Solved = tonumber(Num1) * tonumber(Num2)
		elseif Operation == "min" then
			Solved = tonumber(Num1) - tonumber(Num2)
		elseif Operation == "plus" then
			Solved = tonumber(Num1) + tonumber(Num2)
		elseif Operation == "div" then
			Num1, Num2 = Text[3], string.gsub(Text[6], "?", "")
			Solved = tonumber(Num1) / tonumber(Num2)
		end

		local Table = {}
		local Buttons = {}

		task.wait(0.05)
	
		for _, Child in pairs(Options:GetChildren()) do
			print(Child, Child.Name)
			if Child:IsA("TextButton") then
				if not tonumber(Child.Text) then
					print("Skipping", Child.Text, "Not a number cuh")
					continue
				end
				local dif = math.abs((tonumber(Child.Text) - Solved))
				warn("Added to table", Child.Text, dif)
				table.insert(Table, dif)
				Buttons[dif] = Child.Name
			end
		end

		table.sort(Table, function(a, b)
			return a < b
		end)
		local Num = Table[1]
		if not Num then
			return warn("No num lol")
		end
		print("automath", Num, Operation)
		task.wait(0.5)
		ChoiceEvent:FireServer(Buttons[Num])
		task.wait(0.5)

		if not getStatMax() then
			Humanoid:UnequipTools()
			Maid.AutoMath = nil
			Toggles.AutoMath:SetValue(false)
			print("math block fr 1")
			Library:Notify("[Intelligence AutoFarm]: Reached Target")
			return
		end

		VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
		task.wait()
		VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
	end)
end

local function FindNearestMob()
	local Mob = nil
	local Distance = 1000
	for _, v in pairs(workspace.Live:GetChildren()) do
		if not v:FindFirstChild("HumanoidRootPart") then
			continue
		end
		if not v:FindFirstChild("Humanoid") then
			continue
		end
		if v:GetAttribute("MOB_species") == 'Human' then
			continue
		end
		if v ~= Character and (v.HumanoidRootPart.Position - RootPart.Position).Magnitude < Distance then
			Distance = (v.HumanoidRootPart.Position - RootPart.Position).Magnitude
			Mob = v
		end
	end

	return Mob
end

local function GetFood()
	local Food = nil
	for i, v in pairs(LocalPlayer.Backpack:GetChildren()) do
		if v:FindFirstChild("Food") and v.Name ~= "Canteen" then
			Food = v
			break
		end
	end
	return Food
end

local function InVoidsea()
	local m_RealmInfo = getgenv().require(ReplicatedStorage.Info.RealmInfo)
	local t_CurrentWorld = m_RealmInfo.CurrentWorld
	local Position = RootPart.Position
	local Area = ReplicatedStorage.MarkerWorkspace:FindPartOnRayWithWhitelist(
		Ray.new(Position, Vector3.new(0, 5000, 0)),
		{ ReplicatedStorage.MarkerWorkspace.AreaMarkers }
	)
	Area = Area and Area.Parent.Name or nil
	local MapCentre = ReplicatedStorage:FindFirstChild("MAP_CENTRE") and ReplicatedStorage.MAP_CENTRE.Value
		or Vector3.new()
	local MAP_BOUNDS = ReplicatedStorage:FindFirstChild("MAP_BOUNDS") and ReplicatedStorage.MAP_BOUNDS.Value
		or Vector3.new(20000, 0, 20000)
	local v67 = Position - MapCentre
	local v68 = Position.y < -100 and t_CurrentWorld == "Depths" or false
	local v69
	if not EffectReplicator:FindEffect("InGuildBase") then
		v69 = not v68
			and (
				(math.abs(v67.x) > MAP_BOUNDS.x or math.abs(v67.z) > MAP_BOUNDS.z)
					and (not Area or Area ~= "The Floating Keep")
				or false
			)
	else
		v69 = false
	end
	return v69
end

local AstralNotified = false
function Features.AutoAstral()
	if not Toggles.AutoAstral.Value then
		if not Maid.AutoAstral then
			return
		end
		Maid.AutoAstral = nil
		Maid.AstralBV = nil
		return
	end

	if not InVoidsea() then
		Library:Notify("You must be in the voidsea before activating this feature.", 5)
		return
	end

	Maid.AstralBV = Utilities.NewBodyMover("BodyVelocity")
	Maid.AstralBV.MaxForce = Vector3.new(9e9, 0, 9e9)
	Maid.AutoAstral = RunService.Heartbeat:Connect(function(deltaTime)
		if not RootPart or not Humanoid or not Character then
			return
		end

		if not Character:FindFirstChild("Stomach") or not Character:FindFirstChild("Water") then
			return
		end

		if MODDETECTED then
			getgenv().MODDETECTED = nil
			ServerHopFunction()
			return
		end

		if not InVoidsea() then
			Library:Notify("Player is outside of voidsea, cancelling autofarm.", 5)
			Toggles.AutoAstral.Value = false
			Maid.AutoAstral = nil
			Maid.AstralBV = nil
			return
		end

		local Carnivore = Toggles.AstralCarnivore.Value
		local Stomach = Character:FindFirstChild("Stomach")
		local Water = Character:FindFirstChild("Water")

		local FoodPercentage = Stomach.Value / Stomach.MaxValue
		local WaterPercentage = Water.Value / Water.MaxValue

		if
			FoodPercentage <= (Options.AstralHungerLevel.Value / 100)
			and WaterPercentage <= (Options.AstralWaterLevel.Value / 100)
		then
			local Mob = FindNearestMob()
			local Tool = Character:FindFirstChildOfClass("Tool")
			local Food = Tool and Tool:FindFirstChild("Food") and Tool or GetFood()
			if Carnivore and Mob then
				if not Character:FindFirstChild("Weapon") then
					Humanoid:EquipTool(LocalPlayer.Backpack.Weapon)
				end

				if (Mob.HumanoidRootPart.Position - RootPart.Position).Magnitude < 20 then
					Maid.AstralBV.Parent = nil
					if not EffectReplicator:FindEffect("LightAttack", true) then
						LeftClick:FireServer(Utilities:InAir(), Mouse.Hit, {
							["W"] = false,
							["A"] = false,
							["S"] = false,
							["D"] = false,
							["Right"] = false,
							["Left"] = false,
							ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl),
						})
					end

					if not EffectReplicator:FindEffect("CriticalCool") then
						VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
						task.wait(0.1)
						VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game)
					end
				else
					local LookCF = CFrame.new(RootPart.Position, Mob.HumanoidRootPart.Position)
					Maid.AstralBV.Velocity = LookCF.LookVector * 60
					Maid.AstralBV.Parent = RootPart
				end

				return
			elseif (not Carnivore or (Carnivore and not Mob)) and Food then
				if not Character:FindFirstChild(Food.Name) then
					Humanoid:EquipTool(Food)
				end

				task.wait(0.3)

				if
					FoodPercentage <= (Options.AstralHungerLevel.Value / 100)
					and WaterPercentage <= (Options.AstralWaterLevel.Value / 100)
				then
					return
				end

				VIM:SendMouseButtonEvent(0, 50, 0, true, game, 0)
				task.wait()
				VIM:SendMouseButtonEvent(0, 50, 0, false, game, 0)
			end
		end

		local BellMeteor = nil
		for _, v in pairs(workspace.Thrown:GetChildren()) do
			if v.Name == "BellMeteor" and (v:GetPivot().p - RootPart.Position).Magnitude < 1200 then
				BellMeteor = v
				break
			else
				continue
			end
		end

		if not BellMeteor or (BellMeteor and (BellMeteor:GetPivot().p - RootPart.Position).Magnitude > 1200) then
			AstralNotified = false
			Maid.AstralBV.Velocity = RootPart.CFrame.LookVector * (60 + Options.AstralSpeed.Value)
			Maid.AstralBV.Parent = RootPart
			return
		end

		if BellMeteor then
			Library:Notify("ASTRAL IS IN THE SERVER", 2)
		end

		if
			(BellMeteor:GetPivot().p - RootPart.Position).Magnitude < 1200
			and not AstralNotified
			and Toggles.NotifyAstral.Value
		then
			AstralNotified = true
			request({
				Url = Options.AstralWebhook.Value,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = game:GetService("HttpService"):JSONEncode({
					content = "@everyone ASTRAL BELL METEOR SPAWNED.",
				}),
			})
		end

		if (BellMeteor:GetPivot().p - RootPart.Position).Magnitude < 350 then
			Maid.AstralBV.Parent = nil
			return
		end

		local LookCF = CFrame.new(RootPart.Position, BellMeteor:GetPivot().p)
		Maid.AstralBV.Velocity = LookCF.LookVector * 60
		Maid.AstralBV.Parent = RootPart
	end)
end

local Chests = {}
local CollectionService = game:GetService("CollectionService")

local function onChestAdded(v)
	if not CollectionService:HasTag(v, "Chest") then
		return
	end
	if table.find(Chests, v) then
		return
	end

	table.insert(Chests, v)

	v.AncestryChanged:Connect(function()
		if v.Parent == workspace.Thrown then
			return
		end

		table.remove(Chests, table.find(Chests, v))
	end)
end

function Features.AnimationBlocker()
	if not Toggles.AnimationBlocker.Value then
		Maid.AnimationBlocker = nil
		return
	end

	Maid.AnimationBlocker = Humanoid:WaitForChild("Animator").AnimationPlayed:Connect(function(animationTrack)
		animationTrack:Stop()
	end)
end

function Features.AutoOpenChest()
	if not Toggles.AutoOpenChest.Value then
		Maid.AutoOpenChest = nil
		Maid.AutoOpenChestChild = nil
		return
	end

	for _, v in pairs(workspace.Thrown:GetChildren()) do
		onChestAdded(v)
	end

	Maid.AutoOpenChestChild = workspace.Thrown.ChildAdded:Connect(onChestAdded)
	Maid.AutoOpenChest = task.spawn(function()
		while task.wait() do
			local Distance, Prompt = 12

			for _, v in pairs(Chests) do
				if not v:FindFirstChild("Lid") then
					continue
				end
				if not v:FindFirstChild("InteractPrompt") then
					continue
				end
				if not CollectionService:HasTag(v, "ClosedChest") then
					continue
				end
				if (v.Lid.Position - RootPart.Position).Magnitude >= Distance then
					continue
				end
				Distance = (v.Lid.Position - RootPart.Position).Magnitude
				Prompt = v.InteractPrompt
			end

			if not Prompt then
				continue
			end
			if LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt") then
				continue
			end

			repeat
				fireproximityprompt(Prompt)
				task.wait(0.3)
			until LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt")
				or not Prompt
				or (Prompt.Parent:GetPivot().p - RootPart.Position).Magnitude > 14

			if LocalPlayer.PlayerGui:FindFirstChild("ChoicePrompt") then
				warn("Opened Chest")
			end
		end
	end)
end

local HitboxModule = require("Modules/Deepwoken/Hitbox")
function Features.VisualizeHitbox()
	if not Toggles.VisualizeHitbox.Value then
		Maid.VisualizeHitbox = nil
		Maid.HitboxPart = nil
		return
	end

	Maid.HitboxPart = HitboxModule.new(RootPart, Enum.PartType[Options.HitboxShape.Value])

	Maid.VisualizeHitbox = RunService.Heartbeat:Connect(function()
		if not Maid.HitboxPart then
			return
		end

		local Offset_Y = tonumber(Options.Hitbox_YSet.Value)
		local Offset_Z = tonumber(Options.Hitbox_ZSet.Value)

		Maid.HitboxPart.Transparency = Toggles.UsePresetHitbox.Value and 0.9 or 1
		Maid.HitboxPart.CFrame = RootPart.CFrame
		Maid.HitboxPart.Shape = Enum.PartType[Options.HitboxShape.Value]
		Maid.HitboxPart.Size = Vector3.new(Options.Hitbox_X.Value, Options.Hitbox_Y.Value, Options.Hitbox_Z.Value)

		if not Offset_Y or not Offset_Z then
			return
		end

		Maid.HitboxPart.Weld.C0 = CFrame.new(0, Offset_Y, -Offset_Z)
	end)
end

function Features.JetRunAttack()
	if not Toggles.JetRunAttack.Value then
		if Maid.JetRunAttack then
			Maid.JetRunAttack.Disabled = true
		end

		return
	end

	if not Maid.JetRunAttack then
		Maid.JetRunAttack = EffectReplicator:CreateEffect("ForceMomentum", {Value = 10})
	else
		Maid.JetRunAttack.Disabled = false
	end
end

function Features.RunAttack()
	if not Toggles.RunAttack.Value then
		local ServerSprint = Character and Character:FindFirstChild("ServerSprint", true)
		if ServerSprint then
			ServerSprint:FireServer(false)
		end
		return
	end

	local ServerSprint = Character and Character:FindFirstChild("ServerSprint", true)
	if ServerSprint then
		ServerSprint:FireServer(true)
	end
end

function Features.AntiWind()
	if not Toggles.AntiWind.Value then
		Maid.AntiWind = nil
		return
	end

	Maid.AntiWind = RunService.Heartbeat:Connect(function()
		if not RootPart then
			return
		end

		if RootPart:FindFirstChild("WindPusher") then
			RootPart:FindFirstChild("WindPusher").Parent = nil
		end

		local StrongWindPos = EffectReplicator:FindEffect("StrongWind") and EffectReplicator:FindEffect("StrongWind").Value
		local StrongWind = StrongWindPos and workspace.Thrown:FindFirstChild("WindSide")
		
		if StrongWind then
			local cf = CFrame.new(Vector3.new(), StrongWindPos)
			local WindPosition = CFrame.new(workspace.CurrentCamera.CFrame.p) * cf * CFrame.new(3, -5, 50)
			local LookCF = CFrame.new(RootPart.Position, WindPosition.Position)
			RootPart.CFrame = CFrame.new(LookCF.X, RootPart.Position.Y, LookCF.Z)
		end
	end)
end

function Features.PriorityDodgeFrame()
	if not Toggles.PriorityDodgeFrame.Value then
		Maid.PriorityDodgeFrame = nil
		return
	end

	Maid.PriorityDodgeFrame = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		if input.KeyCode == Enum.KeyCode.Q and EffectReplicator:FindEffect("Blocking") then
			local dodgeRemote = getgenv().DodgeRemote
			local unblockRemote = getgenv().UnblockRemote

			if not dodgeRemote or not unblockRemote then
				return
			end

			unblockRemote:FireServer()
			task.wait()
			dodgeRemote:FireServer("roll", nil, nil, false)
		end
	end)
end

function Features.RemoveLootAllCD()
	if not Toggles.RemoveLootAllCD.Value then
		local v1 = getgenv().require(ReplicatedStorage.Info.RealmInfo)
		v1.IsInstanced = false
		return
	end

	local v1 = getgenv().require(ReplicatedStorage.Info.RealmInfo)
	v1.IsInstanced = true
end

function Features.RemoveZoomLimit()
	if not Toggles.RemoveZoomLimit.Value then
		game.Players.LocalPlayer.CameraMaxZoomDistance = 20
		return
	end

	game.Players.LocalPlayer.CameraMaxZoomDistance = 490
end

function Features.ChatSpy()
	local SquadBark = ReplicatedStorage.Requests:WaitForChild("SquadBark")

	if not Toggles.ChatSpy.Value then
		if not Maid.ChatSpy then return end
		for i,v in pairs(Maid.ChatSpy) do
			v:Disconnect()
		end
		
		Maid.ChatSpy = nil
		return
	end

	Maid.ChatSpy = {}
	for i,plr in pairs(Players:GetPlayers()) do
		Maid.ChatSpy[plr] = plr.Chatted:Connect(function(msg)
			if plr == LocalPlayer then
				return
			end

			for i,v in pairs(getconnections(SquadBark.OnClientEvent)) do
				if not v.Function then continue end
				v.Function(msg, {source = plr.Character, author = plr})
			end
		end)
	end
end

local function lazyfix(name)
	name = name:gsub(' ','')

	local result = ''
	for i,v in pairs(name:split('')) do
		result = result .. ' ' .. v
	end

	return result
end

function Features.ShowAllMap()
	if not Toggles.ShowAllMap.Value then
		Maid.ShowAllMap = nil
		return
	end

	task.spawn(function()
		repeat task.wait() until RootPart

		local MapPointerFunc
		for _,v in pairs(getgc(true)) do
			if typeof(v) ~= "function" then continue end
			if iscclosure(v) or isexecutorclosure(v) then continue end
			local info = debug.getinfo(v)
			local scr_name = info.source
			local encode_constant = HttpService:JSONEncode(debug.getconstants(v))
			if scr_name:match('MapClient') and encode_constant:match('CharacterName') then
				MapPointerFunc = v
				warn('Found mappointerfunc '..tostring(v))
			end
		end
		
		if not MapPointerFunc then
			return
		end
		
		local function addtomap(v)
			if v == LocalPlayer.Character then return end
			if not Players:GetPlayerFromCharacter(v) then return end
			local Humanoid = v:FindFirstChild('Humanoid')

			if Humanoid and Humanoid:GetAttribute('CharacterName') then
				local org = Humanoid:GetAttribute('CharacterName')
				Humanoid:SetAttribute('CharacterName', lazyfix(org))
				task.delay(.5, function()
					Humanoid:SetAttribute('CharacterName', org)
				end)
			end

			SecureCall(MapPointerFunc, v)
		end
		
		for i,v in pairs(workspace.Live:GetChildren()) do
			addtomap(v)
		end
	
		Maid.ShowAllMap = workspace.Live.ChildAdded:Connect(addtomap)
	end)
end

local PromptTag = 'InteractProxPrompt'

---@param Prompt ProximityPrompt
local function ExtendDistance(Prompt)
	if not Prompt:IsA('ProximityPrompt') then
		return
	end
	
	local ActivationDistance = Prompt.MaxActivationDistance
	Prompt:SetAttribute('OldActivationDistance', ActivationDistance)
	Prompt.MaxActivationDistance = ActivationDistance * 2
end

---@param Prompt ProximityPrompt
local function RevertDistance(Prompt)
	if not Prompt:IsA('ProximityPrompt') or not Prompt:GetAttribute('OldActivationDistance') then
		return
	end
	
	local ActivationDistance = Prompt:GetAttribute('OldActivationDistance')
	Prompt:SetAttribute('OldActivationDistance', nil)
	Prompt.MaxActivationDistance = ActivationDistance
end

function Features.ExtendPromptDistance()
	if not Toggles.ExtendPromptDistance.Value then
		Maid.ExtendPromptDistance = nil
		for _, Prompt in pairs(CollectionService:GetTagged(PromptTag)) do
			SecureSpawn(RevertDistance, Prompt)
		end
		return
	end

	Maid.ExtendPromptDistanceAdded = CollectionService:GetInstanceAddedSignal(PromptTag):Connect(ExtendDistance)

	for _, Prompt in pairs(CollectionService:GetTagged(PromptTag)) do
		SecureSpawn(ExtendDistance, Prompt)
	end
end

function Features.NotifyVoidEvents()
	if not Toggles.NotifyVoidEvents.Value then
		Maid.NotifyVoidEvents = nil
		return
	end

	---@param event Model
	Maid.NotifyVoidEvents = workspace.ChildAdded:Connect(function(event)
		if event:GetAttribute('ChestPool') == 'VoidseaChest' then
			local EventName = event.Name
			local EventMobs = event:GetAttribute('MobSpawn')
			
			local message = "A Voidsea Event spawned @everyone\nEventType: %s\nEventMobs:%s"
			message = message:format(EventName, EventMobs)

			Toggles.AutoAstral:SetValue(false)

			if EventMobs:match('mudskipper') then
				Toggles.VoidMobs:SetValue(true)
			else
				Toggles.VoidMobs:SetValue(false)
			end
			
			Library:Notify('Voidsea Event spawned', 5)
		end
	end)
end

---@module Modules/Deepwoken/Replication
local Replication = require("Modules/Deepwoken/Replication")
function Features.CustomESP()
	if not Toggles.CustomESP.Value then
		Replication.ClearTrackers()
		return
	end

	local function OnLiveAdded(child)
		local HumanoidRootPart = child:WaitForChild("HumanoidRootPart", 9e9)
		if not HumanoidRootPart then
			return
		end

		Replication.HealthTracker({
			Character = child
		})
	end

	for _, v in pairs(workspace.Live:GetChildren()) do
		SecureSpawn(OnLiveAdded, v)
	end
	
	for _, v in pairs(workspace.NPCs:GetChildren()) do
		SecureSpawn(OnLiveAdded, v)
	end
end

function Features.AutoRefreshESP()
	if not Toggles.AutoRefreshESP.Value then
		Maid.AutoRefreshESP = nil
		return
	end

	Maid.AutoRefreshESP = task.spawn(function()
		while Toggles.AutoRefreshESP.Value do
			task.wait(Options.AutoRefreshESP.Value)
			SecureCall(getgenv().Maid.ESP)
			task.wait(3)
			SecureCall(getgenv().StartESP)
		end
	end)
end

local function cleanUpTalentPicker()
	local TalentGui = LocalPlayer.PlayerGui:FindFirstChild("TalentGui")
	if not TalentGui then
		return
	end

	local ChoiceFrame = TalentGui:FindFirstChild("ChoiceFrame")
	if not ChoiceFrame then
		return
	end

	for _, v in pairs(ChoiceFrame:GetChildren()) do
		if not v:IsA("TextButton") then
			continue
		end

		local CardFrame = v:FindFirstChild("CardFrame")
		if not CardFrame then
			continue
		end

		CardFrame.BorderSizePixel = 0
	end
end

task.spawn(function()
	repeat
		task.wait()
	until getgenv().SouLoaded

	do -- Get stream around players when we're spectating them
		Maid:GiveTask(RunService.PreRender:Connect(function()
			if not workspace.CurrentCamera.CameraSubject then
				return
			end

			if workspace.CurrentCamera.CameraSubject.Parent == LocalPlayer.Character then
				return
			end

			if not workspace.CurrentCamera.CameraSubject.Parent then
				return
			end

			if not workspace.CurrentCamera.CameraSubject.Parent:IsA("Model") then
				return
			end

			if workspace.StreamingEnabled then
				task.spawn(
					LocalPlayer.RequestStreamAroundAsync,
					LocalPlayer,
					workspace.CurrentCamera.CameraSubject.Parent:GetPivot().Position,
					1
				)
			end
		end))
	end
	
	do -- Damage Indicator & Custom ESP
		local CharList = {}

		---@param child Model
		local function OnLiveAdded(child)
			---@type Humanoid
			local HumanoidRootPart = child:WaitForChild("HumanoidRootPart", 9e9)
			if not HumanoidRootPart then
				return
			end

			local Humanoid = child:WaitForChild("Humanoid", 9e9)
			if not Humanoid or CharList[Humanoid] then
				return
			end
			
			local LastHP = Humanoid.Health
			CharList[child] = true

			child.Destroying:Once(function()
				pcall(function()
					CharList[child] = nil
				end)
			end)
			
			HumanoidRootPart.Destroying:Once(function()
				pcall(function()
					CharList[child] = nil
				end)
			end)

			Maid:GiveTask(Humanoid.HealthChanged:Connect(function()
				local HP = Humanoid.Health

				local Color = Color3.fromRGB(255, 0, 0)
				local diff = HP - LastHP
				if diff >= 0 then
					Color = Color3.fromRGB(0, 255, 0)
				end
				
				LastHP = HP

				if diff >= -0.5 and diff <= 0.5 then
					return
				end

				if Toggles.DamageIndicator.Value and child.Parent == workspace.Live then
					Replication.DamageReadout({
						root = HumanoidRootPart,
						msg = diff,
						col = Color
					})
				end
			end))

			if Toggles.CustomESP.Value then
				Replication.HealthTracker({
					Character = child
				})
			end
		end

		Maid:GiveTask(workspace.Live.ChildAdded:Connect(OnLiveAdded))
		Maid:GiveTask(workspace.NPCs.ChildAdded:Connect(OnLiveAdded))

		for _, v in pairs(workspace.Live:GetChildren()) do
			SecureSpawn(OnLiveAdded, v)
		end
		
		for _, v in pairs(workspace.NPCs:GetChildren()) do
			SecureSpawn(OnLiveAdded, v)
		end
	end

	do -- Constant tween
		Maid:GiveTask(RunService.PreSimulation:Connect(tweenToObjective))
	end

	do -- AP breaker
		Maid:GiveTask(RunService.PreRender:Connect(apBreakerLoop))
	end

	do -- onAdded Connections
		Maid.PlayerAdded = Players.PlayerAdded:Connect(onPlayerAdded)
		for _, v in pairs(Players:GetPlayers()) do
			SecureSpawn(onPlayerAdded, v)
		end

		Maid:GiveTask(LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
		if LocalPlayer.Character then
			SecureSpawn(onCharacterAdded, LocalPlayer.Character)
		end
	end

	do -- Clean-up talent picker
		Maid.TalentPicker = cleanUpTalentPicker
	end

	do -- Clean-up streamer mode
		Maid.StreamerMode = function()
			StreamerMode.Revert()
		end
	end

	SecureSpawn(SpawnNewFrame, 1)
	SecureSpawn(SpawnNewFrame, 2)

	do -- Rapier NPC
		local Common_Name = {'Treasurer','Banker','Antiquarian','Gunsmith','Barber','Blacksmith','Mystic','Guild Librarian','Eiris','Guild Chef','Artisan'}
		Maid:GiveTask(workspace.NPCs.ChildAdded:Connect(function(v)
			if table.find(Common_Name, v.Name) then
				return
			end
			if not Toggles.NotifyNPC.Value then return end
			Library:Notify("NEW NPC Added: "..v.Name .. '. Please check NPC ESP for its location', 5)
		end))

		Maid:GiveTask(workspace.Live.ChildAdded:Connect(function(v)
			if v.Name:lower():match('ministrycache') then
				if not Toggles.NotifyNPC.Value then return end
				Library:Notify("Deepspindle Mob has spawned", 5)
			end
		end))

		for i,v in pairs(workspace.NPCs:GetChildren()) do
			if v.Name:lower():match('ministrycache') or v.Name:lower():match('silhuett') then
				if not Toggles.NotifyNPC.Value then return end
				Library:Notify("Silhuett NPC is in the server", 5)
			end
		end
		
		for i,v in pairs(workspace.Live:GetChildren()) do
			if v.Name:lower():match('ministrycache') then
				if not Toggles.NotifyNPC.Value then return end
				Library:Notify("Deepspindle mob is in the server", 5)
			end
		end
	end
end)

getgenv().Maid.FeaturesMaid = Maid

return Features

end)
__bundle_register("Modules/Deepwoken/Replication", function(require, _LOADED, __bundle_register, __bundle_modules)
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

end)
__bundle_register("ControlModule", function(require, _LOADED, __bundle_register, __bundle_modules)
return (function()
    local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local ControlModule = {};

do
    ControlModule.__index = ControlModule

    function ControlModule.new()
        local self = {
            forwardValue = 0,
            backwardValue = 0,
            leftValue = 0,
            rightValue = 0
        }

        setmetatable(self, ControlModule)
        self:init()
        return self
    end

    function ControlModule:init()
        local handleMoveForward = function(actionName, inputState, inputObject)
            self.forwardValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
            return Enum.ContextActionResult.Pass
        end

        local handleMoveBackward = function(actionName, inputState, inputObject)
            self.backwardValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
            return Enum.ContextActionResult.Pass
        end

        local handleMoveLeft = function(actionName, inputState, inputObject)
            self.leftValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
            return Enum.ContextActionResult.Pass
        end

        local handleMoveRight = function(actionName, inputState, inputObject)
            self.rightValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
            return Enum.ContextActionResult.Pass
        end

        ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveForward, false, Enum.KeyCode.W);
        ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveBackward, false, Enum.KeyCode.S);
        ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveLeft, false, Enum.KeyCode.A);
        ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveRight, false, Enum.KeyCode.D);
    end

    function ControlModule:GetMoveVector()
        return Vector3.new(self.leftValue + self.rightValue, 0, self.forwardValue + self.backwardValue)
    end
end

return ControlModule.new();
end)()
end)
__bundle_register("Features/StreamerMode", function(require, _LOADED, __bundle_register, __bundle_modules)
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
end)
__bundle_register("ThemeManager", function(require, _LOADED, __bundle_register, __bundle_modules)
return (function()
    local httpService = game:GetService('HttpService')
local ThemeManager = {} do
	ThemeManager.Folder = 'LinoriaLibSettings'

	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['Default'] 		= { 1, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232"}') },
		['BBot'] 			= { 2, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
		['Fatality']		= { 3, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
		['Jester'] 			= { 4, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Mint'] 			= { 5, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Tokyo Night'] 	= { 6, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
		['Ubuntu'] 			= { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
		['Quartz'] 			= { 8, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}') },
	}

	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then return end

		local scheme = data[2]
		for idx, col in next, customThemeData or scheme do
			self.Library[idx] = Color3.fromHex(col)
			
			if Options[idx] then
				Options[idx]:SetValueRGB(Color3.fromHex(col))
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
		for i, field in next, options do
			if Options and Options[field] then
				self.Library[field] = Options[field].Value
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()		
		local theme = 'Default'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false;
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
		 	theme = self.DefaultTheme
		end

		if isDefault then
			Options.ThemeManager_ThemeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:CreateThemeManager(groupbox)
		groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor });
		groupbox:AddLabel('Main color')	:AddColorPicker('MainColor', { Default = self.Library.MainColor });
		groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor });
		groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor });
		groupbox:AddLabel('Font color')	:AddColorPicker('FontColor', { Default = self.Library.FontColor });

		local ThemesArray = {}
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

		groupbox:AddDivider()
		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })

		groupbox:AddButton('Set as default', function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value)
			self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_ThemeList.Value))
		end)

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
		end)

		groupbox:AddDivider()
		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		groupbox:AddDivider()
		
		groupbox:AddButton('Save theme', function() 
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)

			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end):AddButton('Load theme', function() 
			self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value) 
		end)

		groupbox:AddButton('Refresh list', function()
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		groupbox:AddButton('Set as default', function()
			if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_CustomThemeList.Value))
			end
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		Options.BackgroundColor:OnChanged(UpdateTheme)
		Options.MainColor:OnChanged(UpdateTheme)
		Options.AccentColor:OnChanged(UpdateTheme)
		Options.OutlineColor:OnChanged(UpdateTheme)
		Options.FontColor:OnChanged(UpdateTheme)
	end

	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. '/themes/' .. file
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(httpService.JSONDecode, httpService, data)
		
		if not success then
			return nil
		end

		return decoded
	end

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 3)
		end

		local theme = {}
		local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

		for _, field in next, fields do
			theme[field] = Options[field].Value:ToHex()
		end

		writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then

				local pos = file:find('.json', 1, true)
				local char = file:sub(pos, pos)

				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1))
				end
			end
		end

		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:BuildFolderTree()
		local paths = {}

		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end

		table.insert(paths, self.Folder .. '/themes')
		table.insert(paths, self.Folder .. '/settings')

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		return tab:AddLeftGroupbox('Themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

return ThemeManager
end)()
end)
__bundle_register("SaveManager", function(require, _LOADED, __bundle_register, __bundle_modules)
return (function()
    local httpService = game:GetService('HttpService')

local SaveManager = {} do
	SaveManager.Folder = 'LinoriaLibSettings'
	SaveManager.Ignore = {}
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) 
				return { type = 'Toggle', idx = idx, value = object.Value } 
			end,
			Load = function(idx, data)
				if Toggles[idx] and Toggles[idx].SetValue then 
					Toggles[idx]:SetValue(data.value)
				end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = 'Slider', idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue(data.value)
				end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = 'Dropdown', idx = idx, value = object.Value, mutli = object.Multi }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue(data.value)
				end
			end,
		},
		ColorPicker = {
			Save = function(idx, object)
				return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
				end
			end,
		},
		KeyPicker = {
			Save = function(idx, object)
				return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue({ data.key, data.mode })
				end
			end,
		},

		Input = {
			Save = function(idx, object)
				return { type = 'Input', idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] and type(data.text) == 'string' then
					Options[idx]:SetValue(data.text)
				end
			end,
		},
	}

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end

	function SaveManager:Save(name)
		if (not name) then
			return false, 'no config file is selected'
		end

		local fullPath = self.Folder .. '/settings/' .. name .. '.json'

		local data = {
			objects = {}
		}

		for idx, toggle in next, Toggles do
			if self.Ignore[idx] then continue end

			table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
		end

		for idx, option in next, Options do
			if not self.Parser[option.Type] then continue end
			if self.Ignore[idx] then continue end

			table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
		end	

		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then
			return false, 'failed to encode data'
		end

		writefile(fullPath, encoded)
		return true
	end

	function SaveManager:Load(name)
		if (not name) then
			return false, 'no config file is selected'
		end
		
		local file = self.Folder .. '/settings/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end

		local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not success then return false, 'decode error' end

		for _, option in next, decoded.objects do
			if self.Parser[option.type] then
				task.spawn(function() self.Parser[option.type].Load(option.idx, option) end)
			end
		end

		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({ 
			"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
			"ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName',
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {
			self.Folder,
			self.Folder .. '/themes',
			self.Folder .. '/settings'
		}

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function SaveManager:RefreshConfigList()
		local list = listfiles(self.Folder .. '/settings')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then

				local pos = file:find('.json', 1, true)
				local start = pos

				local char = file:sub(pos, pos)
				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1, start - 1))
				end
			end
		end
		
		return out
	end

	function SaveManager:SetLibrary(library)
		self.Library = library
	end

	function SaveManager:LoadAutoloadConfig()
		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load autoload config: ' .. err,3)
			end

			self.Library:Notify(string.format('Auto loaded config %q', name),3)
		end
	end


	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, 'Must set SaveManager.Library')

		local section = tab:AddRightGroupbox('Configuration')

		section:AddInput('SaveManager_ConfigName',    { Text = 'Config name' })
		section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true })

		section:AddDivider()

		section:AddButton('Create config', function()
			local name = Options.SaveManager_ConfigName.Value

			if name:gsub(' ', '') == '' then 
				return self.Library:Notify('Invalid config name (empty)', 2)
			end

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to save config: ' .. err,3)
			end

			self.Library:Notify(string.format('Created config %q', name),3)

			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end):AddButton('Load config', function()
			local name = Options.SaveManager_ConfigList.Value

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load config: ' .. err,3)
			end

			self.Library:Notify(string.format('Loaded config %q', name),3)
		end)

		section:AddButton('Overwrite config', function()
			local name = Options.SaveManager_ConfigList.Value

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to overwrite config: ' .. err,3)
			end

			self.Library:Notify(string.format('Overwrote config %q', name),3)
		end)

		section:AddButton('Refresh list', function()
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end)

		section:AddButton('Set as autoload', function()
			local name = Options.SaveManager_ConfigList.Value
			writefile(self.Folder .. '/settings/autoload.txt', name)
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
			self.Library:Notify(string.format('Set %q to auto load', name),3)
		end)

		SaveManager.AutoloadLabel = section:AddLabel('Current autoload config: none', true)

		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
		end

		SaveManager:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
end)()
end)
__bundle_register("Modules/Library", function(require, _LOADED, __bundle_register, __bundle_modules)
local InputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local ScreenGui = Instance.new("ScreenGui")
ProtectGui(ScreenGui)

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

local Toggles = setmetatable({}, {
	__index = function(self, Index)
		local raw_table = rawget(self, "index")
		if raw_table and raw_table[Index] then
			return raw_table[Index]
		else
			return { Value = false } -- prevent errors lol
		end
	end,
})

local Options = {}

getgenv().Toggles = Toggles
getgenv().Options = Options

local Library = {
	Registry = {},
	RegistryMap = {},

	HudRegistry = {},

	FontColor = Color3.fromRGB(255, 255, 255),
	MainColor = Color3.fromRGB(28, 28, 28),
	BackgroundColor = Color3.fromRGB(20, 20, 20),
	AccentColor = Color3.fromRGB(0, 85, 255),
	OutlineColor = Color3.fromRGB(50, 50, 50),
	RiskColor = Color3.fromRGB(255, 50, 50),

	Black = Color3.new(0, 0, 0),
	Font = Enum.Font.Code,

	OpenedFrames = {},
	DependencyBoxes = {},

	Signals = {},
	ScreenGui = ScreenGui,
}

local RainbowStep = 0
local Hue = 0

table.insert(
	Library.Signals,
	RenderStepped:Connect(function(Delta)
		RainbowStep = RainbowStep + Delta

		if RainbowStep >= (1 / 60) then
			RainbowStep = 0

			Hue = Hue + (1 / 400)

			if Hue > 1 then
				Hue = 0
			end

			Library.CurrentRainbowHue = Hue
			Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
		end
	end)
)

local function GetPlayersString()
	local PlayerList = Players:GetPlayers()

	for i = 1, #PlayerList do
		PlayerList[i] = PlayerList[i].Name
	end

	table.sort(PlayerList, function(str1, str2)
		return str1 < str2
	end)

	return PlayerList
end

local function GetTeamsString()
	local TeamList = Teams:GetTeams()

	for i = 1, #TeamList do
		TeamList[i] = TeamList[i].Name
	end

	table.sort(TeamList, function(str1, str2)
		return str1 < str2
	end)

	return TeamList
end

function Library:SafeCallback(f, ...)
	if not f then
		return
	end

	if not Library.NotifyOnError then
		local Success, Response = SecureCall(f, ...)

		if Success then
			return Response
		else
			return
		end
	end

	local success, event = pcall(f, ...)

	if not success then
		local _, i = event:find(":%d+: ")

		if not i then
			return Library:Notify(event)
		end

		return Library:Notify(event:sub(i + 1), 3)
	end
end

function Library:AttemptSave()
	if Library.SaveManager then
		Library.SaveManager:Save()
	end
end

function Library:Create(Class, Properties)
	local _Instance = Class

	if type(Class) == "string" then
		_Instance = Instance.new(Class)
	end

	for Property, Value in next, Properties do
		_Instance[Property] = Value
	end

	return _Instance
end

function Library:ApplyTextStroke(Inst)
	Inst.TextStrokeTransparency = 1

	Library:Create("UIStroke", {
		Color = Color3.new(0, 0, 0),
		Thickness = 1,
		LineJoinMode = Enum.LineJoinMode.Miter,
		Parent = Inst,
	})
end

function Library:CreateLabel(Properties, IsHud)
	local _Instance = Library:Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Library.Font,
		TextColor3 = Library.FontColor,
		TextSize = 16,
		TextStrokeTransparency = 0,
	})

	Library:ApplyTextStroke(_Instance)

	Library:AddToRegistry(_Instance, {
		TextColor3 = "FontColor",
	}, IsHud)

	return Library:Create(_Instance, Properties)
end

function Library:MakeDraggable(Instance, Cutoff)
	Instance.Active = true

	Instance.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			local ObjPos = Vector2.new(Mouse.X - Instance.AbsolutePosition.X, Mouse.Y - Instance.AbsolutePosition.Y)

			if ObjPos.Y > (Cutoff or 40) then
				return
			end

			while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				Instance.Position = UDim2.new(
					0,
					Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
					0,
					Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
				)

				RenderStepped:Wait()
			end
		end
	end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
	local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14)
	local Tooltip = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,

		Size = UDim2.fromOffset(X + 5, Y + 4),
		ZIndex = 100,
		Parent = Library.ScreenGui,

		Visible = false,
	})

	local Label = Library:CreateLabel({
		Position = UDim2.fromOffset(3, 1),
		Size = UDim2.fromOffset(X, Y),
		TextSize = 14,
		Text = InfoStr,
		TextColor3 = Library.FontColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = Tooltip.ZIndex + 1,

		Parent = Tooltip,
	})

	Library:AddToRegistry(Tooltip, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "OutlineColor",
	})

	Library:AddToRegistry(Label, {
		TextColor3 = "FontColor",
	})

	local IsHovering = false

	HoverInstance.MouseEnter:Connect(function()
		if Library:MouseIsOverOpenedFrame() then
			return
		end

		IsHovering = true

		Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
		Tooltip.Visible = true

		while IsHovering do
			RunService.Heartbeat:Wait()
			Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
		end
	end)

	HoverInstance.MouseLeave:Connect(function()
		IsHovering = false
		Tooltip.Visible = false
	end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
	HighlightInstance.MouseEnter:Connect(function()
		local Reg = Library.RegistryMap[Instance]

		for Property, ColorIdx in next, Properties do
			Instance[Property] = Library[ColorIdx] or ColorIdx

			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx
			end
		end
	end)

	HighlightInstance.MouseLeave:Connect(function()
		local Reg = Library.RegistryMap[Instance]

		for Property, ColorIdx in next, PropertiesDefault do
			Instance[Property] = Library[ColorIdx] or ColorIdx

			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx
			end
		end
	end)
end

function Library:MouseIsOverOpenedFrame()
	for Frame, _ in next, Library.OpenedFrames do
		local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize

		if
			Mouse.X >= AbsPos.X
			and Mouse.X <= AbsPos.X + AbsSize.X
			and Mouse.Y >= AbsPos.Y
			and Mouse.Y <= AbsPos.Y + AbsSize.Y
		then
			return true
		end
	end
end

function Library:IsMouseOverFrame(Frame)
	local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize

	if
		Mouse.X >= AbsPos.X
		and Mouse.X <= AbsPos.X + AbsSize.X
		and Mouse.Y >= AbsPos.Y
		and Mouse.Y <= AbsPos.Y + AbsSize.Y
	then
		return true
	end
end

function Library:UpdateDependencyBoxes()
	for _, Depbox in next, Library.DependencyBoxes do
		Depbox:Update()
	end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
	return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
	local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
	return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
	local H, S, V = Color3.toHSV(Color)
	return Color3.fromHSV(H, S, V / 1.5)
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:AddToRegistry(Instance, Properties, IsHud)
	local Idx = #Library.Registry + 1
	local Data = {
		Instance = Instance,
		Properties = Properties,
		Idx = Idx,
	}

	table.insert(Library.Registry, Data)
	Library.RegistryMap[Instance] = Data

	if IsHud then
		table.insert(Library.HudRegistry, Data)
	end
end

function Library:RemoveFromRegistry(Instance)
	local Data = Library.RegistryMap[Instance]

	if Data then
		for Idx = #Library.Registry, 1, -1 do
			if Library.Registry[Idx] == Data then
				table.remove(Library.Registry, Idx)
			end
		end

		for Idx = #Library.HudRegistry, 1, -1 do
			if Library.HudRegistry[Idx] == Data then
				table.remove(Library.HudRegistry, Idx)
			end
		end

		Library.RegistryMap[Instance] = nil
	end
end

function Library:UpdateColorsUsingRegistry()
	for Idx, Object in next, Library.Registry do
		for Property, ColorIdx in next, Object.Properties do
			if type(ColorIdx) == "string" then
				Object.Instance[Property] = Library[ColorIdx]
			elseif type(ColorIdx) == "function" then
				Object.Instance[Property] = ColorIdx()
			end
		end
	end
end

function Library:GiveSignal(Signal)
	table.insert(Library.Signals, Signal)
end

function Library:Unload()
	for Idx = #Library.Signals, 1, -1 do
		local Connection = table.remove(Library.Signals, Idx)
		Connection:Disconnect()
	end

	if Library.OnUnload then
		Library.OnUnload()
	end

	ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
	Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
	if Library.RegistryMap[Instance] then
		Library:RemoveFromRegistry(Instance)
	end
end))

local BaseAddons = {}

do
	local Funcs = {}

	function Funcs:AddColorPicker(Idx, Info)
		local ToggleLabel = self.TextLabel

		assert(Info.Default, "AddColorPicker: Missing default value.")

		local ColorPicker = {
			Value = Info.Default,
			Transparency = Info.Transparency or 0,
			Type = "ColorPicker",
			Title = type(Info.Title) == "string" and Info.Title or "Color picker",
			Callback = Info.Callback or function(Color) end,
		}

		function ColorPicker:SetHSVFromRGB(Color)
			local H, S, V = Color3.toHSV(Color)

			ColorPicker.Hue = H
			ColorPicker.Sat = S
			ColorPicker.Vib = V
		end

		ColorPicker:SetHSVFromRGB(ColorPicker.Value)

		local DisplayFrame = Library:Create("Frame", {
			BackgroundColor3 = ColorPicker.Value,
			BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(0, 28, 0, 14),
			ZIndex = 6,
			Parent = ToggleLabel,
		})

		local CheckerFrame = Library:Create("ImageLabel", {
			BorderSizePixel = 0,
			Size = UDim2.new(0, 27, 0, 13),
			ZIndex = 5,
			Image = "http://www.roblox.com/asset/?id=12977615774",
			Visible = not not Info.Transparency,
			Parent = DisplayFrame,
		})

		local PickerFrameOuter = Library:Create("Frame", {
			Name = "Color",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
			Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253),
			Visible = false,
			ZIndex = 15,
			Parent = ScreenGui,
		})

		DisplayFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			PickerFrameOuter.Position =
				UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18)
		end)

		local PickerFrameInner = Library:Create("Frame", {
			BackgroundColor3 = Library.BackgroundColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 16,
			Parent = PickerFrameOuter,
		})

		local Highlight = Library:Create("Frame", {
			BackgroundColor3 = Library.AccentColor,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 2),
			ZIndex = 17,
			Parent = PickerFrameInner,
		})

		local SatVibMapOuter = Library:Create("Frame", {
			BorderColor3 = Color3.new(0, 0, 0),
			Position = UDim2.new(0, 4, 0, 25),
			Size = UDim2.new(0, 200, 0, 200),
			ZIndex = 17,
			Parent = PickerFrameInner,
		})

		local SatVibMapInner = Library:Create("Frame", {
			BackgroundColor3 = Library.BackgroundColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 18,
			Parent = SatVibMapOuter,
		})

		local SatVibMap = Library:Create("ImageLabel", {
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 18,
			Image = "rbxassetid://4155801252",
			Parent = SatVibMapInner,
		})

		local CursorOuter = Library:Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 6, 0, 6),
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=9619665977",
			ImageColor3 = Color3.new(0, 0, 0),
			ZIndex = 19,
			Parent = SatVibMap,
		})

		local CursorInner = Library:Create("ImageLabel", {
			Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=9619665977",
			ZIndex = 20,
			Parent = CursorOuter,
		})

		local HueSelectorOuter = Library:Create("Frame", {
			BorderColor3 = Color3.new(0, 0, 0),
			Position = UDim2.new(0, 208, 0, 25),
			Size = UDim2.new(0, 15, 0, 200),
			ZIndex = 17,
			Parent = PickerFrameInner,
		})

		local HueSelectorInner = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 18,
			Parent = HueSelectorOuter,
		})

		local HueCursor = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			AnchorPoint = Vector2.new(0, 0.5),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 18,
			Parent = HueSelectorInner,
		})

		local HueBoxOuter = Library:Create("Frame", {
			BorderColor3 = Color3.new(0, 0, 0),
			Position = UDim2.fromOffset(4, 228),
			Size = UDim2.new(0.5, -6, 0, 20),
			ZIndex = 18,
			Parent = PickerFrameInner,
		})

		local HueBoxInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 18,
			Parent = HueBoxOuter,
		})

		Library:Create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
			}),
			Rotation = 90,
			Parent = HueBoxInner,
		})

		local HueBox = Library:Create("TextBox", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, 0),
			Size = UDim2.new(1, -5, 1, 0),
			Font = Library.Font,
			PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
			PlaceholderText = "Hex color",
			Text = "#FFFFFF",
			TextColor3 = Library.FontColor,
			TextSize = 14,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 20,
			Parent = HueBoxInner,
		})

		Library:ApplyTextStroke(HueBox)

		local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
			Position = UDim2.new(0.5, 2, 0, 228),
			Size = UDim2.new(0.5, -6, 0, 20),
			Parent = PickerFrameInner,
		})

		local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild("TextBox"), {
			Text = "255, 255, 255",
			PlaceholderText = "RGB color",
			TextColor3 = Library.FontColor,
		})

		local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor

		if Info.Transparency then
			TransparencyBoxOuter = Library:Create("Frame", {
				BorderColor3 = Color3.new(0, 0, 0),
				Position = UDim2.fromOffset(4, 251),
				Size = UDim2.new(1, -8, 0, 15),
				ZIndex = 19,
				Parent = PickerFrameInner,
			})

			TransparencyBoxInner = Library:Create("Frame", {
				BackgroundColor3 = ColorPicker.Value,
				BorderColor3 = Library.OutlineColor,
				BorderMode = Enum.BorderMode.Inset,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 19,
				Parent = TransparencyBoxOuter,
			})

			Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = "OutlineColor" })

			Library:Create("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Image = "http://www.roblox.com/asset/?id=12978095818",
				ZIndex = 20,
				Parent = TransparencyBoxInner,
			})

			TransparencyCursor = Library:Create("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				AnchorPoint = Vector2.new(0.5, 0),
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(0, 1, 1, 0),
				ZIndex = 21,
				Parent = TransparencyBoxInner,
			})
		end

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.fromOffset(5, 5),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 14,
			Text = ColorPicker.Title,
			TextWrapped = false,
			ZIndex = 16,
			Parent = PickerFrameInner,
		})

		local ContextMenu = {}
		do
			ContextMenu.Options = {}
			ContextMenu.Container = Library:Create("Frame", {
				BorderColor3 = Color3.new(),
				ZIndex = 14,

				Visible = false,
				Parent = ScreenGui,
			})

			ContextMenu.Inner = Library:Create("Frame", {
				BackgroundColor3 = Library.BackgroundColor,
				BorderColor3 = Library.OutlineColor,
				BorderMode = Enum.BorderMode.Inset,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 15,
				Parent = ContextMenu.Container,
			})

			Library:Create("UIListLayout", {
				Name = "Layout",
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = ContextMenu.Inner,
			})

			Library:Create("UIPadding", {
				Name = "Padding",
				PaddingLeft = UDim.new(0, 4),
				Parent = ContextMenu.Inner,
			})

			local function updateMenuPosition()
				ContextMenu.Container.Position = UDim2.fromOffset(
					(DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
					DisplayFrame.AbsolutePosition.Y + 1
				)
			end

			local function updateMenuSize()
				local menuWidth = 60
				for i, label in next, ContextMenu.Inner:GetChildren() do
					if label:IsA("TextLabel") then
						menuWidth = math.max(menuWidth, label.TextBounds.X)
					end
				end

				ContextMenu.Container.Size =
					UDim2.fromOffset(menuWidth + 8, ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4)
			end

			DisplayFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateMenuPosition)
			ContextMenu.Inner.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateMenuSize)

			task.spawn(updateMenuPosition)
			task.spawn(updateMenuSize)

			Library:AddToRegistry(ContextMenu.Inner, {
				BackgroundColor3 = "BackgroundColor",
				BorderColor3 = "OutlineColor",
			})

			function ContextMenu:Show()
				self.Container.Visible = true
			end

			function ContextMenu:Hide()
				self.Container.Visible = false
			end

			function ContextMenu:AddOption(Str, Callback)
				if type(Callback) ~= "function" then
					Callback = function() end
				end

				local Button = Library:CreateLabel({
					Active = false,
					Size = UDim2.new(1, 0, 0, 15),
					TextSize = 13,
					Text = Str,
					ZIndex = 16,
					Parent = self.Inner,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				Library:OnHighlight(Button, Button, { TextColor3 = "AccentColor" }, { TextColor3 = "FontColor" })

				Button.InputBegan:Connect(function(Input)
					if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
						return
					end

					Callback()
				end)
			end

			ContextMenu:AddOption("Copy color", function()
				Library.ColorClipboard = ColorPicker.Value
				Library:Notify("Copied color!", 2)
			end)

			ContextMenu:AddOption("Paste color", function()
				if not Library.ColorClipboard then
					return Library:Notify("You have not copied a color!", 2)
				end
				ColorPicker:SetValueRGB(Library.ColorClipboard)
			end)

			ContextMenu:AddOption("Copy HEX", function()
				pcall(setclipboard, ColorPicker.Value:ToHex())
				Library:Notify("Copied hex code to clipboard!", 2)
			end)

			ContextMenu:AddOption("Copy RGB", function()
				pcall(
					setclipboard,
					table.concat(
						{
							math.floor(ColorPicker.Value.R * 255),
							math.floor(ColorPicker.Value.G * 255),
							math.floor(ColorPicker.Value.B * 255),
						},
						", "
					)
				)
				Library:Notify("Copied RGB values to clipboard!", 2)
			end)
		end

		Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor" })
		Library:AddToRegistry(Highlight, { BackgroundColor3 = "AccentColor" })
		Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor" })

		Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor" })
		Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor" })
		Library:AddToRegistry(RgbBox, { TextColor3 = "FontColor" })
		Library:AddToRegistry(HueBox, { TextColor3 = "FontColor" })

		local SequenceTable = {}

		for Hue = 0, 1, 0.1 do
			table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
		end

		local HueSelectorGradient = Library:Create("UIGradient", {
			Color = ColorSequence.new(SequenceTable),
			Rotation = 90,
			Parent = HueSelectorInner,
		})

		HueBox.FocusLost:Connect(function(enter)
			if enter then
				local success, result = pcall(Color3.fromHex, HueBox.Text)
				if success and typeof(result) == "Color3" then
					ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
				end
			end

			ColorPicker:Display()
		end)

		RgbBox.FocusLost:Connect(function(enter)
			if enter then
				local r, g, b = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
				if r and g and b then
					ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
				end
			end

			ColorPicker:Display()
		end)

		function ColorPicker:Display()
			ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
			SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)

			Library:Create(DisplayFrame, {
				BackgroundColor3 = ColorPicker.Value,
				BackgroundTransparency = ColorPicker.Transparency,
				BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
			})

			if TransparencyBoxInner then
				TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value
				TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0)
			end

			CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0)
			HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0)

			HueBox.Text = "#" .. ColorPicker.Value:ToHex()
			RgbBox.Text = table.concat(
				{
					math.floor(ColorPicker.Value.R * 255),
					math.floor(ColorPicker.Value.G * 255),
					math.floor(ColorPicker.Value.B * 255),
				},
				", "
			)

			Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
			Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
		end

		function ColorPicker:OnChanged(Func)
			ColorPicker.Changed = Func
			Func(ColorPicker.Value)
		end

		function ColorPicker:Show()
			for Frame, Val in next, Library.OpenedFrames do
				if Frame.Name == "Color" then
					Frame.Visible = false
					Library.OpenedFrames[Frame] = nil
				end
			end

			PickerFrameOuter.Visible = true
			Library.OpenedFrames[PickerFrameOuter] = true
		end

		function ColorPicker:Hide()
			PickerFrameOuter.Visible = false
			Library.OpenedFrames[PickerFrameOuter] = nil
		end

		function ColorPicker:SetValue(HSV, Transparency)
			local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])

			ColorPicker.Transparency = Transparency or 0
			ColorPicker:SetHSVFromRGB(Color)
			ColorPicker:Display()
		end

		function ColorPicker:SetValueRGB(Color, Transparency)
			ColorPicker.Transparency = Transparency or 0
			ColorPicker:SetHSVFromRGB(Color)
			ColorPicker:Display()
		end

		SatVibMap.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local MinX = SatVibMap.AbsolutePosition.X
					local MaxX = MinX + SatVibMap.AbsoluteSize.X
					local MouseX = math.clamp(Mouse.X, MinX, MaxX)

					local MinY = SatVibMap.AbsolutePosition.Y
					local MaxY = MinY + SatVibMap.AbsoluteSize.Y
					local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

					ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX)
					ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))
					ColorPicker:Display()

					RenderStepped:Wait()
				end

				Library:AttemptSave()
			end
		end)

		HueSelectorInner.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local MinY = HueSelectorInner.AbsolutePosition.Y
					local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y
					local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

					ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY))
					ColorPicker:Display()

					RenderStepped:Wait()
				end

				Library:AttemptSave()
			end
		end)

		DisplayFrame.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				if PickerFrameOuter.Visible then
					ColorPicker:Hide()
				else
					ContextMenu:Hide()
					ColorPicker:Show()
				end
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
				ContextMenu:Show()
				ColorPicker:Hide()
			end
		end)

		if TransparencyBoxInner then
			TransparencyBoxInner.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
						local MinX = TransparencyBoxInner.AbsolutePosition.X
						local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X
						local MouseX = math.clamp(Mouse.X, MinX, MaxX)

						ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX))

						ColorPicker:Display()

						RenderStepped:Wait()
					end

					Library:AttemptSave()
				end
			end)
		end

		Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize

				if
					Mouse.X < AbsPos.X
					or Mouse.X > AbsPos.X + AbsSize.X
					or Mouse.Y < (AbsPos.Y - 20 - 1)
					or Mouse.Y > AbsPos.Y + AbsSize.Y
				then
					ColorPicker:Hide()
				end

				if not Library:IsMouseOverFrame(ContextMenu.Container) then
					ContextMenu:Hide()
				end
			end

			if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
				if
					not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame)
				then
					ContextMenu:Hide()
				end
			end
		end))

		ColorPicker:Display()
		ColorPicker.DisplayFrame = DisplayFrame

		Options[Idx] = ColorPicker

		return self
	end

	function Funcs:AddKeyPicker(Idx, Info)
		local ParentObj = self
		local ToggleLabel = self.TextLabel
		local Container = self.Container

		assert(Info.Default, "AddKeyPicker: Missing default value.")

		local KeyPicker = {
			Value = Info.Default,
			Toggled = false,
			Mode = Info.Mode or "Toggle", -- Always, Toggle, Hold
			Type = "KeyPicker",
			Callback = Info.Callback or function(Value) end,
			ChangedCallback = Info.ChangedCallback or function(New) end,

			SyncToggleState = Info.SyncToggleState or false,
		}

		if KeyPicker.SyncToggleState then
			Info.Modes = { "Toggle" }
			Info.Mode = "Toggle"
		end

		local PickOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(0, 28, 0, 15),
			ZIndex = 6,
			Parent = ToggleLabel,
		})

		local PickInner = Library:Create("Frame", {
			BackgroundColor3 = Library.BackgroundColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 7,
			Parent = PickOuter,
		})

		Library:AddToRegistry(PickInner, {
			BackgroundColor3 = "BackgroundColor",
			BorderColor3 = "OutlineColor",
		})

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 1, 0),
			TextSize = 13,
			Text = Info.Default,
			TextWrapped = true,
			ZIndex = 8,
			Parent = PickInner,
		})

		local ModeSelectOuter = Library:Create("Frame", {
			BorderColor3 = Color3.new(0, 0, 0),
			Position = UDim2.fromOffset(
				ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4,
				ToggleLabel.AbsolutePosition.Y + 1
			),
			Size = UDim2.new(0, 60, 0, 45 + 2),
			Visible = false,
			ZIndex = 14,
			Parent = ScreenGui,
		})

		ToggleLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			ModeSelectOuter.Position = UDim2.fromOffset(
				ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4,
				ToggleLabel.AbsolutePosition.Y + 1
			)
		end)

		local ModeSelectInner = Library:Create("Frame", {
			BackgroundColor3 = Library.BackgroundColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 15,
			Parent = ModeSelectOuter,
		})

		Library:AddToRegistry(ModeSelectInner, {
			BackgroundColor3 = "BackgroundColor",
			BorderColor3 = "OutlineColor",
		})

		Library:Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = ModeSelectInner,
		})

		local ContainerLabel = Library:CreateLabel({
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 18),
			TextSize = 13,
			Visible = false,
			ZIndex = 110,
			Parent = Library.KeybindContainer,
		}, true)

		local Modes = Info.Modes or { "Always", "Toggle", "Hold" }
		local ModeButtons = {}

		for Idx, Mode in next, Modes do
			local ModeButton = {}

			local Label = Library:CreateLabel({
				Active = false,
				Size = UDim2.new(1, 0, 0, 15),
				TextSize = 13,
				Text = Mode,
				ZIndex = 16,
				Parent = ModeSelectInner,
			})

			function ModeButton:Select()
				for _, Button in next, ModeButtons do
					Button:Deselect()
				end

				KeyPicker.Mode = Mode

				Label.TextColor3 = Library.AccentColor
				Library.RegistryMap[Label].Properties.TextColor3 = "AccentColor"

				ModeSelectOuter.Visible = false
			end

			function ModeButton:Deselect()
				KeyPicker.Mode = nil

				Label.TextColor3 = Library.FontColor
				Library.RegistryMap[Label].Properties.TextColor3 = "FontColor"
			end

			Label.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					ModeButton:Select()
					Library:AttemptSave()
				end
			end)

			if Mode == KeyPicker.Mode then
				ModeButton:Select()
			end

			ModeButtons[Mode] = ModeButton
		end

		function KeyPicker:Update()
			if Info.NoUI then
				return
			end

			local State = KeyPicker:GetState()

			ContainerLabel.Text = string.format("[%s] %s (%s)", KeyPicker.Value, Info.Text, KeyPicker.Mode)

			ContainerLabel.Visible = true
			ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor

			Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and "AccentColor" or "FontColor"

			local YSize = 0
			local XSize = 0

			for _, Label in next, Library.KeybindContainer:GetChildren() do
				if Label:IsA("TextLabel") and Label.Visible then
					YSize = YSize + 18
					if Label.TextBounds.X > XSize then
						XSize = Label.TextBounds.X
					end
				end
			end

			Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
		end

		function KeyPicker:GetState()
			if KeyPicker.Mode == "Always" then
				return true
			elseif KeyPicker.Mode == "Hold" then
				if KeyPicker.Value == "None" or KeyPicker.Value == "N/A" then
					return false
				end

				local Key = KeyPicker.Value

				if Key == "MB1" or Key == "MB2" then
					return Key == "MB1" and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
						or Key == "MB2" and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
				else
					return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value])
				end
			else
				return KeyPicker.Toggled
			end
		end

		function KeyPicker:SetValue(Data)
			local Key, Mode = Data[1], Data[2]
			DisplayLabel.Text = Key
			KeyPicker.Value = Key
			ModeButtons[Mode]:Select()
			KeyPicker:Update()
		end

		function KeyPicker:OnClick(Callback)
			KeyPicker.Clicked = Callback
		end

		function KeyPicker:OnChanged(Callback)
			KeyPicker.Changed = Callback
			Callback(KeyPicker.Value)
		end

		if ParentObj.Addons then
			table.insert(ParentObj.Addons, KeyPicker)
		end

		function KeyPicker:DoClick()
			if ParentObj.Type == "Toggle" and KeyPicker.SyncToggleState then
				ParentObj:SetValue(not ParentObj.Value)
			end

			Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
			Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
		end

		local Picking = false

		PickOuter.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				Picking = true

				DisplayLabel.Text = ""

				local Break
				local Text = ""

				task.spawn(function()
					while not Break do
						if Text == "..." then
							Text = ""
						end

						Text = Text .. "."
						DisplayLabel.Text = Text

						wait(0.4)
					end
				end)

				wait(0.2)

				local Event
				Event = InputService.InputBegan:Connect(function(Input)
					local Key

					if Input.UserInputType == Enum.UserInputType.Keyboard then
						Key = Input.KeyCode.Name
					elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Key = "MB1"
					elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
						Key = "MB2"
					end

					Break = true
					Picking = false

					DisplayLabel.Text = Key
					KeyPicker.Value = Key

					Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
					Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

					Library:AttemptSave()

					Event:Disconnect()
				end)
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
				ModeSelectOuter.Visible = true
			end
		end)

		Library:GiveSignal(InputService.InputBegan:Connect(function(Input, gpe)
			if gpe then
				return
			end
			if not Picking then
				if KeyPicker.Mode == "Toggle" then
					local Key = KeyPicker.Value

					if Key == "MB1" or Key == "MB2" then
						if
							Key == "MB1" and Input.UserInputType == Enum.UserInputType.MouseButton1
							or Key == "MB2" and Input.UserInputType == Enum.UserInputType.MouseButton2
						then
							KeyPicker.Toggled = not KeyPicker.Toggled
							KeyPicker:DoClick()
						end
					elseif Input.UserInputType == Enum.UserInputType.Keyboard then
						if Input.KeyCode.Name == Key then
							KeyPicker.Toggled = not KeyPicker.Toggled
							KeyPicker:DoClick()
						end
					end
				end

				KeyPicker:Update()
			end

			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize

				if
					Mouse.X < AbsPos.X
					or Mouse.X > AbsPos.X + AbsSize.X
					or Mouse.Y < (AbsPos.Y - 20 - 1)
					or Mouse.Y > AbsPos.Y + AbsSize.Y
				then
					ModeSelectOuter.Visible = false
				end
			end
		end))

		Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
			if not Picking then
				KeyPicker:Update()
			end
		end))

		KeyPicker:Update()

		Options[Idx] = KeyPicker

		return self
	end

	BaseAddons.__index = Funcs
	BaseAddons.__namecall = function(Table, Key, ...)
		return Funcs[Key](...)
	end
end

local BaseGroupbox = {}

do
	local Funcs = {}

	function Funcs:AddBlank(Size)
		local Groupbox = self
		local Container = Groupbox.Container

		Library:Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Size),
			ZIndex = 1,
			Parent = Container,
		})
	end

	function Funcs:AddLabel(Text, DoesWrap)
		local Label = {}

		local Groupbox = self
		local Container = Groupbox.Container

		local TextLabel = Library:CreateLabel({
			Size = UDim2.new(1, -4, 0, 15),
			TextSize = 14,
			Text = Text,
			TextWrapped = DoesWrap or false,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = Container,
		})

		if DoesWrap then
			local Y = select(
				2,
				Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge))
			)
			TextLabel.Size = UDim2.new(1, -4, 0, Y)
		else
			Library:Create("UIListLayout", {
				Padding = UDim.new(0, 4),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = TextLabel,
			})
		end

		Label.TextLabel = TextLabel
		Label.Container = Container

		function Label:SetText(Text)
			TextLabel.Text = Text

			if DoesWrap then
				local Y = select(
					2,
					Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge))
				)
				TextLabel.Size = UDim2.new(1, -4, 0, Y)
			end

			Groupbox:Resize()
		end

		if not DoesWrap then
			setmetatable(Label, BaseAddons)
		end

		Groupbox:AddBlank(5)
		Groupbox:Resize()

		return Label
	end

	function Funcs:AddButton(...)
		local Button = {}
		local function ProcessButtonParams(Class, Obj, ...)
			local Props = select(1, ...)
			if type(Props) == "table" then
				Obj.Text = Props.Text
				Obj.Func = Props.Func
				Obj.DoubleClick = Props.DoubleClick
				Obj.Tooltip = Props.Tooltip
			else
				Obj.Text = select(1, ...)
				Obj.Func = select(2, ...)
			end

			assert(type(Obj.Func) == "function", "AddButton: `Func` callback is missing.")
		end

		ProcessButtonParams("Button", Button, ...)

		local Groupbox = self
		local Container = Groupbox.Container

		local function CreateBaseButton(Button)
			local Outer = Library:Create("Frame", {
				BackgroundColor3 = Color3.new(0, 0, 0),
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1, -4, 0, 20),
				ZIndex = 5,
			})

			local Inner = Library:Create("Frame", {
				BackgroundColor3 = Library.MainColor,
				BorderColor3 = Library.OutlineColor,
				BorderMode = Enum.BorderMode.Inset,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 6,
				Parent = Outer,
			})

			local Label = Library:CreateLabel({
				Size = UDim2.new(1, 0, 1, 0),
				TextSize = 14,
				Text = Button.Text,
				ZIndex = 6,
				Parent = Inner,
			})

			Library:Create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
				}),
				Rotation = 90,
				Parent = Inner,
			})

			Library:AddToRegistry(Outer, {
				BorderColor3 = "Black",
			})

			Library:AddToRegistry(Inner, {
				BackgroundColor3 = "MainColor",
				BorderColor3 = "OutlineColor",
			})

			Library:OnHighlight(Outer, Outer, { BorderColor3 = "AccentColor" }, { BorderColor3 = "Black" })

			return Outer, Inner, Label
		end

		local function InitEvents(Button)
			local function WaitForEvent(event, timeout, validator)
				local bindable = Instance.new("BindableEvent")
				local connection = event:Once(function(...)
					if type(validator) == "function" and validator(...) then
						bindable:Fire(true)
					else
						bindable:Fire(false)
					end
				end)
				task.delay(timeout, function()
					connection:disconnect()
					bindable:Fire(false)
				end)
				return bindable.Event:Wait()
			end

			local function ValidateClick(Input)
				if Library:MouseIsOverOpenedFrame() then
					return false
				end

				if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return false
				end

				return true
			end

			Button.Outer.InputBegan:Connect(function(Input)
				if not ValidateClick(Input) then
					return
				end
				if Button.Locked then
					return
				end

				if Button.DoubleClick then
					Library:RemoveFromRegistry(Button.Label)
					Library:AddToRegistry(Button.Label, { TextColor3 = "AccentColor" })

					Button.Label.TextColor3 = Library.AccentColor
					Button.Label.Text = "Are you sure?"
					Button.Locked = true

					local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

					Library:RemoveFromRegistry(Button.Label)
					Library:AddToRegistry(Button.Label, { TextColor3 = "FontColor" })

					Button.Label.TextColor3 = Library.FontColor
					Button.Label.Text = Button.Text
					task.defer(rawset, Button, "Locked", false)

					if clicked then
						Library:SafeCallback(Button.Func)
					end

					return
				end

				Library:SafeCallback(Button.Func)
			end)
		end

		Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
		Button.Outer.Parent = Container

		InitEvents(Button)

		function Button:AddTooltip(tooltip)
			if type(tooltip) == "string" then
				Library:AddToolTip(tooltip, self.Outer)
			end
			return self
		end

		function Button:AddButton(...)
			local SubButton = {}

			ProcessButtonParams("SubButton", SubButton, ...)

			self.Outer.Size = UDim2.new(0.5, -2, 0, 20)

			SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

			SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
			SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
			SubButton.Outer.Parent = self.Outer

			function SubButton:AddTooltip(tooltip)
				if type(tooltip) == "string" then
					Library:AddToolTip(tooltip, self.Outer)
				end
				return SubButton
			end

			if type(SubButton.Tooltip) == "string" then
				SubButton:AddTooltip(SubButton.Tooltip)
			end

			InitEvents(SubButton)
			return SubButton
		end

		if type(Button.Tooltip) == "string" then
			Button:AddTooltip(Button.Tooltip)
		end

		Groupbox:AddBlank(5)
		Groupbox:Resize()

		return Button
	end

	function Funcs:AddDivider()
		local Groupbox = self
		local Container = self.Container

		local Divider = {
			Type = "Divider",
		}

		Groupbox:AddBlank(2)
		local DividerOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(1, -4, 0, 5),
			ZIndex = 5,
			Parent = Container,
		})

		local DividerInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 6,
			Parent = DividerOuter,
		})

		Library:AddToRegistry(DividerOuter, {
			BorderColor3 = "Black",
		})

		Library:AddToRegistry(DividerInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		Groupbox:AddBlank(9)
		Groupbox:Resize()
	end

	function Funcs:AddInput(Idx, Info)
		assert(Info.Text, "AddInput: Missing `Text` string.")

		local Textbox = {
			Value = Info.Default or "",
			Numeric = Info.Numeric or false,
			Finished = Info.Finished or false,
			Type = "Input",
			Callback = Info.Callback or function(Value) end,
		}

		local Groupbox = self
		local Container = Groupbox.Container

		local InputLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 0, 15),
			TextSize = 14,
			Text = Info.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = Container,
		})

		Groupbox:AddBlank(1)

		local TextBoxOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(1, -4, 0, 20),
			ZIndex = 5,
			Parent = Container,
		})

		local TextBoxInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 6,
			Parent = TextBoxOuter,
		})

		Library:AddToRegistry(TextBoxInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		Library:OnHighlight(TextBoxOuter, TextBoxOuter, { BorderColor3 = "AccentColor" }, { BorderColor3 = "Black" })

		if type(Info.Tooltip) == "string" then
			Library:AddToolTip(Info.Tooltip, TextBoxOuter)
		end

		Library:Create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
			}),
			Rotation = 90,
			Parent = TextBoxInner,
		})

		local Container = Library:Create("Frame", {
			BackgroundTransparency = 1,
			ClipsDescendants = true,

			Position = UDim2.new(0, 5, 0, 0),
			Size = UDim2.new(1, -5, 1, 0),

			ZIndex = 7,
			Parent = TextBoxInner,
		})

		local Box = Library:Create("TextBox", {
			BackgroundTransparency = 1,

			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromScale(5, 1),

			Font = Library.Font,
			PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
			PlaceholderText = Info.Placeholder or "",

			Text = Info.Default or "",
			TextColor3 = Library.FontColor,
			TextSize = 14,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,

			ZIndex = 7,
			Parent = Container,
		})

		Library:ApplyTextStroke(Box)

		function Textbox:SetValue(Text)
			if Info.MaxLength and #Text > Info.MaxLength then
				Text = Text:sub(1, Info.MaxLength)
			end

			if Textbox.Numeric then
				if (not tonumber(Text)) and Text:len() > 0 then
					Text = Textbox.Value
				end
			end

			Textbox.Value = Text
			Box.Text = Text

			Library:SafeCallback(Textbox.Callback, Textbox.Value)
			Library:SafeCallback(Textbox.Changed, Textbox.Value)
		end

		if Textbox.Finished then
			Box.FocusLost:Connect(function(enter)
				if not enter then
					return
				end

				Textbox:SetValue(Box.Text)
				Library:AttemptSave()
			end)
		else
			Box:GetPropertyChangedSignal("Text"):Connect(function()
				Textbox:SetValue(Box.Text)
				Library:AttemptSave()
			end)
		end

		local function Update()
			local PADDING = 2
			local reveal = Container.AbsoluteSize.X

			if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
				Box.Position = UDim2.new(0, PADDING, 0, 0)
			else
				local cursor = Box.CursorPosition
				if cursor ~= -1 then
					local subtext = string.sub(Box.Text, 1, cursor - 1)
					local width =
						TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X
					local currentCursorPos = Box.Position.X.Offset + width

					if currentCursorPos < PADDING then
						Box.Position = UDim2.fromOffset(PADDING - width, 0)
					elseif currentCursorPos > reveal - PADDING - 1 then
						Box.Position = UDim2.fromOffset(reveal - width - PADDING - 1, 0)
					end
				end
			end
		end

		task.spawn(Update)

		Box:GetPropertyChangedSignal("Text"):Connect(Update)
		Box:GetPropertyChangedSignal("CursorPosition"):Connect(Update)
		Box.FocusLost:Connect(Update)
		Box.Focused:Connect(Update)

		Library:AddToRegistry(Box, {
			TextColor3 = "FontColor",
		})

		function Textbox:OnChanged(Func)
			Textbox.Changed = Func
			Func(Textbox.Value)
		end

		Groupbox:AddBlank(5)
		Groupbox:Resize()

		Options[Idx] = Textbox

		return Textbox
	end

	function Funcs:AddToggle(Idx, Info)
		assert(Info.Text, "AddInput: Missing `Text` string.")

		local Toggle = {
			Value = Info.Default or false,
			Type = "Toggle",

			Callback = Info.Callback or function(Value) end,
			Addons = {},
			Risky = Info.Risky,
		}

		local Groupbox = self
		local Container = Groupbox.Container

		local ToggleOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(0, 13, 0, 13),
			ZIndex = 5,
			Parent = Container,
		})

		Library:AddToRegistry(ToggleOuter, {
			BorderColor3 = "Black",
		})

		local ToggleInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 6,
			Parent = ToggleOuter,
		})

		Library:AddToRegistry(ToggleInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		local ToggleLabel = Library:CreateLabel({
			Size = UDim2.new(0, 216, 1, 0),
			Position = UDim2.new(1, 6, 0, 0),
			TextSize = 14,
			Text = Info.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
			Parent = ToggleInner,
		})

		Library:Create("UIListLayout", {
			Padding = UDim.new(0, 4),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = ToggleLabel,
		})

		local ToggleRegion = Library:Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 170, 1, 0),
			ZIndex = 8,
			Parent = ToggleOuter,
		})

		Library:OnHighlight(ToggleRegion, ToggleOuter, { BorderColor3 = "AccentColor" }, { BorderColor3 = "Black" })

		function Toggle:UpdateColors()
			Toggle:Display()
		end

		if type(Info.Tooltip) == "string" then
			Library:AddToolTip(Info.Tooltip, ToggleRegion)
		end

		function Toggle:Display()
			ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor
			ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor

			Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
			Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and "AccentColorDark"
				or "OutlineColor"
		end

		function Toggle:OnChanged(Func)
			Toggle.Changed = Func
			Func(Toggle.Value)
		end

		function Toggle:SetValue(Bool)
			Bool = not not Bool

			Toggle.Value = Bool
			Toggle:Display()

			for _, Addon in next, Toggle.Addons do
				if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
					Addon.Toggled = Bool
					Addon:Update()
				end
			end

			Library:SafeCallback(Toggle.Callback, Toggle.Value)
			Library:SafeCallback(Toggle.Changed, Toggle.Value)
			Library:UpdateDependencyBoxes()
		end

		ToggleRegion.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				Toggle:SetValue(not Toggle.Value)
				Library:AttemptSave()
			end
		end)

		if Toggle.Risky then
			Library:RemoveFromRegistry(ToggleLabel)
			ToggleLabel.TextColor3 = Library.RiskColor
			Library:AddToRegistry(ToggleLabel, { TextColor3 = "RiskColor" })
		end

		Toggle:Display()
		Groupbox:AddBlank(Info.BlankSize or 5 + 2)
		Groupbox:Resize()

		Toggle.TextLabel = ToggleLabel
		Toggle.Container = Container
		setmetatable(Toggle, BaseAddons)

		Toggles[Idx] = Toggle

		Library:UpdateDependencyBoxes()

		return Toggle
	end

	function Funcs:AddSlider(Idx, Info)
		assert(Info.Default, "AddSlider: Missing default value.")
		assert(Info.Text, "AddSlider: Missing slider text.")
		assert(Info.Min, "AddSlider: Missing minimum value.")
		assert(Info.Max, "AddSlider: Missing maximum value.")
		assert(Info.Rounding, "AddSlider: Missing rounding value.")

		local Slider = {
			Value = Info.Default,
			Min = Info.Min,
			Max = Info.Max,
			Rounding = Info.Rounding,
			MaxSize = 232,
			Type = "Slider",
			Callback = Info.Callback or function(Value) end,
		}

		local Groupbox = self
		local Container = Groupbox.Container

		if not Info.Compact then
			Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 10),
				TextSize = 14,
				Text = Info.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				ZIndex = 5,
				Parent = Container,
			})

			Groupbox:AddBlank(3)
		end

		local SliderOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(1, -4, 0, 13),
			ZIndex = 5,
			Parent = Container,
		})

		Library:AddToRegistry(SliderOuter, {
			BorderColor3 = "Black",
		})

		local SliderInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 6,
			Parent = SliderOuter,
		})

		Library:AddToRegistry(SliderInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		local Fill = Library:Create("Frame", {
			BackgroundColor3 = Library.AccentColor,
			BorderColor3 = Library.AccentColorDark,
			Size = UDim2.new(0, 0, 1, 0),
			ZIndex = 7,
			Parent = SliderInner,
		})

		Library:AddToRegistry(Fill, {
			BackgroundColor3 = "AccentColor",
			BorderColor3 = "AccentColorDark",
		})

		local HideBorderRight = Library:Create("Frame", {
			BackgroundColor3 = Library.AccentColor,
			BorderSizePixel = 0,
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 1, 1, 0),
			ZIndex = 8,
			Parent = Fill,
		})

		Library:AddToRegistry(HideBorderRight, {
			BackgroundColor3 = "AccentColor",
		})

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 1, 0),
			TextSize = 14,
			Text = "Infinite",
			ZIndex = 9,
			Parent = SliderInner,
		})

		Library:OnHighlight(SliderOuter, SliderOuter, { BorderColor3 = "AccentColor" }, { BorderColor3 = "Black" })

		if type(Info.Tooltip) == "string" then
			Library:AddToolTip(Info.Tooltip, SliderOuter)
		end

		function Slider:UpdateColors()
			Fill.BackgroundColor3 = Library.AccentColor
			Fill.BorderColor3 = Library.AccentColorDark
		end

		function Slider:Display()
			local Suffix = Info.Suffix or ""

			if Info.Compact then
				DisplayLabel.Text = Info.Text .. ": " .. Slider.Value .. Suffix
			elseif Info.HideMax then
				DisplayLabel.Text = string.format("%s", Slider.Value .. Suffix)
			else
				DisplayLabel.Text = string.format("%s/%s", Slider.Value .. Suffix, Slider.Max .. Suffix)
			end

			local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize))
			Fill.Size = UDim2.new(0, X, 1, 0)

			HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0)
		end

		function Slider:OnChanged(Func)
			Slider.Changed = Func
			Func(Slider.Value)
		end

		local function Round(Value)
			if Slider.Rounding == 0 then
				return math.floor(Value)
			end

			return tonumber(string.format("%." .. Slider.Rounding .. "f", Value))
		end

		function Slider:GetValueFromXOffset(X)
			return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max))
		end

		function Slider:SetValue(Str)
			local Num = tonumber(Str)

			if not Num then
				return
			end

			Num = math.clamp(Num, Slider.Min, Slider.Max)

			Slider.Value = Num
			Slider:Display()

			Library:SafeCallback(Slider.Callback, Slider.Value)
			Library:SafeCallback(Slider.Changed, Slider.Value)
		end

		SliderInner.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				local mPos = Mouse.X
				local gPos = Fill.Size.X.Offset
				local Diff = mPos - (Fill.AbsolutePosition.X + gPos)

				while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local nMPos = Mouse.X
					local nX = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize)

					local nValue = Slider:GetValueFromXOffset(nX)
					local OldValue = Slider.Value
					Slider.Value = nValue

					Slider:Display()

					if nValue ~= OldValue then
						Library:SafeCallback(Slider.Callback, Slider.Value)
						Library:SafeCallback(Slider.Changed, Slider.Value)
					end

					RenderStepped:Wait()
				end

				Library:AttemptSave()
			end
		end)

		Slider:Display()
		Groupbox:AddBlank(Info.BlankSize or 6)
		Groupbox:Resize()

		Options[Idx] = Slider

		return Slider
	end

	function Funcs:AddDropdown(Idx, Info)
		if Info.SpecialType == "Player" then
			Info.Values = GetPlayersString()
			Info.AllowNull = true
		elseif Info.SpecialType == "Team" then
			Info.Values = GetTeamsString()
			Info.AllowNull = true
		end

		assert(Info.Values, "AddDropdown: Missing dropdown value list.")
		assert(
			Info.AllowNull or Info.Default,
			"AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional."
		)

		if not Info.Text then
			Info.Compact = true
		end

		local Dropdown = {
			Values = Info.Values,
			Value = Info.Multi and {},
			Multi = Info.Multi,
			Type = "Dropdown",
			SpecialType = Info.SpecialType,
			Callback = Info.Callback or function(Value) end,
		}

		local Groupbox = self
		local Container = Groupbox.Container

		local RelativeOffset = 0

		if not Info.Compact then
			local DropdownLabel = Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 10),
				TextSize = 14,
				Text = Info.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				ZIndex = 5,
				Parent = Container,
			})

			Groupbox:AddBlank(3)
		end

		for _, Element in next, Container:GetChildren() do
			if not Element:IsA("UIListLayout") then
				RelativeOffset = RelativeOffset + Element.Size.Y.Offset
			end
		end

		local DropdownOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(1, -4, 0, 20),
			ZIndex = 5,
			Parent = Container,
		})

		Library:AddToRegistry(DropdownOuter, {
			BorderColor3 = "Black",
		})

		local DropdownInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 6,
			Parent = DropdownOuter,
		})

		Library:AddToRegistry(DropdownInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		Library:Create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
			}),
			Rotation = 90,
			Parent = DropdownInner,
		})

		local DropdownArrow = Library:Create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.new(0, 12, 0, 12),
			Image = "http://www.roblox.com/asset/?id=6282522798",
			ZIndex = 8,
			Parent = DropdownInner,
		})

		local ItemList = Library:CreateLabel({
			Position = UDim2.new(0, 5, 0, 0),
			Size = UDim2.new(1, -5, 1, 0),
			TextSize = 14,
			Text = "--",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			ZIndex = 7,
			Parent = DropdownInner,
		})

		Library:OnHighlight(DropdownOuter, DropdownOuter, { BorderColor3 = "AccentColor" }, { BorderColor3 = "Black" })

		if type(Info.Tooltip) == "string" then
			Library:AddToolTip(Info.Tooltip, DropdownOuter)
		end

		local MAX_DROPDOWN_ITEMS = 8

		local ListOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			ZIndex = 20,
			Visible = false,
			Parent = ScreenGui,
		})

		local function RecalculateListPosition()
			ListOuter.Position = UDim2.fromOffset(
				DropdownOuter.AbsolutePosition.X,
				DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1
			)
		end

		local function RecalculateListSize(YSize)
			ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
		end

		RecalculateListPosition()
		RecalculateListSize()

		DropdownOuter:GetPropertyChangedSignal("AbsolutePosition"):Connect(RecalculateListPosition)

		local ListInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 21,
			Parent = ListOuter,
		})

		Library:AddToRegistry(ListInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		local Scrolling = Library:Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 21,
			Parent = ListInner,

			TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",

			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Library.AccentColor,
		})

		Library:AddToRegistry(Scrolling, {
			ScrollBarImageColor3 = "AccentColor",
		})

		Library:Create("UIListLayout", {
			Padding = UDim.new(0, 0),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = Scrolling,
		})

		function Dropdown:Display()
			local Values = Dropdown.Values
			local Str = ""

			if Info.Multi then
				for Idx, Value in next, Values do
					if Dropdown.Value[Value] then
						Str = Str .. Value .. ", "
					end
				end

				Str = Str:sub(1, #Str - 2)
			else
				Str = Dropdown.Value or ""
			end

			ItemList.Text = (Str == "" and "--" or Str)
		end

		function Dropdown:GetActiveValues()
			if Info.Multi then
				local T = {}

				for Value, Bool in next, Dropdown.Value do
					table.insert(T, Value)
				end

				return T
			else
				return Dropdown.Value and 1 or 0
			end
		end

		function Dropdown:BuildDropdownList()
			local Values = Dropdown.Values
			local Buttons = {}

			for _, Element in next, Scrolling:GetChildren() do
				if not Element:IsA("UIListLayout") then
					Element:Destroy()
				end
			end

			local Count = 0

			for Idx, Value in next, Values do
				local Table = {}

				Count = Count + 1

				local Button = Library:Create("Frame", {
					BackgroundColor3 = Library.MainColor,
					BorderColor3 = Library.OutlineColor,
					BorderMode = Enum.BorderMode.Middle,
					Size = UDim2.new(1, -1, 0, 20),
					ZIndex = 23,
					Active = true,
					Parent = Scrolling,
				})

				Library:AddToRegistry(Button, {
					BackgroundColor3 = "MainColor",
					BorderColor3 = "OutlineColor",
				})

				local ButtonLabel = Library:CreateLabel({
					Active = false,
					Size = UDim2.new(1, -6, 1, 0),
					Position = UDim2.new(0, 6, 0, 0),
					TextSize = 14,
					Text = Value,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 25,
					Parent = Button,
				})

				Library:OnHighlight(
					Button,
					Button,
					{ BorderColor3 = "AccentColor", ZIndex = 24 },
					{ BorderColor3 = "OutlineColor", ZIndex = 23 }
				)

				local Selected

				if Info.Multi then
					Selected = Dropdown.Value[Value]
				else
					Selected = Dropdown.Value == Value
				end

				function Table:UpdateButton()
					if Info.Multi then
						Selected = Dropdown.Value[Value]
					else
						Selected = Dropdown.Value == Value
					end

					ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor
					Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and "AccentColor" or "FontColor"
				end

				ButtonLabel.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						local Try = not Selected

						if Dropdown:GetActiveValues() == 1 and not Try and not Info.AllowNull then
						else
							if Info.Multi then
								Selected = Try

								if Selected then
									Dropdown.Value[Value] = true
								else
									Dropdown.Value[Value] = nil
								end
							else
								Selected = Try

								if Selected then
									Dropdown.Value = Value
								else
									Dropdown.Value = nil
								end

								for _, OtherButton in next, Buttons do
									OtherButton:UpdateButton()
								end
							end

							Table:UpdateButton()
							Dropdown:Display()

							Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
							Library:SafeCallback(Dropdown.Changed, Dropdown.Value)

							Library:AttemptSave()
						end
					end
				end)

				Table:UpdateButton()
				Dropdown:Display()

				Buttons[Button] = Table
			end

			Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1)

			local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1
			RecalculateListSize(Y)
		end

		function Dropdown:SetValues(NewValues)
			if NewValues then
				Dropdown.Values = NewValues
			end

			Dropdown:BuildDropdownList()
		end

		function Dropdown:OpenDropdown()
			ListOuter.Visible = true
			Library.OpenedFrames[ListOuter] = true
			DropdownArrow.Rotation = 180
		end

		function Dropdown:CloseDropdown()
			ListOuter.Visible = false
			Library.OpenedFrames[ListOuter] = nil
			DropdownArrow.Rotation = 0
		end

		function Dropdown:OnChanged(Func)
			Dropdown.Changed = Func
			Func(Dropdown.Value)
		end

		function Dropdown:SetValue(Val)
			if Dropdown.Multi then
				local nTable = {}

				for Value, Bool in next, Val do
					if table.find(Dropdown.Values, Value) then
						nTable[Value] = true
					end
				end

				Dropdown.Value = nTable
			else
				if not Val then
					Dropdown.Value = nil
				elseif table.find(Dropdown.Values, Val) then
					Dropdown.Value = Val
				end
			end

			Dropdown:BuildDropdownList()

			Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
			Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
		end

		DropdownOuter.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				if ListOuter.Visible then
					Dropdown:CloseDropdown()
				else
					Dropdown:OpenDropdown()
				end
			end
		end)

		InputService.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize

				if
					Mouse.X < AbsPos.X
					or Mouse.X > AbsPos.X + AbsSize.X
					or Mouse.Y < (AbsPos.Y - 20 - 1)
					or Mouse.Y > AbsPos.Y + AbsSize.Y
				then
					Dropdown:CloseDropdown()
				end
			end
		end)

		Dropdown:BuildDropdownList()
		Dropdown:Display()

		local Defaults = {}

		if type(Info.Default) == "string" then
			local Idx = table.find(Dropdown.Values, Info.Default)
			if Idx then
				table.insert(Defaults, Idx)
			end
		elseif type(Info.Default) == "table" then
			for _, Value in next, Info.Default do
				local Idx = table.find(Dropdown.Values, Value)
				if Idx then
					table.insert(Defaults, Idx)
				end
			end
		elseif type(Info.Default) == "number" and Dropdown.Values[Info.Default] ~= nil then
			table.insert(Defaults, Info.Default)
		end

		if next(Defaults) then
			for i = 1, #Defaults do
				local Index = Defaults[i]
				if Info.Multi then
					Dropdown.Value[Dropdown.Values[Index]] = true
				else
					Dropdown.Value = Dropdown.Values[Index]
				end

				if not Info.Multi then
					break
				end
			end

			Dropdown:BuildDropdownList()
			Dropdown:Display()
		end

		Groupbox:AddBlank(Info.BlankSize or 5)
		Groupbox:Resize()

		Options[Idx] = Dropdown

		return Dropdown
	end

	function Funcs:AddDependencyBox()
		local Depbox = {
			Dependencies = {},
		}

		local Groupbox = self
		local Container = Groupbox.Container

		local Holder = Library:Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = false,
			Parent = Container,
		})

		local Frame = Library:Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Visible = true,
			Parent = Holder,
		})

		local Layout = Library:Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = Frame,
		})

		function Depbox:Resize()
			Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
			Groupbox:Resize()
		end

		Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Depbox:Resize()
		end)

		Holder:GetPropertyChangedSignal("Visible"):Connect(function()
			Depbox:Resize()
		end)

		function Depbox:Update()
			for _, Dependency in next, Depbox.Dependencies do
				local Elem = Dependency[1]
				local Value = Dependency[2]

				if Elem.Type == "Toggle" and Elem.Value ~= Value then
					Holder.Visible = false
					Depbox:Resize()
					return
				end
			end

			Holder.Visible = true
			Depbox:Resize()
		end

		function Depbox:SetupDependencies(Dependencies)
			for _, Dependency in next, Dependencies do
				assert(type(Dependency) == "table", "SetupDependencies: Dependency is not of type `table`.")
				assert(Dependency[1], "SetupDependencies: Dependency is missing element argument.")
				assert(Dependency[2] ~= nil, "SetupDependencies: Dependency is missing value argument.")
			end

			Depbox.Dependencies = Dependencies
			Depbox:Update()
		end

		Depbox.Container = Frame

		setmetatable(Depbox, BaseGroupbox)

		table.insert(Library.DependencyBoxes, Depbox)

		return Depbox
	end

	BaseGroupbox.__index = Funcs
	BaseGroupbox.__namecall = function(Table, Key, ...)
		return Funcs[Key](...)
	end
end

do
	Library.NotificationArea = Library:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(0, 300, 0, 200),
		ZIndex = 100,
		Parent = ScreenGui,
	})

	Library:Create("UIListLayout", {
		Padding = UDim.new(0, 4),
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Library.NotificationArea,
	})

	local WatermarkOuter = Library:Create("Frame", {
		BorderColor3 = Color3.new(0, 0, 0),
		Position = UDim2.new(0, 100, 0, -25),
		Size = UDim2.new(0, 213, 0, 20),
		ZIndex = 200,
		Visible = false,
		Parent = ScreenGui,
	})

	local WatermarkInner = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.AccentColor,
		BorderMode = Enum.BorderMode.Inset,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 201,
		Parent = WatermarkOuter,
	})

	Library:AddToRegistry(WatermarkInner, {
		BorderColor3 = "AccentColor",
	})

	local InnerFrame = Library:Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 202,
		Parent = WatermarkInner,
	})

	local Gradient = Library:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
			ColorSequenceKeypoint.new(1, Library.MainColor),
		}),
		Rotation = -90,
		Parent = InnerFrame,
	})

	Library:AddToRegistry(Gradient, {
		Color = function()
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
				ColorSequenceKeypoint.new(1, Library.MainColor),
			})
		end,
	})

	local WatermarkLabel = Library:CreateLabel({
		Position = UDim2.new(0, 5, 0, 0),
		Size = UDim2.new(1, -4, 1, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 203,
		Parent = InnerFrame,
	})

	Library.Watermark = WatermarkOuter
	Library.WatermarkText = WatermarkLabel
	Library:MakeDraggable(Library.Watermark)

	local KeybindOuter = Library:Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BorderColor3 = Color3.new(0, 0, 0),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(0, 210, 0, 20),
		Visible = false,
		ZIndex = 100,
		Parent = ScreenGui,
	})

	local KeybindInner = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		BorderMode = Enum.BorderMode.Inset,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 101,
		Parent = KeybindOuter,
	})

	Library:AddToRegistry(KeybindInner, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "OutlineColor",
	}, true)

	local ColorFrame = Library:Create("Frame", {
		BackgroundColor3 = Library.AccentColor,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 2),
		ZIndex = 102,
		Parent = KeybindInner,
	})

	Library:AddToRegistry(ColorFrame, {
		BackgroundColor3 = "AccentColor",
	}, true)

	local KeybindLabel = Library:CreateLabel({
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(5, 2),
		TextXAlignment = Enum.TextXAlignment.Left,

		Text = "Keybinds",
		ZIndex = 104,
		Parent = KeybindInner,
	})

	local KeybindContainer = Library:Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -20),
		Position = UDim2.new(0, 0, 0, 20),
		ZIndex = 1,
		Parent = KeybindInner,
	})

	Library:Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = KeybindContainer,
	})

	Library:Create("UIPadding", {
		PaddingLeft = UDim.new(0, 5),
		Parent = KeybindContainer,
	})

	Library.KeybindFrame = KeybindOuter
	Library.KeybindContainer = KeybindContainer
	Library:MakeDraggable(KeybindOuter)
end

function Library:SetWatermarkVisibility(Bool)
	Library.Watermark.Visible = Bool
end

function Library:SetWatermark(Text)
	local X, Y = Library:GetTextBounds(Text, Library.Font, 14)
	Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3)
	Library:SetWatermarkVisibility(true)

	Library.WatermarkText.Text = Text
end

function Library:Notify(Text, Time)
	if getgenv().silentmode then
		return
	end

	local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14)

	YSize = YSize + 7

	local NotifyOuter = Library:Create("Frame", {
		BorderColor3 = Color3.new(0, 0, 0),
		Position = UDim2.new(0, 100, 0, 10),
		Size = UDim2.new(0, 0, 0, YSize),
		ClipsDescendants = true,
		ZIndex = 100,
		Parent = Library.NotificationArea,
	})

	local NotifyInner = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		BorderMode = Enum.BorderMode.Inset,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 101,
		Parent = NotifyOuter,
	})

	Library:AddToRegistry(NotifyInner, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "OutlineColor",
	}, true)

	local InnerFrame = Library:Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 102,
		Parent = NotifyInner,
	})

	local Gradient = Library:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
			ColorSequenceKeypoint.new(1, Library.MainColor),
		}),
		Rotation = -90,
		Parent = InnerFrame,
	})

	Library:AddToRegistry(Gradient, {
		Color = function()
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
				ColorSequenceKeypoint.new(1, Library.MainColor),
			})
		end,
	})

	local NotifyLabel = Library:CreateLabel({
		Position = UDim2.new(0, 4, 0, 0),
		Size = UDim2.new(1, -4, 1, 0),
		Text = Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 14,
		ZIndex = 103,
		Parent = InnerFrame,
	})

	local LeftColor = Library:Create("Frame", {
		BackgroundColor3 = Library.AccentColor,
		BorderSizePixel = 0,
		Position = UDim2.new(0, -1, 0, -1),
		Size = UDim2.new(0, 3, 1, 2),
		ZIndex = 104,
		Parent = NotifyOuter,
	})

	Library:AddToRegistry(LeftColor, {
		BackgroundColor3 = "AccentColor",
	}, true)

	pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), "Out", "Quad", 0.4, true)

    NotifyOuter.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            task.spawn(function()
                pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), "Out", "Quad", 0.4, true)

                task.wait(0.4)

                NotifyOuter:Destroy()
            end)
        end
    end)

	if Time then
		task.spawn(function()
			task.wait(Time or 5)

			pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), "Out", "Quad", 0.4, true)

			task.wait(0.4)

			NotifyOuter:Destroy()
		end)
	else
		return function()
			task.spawn(function()
				task.wait(Time or 5)

				pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), "Out", "Quad", 0.4, true)

				task.wait(0.4)

				NotifyOuter:Destroy()
			end)
		end
	end
end

function Library:CreateWindow(...)
	local Arguments = { ... }
	local Config = { AnchorPoint = Vector2.zero }

	if type(...) == "table" then
		Config = ...
	else
		Config.Title = Arguments[1]
		Config.AutoShow = Arguments[2] or false
	end

	if type(Config.Title) ~= "string" then
		Config.Title = "No title"
	end
	if type(Config.TabPadding) ~= "number" then
		Config.TabPadding = 0
	end
	if type(Config.MenuFadeTime) ~= "number" then
		Config.MenuFadeTime = 0
	end

	if typeof(Config.Position) ~= "UDim2" then
		Config.Position = UDim2.fromOffset(175, 50)
	end
	if typeof(Config.Size) ~= "UDim2" then
		Config.Size = UDim2.fromOffset(550, 600)
	end

	if Config.Center then
		Config.AnchorPoint = Vector2.new(0.5, 0.5)
		Config.Position = UDim2.fromScale(0.5, 0.5)
	end

	local Window = {
		Tabs = {},
	}

	local Outer = Library:Create("Frame", {
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Position = Config.Position,
		Size = Config.Size,
		Visible = false,
		ZIndex = 1,
		Parent = ScreenGui,
	})

	Library:MakeDraggable(Outer, 25)

	local Inner = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.AccentColor,
		BorderMode = Enum.BorderMode.Inset,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 1,
		Parent = Outer,
	})

	Library:AddToRegistry(Inner, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "AccentColor",
	})

	local WindowLabel = Library:CreateLabel({
		Position = UDim2.new(0, 7, 0, 0),
		Size = UDim2.new(0, 0, 0, 25),
		Text = Config.Title or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 1,
		Parent = Inner,
	})

	local MainSectionOuter = Library:Create("Frame", {
		BackgroundColor3 = Library.BackgroundColor,
		BorderColor3 = Library.OutlineColor,
		Position = UDim2.new(0, 8, 0, 25),
		Size = UDim2.new(1, -16, 1, -33),
		ZIndex = 1,
		Parent = Inner,
	})

	Library:AddToRegistry(MainSectionOuter, {
		BackgroundColor3 = "BackgroundColor",
		BorderColor3 = "OutlineColor",
	})

	local MainSectionInner = Library:Create("Frame", {
		BackgroundColor3 = Library.BackgroundColor,
		BorderColor3 = Color3.new(0, 0, 0),
		BorderMode = Enum.BorderMode.Inset,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1,
		Parent = MainSectionOuter,
	})

	Library:AddToRegistry(MainSectionInner, {
		BackgroundColor3 = "BackgroundColor",
	})

	local TabArea = Library:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(1, -16, 0, 21),
		ZIndex = 1,
		Parent = MainSectionInner,
	})

	local TabListLayout = Library:Create("UIListLayout", {
		Padding = UDim.new(0, Config.TabPadding),
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = TabArea,
	})

	local TabContainer = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		Position = UDim2.new(0, 8, 0, 30),
		Size = UDim2.new(1, -16, 1, -38),
		ZIndex = 2,
		Parent = MainSectionInner,
	})

	Library:AddToRegistry(TabContainer, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "OutlineColor",
	})

	function Window:SetWindowTitle(Title)
		WindowLabel.Text = Title
	end

	function Window:AddTab(Name)
		local Tab = {
			Groupboxes = {},
			Tabboxes = {},
		}

		local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16)

		local TabButton = Library:Create("Frame", {
			BackgroundColor3 = Library.BackgroundColor,
			BorderColor3 = Library.OutlineColor,
			Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0),
			ZIndex = 1,
			Parent = TabArea,
		})

		Library:AddToRegistry(TabButton, {
			BackgroundColor3 = "BackgroundColor",
			BorderColor3 = "OutlineColor",
		})

		local TabButtonLabel = Library:CreateLabel({
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, -1),
			Text = Name,
			ZIndex = 1,
			Parent = TabButton,
		})

		local Blocker = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = TabButton,
		})

		Library:AddToRegistry(Blocker, {
			BackgroundColor3 = "MainColor",
		})

		local TabFrame = Library:Create("Frame", {
			Name = "TabFrame",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			Visible = false,
			ZIndex = 2,
			Parent = TabContainer,
		})

		local LeftSide = Library:Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 8 - 1, 0, 8 - 1),
			Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			BottomImage = "",
			TopImage = "",
			ScrollBarThickness = 0,
			ZIndex = 2,
			Parent = TabFrame,
		})

		local RightSide = Library:Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1),
			Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			BottomImage = "",
			TopImage = "",
			ScrollBarThickness = 0,
			ZIndex = 2,
			Parent = TabFrame,
		})

		Library:Create("UIListLayout", {
			Padding = UDim.new(0, 8),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = LeftSide,
		})

		Library:Create("UIListLayout", {
			Padding = UDim.new(0, 8),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = RightSide,
		})

		for _, Side in next, { LeftSide, RightSide } do
			Side:WaitForChild("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y)
			end)
		end

		function Tab:ShowTab()
			for _, Tab in next, Window.Tabs do
				Tab:HideTab()
			end

			Blocker.BackgroundTransparency = 0
			TabButton.BackgroundColor3 = Library.MainColor
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = "MainColor"
			TabFrame.Visible = true
		end

		function Tab:HideTab()
			Blocker.BackgroundTransparency = 1
			TabButton.BackgroundColor3 = Library.BackgroundColor
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = "BackgroundColor"
			TabFrame.Visible = false
		end

		function Tab:SetLayoutOrder(Position)
			TabButton.LayoutOrder = Position
			TabListLayout:ApplyLayout()
		end

		function Tab:AddGroupbox(Info)
			local Groupbox = {}

			local BoxOuter = Library:Create("Frame", {
				BackgroundColor3 = Library.BackgroundColor,
				BorderColor3 = Library.OutlineColor,
				BorderMode = Enum.BorderMode.Inset,
				Size = UDim2.new(1, 0, 0, 507 + 2),
				ZIndex = 2,
				Parent = Info.Side == 1 and LeftSide or RightSide,
			})

			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = "BackgroundColor",
				BorderColor3 = "OutlineColor",
			})

			local BoxInner = Library:Create("Frame", {
				BackgroundColor3 = Library.BackgroundColor,
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				ZIndex = 4,
				Parent = BoxOuter,
			})

			Library:AddToRegistry(BoxInner, {
				BackgroundColor3 = "BackgroundColor",
			})

			local Highlight = Library:Create("Frame", {
				BackgroundColor3 = Library.AccentColor,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 2),
				ZIndex = 5,
				Parent = BoxInner,
			})

			Library:AddToRegistry(Highlight, {
				BackgroundColor3 = "AccentColor",
			})

			local GroupboxLabel = Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 18),
				Position = UDim2.new(0, 4, 0, 2),
				TextSize = 14,
				Text = Info.Name,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 5,
				Parent = BoxInner,
			})

			local Container = Library:Create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 4, 0, 20),
				Size = UDim2.new(1, -4, 1, -20),
				ZIndex = 1,
				Parent = BoxInner,
			})

			Library:Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = Container,
			})

			function Groupbox:Resize()
				local Size = 0

				for _, Element in next, Groupbox.Container:GetChildren() do
					if (not Element:IsA("UIListLayout")) and Element.Visible then
						Size = Size + Element.Size.Y.Offset
					end
				end

				BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
			end

			Groupbox.Container = Container
			setmetatable(Groupbox, BaseGroupbox)

			Groupbox:AddBlank(3)
			Groupbox:Resize()

			Tab.Groupboxes[Info.Name] = Groupbox

			return Groupbox
		end

		function Tab:AddLeftGroupbox(Name)
			return Tab:AddGroupbox({ Side = 1, Name = Name })
		end

		function Tab:AddRightGroupbox(Name)
			return Tab:AddGroupbox({ Side = 2, Name = Name })
		end

		function Tab:AddTabbox(Info)
			local Tabbox = {
				Tabs = {},
			}

			local BoxOuter = Library:Create("Frame", {
				BackgroundColor3 = Library.BackgroundColor,
				BorderColor3 = Library.OutlineColor,
				BorderMode = Enum.BorderMode.Inset,
				Size = UDim2.new(1, 0, 0, 0),
				ZIndex = 2,
				Parent = Info.Side == 1 and LeftSide or RightSide,
			})

			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = "BackgroundColor",
				BorderColor3 = "OutlineColor",
			})

			local BoxInner = Library:Create("Frame", {
				BackgroundColor3 = Library.BackgroundColor,
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				ZIndex = 4,
				Parent = BoxOuter,
			})

			Library:AddToRegistry(BoxInner, {
				BackgroundColor3 = "BackgroundColor",
			})

			local Highlight = Library:Create("Frame", {
				BackgroundColor3 = Library.AccentColor,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 2),
				ZIndex = 10,
				Parent = BoxInner,
			})

			Library:AddToRegistry(Highlight, {
				BackgroundColor3 = "AccentColor",
			})

			local TabboxButtons = Library:Create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 1),
				Size = UDim2.new(1, 0, 0, 18),
				ZIndex = 5,
				Parent = BoxInner,
			})

			Library:Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = TabboxButtons,
			})

			function Tabbox:AddTab(Name)
				local Tab = {}

				local Button = Library:Create("Frame", {
					BackgroundColor3 = Library.MainColor,
					BorderColor3 = Color3.new(0, 0, 0),
					Size = UDim2.new(0.5, 0, 1, 0),
					ZIndex = 6,
					Parent = TabboxButtons,
				})

				Library:AddToRegistry(Button, {
					BackgroundColor3 = "MainColor",
				})

				local ButtonLabel = Library:CreateLabel({
					Size = UDim2.new(1, 0, 1, 0),
					TextSize = 14,
					Text = Name,
					TextXAlignment = Enum.TextXAlignment.Center,
					ZIndex = 7,
					Parent = Button,
				})

				local Block = Library:Create("Frame", {
					BackgroundColor3 = Library.BackgroundColor,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 1, 0),
					Size = UDim2.new(1, 0, 0, 1),
					Visible = false,
					ZIndex = 9,
					Parent = Button,
				})

				Library:AddToRegistry(Block, {
					BackgroundColor3 = "BackgroundColor",
				})

				local Container = Library:Create("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 4, 0, 20),
					Size = UDim2.new(1, -4, 1, -20),
					ZIndex = 1,
					Visible = false,
					Parent = BoxInner,
				})

				Library:Create("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = Container,
				})

				function Tab:Show()
					for _, Tab in next, Tabbox.Tabs do
						Tab:Hide()
					end

					Container.Visible = true
					Block.Visible = true

					Button.BackgroundColor3 = Library.BackgroundColor
					Library.RegistryMap[Button].Properties.BackgroundColor3 = "BackgroundColor"

					Tab:Resize()
				end

				function Tab:Hide()
					Container.Visible = false
					Block.Visible = false

					Button.BackgroundColor3 = Library.MainColor
					Library.RegistryMap[Button].Properties.BackgroundColor3 = "MainColor"
				end

				function Tab:Resize()
					local TabCount = 0

					for _, Tab in next, Tabbox.Tabs do
						TabCount = TabCount + 1
					end

					for _, Button in next, TabboxButtons:GetChildren() do
						if not Button:IsA("UIListLayout") then
							Button.Size = UDim2.new(1 / TabCount, 0, 1, 0)
						end
					end

					if not Container.Visible then
						return
					end

					local Size = 0

					for _, Element in next, Tab.Container:GetChildren() do
						if (not Element:IsA("UIListLayout")) and Element.Visible then
							Size = Size + Element.Size.Y.Offset
						end
					end

					BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
				end

				Button.InputBegan:Connect(function(Input)
					if
						Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()
					then
						Tab:Show()
						Tab:Resize()
					end
				end)

				Tab.Container = Container
				Tabbox.Tabs[Name] = Tab

				setmetatable(Tab, BaseGroupbox)

				Tab:AddBlank(3)
				Tab:Resize()

				if #TabboxButtons:GetChildren() == 2 then
					Tab:Show()
				end

				return Tab
			end

			Tab.Tabboxes[Info.Name or ""] = Tabbox

			return Tabbox
		end

		function Tab:AddLeftTabbox(Name)
			return Tab:AddTabbox({ Name = Name, Side = 1 })
		end

		function Tab:AddRightTabbox(Name)
			return Tab:AddTabbox({ Name = Name, Side = 2 })
		end

		TabButton.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Tab:ShowTab()
			end
		end)

		if #TabContainer:GetChildren() == 1 then
			Tab:ShowTab()
		end

		Window.Tabs[Name] = Tab
		return Tab
	end

	local ModalElement = Library:Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 0),
		Visible = true,
		Text = "",
		Modal = false,
		Parent = ScreenGui,
	})

	local TransparencyCache = {}
	local Toggled = false
	local Fading = false

	function Library:Toggle()
		if Fading then
			return
		end

		local FadeTime = Config.MenuFadeTime
		Fading = true
		Toggled = not Toggled
		ModalElement.Modal = Toggled

		if Toggled then
			Outer.Visible = true
		end

		for _, Desc in next, Outer:GetDescendants() do
			local Properties = {}

			if Desc:IsA("ImageLabel") then
				table.insert(Properties, "ImageTransparency")
				table.insert(Properties, "BackgroundTransparency")
			elseif Desc:IsA("TextLabel") or Desc:IsA("TextBox") then
				table.insert(Properties, "TextTransparency")
			elseif Desc:IsA("Frame") or Desc:IsA("ScrollingFrame") then
				table.insert(Properties, "BackgroundTransparency")
			elseif Desc:IsA("UIStroke") then
				table.insert(Properties, "Transparency")
			end

			local Cache = TransparencyCache[Desc]

			if not Cache then
				Cache = {}
				TransparencyCache[Desc] = Cache
			end

			for _, Prop in next, Properties do
				if not Cache[Prop] then
					Cache[Prop] = Desc[Prop]
				end

				if Cache[Prop] == 1 then
					continue
				end

				Desc[Prop] = Toggled and Cache[Prop] or 1
			end
		end

		task.wait(FadeTime)

		Outer.Visible = Toggled

		Fading = false
	end

	Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
		if type(Library.ToggleKeybind) == "table" and Library.ToggleKeybind.Type == "KeyPicker" then
			if
				Input.UserInputType == Enum.UserInputType.Keyboard
				and Input.KeyCode.Name == Library.ToggleKeybind.Value
			then
				task.spawn(Library.Toggle)
			end
		elseif
			Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and not Processed)
		then
			task.spawn(Library.Toggle)
		end
	end))

	if Config.AutoShow then
		task.spawn(Library.Toggle)
	end

	Window.Holder = Outer

	return Window
end

local function OnPlayerChange()
	local PlayerList = GetPlayersString()

	for _, Value in next, Options do
		if Value.Type == "Dropdown" and Value.SpecialType == "Player" then
			Value:SetValues(PlayerList)
		end
	end
end

Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

getgenv().Library = Library

return Library

end)
__bundle_register("Modules/Deepwoken/V2Configs", function(require, _LOADED, __bundle_register, __bundle_modules)
return game:GetService("HttpService"):JSONDecode([[{"rbxassetid://8229000378":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"CroccoLeap","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://5865945103":{"RepeatParryDelay":0,"Range":100,"Wait":235,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Name":"ArcCast","Delay":false,"Custom":true},"rbxassetid://8378263543":{"RepeatParryDelay":0,"CustomConfig":true,"Range":40,"Wait":350,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":8.2,"X":14.7,"ZSet":10,"Z":12.5,"YSet":0.8},"RepeatParryAmount":0,"Name":"FireEruption","Delay":false,"selfid":"rbxassetid://8378263543"},"rbxassetid://7391446645":{"RepeatParryDelay":0,"Range":25,"Wait":450,"DelayDistance":0,"Hold":false,"Name":"FistKick","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://8169914770":{"RepeatParryDelay":0,"Range":20,"Wait":200,"DelayDistance":0,"Hold":false,"Name":"LegionCrit","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://7005236296":{"Roll":false,"DelayDistance":0,"Hold":false,"Range":50,"Name":"DivineDaggers","Custom":true,"Delay":false,"Wait":330},"rbxassetid://7639648215":{"RepeatParryDelay":0,"Range":50,"Wait":250,"DelayDistance":0,"Hold":false,"Name":"OwlSwipe1","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://9357410713":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":60,"Wait":1500,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"sharko_laser","Delay":false,"selfid":"9357410713"},"rbxassetid://15420044707":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":25,"Wait":300,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"KaritaLeap_Windup","Delay":false,"selfid":"15420044707"},"rbxassetid://9481400792":{"RepeatParryDelay":0,"Range":35,"Wait":150,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"ArcwarderBeam","Delay":false,"Roll":false},"rbxassetid://6669352471":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":50,"Wait":350,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":8.2,"X":9.5,"ZSet":3.4,"Z":7.8,"YSet":0},"RepeatParryAmount":0,"selfid":"6669352471","Delay":false,"Name":"RunningAttackSword1"},"rbxassetid://8213425641":{"RepeatParryDelay":0,"Range":40,"Wait":560,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":true,"Delay":false,"Name":"MechGround"},"rbxassetid://6470684331":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":70,"Wait":350,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":6.9,"X":11.6,"ZSet":0,"Z":11.6,"YSet":0},"RepeatParryAmount":0,"Name":"AstralWindFirst","Delay":false,"selfid":"6470684331"},"rbxassetid://9921853885":{"RepeatParryDelay":0,"Range":30,"Wait":600,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"ThresherKingSlam","Delay":false,"Roll":true},"rbxassetid://11493923277":{"RepeatParryDelay":0,"Range":20,"Wait":200,"DelayDistance":0,"Hold":false,"Name":"Skyreap2","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://6428525211":{"RepeatParryDelay":0,"Range":100,"Wait":160,"DelayDistance":0,"Hold":false,"Name":"WidowDouble","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://7542502881":{"RepeatParryDelay":0,"Range":25,"Wait":300,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"FlameLeap","Delay":false,"Roll":false},"rbxassetid://7830946229":{"RepeatParryDelay":0,"Range":30,"Wait":300,"DelayDistance":0,"Hold":false,"Name":"ShotelCrit","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://11862841821":{"RepeatParryDelay":0,"Range":20,"Wait":250,"DelayDistance":0,"Hold":false,"Name":"ContractorEqualizer","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://11959603858":{"RepeatParryDelay":0,"Range":20,"Wait":800,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"EclipseKick","Delay":false,"Roll":false},"rbxassetid://7861127585":{"RepeatParryDelay":0,"CustomConfig":true,"Range":60,"Wait":360,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"ThunderKick","Delay":false,"selfid":"rbxassetid://7861127585"},"rbxassetid://6922103707":{"RepeatParryDelay":0,"Range":25,"Wait":40,"DelayDistance":0,"Hold":false,"Name":"SquibboKick","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://9544206893":{"RepeatParryDelay":0,"Range":50,"Wait":850,"DelayDistance":0,"Hold":false,"Roll":true,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Name":"BounderLeap"},"rbxassetid://9928429385":{"RepeatParryDelay":0,"Range":18,"Wait":230,"DelayDistance":0,"Hold":false,"Name":"RifleSwing1","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7693947084":{"Roll":false,"DelayDistance":0,"Hold":false,"Range":20,"Name":"ChokeWindup","Custom":true,"Delay":false,"Wait":200},"rbxassetid://8226933122":{"RepeatParryDelay":320,"CustomConfig":true,"Range":40,"Wait":230,"DelayDistance":0,"Roll":false,"RepeatParryAmount":2,"selfid":"rbxassetid://8226933122","Delay":false,"Name":"CroccoBite"},"rbxassetid://9225086332":{"RepeatParryDelay":0,"Range":100,"Wait":680,"DelayDistance":0,"Hold":false,"Name":"PrimaGrab","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://6675698010":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":300,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.2,"X":11.2,"ZSet":4.1,"Z":9.9,"YSet":0},"RepeatParryAmount":0,"Name":"2handedheavyswing1","Delay":false,"selfid":"6675698010"},"rbxassetid://5656817007":{"RepeatParryDelay":0,"Range":50,"Wait":500,"DelayDistance":0,"Hold":false,"Name":"EraserBlow","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://13799693320":{"RepeatParryDelay":0,"CustomConfig":true,"Range":32,"Wait":100,"DelayDistance":0,"Roll":false,"RepeatParryAmount":1,"Autoload":false,"Delay":false,"Name":"squidslash3_v2"},"rbxassetid://8205670183":{"Custom":true,"DelayDistance":0,"Roll":false,"Delay":false,"Name":"braindive","Hold":false,"Range":60,"Wait":1500},"rbxassetid://6385277192":{"RepeatParryDelay":0,"Range":40,"Wait":530,"DelayDistance":0,"Hold":false,"Name":"ClutchingShadow2","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://8075129603":{"RepeatParryDelay":0,"Range":50,"Wait":300,"DelayDistance":0,"Hold":false,"Name":"IllusoryRealm","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://7666455222":{"RepeatParryDelay":0,"Range":50,"Wait":200,"DelayDistance":0,"Roll":false,"Custom":true,"RepeatParryAmount":0,"Hold":false,"Delay":false,"Name":"WindBladeSlash"},"rbxassetid://4880833465":{"RepeatParryDelay":0,"Range":20,"Wait":215,"DelayDistance":0,"Hold":false,"Name":"MaceTwoHand3","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://9629695751":{"RepeatParryDelay":0,"Range":30,"Wait":300,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"ChampionThrow","Delay":false,"Roll":false},"rbxassetid://9470822568":{"RepeatParryDelay":0,"Range":25,"Wait":600,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"ShadeBringerSlash"},"rbxassetid://9544192782":{"RepeatParryDelay":0,"Range":30,"Wait":300,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"BounderSwing2","Delay":false,"Roll":false},"rbxassetid://6432920452":{"RepeatParryDelay":0,"Range":20,"Wait":215,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"GunShotSide"},"rbxassetid://5865907089":{"RepeatParryDelay":0,"Range":20,"Wait":450,"DelayDistance":0,"Hold":false,"Name":"ShadowArcWindup","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://9710538334":{"RepeatParryDelay":0,"Range":35,"Wait":650,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"BoneKeeperGrab","Delay":false,"Roll":true},"rbxassetid://7565307809":{"RepeatParryDelay":0,"Range":20,"Wait":150,"DelayDistance":0,"Hold":false,"Name":"RifleAerialShot","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://8375086403":{"RepeatParryDelay":0,"Range":40,"Wait":240,"DelayDistance":0,"Hold":false,"Name":"MastersFlourish","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://10768714710":{"RepeatParryDelay":0,"Range":30,"Wait":0,"Roll":false,"DelayDistance":0,"Name":"EnforcerCritSpin","RepeatParry":false,"RepeatParryAmount":0,"Hold":true,"Delay":false,"Custom":true},"rbxassetid://11572468462":{"RepeatParryDelay":0,"CustomConfig":true,"Range":12,"Wait":100,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.5,"X":8.2,"ZSet":3.3,"Z":6.9,"YSet":0},"RepeatParryAmount":0,"Name":"ms_slash1","Delay":false,"selfid":"rbxassetid://11572468462"},"rbxassetid://5953326460":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":35,"Wait":330,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":10.3,"X":14.7,"ZSet":0.7,"Z":14.2,"YSet":0},"RepeatParryAmount":0,"selfid":"5953326460","Delay":false,"Name":"FireSpinChargeUp"},"rbxassetid://11186656574":{"RepeatParryDelay":0,"Range":20,"Wait":190,"DelayDistance":0,"Hold":false,"Name":"LightToll3","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://6916546485":{"RepeatParryDelay":0,"Range":25,"Wait":40,"DelayDistance":0,"Hold":false,"Name":"SquibboPunch2","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://9681472252":{"RepeatParryDelay":0,"Range":30,"Wait":600,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"BoneKeeperSweep2","Delay":false,"Roll":true},"rbxassetid://9209255758":{"RepeatParryDelay":0,"Range":30,"Wait":160,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"WhalingCrit","Delay":false,"Roll":false},"rbxassetid://8228887027":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"CroccoStun","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://5121896072":{"RepeatParryDelay":0,"Range":35,"Wait":250,"DelayDistance":0,"Hold":false,"Name":"SharkoPunt","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://7162928509":{"Name":"LightningImpact","DelayDistance":0,"Roll":false,"Delay":false,"Custom":true,"Hold":false,"Range":100,"Wait":300},"rbxassetid://6054920207":{"RepeatParryDelay":100,"Range":30,"Wait":200,"Name":"CrystalImpale","DelayDistance":0,"Hold":false,"RepeatParry":false,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://6428514850":{"RepeatParryDelay":0,"CustomConfig":true,"Range":100,"Wait":580,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"WidowRightSwing","Delay":false,"selfid":"rbxassetid://6428514850"},"rbxassetid://10695391139":{"RepeatParryDelay":0,"Range":40,"Wait":1400,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"BrachialSpear"},"rbxassetid://8130778356":{"RepeatParryDelay":0,"Range":40,"Wait":260,"DelayDistance":0,"Hold":false,"Name":"SKnightSwing2","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://8265980703":{"RepeatParryDelay":0,"Range":40,"Wait":300,"DelayDistance":0,"Hold":true,"Name":"IceLance","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://10451138202":{"RepeatParryDelay":0,"Range":30,"Wait":265,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"IcebruteSwipe1","Delay":false,"Roll":true},"rbxassetid://12333753799":{"RepeatParryDelay":0,"Range":25,"Wait":230,"DelayDistance":0,"Custom":true,"Roll":false,"RepeatParryAmount":0,"Name":"RisingThunder","Delay":false,"Hold":false},"rbxassetid://11468287607":{"RepeatParryDelay":0,"Range":25,"Wait":250,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"HeroShadowCrit"},"rbxassetid://9544205634":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"BounderRun","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://17134046321":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":250,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":11.6,"X":11.2,"ZSet":1.9,"Z":9.1,"YSet":0},"RepeatParryAmount":0,"Name":"imsleepy","Delay":true,"selfid":"17134046321"},"rbxassetid://7673135333":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"OwlLoopDel","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://14954028005":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":350,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"CTNew","Delay":false,"selfid":"14954028005"},"rbxassetid://7627372304":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":240,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.1,"X":7.8,"ZSet":2.6,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"selfid":"7627372304","Delay":false,"Name":"spear2handed1"},"rbxassetid://8294560344":{"RepeatParryDelay":500,"Range":100,"Wait":1850,"Roll":false,"DelayDistance":0,"Hold":false,"RepeatParry":true,"RepeatParryAmount":2,"Name":"Duke bomb","Delay":false,"Custom":true},"rbxassetid://8249271040":{"RepeatParryDelay":0,"Range":20,"Wait":300,"DelayDistance":0,"Hold":false,"Name":"RapierCrit","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://16707867563":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":25,"Wait":500,"DelayDistance":19,"Roll":false,"Hitbox":{"Y":5.6,"X":8.2,"ZSet":7.6,"Z":19.4,"YSet":0},"RepeatParryAmount":0,"Name":"Imperial_Extend","Delay":false,"selfid":"16707867563"},"rbxassetid://7620630583":{"Custom":true,"Name":"2 shadow","Hold":true,"Roll":false,"Range":50,"Wait":-5},"rbxassetid://13799655062":{"RepeatParryDelay":0,"CustomConfig":true,"Range":32,"Wait":100,"DelayDistance":0,"Roll":false,"RepeatParryAmount":1,"Autoload":false,"Delay":false,"Name":"squidslash2_v2"},"rbxassetid://8199600822":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":35,"Wait":350,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":10.3,"X":13.4,"ZSet":8.1,"Z":11.6,"YSet":0},"RepeatParryAmount":0,"selfid":"8199600822","Delay":false,"Name":"AshSlam"},"rbxassetid://7961600084":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"CrabboFallDel","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7599175716":{"RepeatParryDelay":0,"Range":30,"Wait":580,"DelayDistance":0,"Hold":false,"Name":"StormcallerSlash","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://9422296675":{"RepeatParryDelay":0,"Range":20,"Wait":700,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"CarbuncleLeap"},"rbxassetid://16654113357":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":10,"Wait":300,"DelayDistance":19,"Roll":false,"Hitbox":{"Y":5.6,"X":8.2,"ZSet":2.8,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"Name":"ImperialStaff3","Delay":false,"selfid":"16654113357"},"rbxassetid://5641574212":{"RepeatParryDelay":0,"Range":100,"Wait":250,"DelayDistance":0,"Hold":false,"Roll":true,"RepeatParryAmount":0,"Name":"SharkoScream","Delay":false,"Custom":true},"rbxassetid://5680585677":{"RepeatParryDelay":650,"Range":49,"Wait":250,"Roll":false,"DelayDistance":0,"Hold":false,"RepeatParry":true,"RepeatParryAmount":2,"Name":"LionfishBite","Delay":false,"Custom":true},"rbxassetid://11834545925":{"RepeatParryDelay":0,"Range":30,"Wait":250,"DelayDistance":0,"Hold":false,"Name":"MechLifeSuck","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://6055548639":{"RepeatParryDelay":0,"Range":70,"Wait":130,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"IceLasers"},"rbxassetid://9212883524":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":50,"Wait":520,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.6,"X":13.4,"ZSet":3.8,"Z":9.1,"YSet":0},"RepeatParryAmount":0,"selfid":"9212883524","Delay":false,"Name":"halberd"},"rbxassetid://7894367259":{"RepeatParryDelay":0,"Range":40,"Wait":300,"DelayDistance":0,"Hold":false,"Name":"GremorCrit","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://10437902558":{"RepeatParryDelay":0,"Range":50,"Wait":825,"DelayDistance":0,"Hold":false,"Name":"IceguyFlipThrow","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://5053295423":{"RepeatParryDelay":0,"Range":20,"Wait":0,"DelayDistance":0,"Hold":true,"Name":"DarkBladeSpin","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://9767020777":{"RepeatParryDelay":150,"Range":60,"Wait":400,"DelayDistance":0,"Hold":false,"Name":"Flashstrike","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://8085349676":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":450,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":10.3,"X":8.2,"ZSet":1.9,"Z":5.6,"YSet":0},"RepeatParryAmount":0,"selfid":"8085349676","Delay":false,"Name":"strongpunch"},"rbxassetid://8278926990":{"RepeatParryDelay":0,"Range":20,"Wait":165,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Name":"Karita1"},"rbxassetid://7861135817":{"RepeatParryDelay":0,"Range":20,"Wait":300,"DelayDistance":0,"Hold":false,"Name":"Lightning Kick","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://7599400319":{"RepeatParryDelay":0,"Range":30,"Wait":300,"DelayDistance":0,"Hold":true,"Name":"IceSmash2nd","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://8204924934":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":300,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":8.2,"X":9.9,"ZSet":3.3,"Z":9.9,"YSet":0},"RepeatParryAmount":0,"Name":"Brainsucker_Kick","Delay":false,"selfid":"8204924934"},"rbxassetid://7675544287":{"RepeatParryDelay":0,"Range":100,"Wait":150,"DelayDistance":0,"Hold":false,"Name":"OwlGrab","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://15331452847":{"RepeatParryDelay":350,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":25,"Wait":650,"DelayDistance":0,"Roll":false,"RepeatParryAmount":2,"Name":"ElectroSmash","Delay":false,"selfid":"15331452847"},"rbxassetid://5968288116":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":70,"Wait":450,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":10.3,"X":13.4,"ZSet":10,"Z":28.9,"YSet":2.2},"RepeatParryAmount":0,"Name":"WindPassage","Delay":false,"selfid":"5968288116"},"rbxassetid://8227583745":{"RepeatParryDelay":500,"Range":40,"Wait":230,"Custom":true,"DelayDistance":0,"Hold":false,"Delay":false,"RepeatParryAmount":1,"Name":"CroccoSwipe","RepeatParry":true,"Roll":false},"rbxassetid://9360837202":{"RepeatParryDelay":0,"Range":30,"Wait":380,"DelayDistance":0,"Hold":false,"Name":"ShadeBringer","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://7543723607":{"RepeatParryDelay":0,"Range":40,"Wait":650,"DelayDistance":0,"Hold":false,"Name":"IceSpike","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://0":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":500,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":8.6,"X":15.5,"ZSet":10,"Z":23.7,"YSet":0},"RepeatParryAmount":0,"Name":"MetalEruption","Delay":false,"selfid":"0"},"rbxassetid://16021787986":{"RepeatParryDelay":0,"Range":30,"Wait":150,"Name":"Shattered Katana Crit","DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"IgnoreCustom":true},"rbxassetid://6922310516":{"RepeatParryDelay":0,"Range":50,"Wait":150,"DelayDistance":0,"Hold":false,"Name":"SquibboEruption","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://6505077797":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"GolemScreamDel","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://8095864854":{"RepeatParryDelay":0,"Range":25,"Wait":550,"DelayDistance":0,"Hold":false,"Name":"SerpentCrit","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://10258479464":{"RepeatParryDelay":0,"Range":30,"Wait":700,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"dsgs_crit","Delay":false,"Roll":false},"rbxassetid://9930447958":{"RepeatParryDelay":0,"Range":18,"Wait":230,"DelayDistance":0,"Hold":false,"Name":"RifleSwing3","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7616407967":{"RepeatParryDelay":0,"Range":20,"Wait":160,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"Way1"},"rbxassetid://9681905891":{"RepeatParryDelay":0,"Range":30,"Wait":700,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"BoneKeeperRush\r","Delay":false,"Roll":false},"rbxassetid://6415085564":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":250,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"ShadowGunshot","Delay":false,"selfid":"6415085564"},"rbxassetid://7004327185":{"Roll":false,"DelayDistance":0,"Hold":false,"Range":40,"Name":"DivineSword\r","Custom":true,"Delay":false,"Wait":130},"rbxassetid://7576748728":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":300,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.9,"X":8.6,"ZSet":1.6,"Z":10.3,"YSet":0},"RepeatParryAmount":0,"Name":"AerialStab(SWORD)","Delay":false,"selfid":"7576748728"},"rbxassetid://9234812388":{"RepeatParryDelay":0,"Range":30,"Wait":800,"Roll":false,"DelayDistance":0,"Hold":true,"RepeatParry":false,"RepeatParryAmount":0,"Name":"Iceberg","Delay":false,"Custom":true},"rbxassetid://7600160919":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":200,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.2,"X":9.1,"ZSet":3,"Z":9.5,"YSet":0},"RepeatParryAmount":0,"Name":"Swing1","Delay":false,"selfid":"7600160919"},"rbxassetid://17116105751":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":400,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":11.6,"X":8.6,"ZSet":1.9,"Z":13.8,"YSet":0},"RepeatParryAmount":0,"Name":"RunningCritStartup","Delay":false,"selfid":"17116105751"},"rbxassetid://12564120372":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":350,"DelayDistance":19,"Roll":false,"Hitbox":{"Y":4.7,"X":13.4,"ZSet":0,"Z":14.2,"YSet":-0.7},"RepeatParryAmount":0,"Name":"GroundSlideAttack","Delay":true,"selfid":"12564120372"},"rbxassetid://8285321158":{"RepeatParryDelay":500,"Range":100,"Wait":850,"Roll":false,"DelayDistance":0,"Hold":false,"RepeatParry":false,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Name":"Duke grasp"},"rbxassetid://7961615809":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"CrabboLandDel","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7618754583":{"RepeatParryDelay":0,"CustomConfig":true,"Range":65,"Wait":420,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":13.8,"X":15.1,"ZSet":10,"Z":17.2,"YSet":0.8},"RepeatParryAmount":0,"Name":"FirePalm","Delay":false,"selfid":"rbxassetid://7618754583"},"rbxassetid://8295145565":{"RepeatParryDelay":0,"Range":30,"Wait":360,"DelayDistance":0,"Hold":false,"Name":"KaritaCrit","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://17115889868":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":150,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":11.6,"X":11.2,"ZSet":1.9,"Z":9.1,"YSet":0},"RepeatParryAmount":0,"Name":"PyrecrouchVariant","Delay":false,"selfid":"17115889868"},"rbxassetid://16372412925":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":150,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":10.3,"X":8.2,"ZSet":3.4,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"selfid":"16372412925","Delay":false,"Name":"PurpleCloud1"},"rbxassetid://16873988732":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":450,"DelayDistance":20,"Roll":false,"Hitbox":{"Y":5.2,"X":11.6,"ZSet":6.9,"Z":25,"YSet":0},"RepeatParryAmount":0,"Name":"Jet_Striker_Kick","Delay":true,"selfid":"16873988732"},"rbxassetid://16707905895":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":10,"Wait":0,"DelayDistance":19,"Roll":false,"Hitbox":{"Y":5.6,"X":8.2,"ZSet":0,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"Name":"Imperial_Vortex","Delay":true,"selfid":"16707905895"},"rbxassetid://5808947929":{"RepeatParryDelay":0,"Range":20,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"IceSlam","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://16754870267":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":10,"Wait":250,"DelayDistance":19,"Roll":false,"Hitbox":{"Y":5.6,"X":8.2,"ZSet":0,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"Name":"ImperialVortexWindup","Delay":false,"selfid":"16754870267"},"rbxassetid://7388133473":{"RepeatParryDelay":0,"CustomConfig":true,"Range":12,"Wait":550,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":6.5,"X":7.8,"ZSet":1.9,"Z":5.2,"YSet":0},"RepeatParryAmount":0,"Name":"AxeCrit","Delay":false,"selfid":"rbxassetid://7388133473"},"rbxassetid://11889580367":{"RepeatParryDelay":0,"Range":50,"Wait":500,"DelayDistance":0,"Hold":true,"Name":"StormbreakerCrit","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7014497401":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"KaidoStun","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://13269418897":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":250,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"metaldropkick","Delay":false,"selfid":"13269418897"},"rbxassetid://7675272455":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"OwlJumpDel","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://16654105888":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":10,"Wait":300,"DelayDistance":19,"Roll":false,"Hitbox":{"Y":5.6,"X":8.2,"ZSet":2.8,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"Name":"ImperialStaff2","Delay":false,"selfid":"16654105888"},"rbxassetid://6500291394":{"Name":"LightningImpactDown","DelayDistance":0,"Roll":true,"Delay":false,"Custom":true,"Hold":false,"Range":100,"Wait":0},"rbxassetid://17197732174":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":10,"Wait":300,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":11.6,"X":11.2,"ZSet":3.6,"Z":8.2,"YSet":0},"RepeatParryAmount":0,"Name":"Flame_LW_M1_3","Delay":false,"selfid":"17197732174"},"rbxassetid://7673188481":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"OwlFinishDel","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7794268358":{"RepeatParryDelay":0,"Range":20,"Wait":0,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"RisingWindCast"},"rbxassetid://6466993564":{"RepeatParryDelay":350,"Range":30,"Wait":300,"Name":"WindCarve","DelayDistance":0,"Hold":false,"RepeatParry":true,"RepeatParryAmount":5,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://11379682232":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"IceguyJump","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://7351158603":{"RepeatParryDelay":0,"CustomConfig":true,"Range":30,"Wait":150,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"SpearCrit","Delay":false,"selfid":"rbxassetid://7351158603"},"rbxassetid://9536688585":{"RepeatParryDelay":0,"Range":35,"Wait":300,"DelayDistance":0,"Hold":false,"Name":"ArcwarderWave","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://11887887621":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":350,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":10.3,"X":8.2,"ZSet":1.7,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"selfid":"11887887621","Delay":false,"Name":"greatsworduptilt"},"rbxassetid://6017418456":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":35,"Wait":0,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":6.5,"X":8.6,"ZSet":4.5,"Z":7.8,"YSet":0},"RepeatParryAmount":0,"Name":"SpearGo","Delay":true,"selfid":"6017418456"},"rbxassetid://17197593993":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":10,"Wait":300,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":11.6,"X":11.2,"ZSet":3.6,"Z":8.2,"YSet":0},"RepeatParryAmount":0,"Name":"FlameLW_M1_1","Delay":false,"selfid":"17197593993"},"rbxassetid://5067090007":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":50,"Wait":390,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.6,"X":13.4,"ZSet":3.8,"Z":9.1,"YSet":0},"RepeatParryAmount":0,"selfid":"5067090007","Delay":false,"Name":"swing2axe"},"rbxassetid://13643852843":{"RepeatParryDelay":0,"CustomConfig":true,"Range":32,"Wait":350,"DelayDistance":0,"Roll":false,"RepeatParryAmount":1,"Autoload":false,"Delay":false,"Name":"RocketLance"},"rbxassetid://7627558238":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":240,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.1,"X":7.8,"ZSet":2.6,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"selfid":"7627558238","Delay":false,"Name":"Spear2hand2"},"rbxassetid://5805183957":{"RepeatParryDelay":0,"Range":20,"Wait":215,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Name":"MaceOneHand1","Delay":false,"Custom":true},"rbxassetid://9400896040":{"RepeatParryDelay":0,"Range":100,"Wait":0,"DelayDistance":20,"Hold":true,"Roll":false,"RepeatParryAmount":0,"Name":"ShoulderCharge","Delay":false,"Custom":true},"rbxassetid://11834551880":{"RepeatParryDelay":0,"Range":40,"Wait":750,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"MechSwipe","Delay":false,"Roll":true},"rbxassetid://17208601112":{"RepeatParryDelay":0,"CustomConfig":true,"Range":30,"Wait":250,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":8.2,"X":9.5,"ZSet":1.9,"Z":12.1,"YSet":-1.7},"RepeatParryAmount":0,"selfid":"rbxassetid://17208601112","Delay":false,"Name":"FlameLWAerial"},"rbxassetid://4699358112":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":300,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":7.3,"X":8.2,"ZSet":2.6,"Z":6.9,"YSet":0},"RepeatParryAmount":0,"Name":"RunningAttack","Delay":false,"selfid":"4699358112"},"rbxassetid://17119287814":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":10,"Wait":300,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":12.1,"X":9.9,"ZSet":0,"Z":9.1,"YSet":0},"RepeatParryAmount":0,"Name":"fallingcrit","Delay":false,"selfid":"17119287814"},"rbxassetid://10904625331":{"RepeatParryDelay":0,"Range":25,"Wait":250,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Name":"HeroLightningCrit","Delay":false,"Custom":true},"rbxassetid://8941331579":{"RepeatParryDelay":0,"Range":100,"Wait":900,"DelayDistance":0,"Hold":true,"Name":"PrimaRocks","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7627854272":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":150,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.5,"X":8.2,"ZSet":3.3,"Z":6.9,"YSet":0},"RepeatParryAmount":0,"Name":"Dagger1hand1","Delay":false,"selfid":"7627854272"},"rbxassetid://11186654931":{"RepeatParryDelay":0,"Range":20,"Wait":190,"DelayDistance":0,"Hold":false,"Name":"LightToll2","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://8310877920":{"RepeatParryDelay":0,"Range":50,"Wait":250,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Name":"WindGun","Delay":false,"Custom":true},"rbxassetid://6385670557":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"PrimaBreak","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://5805194816":{"RepeatParryDelay":0,"Range":20,"Wait":215,"DelayDistance":0,"Hold":false,"Name":"MaceOneHand3","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7018046790":{"RepeatParryDelay":0,"Range":25,"Wait":360,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Name":"EnforcerSwing1"},"rbxassetid://6346656673":{"Custom":true,"DelayDistance":0,"Roll":true,"Delay":false,"Name":"PrimaSwing1","Hold":false,"Range":100,"Wait":630},"rbxassetid://10739102450":{"RepeatParryDelay":0,"Range":40,"Wait":465,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"CoralSpear","Delay":false,"Roll":false},"rbxassetid://12921226261":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":590,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":7.3,"X":8.2,"ZSet":2.6,"Z":6.9,"YSet":0},"RepeatParryAmount":0,"Name":"clubcrit","Delay":false,"selfid":"12921226261"},"rbxassetid://7942002115":{"RepeatParryDelay":0,"Range":60,"Wait":360,"DelayDistance":0,"Hold":false,"Name":"CrabboDouble","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://13199310081":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":400,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.6,"X":14.7,"ZSet":0,"Z":16.4,"YSet":0},"RepeatParryAmount":0,"Name":"CryptCrit","Delay":false,"selfid":"13199310081"},"rbxassetid://6396523003":{"Roll":false,"DelayDistance":0,"Hold":false,"Range":35,"Name":"CrystalKnee","Custom":true,"Delay":false,"Wait":275},"rbxassetid://17108275299":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":200,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":8.6,"X":9.9,"ZSet":2.2,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"Name":"BrutePunch2","Delay":false,"selfid":"17108275299"},"rbxassetid://7938161290":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"CraboGrabFinish","Delay":true,"Roll":false},"rbxassetid://8940731625":{"RepeatParryDelay":0,"Range":100,"Wait":750,"DelayDistance":0,"Hold":false,"Name":"PrimaScream\r","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://7960934455":{"RepeatParryDelay":0,"Range":70,"Wait":1000,"DelayDistance":0,"Roll":true,"Custom":true,"RepeatParryAmount":0,"Hold":false,"Delay":false,"Name":"CrabboBeam"},"rbxassetid://13472893499":{"RepeatParryDelay":0,"CustomConfig":true,"Range":45,"Wait":500,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"IronSlam","Delay":false,"selfid":"rbxassetid://13472893499"},"rbxassetid://15105011815":{"RepeatParryDelay":0,"Range":30,"Wait":50,"DelayDistance":0,"Hold":false,"Name":"LFT Crit 2","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://5953334475":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"RisingFlameUp","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://5120461115":{"RepeatParryDelay":0,"Range":100,"Wait":300,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Name":"ArdourScream","Delay":false,"Custom":true},"rbxassetid://10053070573":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":70,"Wait":550,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":8.2,"X":9.1,"ZSet":3.9,"Z":13.8,"YSet":0.8},"RepeatParryAmount":0,"Name":"CrescWindup","Delay":false,"selfid":"10053070573"},"rbxassetid://7019686291":{"RepeatParryDelay":0,"Range":25,"Wait":300,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Name":"EnforcerKick"},"rbxassetid://4880830128":{"RepeatParryDelay":0,"Range":20,"Wait":215,"DelayDistance":0,"Hold":false,"Name":"MaceTwoHand2","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://9149348937":{"Name":"RisingShadow","DelayDistance":0,"Roll":false,"Delay":false,"Custom":true,"Hold":true,"Range":20,"Wait":350},"rbxassetid://15250125394":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":25,"Wait":480,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"EdenstaffTest","Delay":false,"selfid":"15250125394"},"rbxassetid://9366093103":{"RepeatParryDelay":0,"Range":60,"Wait":300,"DelayDistance":0,"Hold":true,"Roll":false,"RepeatParryAmount":0,"Name":"ShadeBringerFlip","Delay":false,"Custom":true},"rbxassetid://8130745441":{"RepeatParryDelay":0,"Range":40,"Wait":260,"DelayDistance":0,"Hold":false,"Name":"SKnightSwing1","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://5828315760":{"RepeatParryDelay":0,"Range":100,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"AirForce","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://8066909599":{"RepeatParryDelay":0,"Range":50,"Wait":300,"DelayDistance":0,"Hold":false,"Name":"Revenge","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://5063313656":{"RepeatParryDelay":0,"Range":30,"Wait":250,"DelayDistance":0,"Hold":false,"Name":"DaggerRunningAttack","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://9863424290":{"RepeatParryDelay":0,"Range":30,"Wait":400,"Name":"RailbladeCrit","DelayDistance":0,"Custom":true,"Delay":false,"RepeatParryAmount":0,"Hold":false,"RepeatParry":false,"Roll":false},"rbxassetid://14953939237":{"RepeatParryDelay":0,"Range":75,"Wait":450,"DelayDistance":40,"Hold":false,"Name":"MetalBall","RepeatParryAmount":0,"Roll":false,"Delay":true,"Custom":true},"rbxassetid://9225081967":{"RepeatParryDelay":0,"Range":100,"Wait":600,"Roll":true,"DelayDistance":0,"Hold":false,"Delay":false,"RepeatParryAmount":0,"Name":"PrimaPunch","RepeatParry":false,"Custom":true},"rbxassetid://11186652658":{"RepeatParryDelay":0,"Range":20,"Wait":190,"DelayDistance":0,"Hold":false,"Name":"LightToll1","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://16550960639":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":320,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"dashstrike","Delay":false,"selfid":"16550960639"},"rbxassetid://7639988883":{"RepeatParryDelay":0,"Range":50,"Wait":550,"DelayDistance":0,"Hold":false,"Name":"OwlSwipe2","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://11887876811":{"RepeatParryDelay":0,"Range":18,"Wait":165,"DelayDistance":0,"Hold":false,"Name":"RifleUppercut\r","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://6922042769":{"RepeatParryDelay":0,"Range":25,"Wait":40,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"SquibboTackle\r"},"rbxassetid://8285638571":{"Roll":false,"DelayDistance":0,"Hold":false,"Range":100,"Custom":true,"Name":"Duke punch down","Delay":false,"Wait":250},"rbxassetid://7620633231":{"RepeatParryDelay":510,"Range":50,"Wait":260,"Custom":true,"DelayDistance":0,"Hold":false,"Delay":false,"RepeatParryAmount":2,"Name":"ShadowRoar","RepeatParry":true,"Roll":false},"rbxassetid://7666433622":{"Roll":false,"DelayDistance":0,"Hold":false,"Range":50,"Name":"WindBlade","Custom":true,"Delay":false,"Wait":450},"rbxassetid://11867360757":{"RepeatParryDelay":0,"Range":30,"Wait":600,"DelayDistance":0,"Hold":false,"Name":"MechGround","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://9919986614":{"RepeatParryDelay":100,"Range":30,"Wait":300,"Custom":true,"DelayDistance":0,"Roll":false,"Delay":false,"RepeatParryAmount":10,"Hold":false,"RepeatParry":true,"Name":"StarkindredSinister"},"rbxassetid://6728862735":{"RepeatParryDelay":0,"Range":40,"Wait":350,"DelayDistance":0,"Hold":false,"Name":"TurtleSwipe\r","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://6017393708":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":320,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.2,"X":6.9,"ZSet":3.5,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"Name":"GaleLungeWindup","Delay":false,"selfid":"6017393708"},"rbxassetid://7007974914":{"Roll":true,"DelayDistance":0,"Hold":false,"Range":40,"Name":"DivineGuns","Custom":true,"Delay":false,"Wait":0},"rbxassetid://7014172795":{"RepeatParryDelay":300,"Range":100,"Wait":280,"Custom":true,"DelayDistance":0,"Hold":false,"Delay":false,"RepeatParryAmount":1,"Name":"KaidoSwipe","RepeatParry":true,"Roll":false},"rbxassetid://14435770311":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":200,"DelayDistance":0,"Roll":true,"RepeatParryAmount":0,"Name":"OneHandedShot1","Delay":false,"selfid":"14435770311"},"rbxassetid://5117879514":{"RepeatParryDelay":0,"Range":35,"Wait":250,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Name":"SharkoSwipe"},"rbxassetid://6347657585":{"Custom":true,"DelayDistance":0,"Roll":false,"Delay":false,"Name":"PrimaStomp1","Hold":false,"Range":100,"Wait":455},"rbxassetid://7667146179":{"RepeatParryDelay":0,"Range":30,"Wait":100,"DelayDistance":0,"Hold":false,"Name":"TempestWind","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://11876148070":{"RepeatParryDelay":250,"Range":2500,"Wait":1100,"DelayDistance":0,"Hold":false,"Name":"EthironBeam","RepeatParryAmount":11,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://8228293862":{"RepeatParryDelay":0,"Range":100,"Wait":290,"DelayDistance":0,"Hold":false,"Name":"CroccoPoison","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://9711047663":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"BoneKeeperSlide","Delay":false,"Roll":false},"rbxassetid://8285534401":{"Roll":false,"DelayDistance":0,"Hold":false,"Range":100,"Custom":true,"Name":"Duke Knee","Delay":false,"Wait":300},"rbxassetid://7673097597":{"Custom":true,"DelayDistance":0,"Roll":true,"Delay":false,"Name":"OwlCharge","Hold":false,"Range":100,"Wait":280},"rbxassetid://7271659917":{"RepeatParryDelay":0,"Range":100,"Wait":275,"DelayDistance":0,"Hold":false,"Name":"EnforcerPull","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://7007372121":{"Roll":false,"DelayDistance":0,"Hold":false,"Range":80,"Name":"DivineAxe","Custom":true,"Delay":false,"Wait":1750},"rbxassetid://6500704554":{"RepeatParryDelay":0,"CustomConfig":true,"Range":45,"Wait":320,"DelayDistance":0,"Roll":true,"RepeatParryAmount":0,"selfid":"rbxassetid://6500704554","Delay":false,"Name":"GolemUppercut"},"rbxassetid://8126520709":{"RepeatParryDelay":0,"Range":40,"Wait":450,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"MechPunch"},"rbxassetid://8857099063":{"Custom":true,"DelayDistance":0,"Roll":false,"Delay":false,"Name":"LightForge","Hold":false,"Range":50,"Wait":260},"rbxassetid://6318273143":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":35,"Wait":300,"DelayDistance":21,"Roll":false,"Hitbox":{"Y":9.5,"X":8.2,"ZSet":6.9,"Z":18.5,"YSet":0},"RepeatParryAmount":0,"Name":"ShadowDash","Delay":true,"selfid":"6318273143"},"rbxassetid://6501497627":{"RepeatParryDelay":200,"RepeatUntilAnimationEnd":true,"Range":50,"Wait":3380,"Roll":false,"DelayDistance":0,"Hold":false,"RepeatParry":true,"RepeatParryAmount":15,"Name":"GolemSpin","Delay":false,"Custom":true},"rbxassetid://16387874493":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":500,"DelayDistance":19,"Roll":false,"Hitbox":{"Y":5.6,"X":10.8,"ZSet":3.1,"Z":10.3,"YSet":0},"RepeatParryAmount":0,"Name":"Purple_Cloud_Charge","Delay":true,"selfid":"16387874493"},"rbxassetid://8232243591":{"RepeatParryDelay":0,"Range":40,"Wait":750,"DelayDistance":0,"Hold":false,"Name":"MechArm","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://11710290503":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":40,"Wait":420,"DelayDistance":0,"Roll":true,"RepeatParryAmount":0,"Name":"sharko_kick_v2","Delay":false,"selfid":"11710290503"},"rbxassetid://15214200859":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":25,"Wait":370,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"risingthunderwindupn","Delay":false,"selfid":"15214200859"},"rbxassetid://5121733951":{"RepeatParryDelay":460,"CustomConfig":true,"Range":35,"Wait":250,"DelayDistance":0,"Roll":false,"RepeatParryAmount":1,"Name":"SharkoDouble","Delay":false,"selfid":"rbxassetid://5121733951"},"rbxassetid://5750353585":{"Roll":true,"DelayDistance":20,"Hold":false,"Range":50,"Name":"MantraChoke","Custom":true,"Delay":true,"Wait":50},"rbxassetid://15106225064":{"RepeatParryDelay":0,"Range":30,"Wait":380,"DelayDistance":0,"Hold":false,"Name":"LFT Crit 3","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7599113567":{"RepeatParryDelay":0,"CustomConfig":true,"Range":45,"Wait":330,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":4.7,"X":12.5,"ZSet":4.3,"Z":13.8,"YSet":0},"RepeatParryAmount":0,"Name":"DaggerThrow","Delay":false,"selfid":"rbxassetid://7599113567"},"rbxassetid://7003342450":{"RepeatParryDelay":0,"Range":30,"Wait":200,"Roll":true,"DelayDistance":0,"Hold":false,"Delay":false,"RepeatParryAmount":0,"Name":"ElectroCarve","RepeatParry":false,"Custom":true},"rbxassetid://9422599069":{"RepeatParryDelay":0,"Range":20,"Wait":260,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Name":"ShoulderBash","Delay":false,"Custom":true},"rbxassetid://7608490737":{"RepeatParryDelay":0,"Range":26,"Wait":400,"DelayDistance":0,"Hold":false,"Name":"galeTrapFireForge","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://16654099937":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":10,"Wait":300,"DelayDistance":19,"Roll":false,"Hitbox":{"Y":5.6,"X":8.2,"ZSet":2.8,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"Name":"ImperialStaff1","Delay":false,"selfid":"16654099937"},"rbxassetid://6448880983":{"RepeatParryDelay":0,"Range":50,"Wait":50,"DelayDistance":20,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"IceChokeLeap","Delay":true,"Roll":true},"rbxassetid://6432260013":{"RepeatParryDelay":550,"Range":100,"Wait":545,"Name":"PrimaTriple","DelayDistance":0,"Hold":false,"RepeatParry":true,"RepeatParryAmount":2,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://11328614766":{"RepeatParryDelay":0,"Range":45,"Wait":350,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"ContractorSlice"},"rbxassetid://7600224169":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":200,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.2,"X":9.1,"ZSet":3,"Z":9.5,"YSet":0},"RepeatParryAmount":0,"Name":"Swing2","Delay":false,"selfid":"7600224169"},"rbxassetid://5950080662":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":200,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.5,"X":8.2,"ZSet":3.3,"Z":6.9,"YSet":0},"RepeatParryAmount":0,"Name":"FollowUpStrike1","Delay":false,"selfid":"5950080662"},"rbxassetid://9484850093":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":200,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.2,"X":9.1,"ZSet":3,"Z":9.5,"YSet":0},"RepeatParryAmount":0,"Name":"kick","Delay":false,"selfid":"9484850093"},"rbxassetid://10892387798":{"Name":"EthironBomb","DelayDistance":0,"Roll":false,"Delay":false,"Custom":true,"Hold":false,"Range":20,"Wait":0},"rbxassetid://7617742471":{"RepeatParryDelay":0,"Range":100,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"LightningBeamFire","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7318254065":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":500,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.2,"X":10.8,"ZSet":3.5,"Z":10.3,"YSet":0},"RepeatParryAmount":0,"Name":"CriticalSword","Delay":false,"selfid":"7318254065"},"rbxassetid://6348124724":{"Custom":true,"DelayDistance":0,"Roll":true,"Delay":false,"Name":"PrimaSnatch","Hold":false,"Range":100,"Wait":680},"rbxassetid://5786525661":{"Name":"WardensBlade","DelayDistance":0,"Roll":true,"Delay":false,"Custom":true,"Hold":false,"Range":50,"Wait":75},"rbxassetid://8198764550":{"RepeatParryDelay":0,"Range":100,"Wait":80,"DelayDistance":0,"Hold":false,"Name":"SingTaunt","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://7613486472":{"RepeatParryDelay":0,"Range":40,"Wait":150,"DelayDistance":0,"Hold":false,"Name":"SlideSlash","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://7585268054":{"Roll":true,"DelayDistance":0,"Hold":false,"Range":100,"Name":"FlameBlind","Custom":true,"Delay":false,"Wait":460},"rbxassetid://6038858570":{"RepeatParryDelay":0,"Range":25,"Wait":50,"DelayDistance":0,"Hold":true,"Name":"DarkBlade2","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://11887874227":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":70,"Wait":220,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":6.9,"X":9.1,"ZSet":2.2,"Z":8.2,"YSet":0},"RepeatParryAmount":0,"Name":"Swordupper","Delay":false,"selfid":"11887874227"},"rbxassetid://9501936889":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":true,"Name":"CarbuncleRaw"},"rbxassetid://11493920418":{"RepeatParryDelay":0,"Range":20,"Wait":200,"DelayDistance":0,"Hold":false,"Name":"Skyreap1","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://9326022926":{"RepeatParryDelay":0,"Range":30,"Wait":275,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"FirstLightH1"},"rbxassetid://7367818208":{"RepeatParryDelay":0,"CustomConfig":true,"Range":25,"Wait":650,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.5,"X":8.2,"ZSet":4.1,"Z":10.3,"YSet":0},"RepeatParryAmount":0,"Name":"GSCrit","Delay":false,"selfid":"rbxassetid://7367818208"},"rbxassetid://5750296638":{"RepeatParryDelay":0,"Range":20,"Wait":250,"DelayDistance":0,"Custom":true,"Roll":false,"RepeatParryAmount":0,"Name":"MantraGrabWindup","Delay":false,"Hold":false},"rbxassetid://10414162177":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"IceguyForm","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://10357806593":{"RepeatParryDelay":0,"Range":35,"Wait":350,"DelayDistance":0,"Hold":true,"Name":"TornadoKick","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://5774829118":{"RepeatParryDelay":0,"Range":50,"Wait":1260,"DelayDistance":0,"Hold":false,"Name":"FlameRepulsion","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://5659487786":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"SharkoDustOffDel","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://9903304018":{"RepeatParryDelay":0,"Range":20,"Wait":250,"DelayDistance":0,"Custom":true,"Roll":true,"RepeatParryAmount":0,"Name":"SharkoAlphaGrab","Delay":false,"Hold":false},"rbxassetid://8161094751":{"RepeatParryDelay":0,"Range":15,"Wait":180,"DelayDistance":0,"Hold":false,"Name":"LegionKick","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://10768748584":{"RepeatParryDelay":0,"Range":25,"Wait":500,"Roll":false,"DelayDistance":0,"Name":"EnforcerCrit","RepeatParry":false,"RepeatParryAmount":0,"Hold":false,"Delay":false,"Custom":true},"rbxassetid://11638263796":{"RepeatParryDelay":0,"Range":20,"Wait":150,"Custom":true,"DelayDistance":0,"Hold":false,"Delay":false,"RepeatParryAmount":0,"Name":"MechaGatling","RepeatParry":true,"Roll":false},"rbxassetid://5641344204":{"RepeatParryDelay":0,"Range":150,"Wait":250,"DelayDistance":0,"Hold":true,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"SharkoCoral"},"rbxassetid://15572651930":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":25,"Wait":320,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"KaritaDiveBomb_Fall","Delay":false,"selfid":"15572651930"},"rbxassetid://5064195992":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":50,"Wait":390,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.6,"X":13.4,"ZSet":3.8,"Z":9.1,"YSet":0},"RepeatParryAmount":0,"selfid":"5064195992","Delay":false,"Name":"battleaxeswing1"},"rbxassetid://11887938902":{"RepeatParryDelay":0,"Range":20,"Wait":165,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Name":"DaggerUppercut","Delay":false,"Custom":true},"rbxassetid://6039297365":{"RepeatParryDelay":0,"Range":30,"Wait":350,"DelayDistance":0,"Hold":true,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"DarkBlade"},"rbxassetid://9326031030":{"RepeatParryDelay":0,"Range":30,"Wait":275,"DelayDistance":0,"Hold":false,"Name":"FirstLightH2","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://10451145418":{"RepeatParryDelay":0,"Range":30,"Wait":265,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"IcebruteSwipe2","Delay":false,"Roll":true},"rbxassetid://13529982886":{"RepeatParryDelay":0,"CustomConfig":true,"Range":25,"Wait":500,"DelayDistance":0,"Roll":false,"RepeatParryAmount":1,"Autoload":false,"Delay":false,"Name":"IronHug"},"rbxassetid://8367730650":{"RepeatParryDelay":0,"Range":20,"Wait":200,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"KaritaR"},"rbxassetid://9832721746":{"RepeatParryDelay":0,"Range":20,"Wait":265,"DelayDistance":0,"Hold":false,"Name":"Railblade1","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://8131156119":{"RepeatParryDelay":0,"Range":40,"Wait":260,"DelayDistance":0,"Hold":false,"Name":"SKnightKick","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://7618253833":{"RepeatParryDelay":0,"Range":100,"Wait":400,"DelayDistance":0,"Hold":false,"Name":"LightningBeam","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://17108826294":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":300,"DelayDistance":0,"Roll":true,"RepeatParryAmount":0,"Name":"BruteSmash","Delay":false,"selfid":"17108826294"},"rbxassetid://5968796999":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":true,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"LightningStreamWU"},"rbxassetid://6063188218":{"RepeatParryDelay":0,"Range":20,"Wait":160,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"Way2"},"rbxassetid://5644214359":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"SharkoStun","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://5991046915":{"RepeatParryDelay":0,"Range":40,"Wait":670,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":true,"Delay":false,"Name":"Eruption"},"rbxassetid://17197704130":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":10,"Wait":300,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":11.6,"X":11.2,"ZSet":3.6,"Z":8.2,"YSet":0},"RepeatParryAmount":0,"Name":"FlameLW_M1_2","Delay":false,"selfid":"17197704130"},"rbxassetid://6437665734":{"RepeatParryDelay":0,"Range":20,"Wait":215,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"GunShotMain"},"rbxassetid://9461044698":{"RepeatParryDelay":0,"Range":40,"Wait":150,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"StarkindredAscension","Delay":false,"Roll":true},"rbxassetid://11834549387":{"RepeatParryDelay":0,"Range":30,"Wait":450,"DelayDistance":0,"Hold":false,"Name":"MechStomp","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://9474993606":{"RepeatParryDelay":50,"Range":50,"Wait":900,"Roll":false,"DelayDistance":0,"Custom":true,"RepeatParry":true,"RepeatParryAmount":4,"Name":"ThresherNightmareBreath","Delay":false,"Hold":true},"rbxassetid://10451129790":{"RepeatParryDelay":0,"Range":30,"Wait":600,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"IcebruteSlam","Delay":false,"Roll":true},"rbxassetid://8278929677":{"RepeatParryDelay":0,"Range":20,"Wait":165,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Name":"Karita2"},"rbxassetid://5805191624":{"RepeatParryDelay":0,"Range":20,"Wait":215,"DelayDistance":0,"Hold":false,"Name":"MaceOneHand2","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://6372560712":{"RepeatParryDelay":0,"Range":0,"Wait":5760,"DelayDistance":0,"Hold":false,"Name":"LionfishBeam","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://8041947316":{"RepeatParryDelay":580,"Range":50,"Wait":400,"Roll":false,"DelayDistance":20,"Hold":false,"RepeatParry":true,"RepeatParryAmount":10,"Name":"turtlespam","Delay":false,"Custom":true},"rbxassetid://6916545890":{"RepeatParryDelay":0,"Range":25,"Wait":40,"DelayDistance":0,"Hold":false,"Name":"SquibboPunch3","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://4830408708":{"RepeatParryDelay":0,"Range":71,"Wait":50,"DelayDistance":16,"Hold":false,"Roll":true,"RepeatParryAmount":0,"Custom":true,"Delay":true,"Name":"GigaTest"},"rbxassetid://7616100008":{"RepeatParryDelay":0,"Range":50,"Wait":430,"DelayDistance":0,"Hold":true,"Name":"IceBeam","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://17116756734":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":350,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":11.6,"X":14.2,"ZSet":0,"Z":13.8,"YSet":0},"RepeatParryAmount":0,"Name":"TRIPLECUT","Delay":false,"selfid":"17116756734"},"rbxassetid://7002644475":{"RepeatParryDelay":500,"Range":100,"Wait":450,"Roll":false,"DelayDistance":0,"Hold":true,"Delay":false,"RepeatParryAmount":0,"Name":"DivineSpear","RepeatParry":false,"Custom":true},"rbxassetid://6030770341":{"RepeatParryDelay":0,"CustomConfig":true,"Range":40,"Wait":50,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.6,"X":14.7,"ZSet":0,"Z":16.4,"YSet":0},"RepeatParryAmount":0,"Name":"HeavenlyWind","Delay":false,"selfid":"rbxassetid://6030770341"},"rbxassetid://6502261630":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"GolemStun","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://9225098544":{"RepeatParryDelay":0,"Range":100,"Wait":410,"Roll":false,"DelayDistance":0,"Hold":false,"RepeatParry":false,"RepeatParryAmount":0,"Name":"PrimaStomp","Delay":false,"Custom":true},"rbxassetid://7608480718":{"RepeatParryDelay":0,"Range":50,"Wait":150,"DelayDistance":0,"Hold":true,"Name":"FireForge","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://10451150713":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"IcebruteDrill","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://8379406836":{"RepeatParryDelay":0,"Range":45,"Wait":410,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Name":"RapidSlashes","Delay":false,"Custom":true},"rbxassetid://6428533082":{"RepeatParryDelay":0,"Range":100,"Wait":400,"DelayDistance":0,"Hold":false,"Name":"WidowCrunch","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://7938093143":{"RepeatParryDelay":0,"Range":60,"Wait":300,"DelayDistance":0,"Hold":false,"Name":"CrabboGrab","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://8150828674":{"RepeatParryDelay":0,"Range":25,"Wait":200,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"RapidPunches"},"rbxassetid://5808939025":{"RepeatParryDelay":0,"CustomConfig":true,"Range":100,"Wait":410,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":4.7,"X":15.9,"ZSet":8.1,"Z":20.7,"YSet":0},"RepeatParryAmount":0,"Name":"IceEruption","Delay":false,"selfid":"rbxassetid://5808939025"},"rbxassetid://15238144593":{"RepeatParryDelay":0,"Range":30,"Wait":250,"DelayDistance":0,"Hold":false,"Name":"Relentless Flame","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://6063195211":{"RepeatParryDelay":0,"Range":20,"Wait":160,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"Way3"},"rbxassetid://16372422960":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":10,"Wait":300,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":12.1,"X":9.5,"ZSet":2.8,"Z":7.8,"YSet":0},"RepeatParryAmount":0,"Name":"PurpleCloud2","Delay":false,"selfid":"16372422960"},"rbxassetid://7761251007":{"RepeatParryDelay":0,"Range":100,"Wait":0,"DelayDistance":0,"Hold":true,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"LightningStreamCast"},"rbxassetid://11710316011":{"RepeatParryDelay":0,"Range":35,"Wait":350,"DelayDistance":0,"Hold":false,"Name":"SharkoBite","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://6728950754":{"RepeatParryDelay":600,"Range":40,"Wait":350,"Custom":true,"DelayDistance":0,"Hold":false,"Delay":false,"RepeatParryAmount":2,"Name":"TurtleTriple","RepeatParry":true,"Roll":false},"rbxassetid://9416602808":{"RepeatParryDelay":0,"Range":40,"Wait":250,"DelayDistance":0,"Hold":false,"Name":"ShadeBringer","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://6438111139":{"RepeatParryDelay":0,"Range":100,"Wait":700,"DelayDistance":0,"Hold":false,"Name":"PrimaPunt","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://7350770431":{"RepeatParryDelay":0,"CustomConfig":true,"Range":20,"Wait":350,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.5,"X":8.2,"ZSet":3.6,"Z":6.9,"YSet":0},"RepeatParryAmount":0,"Name":"DaggerCrit","Delay":false,"selfid":"rbxassetid://7350770431"},"rbxassetid://6675703249":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":300,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.2,"X":11.2,"ZSet":4.1,"Z":9.9,"YSet":0},"RepeatParryAmount":0,"Name":"HeavySwing2","Delay":false,"selfid":"6675703249"},"rbxassetid://11887901212":{"RepeatParryDelay":0,"Range":20,"Wait":175,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"SpearUppercut","Delay":false,"Roll":false},"rbxassetid://9422278968":{"RepeatParryDelay":460,"Range":20,"Wait":700,"Roll":false,"DelayDistance":0,"Hold":false,"RepeatParry":true,"RepeatParryAmount":3,"Name":"CarbuncleFlail","Delay":false,"Custom":true},"rbxassetid://16746044904":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":500,"DelayDistance":19,"Roll":false,"Hitbox":{"Y":16.4,"X":13.8,"ZSet":0,"Z":13.4,"YSet":0},"RepeatParryAmount":0,"Name":"ImperialSlamAOE","Delay":false,"selfid":"16746044904"},"rbxassetid://9460156259":{"RepeatParryDelay":0,"Range":35,"Wait":275,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"ShadeSlash"},"rbxassetid://9597289518":{"RepeatParryDelay":0,"CustomConfig":true,"Range":18,"Wait":165,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.5,"X":8.2,"ZSet":4.1,"Z":10.3,"YSet":0},"RepeatParryAmount":0,"Name":"GreataxeKick","Delay":false,"selfid":"rbxassetid://9597289518"},"rbxassetid://11890861307":{"RepeatParryDelay":0,"Range":50,"Wait":600,"DelayDistance":0,"Hold":true,"Name":"StormbreakerRecover","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://6448867791":{"RepeatParryDelay":0,"Range":25,"Wait":360,"DelayDistance":20,"Hold":false,"Name":"IceChoke","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7612017515":{"RepeatParryDelay":0,"Range":30,"Wait":250,"DelayDistance":0,"Hold":false,"Name":"IceBlade","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7612146010":{"RepeatParryDelay":0,"Range":20,"Wait":300,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"IceBlade2","Delay":false,"Roll":false},"rbxassetid://9236066780":{"RepeatParryDelay":0,"Range":100,"Wait":280,"DelayDistance":0,"Hold":true,"Custom":true,"RepeatParryAmount":0,"Name":"ShardBow","Delay":false,"Roll":false},"rbxassetid://8215751569":{"RepeatParryDelay":0,"Range":30,"Wait":400,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"FlameLeapReversal","Delay":false,"Roll":true},"rbxassetid://5827250000":{"RepeatParryDelay":0,"Range":20,"Wait":230,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"RapierR"},"rbxassetid://5832828296":{"RepeatParryDelay":0,"Range":50,"Wait":750,"DelayDistance":0,"Hold":false,"Name":"MudskipperBlast","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://5968282214":{"RepeatParryDelay":0,"Range":100,"Wait":280,"DelayDistance":0,"Hold":false,"Name":"LightAssault","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://11710417615":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":90,"Wait":250,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"sharko_coral_v2","Delay":false,"selfid":"11710417615"},"rbxassetid://12071495751":{"RepeatParryDelay":0,"Range":30,"Wait":450,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"PetrasAnchorCrit","Delay":false,"Roll":false},"rbxassetid://11183196198":{"RepeatParryDelay":0,"Range":30,"Wait":350,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"HeroIceCrit"},"rbxassetid://12108376249":{"RepeatParryDelay":0,"Range":20,"Wait":250,"DelayDistance":0,"Custom":true,"Roll":false,"RepeatParryAmount":0,"Name":"EclipseKick2","Delay":false,"Hold":false},"rbxassetid://9726608174":{"RepeatParryDelay":0,"Range":45,"Wait":450,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"ContractorJudgment"},"rbxassetid://11095471496":{"RepeatParryDelay":1250,"Range":50,"Wait":300,"Roll":false,"DelayDistance":0,"Custom":true,"RepeatParry":true,"RepeatParryAmount":1,"Name":"ThresherNightmareFear","Delay":false,"Hold":false},"rbxassetid://7794260173":{"RepeatParryDelay":0,"Range":30,"Wait":180,"DelayDistance":0,"Hold":false,"Name":"RisingWind","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://7627889074":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":150,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.5,"X":8.2,"ZSet":3.3,"Z":6.9,"YSet":0},"RepeatParryAmount":0,"Name":"Slash2Dagger","Delay":false,"selfid":"7627889074"},"rbxassetid://6701095669":{"RepeatParryDelay":0,"Range":100,"Wait":50,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"ShadowMeteor","Delay":false,"Roll":true},"rbxassetid://5773131869":{"Custom":true,"DelayDistance":0,"Roll":false,"Delay":false,"Name":"FireGun","Hold":true,"Range":50,"Wait":400},"rbxassetid://8375571405":{"RepeatParryDelay":0,"Range":40,"Wait":500,"DelayDistance":0,"Custom":true,"Roll":false,"RepeatParryAmount":0,"Name":"PressureBlast","Delay":false,"Hold":false},"rbxassetid://9544183744":{"RepeatParryDelay":0,"Range":30,"Wait":300,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"BounderSwing1","Delay":false,"Roll":false},"rbxassetid://7019018522":{"RepeatParryDelay":280,"Range":40,"Wait":850,"Roll":false,"DelayDistance":0,"Hold":false,"RepeatParry":true,"RepeatParryAmount":12,"Name":"EnforcerSpin","Delay":false,"Custom":true},"rbxassetid://10451074652":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"IceCrawl","RepeatParryAmount":0,"Roll":false,"Delay":true,"Custom":true},"rbxassetid://8018881257":{"RepeatParryDelay":0,"CustomConfig":true,"Range":35,"Wait":230,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"ShadowEruption","Delay":false,"selfid":"rbxassetid://8018881257"},"rbxassetid://11312302005":{"RepeatParryDelay":0,"Range":25,"Wait":250,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"HeroWindCrit","Delay":false,"Roll":false},"rbxassetid://8131065347":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"SKnightStun","RepeatParryAmount":0,"Custom":true,"Delay":true,"Roll":false},"rbxassetid://9681908909":{"RepeatParryDelay":0,"Range":50,"Wait":2600,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"BoneKeeperJavelin","Delay":false,"Roll":false},"rbxassetid://6428519131":{"RepeatParryDelay":0,"Range":100,"Wait":400,"DelayDistance":0,"Hold":false,"Name":"WidowLeftSwing","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://7543558046":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":60,"Wait":330,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":10.3,"X":9.9,"ZSet":3.1,"Z":17.7,"YSet":0},"RepeatParryAmount":0,"selfid":"7543558046","Delay":true,"Name":"FlameAssault"},"rbxassetid://8183996606":{"RepeatParryDelay":0,"Range":40,"Wait":260,"DelayDistance":0,"Hold":false,"Name":"GrandJavelin","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://8198492537":{"RepeatParryDelay":0,"Range":30,"Wait":200,"DelayDistance":0,"Hold":false,"Name":"ExhaustionStrike","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://8286153000":{"RepeatParryDelay":0,"Range":100,"Wait":320,"DelayDistance":0,"Hold":true,"Name":"Duke wind blast","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://8150846354":{"RepeatParryDelay":0,"Range":25,"Wait":100,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"RapindPunchesBarrage"},"rbxassetid://15104780537":{"RepeatParryDelay":0,"Range":30,"Wait":50,"DelayDistance":0,"Hold":false,"Name":"LFT Crit 1","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7599168630":{"RepeatParryDelay":0,"Range":40,"Wait":150,"DelayDistance":0,"Hold":false,"Name":"LightningBlade","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://7018083796":{"RepeatParryDelay":0,"Range":25,"Wait":360,"DelayDistance":0,"Hold":false,"Name":"EnforcerSwing2","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://8278933540":{"RepeatParryDelay":0,"Range":15,"Wait":165,"DelayDistance":0,"Hold":false,"Name":"KaritaKick","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://13253662736":{"RepeatParryDelay":0,"CustomConfig":true,"Range":25,"Wait":270,"DelayDistance":0,"Roll":false,"RepeatParryAmount":1,"Autoload":false,"Delay":false,"Name":"rodassault2"},"rbxassetid://7014547998":{"RepeatParryDelay":0,"Range":100,"Wait":280,"DelayDistance":0,"Hold":false,"Name":"KaidoTail","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://9356892933":{"RepeatParryDelay":0,"Range":70,"Wait":250,"DelayDistance":0,"Custom":true,"Roll":false,"RepeatParryAmount":0,"Name":"SharkoMechaMinigun","Delay":false,"Hold":false},"rbxassetid://11363599835":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":50,"Wait":350,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.5,"X":10.8,"ZSet":3.3,"Z":12.5,"YSet":-1},"RepeatParryAmount":0,"selfid":"11363599835","Delay":false,"Name":"heavy_aerial"},"rbxassetid://7003448248":{"RepeatParryDelay":0,"Range":80,"Wait":550,"DelayDistance":0,"Hold":false,"Name":"DivineGS","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://11308969885":{"RepeatParryDelay":0,"Range":30,"Wait":250,"DelayDistance":0,"Hold":false,"Name":"HeroFlameCrit","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://8278931393":{"RepeatParryDelay":0,"Range":20,"Wait":165,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Name":"Karita3"},"rbxassetid://9365486663":{"RepeatParryDelay":0,"Range":35,"Wait":275,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"ShadeBringerSlash","Delay":false,"Roll":false},"rbxassetid://8290626574":{"RepeatParryDelay":0,"Range":100,"Wait":550,"DelayDistance":0,"Hold":false,"Name":"Duke stomp","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://8131374542":{"RepeatParryDelay":0,"Range":100,"Wait":330,"DelayDistance":0,"Hold":false,"Name":"SKnightAircut","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://6916513795":{"RepeatParryDelay":0,"Range":25,"Wait":40,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"SquibboPunch1"},"rbxassetid://9690822091":{"RepeatParryDelay":0,"Range":0,"Wait":0,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"BoneKeeperRun","Delay":false,"Roll":false},"rbxassetid://9657469282":{"RepeatParryDelay":0,"Range":25,"Wait":0,"DelayDistance":0,"Hold":true,"Custom":true,"RepeatParryAmount":0,"Name":"Tempo","Delay":false,"Roll":false},"rbxassetid://8230353450":{"RepeatParryDelay":0,"Range":55,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"CrocDig","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://16214012662":{"RepeatParryDelay":450,"Range":70,"Wait":1200,"DelayDistance":0,"Hold":false,"Name":"Skyshatter Kick","RepeatParryAmount":1,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://11493924588":{"RepeatParryDelay":0,"Range":20,"Wait":250,"DelayDistance":0,"Hold":false,"Name":"SkyreapSprint\r","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://13799614234":{"RepeatParryDelay":0,"CustomConfig":true,"Range":32,"Wait":100,"DelayDistance":0,"Roll":false,"RepeatParryAmount":1,"Autoload":false,"Delay":false,"Name":"squidslash1_v2"},"rbxassetid://8176091986":{"RepeatParryDelay":0,"Range":80,"Wait":850,"DelayDistance":0,"Hold":false,"Name":"CrabboSlam","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://11508725111":{"Name":"EthironPunch","DelayDistance":0,"Roll":false,"Delay":false,"Custom":true,"Hold":false,"Range":2500,"Wait":1400},"rbxassetid://7827886914":{"RepeatParryDelay":0,"CustomConfig":true,"Range":35,"Wait":320,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"KatanaCrit","Delay":false,"selfid":"rbxassetid://7827886914"},"rbxassetid://8172871094":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":25,"Wait":680,"DelayDistance":0,"Roll":true,"RepeatParryAmount":0,"Name":"spearshot","Delay":false,"selfid":"8172871094"},"rbxassetid://6415074870":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":20,"Wait":650,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"Name":"ShadowGun","Delay":false,"selfid":"6415074870"},"rbxassetid://9544203895":{"RepeatParryDelay":0,"Range":30,"Wait":800,"DelayDistance":0,"Hold":false,"Roll":true,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Name":"BounderCharge"},"rbxassetid://7599410106":{"RepeatParryDelay":0,"Range":20,"Wait":400,"DelayDistance":0,"Hold":false,"Name":"MaceCrit","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://11438175479":{"RepeatParryDelay":600,"Range":30,"Wait":300,"Roll":false,"DelayDistance":0,"Name":"IcecrawlerSwipes","Delay":false,"RepeatParryAmount":1,"Hold":false,"RepeatParry":true,"Custom":true},"rbxassetid://17116112176":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":50,"Wait":0,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":8.2,"X":9.5,"ZSet":3.4,"Z":11.2,"YSet":0},"RepeatParryAmount":0,"selfid":"17116112176","Delay":true,"Name":"RUNNINGCRIT"},"rbxassetid://6501044846":{"RepeatParryDelay":0,"Range":40,"Wait":360,"DelayDistance":0,"Hold":false,"Name":"GolemStomp","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://5786514661":{"RepeatParryDelay":0,"Range":30,"Wait":150,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"WardensBlade","Delay":false,"Roll":true},"rbxassetid://13989464729":{"RepeatParryDelay":50,"CustomConfig":true,"Range":35,"Wait":200,"DelayDistance":0,"Roll":false,"RepeatParryAmount":2,"Name":"Gran Critical","Delay":false,"Autoload":false},"rbxassetid://10622235550":{"RepeatParryDelay":150,"Range":25,"Wait":350,"Roll":false,"DelayDistance":0,"Hold":true,"RepeatParry":false,"RepeatParryAmount":8,"Name":"DawnbreakerBlinding","Delay":false,"Custom":true},"rbxassetid://7600450739":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":70,"Wait":200,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":6.9,"X":9.1,"ZSet":3.5,"Z":10.8,"YSet":0},"RepeatParryAmount":0,"Name":"FakeSwing","Delay":false,"selfid":"7600450739"},"rbxassetid://10358800338":{"RepeatParryDelay":350,"Range":100,"Wait":480,"Custom":true,"DelayDistance":0,"Hold":false,"Delay":false,"RepeatParryAmount":3,"Name":"triple_wind_kick","RepeatParry":true,"Roll":false},"rbxassetid://11887898774":{"RepeatParryDelay":0,"Range":20,"Wait":165,"DelayDistance":0,"Hold":false,"Name":"MaceUppercut","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://8227878518":{"RepeatParryDelay":0,"CustomConfig":true,"Range":50,"Wait":590,"DelayDistance":0,"Roll":false,"RepeatParryAmount":0,"selfid":"rbxassetid://8227878518","Delay":false,"Name":"CroccoTail"},"rbxassetid://8018953639":{"Roll":false,"Name":"shadow eruption 2","Hold":true,"Custom":true,"Range":20,"Wait":-1},"rbxassetid://9832727905":{"RepeatParryDelay":0,"Range":20,"Wait":265,"DelayDistance":0,"Hold":false,"Name":"Railblade3","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://10680972676":{"Name":"EthironSpear","DelayDistance":0,"Roll":false,"Delay":false,"Custom":true,"Hold":false,"Range":20,"Wait":0},"rbxassetid://7961577198":{"RepeatParryDelay":0,"Range":80,"Wait":800,"DelayDistance":0,"Hold":false,"Name":"CrabboLeap","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://12071942369":{"RepeatParryDelay":0,"Range":30,"Wait":600,"DelayDistance":0,"Hold":false,"Roll":true,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Name":"PetrasAnchorCritM1"},"rbxassetid://8131612979":{"RepeatParryDelay":0,"Range":100,"Wait":650,"DelayDistance":0,"Hold":false,"Name":"SKnightPunch","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://9551012380":{"RepeatParryDelay":0,"CustomConfig":true,"Range":30,"Wait":600,"DelayDistance":0,"Roll":true,"Hitbox":{"Y":4.7,"X":15.9,"ZSet":8.1,"Z":20.7,"YSet":0},"RepeatParryAmount":0,"Name":"IceEruptionNew","Delay":false,"selfid":"rbxassetid://9551012380"},"rbxassetid://7013388154":{"RepeatParryDelay":0,"Range":100,"Wait":1100,"DelayDistance":0,"Hold":false,"Name":"KaidoBreath","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://17108566269":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":15,"Wait":450,"DelayDistance":0,"Roll":true,"Hitbox":{"Y":8.6,"X":9.9,"ZSet":2.2,"Z":8.6,"YSet":0},"RepeatParryAmount":0,"Name":"Brute_Heavy_Punch","Delay":false,"selfid":"17108566269"},"rbxassetid://9928485641":{"RepeatParryDelay":0,"Range":18,"Wait":230,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"RifleSwing2"},"rbxassetid://5769343416":{"RepeatParryDelay":0,"Range":25,"Wait":550,"DelayDistance":0,"Hold":false,"Name":"Servants","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://6030850955":{"RepeatParryDelay":0,"Range":25,"Wait":0,"DelayDistance":0,"Hold":false,"Name":"HeavenlyWindSlam","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://7598898608":{"RepeatParryDelay":0,"Range":30,"Wait":450,"DelayDistance":0,"Hold":true,"Name":"IceSmash","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://11573034823":{"RepeatParryDelay":0,"CustomConfig":true,"Range":12,"Wait":100,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":9.5,"X":8.2,"ZSet":3.3,"Z":6.9,"YSet":0},"RepeatParryAmount":0,"Name":"ms_slash2","Delay":false,"selfid":"rbxassetid://11573034823"},"rbxassetid://7013342486":{"RepeatParryDelay":0,"Range":100,"Wait":1100,"DelayDistance":0,"Hold":false,"Name":"KaidoCloseBreath","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":true},"rbxassetid://9681421310":{"RepeatParryDelay":0,"Range":30,"Wait":400,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"BoneKeeperSweep1","Delay":false,"Roll":false},"rbxassetid://9832724876":{"RepeatParryDelay":0,"Range":20,"Wait":265,"DelayDistance":0,"Hold":false,"Name":"Railblade2","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://12337662319":{"RepeatParryDelay":0,"Range":20,"Wait":400,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"ProminenceDraw","Delay":false,"Roll":false},"rbxassetid://16337196055":{"RepeatParryDelay":90,"Range":30,"Wait":10,"DelayDistance":0,"Hold":false,"Name":"Ice Carve Spin","RepeatParryAmount":2,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://8161046333":{"RepeatParryDelay":0,"Range":20,"Wait":150,"DelayDistance":0,"Hold":false,"Name":"LegionUppercut","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://5805138186":{"RepeatParryDelay":0,"Range":20,"Wait":215,"DelayDistance":0,"Hold":false,"Name":"MaceTwoHand1","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://16372427756":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":10,"Wait":300,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":12.1,"X":9.5,"ZSet":2.8,"Z":7.8,"YSet":0},"RepeatParryAmount":0,"Name":"PurpleCloud3","Delay":false,"selfid":"16372427756"},"rbxassetid://8467835626":{"RepeatParryDelay":0,"Range":50,"Wait":0,"DelayDistance":0,"Hold":true,"Name":"IceForge","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://9681916972":{"RepeatParryDelay":0,"Range":50,"Wait":650,"DelayDistance":0,"Custom":true,"Hold":false,"RepeatParryAmount":0,"Name":"BoneKeeperFloor","Delay":false,"Roll":true},"rbxassetid://8046864635":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":35,"Wait":500,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":10.3,"X":8.6,"ZSet":2.6,"Z":7.3,"YSet":0},"RepeatParryAmount":0,"selfid":"8046864635","Delay":false,"Name":"FireBlade"},"rbxassetid://7968088101":{"RepeatParryDelay":0,"Range":25,"Wait":50,"DelayDistance":0,"Hold":false,"Name":"HeadButt","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://9359697890":{"RepeatParryDelay":0,"Range":30,"Wait":250,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Name":"ShadeDevour","Delay":false,"Roll":false},"rbxassetid://9941118927":{"RepeatParryDelay":0,"Range":20,"Wait":150,"DelayDistance":0,"Hold":true,"Name":"StarkindredCelestial","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://10880473795":{"RepeatParryDelay":0,"Range":100,"Wait":650,"DelayDistance":0,"Hold":false,"Roll":false,"RepeatParryAmount":0,"Custom":true,"Delay":false,"Name":"EnforcerPullMantra"},"rbxassetid://6499077558":{"RepeatParryDelay":0,"Range":40,"Wait":350,"DelayDistance":0,"Hold":false,"Name":"GolemSlam","RepeatParryAmount":0,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://6385078248":{"RepeatParryDelay":0,"Range":45,"Wait":240,"DelayDistance":0,"Hold":false,"Name":"ClutchingShadow3","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://9893133020":{"RepeatParryDelay":0,"Range":20,"Wait":265,"DelayDistance":0,"Hold":false,"Name":"RailbladeAirCrit","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://16337192866":{"RepeatParryDelay":100,"Range":30,"Wait":10,"DelayDistance":0,"Hold":false,"Name":"Ice Carve Spin Loop","RepeatParryAmount":1,"Custom":true,"Delay":false,"Roll":false},"rbxassetid://9224920648":{"RepeatParryDelay":0,"Range":100,"Wait":900,"DelayDistance":0,"Hold":false,"Name":"PrimaLeap","RepeatParryAmount":0,"Roll":true,"Delay":false,"Custom":true},"rbxassetid://10413822826":{"RepeatParryDelay":650,"Range":30,"Wait":350,"Custom":true,"DelayDistance":0,"Hold":false,"Delay":false,"RepeatParryAmount":1,"Name":"IceguyCombo","RepeatParry":true,"Roll":false},"rbxassetid://5963021481":{"RepeatParryDelay":0,"Range":20,"Wait":250,"DelayDistance":0,"Hold":false,"Name":"FlameLeapSlam","RepeatParryAmount":0,"Roll":false,"Delay":false,"Custom":true},"rbxassetid://5769290839":{"RepeatParryDelay":0,"Range":100,"Wait":200,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":true,"Delay":false,"Name":"Gaze"},"rbxassetid://8295920689":{"RepeatParryDelay":0,"Range":40,"Wait":260,"DelayDistance":0,"Hold":false,"Custom":true,"RepeatParryAmount":0,"Roll":false,"Delay":false,"Name":"MechBarrage"},"rbxassetid://6428530032":{"RepeatParryDelay":0,"CustomConfig":true,"Range":100,"Wait":500,"DelayDistance":0,"Roll":true,"RepeatParryAmount":0,"Name":"WidowSpit","Delay":false,"selfid":"rbxassetid://6428530032"},"rbxassetid://13282373122":{"RepeatParryDelay":200,"CustomConfig":true,"Range":38,"Wait":350,"DelayDistance":0,"Roll":false,"RepeatParryAmount":5,"Autoload":false,"Delay":false,"Name":"firingline"},"rbxassetid://5067105317":{"RepeatParryDelay":0,"CustomConfig":true,"RepeatUntilAnimationEnd":false,"Range":50,"Wait":390,"DelayDistance":0,"Roll":false,"Hitbox":{"Y":5.6,"X":13.4,"ZSet":3.8,"Z":9.1,"YSet":0},"RepeatParryAmount":0,"selfid":"5067105317","Delay":false,"Name":"swing3axe"}}]])
end)
return __bundle_require("__root")