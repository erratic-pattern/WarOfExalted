require("modifiers/modifier_base")
modifier_woe_attributes = class({}, nil, modifier_base)

SS_PER_AGI = 0.5           -- amount of spell speed increased per point of agility
MR_PER_INT = 0.14          -- amount of base magic resist increased per point of intelligence
STAM_PER_AGI = 5           -- amount of max stamina increased per point of agi


modifier_woe_attributes:Init({
    Attributes = MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE,
    IsHidden = true,
    IsPurgable = false,
    ExpireOnDeath = false,
    DeclareFunctions = {
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
    },
    OnCreated = function(self)
        self.BaseProjectileSpeed = self:GetProjectileSpeed()
    end
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
    end
})

function modifier_woe_attributes:GetModifierProjectileSpeedBonus(params)
    if IsServer() then
        print("GetModifierProjectileSpeedBonus")
        util.printTable(params)
        return self:GetParent():GetProjectileSpeedModifier() * self.BaseProjectileSpeed
    end
end