--Modifier used to implement stat bonuses from attributes
woe_attributes = class({})

MINUS_ARMOR_PER_AGI = 0.14 -- amount of base armor reduced per point of agility
SS_PER_AGI = 0.5           -- amount of spell speed increased per point of agility
ARMOR_PER_STR = 0.14       -- amount of base armor increased per point of strength
MR_PER_INT = 0.14          -- amount of base magic resist increased per point of intelligence
STAM_PER_AGI = 5           -- amount of max stamina increased per point of agi

function woe_attributes:OnHeroCalculateStatBonus()
    if IsServer() then
        self.lastStr = self.lastStr or 0
        self.lastAgi = self.lastAgi or 0
        self.lastInt = self.lastInt or 0
        local unit = self:GetCaster()
        local diffStr = unit:GetStrength() - self.lastStr
        local diffAgi = unit:GetAgility() - self.lastAgi
        local diffInt = unit:GetIntellect() - self.lastInt
        self.lastStr = unit:GetStrength()
        self.lastAgi = unit:GetAgility()
        self.lastInt = unit:GetIntellect()
          
        unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorBaseValue() - diffAgi*MINUS_ARMOR_PER_AGI + diffStr*ARMOR_PER_STR)
        unit:BatchUpdate(function()
            unit:SetWoeMagicResistBase(unit:GetWoeMagicResistBase() + MR_PER_INT * diffInt)
            unit:SetSpellSpeedBase(unit:GetSpellSpeed() + SS_PER_AGI * diffAgi)
            unit:SetMaxStamina(unit:GetMaxStamina() + STAM_PER_AGI * diffAgi)
        end)
    end
end
