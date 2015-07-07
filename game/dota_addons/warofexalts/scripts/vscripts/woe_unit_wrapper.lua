--This function takes a dota NPC and adds custom WoE functionality to it
function WoeUnitWrapper(unit)
    keys = keys or {}
    --Special flag we can use to identify a WoE unit
    unit.isWoeUnit = true
    --Initialize WoE instance variables
    unit._woeKeys = {
        spellHaste = 0,
        magicResistBase = 0,
        magicResistBonus = 0,
        cdrBonus = 0,
        staminaCurrent = 20,
        staminaMax = 100,
        staminaRegenBase = 0.01,
        staminaRegenBonusFlat = 0,
        staminaRegenBonusPercent = 0,
        staminaRechargeDelayBase = 5,
        staminaRechargeDelayReduction = 0,
        staminaRechargeRateBase = 0.1,
        staminaRechargeRateBonus = 0,
        staminaTimer = 0,
        forceStaminaRecharge = false,
    }
    
    --Add WoE-specific methods to the unit
    
    --Get the total WoE MR rating (analogous to armor rating)
    function unit:GetWoeMagicResist() 
        return self._woeKeys.magicResistBase + self._woeKeys.magicResistBonus
    end
    
    --Get only the base MR rating
    function unit:GetWoeMagicResistBase()
        return self._woeKeys.magicResistBase
    end
    
    --Get only the bonus MR rating
    function unit:GetWoeMagicResistBonus()
        return self._woeKeys.magicResistBonus
    end
    
    --Set the base MR rating of the unit
    function unit:SetWoeMagicResistBase(v)
        self._woeKeys.magicResistBase = v
        self:_RecalculateMagicReduction()
    end
    
    --Set the bonus MR rating of the unit
    function unit:SetWoeMagicResistBonus(v)
        self._woeKeys.magicResistBonus = v
        self:_RecalculateMagicReduction()
    end
    
    --Calculates % magic reduction from current MR rating and resets it via the dota API
    function unit:_RecalculateMagicReduction()
        local mr = self:GetWoeMagicResist()
        self:SetBaseMagicalResistanceValue(0.06 * mr / (1 + 0.06 * mr))
    end
    
    --Get spell haste rating
    function unit:GetSpellHaste()
        return self._woeKeys.spellHaste
    end
    
    --Set spell haste rating
    function unit:SetSpellHaste(v)
        self._woeKeys.spellHaste = v
    end
    
    function unit:GetCdrBonus()
        return self._woeKeys.cdrBonus
    end
    
    function unit:SetCdrBonus(v)
        self._woeKeys.cdrBonus = v
    end
    
    function unit:GetStamina()
        return self._woeKeys.staminaCurrent
    end
    
    --directly sets current stamina. will not trigger recharge cooldown
    function unit:SetStamina(v)
        if v > self._woeKeys.staminaMax then
            v = self._woeKeys.staminaMax
        elseif v < 0 then
            v = 0
        end
        self._woeKeys.staminaCurrent = v
    end
    
    function unit:GetStaminaPercent()
        if self._woeKeys.staminaMax == 0 then
            return 1
        end
        return self._woeKeys.staminaCurrent / self._woeKeys.staminaMax
    end
    
    function unit:SetStaminaPercent(v)
        self:SetStamina(v * self:GetStamina())
    end
    
    function unit:GetMaxStamina()
        return self._woeKeys.staminaMax
    end
    
    --Sets maximum stamina, adjusting current stamina by percentage
    function unit:SetMaxStamina(v)
        if v < 0 then
            v = 0
        end
        local ratio = self:GetStaminaPercent()
        self._woeKeys.staminaMax = v
        self._woeKeys.staminaCurrent = ratio*v
        self:_InitializeStaminaRegenerator()
    end
    
    --Sets max stamina without adjusting current stamina by percentage. Current stamina will be clipped at the new max if it exceeds the new max.
    function unit:SetMaxStaminaNoPercentAdjust(v)
        if v < 0 then
            v = 0
        end
        self._woeKeys.staminaMax = v
        if self._woeKeys.currentStamina > v then
          self._woeKeys.currentStamina = v
        end
    end
    
    --puts stamina recharge on cooldown. if already on cooldown, will reset the duration
    function unit:TriggerStaminaRechargeCooldown()
        self.forceStaminaRecharge = false
        self.staminaTimer = GameRules:GetDOTATime(false, false)
    end
    
    --forces stamina to begin recharging regardless of when it was last used
    function unit:ForceStaminaRecharge()
        self.forceStaminaRecharge = true
    end
    
    --returns the number of seconds until stamina will enter recharge mode. 0 indicates that we are in recharge mode.
    function unit:GetStaminaRechargeDelayRemaining()
        if forceStaminaRecharge then
            return 0
        end
        local t = self:GetStaminaRechargeDelay() - GameRules:GetDOTATime(false, false) - self._woeKeys.staminaTimer
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
        return self._woeKeys.staminaRegenBase
    end
    
    function unit:SetStaminaRegenBase(v)
        self._woeKeys.staminaRegenBase = v
        self:_InitializeStaminaRegenerator()
    end
    
    function unit:GetStaminaRegenBonusFlat()
        return self._woeKeys.staminaRegenBonusFlat
    end
    
    function unit:SetStaminaRegenBonusFlat(v)
        self._woeKeys.staminaRegenBonusFlat = v
        self:_InitializeStaminaRegenerator()
    end
    
    function unit:GetStaminaRegenBonusPercent()
        return self._woeKeys.staminaRegenBonusPercent
    end
    
    function unit:SetStaminaRegenBonusPercent(v)
        self._woeKeys.staminaRegenBonusPercent = v
        self:_InitializeStaminaRegenerator()
    end
    
    
    function unit:GetStaminaRegenBonus()
        return self:GetStaminaRegenBase() * self:GetStaminaRegenBonusPercent() + self:GetStaminaRegenBonusFlat()
    end
    
    function unit:GetStaminaRegen()
        return self:GetStaminaRegenBase() + self:GetStaminaRegenBonus()
    end
    
    function unit:GetStaminaRechargeDelayBase()
        return self._woeKeys.staminaRechargeDelayBase
    end
    
    function unit:SetStaminaRechargeDelayBase(v)
        self._woeKeys.staminaRechargeDelayBase = v
    end
    
    function unit:GetStaminaRechargeDelayReduction()
        return self._woeKeys.staminaRechargeDelayReduction
    end
    
    function unit:SetStaminaRechargeDelayReduction(v)
        self._woeKeys.staminaRechargeDelayReduction = v
    end
    
    function unit:GetStaminaRechargeDelay()
        return self:GetStaminaRechargeDelayBase() * (1 - self:GetStaminaRechargeDelayReduction())
    end
    
    function unit:GetStaminaRechargeRateBase()
        return self._woeKeys.staminaRechargeRateBase
    end
    
    function unit:SetStaminaRechargeRateBase(v)
        self._woeKeys.staminaRechargeRateBase = v
        self:_InitializeStaminaRegenerator()
    end
    
    function unit:GetStaminaRechargeRateBonus()
        return self._woeKeys.staminaRechargeRateBonus
    end
    
    function unit:SetStaminaRechargeRateBonus(v)
        self._woeKeys.staminaRechargeRateBonus = v
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
    
    if unit:IsHero() then
        WoeHeroWrapper(unit)
    end
    
end

function WoeHeroWrapper(unit)
    unit:AddNewModifier(unit, nil, "modifier_woe_attributes", {})  
end
        
    