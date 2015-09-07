modifier_woe_dot = class({})
--require('lua_modifier_utils')
--require('woe_damage')

function modifier_woe_dot:OnCreated(keys)
    if IsServer() then
        keys.ThinkInterval = keys.ThinkInterval or keys.Interval or 0.5
        if keys.IsPurgable == nil then
            keys.IsPurgable = true
        end
        if keys.RemoveOnDeath == nil then
            keys.RemoveOnDeath = true
        end
        if keys.DestroyOnExpire == nil then
            keys.DestroyOnExpire = true
        end
        keys.Victim = keys.Victim or self:GetParent()
        keys.Attacker = keys.Attacker or self:GetCaster()
        keys.Ability = keys.Ability or self:GetAbility()
        self.Damage = keys.Damage or WoeDamage(keys)
        self.Damage:GetKeywords():Add("dot")
        InitLuaModifier(self, keys)
        self.total = WoeDamage()
        if self.x == nil then
            self.x = 0
        end
    end
end

function modifier_woe_dot:OnIntervalThink()
    if IsServer() then
        self.total = self.total:Combine(self.Damage)
        self.Damage:Apply()
    end
end
