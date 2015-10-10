require("warofexalted")

--all behavior flags that specify a targeting behavior
ABILITY_TARGETING_BEHAVIOR = bit.bor(
    DOTA_ABILITY_BEHAVIOR_PASSIVE,
    DOTA_ABILITY_BEHAVIOR_AOE,
    DOTA_ABILITY_BEHAVIOR_NO_TARGET,
    DOTA_ABILITY_BEHAVIOR_POINT
)

function WarOfExalted:WoeAbilityWrapper(abi, extraKeys)  
    if abi.isWoeAbility then return end -- exit if we've already wrapped
    if not extraKeys then
        extraKeys = { }
    end
    local WarOfExalted = self
    
    local abiName = abi:GetAbilityName()
    local isLuaAbility = "ability_lua" == abi:GetClassname()
    if Testing and not isLuaAbility then
        print("[WAROFEXALTED] warning: " .. abiName .. " is not a Lua ability. Can't implement all WoE functionality.")
    end
    abi.isWoeAbility = true --flag we can use to easily test if ability is wrapped
    
    --WoE ability instance variables
    abi._woeKeys = {
        StaminaCost = 0,
        ChannelledStaminaCostPerSecond = 0,
        SpellSpeedRatio = 1,
        AttackSpeedRatio = 1,
        Keywords = "",
        AutoDeriveKeywords = true, -- whether or not we derive keywords from dota ability behaviors
        AutoDeriveBehaviors = true -- whether or not we derive behaviors from WoE keywords
    }
    
    --the table of custom data parsed from KV files
    abi._woeDatadriven = WarOfExalted.datadriven.abilities[abiName] or { }
    
    --update our instance variables from KV files and any extra keys that were given
    util.updateTable(abi._woeKeys, abi._woeDatadriven)
    util.updateTable(abi._woeKeys, extraKeys)
    
    abi._woeKeys.Keywords = WoeKeywords(abi._woeKeys.Keywords) --parse keyword string
    for _, key in pairs({"StaminaCost", "ChannelledStaminaCostPerSecond", "SpellSpeedRatio", "AttackSpeedRatio"}) do -- split these keys by spaces
        abi._woeKeys[key] = string.split(abi._woeKeys[key])
    end
    
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
        if not self:CanPayStaminaCost() then --insufficient stamina
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
        if not self:CanPayStaminaCost() then
            return "#woe_cast_error_insufficient_stamina"
        elseif cb then
            return cb(self, ...)
        end
        return ""
    end

    local _OnAbilityPhaseStart = abi.OnAbilityPhaseStart
    function abi:OnAbilityPhaseStart()
        local result = _OnAbilityPhaseStart(self)
        if self:CanPayStaminaCost() then
            return result
        else
            self:OnAbilityPhaseInterrupted()
            self:SetInAbilityPhase(false)
            return false
        end
    end

    local _OnSpellStart = abi.OnSpellStart
    function abi:OnSpellStart()
        if self:PayStaminaCost() then
            _OnSpellStart(self)
        else
            self:OnAbilityPhaseInterrupted()
            self:SetInAbilityPhase(false)
            self:EndCooldown()
        end
    end
    
    --retrieves a value from an array based on ability levels
    function abi:_GetLevelScalableKey(arr, iLvl)
        local index = math.min(table.getn(arr), self:GetMaxLevel(), iLvl or self:GetLevel())
        return arr[index]
    end
    
    function abi:GetBaseStaminaCost(iLvl)
        return self:_GetLevelScalableKey(self._woeKeys.StaminaCost, iLvl)
    end

    function abi:GetStaminaCost()
        local caster = self:GetCaster()
        local m = 1
        if caster then
            m = 1 + caster:GetStaminaCostModifier()
        end
        return m * self:GetBaseStaminaCost()
    end
    
    function abi:PayStaminaCost()
        caster = caster or self:GetCaster()
        if caster and caster.isWoeUnit then
            return caster:SpendStamina(self:GetStaminaCost(), {ability = self})
        end
        return true
    end
    
    function abi:CanPayStaminaCost()
        caster = self:GetCaster()
        if caster and caster.isWoeUnit then
            return caster:CanSpendStamina(self:GetStaminaCost())
        end
        return true
    end
    
    function abi:GetSpellSpeedRatio(iLvl)
        return self:_GetLevelScalableKey(self._woeKeys.SpellSpeedRatio, iLvl)
    end
    
    function abi:SetSpellSpeedRatio(v)
        self._woeKeys.SpellSpeedRatio = v
    end
    
    function abi:GetAttackSpeedRatio(iLvl)
        return self:_GetLevelScalableKey(self._woeKeys.AttackSpeedRatio, iLvl)
    end
    
    function abi:SetAttackSpeedRatio(v)
        self._woeKeys.AttackSpeedRatio = v
    end
    
    --GetCooldown that existed before wrapper was applied
    abi.GetBaseCooldown = abi.GetCooldown
    
    
    
    --gets the total cooldown after all CDR has been calculated
    function abi:GetCooldown(lvl)
        print(self:GetAbilityName() .. ":GetCooldown called")
        local caster = self:GetCaster()
        local baseCd = self:GetBaseCooldown(lvl)
        local cdOut
        if not isLuaAbility or not caster or not caster.isWoeUnit then
            cdOut = baseCd
        else
            local ics = 0
            local keys = self:GetKeywords()
            if keys:Has("attack") then
                ics = ics + caster:GetIncreasedAttackSpeed()*100 * self:GetAttackSpeedRatio()
            end
            if keys:Has("spell") then
                ics = ics + caster:GetSpellSpeed() * self:GetSpellSpeedRatio()
            end
            cdOut =  baseCd / ((100 + ics) * 0.01)
            print("base cooldown: ", baseCd)
            print("ics: ", ics)
            print("reduced cooldown: ", cdOut)
        end
        self._prevCd = cdOut
        self._prevCdLvl = lvl
        return cdOut
    end
    
    --Updates the current cooldown based on the ratio of the old cooldown to the new one
    function abi:UpdateCurrentCooldown(newCd)
        local remaining = self:GetCooldownTimeRemaining()
        if self._prevCd and remaining > 0 then
            print("updating current cooldown")
            local oldCd = self._prevCd
            newCd = newCd or self:GetCooldown(self._prevCdLvl)
            local newRemaining = newCd * (remaining / oldCd)
            if newRemaining < remaining then
                self:EndCooldown()
            end
            self:StartCooldown(newRemaining)
        end
    end
end

