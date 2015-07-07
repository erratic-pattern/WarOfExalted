(function() {
    
    var currentUnit;
    
    function RequestUnitInfo( unitId ) {
        var listener = GameEvents.Subscribe("woe_unit_response", function( data ) {
           //$.Msg("woe_unit_response received: ", data); 
           if(data.unitId === unitId) {
                GameEvents.Unsubscribe(listener);
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
            $("#WoeStatsMSLabel").text = keys.msTotal;
            $("#WoeStatsArmorLabel").text = Math.round(keys.armorTotal);
            $("#WoeStatsMRLabel").text = Math.round(keys.magicResistTotal);
            $("#WoeStatsHasteLabel").text = Math.round(keys.spellHaste);
            $("#WoeStatsStaminaLabel").text = Math.round(keys.staminaCurrent.toString()) + "/" + Math.round(keys.staminaMax.toString());
            panel.visible = true;
        }
        else {
            panel.visible = false;
        }
    }
    
    GameEvents.Subscribe("dota_player_update_selected_unit", function( data ) {
        var panel = $.GetContextPanel(),
            pId = data.splitscreenplayer,
            selection = Players.GetSelectedEntities(pId);
        //$.Msg("dota_player_update_selected_unit: ", pId, " - ", Players.GetPlayerName(pId));
        //$.Msg(selection);
        if(selection.length > 1) {
            panel.visible = false;
        }
        else {
            currentUnit = selection[0]
            RequestUnitInfo(currentUnit);
        }
            
    });
    GameEvents.Subscribe("dota_player_update_query_unit", function( data ) {
       var pId = data.splitscreenplayer,
           unitId = Players.GetQueryUnit(pId);
       //$.Msg("dota_player_update_query_unit: ", pId, " - ", Players.GetPlayerName(pId));
       //$.Msg(unitId);
       currentUnit = unitId;
       RequestUnitInfo(unitId);
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
