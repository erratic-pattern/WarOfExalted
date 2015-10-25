item_vector_target_test = class({})

function item_vector_target_test:OnSpellStart()
    local caster = self:GetCaster()
    local data = self:GetSpecials()
    
    local startPos = self:GetInitialPosition()
    local endPos = startPos + self:GetDirectionVector() * data.effect_length
    
    local expireTime = GameRules:GetGameTime() + data.effect_duration
    
    local particleName = "particles/units/heroes/hero_jakiro/jakiro_macropyre.vpcf"
    local pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, caster )
    ParticleManager:SetParticleControl( pfx, 0, startPos )
    ParticleManager:SetParticleControl( pfx, 1, endPos )
    ParticleManager:SetParticleControl( pfx, 2, Vector( data.effect_duration, 0, 0 ) )
    ParticleManager:SetParticleControl( pfx, 3, startPos )
    
    local pathRadius = math.max( data.effect_radius, 64 )
    local projectileRadius = pathRadius
    local numProjectiles = math.floor( data.effect_length / (pathRadius*2) + 0.5) + 1
    local stepLength = data.effect_length / ( numProjectiles - 1 )
    local directionVector = self:GetDirectionVector()

    
    --destroy trees in area upon cast
    for i=1, numProjectiles do
        local pos = startPos + self:GetDirectionVector() * (i-1) * stepLength
        GridNav:DestroyTreesAroundPoint(pos, pathRadius, false)
        --DebugDrawCircle(pos, Vector(255,0,0), 1, pathRadius, true, data.effect_duration)
    end
    --start effect timer
    local elapsed = 0
    Timers:CreateTimer(data.burn_interval, function()
        for i=1, numProjectiles do
            local pos = startPos + directionVector * (i-1) * stepLength
            
            local ents = self:FindUnitsInRadius(pos, pathRadius)
            for _, ent in pairs(ents) do
                ApplyWoeDamage({
                    Attacker = caster,
                    Victim = ent,
                    Ability = self,
                    MagicalDamage = data.damage * data.burn_interval
                })
            end
        end
        elapsed = elapsed + data.burn_interval
        if elapsed < data.effect_duration then
            return data.burn_interval
        end
    end)
end
