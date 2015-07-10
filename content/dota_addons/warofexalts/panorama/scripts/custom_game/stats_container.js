'use strict';
(function() {
    var currentListener;
    
    function RequestUnitInfo( unitId ) {
        if(currentListener) GameEvents.Unsubscribe(currentListener)
        currentListener = GameEvents.Subscribe("woe_unit_response", function( data ) {
           //$.Msg("woe_unit_response received: ", data); 
           if(data.unitId === unitId) {
                GameEvents.Unsubscribe(currentListener);
                UpdateStatsContainer(data)
           }               
        });
        //$.Msg("Registered event handler for woe_unit_response");
        GameEvents.SendCustomGameEventToServer("woe_unit_request", {"unitId": unitId});
        //$.Msg("Sent woe_unit_request")
    }
    
    function UpdateStatsContainer( keys ) {
        var panel = $.GetContextPanel();
        if(keys.isWoeUnit) {
            $("#WoeStatsMSLabel").text = keys.MsTotal;
            $("#WoeStatsArmorLabel").text = Math.round(keys.ArmorTotal);
            $("#WoeStatsMRLabel").text = Math.round(keys.MagicResistTotal);
            $("#WoeStatsHasteLabel").text = Math.round(keys.SpellHaste);
            $("#WoeStatsStaminaLabel").text = Math.round(keys.StaminaCurrent.toString()) + "/" + Math.round(keys.StaminaMax.toString());
            panel.visible = true;
        }
        else {
            panel.visible = false;
        }
    }
    
    GameEvents.Subscribe("dota_player_update_selected_unit", function( data ) {
        var panel = $.GetContextPanel(),
            //pId = data.splitscreenplayer,
            selection = Players.GetSelectedEntities(Game.GetLocalPlayerID());
        $.Msg("dota_player_update_selected_unit: ", data);
        $.Msg(selection);
        if(selection.length > 1) {
            panel.visible = false;
            if (currentListener) GameEvents.Unsubscribe(currentListener)
        }
        else {
            RequestUnitInfo(selection[0]);
        }
            
    });
    GameEvents.Subscribe("dota_player_update_query_unit", function( data ) {
        var //pId = data.splitscreenplayer,
            unitId = Players.GetQueryUnit(Game.GetLocalPlayerID());
        $.Msg("dota_player_update_query_unit");
        $.Msg(unitId);
        if (unitId == -1)
            currentUnit = Players.GetLocalPlayerPortraitUnit()
        else
            currentUnit = unitId;
        RequestUnitInfo(currentUnit);
    });
    
    GameEvents.Subscribe("dota_portrait_unit_stats_changed", function( data ) {
        RequestUnitInfo(Players.GetLocalPlayerPortraitUnit());
    });
    
    GameEvents.Subscribe("dota_portrait_unit_modifiers_changed", function( data ) {
        RequestUnitInfo(Players.GetLocalPlayerPortraitUnit());
    });
    
    GameEvents.Subscribe("dota_force_portrait_update", function( data ) {
        $.Msg("dota_force_portrait_update: ", data);
        RequestUnitInfo(Players.GetLocalPlayerPortraitUnit());
    });

    $.Msg("stats_container.js loaded");
    
})();
