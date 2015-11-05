require("warofexalted")

--Put links to Lua modifiers here
function WarOfExalted:LinkModifiers()

    --Core game modifiers
    LinkLuaModifier("modifier_client_side_init", "modifiers/modifier_client_side_init", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_base", "modifiers/modifier_base", LUA_MODIFIER_MOTION_NONE) -- Note: this needs to be linked before most other modifiers
    LinkLuaModifier("modifier_woe_stamina_regenerator", "modifiers/modifier_woe_stamina_regenerator", LUA_MODIFIER_MOTION_NONE)
    --LinkLuaModifier("modifier_woe_attributes", "modifiers/modifier_woe_attributes", LUA_MODIFIER_MOTION_NONE) 
end