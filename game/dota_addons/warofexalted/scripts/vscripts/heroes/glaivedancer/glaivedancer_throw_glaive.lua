glaivedancer_throw_glaive = class({})

local GLAIVE_THINK_RATE = 1/30

--attack phases
local ATTACK_PHASE_START, 
      ATTACK_PHASE_HOVER,
      ATTACK_PHASE_RETURN,
      ATTACK_PHASE_STORM_TARGET,
      ATTACK_PHASE_STORM_SPIRAL 
      = 0,1,2,3,4

function glaivedancer_throw_glaive:GetDotDamage()
    return self:GetSpecialValueFor("dot_base_damage") + self:GetSpecialValueFor("dot_damage_multiplier") * self:GetCaster():GetAverageTrueAttackDamage()
end

function glaivedancer_throw_glaive:GetInitialDamage()
    return self:GetSpecialValueFor("initial_base_damage") + self:GetSpecialValueFor("initial_damage_multiplier") * self:GetCaster():GetAverageTrueAttackDamage()
end

function glaivedancer_throw_glaive:GetReturnDamage()
    return self:GetSpecialValueFor("return_base_damage") + self:GetSpecialValueFor("return_damage_multiplier") * self:GetCaster():GetAverageTrueAttackDamage()
end

function glaivedancer_throw_glaive:GetFrostModifier()
    return self:GetCaster():FindModifierByName("modifier_glaivedancer_frost_glaives_buff")
end

function glaivedancer_throw_glaive:GetStormModifier()
    return self:GetCaster():FindModifierByName("modifier_glaivedancer_glaive_storm_buff")
end

function glaivedancer_throw_glaive:OnSpellStart()
    local caster = self:GetCaster()
    local data = self:GetSpecials()
    local startPos = caster:GetAbsOrigin()
    local cursorPos = self:GetCursorPosition()
    local cursorDelta = cursorPos - startPos
    local maxDistance = data.max_average_speed * data.travel_duration
    local targetDistance = math.min(maxDistance, cursorDelta:Length2D())
    local distanceRatio = targetDistance / maxDistance
    local forward = cursorDelta:Normalized()
    forward.z = 0
    local maxSpeed = data.acceleration_factor * data.max_average_speed
    local initialSpeed = maxSpeed * distanceRatio
    local initialVelocity = forward * initialSpeed
    local initialAcceleration = -initialVelocity * (data.acceleration_factor/2) / data.travel_duration
    print(targetDistance,  initialSpeed, initialAcceleration:Length2D())
    --local targetPos = startPos + targetDelta
    --targetDistance = targetDelta:Length2D() -- account for rounding errors
    
    
    local p = CreateUnitByName("npc_dummy_unit", startPos, false, caster, caster, caster:GetTeamNumber())
    p:GetAbilityByIndex(0):SetLevel(1)
    p.fx = ParticleManager:CreateParticle("particles/heroes/glaivedancer/glaivedancer_throw_glaive.vpcf", PATTACH_ABSORIGIN_FOLLOW, p)
    Physics:Unit(p)
    p:SetPhysicsVelocityMax(maxSpeed)
    p:SetPhysicsFriction(0)
    p:SetVelocityClamp(initialSpeed * GLAIVE_THINK_RATE)
    p:SetGroundBehavior(PHYSICS_GROUND_LOCK)
    p:FollowNavMesh(false)
    p:GetAutoUnstuck(false)
    p:Hibernate(false)
    p.attackPhase = ATTACK_PHASE_START
    p.rehit = { }
    p.checkFirstHit = { }
    p:SetPhysicsVelocity(initialVelocity)
    p:SetPhysicsAcceleration(initialAcceleration)
    p:OnPhysicsFrame(function()
        local frostGlaives = self:GetFrostModifier()

        --check if ulti activated     
        if not p.glaiveStorm then
            local glaiveStorm = self:GetStormModifier()
            if glaiveStorm then
                p.attackPhase = ATTACK_PHASE_STORM_TARGET -- start ulti phase
                p.checkFirstHit = { } -- reset initial hit check
                p.glaiveStorm = glaiveStorm
                p.stormTarget = EntIndexToHScript(glaiveStorm.targetId) -- ulti target
            end
        end

        --handle movement logic
        if p.attackPhase == ATTACK_PHASE_START then -- initial phase
            local delta = startPos - p:GetAbsOrigin()
            if math.floor(p:GetPhysicsVelocity():Length2D()) == 0 then -- has reached end of initial phase
                p.attackPhase = ATTACK_PHASE_RETURN
                p.checkFirstHit = { }
                p.initialReturnPos = p:GetAbsOrigin()
            end

        elseif p.attackPhase == ATTACK_PHASE_HOVER then -- hover phase
            if not frostGlaives then 
                p.attackPhase = ATTACK_PHASE_RETURN -- move from hover phase to return phase
                p.initialReturnPos = p.initialReturnPos or p:GetAbsOrigin()
                p.checkFirstHit = { }
            end

        elseif p.attackPhase == ATTACK_PHASE_RETURN then -- return phase
            if frostGlaives then -- check for frost glaives modifier
                p.attackPhase = ATTACK_PHASE_HOVER
                p:SetPhysicsVelocity(Vector(0,0,0))
                p:SetPhysicsAcceleration(Vector(0,0,0))
                p.hoverStartTime = GameRules:GetGameTime()
            else 
                local casterPos = self:GetCaster():GetAbsOrigin()
                local delta = casterPos - p:GetAbsOrigin() -- glaive-to-caster delta
                if delta:Length2D() <= p:GetPhysicsVelocity():Length2D() * GLAIVE_THINK_RATE then -- has returned to caster
                    ParticleManager:DestroyParticle(p.fx, false)
                    p:Destroy()
                    return -- stop thinking
                end
                p:SetPhysicsVelocity(delta:Normalized() * p:GetPhysicsVelocity():Length2D())
                local distanceRatio = (casterPos - p.initialReturnPos):Length2D() / maxDistance
                p:SetPhysicsAcceleration(delta:Normalized() * maxSpeed * distanceRatio * (data.acceleration_factor/2) / data.travel_duration)
            end
        
        elseif p.attackPhase == ATTACK_PHASE_STORM_TARGET then -- ulti homing phase
            local targetPos = p.stormTarget:GetAbsOrigin()
            local delta = targetPos - p:GetAbsOrigin() -- glaive-to-target delta
            if delta:Length2D() <= p:GetPhysicsVelocity():Length2D() * GLAIVE_THINK_RATE then
                p.attackPhase = ATTACK_PHASE_STORM_SPIRAL
            end
            p:SetPhysicsVelocity(delta:Normalized() * p:GetPhysicsVelocity():Length2D())
            p:SetPhysicsAcceleration(delta:Normalized() * data.max_average_speed * (delta:Length2D() / maxDistance) * (data.acceleration_factor^2 / 2) / data.travel_duration)
        elseif p.attackPhase == ATTACK_PHASE_STORM_SPIRAL then -- ulti spiral phase

        end

        -- handle on-hit unit logic
        local units = self:FindUnitsInRadius(p:GetAbsOrigin(), data.projectile_radius)
        for _, unit in pairs(units) do
            local kw = WoeKeywords(self:GetKeywords())
            if p.attackPhase ~= ATTACK_PHASE_HOVER then -- non-dot phase
                local firstHit = not p.checkFirstHit[unit:GetEntityIndex()]
                p.checkFirstHit[unit:GetEntityIndex()] = true
                if firstHit then
                    local dmg
                    if p.attackPhase == ATTACK_PHASE_START then
                        dmg = self:GetInitialDamage()
                    elseif p.attackPhase == ATTACK_PHASE_RETURN then
                        dmg = self:GetReturnDamage()
                    end
                    if dmg then -- apply non-dot hit
                        ApplyWoeDamage({
                            Victim = unit,
                            Attacker = caster,
                            Ability = self,
                            Keywords = kw:Remove("dot"),
                            PhysicalDamage = dmg
                        })
                    end
                end
            end
        
            local rehitTime = p.rehit[unit:GetEntityIndex()] 
            if not rehitTime or (GameRules:GetGameTime() - rehitTime >= data.tick_rate) then --check rehit timer for unit
                --apply dot damage
                ApplyWoeDamage({
                    Victim = unit,
                    Attacker = caster,
                    Keywords = kw:Add("dot"),
                    PhysicalDamage = self:GetDotDamage() * data.tick_rate
                })
                --apply slow modifier
                if frostGlaives then
                    unit:AddNewModifier(caster, self, "modifier_glaivedancer_frost_glaives_slow", {
                        duration = frostGlaives.slow_duration,
                        slow_amount = frostGlaives.slow_amount,
                    })
                end
                --update rehit timer for unit
                p.rehit[unit:GetEntityIndex()] = GameRules:GetGameTime()
            end
        end

        --spawn FoWViewer
        AddFOWViewer(caster:GetTeamNumber(), p:GetAbsOrigin(), data.projectile_radius, 0.3, false)
        --cut trees
        GridNav:DestroyTreesAroundPoint(p:GetAbsOrigin(), data.projectile_radius, false)
    end)
end