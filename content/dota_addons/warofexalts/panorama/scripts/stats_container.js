'use strict';
(function() {
    
    var currentListener; // the current request/response listener handle (see woe.js)
    
    
    /* Update functions and event handlers */
    
    function UpdateStatsContainer(keys) {
        var panel = $.GetContextPanel();
        if(keys.isWoeUnit) {
            if (keys.MoveSpeed != null)
                SetTextOfClass(panel, "WoeStatsMoveSpeedLabel", Math.floor(keys.MoveSpeed));
            if( keys.MagicResist != null )
                SetTextOfClass(panel, "WoeStatsMagicResistLabel", Math.floor(keys.MagicResist));
            if( keys.SpellSpeed != null )
                SetTextOfClass(panel, "WoeStatsSpellSpeedLabel", Math.floor(keys.SpellSpeed));
            UpdateNonWoeStats(keys.id);
            panel.visible = true;
        }
        else {
            panel.visible = false;
        }
    }
    
    function UpdateNonWoeStats(unitId) {
        var panel = $.GetContextPanel();
        SetTextOfClass(panel, "WoeStatsArmorLabel",  Math.floor(Entities.GetArmorForDamageType(unitId, DAMAGE_TYPES.DAMAGE_TYPE_PHYSICAL)));
        SetTextOfClass(panel, "WoeStatsAttackSpeedLabel", Math.floor(Entities.GetIncreasedAttackSpeed(unitId) * 100));
    }
    
    function RequestUnitInfo(unitId) {
        unlistenCurrent();
        currentListener = woe.requestUnitInfo(unitId, UpdateStatsContainer);
    }
    
    
    /* Utility functions */
    
    function unlistenCurrent() {
        if(currentListener) {
            currentListener.unlisten();
            currentListener = undefined;
        }
    }
    
    function SetTextOfClass(panel, cls, txt) {
        panel.FindChildrenWithClassTraverse(cls).forEach(function(e) {
            e.text = txt;
        });
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
            unlistenCurrent()
        }
        else {
            RequestUnitInfo(selection[0]);
        }        
    });
    
    GameEvents.Subscribe("dota_player_update_query_unit", function( data ) {
        var //pId = data.splitscreenplayer,
            unitId = Players.GetQueryUnit(Game.GetLocalPlayerID());
        if (unitId == -1)
            unitId = Players.GetLocalPlayerPortraitUnit()
        //$.Msg("dota_player_update_query_unit: ", unitId);
        RequestUnitInfo(unitId);
    });
    
    GameEvents.Subscribe("dota_portrait_unit_stats_changed", function( data ) {
        RequestUnitInfo(Players.GetLocalPlayerPortraitUnit());
    });
    
    /*GameEvents.Subscribe("dota_portrait_unit_modifiers_changed", function( data ) {
        RequestUnitInfo(Players.GetLocalPlayerPortraitUnit());
    });*/   
    
    GameEvents.Subscribe("dota_force_portrait_update", function( data ) {
        $.Msg("dota_force_portrait_update: ", data);
        RequestUnitInfo(Players.GetLocalPlayerPortraitUnit());
    });
    
    GameEvents.Subscribe("woe_stats_changed", function( data ) {
        if(data.id == Players.GetLocalPlayerPortraitUnit()) {
            $.Msg("woe_stats_changed: ", data)
            RequestUnitInfo(data.id)
        }
    });

    $.Msg("stats_container.js loaded");
})();
