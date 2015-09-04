test_vector_targeting = class({})

-- Code adapted from https://github.com/Pizzalol/SpellLibrary
function test_vector_targeting:OnSpellStart()
    local caster = self:GetCaster()
    local pathLength = self:GetMaxDistance()
    local pathRadius = self:GetSpecialValueFor("path_radius")
    local duration = self:GetSpecialValueFor("duration")
    
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
	local projectileRadius = pathRadius * math.sqrt(2)
	local numProjectiles = math.floor( pathLength / (pathRadius*2) ) + 1
	local stepLength = pathLength / ( numProjectiles - 1 )

	for i=1, numProjectiles do
		local projectilePos = startPos + self:GetDirectionVector() * (i-1) * stepLength

		ProjectileManager:CreateLinearProjectile( {
			Ability				= self,
		--	EffectName			= "",
			vSpawnOrigin		= projectilePos,
			fDistance			= 64,
			fStartRadius		= projectileRadius,
			fEndRadius			= projectileRadius,
			Source				= caster,
			bHasFrontalCone		= false,
			bReplaceExisting	= false,
			iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags	= DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_MECHANICAL,
			fExpireTime			= expireTime,
			bDeleteOnHit		= false,
			vVelocity			= Vector( 0, 0, 0 ),	-- Don't move!
			bProvidesVision		= false,
		--	iVisionRadius		= 0,
		--	iVisionTeamNumber	= caster:GetTeamNumber(),
		} )
	end

end