require("modifiers/modifier_base")
modifier_woe_attributes = class({}, nil, modifier_base)

SS_PER_AGI = 0.5           -- amount of spell speed increased per point of agility
MR_PER_INT = 0.14          -- amount of base magic resist increased per point of intelligence
STAM_PER_AGI = 5           -- amount of max stamina increased per point of agility
STAM_REGEN_PER_AGI = 0.08  -- amount of flat stamina regen increased per point of agility


modifier_woe_attributes:Init({
    Attributes = MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE,
    IsHidden = true,
    IsPurgable = false,
    ExpireOnDeath = false,
})

modifier_woe_attributes:Properties({
    MagicResistBase = function(m)
        return MR_PER_INT * m:GetParent():GetIntellect()
    end,
    SpellSpeedBase = function(m)
        return SS_PER_AGI * m:GetParent():GetAgility()
    end,
    MaxStamina = function(m)
        return STAM_PER_AGI * m:GetParent():GetAgility()
    end,
    StaminaRegenBase = function(m)
        return STAM_REGEN_PER_AGI * m:GetParent():GetAgility()
    end
})
