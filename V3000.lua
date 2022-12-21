-- xsixx
------------------------------------------------------------
-- variables
	local pluginToolbar

	if _G.MoonGlobal then
		_G.MoonGlobal.ready = false
		pluginToolbar = plugin:CreateToolbar("Moon Animator [restart required]")
		pluginToolbar:CreateButton("", "Moon Animator", "http://www.roblox.com/asset/?id=4725619926")
		pluginToolbar:CreateButton("", "Restart Studio", "")
		return
	end

	pluginToolbar = plugin:CreateToolbar("Moon Animator")

	_G.MoonGlobal = {}
	global = _G.MoonGlobal

	global.ver = 30000

	global.toolbar = pluginToolbar

	global.http = game:GetService("HttpService")
	global.chs = game:GetService("ChangeHistoryService")
	global.insert = game:GetService("InsertService")
	global.inputServ = game:GetService("UserInputService")
	global.runServ = game:GetService("RunService")
	global.studioServ = game:GetService("StudioService")

	global.plugin = plugin
	
	global.Mouse = plugin:GetMouse()
	global.MouseFilter = Instance.new("Folder"); global.MouseFilter.Name = "MoonAnimatorMouseFilter"; global.MouseFilter.Archivable = false
	global.ReleaseHandlesCon = nil

	global.newUI = script.Parent.UI
	global.rigs = script.Parent.Rigs
	global.anis = script.Parent.Animations

	global.window_folder = Instance.new("Folder", game:GetService("CoreGui")); global.window_folder.Name = "xSIXxCoreGui"
	global.ui3d = Instance.new("Folder", global.window_folder); global.ui3d.Name = "MoonAnimatorUI3D"

	global.DOUBLE_CLICC_TIME = 0.5

	global.DEFAULT_FPS = 60
	
	global.MIN_FRAMES = 60
	global.DEFAULT_FRAMES = 300
	global.MAX_FRAMES = 216000

	global.time_offset = 0

	global.NIL_VALUE = newproxy()
------------------------------------------------------------
-- libraries
do
	for _, lib in pairs(script.Parent.Libraries:GetChildren()) do
		if lib.ClassName == "ModuleScript" then
			global[lib.Name] = require(lib)
		end
	end
end
------------------------------------------------------------
-- objects
do
	global.ObjectModules = {}
	global.Objects = {}

	global.objIsType = function(obj, str)
		assert(obj.type ~= nil, "Object is not a xSIXxObject.")
		
		for i = 1, #obj.type do
			if obj.type[i] == str then
				return true
			end
		end

		return false
	end

	local function RequireObjects(folder, tbl, req)
		for _, mod in pairs(folder:GetChildren()) do
			if mod.ClassName == "Folder" then
				tbl[mod.Name] = {}
				RequireObjects(mod, tbl[mod.Name], req)
			else
				if req then
					tbl[mod.Name] = require(mod)
				else
					tbl[mod.Name] = mod
				end
			end
		end
	end
	RequireObjects(script.Parent.Classes, global.ObjectModules, false)
	RequireObjects(script.Parent.Classes, global.Objects, true)
end
------------------------------------------------------------
-- useful
do
	global.ResetUndoRedo = function()
		global.chs:SetWaypoint("Moon Animator Reseting")
		global.chs:SetWaypoint("Moon Animator Reset")
		global.chs:ResetWaypoints()
	end
	
	global.ClosestValue = function(sorted_int_table, target_value, start_index) -- binary search
		local table_size = #sorted_int_table
		local i, j, mid = 1, table_size, start_index

		while i < j do
			if sorted_int_table[mid] == target_value then
				return sorted_int_table[mid]
			end
			if target_value < sorted_int_table[mid] then
				if mid > 1 and target_value > sorted_int_table[mid - 1] then
					if target_value - sorted_int_table[mid - 1] >= sorted_int_table[mid] - target_value then
						return sorted_int_table[mid]
					else
						return sorted_int_table[mid - 1]
					end
				end
				j = mid
			else
				if mid < table_size and target_value < sorted_int_table[mid + 1] then
					if target_value - sorted_int_table[mid] >= sorted_int_table[mid + 1] - target_value then
						return sorted_int_table[mid + 1]
					else
						return sorted_int_table[mid]
					end
				end
				i = mid + 1
			end
			mid = math.floor((i + j) / 2)
		end

		return sorted_int_table[mid]
	end

	global.hex2rgb = function(hex)
		if #hex < 6 then return end
		
		hex = hex:gsub("#","")
		return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
	end

	global.split = function(inputstr, sep)
		local t = {}
		for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
		end
		return t
	end
	
	global.round = function(n, b)
		return math.floor((n / b) + 0.5) * b
	end

	global.reflect = function(cf)
		local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:components()
		x = -x
		-- R00, R10, R20 (x)
		R10 = -R10
		R20 = -R20
		-- R01, R11, R21 (y) 
		R01 = -R01
		-- R02, R12, R22 (z) 
		R02 = -R02
	
		return CFrame.new(x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
	end

	global.deepcopy = function(orig)
	    local orig_type = type(orig)
	    local copy
	    if orig_type == 'table' then
	        copy = {}
	        for orig_key, orig_value in next, orig, nil do
	            copy[global.deepcopy(orig_key)] = global.deepcopy(orig_value)
	        end
	        setmetatable(copy, global.deepcopy(getmetatable(orig)))
	    else
	        copy = orig
	    end
	    return copy
	end

	global.csvToNumberTable = function(csv)
		csv = csv:gsub("%s+", "")..","

		local vals = {}
		local getNum = nil
		repeat
			local findComma = csv:find(",")
			if findComma == nil then break end
			getNum = tonumber(csv:sub(1, findComma - 1))
			if getNum == nil then break end
			table.insert(vals, getNum)
			csv = csv:sub(findComma + 1)
		until false

		return vals
	end

	global.TickToTime = function(t)
		local timeTable = os.date("*t", t)
		local pm = false

		if timeTable.hour > 12 then -- miss me with that 24 hour stuff
			pm = true
			timeTable.hour = timeTable.hour - 12
		elseif timeTable.hour == 12 then
			pm = true
		elseif timeTable.hour == 0 then
			timeTable.hour = 12
		end

		if timeTable.min < 10 then
			timeTable.min = "0"..timeTable.min
		end
		if timeTable.sec < 10 then
			timeTable.sec = "0"..timeTable.sec
		end

		local ending = pm and "PM" or "AM"

		return timeTable.hour..":"..timeTable.min..":"..timeTable.sec.." "..ending.." "..timeTable.month.."/"..timeTable.day.."/"..timeTable.year
	end

	global.TimeConvert = function(orig, origUnit, destUnit, fps) -- UNITS: "f" (frames), "s" (seconds), "t" (time, 1:00, 4:00:00, etc)
		if orig == nil then return nil end
		
		if origUnit == "s" then
			orig = math.floor(orig * fps + 0.5)
		elseif origUnit == "t" then
			orig = ":"..string.gsub(orig, ":", "::")..":"
			local iter = string.gmatch(orig, ":(%d+):")

			local vals = {}
			local count = -1

			repeat
				local getNum = iter()
				if getNum == nil then break end
				getNum = tonumber(getNum)
				assert(getNum ~= nil, "Invalid time format.")

				table.insert(vals, getNum)
				count = count + 1
			until false

			orig = 0
			for _, num in pairs(vals) do
				orig = math.floor(orig + num * (fps ^ count))
				count = count - 1
			end
		end

		local dest

		if destUnit == "f" then
			dest = orig
		elseif destUnit == "s" then
			dest = orig / fps
		elseif destUnit == "t" then
			dest = ""

			if orig >= fps ^ 2 then
				local get = math.floor(orig / (fps ^ 2))
				dest = dest..get..":"
				orig = math.floor(orig - get * (fps ^ 2))
			end
			if orig >= fps then
				local get = math.floor(orig / fps)
				if #dest > 0 then
					local str = tostring(get)
					if #str == 1 then str = "0"..str end
					dest = dest..str..":"
				else
					dest = dest..get..":"
				end
				orig = math.floor(orig - get * fps)
			else
				if #dest > 0 then
					dest = dest.."00:"
				else
					dest = dest.."0:"
				end
			end

			local str = tostring(orig)
			if #str == 1 then str = "0"..str end
			dest = dest..str
		end

		return dest
	end

	global.FormatFrameTime = function(frames, fps)
		if global.Toggles.GetToggleValue("TotalInSeconds") then -- bad, getting toggle repeatedly
			return global.TimeConvert(frames, "f", "t", fps).." ["..string.format("%.3f", global.round(global.TimeConvert(frames, "f", "s", fps), 0.001)).."s]"
		else
			return global.TimeConvert(frames, "f", "t", fps).." ["..frames.."f]"
		end
	end

	global.RigHierarchy = function(rig)
		assert(rig.PrimaryPart ~= nil)
		local final = {} -- { {Motor = motor, Attached = { {Motor = motor, Attached = {}, Parent = tbl, Depth = 2} }, Parent = nil, Depth = 1}

		local allJoints  = {}
		local jointStack = {}

		for _, motor in pairs(rig:GetDescendants()) do
			if motor.ClassName == "Motor6D" and (motor.Part0 and motor.Part0.Parent) and (motor.Part1 and motor.Part1.Parent) then
				if motor.Part0 == rig.PrimaryPart then
					local new_motor = {Motor = motor, Depth = 1, Path = motor.Part1.Name, Parent = nil, Attached = {}}
					table.insert(final, new_motor)
					table.insert(jointStack, 1, new_motor)
				end
				table.insert(allJoints, motor)
			end
		end

		table.sort(allJoints,  function(a, b) return a.Name < b.Name end)
		table.sort(jointStack, function(a, b) return a.Motor.Name < b.Motor.Name end)

		while (#jointStack > 0) do -- depth first search
			local pop = table.remove(jointStack, 1)
			for _, motor in pairs(allJoints) do
				if motor.Part0 == pop.Motor.Part1 then
					local new_motor = {Motor = motor, Depth = pop.Depth + 1, Path = pop.Path.."."..motor.Part1.Name, Parent = pop, Attached = {}}
					table.insert(pop.Attached, new_motor)
					table.insert(jointStack, 1, new_motor)
				end
			end
		end

		return final
	end

	global.RobloxKeyframeCount = function(roblox)
		if roblox == nil then return nil, "animation is nil" end

		local count = 0

		for _, Keyframe in pairs(roblox:GetChildren()) do
			if Keyframe.ClassName == "Keyframe" then

				for _, Pose in pairs(Keyframe:GetDescendants()) do
					if Pose.ClassName == "Pose" and Pose:FindFirstChild("xSIXxNull") == nil and Pose.Parent ~= Keyframe then
						count = count + 1
					end
				end

			end
		end

		return count
	end

	global.RobloxToBuffers = function(roblox, rig, fps)
		local final = {}

		local simple, length = global.RobloxToSimple(roblox, rig, fps)
		if not simple or not length then return end

		for motorId, data in pairs(simple) do
			final[motorId] = {Motor = data.Motor, Buffer = {}}

			local all_pos = {}
			for kfPos, _ in pairs(data.TargetValues) do
				table.insert(all_pos, kfPos)
			end
			table.sort(all_pos, function(a,b) return a < b end)

			local ini_value
			local ini_pos = 0
			for _, kfPos in pairs(all_pos) do
				if ini_value == nil then
					ini_value = data.TargetValues[kfPos]
					final[motorId].Buffer[kfPos] = ini_value
				else
					local final_value = data.TargetValues[kfPos]
					local dist = kfPos - ini_pos
					local ease = data.Easing[kfPos] and global.Objects.Ease.Detableize(data.Easing[kfPos]) or global.Objects.Ease.LINEAR()

					for bufferPos = ini_pos, kfPos, 1 do
						final[motorId].Buffer[bufferPos] = global.ItemTable.TweenFunctions.Lerp(ini_value, final_value, ease._func((bufferPos - ini_pos) / dist))
					end

					ease:Destroy()

					ini_value = final_value
					ini_pos = kfPos
				end
			end

			if ini_pos < length then
				for bufferPos = ini_pos, length, 1 do
					final[motorId].Buffer[bufferPos] = final[motorId].Buffer[ini_pos]
				end
			end

			local c1_inv = data.Motor.C1:Inverse()
			for ind, val in pairs(final[motorId].Buffer) do
				final[motorId].Buffer[ind] = (val * c1_inv):Inverse()
			end
		end

		return final, length
	end

	global.RobloxToSimple = function(roblox, rig, fps)
		if roblox == nil then return nil, nil, "animation is nil" end

		-- check if "rig" is a rig
		if not global.ItemTable.CheckIfRig(rig) then
			return nil, nil, "not a rig"
		end

		-- find target KeyframeSequence
		local target = nil

		if type(roblox) == "number" then
			local succ, err = pcall(function() 
				target = global.insert:LoadAsset(roblox)
				for _, obj in pairs(target:GetChildren()) do
					if obj.ClassName == "KeyframeSequence" then
						target = obj
						break
					end
				end
			end)
			if not succ then warn(err) return nil, nil, "failed to insert animation from id" end
		elseif roblox.ClassName == "KeyframeSequence" then
			target = roblox
		else
			return nil, nil, "animation is invalid"
		end

		-- gather all (reasonably) correct motors in rig
		local allMotors = {}
		for _, motor in pairs(rig:GetDescendants()) do
			if motor.ClassName == "Motor6D" and motor.Part0 and motor.Part0.Parent and motor.Part1 and motor.Part1.Parent then
				table.insert(allMotors, motor)
			end
		end

		local motorMap = {}
		local motorHier
		for _, motor in pairs(allMotors) do
			local motorData = {motor:GetDebugId(8), motor}
			motorHier = motor.Part0.Name.."."..motor.Part1.Name
			while true do
				motorMap[motorHier] = motorData

				local foundNextMotor
				for _, nextMotor in pairs(allMotors) do
					if nextMotor.Part1 == motor.Part0 then
						foundNextMotor = nextMotor
						break
					end
				end
				if foundNextMotor == nil then break end

				motorHier = foundNextMotor.Part0.Name.."."..motorHier
				motor = foundNextMotor
			end
		end

		-- build final table
		local function GetPoseHierarchy(Pose)
			local str = Pose.Name
			while (Pose.Parent and Pose.Parent.ClassName == "Pose") do
				Pose = Pose.Parent
				str = Pose.Name.."."..str
			end
			return str
		end

		local final = {}
		local maxLength = 0

		for _, Keyframe in pairs(target:GetChildren()) do
			if Keyframe.ClassName == "Keyframe" then

				local frmPos = math.floor(Keyframe.Time * fps + 0.5)
				if frmPos > maxLength then
					maxLength = frmPos
				end

				for _, Pose in pairs(Keyframe:GetDescendants()) do
					if Pose.ClassName == "Pose" and Pose:FindFirstChild("xSIXxNull") == nil and Pose.Parent ~= Keyframe then
						local motor = motorMap[GetPoseHierarchy(Pose)] -- {debug id, motor}
						if motor then
							local debugId = motor[1]
							motor = motor[2]

							if final[debugId] == nil then
								final[debugId] = {Motor = motor, TargetValues = {}, Easing = {}}
							end
							
							if Pose.Weight > 0 then
								final[debugId].TargetValues[frmPos] = Pose.CFrame
							end

							if Pose:FindFirstChild("Ease") then
								local ease = global.Objects.Ease.Deserialize(Pose.Ease) -- bad, temp object.
								final[debugId].Easing[frmPos] = ease:Tableize()
								ease:Destroy()
							elseif Pose:FindFirstChild("xSIXxCustomStyle") then
								final[debugId].Easing[frmPos] = {_tblType = "Ease", ease_type = Pose.xSIXxCustomStyle.Value, params = {Direction = Pose.xSIXxCustomDir.Value}}
							elseif Pose.EasingStyle.Name ~= "Linear" then
								final[debugId].Easing[frmPos] = {_tblType = "Ease", ease_type = Pose.EasingStyle.Name, params = {Direction = Pose.EasingDirection.Name}}
							else
								final[debugId].Easing[frmPos] = global.Objects.Ease.LINEAR_tbl()
							end

						end

					end
				end

			end
		end

		return final, maxLength
	end 
end
------------------------------------------------------------
-- windows
do
	global.Windows = {}

	for _, window in pairs(script.Parent.Windows:GetChildren()) do
		global.Windows[window.Name] = require(window)
	end
	global.Themer:SetTheme(global.Themer._BuiltInThemes.Default)
end
------------------------------------------------------------
-- version check
do
	pcall(function()
		local verLabel = global.Windows.MoonAnimator.UI.TitleBar.TitleButtons.Version.Label
		verLabel.Text = "v"..tostring(global.ver)

		local verCheck = game:GetService("MarketplaceService"):GetProductInfo(4725618216).Description

		if verCheck then
			local _, checkVer = string.find(verCheck, "!V")

			if checkVer then
				local theVer = tonumber(string.sub(verCheck, checkVer + 1))

				if theVer > global.ver then
					verLabel.Text = verLabel.Text.." [OUT OF DATE, NEW v"..tostring(theVer).."]"
					verLabel.TextColor3 = Color3.new(1, 0, 0)
					verLabel.Parent.Visible = true
				elseif theVer < global.ver then
					verLabel.Text = verLabel.Text.." [PREVIEW, CURRENT v"..tostring(theVer).."]"
					verLabel.TextColor3 = Color3.new(0, 1, 0)
					verLabel.Parent.Visible = true
				end
			end
		end
	end)
end
------------------------------------------------------------
-- buttons
do
	local create = {
		pluginToolbar:CreateButton("",
			"Moon\nAnimator\n------------",
			"http://www.roblox.com/asset/?id=4725619926"),
		pluginToolbar:CreateButton("",
			"File\nExplorer\n------------",
			"http://www.roblox.com/asset/?id=4572599969"),
		pluginToolbar:CreateButton("",
			"Character\nInserter\n------------",
			"http://www.roblox.com/asset/?id=4049942026"),
		pluginToolbar:CreateButton("",
			"Easy\nWeld\n------------",
			"http://www.roblox.com/asset/?id=4657420207"),
	}
	
	local buttons = {
		but_MoonAnimator = create[1],
		but_FileExplorer = create[2],
		but_CharacterInserter = create[3],
		but_Welder = create[4],
	}
	
	for name, but in pairs(buttons) do
		local window_name = name:sub(5)
		but.Click:Connect(function()
			but:SetActive(false)
			global.Windows[window_name]:Toggle()
		end)
	end
	
	local SavedTheme = global.plugin:GetSetting("xSIXx_SavedTheme")
	if SavedTheme ~= nil then
		global.Themer:SetTheme(SavedTheme)
	end

	global.ready = true
end
