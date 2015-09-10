requires = {
	'util',
	'lib.timers',
	'lib.physics',
	--'lib.statcollection',
    "lib.projectiles",
    "lib.affectors",
    "lib.storage",
	'warofexalts',
    'woe_link_modifiers',
    'woe_keywords',
    'woe_damage',
    'woe_unit_wrapper',
    'woe_ability_wrapper',
    "vector_target",
    "lua_modifier_utils",
}

function Precache( context )
	-- NOTE: IT IS RECOMMENDED TO USE A MINIMAL AMOUNT OF LUA PRECACHING, AND A MAXIMAL AMOUNT OF DATADRIVEN PRECACHING.
	-- Precaching guide: https://moddota.com/forums/discussion/119/precache-fixing-and-avoiding-issues

	print("[WAROFEXALTS] Performing pre-load precache")

	-- Particles can be precached individually or by folder
	-- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
	--PrecacheResource("particle", "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", context)
	--PrecacheResource("particle_folder", "particles/test_particle", context)
    PrecacheVectorTarget(context)

	-- Models can also be precached by folder or individually
	--PrecacheModel should generally used over PrecacheResource for individual models
	--PrecacheResource("model_folder", "particles/heroes/antimage", context)
	--PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
	--PrecacheModel("models/heroes/viper/viper.vmdl", context)

	-- Sounds can precached here like anything else
	--PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)

	-- Entire items can be precached by name
	-- Abilities can also be precached in this way despite the name
	--PrecacheItemByNameSync("example_ability", context)
	--PrecacheItemByNameSync("item_example_item", context)
    --PrecacheItemByNameSync("item_ultimate_orb", context)

	-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
	-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
	--PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
    PrecacheUnitByNameSync("npc_precache_everything", context)
end

-- Create the game mode when we activate
function Activate()
	GameRules.WarOfExalts = WarOfExalts()
	GameRules.WarOfExalts:InitWarOfExalts()
end

for i,v in ipairs(requires) do
	require(v)	
end
