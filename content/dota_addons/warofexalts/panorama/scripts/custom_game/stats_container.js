'use strict';
(function() {
    
    var currentListener;
    
    function unlistenCurrent() {
        if(currentListener) {
            currentListener.unlisten()
            currentListener = null
        }
    }
    
    function UpdateStatsContainer(unitId) {
        unlistenCurrent()
        currentListener = woe.requestUnitInfo(unitId, function(keys) {
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
        });
    }
    
    GameEvents.Subscribe("dota_player_update_selected_unit", function( data ) {
        var panel = $.GetContextPanel(),
            //pId = data.splitscreenplayer,
            selection = Players.GetSelectedEntities(Game.GetLocalPlayerID());
        $.Msg("dota_player_update_selected_unit: ", data);
        $.Msg(selection);
        if(selection.length > 1) {
            panel.visible = false;
            unlistenCurrent()
        }
        else {
            UpdateStatsContainer(selection[0]);
        }        
    });
    
    GameEvents.Subscribe("dota_player_update_query_unit", function( data ) {
        var //pId = data.splitscreenplayer,
            unitId = Players.GetQueryUnit(Game.GetLocalPlayerID());
        if (unitId == -1)
            unitId = Players.GetLocalPlayerPortraitUnit()
        $.Msg("dota_player_update_query_unit: ", unitId);
        UpdateStatsContainer(unitId);
    });
    
    GameEvents.Subscribe("dota_portrait_unit_stats_changed", function( data ) {
        UpdateStatsContainer(Players.GetLocalPlayerPortraitUnit());
    });
    
    GameEvents.Subscribe("dota_portrait_unit_modifiers_changed", function( data ) {
        UpdateStatsContainer(Players.GetLocalPlayerPortraitUnit());
    });
    
    GameEvents.Subscribe("dota_force_portrait_update", function( data ) {
        $.Msg("dota_force_portrait_update: ", data);
        UpdateStatsContainer(Players.GetLocalPlayerPortraitUnit());
    });

    $.Msg("stats_container.js loaded");
})();
