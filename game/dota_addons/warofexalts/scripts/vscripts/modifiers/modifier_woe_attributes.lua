--Modifier used to implement stat bonuses from attributes
modifier_woe_attributes = class({})

MINUS_ARMOR_PER_AGI = 0.14 -- amount of base armor reduced per point of agility
HASTE_PER_AGI = 0.3        -- amount of spell haste increased per point of agility
ARMOR_PER_STR = 0.10       -- amount of base armor increased per point of strength
MR_PER_INT = 0.10          -- amount of base magic resist increased per point of intelligence

--initializer
function modifier_woe_attributes:OnCreated(kv)
    local unit = self:GetParent()
    if not unit:IsHero() then
        print("Warning: modifier_woe_attributes applied to non-hero unit")       
    self.updateInterval = 0.1 or kv.updateInterval
    self.lastStr = 0
    self.lastAgi = 0
    self.lastInt = 0
    if kv.skipCurrentAttributes then     -- if true, ignore existing attributes during the first update cycle
        self.lastStr = unit:GetStrength()
        self.lastAgi = unit:GetAgility()
        self.lastInt = unit:GetIntellect()
    end
    self:StartIntervalThink(self.updateInterval) -- start update loop
end

--update loop
function modifier_woe_attributes:OnIntervalThink()
    local unit = self:GetParent(),
          diffStr = unit:GetStrength() - self.lastStr,
          diffAgi = unit:GetAgility() - self.lastAgi,
          diffInt = unit:GetIntellect() - self.lastInt
      
    unit:SetPhysicalArmorBaseValue(unit:GetPhysicalBaseArmorValue() - diffAgi*MINUS_ARMOR_PER_AGI + diffStr*ARMOR_PER_STR)
    unit:SetWoeMagicResistBase(unit:GetWoeMagicResistBase() + MR_PER_INT * diffInt)
    unit:SetSpellHaste(unit:GetSpellHaste() + HASTE_PER_AGI * diffAgi)
end

--overridden from the parent modifier
function modifier_woe_attributes:IsHidden(kv)
    return true
end

--overridden from the parent modifier
function modifier_Woe_attributes:IsPurgable()
    return false
end


-- Returns the interval in seconds that stats are updated by
function modifier_woe_attributes:GetUpdateInterval()
    return self.updateInterval
end

-- Sets the interval in seconds where stats are updated
function modifier_woe_attributes:SetUpdateInterval(i)
    self.updateInterval = i
    self:StartIntervalThink(-1) -- stop previous think (not sure if actually needed)
    self:StartIntervalThink(i)  -- start think with new interval
end


