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
