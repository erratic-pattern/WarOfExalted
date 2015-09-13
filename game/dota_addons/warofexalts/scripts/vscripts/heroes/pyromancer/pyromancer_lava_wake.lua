pyromancer_lava_wake = class({})

function pyromancer_lava_wake:OnSpellStart()
    local caster = self:GetCaster()
    local data = self:GetSpecials()
    local pathLength = self:GetMaxDistance()
    
    local startPos = self:GetInitialPosition()
    local endPos = startPos + self:GetDirectionVector() * pathLength
    
    local expireTime = GameRules:GetGameTime() + data.effect_duration
    
    local particleName = "particles/units/heroes/hero_jakiro/jakiro_macropyre.vpcf"
	local pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( pfx, 0, startPos )
	ParticleManager:SetParticleControl( pfx, 1, endPos )
	ParticleManager:SetParticleControl( pfx, 2, Vector( data.effect_duration, 0, 0 ) )
	ParticleManager:SetParticleControl( pfx, 3, startPos )
    
	local pathRadius = math.max( data.effect_radius, 64 )
	local projectileRadius = pathRadius
	local numProjectiles = math.floor( pathLength / (pathRadius*2) + 0.5) + 1
	local stepLength = pathLength / ( numProjectiles - 1 )

    
    --destroy trees in area upon cast
    for i=1, numProjectiles do
        local pos = startPos + self:GetDirectionVector() * (i-1) * stepLength
        GridNav:DestroyTreesAroundPoint(pos, pathRadius, false)
        --DebugDrawCircle(pos, Vector(255,0,0), 1, pathRadius, true, data.effect_duration)
    end
    local elapsed = 0
    Timers:CreateTimer(data.burn_interval, function()
        for i=1, numProjectiles do
            local pos = startPos + self:GetDirectionVector() * (i-1) * stepLength
            
            local ents = 
                FindUnitsInRadius(caster:GetTeam(), pos, nil, pathRadius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
            for _, ent in pairs(ents) do
                ApplyWoeDamage({
                    Attacker = caster,
                    Victim = ent,
                    Ability = self,
                    MagicalDamage = data.damage * data.burn_interval
                })
                ent:AddNewModifier(caster, self, "modifier_pyromancer_lava_wake_mr_reduction", {
                    duration = data.debuff_duration,
                    value = data.mr_reduction,
                    Test = "Test"
                })
            end
        end
        elapsed = elapsed + data.burn_interval
        if elapsed < data.effect_duration then
            return data.burn_interval
        end
    end)
end
