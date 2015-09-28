pyra_pyromania = class({})
local modName = "modifier_pyra_pyromania"
LinkLuaModifier(modName, "modifiers/" .. modName, LUA_MODIFIER_MOTION_NONE)
function pyra_pyromania:GetIntrinsicModifierName()
    return modName
end