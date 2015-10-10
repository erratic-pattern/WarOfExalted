glaivedancer_frost_glaives = class({})

local modBuffName = "modifier_glaivedancer_frost_glaives_buff"
LinkLuaModifier(modBuffName, "modifiers/" .. modBuffName, LUA_MODIFIER_MOTION_NONE)

local modDebuffName = "modifier_glaivedancer_frost_glaives_slow"
LinkLuaModifier(modDebuffName, "modifiers/" .. modDebuffName, LUA_MODIFIER_MOTION_NONE)

function glaivedancer_frost_glaives:OnSpellStart()
	local caster = self:GetCaster()
	local data = self:GetSpecials()
	caster:AddNewModifier(caster, self, modBuffName, {
		duration = data.buff_duration,
		slow_amount = data.glaive_slow_amount,
		slow_duration = data.glaive_slow_duration,
	})
end