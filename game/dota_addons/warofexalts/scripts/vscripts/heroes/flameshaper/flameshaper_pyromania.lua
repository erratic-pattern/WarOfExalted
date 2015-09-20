flameshaper_pyromania = class({})
local modName = "modifier_flameshaper_pyromania"
LinkLuaModifier(modName, "modifiers/" .. modName, LUA_MODIFIER_MOTION_NONE)
function flameshaper_pyromania:GetIntrinsicModifierName()
    return modName
end