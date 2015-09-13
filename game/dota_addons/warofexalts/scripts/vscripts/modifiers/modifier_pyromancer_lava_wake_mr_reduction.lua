modifier_pyromancer_lava_wake_mr_reduction = class({})
--require('lua_modifier_utils')
--require('woe_damage')

function modifier_pyromancer_lava_wake_mr_reduction:OnCreated(keys)
    if IsServer() then
        --print("OnCreated")
        keys.IsDebuff = true
        keys.IsPurgable = true
        self.value = keys.value or 0
        self.affected = self:GetParent()
        self.affected:SetWoeMagicResistBonus(self.affected:GetWoeMagicResistBonus() - self.value)
        InitModifier(self, keys)
    end
end

function modifier_pyromancer_lava_wake_mr_reduction:OnDestroy()
    if IsServer() then
        --print("OnDestroy")
        self.affected:SetWoeMagicResistBonus(self.affected:GetWoeMagicResistBonus() + self.value)
    end
end

function modifier_pyromancer_lava_wake_mr_reduction:OnRefresh()
    --print("OnRefresh")
end
