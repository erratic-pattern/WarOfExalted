--print ('[WAROFEXALTS] warofexalts.lua' )

ENABLE_HERO_RESPAWN = true              -- Should the heroes automatically respawn on a timer or stay dead until manually respawned
UNIVERSAL_SHOP_MODE = false             -- Should the main shop contain Secret Shop items as well as regular items
ALLOW_SAME_HERO_SELECTION = false       -- Should we let people select the same hero as each other

HERO_SELECTION_TIME = 1             -- How long should we let people select their hero?
PRE_GAME_TIME = 0                   -- How long after people select their heroes should the horn blow and the game start?
POST_GAME_TIME = 60.0               -- How long should we let people look at the scoreboard before closing the server automatically?
TREE_REGROW_TIME = 5.0              -- How long should it take individual trees to respawn after being cut down/destroyed?

STARTING_GOLD = 625                   -- Starting gold for heroes.
GOLD_PER_TICK = 1                     -- How much gold should players get per tick?
GOLD_TICK_TIME = 0.6                  -- How long should we wait in seconds between gold ticks?

RECOMMENDED_BUILDS_DISABLED = true     -- Should we disable the recommened builds for heroes (Note: this is not working currently I believe)
CAMERA_DISTANCE_OVERRIDE = 1134.0        -- How far out should we allow the camera to go?  1134 is the default in Dota

MINIMAP_ICON_SIZE = 1                   -- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE = 1             -- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE = 1              -- What icon size should we use for runes?

RUNE_SPAWN_TIME = 120                   -- How long in seconds should we wait between rune spawns?
CUSTOM_BUYBACK_COST_ENABLED = true      -- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED = true  -- Should we use a custom buyback time?
BUYBACK_ENABLED = true                  -- Should we allow people to buyback when they die?

DISABLE_FOG_OF_WAR_ENTIRELY = false     -- Should we disable fog of war entirely for both teams?
										-- NOTE: This won't reveal particle effects for everyone. You need to create vision dummies for that.

--USE_STANDARD_DOTA_BOT_THINKING = false  -- Should we have bots act like they would in Dota? (This requires 3 lanes, normal items, etc)
USE_STANDARD_HERO_GOLD_BOUNTY = true      -- Should we give gold for hero kills the same as in Dota, or allow those values to be changed?

USE_CUSTOM_TOP_BAR_VALUES = true        -- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE = true                  -- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR = true             -- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals)  Requires USE_CUSTOM_TOP_BAR_VALUES

ENABLE_TOWER_BACKDOOR_PROTECTION = true  -- Should we enable backdoor protection for our towers?
REMOVE_ILLUSIONS_ON_DEATH = false        -- Should we remove all illusions if the main hero dies?
DISABLE_GOLD_SOUNDS = false              -- Should we disable the gold sound when players get gold?

END_GAME_ON_KILLS = false                -- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 50         -- How many kills for a team should signify an end of game?

USE_CUSTOM_HERO_LEVELS = false          -- Should we allow heroes to have custom levels?
MAX_LEVEL = 50                          -- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES = false            -- Should we use custom XP values to level up heroes, or the default Dota numbers?

FAKE_CLIENT_HERO = "woe_test_hero_generic"

Testing = true
OutOfWorldVector = Vector(11000, 11000, -200)

if not Testing then
  statcollection.addStats({
    modID = 'XXXXXXXXXXXXXXXXXXX'
  })
end

-- Fill this table up with the required XP per level if you want to change it
XP_PER_LEVEL_TABLE = {}
for i=1,MAX_LEVEL do
	XP_PER_LEVEL_TABLE[i] = i * 100
end

-- Generated from template
if WarOfExalts == nil then
	--print ( '[WAROFEXALTS] creating warofexalts game mode' )
	WarOfExalts = class({})
end

function WarOfExalts:PostLoadPrecache()
	--print("[WAROFEXALTS] Performing Post-Load precache")

	PrecacheUnitByNameAsync("npc_precache_everything", function(...) end)
end

--[[
  This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
  It can be used to initialize state that isn't initializeable in InitWarOfExalts() but needs to be done before everyone loads in.
]]
function WarOfExalts:OnFirstPlayerLoaded()
	--print("[WAROFEXALTS] First Player has loaded")
end

--[[
  This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
  It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function WarOfExalts:OnAllPlayersLoaded()
	--print("[WAROFEXALTS] All Players have loaded into the game")
end

--[[
  This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
  if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
  levels, changing the starting gold, removing/adding abilities, adding physics, etc.

  The hero parameter is the hero entity that just spawned in.
]]
function WarOfExalts:OnHeroInGame(hero)
	--print("[WAROFEXALTS] Hero spawned in game for first time -- " .. hero:GetUnitName())

	if not self.greetPlayers then
		-- At this point a player now has a hero spawned in your map.
		
	    local firstLine = util.color("Welcome to ", "green") .. util.color(self.addonInfo.addontitle, "magenta") .. util.color(self.addonInfo.addonversion, "blue");
	    local secondLine = util.color("Developer: ", "green") .. util.color(self.addonInfo.addonauthor, "orange")
		-- Send the first greeting in 4 secs.
		Timers:CreateTimer(4, function()
	        GameRules:SendCustomMessage(firstLine, 0, 0)
	        GameRules:SendCustomMessage(secondLine, 0, 0)
		end)

		self.greetPlayers = true
	end

	-- Store a reference to the player handle inside this hero handle.
	hero.player = PlayerResource:GetPlayer(hero:GetPlayerID())
	-- Store the player's name inside this hero handle.
	hero.playerName = PlayerResource:GetPlayerName(hero:GetPlayerID())
	-- Store this hero handle in this table.
	table.insert(self.vPlayers, hero)

	if Testing then
		Say(nil, "Testing is on.", false)
	end

	util.initAbilities(hero)

	-- Show a popup with game instructions.
    --ShowGenericPopupToPlayer(hero.player, "#warofexalts_instructions_title", "#warofexalts_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )

	-- This line for example will set the starting gold of every hero to 500 unreliable gold
	hero:SetGold(STARTING_GOLD, false)

	-- These lines will create an item and add it to the player, effectively ensuring they start with the item
	--local item = CreateItem("item_example_item", hero, hero)
	--hero:AddItem(item)
end

--[[
	This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
	gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
	is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function WarOfExalts:OnGameInProgress()
	--print("[WAROFEXALTS] The game has officially begun")

	Timers:CreateTimer(30, function() -- Start this timer 30 game-time seconds later
		--print("This function is called 30 seconds after the game begins, and every 30 seconds thereafter")
		return 30.0 -- Rerun this timer every 30 game-time seconds
	end)
end

function WarOfExalts:PlayerSay( keys )
	local ply = keys.ply
	local hero = ply:GetAssignedHero()
	local txt = keys.text

	if keys.teamOnly then
		-- This text was team-only.
	end

	if txt == nil or txt == "" then
		return
	end

  -- At this point we have valid text from a player.
	--print("P" .. ply .. " wrote: " .. keys.text)
end

-- Cleanup a player when they leave
function WarOfExalts:OnDisconnect(keys)
	--print('[WAROFEXALTS] Player Disconnected ' .. tostring(keys.userid))
	--util.printTable(keys)

	local name = keys.name
	local networkid = keys.networkid
	local reason = keys.reason
	local userid = keys.userid
end

-- The overall game state has changed
function WarOfExalts:OnGameRulesStateChange(keys)
	--print("[WAROFEXALTS] GameRules State Changed")
	--util.printTable(keys)

	local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		self.bSeenWaitForPlayers = true
	elseif newState == DOTA_GAMERULES_STATE_INIT then
		Timers:RemoveTimer("alljointimer")
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		local et = 6
		if self.bSeenWaitForPlayers then
			et = .01
		end
		Timers:CreateTimer("alljointimer", {
			useGameTime = true,
			endTime = et,
			callback = function()
				if PlayerResource:HaveAllPlayersJoined() then
					WarOfExalts:PostLoadPrecache()
					WarOfExalts:OnAllPlayersLoaded()
					return
				end
				return 1
			end})
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		WarOfExalts:OnGameInProgress()
	end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function WarOfExalts:OnNPCSpawned(keys)
	--print("[WAROFEXALTS] NPC Spawned")
	--util.printTable(keys)
	local npc = EntIndexToHScript(keys.entindex)
    self:WoeUnitWrapper(npc)
    npc:WithAbilities(function(a) self:WoeAbilityWrapper(a) end)

	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		WarOfExalts:OnHeroInGame(npc)
	end
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function WarOfExalts:OnEntityHurt(keys)
	--print("[WAROFEXALTS] Entity Hurt")
	--util.printTable(keys)
	local attacker = EntIndexToHScript(keys.entindex_attacker)
	local victim = EntIndexToHScript(keys.entindex_killed)
end

-- An item was picked up off the ground
function WarOfExalts:OnItemPickedUp(keys)
	--print ( '[WAROFEXALTS] OnItemPurchased' )
	--util.printTable(keys)

	local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
	local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function WarOfExalts:OnPlayerReconnect(keys)
	--print ( '[WAROFEXALTS] OnPlayerReconnect' )
	--util.printTable(keys)
end

-- An item was purchased by a player
function WarOfExalts:OnItemPurchased( keys )
	--print ( '[WAROFEXALTS] OnItemPurchased' )
	--util.printTable(keys)

	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end

	-- The name of the item purchased
	local itemName = keys.itemname

	-- The cost of the item purchased
	local itemcost = keys.itemcost

end

-- An ability was used by a player
function WarOfExalts:OnAbilityUsed(keys)
	--print('[WAROFEXALTS] AbilityUsed')
	--util.printTable(keys)

	local player = EntIndexToHScript(keys.PlayerID)
	local abilityname = keys.abilityname
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function WarOfExalts:OnNonPlayerUsedAbility(keys)
	--print('[WAROFEXALTS] OnNonPlayerUsedAbility')
	--util.printTable(keys)

	local abilityname=  keys.abilityname
end

-- A player changed their name
function WarOfExalts:OnPlayerChangedName(keys)
	--print('[WAROFEXALTS] OnPlayerChangedName')
	--util.printTable(keys)

	local newName = keys.newname
	local oldName = keys.oldName
end

-- A player leveled up an ability
function WarOfExalts:OnPlayerLearnedAbility( keys)
	--print ('[WAROFEXALTS] OnPlayerLearnedAbility')
	--util.printTable(keys)

	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function WarOfExalts:OnAbilityChannelFinished(keys)
	--print ('[WAROFEXALTS] OnAbilityChannelFinished')
	--util.printTable(keys)

	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

-- A player leveled up
function WarOfExalts:OnPlayerLevelUp(keys)
	--print ('[WAROFEXALTS] OnPlayerLevelUp')
	--util.printTable(keys)

	local player = EntIndexToHScript(keys.player)
	local level = keys.level
end

-- A player last hit a creep, a tower, or a hero
function WarOfExalts:OnLastHit(keys)
	--print ('[WAROFEXALTS] OnLastHit')
	--util.printTable(keys)

	local isFirstBlood = keys.FirstBlood == 1
	local isHeroKill = keys.HeroKill == 1
	local isTowerKill = keys.TowerKill == 1
	local player = PlayerResource:GetPlayer(keys.PlayerID)
end

-- A tree was cut down by tango, quelling blade, etc
function WarOfExalts:OnTreeCut(keys)
	--print ('[WAROFEXALTS] OnTreeCut')
	--util.printTable(keys)

	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

-- A rune was activated by a player
function WarOfExalts:OnRuneActivated (keys)
	--print ('[WAROFEXALTS] OnRuneActivated')
	--util.printTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local rune = keys.rune

	--[[ Rune Can be one of the following types
	DOTA_RUNE_DOUBLEDAMAGE
	DOTA_RUNE_HASTE
	DOTA_RUNE_HAUNTED
	DOTA_RUNE_ILLUSION
	DOTA_RUNE_INVISIBILITY
	DOTA_RUNE_MYSTERY
	DOTA_RUNE_RAPIER
	DOTA_RUNE_REGENERATION
	DOTA_RUNE_SPOOKY
	DOTA_RUNE_TURBO
	]]
end

-- A player took damage from a tower
function WarOfExalts:OnPlayerTakeTowerDamage(keys)
	--print ('[WAROFEXALTS] OnPlayerTakeTowerDamage')
	--util.printTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local damage = keys.damage
end

-- A player picked a hero
function WarOfExalts:OnPlayerPickHero(keys)
	--print ('[WAROFEXALTS] OnPlayerPickHero')
	--util.printTable(keys)

	local heroClass = keys.hero
	local heroEntity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
end

-- A player killed another player in a multi-team context
function WarOfExalts:OnTeamKillCredit(keys)
	--print ('[WAROFEXALTS] OnTeamKillCredit')
	--util.printTable(keys)

	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
	local numKills = keys.herokills
	local killerTeamNumber = keys.teamnumber
end

-- An entity died
function WarOfExalts:OnEntityKilled( keys )
	--print( '[WAROFEXALTS] OnEntityKilled Called' )
	--util.printTable( keys )

	-- The Unit that was Killed
	local killedUnit = EntIndexToHScript( keys.entindex_killed )
	-- The Killing entity
	local killerEntity = nil

	if keys.entindex_attacker ~= nil then
		killerEntity = EntIndexToHScript( keys.entindex_attacker )
	end

	if killedUnit:IsRealHero() then
		--print ("KILLEDKILLER: " .. killedUnit:GetName() .. " -- " .. killerEntity:GetName())
		if killedUnit:GetTeam() == DOTA_TEAM_BADGUYS and killerEntity:GetTeam() == DOTA_TEAM_GOODGUYS then
			self.nRadiantKills = self.nRadiantKills + 1
			if END_GAME_ON_KILLS and self.nRadiantKills >= KILLS_TO_END_GAME_FOR_TEAM then
				GameRules:SetSafeToLeave( true )
				GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
			end
		elseif killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS and killerEntity:GetTeam() == DOTA_TEAM_BADGUYS then
			self.nDireKills = self.nDireKills + 1
			if END_GAME_ON_KILLS and self.nDireKills >= KILLS_TO_END_GAME_FOR_TEAM then
				GameRules:SetSafeToLeave( true )
				GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
			end
		end

		if SHOW_KILLS_ON_TOPBAR then
			GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.nDireKills )
			GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.nRadiantKills )
		end
	end

	-- Put code here to handle when an entity gets killed
end

function WarOfExalts:OnWoeUnitRequest( keys )
    --print("[WAROFEXALTS] OnWoeUnitRequest called")
    --util.printTable(keys)
    local unit = EntIndexToHScript(keys.id)
    if unit then
        keys.isWoeUnit = unit.isWoeUnit
        if unit.isWoeUnit then
            keys.MsBase = unit:GetBaseMoveSpeed()
            keys.MsTotal = unit:GetIdealSpeed()
            keys.MagicResistTotal = unit:GetWoeMagicResist()
            keys.ArmorBase = unit:GetPhysicalArmorBaseValue()
            keys.ArmorTotal = unit:GetPhysicalArmorValue()
            keys.SpellSpeed = unit:GetSpellSpeed()
            util.mergeTable(keys, unit._woeKeys)
        end
    end
    --util.printTable(keys)
    CustomGameEventManager:Send_ServerToAllClients("woe_unit_response", keys)
    --Sending to PlayerID doesn't appear to be working correctly
    --CustomGameEventManager:Send_ServerToPlayer(EntIndexToHScript(keys.PlayerID), "woe_unit_response", keys)
end

function WarOfExalts:OnWoeAbilityRequest(keys)
    local abi = EntIndexToHScript(keys.id)
    if abi then
        keys.isWoeAbility = abi.isWoeAbility
        if abi.isWoeAbility then
            util.mergeTable(keys, abi._woeKeys)
        end
    end
    CustomGameEventManager:Send_ServerToAllClients("woe_ability_response", keys)
end

--[[
function WarOfExalts:AbilityTuningFilter( keys )
    print("[WAROFEXALTS] AbilityTuningFilter called")
    util.printTable(keys)
end
]]

function WarOfExalts:ExecuteOrderFilter(data)
    --print("[WAROFEXALTS] ExecuteOrderFilter called")
    return VectorTargetOrderFilter(data)
end


-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function WarOfExalts:InitWarOfExalts()
	WarOfExalts = self
    local gameMode = GameRules:GetGameModeEntity()
	print('[WAROFEXALTS] Starting to load WarOfExalts gamemode...')
    --Initialize custom Lua modifiers
    self:LinkModifiers()
    
    InitVectorTargetEventListeners()
    
    --set script filters
    gameMode:SetExecuteOrderFilter(Dynamic_Wrap(WarOfExalts, "ExecuteOrderFilter"), self)
    --gameMode:SetAbilityTuningValueFilter(Dynamic_Wrap(WarOfExalts, "AbilityTuningFilter"), self)

	-- Setup rules
	GameRules:SetHeroRespawnEnabled( ENABLE_HERO_RESPAWN )
	GameRules:SetUseUniversalShopMode( UNIVERSAL_SHOP_MODE )
	GameRules:SetSameHeroSelectionEnabled( ALLOW_SAME_HERO_SELECTION )
	GameRules:SetHeroSelectionTime( HERO_SELECTION_TIME )
	GameRules:SetPreGameTime( PRE_GAME_TIME)
	GameRules:SetPostGameTime( POST_GAME_TIME )
	GameRules:SetTreeRegrowTime( TREE_REGROW_TIME )
	GameRules:SetUseCustomHeroXPValues ( USE_CUSTOM_XP_VALUES )
	GameRules:SetGoldPerTick(GOLD_PER_TICK)
	GameRules:SetGoldTickTime(GOLD_TICK_TIME)
	GameRules:SetRuneSpawnTime(RUNE_SPAWN_TIME)
	GameRules:SetUseBaseGoldBountyOnHeroes(USE_STANDARD_HERO_GOLD_BOUNTY)
	GameRules:SetHeroMinimapIconScale( MINIMAP_ICON_SIZE )
	GameRules:SetCreepMinimapIconScale( MINIMAP_CREEP_ICON_SIZE )
	GameRules:SetRuneMinimapIconScale( MINIMAP_RUNE_ICON_SIZE )
	--print('[WAROFEXALTS] GameRules set')

	InitLogFile( "log/warofexalts.txt","")

	-- Event Hooks
	-- All of these events can potentially be fired by the game, though only the uncommented ones have had
	-- Functions supplied for them.  If you are interested in the other events, you can uncomment the
	-- ListenToGameEvent line and add a function to handle the event
	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(WarOfExalts, 'OnPlayerLevelUp'), self)
	ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(WarOfExalts, 'OnAbilityChannelFinished'), self)
	ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(WarOfExalts, 'OnPlayerLearnedAbility'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(WarOfExalts, 'OnEntityKilled'), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(WarOfExalts, 'OnConnectFull'), self)
	ListenToGameEvent('player_disconnect', Dynamic_Wrap(WarOfExalts, 'OnDisconnect'), self)
	ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(WarOfExalts, 'OnItemPurchased'), self)
	ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(WarOfExalts, 'OnItemPickedUp'), self)
	ListenToGameEvent('last_hit', Dynamic_Wrap(WarOfExalts, 'OnLastHit'), self)
	ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(WarOfExalts, 'OnNonPlayerUsedAbility'), self)
	ListenToGameEvent('player_changename', Dynamic_Wrap(WarOfExalts, 'OnPlayerChangedName'), self)
	ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(WarOfExalts, 'OnRuneActivated'), self)
	ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(WarOfExalts, 'OnPlayerTakeTowerDamage'), self)
	ListenToGameEvent('tree_cut', Dynamic_Wrap(WarOfExalts, 'OnTreeCut'), self)
	ListenToGameEvent('entity_hurt', Dynamic_Wrap(WarOfExalts, 'OnEntityHurt'), self)
	ListenToGameEvent('player_connect', Dynamic_Wrap(WarOfExalts, 'PlayerConnect'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(WarOfExalts, 'OnAbilityUsed'), self)
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(WarOfExalts, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(WarOfExalts, 'OnNPCSpawned'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(WarOfExalts, 'OnPlayerPickHero'), self)
	ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(WarOfExalts, 'OnTeamKillCredit'), self)
	ListenToGameEvent("player_reconnected", Dynamic_Wrap(WarOfExalts, 'OnPlayerReconnect'), self)
	--ListenToGameEvent('player_spawn', Dynamic_Wrap(WarOfExalts, 'OnPlayerSpawn'), self)
	--ListenToGameEvent('dota_unit_event', Dynamic_Wrap(WarOfExalts, 'OnDotaUnitEvent'), self)
	--ListenToGameEvent('nommed_tree', Dynamic_Wrap(WarOfExalts, 'OnPlayerAteTree'), self)
	--ListenToGameEvent('player_completed_game', Dynamic_Wrap(WarOfExalts, 'OnPlayerCompletedGame'), self)
	--ListenToGameEvent('dota_match_done', Dynamic_Wrap(WarOfExalts, 'OnDotaMatchDone'), self)
	--ListenToGameEvent('dota_combatlog', Dynamic_Wrap(WarOfExalts, 'OnCombatLogEvent'), self)
	--ListenToGameEvent('dota_player_killed', Dynamic_Wrap(WarOfExalts, 'OnPlayerKilled'), self)
	--ListenToGameEvent('player_team', Dynamic_Wrap(WarOfExalts, 'OnPlayerTeam'), self)
    
    -- Custom Event Hooks
    CustomGameEventManager:RegisterListener("woe_unit_request", Dynamic_Wrap(WarOfExalts, "OnWoeUnitRequest"));
    CustomGameEventManager:RegisterListener("woe_ability_request", Dynamic_Wrap(WarOfExalts, "OnWoeAbilityRequest"));


	Convars:RegisterCommand('player_say', function(...)
		local arg = {...}
		table.remove(arg,1)
		local sayType = arg[1]
		table.remove(arg,1)

		local cmdPlayer = Convars:GetCommandClient()
		keys = {}
		keys.ply = cmdPlayer
		keys.teamOnly = false
		keys.text = table.concat(arg, " ")

		if (sayType == 4) then
			-- Student messages
		elseif (sayType == 3) then
			-- Coach messages
		elseif (sayType == 2) then
			-- Team only
			keys.teamOnly = true
			-- Call your player_say function here like
			self:PlayerSay(keys)
		else
			-- All chat
			-- Call your player_say function here like
			self:PlayerSay(keys)
		end
	end, 'player say', 0)

	-- Fill server with fake clients
	-- Fake clients don't use the default bot AI for buying items or moving down lanes and are sometimes necessary for debugging
	Convars:RegisterCommand('fake', function()
		-- Check if the server ran it
		if not Convars:GetCommandClient() then
			-- Create fake Players
			SendToServerConsole('dota_create_fake_clients')

			Timers:CreateTimer('assign_fakes', {
				useGameTime = false,
				endTime = Time(),
				callback = function(warofexalts, args)
					local userID = 20
					for i=0, 9 do
						userID = userID + 1
						-- Check if this player is a fake one
						if PlayerResource:IsFakeClient(i) then
							-- Grab player instance
							local ply = PlayerResource:GetPlayer(i)
							-- Make sure we actually found a player instance
							if ply then
								CreateHeroForPlayer(FAKE_CLIENT_HERO, ply)
								self:OnConnectFull({
									userid = userID,
									index = ply:entindex()-1
								})

								ply:GetAssignedHero():SetControllableByPlayer(0, true)
							end
						end
					end
				end})
		end
	end, 'Connects and assigns fake Players.', 0)
    
    Convars:RegisterCommand("run_lua", function(...)
        ex = select(2, ...)
        loadstring(ex)() 
    end, "Execute lua", 0 )

	-- Change random seed
	local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
	math.randomseed(tonumber(timeTxt))

	-- Initialized tables for tracking state
	self.vUserIds = {}
	self.vSteamIds = {}
	self.vBots = {}
	self.vBroadcasters = {}

	self.vPlayers = {}
	self.vRadiant = {}
	self.vDire = {}

	self.nRadiantKills = 0
	self.nDireKills = 0

	self.bSeenWaitForPlayers = false
    
    self.addonInfo = LoadKeyValues("addoninfo.txt")
    self.config = LoadKeyValues("woeconfig.txt")
    self.datadriven = {}
    self:LoadAllDatadrivenFiles()

	if RECOMMENDED_BUILDS_DISABLED then
		gameMode:SetHUDVisible( DOTA_HUD_VISIBILITY_SHOP_SUGGESTEDITEMS, false )
	end

	--print('[WAROFEXALTS] Done loading WarOfExalts gamemode!\n\n')
end

function WarOfExalts:LoadAllDatadrivenFiles()
    self:LoadAbilityDatadrivenFiles()
    self:LoadItemDatadrivenFiles()
    self:LoadUnitDatadrivenFiles()
    self:LoadHeroDatadrivenFiles()
end

function WarOfExalts:LoadAbilityDatadrivenFiles()
    self:_LoadDatadrivenFilesHelper("abilities", self.config.AbilityFile)
end

function WarOfExalts:LoadItemDatadrivenFiles()
    self:_LoadDatadrivenFilesHelper("items", self.config.ItemFile)
end

function WarOfExalts:LoadUnitDatadrivenFiles()
    self:_LoadDatadrivenFilesHelper("units", self.config.UnitFile)

end

function WarOfExalts:LoadHeroDatadrivenFiles()
    self:_LoadDatadrivenFilesHelper("heroes", self.config.HeroFile)
end

function WarOfExalts:_LoadDatadrivenFilesHelper(keyName, fileName)
    print("[WAROFEXALTS] Loading WoE KV file:", fileName)
    local keys = LoadKeyValues(fileName)
    if keys then
        self.datadriven[keyName] = keys
    elseif not self.datadriven[keyName] then
        print("[WAROFEXALTS] " .. fileName .. " not found")
        self.datadriven[keyName] = {}
    end
end

mode = nil

-- This function is called as the first player loads and sets up the WarOfExalts parameters
function WarOfExalts:CaptureWarOfExalts()
	if mode == nil then
		-- Set WarOfExalts parameters
		mode = GameRules:GetGameModeEntity()
		mode:SetRecommendedItemsDisabled( RECOMMENDED_BUILDS_DISABLED )
		mode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
		mode:SetCustomBuybackCostEnabled( CUSTOM_BUYBACK_COST_ENABLED )
		mode:SetCustomBuybackCooldownEnabled( CUSTOM_BUYBACK_COOLDOWN_ENABLED )
		mode:SetBuybackEnabled( BUYBACK_ENABLED )
		mode:SetTopBarTeamValuesOverride ( USE_CUSTOM_TOP_BAR_VALUES )
		mode:SetTopBarTeamValuesVisible( TOP_BAR_VISIBLE )
		mode:SetUseCustomHeroLevels ( USE_CUSTOM_HERO_LEVELS )
		mode:SetCustomHeroMaxLevel ( MAX_LEVEL )
		mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

		--mode:SetBotThinkingEnabled( USE_STANDARD_DOTA_BOT_THINKING )
		mode:SetTowerBackdoorProtectionEnabled( ENABLE_TOWER_BACKDOOR_PROTECTION )

		mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
		mode:SetGoldSoundDisabled( DISABLE_GOLD_SOUNDS )
		mode:SetRemoveIllusionsOnDeath( REMOVE_ILLUSIONS_ON_DEATH )

		self:OnFirstPlayerLoaded()
	end
end

-- This function is called 1 to 2 times as the player connects initially but before they
-- have completely connected
function WarOfExalts:PlayerConnect(keys)
	--print('[WAROFEXALTS] PlayerConnect')
	--util.printTable(keys)

	if keys.bot == 1 then
		-- This user is a Bot, so add it to the bots table
		self.vBots[keys.userid] = 1
	end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function WarOfExalts:OnConnectFull(keys)
	--print ('[WAROFEXALTS] OnConnectFull')
	--util.printTable(keys)
	WarOfExalts:CaptureWarOfExalts()

	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)

	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()

	-- Update the user ID table with this user
	self.vUserIds[keys.userid] = ply

	-- Update the Steam ID table
	self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply

	-- If the player is a broadcaster flag it in the Broadcasters table
	if PlayerResource:IsBroadcaster(playerID) then
		self.vBroadcasters[keys.userid] = 1
		return
	end
end

-- This is an example console command
function WarOfExalts:ExampleConsoleCommand()
	--print( '******* Example Console Command ***************' )
	local cmdPlayer = Convars:GetCommandClient()
	if cmdPlayer then
		local playerID = cmdPlayer:GetPlayerID()
		if playerID ~= nil and playerID ~= -1 then
			-- Do something here for the player who called this command
			PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_viper", 1000, 1000)
		end
	end
	--print( '*********************************************' )
end
