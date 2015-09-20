require("warofexalts")
require("lib/property")


--local function declarations (code defined at bottom of file)
local recalculateMagicReduction, initializeStaminaRegenerator, updateCooldowns, onMaxStaminaChange, onCurrentStaminaChange


function WarOfExalts:WoeUnitWrapper(unit, extraKeys)
    --[[ This function takes a dota NPC and adds custom WoE functionality to it.
    ]]
    
    if unit.isWoeUnit then return end -- return if already initialized
    extraKeys = extraKeys or { }
    
    unit.isWoeUnit = true --flag we can use to identify a WoE unit
    
    function unit:EachAbility(cb)
        --[[ Iterate over all abilities on this unit, passing them to the given callback
        ]]
        for i=0, self:GetAbilityCount()-1 do
            local abil = self:GetAbilityByIndex(i)
            if abil ~= nil then
                cb(abil)
            end
        end
    end
    
    function unit:CallOnModifiers(fName, ...)
        --[[ Calls a method on all child modifiers for this unit, specified by the string fName. 
            The first argument to the modifier's function will always be the modifier itself, followed by any extra arguments passed to CallOnModifiers.
        
            If the modifier doesn't define the function, it is ignored. No error occurs.
        ]]
        --print(unit:GetUnitName() .. ":CallOnModifiers: ", fName)
        for _, modifier in pairs(self:FindAllModifiers()) do
            local f = modifier[fName]
            if type(f) == "function" then
                f(modifier, ...)
            end
        end
    end
    
    --[[ unit-wide property settings ]]
    Property.UnitOptions(unit, {
        --debug = true,
        defaultPropertyOptions = { -- default options for properties on this unit
            type = "number",
            useGameTime = true, -- use GetGameTime instead of Time for caching
            updateEvent = "woe_stats_changed",
            modifyEventParams = function(eventName, eventParams, unit)
                eventParams.isWoeUnit = unit.isWoeUnit
                eventParams.id = unit:GetEntityIndex()
            end
        }
    })
    
    --[[ Property definitions and related functions

        Note that many properties are split into three parts: base, bonus, and modifier.
        
        The general formula for calculating the total looks like:
            ( modifier + 1 ) * (base + bonus) 
    ]]
    
    --Returns the total magic resist rating for this unit, analogous to dota's armor stat.
    function unit:GetMagicResist() 
        return (1 + self:GetMagicResistModifier()) * (self:GetMagicResistBase() + self:GetMagicResistBonus())
    end
    
    Property(unit, "MagicResistBase", {
        onChange = recalculateMagicReduction
    }) 
    Property(unit, "MagicResistBonus", {
        onChange =  recalculateMagicReduction
    })
    Property(unit, "MagicResistModifier", {
        onChange =  recalculateMagicReduction
    })
    
    
    --Returns the total spell speed for this unit, analogous to dota's attack speed stat.
    function unit:GetSpellSpeed()
        return (1 + self:GetSpellSpeedModifier()) * (self:GetSpellSpeedBase() + self:GetSpellSpeedBonus())
    end
    Property(unit, "SpellSpeedBase", {
        onChange = updateCooldowns
    })
    Property(unit, "SpellSpeedBonus", {
        onChange = updateCooldowns
    })
    Property(unit, "SpellSpeedModifier", {
        onChange = updateCooldowns
    })
    
    
    --Current stamina pool
    Property(unit, "CurrentStamina", {
        get = "GetStamina",
        set = "SetStamina",
        --debug = false,
        default = 100,
        onChange = onCurrentStaminaChanged,
        combine = Property.ignoreModifiers,
    })
    --Maximum stamina pool.
    Property(unit, "MaxStamina", {
        default = 100,
        --debug = false,
        onChange = onMaxStaminaChange
    })
    --Returns the effective ratio between current and max stamina
    function unit:GetStaminaPercent()
        local sMax = self:GetMaxStamina()
        if sMax == 0 then -- avoid division by 0; no max stamina means that stamina ratio is considered to always be 100%
            return 1
        end
        return self:GetStamina() / sMax
    end
    
    --[[ Sets max stamina without adjusting current stamina by percentage. 
        Current stamina will be clipped at the new max if it exceeds the new max.
    ]]
    unit.SetMaxStaminaNoPercentAdjust = Property.PropSetter("MaxStamina", {
        onChange = function(self, v)
            v = math.min(0, v)
            if self:GetStamina() > v then
                self.SetStamina(v)
            end
            initializeStaminaRegenerator(self)
            return v
        end
    })
    
    
    --Returns the flat regen per second applied to stamina at all times, regardless of recharge mode.
    function unit:GetStaminaRegen()
        return self:GetStaminaRegenBase() * (1 + self:GetStaminaRegenBaseModifier()) + self:GetStaminaRegenBonus()
    end   
    Property(unit, "StaminaRegenBase", {
        default = 0.01,
        onChange = initializeStaminaRegenerator
    })
    Property(unit, "StaminaRegenBonus", {
        onChange = initializeStaminaRegenerator
    })
    Property(unit, "StaminaRegenBaseModifier")
    
    
    --Returns the time in seconds that we must wait, in total, before entering recharge mode
    function unit:GetStaminaRechargeDelay()
        return self:GetStaminaRechargeDelayBase() * (1 + self:GetStaminaRechargeDelayModifier())
    end
    Property(unit, "StaminaRechargeDelayBase", {
        default = 5
    })
    Property(unit, "StaminaRechargeDelayModifier")
    
    --returns the number of seconds until stamina will enter recharge mode. 0 indicates that we are in recharge mode.
    function unit:GetStaminaRechargeDelayRemaining()
        if self:IsStaminaRechargeForced() then
            return 0
        end
        local t = self:GetStaminaRechargeDelay() - GameRules:GetGameTime() - self:GetStaminaTimer()
        if t < 0 then
            t = 0
        end
        return t
    end
    
    
    --Returns the % of max stamina that's restored per second when in stamina recharge mode
    function unit:GetStaminaRechargeRate()
        return self:GetStaminaRechargeRateBase() * (1 + self:GetStaminaRechargeRateBonus())
    end
    Property(unit, "StaminaRechargeRateBase", {
        default = 0.01,
        onChange = initializeStaminaRegenerator
    })
    
    Property(unit, "StaminaRechargeRateBonus", {
        onChange = initializeStaminaRegenerator
    })
    
    --Time in seconds since stamina was last spent/drained
    Property(unit, "StaminaTimer")
    
    --If true, forces stamina to enter recharge mode regardless of the current timer value.
    Property(unit, "ForceStaminaRecharge", {
        type = "bool",
        get = "IsStaminaRechargeForced",
        set = "ForceStaminaRecharge",
    })
    
    --Returns true if stamina is in recharge mode
    function unit:IsStaminaRecharging()
        return self:GetStaminaRechargeDelayRemaining() == 0
    end
    
    --[[ Puts stamina recharge on cooldown. If already on cooldown, will reset the duration.
        The optional offset parameter is a number of seconds to increase or decrease the delay time before
        stamina begins recharging again.
    ]]
    function unit:TriggerStaminaRechargeCooldown(offset)
        self:ForceStaminaRecharge(false)
        self.staminaTimer = GameRules:GetGameTime() + (offset or 0)
    end
    
    --Percentage modifier on projectile speed of unit's abilities. A value of 0 indicates 100% projectile speed.
    Property(unit, "ProjectileSpeedModifier")
    
    --Percentage modifier on ability stamina costs. A value of 0 indicates 100% stamina cost.
    Property(unit, "StaminaCostModifier")
         
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
        self:SetCurrentStamina(newStamina)
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
    
    --update property data from KV data
    if unit:IsHero() then
        util.updateTable(unit._props, self.datadriven.heroes[unit:GetUnitName()])
    else
        util.updateTable(unit._props, self.datadriven.units[unit:GetUnitName()])
    end   
    util.updateTable(unit._props, extraKeys)
    if unit:IsHero() then 
        unit:AddAbility("woe_attributes")
    end
end


--[[ local property onChange event handlers ]]

recalculateMagicReduction = function(self, mr)
    self:SetBaseMagicalResistanceValue(0.06 * mr / (1 + 0.06 * mr))
end

initializeStaminaRegenerator = function(self)
    if self:GetMaxStamina() > 0 
        and (self:GetStaminaRegen() > 0 or self:GetStaminaRechargeRate() > 0) then
            self:AddNewModifier(self, nil, "modifier_woe_stamina_regenerator", {})
    end
end

updateCooldowns = function(self, new, old)
    self:EachAbility(function(a)
        if a.isWoeAbility then
            a:UpdateCurrentCooldown()
        end
    end)
end

onMaxStaminaChange = function(self, new, old)
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

onCurrentStaminaChange = function(self, v)
    return math.max(math.min(self:GetMaxStamina(), v), 0)
end
