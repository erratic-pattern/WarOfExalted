modifier_base = class({})

function modifier_base:Properties(propTable)
    --[[ Adds a table of property handlers to this modifier.
    
        Inputs:
            propTable - a table of string names pointing to functions, where the strings represent custom property names that were previously defined via Property() calls (see property.lua docs), and the functions
                        are property handlers that get called when the associated property needs to be recomputed. The handler function has the following format:
                        
                        Input parameters: (modifier, paramsTable)
                        Return value: a computed value for the property. How this value is used depends on the property itself.
                        
                        For convenience, you can also use a non-function value as the property handler, which is equivalent to defining a handler function that simply
                        returns a constant value and does nothing else.
    ]]
    if self._propHandlers == nil then
        self._propHandlers = { }
    end
    for k, v in pairs(propTable) do
        self._propHandlers[k] = v
    end
end

function modifier_base:DeleteProperties(propList)
    --[[ Clears custom property handlers for this modifier
    
        Inputs:
            propList - (optional) An array of strings indicating property names to remove. If not provided, we clear
                       all property handlers
    ]]
    if self._propHandlers == nil then
        self._propHandlers = { }
    end
    if propList == nil then
        self._propHandlers = { }
    else
        for _, key in ipairs(propList) do
            self._propHandlers[key] = nil
        end
    end
end

function modifier_base:Init(keys)

    function self:OnCreated(params, ...)
        self._params = params
        if keys.OnCreated ~= nil then
            keys.OnCreated(self, params, ...)
        end
    end
    
    function self:OnDestroy(...)
        self._params = nil
        if keys.OnDestroy ~= nil then
            keys.OnDestroy(self, ...)
        end
    end

    --smart IsAura defaulting based on existence of aura-related keys
    if keys.IsAura == nil then
        keys.IsAura = keys.AuraSearchFlags ~= nil or keys.AuraSearchTeam ~= nil or keys.AuraSearchType ~= nil 
                       or keys.AuraRadius  ~= nil or keys.AuraEntityReject ~= nil or keys.IsAuraActiveOnDeath ~= nil
                       or keys.ModifierAura ~= nil
    end
    
    if type(keys.AllowIllusionDuplicate) == "function" then
        self.AllowIllusionDuplicate = keys.AllowIllusionDuplicate
    elseif keys.AllowIllusionDuplicate~= nil then
        function self:AllowIllusionDuplicate()
            return keys.AllowIllusionDuplicate and keys.AllowIllusionDuplicate ~= 0
        end
    end
    
    if type(keys.HeroEffectName) == "function" then
        self.HeroEffectName = keys.HeroEffectName
    elseif keys.HeroEffectName~= nil then
        function self:GetHeroEffectName()
            return keys.HeroEffectName
        end
    end
    
    if type(keys.EffectName) == "function" then
        self.GetEffectName = keys.EffectName
    elseif keys.EffectName~= nil then
        function self:GetEffectName()
            return keys.EffectName
        end
    end
    
    if type(keys.EffectAttachType) == "function" then
        self.GetEffectAttachType = keys.EffectAttachType
    elseif keys.EffectAttachType~= nil then
        function self:GetEffectAttachType()
            return keys.EffectAttachType
        end
    end
    
    if type(keys.StatusEffectName) == "function" then
        self.GetStatusEffectName = keys.StatusEffectName
    elseif keys.StatusEffectName~= nil then
        function self:GetStatusEffectName()
            return keys.StatusEffectName
        end
    end
    
    if type(keys.ModifierAura) == "function" then
        self.GetModifierAura = keys.ModifierAura
    elseif keys.ModifierAura~= nil then
        function self:GetModifierAura()
            return keys.ModifierAura
        end
    end
    
    if type(keys.AuraSearchFlags) == "function" then
        self.GetAuraSearchFlags = keys.AuraSearchFlags
    elseif keys.AuraSearchFlags~= nil then
        function self:GetAuraSearchFlags()
            return keys.AuraSearchFlags
        end
    end
    
    if type(keys.AuraSearchTeam) == "function" then
        self.GetAuraSearchTeam = keys.AuraSearchTeam
    elseif keys.AuraSearchTeam~= nil then
        function self:GetAuraSearchTeam()
            return keys.AuraSearchTeam
        end
    end
    
    if type(keys.AuraSearchType) == "function" then
        self.GetAuraSearchType = keys.AuraSearchType
    elseif keys.AuraSearchType~= nil then
        function self:GetAuraSearchType()
            return keys.AuraSearchType
        end
    end
    
    if type(keys.AuraRadius) == "function" then
        self.GetAuraRadius = keys.AuraRadius
    elseif keys.AuraRadius~= nil then
        function self:GetAuraRadius()
            return keys.AuraRadius
        end
    end
    
    if type(keys.Attributes) == "function" then
        self.GetAttributes = keys.Attributes
    elseif keys.Attributes~= nil then
        function self:GetAttributes()
            return keys.Attributes
        end
    end
    
    if type(keys.DestroyOnExpire) == "function" then
        self.DestroyOnExpire = keys.DestroyOnExpire
    elseif keys.DestroyOnExpire~= nil then
        function self:DestroyOnExpire()
            return keys.DestroyOnExpire and keys.DestroyOnExpire ~= 0
        end
    end
    
    if type(keys.Texture) == "function" then
        self.GetTexture = keys.Texture
    elseif keys.Texture~= nil then
        function self:GetTexture()
            return keys.Texture
        end
    end
    
    if type(keys.HeroEffectPriority) == "function" then
        self.HeroEffectPriority = keys.HeroEffectPriority
    elseif keys.HeroEffectPriority~= nil then
        function self:HeroEffectPriority()
            return keys.HeroEffectPriority
        end
    end
    
    if type(keys.IsAura) == "function" then
        self.IsAura = keys.IsAura
    elseif keys.IsAura~= nil then
        function self:IsAura()
            return keys.IsAura and keys.IsAura ~= 0
        end
    end
    
    if type(keys.IsAuraActiveOnDeath) == "function" then
        self.IsAuraActiveOnDeath = keys.IsAuraActiveOnDeath
    elseif keys.IsAuraActiveOnDeath~= nil then
        function self:IsAuraActiveOnDeath()
            return keys.IsAuraActiveOnDeath and keys.IsAuraActiveOnDeath ~= 0
        end
    end
    
    if type(keys.IsDebuff) == "function" then
        self.IsDebuff = keys.IsDebuff
    elseif keys.IsDebuff~= nil then
        function self:IsDebuff()
            return keys.IsDebuff and keys.IsDebuff ~= 0
        end
    end
    
    if type(keys.IsHidden) == "function" then
        self.IsHidden = keys.IsHidden
    elseif keys.IsHidden~= nil then
        function self:IsHidden()
            return keys.IsHidden and keys.IsHidden ~= 0
        end
    end
    
    if type(keys.IsPurgable) == "function" then
        self.IsPurgable = keys.IsPurgable
    elseif keys.IsPurgable~= nil then
        function self:IsPurgable()
            return keys.IsPurgable and keys.IsPurgable ~= 0
        end
    end
    
    if type(keys.IsPurgeException) == "function" then
        self.IsPurgeException = keys.IsPurgeException
    elseif keys.IsPurgeException~= nil then
        function self:IsPurgeException()
            return keys.IsPurgeException and keys.IsPurgeException ~= 0
        end
    end
    
    if type(keys.IsStunDebuff) == "function" then
        self.IsStunDebuff = keys.IsStunDebuff
    elseif keys.IsStunDebuff~= nil then
        function self:IsStunDebuff()
            return keys.IsStunDebuff and keys.IsStunDebuff ~= 0
        end
    end
    
    if type(keys.RemoveOnDeath) == "function" then
        self.RemoveOnDeath = keys.RemoveOnDeath
    elseif keys.RemoveOnDeath~= nil then
        function self:RemoveOnDeath()
            return keys.RemoveOnDeath and keys.RemoveOnDeath ~= 0
        end
    end
    
    if type(keys.StatusEffectPriority) == "function" then
        self.StatusEffectPriority = keys.StatusEffectPriority
    elseif keys.StatusEffectPriority~= nil then
        function self:StatusEffectPriority()
            return keys.StatusEffectPriority
        end
    end
    
    if type(keys.AuraEntityReject) == "function" then
        self.GetAuraEntityReject = keys.AuraEntityReject
    elseif keys.AuraEntityReject~= nil then
        function self:GetAuraEntityReject(...)
            return keys.GetAuraEntityReject(self, ...)
        end
    end
    
    if type(keys.OnRefresh) == "function" then
        self.OnRefresh = keys.OnRefresh
    elseif keys.OnRefresh~= nil then
        function self:OnRefresh(...)
            keys.OnRefresh(self, ...)
        end
    end
    
    if type(keys.OnIntervalThink) == "function" then
        self.OnIntervalThink = keys.OnIntervalThink
    elseif keys.OnIntervalThink~= nil then
        function self:OnIntervalThink(...)
            keys.OnIntervalThink(self, ...)
        end
    end
    
    if type(keys.DeclareFunctions) == "function" then
        self.DeclareFunctions = keys.DeclareFunctions
    elseif keys.DeclareFunctions~= nil then
        function self:DeclareFunctions(...)
            return keys.DeclareFunctions
        end
    end
    
    if type(keys.CheckState) == "function" then
        self.CheckState = keys.CheckState
    elseif keys.CheckState~= nil then
        function self:CheckState(...)
            keys.CheckState(self, ...)
        end
    end
    
    --add custom property handlers to the modifier
    if keys.Properties ~= nil then
        self:Properties(keys.Properties)
        keys.Properties = nil --prevents Properties field from being copied into modifier's table
    end
    
    --copy remaining input keys into modifier's table
    for k, v in pairs(keys) do
        if self[k] == nil then
            self[k] = v
        end
    end
end

