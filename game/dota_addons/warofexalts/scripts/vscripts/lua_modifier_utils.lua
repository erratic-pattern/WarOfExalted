function InitDotModifier(modifier, keys)
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
    keys.Victim = keys.Victim or modifier:GetParent()
    keys.Attacker = keys.Attacker or modifier:GetCaster()
    keys.Ability = keys.Ability or modifier:GetAbility()
    keys.OnIntervalThink = function(modifier)
        modifier.Damage:Apply()
    end
    modifier.Damage = keys.Damage or WoeDamage(keys)
    modifier.Damage:GetKeywords():Add("dot")
    InitModifier(modifier, keys)
end