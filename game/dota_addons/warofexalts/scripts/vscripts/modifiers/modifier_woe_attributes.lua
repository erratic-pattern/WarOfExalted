require("modifiers/modifier_woe_base")
modifier_woe_attributes = class({}, nil, modifier_woe_base)

SS_PER_AGI = 0.5           -- amount of spell speed increased per point of agility
MR_PER_INT = 0.14          -- amount of base magic resist increased per point of intelligence
STAM_PER_AGI = 5           -- amount of max stamina increased per point of agi


modifier_woe_attributes:Init({
    Attributes = MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE,
    IsHidden = true,
    IsPurgable = false,
    ExpireOnDeath = false,
})

modifier_woe_attributes:WoeProperties({
    MagicResistBase = function(m)
        print("MagicResistBase modifier")
        return MR_PER_INT * m:GetParent():GetIntellect()
    end,
    SpellSpeedBase = function(m)
        print("SpellSpeedBase modifier")
        return SS_PER_AGI * m:GetParent():GetAgility()
    end,
    MaxStamina = function(m)
        print("MaxStamina modifier")
        return STAM_PER_AGI * m:GetParent():GetAgility()
    end
})