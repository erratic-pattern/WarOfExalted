require("util")
require("woe_keywords")

--Damage instances in WoE are slightly different from those in dota, and thus use an overhauled system. 
--WoE damage can have multiple damage types per instance, and has special Keywords.



--Analogous to ApplyDamage. Takes a table of parameters.
--  Required parameters: 
--      Victim - the entity receiving damage
--      Attacker - the entity dealing damage
--  Damage parameters (not required, but at least one should probably be used):
--      PhysicalDamage - Amount of physical damage to deal
--      MagicalDamage - amount of magical damage to deal
--      PureDamage - amount of pure damage to deal
--  Optional parameters:
--      Keywords     - A list of Keywords associated with this damage. Can be specified as either
--                     an array of strings or a string of words delimited by spaces
--      Ability      - ability source of the damage (optional)
--      damage_flags - passed directly to damage_flags parameter of ApplyDamage
--
--  ApplyWoeDamage also supports the damage and damage_flags for compatibility with code that uses ApplyDamage, however only
--  physical, magical, and pure damage types are supported. This may change in the future. For new code that doesn't need to be
--  compatible with ApplyDamage, using damage and damage_types is discouraged.
function ApplyWoeDamage(...)
    local dmg = WoeDamage(...)
    util.printTable(getmetatable(dmg)) 
    dmg:Apply()
end


--Class used to represent instances of WoE damage. Initialization parameters are the same as ApplyWoeDamage
WoeDamage = class({})
function WoeDamage:constructor(keys)
    --print("WoeDamage:constructor")
    keys = keys or {}
    
    --information about the damage (passed directly to ApplyDamage)
    self.Victim = keys.Victim
    self.Attacker = keys.Attacker
    self.Ability = keys.Ability
    self.DotaDamageFlags = util.normalizeBitFlags(keys.DotaDamageFlags or keys.damage_flags)
    
    --damage types and their values
    self.PhysicalDamage = keys.PhysicalDamage or 0
    self.MagicalDamage = keys.MagicalDamage or 0
    self.PureDamage = keys.PureDamage or 0
    
    --Compatability with ApplyDamage
    if keys.damage then
        if keys.damage_type == DAMAGE_TYPE_PHYSICAL then
            self.PhysicalDamage = self.PhysicalDamage + keys.damage
        elseif self.damage_type == DAMAGE_TYPE_MAGICAL then
            self.MagicalDamage = self.MagicalDamage + keys.damage
        elseif self.damage_type == DAMAGE_TYPE_PURE then
            self.PureDamage = self.PureDamage + keys.damage
        elseif not keys.damage_type then
            print("Warning: damage key used but no damage_type given. Key was ignored")
        else
            print("WoeDamage doesn't support damage_type " .. keys.damage_type)
        end
    end
      
    --Ability Keywords
    if keys.Keywords == nil then
        if self.Ability ~= nil and self.Ability.isWoeAbility then
            self.Keywords = WoeKeywords(self.Ability:GetKeywords())
        else
            self.Keywords = WoeKeywords()
        end
    else
        self.Keywords = WoeKeywords(keys.Keywords)
    end
end

function WoeDamage:GetKeywords()
    return self.Keywords
end

function WoeDamage:GetTotal()
    return self.GetPhysical() + self.GetMagical() + self.GetPure()
end

function WoeDamage:GetPhysical()
    return self.PhysicalDamage
end

function WoeDamage:GetMagical()
    return self.MagicalDamage
end

function WoeDamage:GetPure()
    return self.PureDamage
end

function WoeDamage:IsMitigated()
    return self.isMitigated
end

function WoeDamage:Zero()
    if self == nil then
        return WoeDamage()
    else
        return self:Modify(function() return 0 end)
    end
end

--Combine multiple damage instances into a new one.
function WoeDamage.Add(...)
    return WoeDamage.CombineWith(function(a,b) return a+b end, ...)
end

function WoeDamage.Multiply(...)
    return WoeDamage.CombineWith(function(a,b) return a*b end, ...)
end

function WoeDamage.Subtract(...)
    return WoeDamage.CombineWith(function(a,b) return a-b end, ...)
end

function WoeDamage.Divide(...)
    return WoeDamage.CombineWith(function(a,b) return a/b end, ...)
end

function WoeDamage:Negate()
    return self:Modify(function(x) return -x end)
end

--Combine multiple damage instances into a new one using the given binary combinator for damage number
function WoeDamage.CombineWith(f, ...)
    local outDmg = WoeDamage()
    for n=1,select("#", ...) do
        local inDmg = select(n, ...)
        outDmg.Victim = outDmg.Victim or inDmg.Victim
        outDmg.Attacker = outDmg.Attacker or inDmg.Attacker
        outDmg.Ability = outDmg.Ability or inDmg.Ability
        outDmg.DotaDamageFlags = bit.bor(outDmg.DotaDamageFlags, inDmg.DotaDamageFlags)
        outDmg.PhysicalDamage = f(outDmg.PhysicalDamage, inDmg.PhysicalDamage)
        outDmg.MagicalDamage = f(outDmg.MagicalDamage, inDmg.MagicalDamage)
        outDmg.PureDamage = f(outDmg.PureDamage, inDmg.PureDamage)
        outDmg.Keywords:UnionInPlace(inDmg.Keywords)   
    end
    return outDmg
end

function WoeDamage:Modify(f)
    local out = self:Clone()
    out.PhysicalDamage = f(out.PhysicalDamage)
    out.MagicalDamage = f(out.MagicalDamage)
    out.PureDamage = f(out.PureDamage)
    return out
end

--Create a copy
function WoeDamage:Clone()
    return WoeDamage(self)
end

--iterate over damage types as (dmg_flag, dmg_number) pairs, where
-- "dmg_flag" is one of DAMAGE_TYPE_PHYSICAL, DAMAGE_TYPE_MAGICAL, etc
function WoeDamage:IterateDmg()
    return ipairs({
        [DAMAGE_TYPE_PHYSICAL] = self:GetPhysical(),
        [DAMAGE_TYPE_MAGICAL] = self:GetMagical(),
        [DAMAGE_TYPE_PURE] = self:GetPure()  
    })
end

function WoeDamage:Mitigated()
    if self:IsMitigated() then
        return self
    end
    local mitigated = self:Clone()
    mitigated.isMitigated = true
    mitigated.unmitigated = self
    --print("WoeDamage:_ApplyMitigation")
    local armor = self.Victim:GetPhysicalArmorValue()
    local physReduction = 1 - 0.06 * armor / (1 + 0.06 * armor)
    --print("armor: ", armor)
    --print("unmitigated phys: ", self:GetPhysicalDamage())
    --print("phys modifier: ", physReduction)
    mitigated.PhysicalDamage = physReduction * self.PhysicalDamage
    --print("mitigated phys: ", self:GetPhysicalDamage())
    local magReduction = 1 - self.Victim:GetMagicalArmorValue()
    --print("mr: ", self.Victim:GetMagicResist())
    --print("unmitigated magic: ", self:GetMagicalDamage())
    --print("magic modifier", magReduction)
    mitigated.MagicalDamage = magReduction * self.MagicalDamage
    --print("mitigated magic: ", self:GetMagicalDamage())
    return mitigated
end

function WoeDamage:Unmitigated()
    if self:IsMitigated() then
        return self.unmitigated
    else
        return self
    end
end

--Apply the damage from Attacker to Victim
function WoeDamage:Apply()
    if not self:IsMitigated() then
        self.Attacker:CallOnModifiers("OnDealWoeDamagePreMitigation", self)
        self.Victim:CallOnModifiers("OnTakeWoeDamagePreMitigation", self)
    end
    local mitigated = self:Mitigated()
    mitigated.Attacker:CallOnModifiers("OnDealWoeDamage", mitigated)
    mitigated.Victim:CallOnModifiers("OnTakeWoeDamage", mitigated)
    local dmgArgs = {
        victim = mitigated.Victim,
        attacker = mitigated.Attacker,
        ability = mitigated.Ability,
        damage_flags = bit.bor(DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR, DOTA_DAMAGE_FLAG_IGNORES_MAGIC_ARMOR, self.DotaDamageFlags)
    }
    for dType, dmg in mitigated:IterateDmg() do
        if dmg > 0 then
            dmgArgs.damage = dmg
            dmgArgs.damage_type = dType
            ApplyDamage(dmgArgs)
        end
    end
end

-- operator definitions (this doesn't work)
WoeDamage.__mul = function(a, b) return a:Multiply(b) end
WoeDamage.__add = function(a, b) return a:Add(b) end
WoeDamage.__div = function(a, b) return a:Divide(b) end
WoeDamage.__unm = function(x) return x:Negate() end