'use strict';
(function() {
    
    var dragCastSlots = []
    
    function UpdateDragCastBinds(unit) {
        
    }
    
    GameEvents.Subscribe("dota_player_update_selected_unit", function( keys ) {
        var selection = Players.GetSelectedEntities(Game.GetLocalPlayerID());
        if (selection.length > 0) {
            UpdateDragCastBinds(selection[0])
        }
    });
    
    GameEvents.Subscribe("keybind_changed", function() {
        for(var i = 0; i < 20; i++) {
            $.Msg(Game.GetKeybindForAbility(i));
        }
    });
})()