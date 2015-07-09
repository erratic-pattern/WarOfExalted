if WarOfExalts == nil then
	--print ( '[WAROFEXALTS] creating warofexalts game mode' )
	WarOfExalts = class({})
end

--Put links to Lua modifiers here
function WarOfExalts:LinkModifiers()

    --Core game modifiers
    LinkLuaModifier("modifier_woe_attributes", "modifiers/modifier_woe_attributes", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_woe_stamina_regenerator", "modifiers/modifier_woe_stamina_regenerator", LUA_MODIFIER_MOTION_NONE)
    
end