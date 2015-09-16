require("modifiers/modifier_woe_base")
modifier_pyromancer_lava_wake_mr_reduction = class({}, nil, modifier_woe_base)

modifier_pyromancer_lava_wake_mr_reduction:Init({
    IsDebuff = true,
    IsPurgable = true,
    IsHidden = false,
    EffectName = "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn_creep.vpcf",
    HeroEffectName = "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn.vpcf",
    EffectAttachType = PATTACH_ABSORIGIN_FOLLOW
})

modifier_pyromancer_lava_wake_mr_reduction:WoeProperties({
    MagicResistBonus = function(modifier, params)
        return -params.value
    end
})
