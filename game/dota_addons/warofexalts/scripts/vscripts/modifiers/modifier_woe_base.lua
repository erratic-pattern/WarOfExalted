modifier_woe_base = class({})

function modifier_woe_base:WoeProperties(props)
    self._woeProperties = props
end

function modifier_woe_base:Init(keys)

    function self:OnCreated(params, ...)
        self._params = params
        if keys.OnCreated ~= nil then
            keys.OnCreated(self, params, ...)
        end
    end

    --smart IsAura defaulting based on existence of aura-related keys
    if keys.IsAura == nil then
        keys.IsAura = keys.AuraSearchFlags ~= nil or keys.AuraSearchTeam ~= nil or keys.AuraSearchType ~= nil 
                       or keys.AuraRadius  ~= nil or keys.AuraEntityReject ~= nil or keys.IsAuraActiveOnDeath ~= nil
                       or keys.ModifierAura ~= nil
    end
    
    if keys.AllowIllusionDuplicate ~= nil then
        function self:AllowIllusionDuplicate()
            return keys.AllowIllusionDuplicate and keys.AllowIllusionDuplicate ~= 0
        end
    end
    
    if keys.GetHeroEffectName ~= nil then
        function self:GetHeroEffectName()
            return keys.HeroEffectName
        end
    end
    
    if keys.GetEffectName ~= nil then
        function self:GetEffectName()
            return keys.EffectName
        end
    end
    
    if keys.GetEffectAttachType ~= nil then
        function self:GetEffectAttachType()
            return keys.EffectAttachType
        end
    end
    
    if keys.GetStatusEffectName ~= nil then
        function self:GetStatusEffectName()
            return keys.StatusEffectName
        end
    end
    
    if keys.GetModifierAura ~= nil then
        function self:GetModifierAura()
            return keys.ModifierAura
        end
    end
    
    if keys.GetAuraSearchFlags ~= nil then
        function self:GetAuraSearchFlags()
            return keys.AuraSearchFlags
        end
    end
    
    if keys.GetAuraSearchTeam ~= nil then
        function self:GetAuraSearchTeam()
            return keys.AuraSearchTeam
        end
    end
    
    if keys.GetAuraSearchType ~= nil then
        function self:GetAuraSearchType()
            return keys.AuraSearchType
        end
    end
    
    if keys.GetAuraRadius ~= nil then
        function self:GetAuraRadius()
            return keys.AuraRadius
        end
    end
    
    if keys.GetAttributes ~= nil then
        function self:GetAttributes()
            return keys.Attributes
        end
    end
    
    if keys.DestroyOnExpire ~= nil then
        function self:DestroyOnExpire()
            return keys.DestroyOnExpire and keys.DestroyOnExpire ~= 0
        end
    end
    
    if keys.GetTexture ~= nil then
        function self:GetTexture()
            return keys.Texture
        end
    end
    
    if keys.HeroEffectPriority ~= nil then
        function self:HeroEffectPriority()
            return keys.HeroEffectPriority
        end
    end
    
    if keys.IsAura ~= nil then
        function self:IsAura()
            return keys.IsAura and keys.IsAura ~= 0
        end
    end
    
    if keys.IsAuraActiveOnDeath ~= nil then
        function self:IsAuraActiveOnDeath()
            return keys.IsAuraActiveOnDeath and keys.IsAuraActiveOnDeath ~= 0
        end
    end
    
    if keys.IsDebuff ~= nil then
        function self:IsDebuff()
            return keys.IsDebuff and keys.IsDebuff ~= 0
        end
    end
    
    if keys.IsHidden ~= nil then
        function self:IsHidden()
            return keys.IsHidden and keys.IsHidden ~= 0
        end
    end
    
    if keys.IsPurgable ~= nil then
        function self:IsPurgable()
            return keys.IsPurgable and keys.IsPurgable ~= 0
        end
    end
    
    if keys.IsPurgeException ~= nil then
        function self:IsPurgeException()
            return keys.IsPurgeException and keys.IsPurgeException ~= 0
        end
    end
    
    if keys.IsStunDebuff ~= nil then
        function self:IsStunDebuff()
            return keys.IsStunDebuff and keys.IsStunDebuff ~= 0
        end
    end
    
    if keys.RemoveOnDeath ~= nil then
        function self:RemoveOnDeath()
            return keys.RemoveOnDeath and keys.RemoveOnDeath ~= 0
        end
    end
    
    if keys.StatusEffectPriority ~= nil then
        function self:StatusEffectPriority()
            return keys.StatusEffectPriority
        end
    end
    
    if keys.GetAuraEntityReject ~= nil then
        function self:GetAuraEntityReject(...)
            return keys.GetAuraEntityReject(self, ...)
        end
    end
    
    if keys.OnRefresh ~= nil then
        function self:OnRefresh(...)
            keys.OnRefresh(self, ...)
        end
    end
    
    if keys.OnIntervalThink ~= nil then
        function self:OnIntervalThink(...)
            keys.OnIntervalThink(self, ...)
        end
    end
    
    
    function self:OnDestroy(...)
        self._params = nil
        if keys.OnDestroy ~= nil then
            keys.OnDestroy(self, ...)
        end
    end
    
    if keys.DeclareFunctions ~= nil then
        function self:DeclareFunctions(...)
            keys.DeclareFunctions(self, ...)
        end
    end
    
    if keys.CheckState ~= nil then
        function self:CheckState(...)
            keys.CheckState(self, ...)
        end
    end
end

