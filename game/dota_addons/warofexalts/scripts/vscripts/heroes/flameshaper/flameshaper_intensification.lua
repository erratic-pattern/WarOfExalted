flameshaper_intensification = class({})
local modName = "modifier_flameshaper_intensification"
LinkLuaModifier(modName, "modifiers/" .. modName, LUA_MODIFIER_MOTION_NONE)
function flameshaper_intensification:GetIntrinsicModifierName()
    return modName
end