'use strict';
(function() {
    
    var currentUnit;
    
    //iterate over abilities of given unit
    function EachAbility(unit, cb)  {
        var nAbilities = Entities.GetAbilityCount(unit);
        for(var i = 0; i < nAbilities; i++) {
            cb(Entities.GetAbility(unit, i));
        }
    }
    
    //Checks a unit's abilities for vector targeting and updates client keybinds with
    //vector targeting handlers
    function UpdateVectorTargetBinds(unit) {
        $.Msg("UpdateVectorTargetBinds: ", Entities.GetUnitName(unit))     
        if(currentUnit) CancelAllAbilityRequests(currentUnit) //cancel any unfinished ability requests from previous calls
        currentUnit = unit 
        if(Entities.HasCastableAbilities(unit)) {
            EachAbility(unit, function(abi) {
                if (abi == -1) return;
                woe.requestAbilityInfo(abi, function(info) {
                    if(info.IsVectorTarget) {
                        BindVectorTargeting(Abilities.GetKeybind(abi), info);
                    }
                });
            })
        }
        else { //not castable abilities, unbind all keys
        }
    }
    
    //Bind a vector targeting handler to the given key for the given ability (represented as a woe_ability_response object).
    function BindVectorTargeting(key, info) {
        $.Msg("Binding vector targeting handler for ", Abilities.GetAbilityName(info.id), " at ", key);
        //TODO: figure out correct input context parameter for RegisterKeyBind
        $.RegisterKeyBind("", key, function() {
            $.Msg("Vector target keybind called: ", key)
            $.Msg(arguments);
        });
    }
    
    //cancel all incomplete ability info requests for given unit
    function CancelAllAbilityRequests(unit) {
        EachAbility(unit, function(abi) {
            woe.cancelRequestsById("woe_ability_request", abi);
        });
    }
    
    GameEvents.Subscribe("dota_player_update_selected_unit", function(keys) {
        var selection = Players.GetSelectedEntities(Game.GetLocalPlayerID());
        if (selection.length > 0) {
            UpdateVectorTargetBinds(selection[0]);
        }
    });
    
    GameEvents.Subscribe("keybind_changed", function(keys) {
        UpdateVectorTargetBinds(currentUnit);
        //this probably recurses
    });
})()