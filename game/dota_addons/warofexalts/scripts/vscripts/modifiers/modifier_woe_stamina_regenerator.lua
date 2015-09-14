require("modifiers/modifier_woe_base")
modifier_woe_stamina_regenerator = class({}, nil, modifier_woe_base)

modifier_woe_stamina_regenerator:Init({
    Attributes = MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE,
    IsHidden = true,
    IsPurgable = false,
    ExpireOnDeath = false,
})

function modifier_woe_stamina_regenerator:OnCreated(keys)
    if IsServer() then
        self.Interval = keys.Interval or 0.01
        self:StartIntervalThink(self.Interval)
    end
end

function modifier_woe_stamina_regenerator:OnIntervalThink()
    if IsServer() then
        local unit = self:GetParent()
        local sMax = unit:GetMaxStamina()
        if sMax > unit:GetStamina() then 
            local stamPerSec = unit:GetStaminaRegen()
            if unit:IsStaminaRecharging() then
                stamPerSec = stamPerSec + unit:GetMaxStamina() * unit:GetStaminaRechargeRate()
            end
            unit:SetStamina(unit:GetStamina() + self.Interval * stamPerSec)
        end
    end
end
