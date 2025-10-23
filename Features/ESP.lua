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