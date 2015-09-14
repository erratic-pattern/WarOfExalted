modifier_pyromancer_lava_wake_mr_reduction = class({}, nil, modifier_woe_base)


modifier_pyromancer_lava_wake_mr_reduction:Init(modifier_pyromancer_lava_wake_mr_reduction, {
    IsDebuff = true,
    isPurgable = true,
    StatusEffectName = "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn_creep.vpcf",
    HeroEffectName = "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn.vpcf",
    EffectAttachType = PATTACH_ABSORIGIN_FOLLOW
})

modifier_pyromancer_lava_wake_mr_reduction:WoeProperties({
    MagicResistBonus = function(modifier)
        return -modifier.value
    end
})

function modifier_pyromancer_lava_wake_mr_reduction:OnCreated(keys)
    self.value = keys.value or 0
end
