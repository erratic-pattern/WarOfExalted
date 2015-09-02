'use strict';
(function() {
    var UPDATE_RANGE_INDICATOR_RATE = 1/60;
    var rangeFinderParticle;
    var initialPosition;
    var currentAbil;
    var currentUnit;
    
    GameEvents.Subscribe("vector_target_order_start", function(keys) {
        $.Msg("vector_target_order_start event");
        $.Msg(keys);
        if(Game.GetLocalPlayerID() != keys.playerId)
            return;
        var unit = keys.unitId;
        var pos = keys.initialPosition;
        initialPosition = [pos.x, pos.y, pos.z];
        currentAbil = keys.abilId;
        currentUnit = unit;
        showRangeFinder();
        Abilities.ExecuteAbility(currentAbil, currentUnit, false) //make ability our active ability so that a left-click will complete cast
    });
    
    function showRangeFinder() {
        if(!rangeFinderParticle) {
            rangeFinderParticle = Particles.CreateParticle("particles/vector_target_range_finder_line.vpcf", ParticleAttachment_t.PATTACH_WORLDORIGIN, currentUnit);
            Particles.SetParticleControl(rangeFinderParticle, 1, initialPosition)
            Particles.SetParticleControl(rangeFinderParticle, 0, initialPosition)
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
        if(currentAbil == activeAbil) {
            showRangeFinder();
        }
        if(rangeFinderParticle) {

            var pos = Game.ScreenXYToWorld.apply(Game, GameUI.GetCursorPosition());
            //$.Msg("initial: ", initialPosition, "terminal: ", pos);
            //$.Msg("active ability: ", activeAbil, "current vector ability: ", currentAbil);
            if(currentAbil != activeAbil) {
                hideRangeFinder();
            }
            else {
                Particles.SetParticleControl(rangeFinderParticle, 2, pos)
            }
        }
        if(activeAbil == -1) {
            cancelVectorTargetOrder()
        }
        $.Schedule(UPDATE_RANGE_INDICATOR_RATE, updateRangeFinder);
    }
    updateRangeFinder();
    
    function cancelVectorTargetOrder() {
        if(currentAbil === undefined) return;
        GameEvents.SendCustomGameEventToServer("vector_target_order_cancel", {
            "abilId": currentAbil,
            "unitId": currentUnit,
            "playerId": Game.GetLocalPlayerID(),
        });
        finalize();
    }
    
    
    function finalize() {
        //$.Msg("finalizer called");
        hideRangeFinder();
        initialPosition = undefined;
        currentAbil = undefined;
        currentUnit = undefined;
    }
    
    GameUI.SetMouseCallback(function(event, arg) {
        //TODO: click-and-drag option for vector targeting
        //$.Msg("mouse event: ", event);
        //$.Msg(arg);
        /*
        if(currentUnit == Player.GetLocalPlayerPortraitUnit()) {
            if(arg == 0) { //left click
                if(event == "pressed" || event == "double pressed") {
                    
                }
            }
        }*/
    });
    
    GameEvents.Subscribe("vector_target_order_finish", finalize);
    GameEvents.Subscribe("vector_target_order_cancel", finalize);
    GameEvents.Subscribe("dota_update_selected_unit", function(keys) {
        var selection = Players.GetSelectedEntities(Game.GetLocalPlayerID());
        if(selected[0] != currentUnit) {
            cancelVectorTargetOrder();
        }
    })
    
    $.Msg("vector_target.js loaded");
})()