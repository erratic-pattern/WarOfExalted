if WarOfExalts == nil then
	--print ( '[WAROFEXALTS] creating warofexalts game mode' )
	WarOfExalts = class({})
end

--all behavior flags that specify a targeting behavior
ABILITY_TARGETING_BEHAVIOR = bit.bor(
    DOTA_ABILITY_BEHAVIOR_PASSIVE,
    DOTA_ABILITY_BEHAVIOR_AOE,
    DOTA_ABILITY_BEHAVIOR_NO_TARGET,
    DOTA_ABILITY_BEHAVIOR_POINT
)

function WarOfExalts:WoeAbilityWrapper(abi, extraKeys)  
    if abi.isWoeAbility then return end -- exit if we've already wrapped
    if not extraKeys then
        extraKeys = { }
    end
    local WarOfExalts = self
    
    local abiName = abi:GetAbilityName()
    local isLuaAbility = "ability_lua" == abi:GetClassname()
    if not isLuaAbility then
        print("[WAROFEXALTS] warning: " .. abiName .. " is not a Lua ability. Can't implement all WoE functionality.")
    end
    abi.isWoeAbility = true --flag we can use to easily test if ability is wrapped
    
    --WoE ability instance variables
    abi._woeKeys = {
        StaminaCost = 0,
        SpellSpeedRatio = 1,
        AttackSpeedRatio = 1,
        IsVectorTarget = false,
        AutoDeriveKeywords = true, -- whether or not we derive keywords from dota ability behaviors
        AutoDeriveBehaviors = true -- whether or not we derive behaviors from WoE keywords
    }
    
    --the table of custom data parsed from KV files
    abi._woeDatadriven = WarOfExalts.datadriven.abilities[abiName] or { }
    
    --update our instance variables from KV files and any extra keys that were given
    util.updateTable(abi._woeKeys, abi._woeDatadriven)
    util.updateTable(abi._woeKeys, extraKeys)
    
    abi._woeKeys.Keywords = WoeKeywords(extraKeys.Keywords or abi._woeDatadriven.Keywords) --parse keyword string
    
    -- convenience function that collects all of the ability special fields for the given level (or the casters current level if none)
    function abi:GetSpecials(i)
        local out = { }
        for _, field in pairs(self._woeDatadriven.AbilitySpecial or { }) do
            for k, _ in pairs(field) do
                if k ~= "var_type" then
                    if i == nil then
                        out[k] = self:GetSpecialValueFor(k)
                    else
                        out[k] = self:GetLevelSpecialValueFor(k, i)
                    end
                    break
                end
            end
        end
        return out
    end
    
    function abi:GetKeywords()
        local keys = self._woeKeys.Keywords
        if not self._woeKeys.AutoDeriveKeywords then
            return keys
        end
        local b = self:GetBehavior()
        if self._cachedBehavior == b then --check our cached behaviors. if new behaviors match, return early
            return keys
        end
        self._cachedBehavior = b
        local inFlags = function(...) --bitfield helper function
            return bit.band(b, ...) ~= 0
        end
        --auto-derive keywords from ability behavior flags
        if inFlags(DOTA_ABILITY_BEHAVIOR_AOE) then
            keys:Add("area")
        end
        if inFlags(DOTA_ABILITY_BEHAVIOR_PASSIVE) then
            keys:Add("passive")
        end
        if inFlags(DOTA_ABILITY_BEHAVIOR_ATTACK) and not keys:Has("spell") then
            keys:Add("attack")
        end
        --[[if inFlags(DOTA_ABILITY_BEHAVIOR_AURA) then
            keys.Add("aura")
        end]]
        --[[if inFlags(DOTA_ABILITY_BEHAVIOR_CHANNELLED) then
            keys.Add("channel")
        end]]
        
        return keys
    end
    
    local _GetBehavior = abi.GetBehavior --old GetBehavior
    function abi:GetBehavior() 
        local b = _GetBehavior(self)
        if not self._woeKeys.AutoDeriveBehaviors then
            return b
        end
        local keys = self._woeKeys.Keywords --note: calling self:GetKeywords() will recurse infinitely
        local addFlags = function(...) --bitfield helper function
            b = bit.bor(b, ...)
        end
        --begin behavior auto-deriving
        if keys:Has("movement") then
            addFlags(DOTA_BEHAVIOR_ROOT_DISABLES)
        end
        if keys:Has("passive") then
            addFlags(DOTA_ABILITY_BEHAVIOR_PASSIVE)
        end
        return b
    end
    
    --check dota behavior flags
    function abi:HasBehavior(...)
        return bit.band(self:GetBehavior(), ...) ~= 0
    end
    
    --override CastFilterResult
    local _CastFilterResult = abi.CastFilterResult
    function abi:CastFilterResult()
        return self:CastFilterSpendStamina(_CastFilterResult) 
    end
    
    --override CastFilterResultLocation
    local _CastFilterResultLocation = abi.CastFilterResultLocation
    function abi:CastFilterResultLocation(loc)
        return self:CastFilterSpendStamina(_CastFilterResultLocation, loc)
    end
    
    --override CastFilterResultTarget
    local _CastFilterResultTarget = abi.CastFilterResultTarget
    function abi:CastFilterResultTarget(target)
        return self:CastFilterSpendStamina(_CastFilterResultTarget, target)
    end
    
    --helper function for CastFilters
    function abi:CastFilterSpendStamina(cb, ...)
        if not self:SpendStaminaCost() then --insufficient stamina
            return UF_FAIL_CUSTOM
        elseif cb then
            return cb(self, ...)
        end
        return UF_SUCCESS
    end
     
    --override GetCustomCastError
    local _GetCustomCastError = abi.GetCustomCastError
    function abi:GetCustomCastError()
        return self:GetCustomCastErrorBase(_GetCustomCastError) 
    end
    
    --override GetCustomCastErrorLocation
    local _GetCustomCastErrorLocation = abi.GetCustomCastErrorLocation
    function abi:GetCustomCastErrorLocation(loc)
        return self:GetCustomCastErrorBase(_GetCustomCastErrorLocation, loc)
    end
    
    --override GetCustomCastErrorTarget
    local _GetCustomCastErrorTarget = abi.GetCustomCastErrorTarget
    function abi:GetCustomCastErrorTarget(target)
        return self:GetCustomCastErrorBase(_GetCustomCastErrorTarget, target)
    end
    
    --helper function for GetCustomCastError
    function abi:GetCustomCastErrorBase(cb, ...)
        if not self:CanSpendStaminaCost() then
            return "#woe_cast_error_insufficient_stamina"
        elseif cb then
            return cb(self, ...)
        end
        return ""
    end
    
    function abi:GetStaminaCost()
        return self._woeKeys.StaminaCost
    end
    
    function abi:SetStaminaCost(v)
        self._woeKeys.StaminaCost = v
    end
    
    function abi:SpendStaminaCost()
        caster = caster or self:GetCaster()
        if caster and caster.isWoeUnit then
            return caster:SpendStamina(self:GetStaminaCost())
        end
        return true
    end
    
    function abi:CanSpendStaminaCost()
        caster = self:getCaster()
        if caster and caster.isWoeUnit then
            return caster:CanSpendStamina(self:GetStaminaCost())
        end
        return true
    end
    
    function abi:GetSpellSpeedRatio()
        return self._woeKeys.SpellSpeedRatio
    end
    
    function abi:SetSpellSpeedRatio(v)
        self._woeKeys.SpellSpeedRatio = v
    end
    
    function abi:GetAttackSpeedRatio()
        return self._woeKeys.AttackSpeedRatio
    end
    
    function abi:SetAttackSpeedRatio(v)
        self._woeKeys.AttackSpeedRatio = v
    end
    
    --GetCooldown that existed before wrapper was applied
    abi.GetBaseCooldown = abi.GetCooldown
    
    --gets the total cooldown after all CDR has been calculated
    function abi:GetCooldown(lvl)
        print(self:GetAbilityName() .. ":GetCooldown called")
        if not isLuaAbility then -- remove this if overriding on ability_datadriven suddenly works
            return self:GetBaseCooldown(lvl)
        end
        local caster = self:GetCaster()
        if caster and caster.isWoeUnit then
            local ics = 0
            local keys = self:GetKeywords()
            if keys:Has("attack") then
                ics = caster:GetIncreasedAttackSpeed() * self:GetAttackSpeedRatio()
                print("ias: ", ics)
            elseif keys:Has("spell") then
                ics = caster:GetSpellSpeed() * self:GetSpellSpeedRatio()
                print("SpellSpeed: ", ics)
            end
            local baseCd = self:GetBaseCooldown(lvl)
            print("base cooldown: ", baseCd)
            local cdOut =  baseCd * (1 - caster:GetCdrPercent()) / ((100 + ics) * 0.01)
            print("reduced cooldown: ", cdOut)
            return cdOut
        else
            return self:GetBaseCooldown(lvl)
        end
    end
    
    --[[if abi._woeKeys.IsVectorTarget then
        VectorTargetWrapper(abi)
    end]]
end

