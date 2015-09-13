require("util")
require("woe_keywords")

--Damage instances in WoE are slightly different from those in dota, and thus use an overhauled system. 
--WoE damage can have multiple damage types per instance, and has special Keywords.
--Additionally, all damage types can have critical strike damage.



--Analogous to ApplyDamage. Takes a table of parameters.
--  Required parameters: 
--      Victim - the entity receiving damage
--      Attacker - the entity dealing damage
--  Damage parameters (not required, but at least one should probably be used):
--      PhysicalDamage - Amount of non-critical physical damage to deal
--      MagicalDamage - amount of non-critical magical damage to deal
--      PureDamage - amount of non-critical pure damage to deal
--      CritDamage - a table containing optional PhysicalDamage, MagicalDamage, and PureDamage keys
--                   representing damage from critical strikes.
--  Optional parameters:
--      Keywords     - A list of Keywords associated with this damage. Can be specified as either
--                     an array of strings or a string of words delimited by spaces
--      Ability      - ability source of the damage (optional)
--      damage_flags - passed directly to damage_flags parameter of ApplyDamage
--
--  ApplyWoeDamage also supports the damage and damage_flags for compatibility with code that uses ApplyDamage, however only
--  physical, magical, and pure damage types are supported. This may change in the future. For new code that doesn't need to be
--  compatible with ApplyDamage, using damage and damage_types is discouraged.
function ApplyWoeDamage(dmgArgs)
    local dmg = WoeDamage(dmgArgs)
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
    
    --critical damage
    self.CritDamage = {
        PhysicalDamage = 0,
        MagicalDamage = 0,
        PureDamage = 0
    }
    util.updateTable(self.CritDamage, keys.CritDamage)
      
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

--Combine multiple damage instances into a new one.
function WoeDamage.Combine(...)
    local outDmg = WoeDamage()
    for n=1,select("#", ...) do
        local inDmg = select(n, ...)
        outDmg.Victim = outDmg.Victim or inDmg.Victim
        outDmg.Attacker = outDmg.Attacker or inDmg.Attacker
        outDmg.Ability = outDmg.Ability or inDmg.Ability
        outDmg.DotaDamageFlags = bit.bor(outDmg.DotaDamageFlags, inDmg.DotaDamageFlags)
        outDmg.PhysicalDamage = outDmg.PhysicalDamage + inDmg.PhysicalDamage
        outDmg.MagicalDamage = outDmg.MagicalDamage + inDmg.MagicalDamage
        outDmg.PureDamage = outDmg.PureDamage + inDmg.PureDamage
        outDmg.CritDamage.PhysicalDamage = outDmg.CritDamage.PhysicalDamage + inDmg.CritDamage.PhysicalDamage
        outDmg.CritDamage.MagicalDamage = outDmg.CritDamage.MagicalDamage + inDmg.CritDamage.MagicalDamage
        outDmg.CritDamage.PureDamage = outDmg.CritDamage.PureDamage + inDmg.CritDamage.PureDamage
        outDmg.Keywords:UnionInPlace(inDmg.Keywords)   
    end
    return outDmg
end

--Create a copy
function WoeDamage:Clone()
    return WoeDamage(self)
end

function WoeDamage:IsMitigated()
    return self.isMitigated
end

function WoeDamage:GetKeywords()
    return self.Keywords
end

function WoeDamage:GetTotalNonCritDamage()
    return self.PhysicalDamage + self.MagicalDamage + self.PureDamage
end

function WoeDamage:GetTotalCritDamage()
    local c = self.CritDamage
    return c.PhysicalDamage + c.MagicalDamage + c.PureDamage
end

function WoeDamage:GetTotalDamage()
    return self:GetTotalNonCritDamage() + self:GetTotalCritDamage()
end

function WoeDamage:GetPhysicalDamage()
    return self.PhysicalDamage + self.CritDamage.PhysicalDamage
end

function WoeDamage:GetMagicalDamage()
    return self.MagicalDamage + self.CritDamage.MagicalDamage
end

function WoeDamage:GetPureDamage()
    return self.PureDamage + self.CritDamage.PureDamage
end

function WoeDamage:GetNonCritPhysicalPercent()
    return self.PhysicalDamage / self:GetTotalNonCritDamage()
end

function WoeDamage:GetNonCritMagicalPercent()
    return self.MagicalDamage / self:GetTotalNonCritDamage()
end

function WoeDamage:GetNonCriticalPurePercent()
    return self.PureDamage / self:GetTotalNonCritDamage()
end

--applies crit damage, fully stacking with any existing crit
function WoeDamage:AddCritStacking(modifier)
    local c = self.CritDamage
    c.PhysicalDamage = c.PhysicalDamage + self.PhysicalDamage * modifier
    c.MagicalDamage = c.MagicalDamage + self.MagicalDamage * modifier
    c.PureDamage = c.PureDamage + self.PureDamage * modifier
end

--applies crit damage, replacing any existing crit damage only if the new crit amount is greater than the previous
function WoeDamage:AddCrit(modifier)
    if modifier * self:GetTotalNonCritDamage() > self:GetTotalCritDamage() then
        self:RemoveCritDamage()
        self:AddCritStacking(modifier)
    end
end

function WoeDamage:RemoveCritDamage()
    self.CritDamage = {
        PhysicalDamage = 0,
        MagicalDamage = 0,
        PureDamage = 0
    }
end

--Applies percent damage modifier to the non-crit portion of the damage. Note that any crit applied
--afterwards with AddCrit/AddCritStacking calls will still be affected.
function WoeDamage:ApplyNonCritDamageModifier(modifier)
    self.PhysicalDamage = self.PhysicalDamage * modifier
    self.MagicalDamage = self.MagicalDamage * modifier
    self.PureDamage = self.PureDamage * modifier
end

--Applies damage modifier to all damage (crit and non-crit)
function WoeDamage:ApplyDamageModifier(modifier)
    self:ApplyNonCritDamageModifier(modifier)
    self:AddCritStacking(modifier)
end

--Convert all crit damage into non-crit damage.
function WoeDamage:FlattenCrit()
    self.PhysicalDamage = self.PhysicalDamage + self.CritDamage.PhysicalDamage
    self.MagicalDamage = self.MagicalDamage + self.CritDamage.MagicalDamage
    self.PureDamage = self.PureDamage + self.CritDamage.PureDamage
    self:RemoveCritDamage()
end

--Apply the damage from Attacker to Victim
function WoeDamage:Apply()
    local mitigated
    if self:IsMitigated() then
        mitigated = self
    else
        self.Attacker:CallOnModifiers("OnDealWoeDamagePreMitigation", self)
        self.Victim:CallOnModifiers("OnTakeWoeDamagePreMitigation", self)
        mitigated = self:_ApplyMitigation()
    end
    self.Attacker:CallOnModifiers("OnDealWoeDamage", mitigated)
    self.Victim:CallOnModifiers("OnTakeWoeDamage", mitigated)
    local dmgArgs = {
        victim = self.Victim,
        attacker = self.Attacker,
        ability = self.Ability,
        damage_flags = bit.bor(DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR, DOTA_DAMAGE_FLAG_IGNORES_MAGIC_ARMOR, self.DotaDamageFlags)
    }
    local dmgIter = {
        [DAMAGE_TYPE_PHYSICAL] = mitigated:GetPhysicalDamage(),
        [DAMAGE_TYPE_MAGICAL] = mitigated:GetMagicalDamage(),
        [DAMAGE_TYPE_PURE] = mitigated:GetPureDamage()
    }
    for dType, dmg in ipairs(dmgIter) do
        if dmg > 0 then
            dmgArgs.damage = dmg
            dmgArgs.damage_type = dType
            ApplyDamage(dmgArgs)
        end
    end
end

function WoeDamage:_ApplyMitigation()
    local mitigated = WoeDamage(self)
    mitigated.isMitigated = true
    mitigated.unmitigated = self
    --print("WoeDamage:_ApplyMitigation")
    local armor = self.Victim:GetPhysicalArmorValue()
    local physReduction = 1 - 0.06 * armor / (1 + 0.06 * armor)
    --print("armor: ", armor)
    --print("unmitigated phys: ", self:GetPhysicalDamage())
    --print("phys modifier: ", physReduction)
    mitigated.PhysicalDamage = physReduction * self.PhysicalDamage
    mitigated.CritDamage.PhysicalDamage = physReduction * self.CritDamage.PhysicalDamage
    --print("mitigated phys: ", self:GetPhysicalDamage())
    local magReduction = 1 - self.Victim:GetMagicalArmorValue()
    --print("mr: ", self.Victim:GetWoeMagicResist())
    --print("unmitigated magic: ", self:GetMagicalDamage())
    --print("magic modifier", magReduction)
    mitigated.MagicalDamage = magReduction * self.MagicalDamage
    mitigated.CritDamage.MagicalDamage = magReduction * self.CritDamage.MagicalDamage
    --print("mitigated magic: ", self:GetMagicalDamage())
    return mitigated
end