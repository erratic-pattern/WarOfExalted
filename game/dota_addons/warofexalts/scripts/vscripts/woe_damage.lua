--Damage instances in WoE are slightly different from those in dota, and thus use an overhauled system. 
--WoE damage can have multiple damage types per instance, and has special keywords.
--Additionally, all damage types can have critical strike damage.



--Analogous to ApplyDamage. Takes a table of parameters.
--  Required parameters: 
--      victim - the entity receiving damage
--      attacker - the entity dealing damage
--  Damage parameters (not required, but at least one should probably be used):
--      physicalDamage - Amount of non-critical physical damage to deal
--      magicalDamage - amount of non-critical magical damage to deal
--      pureDamage - amount of non-critical pure damage to deal
--      critDamage - a table containing optional physicalDamage, magicalDamage, and pureDamage keys
--                   representing damage from critical strikes.
--  Optional parameters:
--      keywords - A list of keywords associated with this damage. Can be specified as either
--                 an array of strings or a string of words delimited by spaces
--      ability - ability source of the damage (optional)
--      dotaDamageFlags - passed directly to damage_flags parameter of ApplyDamage (optional)   
function ApplyWoeDamage(dmgArgs)
    local dmg = WoeDamage(dmgArgs)
    dmg:Apply()
end


--Class used to represent instances of WoE damage. Initialization parameters are the same as ApplyWoeDamage
WoeDamage = class({})
function WoeDamage:constructor(keys)
    print("WoeDamage:constructor")
    keys = keys or {}
    
    --information about the damage (passed directly to ApplyDamage)
    self.victim = keys.victim
    self.attacker = keys.attacker
    self.ability = keys.ability
    self.dotaDamageFlags = util.normalizeBitFlags(keys.damage_flags)
    
    --damage types and their values
    self.physicalDamage = keys.physicalDamage or 0
    self.magicalDamage = keys.magicalDamage or 0
    self.pureDamage = keys.pureDamage or 0
    
    --Compatability with ApplyDamage
    if keys.damage then
        if keys.damage_type == DAMAGE_TYPE_PHYSICAL then
            self.physicalDamage = self.physicalDamage + keys.damage
        elseif self.damage_type = DAMAGE_TYPE_MAGICAL then
            self.magicalDamage = self.magicalDamage + keys.damage
        elseif self.damage_type == DAMAGE_TYPE_PURE then
            self.pureDamage = self.pureDamage + keys.damage
        elseif not keys.damage_type then
            print("Warning: damage key used but no damage_type given. Key was ignored")
        else
            print("WoeDamage doesn't support damage_type " .. keys.damage_type)
    end
    
    --critical damage
    self.critDamage = {
        physicalDamage = 0,
        magicalDamage = 0,
        pureDamage = 0
    }
    util.updateTable(self.critDamage, keys.critDamage)
      
    --ability keywords
    self.keywords = WoeKeywords(keys.keywords)
end

--Combine multiple damage instances into a new one.
function WoeDamage.Combine(...)
    local outDmg = WoeDamage()
    for _, inDmg in pairs(arg) do
        outDmg.victim = outDmg.victim or inDmg.victim
        outDmg.attacker = outDmg.attacker or inDmg.attacker
        outDmg.ability = outDmg.ability or inDmg.ability
        outDmg.dotaDamageFlags = bit.bor(outDmg.dotaDamageFlags, inDmg.dotaDamageFlags)
        outDmg.physicalDamage = outDmg.physicalDamage + inDmg.physicalDamage
        outDmg.magicalDamage = outDmg.magicalDamage + inDmg.magicalDamage
        outDmg.pureDamage = outDmg.pureDamage + inDmg.pureDamage
        outDmg.critDamage.physicalDamage = outDmg.critDamage.physicalDamage + inDmg.critDamage.physicalDamage
        outDmg.critDamage.magicalDamage = outDmg.critDamage.magicalDamage + inDmg.critDamage.magicalDamage
        outDmg.critDamage.pureDamage = outDmg.critDamage.pureDamage + inDmg.critDamage.pureDamage
        outDmg.keywords:UnionInPlace(inDmg.keywords)   
    end
    return outDmg
end

--Create a copy
function WoeDamage:Clone()
    return WoeDamage.Combine(self)
end

function WoeDamage:IsMitigated()
    return self.mitigated
end

function WoeDamage:Keywords()
    return self.keywords
end

function WoeDamage:GetTotalNonCritDamage()
    return self.physicalDamage + self.magicalDamage + self.pureDamage
end

function WoeDamage:GetTotalCritDamage()
    local c = self.critDamage
    return c.physicalDamage + c.magicalDamage + c.pureDamage
end

function WoeDamage:GetTotalDamage()
    return self:GetTotalNonCritDamage() + self:GetTotalCritDamage()
end

function WoeDamage:GetPhysicalDamage()
    return self.physicalDamage + self.critDamage.physicalDamage
end

function WoeDamage:GetMagicalDamage()
    return self.magicalDamage + self.critDamage.magicalDamage
end

function WoeDamage:GetPureDamage()
    return self.pureDamage + self.critDamage.pureDamage
end

function WoeDamage:GetNonCritPhysicalPercent()
    return self.physicalDamage / self:GetTotalNonCritDamage()
end

function WoeDamage:GetNonCritMagicalPercent()
    return self.magicalDamage / self:GetTotalNonCritDamage()
end

function WoeDamage:GetNonCriticalPurePercent()
    return self.pureDamage / self:GetTotalNonCritDamage()
end

--applies crit damage, fully stacking with any existing crit
function WoeDamage:AddCritStacking(modifier)
    local c = self.critDamage
    c.physicalDamage = c.physicalDamage + self.physicalDamage * modifier
    c.magicalDamage = c.magicalDamage + self.magicalDamage * modifier
    c.pureDamage = c.pureDamage + self.pureDamage * modifier
end

--applies crit damage, replacing any existing crit damage only if the new crit amount is greater than the previous
function WoeDamage:AddCrit(modifier)
    if modifier * self:GetTotalNonCritDamage() > self:GetTotalCritDamage() then
        self:RemoveCritDamage()
        self:AddCritStacking(modifier)
    end
end

function WoeDamage:RemoveCritDamage()
    self.critDamage = {
        physicalDamage = 0,
        magicalDamage = 0,
        pureDamage = 0
    }
end

--Applies percent damage modifier to the non-crit portion of the damage. Note that any crit applied
--afterwards with AddCrit/AddCritStacking calls will still be affected.
function WoeDamage:ApplyNonCritDamageModifier(modifier)
    self.physicalDamage = self.physicalDamage * modifier
    self.magicalDamage = self.magicalDamage * modifier
    self.pureDamage = self.pureDamage * modifier
end

--Applies damage modifier to all damage (crit and non-crit)
function WoeDamage:ApplyDamageModifier(modifier)
    self:ApplyNonCritDamageModifier(modifier)
    self:AddCritStacking(modifier)
end

--Convert all crit damage into non-crit damage.
function WoeDamage:FlattenCrit()
    self.physicalDamage = self.physicalDamage + self.critDamage.physicalDamage
    self.magicalDamage = self.magicalDamage + self.critDamage.magicalDamage
    self.pureDamage = self.pureDamage + self.critDamage.pureDamage
    self:RemoveCritDamage()
end

--Apply the damage from attacker to victim
function WoeDamage:Apply()
    if not self:IsMitigated() then
        self.attacker:CallOnModifiers("OnDealWoeDamagePreMitigation", self)
        self.victim:CallOnModifiers("OnTakeWoeDamagePreMitigation", self)
        self:_ApplyMitigation()
    end
    self.attacker:CallOnModifiers("OnDealWoeDamage", self)
    self.victim:CallOnModifiers("OnTakeWoeDamage", self)
    local dmgArgs = {
        victim = self.victim,
        attacker = self.attacker,
        ability = self.ability,
        damage_flags = bit.bor(DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR, DOTA_DAMAGE_FLAG_IGNORES_MAGIC_ARMOR, self.dotaDamageFlags)
    }
    local dmgIter = {
        [DAMAGE_TYPE_PHYSICAL] = self:GetPhysicalDamage(),
        [DAMAGE_TYPE_MAGICAL] = self:GetMagicalDamage(),
        [DAMAGE_TYPE_PURE] = self:GetPureDamage()
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
    print("WoeDamage:_ApplyMitigation")
    local armor = self.victim:GetPhysicalArmorValue()
    local physReduction = 1 - 0.06 * armor / (1 + 0.06 * armor)
    print("armor: ", armor)
    print("unmitigated phys: ", self:GetPhysicalDamage())
    print("phys modifier: ", physReduction)
    self.physicalDamage = physReduction * self.physicalDamage
    self.critDamage.physicalDamage = physReduction * self.critDamage.physicalDamage
    print("mitigated phys: ", self:GetPhysicalDamage())
    local magReduction = 1 - self.victim:GetMagicalArmorValue()
    print("mr: ", self.victim:GetWoeMagicResist())
    print("unmitigated magic: ", self:GetMagicalDamage())
    print("magic modifier", magReduction)
    self.magicalDamage = magReduction * self.magicalDamage
    self.critDamage.magicalDamage = magReduction * self.critDamage.magicalDamage
    print("mitigated magic: ", self:GetMagicalDamage())
    self.mitigated = true
end