glaivedancer_throw_glaive = class({})

local GLAIVE_THINK_RATE = 1/30
local GLAIVE_RETURN_VELOCITY_CHANGE_DELAY = 0.1

--attack phases
local ATTACK_PHASE_START, 
      ATTACK_PHASE_HOVER,
      ATTACK_PHASE_RETURN,
      ATTACK_PHASE_STORM_TARGET,
      ATTACK_PHASE_STORM_SPIRAL 
      = 0,1,2,3,4

function glaivedancer_throw_glaive:GetDotDamage()
    return self:GetSpecialValueFor("base_damage") + self:GetSpecialValueFor("damage_multiplier") * self:GetCaster():GetAverageTrueAttackDamage()
end

function glaivedancer_throw_glaive:GetInitialDamage()
    return self:GetSpecialValueFor("initial_base_damage") + self:GetSpecialValueFor("initial_damage_multiplier") * self:GetCaster():GetAverageTrueAttackDamage()
end

function glaivedancer_throw_glaive:GetReturnDamage()
    return self:GetSpecialValueFor("return_base_damage") + self:GetSpecialValueFor("return_damage_multiplier") * self:GetCaster():GetAverageTrueAttackDamage()
end

function glaivedancer_throw_glaive:GetFrostModifier()
    return self:GetCaster():FindModifierByName("glaivedancer_frost_glaives_buff")
end

function glaivedancer_throw_glaive:GetStormModifier()
    return self:GetCaster():FindModifierByName("glaivedancer_glaive_storm_buff")
end

function glaivedancer_throw_glaive:OnSpellStart()
    local height = 75
    local caster = self:GetCaster()
    local data = self:GetSpecials()
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
    
    
    local p = CreateUnitByName("npc_dummy_blank", startPos, false, caster, caster, caster:GetTeamNumber())
    p.fx = ParticleManager:CreateParticle("particles/heroes/glaivedancer/glaivedancer_throw_glaive.vpcf", PATTACH_ABSORIGIN, p)
    --ParticleManager:SetParticleControl(pfx, 2, Vector(data.speed,0,0))
    Physics:Unit(p)
    p:SetPhysicsVelocity(velocity)
    p:SetPhysicsFriction(Vector(0,0,0))
    p:SetVelocityClamp(-1)
    p:SetGroundBehavior(PHYSICS_GROUND_LOCK)
    p.checkFirstHit = { }
    p.rehit = { }
    p.attackPhase = ATTACK_PHASE_START
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
        print(p.attackPhase)
        if p.attackPhase == ATTACK_PHASE_START then -- initial phase
            local delta = startPos - p:GetAbsOrigin()
            print(delta:Length2D(), targetDistance, p:GetTotalVelocity())
            if delta:Length2D() >= targetDistance then -- has reached end of initial phase
                p:SetPhysicsVelocity(Vector(0,0,0))
                --ParticleManager:SetParticleControl(p.id, 2, Vector(0,0,0))
                p.attackPhase = ATTACK_PHASE_HOVER
                p.hoverStartTime = GameRules:GetGameTime()
                --return data.hover_duration -- sleep until the end of DoT phase
            end

        elseif p.attackPhase == ATTACK_PHASE_HOVER then -- hover phase
            local totalDuration = data.hover_duration
            if frostGlaives then
                totalDuration = totalDuration + frostGlaives.bonus_hover_duration
            end
            if GameRules:GetGameTime() - p.hoverStartTime >= totalDuration then 
                p.attackPhase = ATTACK_PHASE_RETURN -- move from dot phase to return phase
                p.checkFirstHit = { }
            end
            --ParticleManager:SetParticleControl(p.id, 2, Vector(data.speed,0,0))

        elseif p.attackPhase == ATTACK_PHASE_RETURN then -- return phase
            local casterPos = self:GetCaster():GetAbsOrigin()
            local delta = casterPos - p:GetAbsOrigin() -- glaive-to-caster delta
            if delta:Length2D() <= data.speed * GLAIVE_THINK_RATE * 1.5 then -- has returned to caster
                ParticleManager:DestroyParticle(p.fx, false)
                p:Destroy()
                return -- stop thinking
            end
            p:SetPhysicsVelocity( data.speed * delta:Normalized() )
        
        elseif p.attackPhase == ATTACK_PHASE_STORM_TARGET then -- ulti homing phase
            local targetPos = p.stormTarget:GetAbsOrigin()
            local delta = targetPos - p:GetAbsOrigin() -- glaive-to-target delta
            if delta:Length2D() <= data.speed * GLAIVE_THINK_RATE * 1.5 then
                p.attackPhase = ATTACK_PHASE_STORM_SPIRAL
            end
            p:SetPhysicsVelocity( data.speed * delta:Normalized() )
        elseif p.attackPhase == ATTACK_PHASE_STORM_SPIRAL then -- ulti spiral phase

        end

        -- handle on-hit unit logic
        local units = FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, data.projectile_radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
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
                    unit:AddNewModifier(caster, self, "glaivedancer_frost_glaives_slow", {
                        duration = frostGlaives.slow_duration,
                        slow_amount = frostGlaives.slow_amount,
                    })
                end
                --update rehit timer for unit
                p.rehit[unit:GetEntityIndex()] = GameRules:GetGameTime()
            end
        end
    end)
end