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