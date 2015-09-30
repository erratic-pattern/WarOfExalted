-- GREAT UTILITY FUNCTIONS

util = {}

function string.split( str )
	local split = {}
	for i in string.gmatch(str, "%S+") do
		table.insert(split, i)
	end
	return split
end

-- Returns a shallow copy of the passed table.
function util.shallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--update the first table argument's keys with values from the second table argument.
--Note that only keys that are exist in the first table are updated.
function util.updateTable(destTab, srcTab)
    if srcTab == nil or util.isTableEmpty(srcTab) then 
        return
    end
    for k in pairs(destTab) do
        local val = srcTab[k]
        if val ~= nil then
            destTab[k] = srcTab[k]
        end
    end
end

--Merge all (key,value) pairs from the second table argument into the first.
function util.mergeTable(destTab, srcTab)
    if srcTab == nil then
        return
    end
    for k,v in pairs(srcTab) do
        destTab[k] = v
    end
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function util.vectorToString(v)
  return 'x: ' .. v.x .. ' y: ' .. v.y .. ' z: ' .. v.z
end

function util.tableLength( t )
    if t == nil or t == {} then
        return 0
    end
    local len = 0
    for k,v in pairs(t) do
        len = len + 1
    end
    return len
end

function util.isTableEmpty(t)
    return not next(t)
end

-- Remove all abilities on a unit.
function util.clearAbilities( unit )
	for i=0, unit:GetAbilityCount()-1 do
		local abil = unit:GetAbilityByIndex(i)
		if abil ~= nil then
			unit:RemoveAbility(abil:GetAbilityName())
		end
	end
	-- we have to put in dummies and remove dummies so the ability icon changes.
	-- it's stupid but volvo made us
	for i=1,6 do
		unit:AddAbility("warofexalted_empty" .. tostring(i))
	end
	for i=0, unit:GetAbilityCount()-1 do
		local abil = unit:GetAbilityByIndex(i)
		if abil ~= nil then
			unit:RemoveAbility(abil:GetAbilityName())
		end
	end
end

-- goes through a unit's abilities and sets the abil's level to 1,
-- spending an ability point if possible.
function util.initAbilities( hero )
	for i=0, hero:GetAbilityCount()-1 do
		local abil = hero:GetAbilityByIndex(i)
		if abil ~= nil then
			if hero:GetAbilityPoints() > 0 then
				hero:UpgradeAbility(abil)
			else
				abil:SetLevel(1)
			end
		end
	end
end

-- adds ability to a unit, sets the level to 1, then returns ability handle.
function util.addAbilityToUnit(unit, abilName)
	if not unit:HasAbility(abilName) then
		unit:AddAbility(abilName)
	end
	local abil = unit:FindAbilityByName(abilName)
	abil:SetLevel(1)
	return abil
end

function util.getOppositeTeam( unit )
	if unit:GetTeam() == DOTA_TEAM_GOODGUYS then
		return DOTA_TEAM_BADGUYS
	else
		return DOTA_TEAM_GOODGUYS
	end
end

-- returns true 50% of the time.
function util.coinFlip(  )
	return RollPercentage(50)
end

-- theta is in radians.
function util.rotateVector2D(v,theta)
	local xp = v.x*math.cos(theta)-v.y*math.sin(theta)
	local yp = v.x*math.sin(theta)+v.y*math.cos(theta)
	return Vector(xp,yp,v.z):Normalized()
end

function util.printVector(v)
	print(util.vectorToString(v))
end

--Allows input of bit flags as either x | y | z or an array {x, y, z}
function util.normalizeBitFlags(bFlags) 
    if bFlags == nil then
        return 0
    elseif type(bFlags) == 'table' then
        return bit.bor(unpack(bFlags))
    elseif type(bFlags) == 'number' then
        return bFlags
    else
        print("[WAROFEXALTED] Warning: Invalid input for bitfield ", bFlags)
    end
end

-- Given element and list, returns true if element is in the list.
function table.contains( list, element )
	if list == nil then return false end
	for k,v in pairs(list) do
		if k == element then
			return true
		end
	end
	return false
end

-- useful with GameRules:SendCustomMessage
function util.color( sStr, sColor )
	if sStr == nil or sColor == nil then
		return
	end

	--Default is cyan.
	local color = "00FFFF"

	if sColor == "green" then
		color = "ADFF2F"
	elseif sColor == "purple" then
		color = "EE82EE"
	elseif sColor == "blue" then
		color = "00BFFF"
	elseif sColor == "orange" then
		color = "FFA500"
	elseif sColor == "pink" then
		color = "DDA0DD"
	elseif sColor == "red" then
		color = "FF6347"
	elseif sColor == "cyan" then
		color = "00FFFF"
	elseif sColor == "yellow" then
		color = "FFFF00"
	elseif sColor == "brown" then
		color = "A52A2A"
	elseif sColor == "magenta" then
		color = "FF00FF"
	elseif sColor == "teal" then
		color = "008080"
	end
	return "<font color='#" .. color .. "'>" .. sStr .. "</font>"
end


function util.printTable(t, indent, done)
	--print ( string.format ('util.printTable type %s', type(keys)) )
	if type(t) ~= "table" then return end

	done = done or {}
	done[t] = true
	indent = indent or 0

	local l = {}
	for k, v in pairs(t) do
		table.insert(l, k)
	end

	table.sort(l)
	for k, v in ipairs(l) do
		-- Ignore FDesc
		if v ~= 'FDesc' then
			local value = t[v]

			if type(value) == "table" and not done[value] then
				done [value] = true
				print(string.rep ("\t", indent)..tostring(v)..":")
				util.printTable (value, indent + 2, done)
			elseif type(value) == "userdata" and not done[value] then
				done [value] = true
				print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
				util.printTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
			else
				if t.FDesc and t.FDesc[v] then
					print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
				else
					print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
				end
			end
		end
	end
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'
