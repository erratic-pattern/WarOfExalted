'use strict';
(function() {
    var unitListener = woe.newUniqueListener(function(unitId) {
        woe.requestUnitInfo(unitId, UpdateStamina);
    });
    
    var currentStamina = 0, maxStamina = 0;
    
    function UpdateStamina(data) {
        //update max stamina
        if (data.MaxStamina != null) {
            maxStamina = data.MaxStamina;
        }
        //update current stamina
        if (data.CurrentStamina != null) {
            currentStamina = data.CurrentStamina;
            $("#StaminaBar").style.width = GetStaminaPercent() * 100 + "%";
        }
        //determine panel visibility
        var panel = $("#StaminaContainer");
        panel.visible = Entities.IsAlive(data.id) && ( maxStamina != 0 );
        if (data.isWoeUnit != null) {
            panel.visible = data.isWoeUnit;
        }
        //update numeric displays
        $("#StaminaCurrentMaxOverlay").text = Math.floor(currentStamina).toString() + " / " + Math.floor(maxStamina).toString();
    }
    
    function GetStaminaPercent() {
        if (maxStamina == 0) //catch divison by zero
            return 0;
        return currentStamina / maxStamina;
    }
    
    //UpdateStamina({});
    
    GameEvents.Subscribe("woe_stats_changed", function( data ) {
        if(data.id == Players.GetLocalPlayerPortraitUnit()) {
            UpdateStamina(data);
        }
    });
    
    GameEvents.Subscribe("dota_player_update_selected_unit", function( data ) {
        var panel = $("#WoeStatsContainer"),
            selection = Players.GetSelectedEntities(Game.GetLocalPlayerID());
        var unitId = selection[0];
        if(unitId == Players.GetLocalPlayerPortraitUnit())
            unitListener.request(unitId);
    });
    
    GameEvents.Subscribe("dota_player_update_query_unit", function( data ) {
        var unitId = Players.GetQueryUnit(Game.GetLocalPlayerID());
        if (unitId == -1) unitId = Players.GetLocalPlayerPortraitUnit();
        if(unitId == Players.GetLocalPlayerPortraitUnit())
            unitListener.request(unitId);
    });

})();

$.Msg("stamina.js loaded");
