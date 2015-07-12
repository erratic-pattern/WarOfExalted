print("test_woe_damage: script file invoked")
test_woe_damage = class({})
function test_woe_damage:constructor()
    print("test_Woe_Damage: constructor called")
end

function test_woe_damage:OnSpellStart()
	local info = {
			EffectName = "particles/units/heroes/hero_vengeful/vengeful_magic_missle.vpcf",
			Ability = self,
			iMoveSpeed = self:GetSpecialValueFor( "missile_speed" ),
			Source = self:GetCaster(),
			Target = self:GetCursorTarget(),
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
		}
	ProjectileManager:CreateTrackingProjectile( info )
    EmitSoundOn( "Hero_VengefulSpirit.MagicMissile", self:GetCaster() )
end

function test_woe_damage:OnProjectileHit( hTarget, vLocation )
	if hTarget ~= nil and ( not hTarget:IsInvulnerable() ) and ( not hTarget:TriggerSpellAbsorb( self ) ) and ( not hTarget:IsMagicImmune() ) then
        EmitSoundOn( "Hero_VengefulSpirit.MagicMissileImpact", hTarget )
        local dmg = self:GetAbilityDamage()
		local damage = {
			victim = hTarget,
			attacker = self:GetCaster(),
			magicalDamage = dmg,
            physicalDamage = dmg,
			ability = self
		}
		ApplyWoeDamage( damage )
		hTarget:AddNewModifier( self:GetCaster(), self, "modifier_stunned", { duration = self:GetSpecialValueFor( "stun_duration" ) } )
	end

    return true
end