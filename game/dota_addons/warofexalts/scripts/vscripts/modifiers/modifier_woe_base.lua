modifier_woe_base = class({})


--default handling
local default = function(key, modifier, keys)
    if keys[key] == nil then
        if modifier[key] ~= nil then
            modifier["_" .. key] = modifier[key](modifier)
        end
    else
        modifier["_" .. key] = keys[key]
    end
end

--default handling for keys with a "get" function
local getDefault = function(key, modifier, keys)
    if keys[key] == nil then
        if modifier[key] ~= nil then
            modifier["_" .. key] = modifier["Get" .. key](modifier)
        end
    else
        modifier["_" .. key] = keys[key]
    end
end

function modifier_woe_base:Init(keys)
    --util.printTable(keys)
    getDefault("Attributes", self, keys)
    getDefault("AuraRadius", self, keys)
    getDefault("AuraSearchFlags", self, keys)
    getDefault("AuraSearchTeam", self, keys)
    getDefault("AuraSearchType", self, keys)
    getDefault("EffectAttachType", self, keys)
    getDefault("EffectName", self, keys)
    getDefault("StatusEffectName", self, keys)
    getDefault("Texture", self, keys)
    default("HeroEffectPriority", self, keys)
    default("StatusEffectPriority", self, keys)
    default("IsAuraActiveOnDeath", self, keys)
    default("AllowIllusionDuplicate", self, keys)
    default("DestroyOnExpire", self, keys)
    default("IsDebuff", self, keys)
    default("IsHidden", self, keys)
    default("IsPurgable", self, keys)
    default("IsPurgeException", self, keys)
    default("IsStunDebuff", self, keys)
    default("RemoveOnDeath", self, keys)
    
    --event handlers (note: these cannot be passed in via AddNewModifier)
    self.GetAuraEntityReject = keys.GetAuraEntityReject or self.GetAuraEntityReject or function() return true end
    self.OnDestroy = keys.OnDestroy or self.OnDestroy
    self.OnIntervalThink = keys.OnIntervalThink or self.OnIntervalThink
    self.OnRefresh = keys.OnRefresh or self.OnRefresh
    self.OnCreated = keys.OnCreated or self.OnCreated

    --smart IsAura defaulting based on existence of aura-related keys
    if keys.IsAura ~= nil then
        self._IsAura = keys._IsAura
    else
        self._IsAura = keys.AuraSearchFlags ~= nil or keys.AuraSearchTeam ~= nil or keys.AuraSearchType ~= nil 
                           or keys.AuraRadius  ~= nil or keys.AuraEntityReject ~= nil or keys.IsAuraActiveOnDeath ~= nil
    end
    
    function self:AllowIllusionDuplicate()
        return self._AllowIllusionDuplicate and self._AllowIllusionDuplicate ~= 0
    end

    function self:GetHeroEffectName()
        return self._HeroEffectName
    end

    function self:GetEffectName()
        return self._EffectName
    end

    function self:GetEffectAttachType()
        return self._EffectAttachType
    end

    function self:GetStatusEffectName()
        return self._StatusEffectName
    end
    
    function self:GetselfAura()
        return self._selfAura
    end
    
    function self:GetAuraSearchFlags()
        return self._AuraSearchFlags
    end
    
    function self:GetAuraSearchTeam()
        return self._AuraSearchTeam
    end
    
    function self:GetAuraSearchType()
        return self._AuraSearchType
    end
    
    function self:GetAuraRadius()
        return self._AuraRadius
    end
    
    function self:GetAttributes()
        return self._Attributes
    end
    
    function self:DestroyOnExpire()
        return self._DestroyOnExpire and self._DestroyOnExpire ~= 0
    end
    
    function self:GetTexture()
        return self._Texture
    end
    
    function self:HeroEffectPriority()
        return self._HeroEffectPriority
    end
    
    function self:IsAura()
        return self._IsAura and self._IsAura ~= 0
    end
    
    function self:IsAuraActiveOnDeath()
        return self._IsAuraActiveOnDeath and self._IsAuraActiveOnDeath ~= 0
    end
    
    function self:IsDebuff()
        return self._IsDebuff and self._IsDebuff ~= 0
    end
    
    function self:IsHidden()
        return self._IsHidden and self._IsHidden ~= 0
    end

    function self:IsPurgable()
        return self._IsPurgable and self._IsPurgable ~= 0
    end

    function self:IsPurgeException()
        return self._IsPurgeException and self._IsPurgeException ~= 0
    end

    function self:IsStunDebuff()
        return self._IsStunDebuff and self._IsStunDebuff ~= 0
    end
    
    function self:RemoveOnDeath()
        return self._RemoveOnDeath and self._RemoveOnDeath ~= 0
    end
    
    function self:StatusEffectPriority()
        return self._StatusEffectPriority
    end
end

function modifier_woe_base:WoeProperties(props)
    self._WoeProperties = props
end