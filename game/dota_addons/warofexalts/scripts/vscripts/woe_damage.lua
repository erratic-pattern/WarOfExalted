
function ApplyWoeDamage(dmgArgs)
    local dmg = WoeDamage()
    dmg:init(dmgArgs)
    dmg:Apply()
end


WoeDamage = class({})

--Damage instances in WoE are slightly different from those in dota: 
--they can have multiple damage types, and have special keywords associated with them
function WoeDamage:init(keys)
    self.victim = keys.victim
    self.attacker = keys.attacker
    self.physicalDamage = keys.physicalDamage or 0
    self.magicalDamage = keys.magicalDamage or 0
    self.pureDamage = keys.pureDamage or 0
    
    --initialize critical damage
    self:ResetCritDamage()
    updateKeys(self.critDamage, keys.critDamage)
      
    --ability keywords
    self.keywords = {}
    local t = type(keys.keywords)
    if t == "string" then
        for _, kWord in pairs(string.split(keys.keywords)) do
            self.keywords[kWord] = true
        end
    elseif t == "table" then
        self.keywords = keys.keywords
    else
        print("Warning: Invalid value for WoeDamage keywords parameter: ", keys.keywords)
    end
end

function WoeDamage:HasKeyword(kWord)
    return self.keywords[kWord]
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
    c.physicalDamage = c.physicalDamage + self.physicalDamage * modifier * self:GetNonCriticalPhysicalPercent()
    c.magicalDamage = c.magicalDamage + self.magicalDamage * modifier * self:GetNonCriticalMagicalPercent()
    c.pureDamage = c.pureDamage + self.pureDamage * modifier * self:GetNonCriticalPurePercent()
end

--applies crit damage, replacing any existing crit damage only if the new crit amount is greater than the previous
function WoeDamage:AddCrit(modifier)
    if modifier * self:GetTotalNonCritDamage() > self:GetTotalCritDamage() then
        self:ResetCritDamage()
        self:AddCritStacking(modifier)
    end
end

function WoeDamage:ResetCritDamage()
    self.critDamage = {
        physicalDamage = 0,
        magicalDamage = 0,
        pureDamage = 0
    }
end

function WoeDamage:ApplyNonCritModifier(modifier)
    self.physicalDamage = self.physicalDamage * modifier * self:GetNonCriticalPhysicalPercent()
    self.magicalDamage = self.magicalDamage * modifier * self:GetNonCriticalMagicalPercent()
    self.pureDamage = self.pureDamage * modifier * self:GetNonCriticalPurePercent()
end

--Apply the damage from attacker to victim
function WoeDamage:Apply()
    self.attacker:CallOnModifiers("OnDealWoeDamage", self)
    self.victim:CallOnModifiers("OnTakeWoeDamage", self)
    local dmgArgs = {
        victim = self.victim,
        attacker = self.attacker
    }
    local dmgIter = { }
    dmgIter[DAMAGE_TYPE_PHYSICAL] = self:GetPhysicalDamage()
    dmgIter[DAMAGE_TYPE_MAGICAL] = self:GetMagicalDamage()
    dmgIter[DAMAGE_TYPE_PURE] = self:GetPureDamage()
    for dType, dmg in pairs(dmgIter) do
        if dmg > 0 then
            dmgArgs.damage = dmg
            dmgArgs.damage_type = dType
            ApplyDamage(dmgArgs)
        end
    end
end