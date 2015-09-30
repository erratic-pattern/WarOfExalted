'use strict';
(function() {
    
    // the current request/response listener handle (see woe.js)
    var unitListener = woe.newUniqueListener(function(unitId) {
        woe.requestUnitInfo(unitId, UpdateStatsContainer);
    }); 
    
    
    /* Update functions and event handlers */
    
    function UpdateStatsContainer(keys) {
        var panel = $.GetContextPanel();
        if(keys.isWoeUnit) {
            if (keys.MoveSpeed != null)
                util.SetTextOfClass(panel, "WoeStatsMoveSpeedLabel", Math.floor(keys.MoveSpeed));
            if( keys.MagicResist != null )
                util.SetTextOfClass(panel, "WoeStatsMagicResistLabel", Math.floor(keys.MagicResist));
            if( keys.SpellSpeed != null )
                util.SetTextOfClass(panel, "WoeStatsSpellSpeedLabel", Math.floor(keys.SpellSpeed));
            UpdateNonWoeStats(keys.id);
            panel.visible = true;
        }
        else {
            panel.visible = false;
        }
    }
    
    function UpdateNonWoeStats(unitId) {
        var panel = $.GetContextPanel();
        util.SetTextOfClass(panel, "WoeStatsArmorLabel",  Math.floor(Entities.GetArmorForDamageType(unitId, DAMAGE_TYPES.DAMAGE_TYPE_PHYSICAL)));
        util.SetTextOfClass(panel, "WoeStatsAttackSpeedLabel", Math.floor(Entities.GetIncreasedAttackSpeed(unitId) * 100));
    }
    
    /* Event Handlers */
    
    GameEvents.Subscribe("dota_player_update_selected_unit", function( data ) {
        var panel = $("#WoeStatsContainer"),
            //pId = data.splitscreenplayer,
            selection = Players.GetSelectedEntities(Game.GetLocalPlayerID());
        //$.Msg("dota_player_update_selected_unit: ", data);
        //$.Msg(selection);
        if(selection.length > 1) {
            panel.visible = false;
            unitListener.unlisten();
        }
        else {
            unitListener.request(selection[0]);
        }        
    });
    
    GameEvents.Subscribe("dota_player_update_query_unit", function( data ) {
        var //pId = data.splitscreenplayer,
            unitId = Players.GetQueryUnit(Game.GetLocalPlayerID());
        if (unitId == -1)
            unitId = Players.GetLocalPlayerPortraitUnit()
        //$.Msg("dota_player_update_query_unit: ", unitId);
        unitListener.request(unitId);
    });
    
    GameEvents.Subscribe("dota_portrait_unit_stats_changed", function( data ) {
        unitListener.request(Players.GetLocalPlayerPortraitUnit());
    });
    
    /*GameEvents.Subscribe("dota_portrait_unit_modifiers_changed", function( data ) {
        unitListener.request(Players.GetLocalPlayerPortraitUnit());
    });*/   
    
    GameEvents.Subscribe("dota_force_portrait_update", function( data ) {
        $.Msg("dota_force_portrait_update: ", data);
        unitListener.request(Players.GetLocalPlayerPortraitUnit());
    });
    
    GameEvents.Subscribe("woe_stats_changed", function( data ) {
        if(data.id == Players.GetLocalPlayerPortraitUnit()) {
            $.Msg("woe_stats_changed: ", data)
            unitListener.request(data.id);
        }
    });
})();

$.Msg("stats_container.js loaded");
