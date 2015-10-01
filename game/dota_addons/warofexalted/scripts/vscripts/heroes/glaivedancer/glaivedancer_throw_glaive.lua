glaivedancer_throw_glaive = class({})

local GLAIVE_THINK_RATE = 1/30
local GLAIVE_RETURN_VELOCITY_CHANGE_DELAY = 0.1

function glaivedancer_throw_glaive:GetDotDamage()
    return self:GetSpecialValueFor("base_damage") + self:GetSpecialValueFor("damage_multiplier") * self:GetCaster():GetAverageTrueAttackDamage()
end

function glaivedancer_throw_glaive:GetInitialDamage()
    return self:GetSpecialValueFor("initial_base_damage") + self:GetSpecialValueFor("initial_damage_multiplier") * self:GetCaster():GetAverageTrueAttackDamage()
end

function glaivedancer_throw_glaive:GetReturnDamage()
    return self:GetSpecialValueFor("return_base_damage") + self:GetSpecialValueFor("return_damage_multiplier") * self:GetCaster():GetAverageTrueAttackDamage()
end

function glaivedancer_throw_glaive:OnSpellStart()
    local height = 70
    local caster = self:GetCaster()
    local data = self:GetSpecials()
    local startPos = caster:GetAbsOrigin() + Vector(0,0,height)
    local targetPos = self:GetCursorPosition()
    local maxDistance = data.speed * data.travel_duration
    local targetDistance = math.min(maxDistance, (targetPos - startPos):Length2D())
    local forward = ( targetPos - self:GetAbsOrigin()):Normalized()
    forward.z = 0
    local velocity = forward * data.speed
    
    local p = Projectiles:CreateProjectile({
        Ability             = self,
        EffectName          = "particles/heroes/glaivedancer/glaivedancer_throw_glaive.vpcf",
        Source              = caster,
        fGroundOffset       = height,
        bGroundLock         = true,
        vSpawnOrigin        = startPos,
        fDistance           = maxDistance * 2,
        fStartRadius        = data.projectile_radius,
        fEndRadius          = data.projectile_radius,
        fStartRadius        = data.projectile_radius,
        fEndRadius          = data.projectile_radius,
        fExpireTime         = GameRules:GetGameTime() + 9999,
        vVelocity           = velocity,
        fRehitDelay         = data.tick_rate,
        GroundBehavior      = PROJECTILES_NOTHING,
        WallBehavior        = PROJECTILES_NOTHING,
        TreeBehavior        = PROJECTILES_NOTHING,
        UnitBehavior        = PROJECTILES_NOTHING,
        WallBehavior        = PROJECTILES_NOTHING,
        nChangeMax          = 9999999999999,
        fChangeDelay        = GLAIVE_RETURN_VELOCITY_CHANGE_DELAY,
        bCutTrees           = true,
        bZCheck             = false,
        draw                = true,
        bMultipleHits       = true,
    })
    
    p.checkFirstHit = { }
    p.attackPhase = 0   -- 0 = initial, 1 = dot, 2 = return
    
    p.OnUnitHit = function(p, unit)
        local kw = WoeKeywords(self:GetKeywords())
        local notFirstHit
        if p.attackPhase ~= 1 then -- non-dot phase
            notFirstHit = p.checkFirstHit[unit:GetEntityIndex()]
            p.checkFirstHit[unit:GetEntityIndex()] = true
        end
        local dmg
        if p.attackPhase == 1 or notFirstHit then
            dmg = self:GetDotDamage()
            kw.Add("dot")
        elseif p.attackPhase == 0 then
            dmg = self:GetInitialDamage()
            kw.Remove("dot")
        elseif p.attackPhase == 2 then
            dmg = self:GetReturnDamage()
            kw.Remove("dot")
        end
        
        ApplyWoeDamage({
            Victim = unit,
            Attacker = caster,
            Ability = self,
            Keywords = kw,
            PhysicalDamage = dmg * data.tick_rate
        })
    end
    
    --glaive thinker
    Timers:CreateTimer(GLAIVE_THINK_RATE, function()
        if p.attackPhase == 0 then -- initial phase
            if p.distanceTraveled >= targetDistance then -- has reached end of initial phase
                p:SetVelocity(Vector(0,0,0))
                p.attackPhase = 1
                return data.hover_duration -- sleep until the end of DoT phase
            end
        elseif p.attackPhase == 1 then
            p.attackPhase = 2 -- move from dot phase to return phase
            p.checkFirstHit = { }
        elseif p.attackPhase == 2 then -- return phase
            local delta = self:GetCaster():GetAbsOrigin() - p.pos -- glaive-to-caster delta
            if delta:Length2D() <= data.speed * GLAIVE_THINK_RATE * 1.5 then -- has returned to caster
                p:Destroy()
                return -- stop thinking
            end
            p:SetVelocity( data.speed * delta:Normalized() ) -- move towards caster
        end
        return GLAIVE_THINK_RATE -- continue thinking
    end)
end