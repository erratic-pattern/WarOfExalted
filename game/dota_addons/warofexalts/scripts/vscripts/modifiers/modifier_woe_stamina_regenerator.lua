DEFAULT_TICK_RATE = 1/30
--print("[WAROFEXALTS] Loading stamina regenerator")
require("modifiers/modifier_base")
modifier_woe_stamina_regenerator = class({}, nil, modifier_base)

modifier_woe_stamina_regenerator:Init({
    Attributes = MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE,
    IsHidden = true,
    IsPurgable = false,
    ExpireOnDeath = false,
    OnCreated = function(self, keys)
        if IsServer() then
            self.Interval = keys.Interval or DEFAULT_TICK_RATE
            self:StartIntervalThink(self.Interval)
        end   
    end,
    OnIntervalThink = function(self)
        if IsServer() then
            local unit = self:GetParent()
            Property.BatchUpdateEvents(unit, function()
                local sMax = unit:GetMaxStamina()
                local sCur = unit:GetStamina()
                if sMax > sCur then
                    local stamPerSec = unit:GetStaminaRegen()
                    if unit:IsStaminaRecharging() then
                        stamPerSec = stamPerSec + sMax * unit:GetStaminaRechargeRate()
                    end
                    unit:SetStamina(sCur + self.Interval * stamPerSec)
                end
            end)
        end  
    end
})
