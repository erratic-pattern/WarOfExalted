--default handling
local default = function(key, modifier, keys)
    if keys[key] == nil then
        modifier["_" .. key] = modifier[key](modifier)
    else
        modifier["_" .. key] = keys[key]
    end
end

--default handling for keys with a "get" function
local getDefault = function(key, modifier, keys)
    if keys[key] == nil then
        modifier["_" .. key] = modifier["Get" .. key](modifier)
    else
        modifier["_" .. key] = keys[key]
    end
end

function InitModifier(modifier, keys)
    --util.printTable(keys)
    getDefault("Attributes", modifier, keys)
    getDefault("AuraRadius", modifier, keys)
    getDefault("AuraSearchFlags", modifier, keys)
    getDefault("AuraSearchTeam", modifier, keys)
    getDefault("AuraSearchType", modifier, keys)
    getDefault("EffectAttachType", modifier, keys)
    getDefault("EffectName", modifier, keys)
    getDefault("StatusEffectName", modifier, keys)
    getDefault("Texture", modifier, keys)
    default("HeroEffectPriority", modifier, keys)
    default("StatusEffectPriority", modifier, keys)
    default("IsAuraActiveOnDeath", modifier, keys)
    default("AllowIllusionDuplicate", modifier, keys)
    default("DestroyOnExpire", modifier, keys)
    default("IsDebuff", modifier, keys)
    default("IsHidden", modifier, keys)
    default("IsPurgable", modifier, keys)
    default("IsPurgeException", modifier, keys)
    default("IsStunDebuff", modifier, keys)
    default("RemoveOnDeath", modifier, keys)
    
    --event handlers (note: these cannot be passed in via AddNewModifier)
    modifier.GetAuraEntityReject = keys.GetAuraEntityReject or modifier.GetAuraEntityReject or function() return true end
    modifier.OnDestroy = keys.OnDestroy or modifier.OnDestroy
    modifier.OnIntervalThink = keys.OnIntervalThink or modifier.OnIntervalThink
    modifier.OnRefresh = keys.OnRefresh or modifier.OnRefresh

    --smart IsAura defaulting based on existence of aura-related keys
    if keys.IsAura ~= nil then
        modifier._IsAura = keys._IsAura
    else
        modifier._IsAura = keys.AuraSearchFlags ~= nil or keys.AuraSearchTeam ~= nil or keys.AuraSearchType ~= nil 
                           or keys.AuraRadius  ~= nil or keys.AuraEntityReject ~= nil or keys.IsAuraActiveOnDeath ~= nil
    end
    
    function modifier:AllowIllusionDuplicate()
        return self._AllowIllusionDuplicate and self._AllowIllusionDuplicate ~= 0
    end

    function modifier:GetHeroEffectName()
        return self._HeroEffectName
    end

    function modifier:GetEffectName()
        return self._EffectName
    end

    function modifier:GetEffectAttachType()
        return self._EffectAttachType
    end

    function modifier:GetStatusEffectName()
        return self._StatusEffectName
    end
    
    function modifier:GetModifierAura()
        return self._ModifierAura
    end
    
    function modifier:GetAuraSearchFlags()
        return self._AuraSearchFlags
    end
    
    function modifier:GetAuraSearchTeam()
        return self._AuraSearchTeam
    end
    
    function modifier:GetAuraSearchType()
        return self._AuraSearchType
    end
    
    function modifier:GetAuraRadius()
        return self._AuraRadius
    end
    
    function modifier:GetAttributes()
        return self._Attributes
    end
    
    function modifier:DestroyOnExpire()
        return self._DestroyOnExpire and self._DestroyOnExpire ~= 0
    end
    
    function modifier:GetTexture()
        return self._Texture
    end
    
    function modifier:HeroEffectPriority()
        return self._HeroEffectPriority
    end
    
    function modifier:IsAura()
        return self._IsAura and self._IsAura ~= 0
    end
    
    function modifier:IsAuraActiveOnDeath()
        return self._IsAuraActiveOnDeath and self._IsAuraActiveOnDeath ~= 0
    end
    
    function modifier:IsDebuff()
        return self._IsDebuff and self._IsDebuff ~= 0
    end
    
    function modifier:IsHidden()
        return self._IsHidden and self._IsHidden ~= 0
    end

    function modifier:IsPurgable()
        return self._IsPurgable and self._IsPurgable ~= 0
    end

    function modifier:IsPurgeException()
        return self._IsPurgeException and self._IsPurgeException ~= 0
    end

    function modifier:IsStunDebuff()
        return self._IsStunDebuff and self._IsStunDebuff ~= 0
    end
    
    function modifier:RemoveOnDeath()
        return self._RemoveOnDeath and self._RemoveOnDeath ~= 0
    end
    
    function modifier:StatusEffectPriority()
        return self._StatusEffectPriority
    end
    
    if keys.ThinkInterval ~= nil then
        modifier:StartIntervalThink(keys.ThinkInterval)
    end
    --util.printTable(modifier)
    return modifier
end

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