pyra_fireball = class({})

function pyra_fireball:GetAreaRadius()
    return self:GetSpecialValueFor("area_radius") * 1
end

function pyra_fireball:GetProjectileSpeed()
    local speed = self:GetSpecialValueFor("speed")
    if IsServer() then 
        local conflagration = self:GetCaster():FindModifierByName("modifier_pyra_conflagration")
        if conflagration then
            speed = speed + conflagration.fireballSpeedBonus
        end
    end
    return speed
end

function pyra_fireball:GetCastRange()

    return self:GetSpecialValueFor("duration") * self:GetProjectileSpeed()
end

function pyra_fireball:OnSpellStart()
    local height = 70
    local caster = self:GetCaster()
    local data = self:GetSpecials()
    local startPos = caster:GetAbsOrigin() + Vector(0,0,height)
    local maxDistance = data.speed*data.duration
    local forward = (self:GetCursorPosition() - self:GetAbsOrigin()):Normalized()
    forward.z = 0
    local velocity = forward * self:GetProjectileSpeed()
    
    function Explode(p)
        local pfx = ParticleManager:CreateParticle("particles/heroes/pyra/fireball_explosion.vpcf", PATTACH_ABSORIGIN, caster)
        ParticleManager:SetParticleControl(pfx, 1, p.vel)
        ParticleManager:SetParticleControl(pfx, 3, p.pos)
        ParticleManager:SetParticleControl(pfx, 4, Vector(1,1,1))
        --DebugDrawCircle(p.pos, Vector(200,0,0), 1, self:GetAreaRadius(), false, 2)
        local ents = self:FindUnitsInRadius(p.pos, self:GetAreaRadius())
        for _, unit in ipairs(ents) do
            ApplyWoeDamage({
                Victim = unit,
                Attacker = caster,
                Ability = self,
                MagicalDamage = self:GetAbilityDamage()
            })
        end
        GridNav:DestroyTreesAroundPoint(p.pos, self:GetAreaRadius(), false)
    end
    
    Projectiles:CreateProjectile({
        Ability             = self,
        EffectName          = "particles/heroes/pyra/fireball.vpcf",
        Source              = caster,
        fGroundOffset       = height,
        bGroundLock         = true,
        vSpawnOrigin        = startPos,
        fDistance           = maxDistance,
        fStartRadius        = data.projectile_radius,
        fEndRadius          = data.projectile_radius,
        fExpireTime         = GameRules:GetGameTime() + data.duration,
        vVelocity           = velocity,
        GroundBehavior      = PROJECTILES_NOTHING,
        WallBehavior        = PROJECTILES_NOTHING,
        TreeBehavior        = PROJECTILES_NOTHING,
        UnitBehavior        = PROJECTILES_DESTROY,
        WallBehavior        = PROJECTILES_NOTHING,
        --fChangeDelay        = 0.1,
        bCutTrees           = true,
        bZCheck             = false,
        --draw                = true,
        bProvidesVision     = true,
        iVisionRadius       = data.vision_radius,
        OnFinish = function(p)
            --Explode(p)
        end,
        OnUnitHit   = function(p, unit)
            Explode(p)
        end,
    })
end

