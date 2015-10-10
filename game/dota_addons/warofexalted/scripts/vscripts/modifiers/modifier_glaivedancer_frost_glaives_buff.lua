require("modifiers/modifier_base")

modifier_glaivedancer_frost_glaives_buff = class({}, nil, modifier_base)

modifier_glaivedancer_frost_glaives_buff:Init({
	IsHidden = false,
	IsPurgable = false,
	OnCreated = function(self, keys)
		for k,v in pairs(keys) do
			self[k] = v
		end
	end
})