pyromancer_lava_path = class({})

function pyromancer_lava_path:OnSpellStart()
    local caster = self:GetCaster()
    local pathLength = self:GetMaxDistance()
    local pathRadius = self:GetSpecialValueFor("path_radius")
    local duration = self:GetSpecialValueFor("duration")
    local interval = self:GetSpecialValueFor("burn_interval")
    local damage = self:GetSpecialValueFor("damage")
    local mrReduction = self:GetSpecialValueFor("mr_reduction")
    
    local startPos = self:GetInitialPosition()
    local endPos = startPos + self:GetDirectionVector() * pathLength
    
    local expireTime = GameRules:GetGameTime() + duration
    
    local particleName = "particles/units/heroes/hero_jakiro/jakiro_macropyre.vpcf"
	local pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( pfx, 0, startPos )
	ParticleManager:SetParticleControl( pfx, 1, endPos )
	ParticleManager:SetParticleControl( pfx, 2, Vector( duration, 0, 0 ) )
	ParticleManager:SetParticleControl( pfx, 3, startPos )
    
	pathRadius = math.max( pathRadius, 64 )
	local projectileRadius = pathRadius
	local numProjectiles = math.floor( pathLength / (pathRadius*2) + 0.5) + 1
	local stepLength = pathLength / ( numProjectiles - 1 )

    --wait 0.5 seconds
    Timers:CreateTimer(interval, function()
        for i=1, numProjectiles do
            local pos = startPos + self:GetDirectionVector() * (i-1) * stepLength
            --CreateModifierThinker(caster, self, "modifier_lava_path_thinker", {duration = duration}, pos, caster:GetTeam(), false)
            GridNav:DestroyTreesAroundPoint(pos, pathRadius, false)
            Affectors:CreateAffector({
                Source  = caster,
                Ability = self,
                Position = pos,
                Radius = pathRadius,
                Duration = duration,
                OnUnit = function(affector, unit)
                    --print("unit hit!")
                    unit:AddNewModifier(caster, self, "modifier_woe_dot", {
                        duration = interval,
                        Interval = interval,
                        IsHidden = true,
                        MagicalDamage = damage * interval,
                        Test    = "Test"
                    })
                end,
            })
        end
    end)

end
