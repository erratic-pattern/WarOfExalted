'use strict';
(function() {
    //constants
    var UPDATE_RANGE_INDICATOR_RATE = 1/60;
    var DEFAULT_PARTICLE = "particles/vector_target_range_finder_line.vpcf"
    var DEFAULT_CONTROL_POINTS = {
        0 : "initial",
        1 : "initial",
        2 : "terminal"
    }
    //state variables
    var rangeFinderParticle;
    var eventKeys = { };
    
    GameEvents.Subscribe("vector_target_order_start", function(keys) {
        //$.Msg("vector_target_order_start event");
        //$.Msg(keys);
        if(Game.GetLocalPlayerID() != keys.playerId)
            return;
        //initialize local state
        eventKeys = keys;
        var p = keys.initialPosition;
        keys.initialPosition = [p.x, p.y, p.z];
        //set defaults
        keys.particleName = keys.particleName || DEFAULT_PARTICLE;
        keys.cpMap = keys.cpMap || DEFAULT_CONTROL_POINTS;
        
        showRangeFinder();
        Abilities.ExecuteAbility(keys.abilId, keys.unitId, false); //make ability our active ability so that a left-click will complete cast
    });
    
    function showRangeFinder() {
        if(!rangeFinderParticle) {
            rangeFinderParticle = Particles.CreateParticle(eventKeys.particleName, ParticleAttachment_t.PATTACH_WORLDORIGIN, eventKeys.unitId);
            mapToControlPoints({"initial": eventKeys.initialPosition});
        }
    }
    
    function hideRangeFinder() {
        if(rangeFinderParticle) {
            Particles.DestroyParticleEffect(rangeFinderParticle, false);
            Particles.ReleaseParticleIndex(rangeFinderParticle);
            rangeFinderParticle = undefined;
        }
    }
    
    function updateRangeFinder() {
        var activeAbil = Abilities.GetLocalPlayerActiveAbility();
        //$.Msg("active ability: ", Abilities.GetLocalPlayerActiveAbility());
        if(eventKeys.abilId === activeAbil) {
            showRangeFinder();
        }
        if(rangeFinderParticle) {
            if(eventKeys.abilId !== activeAbil) {
                hideRangeFinder();
            }
            else {
                var pos = GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition());
                if(pos != null)
                    mapToControlPoints({"terminal" : pos}, true);
            }
        }
        if(activeAbil === -1) {
            cancelVectorTargetOrder()
        }
        $.Schedule(UPDATE_RANGE_INDICATOR_RATE, updateRangeFinder);
    }
    updateRangeFinder();
    
    function cancelVectorTargetOrder() {
        var abilId = eventKeys.abilId
        if(abilId === undefined) return;
        GameEvents.SendCustomGameEventToServer("vector_target_order_cancel", eventKeys);
        finalize();
    }
    
    
    function mapToControlPoints(keyMap, ignoreConst) {
        var cpMap = eventKeys.cpMap;
        for(var cp in cpMap) {
            var vector = cpMap[cp].split(" ");
            if(vector.length == 1) {
                vector = [vector[0], vector[0], vector[0]]
            }
            else if(vector.length != 3) {
                throw new Error("Vector for CP " + cp + " has " + vector.length + " components");
            }
            var shouldSet = !ignoreConst;
            for(var i in vector) {
                var val = vector[i];
                var out;
                if((out = keyMap[val]) !== undefined) { //check for string variables
                    vector[i] = out[i];
                    if(ignoreConst) shouldSet = true;
                }
                else if(!isNaN(out = parseInt(val))) { //is a number
                    vector[i] = out;
                }
                else {
                    shouldSet = false;
                }
            }
            if(shouldSet) {
                Particles.SetParticleControl(rangeFinderParticle, parseInt(cp), vector);
            }
        }
    }
    
    function finalize() {
        //$.Msg("finalizer called");
        hideRangeFinder();
        eventKeys = { };
    }
    
    GameUI.SetMouseCallback(function(event, arg) {
        //TODO: click-and-drag option for vector targeting
    });
    
    //GameEvents.Subscribe("vector_target_order_finish", finalize);
    GameEvents.Subscribe("vector_target_order_cancel", finalize);
    GameEvents.Subscribe("dota_update_selected_unit", function(keys) {
        var selection = Players.GetSelectedEntities(Game.GetLocalPlayerID());
        if(selected[0] !== eventKeys.unitId) {
            cancelVectorTargetOrder();
        }
    });
    
    $.Msg("vector_target.js loaded");
})()