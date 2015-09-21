require("modifiers/modifier_base")
modifier_flameshaper_conflagration = class({}, nil, modifier_base)

modifier_flameshaper_conflagration:Init({
    IsHidden = false,
    IsPurgable = false,
    EffectName = "particles/heroes/flameshaper/conflagration.vpcf",
    
    OnCreated = function(self, params)
        self.fireballSpeedBonus = params.fireballSpeedBonus or 0
        self.lavaWakeDurationBonus = params.lavaWakeDurationBonus or 0
        self.lavaWakeLengthBonus = params.lavaWakeLengthBonus or 0
        self.interval = params.interval or 0.1
        self.radius = params.radius or 100
        self.damage = params.damage or 0
        self:StartIntervalThink(self.interval)
    end,
    
    OnIntervalThink = function(self)
        if IsServer() then
            local center = self:GetParent()
            local abil = self:GetAbility()
            local caster = abil:GetCaster()
            local units = FindUnitsInRadius(caster:GetTeam(), center:GetAbsOrigin(), nil, self.radius, abil:GetAbilityTargetTeam(), abil:GetAbilityTargetType(), abil:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
            for _, unit in pairs(units) do
                ApplyWoeDamage({
                    Victim = unit,
                    Attacker = caster,
                    Ability = abil,
                    MagicalDamage = self.damage * self.interval
                })
            end
        end
    end
})