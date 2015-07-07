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
        cdrBonus = 0 
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
    
    if unit:IsHero() then
        WoeHeroWrapper(unit)
    end
    
end

function WoeHeroWrapper(unit)
    unit.isWoeHero = true
    unit:AddNewModifier(unit, nil, "modifier_woe_attributes", {})
end
        
    