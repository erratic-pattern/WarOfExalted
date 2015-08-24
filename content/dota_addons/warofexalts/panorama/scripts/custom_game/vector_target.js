'use strict';
(function() {
    
    var currentUnit;
    
    function UpdateVectorTargetBinds(unit) {
        $.Msg("UpdateVectorTargetBinds: ", Entities.GetUnitName(unit))
        currentUnit = unit
        if(Entities.HasCastableAbilities(unit)) {
            var nAbilities = Entities.GetAbilityCount(unit);
            for(var i = 0; i < nAbilities; i++) {
                var abi = Entities.GetAbility(unit, i);
                var name = Abilities.GetAbilityName(abi);
                var key = Abilities.GetKeybind(abi);
                $.Msg(name, ": ", key);
            }
        }
        else {
            //unbind keys
        }
    }
    
    GameEvents.Subscribe("dota_player_update_selected_unit", function(keys) {
        var selection = Players.GetSelectedEntities(Game.GetLocalPlayerID());
        if (selection.length > 0) {
            UpdateVectorTargetBinds(selection[0])
        }
    });
    
    GameEvents.Subscribe("keybind_changed", function(keys) {
        UpdateVectorTargetBinds(currentUnit);
        //this probably recurses
    });
})()