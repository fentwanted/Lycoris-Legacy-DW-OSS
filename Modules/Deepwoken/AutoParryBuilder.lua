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