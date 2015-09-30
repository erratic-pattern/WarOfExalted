pyra_conflagration = class({})

local modName = "modifier_pyra_conflagration"
LinkLuaModifier(modName, "modifiers/" .. modName, LUA_MODIFIER_MOTION_NONE)

function pyra_conflagration:OnSpellStart()
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, modName, {
        duration = self:GetSpecialValueFor("duration"),
        damage = self:GetSpecialValueFor("damage"),
        radius = self:GetSpecialValueFor("radius"),
        interval = self:GetSpecialValueFor("burn_interval"),
        fireballSpeedBonus = self:GetSpecialValueFor("fireball_speed_bonus"),
        lavaWakeDurationBonus = self:GetSpecialValueFor("lava_wake_duration_bonus"),
        lavaWakeLengthBonus = self:GetSpecialValueFor("lava_wake_length_bonus"),
    })
end