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
    local height = 75
    local caster = self:GetCaster()
    local data = self:GetSpecials()
    util.printTable(data)
    local startPos = caster:GetAbsOrigin()
    local maxDistance = data.speed * data.travel_duration
    local cursorPos = self:GetCursorPosition()
    local cursorDelta = cursorPos - startPos
    local targetDistance = math.min(maxDistance, cursorDelta:Length2D())
    local forward = cursorDelta:Normalized()
    forward.z = 0
    local targetDelta = forward * targetDistance
    local velocity = forward * data.speed
    local targetPos = startPos + targetDelta
    targetDistance = targetDelta:Length2D() -- account for rounding errors
    
    if caster.glaives = nil then
        caster.glaives = { }
    end
    
    
    local p = CreateUnitByName("npc_dummy_blank", startPos, false, caster, caster, caster:GetTeamNumber())
    caster.glaives[p:GetEntityIndex()] = p
    p.fx = ParticleManager:CreateParticle("particles/heroes/glaivedancer/glaivedancer_throw_glaive.vpcf", PATTACH_ABSORIGIN, p)
    --ParticleManager:SetParticleControl(pfx, 2, Vector(data.speed,0,0))
    Physics:Unit(p)
    p:SetPhysicsVelocity(velocity)
    p:SetGroundBehavior(PHYSICS_GROUND_LOCK)
    p.checkFirstHit = { }
    p.rehit = { }
    p.attackPhase = 0   -- 0 = initial, 1 = dot, 2 = return
    p.Destroy = function(self)
        ParticleManager:DestroyParticle(p.fx, false)
        caster.glaives[self:GetEntityIndex()] = nil
    end
    p:OnPhysicaFrame(function()
        local ents = FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, data.projectile_radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
        for _, unit in pairs(ents)
            local kw = WoeKeywords(self:GetKeywords())
            kw:Remove("dot")
            print(p.attackPhase)
            local notFirstHit
            if p.attackPhase ~= 1 then -- non-dot phase
                notFirstHit = p.checkFirstHit[unit:GetEntityIndex()]
                p.checkFirstHit[unit:GetEntityIndex()] = true
                local dmg
                if p.attackPhase == 0 then
                dmg = self:GetInitialDamage()
                kw:Remove("dot")
                elseif p.attackPhase == 2 then
                    dmg = self:GetReturnDamage()
                    kw:Remove("dot")
                end
                if dmg then -- apply non-dot hit
                    ApplyWoeDamage({
                        Victim = unit,
                        Attacker = caster,
                        Ability = self,
                        Keywords = kw,
                        PhysicalDamage = dmg
                    })
                end
            end
        
            --apply dot damage
            ApplyWoeDamage({
                Victim = unit,
                Attacker = caster,
                Keywords = WoeKeywords(kw):Add("dot"),
                PhysicalDamage = self:GetDotDamage() * data.tick_rate
            })
            
        end
    end)
    
    --glaive thinker
    Timers:CreateTimer(GLAIVE_THINK_RATE, function()
        if p.attackPhase == 0 then -- initial phase
            local delta = casterPos - p:GetAbsOrigin()
            if p.distanceTraveled >= targetDistance then -- has reached end of initial phase
                p:SetPhysicsVelocity(Vector(0,0,0))
                --ParticleManager:SetParticleControl(p.id, 2, Vector(0,0,0))
                p.attackPhase = 1             
                return data.hover_duration -- sleep until the end of DoT phase
            end
        elseif p.attackPhase == 1 then
            p.attackPhase = 2 -- move from dot phase to return phase
            p.checkFirstHit = { }
            --ParticleManager:SetParticleControl(p.id, 2, Vector(data.speed,0,0))
        elseif p.attackPhase == 2 then -- return phase
            local casterPos = self:GetCaster():GetAbsOrigin()
            local delta = casterPos - p:GetAbsOrigin() -- glaive-to-caster delta
            if delta:Length2D() <= data.speed * GLAIVE_THINK_RATE * 1.5 then -- has returned to caster
                p:Destroy()
                return -- stop thinking
            end
            p:SetPhysicsVelocity( data.speed * delta:Normalized() )
        end
        return GLAIVE_THINK_RATE -- continue thinking
    end)
end