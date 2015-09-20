print("[WAROFEXALTS] loading woe_attributes")
--Hidden passive used to implement stat bonuses from attributes
woe_attributes = class({})

MINUS_ARMOR_PER_AGI = 0.14 -- amount of base armor reduced per point of agility
ARMOR_PER_STR = 0.14       -- amount of base armor increased per point of strength

local modName = "modifier_woe_attributes"
LinkLuaModifiers(modName, "modifiers/" .. modifier, LUA_MODIFIER_MOTION_NONE)

function woe_attributes:GetIntrinsicModifierName()
    return modName
end

function woe_attributes:OnHeroCalculateStatBonus()
    if IsServer() then
        print("OnHeroCalculateStatBonus")
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
