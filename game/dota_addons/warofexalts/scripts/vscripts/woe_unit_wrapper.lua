
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
        SpellHasteBase = 0,
        SpellHasteBonus = 0,
        SpellHasteModifier = 0,
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
        StaminaRechargeDelayReduction = 0,
        StaminaRechargeRateBase = 0.1,
        StaminaRechargeRateBonus = 0,
        StaminaTimer = 0,
        ForceStaminaRecharge = false,
    }
    
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
        self._woeKeys.MagicResistBase = v
        self:_RecalculateMagicReduction()
    end
    
    --Set the bonus MR rating of the unit
    function unit:SetWoeMagicResistBonus(v)
        self._woeKeys.MagicResistBonus = v
        self:_RecalculateMagicReduction()
    end
    
    function unit:GetWoeMagicResistModifier()
        return self._woeKeys.MagicResistModifier
    end
    
    function unit:SetWoeMagicResistModifier(v)
        self._woeKeys.MagicResistModifier = v
        self:_RecalculateMagicReduction()
    end
    
    --Calculates % magic reduction from current MR rating and resets it via the dota API
    function unit:_RecalculateMagicReduction()
        local mr = self:GetWoeMagicResist()
        self:SetBaseMagicalResistanceValue(0.06 * mr / (1 + 0.06 * mr))
    end
    
    --Get spell haste rating
    function unit:GetSpellHasteBase()
        return self._woeKeys.SpellHasteBase
    end
    
    --Set spell haste rating
    function unit:SetSpellHasteBase(v)
        self._woeKeys.SpellHasteBase = v
    end
    
    function unit:GetSpellHasteBonus()
        return self._woeKeys.SpellHasteBonus
    end
    
    function unit:SetSpellHasteBonus(v)
        self._woeKeys.SpellHasteBonus = v
    end
    
    function unit:GetSpellHasteModifier()
        return self._woeKeys.SpellHasteModifier
    end
    
    function unit:SetSpellHaste(v)
        self._woeKeys.SpellHasteModifier = v
    end
    
    function unit:GetSpellHaste()
        return (1 + self:GetSpellHasteModifier()) * (self:GetSpellHasteBase() + self:GetSpellHasteBonus())
    end
    
    function unit:GetCdrPercent()
        return self._woeKeys.CdrPercent
    end
    
    function unit:SetCdrPercent(v)
        self._woeKeys.CdrPercent = v
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
        self._woeKeys.StaminaCurrent = v
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
        local ratio = self:GetStaminaPercent()
        self._woeKeys.StaminaMax = v
        self._woeKeys.StaminaCurrent = ratio*v
        self:_InitializeStaminaRegenerator()
    end
    
    --Sets max stamina without adjusting current stamina by percentage. Current stamina will be clipped at the new max if it exceeds the new max.
    function unit:SetMaxStaminaNoPercentAdjust(v)
        if v < 0 then
            v = 0
        end
        self._woeKeys.staminaMax = v
        if self._woeKeys.CurrentStamina > v then
          self._woeKeys.CurrentStamina = v
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
    
    function unit:GetStaminaRegenBase()
        return self._woeKeys.StaminaRegenBase
    end
    
    function unit:SetStaminaRegenBase(v)
        self._woeKeys.StaminaRegenBase = v
        self:_InitializeStaminaRegenerator()
    end
    
    function unit:GetStaminaRegenBonus()
        return self._woeKeys.StaminaRegenBonus
    end
    
    function unit:SetStaminaRegenBonus(v)
        self._woeKeys.StaminaRegenBonus = v
        self:_InitializeStaminaRegenerator()
    end
    
    function unit:GetStaminaRegenBaseModifier()
        return self._woeKeys.StaminaRegenBaseModifier
    end
    
    function unit:SetStaminaRegenBaseModifier(v)
        self._woeKeys.StaminaRegenBaseModifier = v
        self:_InitializeStaminaRegenerator()
    end
    
    function unit:GetStaminaRegen()
        return self:GetStaminaRegenBase() * (1 + self:GetStaminaRegenBaseModifier()) + self:GetStaminaRegenBonus()
    end
    
    function unit:GetStaminaRechargeDelayBase()
        return self._woeKeys.StaminaRechargeDelayBase
    end
    
    function unit:SetStaminaRechargeDelayBase(v)
        self._woeKeys.StaminaRechargeDelayBase = v
    end
    
    function unit:GetStaminaRechargeDelayReduction()
        return self._woeKeys.StaminaRechargeDelayReduction
    end
    
    function unit:SetStaminaRechargeDelayReduction(v)
        self._woeKeys.StaminaRechargeDelayReduction = v
    end
    
    function unit:GetStaminaRechargeDelay()
        return self:GetStaminaRechargeDelayBase() * (1 - self:GetStaminaRechargeDelayReduction())
    end
    
    function unit:GetStaminaRechargeRateBase()
        return self._woeKeys.StaminaRechargeRateBase
    end
    
    function unit:SetStaminaRechargeRateBase(v)
        self._woeKeys.StaminaRechargeRateBase = v
        self:_InitializeStaminaRegenerator()
    end
    
    function unit:GetStaminaRechargeRateBonus()
        return self._woeKeys.StaminaRechargeRateBonus
    end
    
    function unit:SetStaminaRechargeRateBonus(v)
        self._woeKeys.StaminaRechargeRateBonus = v
        self:_InitializeStaminaRegenerator()
    end
    
    --returns the % of max stamina that's restored per second when in stamina recharge mode
    function unit:GetStaminaRechargeRate()
        return self:GetStaminaRechargeRateBase() * (1 + self:GetStaminaRechargeRateBonus())
    end
    
    function unit:_InitializeStaminaRegenerator()
        if (not self._woeStaminaRegeneratorInitialized 
            and self:GetMaxStamina() > 0 
            and (self:GetStaminaRegen() > 0 or self:GetStaminaRechargeRate() > 0)) then
                self._woeStaminaRegeneratorInitialized = true
                unit:AddNewModifier(unit, nil, "modifier_woe_stamina_regenerator", {})
        end
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
        for k, modifier in pairs(self:FindAllModifiers()) do
            local f = modifier[fName]
            if f then
                f(modifier, unpack(args))
            end
        end
    end
    
    if unit:IsHero() then
        self:WoeHeroWrapper(unit)
    else
        util.updateKeys(unit._woeKeys, self.datadriven.units[unit:GetUnitName()])
    end
    
    util.updateKeys(unit._woeKeys, extraKeys)
    
end

function WarOfExalts:WoeHeroWrapper(unit)
    local keys = self.datadriven.heroes[unit:GetUnitName()]
    util.updateKeys(unit._woeKeys, keys)
    
    unit:AddNewModifier(unit, nil, "modifier_woe_attributes", {})
end
 