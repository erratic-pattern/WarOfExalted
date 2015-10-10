require("modifiers/modifier_base")

modifier_glaivedancer_frost_glaives_slow = class({}, nil, modifier_base)

modifier_glaivedancer_frost_glaives_slow:Init({
	IsHidden = false,
	IsPurgable = true,
	IsDebuff = true,
	DeclareFunctions = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	},
	GetModifierMoveSpeedBonus_Percentage = function(self, keys)
		return -self.slow_amount*100
	end,
	OnCreated = function(self, keys)
		for k,v in pairs(keys) do
			self[k] = v
		end
	end
})