if WarOfExalts == nil then
	--print ( '[WAROFEXALTS] creating warofexalts game mode' )
	WarOfExalts = class({})
end

function WarOfExalts:WoeAbilityWrapper(abi)
    --flag we can use to easily test if ability is wrapped
    abi.isWoeAbility = true
    
    --WoE ability instance variables
    abi._woeKeys = {
        StaminaCost = 0,
        SpellHasteRatio = 1, 
    }
    
    function abi:GetStaminaCost()
        return self._woeKeys.StaminaCost
    end
    
    function abi:SetStaminaCost(v)
        self._woeKeys.StaminaCost = v
    end
    
    function abi:SpendStaminaCost()
        local caster = self:GetCaster()
        if caster and caster.isWoeUnit then
            return caster:SpendStamina(self:GetStaminaCost())
        end
        return true
    end
    
    function abi:GetSpellHasteRatio()
        return self._woeKeys.SpellHasteRatio
    end
    
    function abi:SetSpellHasteRatio(v)
        self._woeKeys.SpellHasteRatio = v
    end
    
    --capture base classes GetCooldown method before we override it
    abi.GetBaseCooldown = abi.GetCooldown
    --gets the total cooldown after all CDR has been calculated
    function abi:GetCooldown()
        local caster = self:GetCaster()
        local haste = 0
        local cdr = 0
        if caster and caster.isWoeUnit then
            return self:GetBaseCooldown() * (1 - caster:GetCdrPercent()) / ((100 + caster:GetSpellHaste() * self:GetSpellHasteRatio()) * 0.01)
        else
            return self:GetBaseCooldown()
        end
    end
    
    updateKeys(abi._woeKeys, self.datadriven.abilities[abi:GetAbilityName()])
end
