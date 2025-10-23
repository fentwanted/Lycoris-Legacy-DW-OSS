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
