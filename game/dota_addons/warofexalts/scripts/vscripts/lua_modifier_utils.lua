function InitLuaModifier(modifier, keys)
    util.printTable(keys)
    modifier._AllowIllusionDuplicate = keys.AllowIllusionDuplicate
    modifier._DestroyOnExpire = keys.DestroyOnExpire
    modifier._Attributes = keys.Attributes
    modifier._AuraEntityReject = keys.AuraEntityReject or modifier.GetAuraEntityReject
    modifier._AuraRadius = keys.AuraRadius
    modifier._AuraSearchFlags = keys.AuraSearchFlags
    modifier._AuraSearchTeam = keys.AuraSearchTeam
    modifier._AuraSearchType = keys.AuraSearchType
    modifier._EffectAttachType = keys.EffectAttachType
    modifier._EffectName = keys.EffectName
    modifier._StatusEffectName = keys.StatusEffectName
    modifier._Texture = keys.Texture
    modifier._HeroEffectPriority = keys.HeroEffectPriority
    modifier._IsAuraActiveOnDeath = keys.IsAuraActiveOnDeath
    if keys.IsAura ~= nil then
        modifier._IsAura = keys._IsAura
    else
        modifier._IsAura = modifier._AuraSearchFlags ~= nil or modifier._AuraSearchTeam ~= nil or modifier._AuraSearchType ~= nil 
                           or modifier._AuraRadius  ~= nil or keys.AuraEntityReject ~= nil or modifier._IsAuraActiveOnDeath ~= nil
    end
    modifier._IsDebuff = keys.IsDebuff
    modifier._IsHidden = keys.IsHidden
    modifier._IsPurgable = keys.IsPurgable
    modifier._IsPurgeException = keys.IsPurgeException
    modifier._IsStunDebuff = keys.IsStunDebuff
    modifier._RemoveOnDeath = keys.RemoveOnDeath
    modifier._StatusEffectPriority = keys.StatusEffectPriority
    
    modifier.OnDestroy = keys.OnDestroy or modifier.OnDestroy
    modifier.OnIntervalThink = keys.OnIntervalThink or modifier.OnIntervalThink
    modifier.OnRefresh = keys.OnRefresh or modifier.OnRefresh

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
    
    function modifier:GetAuraEntityReject(ent)
        return self._AuraEntityReject(ent)
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
    return modifier
end