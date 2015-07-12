
print("debug_projectiles: script file invoked")
debug_projectiles = class({})
function debug_projectiles:constructor()
    print("debug_projectiles: constructor called")
end

function DebugTable(name, t)
    local out = { __isDebugTable = true, __debugTableName = name or "table" }
    setmetatable(out, {
        isDebugMetaTable = true,
        __index = function(_, key)
            print(name .. " key access: ", key)
            return t[key]
        end,
        __newindex = function(_, key, val) 
            print(name .. " key update: ", key, " = ", val)
            if type(val) == "table" then
                util.printTable(val)
            end
            t[key] = val
        end
    })
    return out
end

function CheckDebugTable(t)
    if t == nil then
        print("CheckDebugTable: nil")
        return false
    elseif type(t) == 'table' then
        if not t.__isDebugTable then
            print ("CheckDebugTable: not a debug table")
            return false
        elseif not getmetatable(t).isDebugMetaTable then
            print ("CheckDebugTable: " .. t.__debugTableName .. " metatable unset by volvo")
            return false
        else
            return true
        end
    else
        print("CheckDebugTable: type is " .. type(t) .. " not table")
        return false
    end
end

local extra
local infoTracking
local infoLinear

function debug_projectiles:OnSpellStart()
    extra = DebugTable("ExtraData", {nThinkCalls = 0})
    infoTracking = DebugTable("tracking projectile info", {
        EffectName = "particles/units/heroes/hero_vengeful/vengeful_magic_missle.vpcf",
        Ability = self,
        iMoveSpeed = 1500,
        Source = self:GetCaster(),
        Target = self:GetCaster(),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2,
        ExtraData = extra
    })
    infoLinear = DebugTable("linear projectile info", {
        EffectName = "particles/units/heroes/hero_vengeful/vengeful_magic_missle.vpcf",
        Ability = self,
        vSpawnOrigin = self:GetCaster():GetAbsOrigin(),
        Source = self:GetCaster(),
        vVelocity = Vector(1,0,0),
        fExpireTime = GameRules:GetGameTime() + 0.1,
        ExtraData = extra
    })
    print("Creating tracking projectile...")
    local pId = ProjectileManager:CreateTrackingProjectile(infoTracking) --todo: see if this generates projectile IDs outside of return
                                                                         --todo: run tests OnProjectileHit
    print("Creating linear projectile...")
    local pId2 = ProjectileManager:CreateLinearProjectile(infoLinear)
    EmitSoundOn("Hero_VengefulSpirit.MagicMissile", self:GetCaster())
    CheckDebugTable(infoTracking)
    CheckDebugTable(infoLinear)
    CheckDebugTable(extra)
end

function debug_projectiles:OnProjectileThink_ExtraData(vLocation, extraData)
    --print("vLocation: ", vLocation)
    CheckDebugTable(infoTracking)
    CheckDebugTable(infoLinear)
    CheckDebugTable(extra)
    CheckDebugTable(extraData)
    extraData.nThinkCalls = extraData.nThinkCalls + 1
end

function debug_projectiles:OnProjectileHit_ExtraData( hTarget, vLocation, extraData )
    print("OnProjectileHit; extraData.nThinkCalls = ", extraData.nThinkCalls)
    EmitSoundOn("Hero_VengefulSpirit.MagicMissileImpact", hTarget)
    CheckDebugTable(infoTracking)
    CheckDebugTable(infoLinear)
    CheckDebugTable(extra)
    return true
end