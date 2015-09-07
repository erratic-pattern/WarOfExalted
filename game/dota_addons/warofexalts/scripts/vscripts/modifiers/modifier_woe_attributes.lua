--Modifier used to implement stat bonuses from attributes
modifier_woe_attributes = class({})

MINUS_ARMOR_PER_AGI = 0.14 -- amount of base armor reduced per point of agilit
SS_PER_AGI = 0.3           -- amount of spell speed increased per point of agility
ARMOR_PER_STR = 0.07       -- amount of base armor increased per point of strength
MR_PER_INT = 0.07          -- amount of base magic resist increased per point of intelligence
STAM_PER_AGI = 5           -- amount of max stamina increased per point of agi


function modifier_woe_attributes:IsHidden(kv)
    return true
end

function modifier_woe_attributes:IsPurgable()
    return false
end


--initializer
function modifier_woe_attributes:OnCreated(kv)
    if IsServer() then
        local unit = self:GetParent()
        if not unit:IsHero() then
            print("Warning: modifier_woe_attributes applied to non-hero unit")
        end
        
        self.updateInterval = kv.updateInterval or 0.01
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
end

--update loop
function modifier_woe_attributes:OnIntervalThink()
    if IsServer() then
        local unit = self:GetParent()
        local diffStr = unit:GetStrength() - self.lastStr
        local diffAgi = unit:GetAgility() - self.lastAgi
        local diffInt = unit:GetIntellect() - self.lastInt
          
        unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorBaseValue() - diffAgi*MINUS_ARMOR_PER_AGI + diffStr*ARMOR_PER_STR)
        unit:SetWoeMagicResistBase(unit:GetWoeMagicResistBase() + MR_PER_INT * diffInt)
        unit:SetSpellSpeedBase(unit:GetSpellSpeed() + SS_PER_AGI * diffAgi)
        unit:SetMaxStamina(unit:GetMaxStamina() + STAM_PER_AGI * diffAgi)
        
        self.lastStr = unit:GetStrength()
        self.lastAgi = unit:GetAgility()
        self.lastInt = unit:GetIntellect()
    end
end
