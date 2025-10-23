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
