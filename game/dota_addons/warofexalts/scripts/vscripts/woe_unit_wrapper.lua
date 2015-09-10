
if WarOfExalts == nil then
	--print ( '[WAROFEXALTS] creating warofexalts game mode' )
	WarOfExalts = class({})
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
        StaminaCurrent = 20,
        StaminaMax = 100,
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
    --note: for stats that are expected to rapidly change (i.e. current stamina) this event is not used
    function unit:SendUpdateEvent(eventName, eventParams)
        eventParams = eventParams or { }
        if self._woeKeys.suppressEvents then
            self._woeKeys.suppressedEvents[eventName] = eventParams
        else
            eventParams.unit = eventParams.unit or self
            CustomGameEventManager:Send_ServerToAllClients(eventName, eventParams)
        end
    end
    
    --begin suppressing update events
    function unit:SuppressEvents()
        self.suppressEvents = true
    end
    
    --stop suppressing update events
    function unit:UnsuppressEvents()
        self.suppressEvents = false
        self.suppressedEvents = { }
    end
    
    --execute callback with suppressed events, then trigger events at end
    function unit:BatchUpdate(cb, ...)
        self:SuppressEvents()
        local status, res = pcall(cb)
        local suppressed = self.suppressedEvents
        self:UnsuppressEvents()
        for name, params in pairs(suppressed) do
            self:SendUpdateEvent(eventName, eventParams)
        end
        if status then
            return res
        else
            error(res)
        end
    end
    
    --Get the total WoE MR rating (analogous to armor rating)
    function unit:GetWoeMagicResist() 
        return (1 + self:GetWoeMagicResistModifier()) * (self._woeKeys.MagicResistBase + self._woeKeys.MagicResistBonus)
    end
    
    --Get only the base MR rating
    function unit:GetWoeMagicResistBase()
        return self._woeKeys.MagicResistBase
    end
    
    --Get only the bonus MR rating
    function unit:GetWoeMagicResistBonus()
        return self._woeKeys.MagicResistBonus
    end
    
    --Set the base MR rating of the unit
    function unit:SetWoeMagicResistBase(v)
        if v ~= self._woeKeys.MagicResistBase then
            self._woeKeys.MagicResistBase = v
            self:_RecalculateMagicReduction()
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    --Set the bonus MR rating of the unit
    function unit:SetWoeMagicResistBonus(v)
        if v ~= self._woeKeys.MagicResistBonus then
            self._woeKeys.MagicResistBonus = v
            self:_RecalculateMagicReduction()
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    function unit:GetWoeMagicResistModifier()
        return self._woeKeys.MagicResistModifier
    end
    
    function unit:SetWoeMagicResistModifier(v)
        if v ~= self._woeKeys.MagicResistModifier then
            self._woeKeys.MagicResistModifier = v
            self:_RecalculateMagicReduction()
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    --Calculates % magic reduction from current MR rating and resets it via the dota API
    function unit:_RecalculateMagicReduction()
        local mr = self:GetWoeMagicResist()
        self:SetBaseMagicalResistanceValue(0.06 * mr / (1 + 0.06 * mr))
    end
    
    --Get spell SpellSpeed rating
    function unit:GetSpellSpeedBase()
        return self._woeKeys.SpellSpeedBase
    end
    
    --Set spell SpellSpeed rating
    function unit:SetSpellSpeedBase(v)
        if v ~= self._woeKeys.SpellSpeedBase then
            self._woeKeys.SpellSpeedBase = v
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    function unit:GetSpellSpeedBonus()
        return self._woeKeys.SpellSpeedBonus
    end
    
    function unit:SetSpellSpeedBonus(v)
        if v ~= self._woeKeys.SpellSpeedBonus then
            self._woeKeys.SpellSpeedBonus = v
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    function unit:GetSpellSpeedModifier()
        return self._woeKeys.SpellSpeedModifier
    end
    
    function unit:SetSpellSpeed(v)
        if v ~= self._woeKeys.SpellSpeedModifier then
            self._woeKeys.SpellSpeedModifier = v
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    function unit:GetSpellSpeed()
        return (1 + self:GetSpellSpeedModifier()) * (self:GetSpellSpeedBase() + self:GetSpellSpeedBonus())
    end
    
    function unit:GetCdrPercent()
        return self._woeKeys.CdrPercent
    end
    
    function unit:SetCdrPercent(v)
        if v ~= self._woeKeys.CdrPercent then
            self._woeKeys.CdrPercent = v
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    function unit:GetStamina()
        return self._woeKeys.StaminaCurrent
    end
    
    --directly sets current stamina. will not trigger recharge cooldown
    function unit:SetStamina(v)
        if v > self._woeKeys.StaminaMax then
            v = self._woeKeys.StaminaMax
        elseif v < 0 then
            v = 0
        end
        if v ~= self._woeKeys.StaminaCurrent then
            self._woeKeys.StaminaCurrent = v
            self:SendUpdateEvent("woe_stamina_changed", {unit = self, amount = v})
        end
    end
    
    function unit:GetStaminaPercent()
        if self._woeKeys.StaminaMax == 0 then
            return 1
        end
        return self._woeKeys.StaminaCurrent / self._woeKeys.StaminaMax
    end
    
    function unit:SetStaminaPercent(v)
        self:SetStamina(v * self:GetStamina())
    end
    
    function unit:GetMaxStamina()
        return self._woeKeys.StaminaMax
    end
    
    --Sets maximum stamina, adjusting current stamina by percentage
    function unit:SetMaxStamina(v)
        if v < 0 then
            v = 0
        end
        if v ~= self._woeKeys.StaminaMax then
        local ratio = self:GetStaminaPercent()
            self._woeKeys.StaminaMax = v
            self._woeKeys.StaminaCurrent = ratio*v
            self:_InitializeStaminaRegenerator()
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    --Sets max stamina without adjusting current stamina by percentage. Current stamina will be clipped at the new max if it exceeds the new max.
    function unit:SetMaxStaminaNoPercentAdjust(v)
        if v < 0 then
            v = 0
        end
        if v ~= self._woeKeys.StaminaMax then
            self._woeKeys.staminaMax = v
            if self._woeKeys.CurrentStamina > v then
              self._woeKeys.CurrentStamina = v
              self:SendUpdateEvent("woe_stamina_changed", {unit = self, amount = v})
            end
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    --puts stamina recharge on cooldown. if already on cooldown, will reset the duration
    function unit:TriggerStaminaRechargeCooldown()
        self.forceStaminaRecharge = false
        self.staminaTimer = GameRules:GetDOTATime(false, false)
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
        local t = self:GetStaminaRechargeDelay() - GameRules:GetDOTATime(false, false) - self._woeKeys.StaminaTimer
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
    function unit:SpendStamina(v)
        if v <= 0 then
            return true
        end
        local newStamina = self:GetStamina() - v
        if newStamina < 0 then
            return false
        end
        self:SetStamina(newStamina)
        self:TriggerStaminaRechargeCooldown()
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
    
    function unit:GetStaminaRegenBase()
        return self._woeKeys.StaminaRegenBase
    end
    
    function unit:SetStaminaRegenBase(v)
        if v ~= self._woeKeys.StaminaRegenBase then
            self._woeKeys.StaminaRegenBase = v
            self:_InitializeStaminaRegenerator()
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    function unit:GetStaminaRegenBonus()
        return self._woeKeys.StaminaRegenBonus
    end
    
    function unit:SetStaminaRegenBonus(v)
        if v ~= self._woeKeys.StaminaRegenBonus then
            self._woeKeys.StaminaRegenBonus = v
            self:_InitializeStaminaRegenerator()
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    function unit:GetStaminaRegenBaseModifier()
        return self._woeKeys.StaminaRegenBaseModifier
    end
    
    function unit:SetStaminaRegenBaseModifier(v)
        if v ~= self._woeKeys.StaminaRegenBaseModifier then
            self._woeKeys.StaminaRegenBaseModifier = v
            self:_InitializeStaminaRegenerator()
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    function unit:GetStaminaRegen()
        return self:GetStaminaRegenBase() * (1 + self:GetStaminaRegenBaseModifier()) + self:GetStaminaRegenBonus()
    end
    
    function unit:GetStaminaRechargeDelayBase()
        return self._woeKeys.StaminaRechargeDelayBase
    end
    
    function unit:SetStaminaRechargeDelayBase(v)
        if v ~= self._woeKeys.StaminaRechargeDelayBase then
            self._woeKeys.StaminaRechargeDelayBase = v
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    function unit:GetStaminaRechargeDelayModifier()
        return self._woeKeys.StaminaRechargeDelayModifier
    end
    
    function unit:SetStaminaRechargeDelayModifier(v)
        if v ~= self._woeKeys.StaminaRechargeDelayModifier then
            self._woeKeys.StaminaRechargeDelayModifier = v
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    function unit:GetStaminaRechargeDelay()
        return self:GetStaminaRechargeDelayBase() * (1 + self:GetStaminaRechargeDelayModifier())
    end
    
    function unit:GetStaminaRechargeRateBase()
        return self._woeKeys.StaminaRechargeRateBase
    end
    
    function unit:SetStaminaRechargeRateBase(v)
        if v ~= self._woeKeys.StaminaRechargeRateBase then
            self._woeKeys.StaminaRechargeRateBase = v
            self:_InitializeStaminaRegenerator()
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    function unit:GetStaminaRechargeRateBonus()
        return self._woeKeys.StaminaRechargeRateBonus
    end
    
    function unit:SetStaminaRechargeRateBonus(v)
        if v ~= self._woeKeys.StaminaRechargeRateBonus then
            self._woeKeys.StaminaRechargeRateBonus = v
            self:_InitializeStaminaRegenerator()
            self:SendUpdateEvent("woe_stats_changed")
        end
    end
    
    --returns the % of max stamina that's restored per second when in stamina recharge mode
    function unit:GetStaminaRechargeRate()
        return self:GetStaminaRechargeRateBase() * (1 + self:GetStaminaRechargeRateBonus())
    end
    
    function unit:_InitializeStaminaRegenerator()
        if self:GetMaxStamina() > 0 
            and (self:GetStaminaRegen() > 0 or self:GetStaminaRechargeRate() > 0) then
                unit:AddNewModifier(unit, nil, "modifier_woe_stamina_regenerator", {})
        end
    end
    
    function unit:GetStaminaCostModifier()
        return self._woeKeys.StaminaCostModifier
    end
    
    function unit:SetStaminaCostModifier(v)
        self._woeKeys.StaminaCostModifier = v
    end
    
    function unit:GetProjectileSpeedModifier()
        return self._woeKeys.ProjectileSpeedModifier()
    end
    
    function unit:SetProjectileSpeedModifier(v)
        self._woeKeys.ProjectileSpeedModifier() = v
    end
    
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
    
    if unit:IsHero() then
        self:WoeHeroWrapper(unit)
    else
        util.updateTable(unit._woeKeys, self.datadriven.units[unit:GetUnitName()])
    end
    
    util.updateTable(unit._woeKeys, extraKeys)
    
end

function WarOfExalts:WoeHeroWrapper(unit)
    local keys = self.datadriven.heroes[unit:GetUnitName()]
    util.updateTable(unit._woeKeys, keys)
    
    unit:AddAbility("woe_attributes")
end
 