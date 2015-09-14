--Modifier used to implement stat bonuses from attributes
woe_attributes = class({}, nil)

MINUS_ARMOR_PER_AGI = 0.14 -- amount of base armor reduced per point of agility
ARMOR_PER_STR = 0.14       -- amount of base armor increased per point of strength

function woe_attributes:OnHeroCalculateStatBonus()
    if IsServer() then
        self.lastStr = self.lastStr or 0
        self.lastAgi = self.lastAgi or 0
        local unit = self:GetCaster()
        local diffStr = unit:GetStrength() - self.lastStr
        local diffAgi = unit:GetAgility() - self.lastAgi
        self.lastStr = unit:GetStrength()
        self.lastAgi = unit:GetAgility()
          
        unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorBaseValue() - diffAgi*MINUS_ARMOR_PER_AGI + diffStr*ARMOR_PER_STR)
    end
end
