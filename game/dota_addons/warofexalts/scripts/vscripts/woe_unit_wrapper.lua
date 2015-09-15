
if WarOfExalts == nil then
	--print ( '[WAROFEXALTS] creating warofexalts game mode' )
	WarOfExalts = class({})
end

CACHE_LIFETIME = 0.1

local propGetter = function(name, onChange)
    return function(unit)
        --print("propGetter", name)
        local t = Time()
        local cached = unit._woeKeysCache[name]
        local old = cached.value
        if t > cached.cacheTime + CACHE_LIFETIME then
            print("fetching new value for ", name)
            v = unit._woeKeys[name] + unit:SumModifierProperties(name)
            if v ~= old then
                print("propGetter", "value changed", name, v, old)
                cached.value = v
                cached.cacheTime = t
                if onChange ~= nil then
                    v = onChange(unit, v, old) or v
                    cached.value = v
                end
                unit:SendUpdateEvent("woe_stats_changed")
            end
        else
            print("fetching cached value for", name, cached.value)
            v = cached.value
        end 
        return v
    end
end

local propSetter = function(name)
    return function(unit, v)
        print("propSetter", name)
        local old = unit._woeKeys[name]
        if v ~= old then
            unit._woeKeys[name] = v
            local cached = unit._woeKeysCache[name]
            cached.value = cached.value + v - old
            if onChange ~= nil then
                local old2 = v
                v = onChange(unit, v, old)
                unit._woeKeys[name] = v
                cached.value = cached.value + v - old2
            end
            unit:SendUpdateEvent("woe_stats_changed")
        end
    end
end

--Calculates % magic reduction from current MR rating and resets it via the dota API
local recalculateMagicReduction = function(self, mr)
    self:SetBaseMagicalResistanceValue(0.06 * mr / (1 + 0.06 * mr))
end

local initializeStaminaRegenerator = function(self)
    if self:GetMaxStamina() > 0 
        and (self:GetStaminaRegen() > 0 or self:GetStaminaRechargeRate() > 0) then
            unit:AddNewModifier(unit, nil, "modifier_woe_stamina_regenerator", {})
    end
end

--This function takes a dota NPC and adds custom WoE functionality to it
function WarOfExalts:WoeUnitWrapper(unit, extraKeys)
    if unit.isWoeUnit then return end
    extraKeys = extraKeys or { }
    
    --Special flag we can use to identify a WoE unit
    unit.isWoeUnit = true
    --Initialize WoE instance variables
    unit._woeKeys = {
        SpellSpeedBase = 0,
        SpellSpeedBonus = 0,
        SpellSpeedModifier = 0,
        MagicResistBase = 0,
        MagicResistBonus = 0,
        MagicResistModifier = 0,
        CdrPercent = 0,
        CurrentStamina = 100,
        MaxStamina = 100,
        StaminaRegenBase = 0.01,
        StaminaRegenBonus = 0,
        StaminaRegenBaseModifier = 0,
        StaminaRechargeDelayBase = 5,
        StaminaRechargeDelayModifier = 0,
        StaminaRechargeRateBase = 0.1,
        StaminaRechargeRateBonus = 0,
        StaminaTimer = 0,
        ForceStaminaRecharge = false,
        StaminaCostModifier = 0,
        ProjectileSpeedModifier = 0,
    }            
    
    unit.suppressEvents = false
    unit.suppressedEvents = { }
    
    --send to clients to indicate that stats were changed
    function unit:SendUpdateEvent(eventName, eventParams)
        eventParams = eventParams or { }
        eventParams.unit = eventParams.unit or self
        print("SendUpdateEvent", eventName)
        --util.printTable(eventParam)
        if self.suppressEvents then
            print("suppressed")
            self.suppressedEvents[eventName] = eventParams
        else
            print("sending")
            CustomGameEventManager:Send_ServerToAllClients(eventName, eventParams)
        end
    end
    
    --begin suppressing update events
    function unit:SuppressEvents(cb, supressedHandler)
        self.suppressEvents = true
        local status, res = pcall(cb)
        local suppressed = self.suppressedEvents
        self.suppressEvents = false
        self.suppressedEvents = { }     
        if suppressedHandler then
            suppressedHandler(suppressed)
        end
        if status then
            error(res)
        else
            return res
        end
    end
    
    --execute callback with suppressed events, then trigger events at end
    function unit:BatchUpdate(cb)
        return SuppressEvents(cb, function(suppressed)
            print("BatchUpdate: sending suppressed events")
            for name, params in pairs(suppressed) do
                self:SendUpdateEvent(eventName, eventParams)
            end
        end)
    end
    
    --Get the total WoE MR rating (analogous to armor rating)
    function unit:GetMagicResist() 
        return (1 + self:GetMagicResistModifier()) * (self:GetMagicResistBase() + self:GetMagicResistBonus())
    end
    
    --Get only the base MR rating
    unit.GetMagicResistBase = propGetter("MagicResistBase", recalculateMagicReduction)
    
    --Get only the bonus MR rating
    unit.GetMagicResistBonus = propGetter("MagicResistBonus", recalculateMagicReduction)
    
    --Set the base MR rating of the unit
    unit.SetMagicResistBase = propSetter("MagicResistBase", recalculateMagicReduction)
    
    --Set the bonus MR rating of the unit
    unit.SetMagicResistBonus = propSetter("MagicResistBonus", recalculateMagicReduction)
    
    unit.GetMagicResistModifier = propGetter("MagicResistModifier", recalculateMagicReduction)
    
    unit.SetMagicResistModifier = propSetter("MagicResistModifier", recalculateMagicReduction)
    

    
    --Get spell SpellSpeed rating
    unit.GetSpellSpeedBase = propGetter("SpellSpeedBase")
    
    --Set spell SpellSpeed rating
    unit.SetSpellSpeedBase = propSetter("SpellSpeedBase")
    
    unit.GetSpellSpeedBonus = propGetter("SpellSpeedBonus")
    
    unit.SetSpellSpeedBonus = propSetter("SpellSpeedBonus")
    
    unit.GetSpellSpeedModifier = propGetter("SpellSpeedModifier")
    
    unit.SetSpellSpeedModifier = propSetter("SpellSpeedModifier")
    
    function unit:GetSpellSpeed()
        return (1 + self:GetSpellSpeedModifier()) * (self:GetSpellSpeedBase() + self:GetSpellSpeedBonus())
    end
    
    unit.GetCdrPercent = propGetter("CdrPercent")
    
    unit.SetCdrPercent = propSetter("CdrPercent")
    
    function unit:GetStamina()
        return self._woeKeys.CurrentStamina
    end
    
    --directly sets current stamina. will not trigger recharge cooldown
    function unit:SetStamina(v)
        print("SetStamina", v)
        v = math.max(math.min(self:GetMaxStamina(), v), 0)
        if v ~= self._woeKeys.CurrentStamina then
            print("SetStamina", "value changed")
            self._woeKeys.CurrentStamina = v
            self:SendUpdateEvent("woe_stats_changed")
            self:SendUpdateEvent("woe_stamina_changed", {value = v})
        end
    end
    
    
    function unit:GetStaminaPercent()
        local sMax = self:GetMaxStamina()
        if sMax == 0 then
            return 1
        end
        return self:GetStamina() / sMax
    end
    
    local onMaxStaminaChange = function(self, new, old)
        if new < 0 then
            new = 0
        end
        local ratio
        if old == 0 then
            ratio = 1
        else
            ratio = self:GetStamina() / old
        end
        self:SetStamina(ratio*new)
        initializeStaminaRegenerator(self)
        return new
    end
    
    unit.GetMaxStamina = propGetter("MaxStamina", onMaxStaminaChange)
    
    unit.SetMaxStamina = propSetter("MaxStamina", onMaxStaminaChange)
    
    --Sets max stamina without adjusting current stamina by percentage. Current stamina will be clipped at the new max if it exceeds the new max.
    unit.SetMaxStaminaNoPercentAdjust = propSetter("MaxStamina", function(self, v)
        v = math.min(0, v)
        if self:GetStamina() > v then
            self.SetStamina(v)
        end
        initializeStaminaRegenerator(self)
        return v
    end)
    
    --puts stamina recharge on cooldown. if already on cooldown, will reset the duration
    function unit:TriggerStaminaRechargeCooldown()
        self.forceStaminaRecharge = false
        self.staminaTimer = GameRules:GetGameTime()
    end
    
    --forces stamina to begin recharging regardless of when it was last used
    function unit:ForceStaminaRecharge()
        self.ForceStaminaRecharge = true
    end
    
    --returns the number of seconds until stamina will enter recharge mode. 0 indicates that we are in recharge mode.
    function unit:GetStaminaRechargeDelayRemaining()
        if forceStaminaRecharge then
            return 0
        end
        local t = self:GetStaminaRechargeDelay() - GameRules:GetGameTime() - self._woeKeys.StaminaTimer
        if t < 0 then
            t = 0
        end
        return t
    end
    
    --Returns true if stamina is in recharge mode
    function unit:IsStaminaRecharging()
        return self:GetStaminaRechargeDelayRemaining() <= 0
    end
         
    --attempts to spend the given amount of stamina. will not reduce stamina if there is not enough available. returns true and triggers stamina recharge cooldown if stamina was successfully spent.
    function unit:SpendStamina(v, context)
        if v <= 0 then
            return true
        end
        local newStamina = self:GetStamina() - v
        if newStamina < 0 then
            return false
        end
        self:SetStamina(newStamina)
        self:TriggerStaminaRechargeCooldown()
        context = context or { }
        context.value = v
        self:CallOnModifiers("OnSpentStamina", context)
        return true;
    end
    
    --similar to spend stamina but used by abilities that drain enemy stamina. returns the amount of stamina drained. if 0 stamina is drained, will not trigger stamina recharge cooldown.
    function unit:DrainStamina(v)
        local amountDrained = v
        local newStamina = self:GetStamina() - amountDrained
        if newStamina < 0 then
            amountDrained = amountDrained + newStamina
        end
        if amountDrained > 0 then
            self:TriggerStaminaRechargeCooldown()
        end
        self:SetStamina(newStamina)
        return amountDrained
    end
    
    function unit:CanSpendStamina(v)
        if v <= 0 then
            return true
        elseif self:GetStamina() - v < 0 then
            return false
        else
            return true
        end  
    end
    
    unit.GetStaminaRegenBase = propGetter("StaminaRegenBase", initializeStaminaRegenerator)
    
    unit.SetStaminaRegenBase = propSetter("StaminaRegenBase", initializeStaminaRegenerator)
    
    unit.GetStaminaRegenBonus = propGetter("StaminaRegenBonus", initializeStaminaRegenerator)
    
    unit.SetStaminaRegenBonus = propSetter("StaminaRegenBonus", initializeStaminaRegenerator)
    
    unit.GetStaminaRegenBaseModifier = propGetter("StaminaRegenBaseModifier")
    
    unit.SetStaminaRegenBaseModifier = propSetter("StaminaRegenBaseModifier")
    
    function unit:GetStaminaRegen()
        return self:GetStaminaRegenBase() * (1 + self:GetStaminaRegenBaseModifier()) + self:GetStaminaRegenBonus()
    end
    
    unit.GetStaminaRechargeDelayBase = propGetter("StaminaRechargeDelayBase")
    
    unit.SetStaminaRechargeDelayBase = propSetter("StaminaRechargeDelayBase")
    
    unit.GetStaminaRechargeDelayModifier = propGetter("StaminaRechargeDelayModifier")
    
    unit.SetStaminaRechargeDelayModifier = propSetter("StaminaRechargeDelayModifier")
    
    function unit:GetStaminaRechargeDelay()
        return self:GetStaminaRechargeDelayBase() * (1 + self:GetStaminaRechargeDelayModifier())
    end
    
    unit.GetStaminaRechargeRateBase = propGetter("StaminaRechargeRateBase", initializeStaminaRegenerator)
    
    unit.SetStaminaRechargeRateBase = propSetter("StaminaRechargeRateBase", initializeStaminaRegenerator)
    
    unit.GetStaminaRechargeRateBonus = propGetter("StaminaRechargeRateBonus", initializeStaminaRegenerator)
    
    unit.SetStaminaRechargeRateBonus = propSetter("StaminaRechargeRateBonus", initializeStaminaRegenerator)
    
    --returns the % of max stamina that's restored per second when in stamina recharge mode
    function unit:GetStaminaRechargeRate()
        return self:GetStaminaRechargeRateBase() * (1 + self:GetStaminaRechargeRateBonus())
    end
    
    unit.GetStaminaCostModifier = propGetter("StaminaCostModifier")
    
    unit.SetStaminaCostModifier = propSetter("StaminaCostModifier")
    
    unit.GetProjectileSpeedModifier = propGetter("ProjectileSpeedModifier")
    
    unit.SetProjectileSpeedModifier = propSetter("ProjectileSpeedModifier")
    
    function unit:WithAbilities(cb)
        for i=0, self:GetAbilityCount()-1 do
            local abil = self:GetAbilityByIndex(i)
            if abil ~= nil then
                cb(abil)
            end
        end
    end
    
    function unit:CallOnModifiers(fName, ...)
        --print(unit:GetUnitName() .. ":CallOnModifiers: ", fName)
        for k, modifier in pairs(self:FindAllModifiers()) do
            local f = modifier[fName]
            if f then
                f(modifier, ...)
            end
        end
    end
    
    function unit:SumModifierProperties(pName, extraParams)
        local out = 0
        for k, modifier in pairs(self:FindAllModifiers()) do
            if instanceof(modifier, modifier_woe_base) then
                local prop = modifier._woeProperties[pName]
                if prop ~= nil then
                    if type(prop) == "function" then
                        local params = util.shallowCopy(modifier._params)
                        util.mergeTable(params, extraParams or { })
                        out = out + prop(modifier, params)
                    else
                        out = out + prop
                    end
                end
            end
        end
        return out
    end
    
    if unit:IsHero() then
        util.updateTable(unit._woeKeys, self.datadriven.heroes[unit:GetUnitName()])
    else
        util.updateTable(unit._woeKeys, self.datadriven.units[unit:GetUnitName()])
    end   
    util.updateTable(unit._woeKeys, extraKeys)
    
    --initialize property cache
    unit._woeKeysCache = { }
    local t = Time()
    for k, v in pairs(unit._woeKeys) do
        unit._woeKeysCache[k] = {
            value = v,
            cacheTime = t
        }
    end
    
    if unit:IsHero() then
        unit:AddNewModifier(unit, nil, "modifier_woe_attributes", { })    
        unit:AddAbility("woe_attributes")
    end
end
