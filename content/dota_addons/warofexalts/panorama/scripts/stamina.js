'use strict';
(function() {
    var UPDATE_RATE = 1/30; // stamina UI update rate
    var TIMER_START_THRESHOLD = 0.75 // number of seconds that must elapse before we begin showing the stamina timer. Some toggle
                                     // abilities and stamina drains will cause the stamina timer to jump around rapidly if this is not used.
    var TIMER_END_THRESHOLD = 0.9  // percentage of the stamina timer where we stop updating until the timer reaches 100%
                                   // this is done because it's difficult to see when it's very close to 100% complete
    var unitListener = woe.newUniqueListener(function(unitId) {
        woe.requestUnitInfo(unitId, function(data) { staminaHistory.update(data) });
    });
    
    var staminaHistory = {
        id: null,
        isWoeUnit: false,
        CurrentStamina: 0,
        MaxStamina: 0,
        StaminaRechargeDelay: 0,
        StaminaTimer: 0,
        ForceStaminaRecharge: false,
        StaminaRegen: 0,
        
        //updates history values from a table
        update: function(data) {
            for(var key in data) {
                if (this[key] !== undefined && data[key] !== undefined) {
                    //$.Msg("Updating: ", key, " = ", data[key]);
                    this[key] = data[key];
                }
            }
        },
        
        getStaminaRechargeDelayRemaining: function() {
            if(this.ForceStaminaRecharge)
                return 0;
            return Math.max(0, this.StaminaRechargeDelay - (Game.GetGameTime() - this.StaminaTimer))
        },
        getStaminaPercent:  function() {
            if (staminaHistory.MaxStamina == 0) //catch divison by zero
                return 0;
            return staminaHistory.CurrentStamina / staminaHistory.MaxStamina;
        },
    };
    
    function StaminaTick() {
        //determine panel visibility       
        var visible = staminaHistory.id != null && Entities.IsAlive(staminaHistory.id);
        if (staminaHistory.isWoeUnit != null) {
            visible = visible && staminaHistory.isWoeUnit && ( staminaHistory.MaxStamina != 0 );
        }
        $("#StaminaContainer").visible = visible;
        if (!visible) return; //finish early if panel not visible
        
        //update stamina bar
        $("#StaminaBar").style.width = staminaHistory.getStaminaPercent() * 100 + "%";
        //update numeric stamina display
        $("#StaminaCurrentMaxDisplay").text = staminaHistory.CurrentStamina.toFixed(1) + " / " + Math.floor(staminaHistory.MaxStamina);
        
        
        //update recharge cooldown timer
        var remaining = staminaHistory.getStaminaRechargeDelayRemaining();
        var delay = staminaHistory.StaminaRechargeDelay;
        if(remaining > 0 && delay > 0) {
            var ratio = 1 - (remaining / delay);
            var elapsed = delay - remaining;
            if ( delay > 1 && elapsed < TIMER_START_THRESHOLD ) { //don't show the timer until we hit the 0.75 second mark
                ratio = 0;
            }
            else if (ratio < 1 && ratio >= TIMER_END_THRESHOLD) { //keep the timer fixed near the end
                ratio = TIMER_END_THRESHOLD;
            }
            $("#StaminaTimerProgress").style.width = ratio * 100 + "%";
            $("#StaminaTimerNumber").visible = true;
            $("#StaminaTimerNumber").text = Math.ceil(remaining);
        }
        else {
            $("#StaminaTimerProgress").style.width = "100%";
            $("#StaminaTimerNumber").visible = false;
        }
        
        //update regen display
        var regenPanel = $("#StaminaRegenDisplay");
        regenPanel.visible = Math.floor(staminaHistory.CurrentStamina) != Math.floor(staminaHistory.MaxStamina);
        if (regenPanel.visible) {
            var regen = staminaHistory.StaminaRegen;
            var regenText = regen.toFixed(1);
            if (regen > 0) {
                regenText = "+" + regenText;
            }
            regenPanel.text = regenText;
        }
    }
    
    //UpdateStamina({});
    
    GameEvents.Subscribe("woe_stats_changed", function( data ) {
        if(data.id == Players.GetLocalPlayerPortraitUnit()) {
            staminaHistory.update(data); //update our state 
        }
    });
    
    GameEvents.Subscribe("dota_player_update_selected_unit", function( data ) {
        var panel = $("#WoeStatsContainer"),
            selection = Players.GetSelectedEntities(Game.GetLocalPlayerID());
        var unitId = selection[0];
        if(unitId == Players.GetLocalPlayerPortraitUnit())
            unitListener.request(unitId); //update our state
    });
    
    GameEvents.Subscribe("dota_player_update_query_unit", function( data ) {
        var unitId = Players.GetQueryUnit(Game.GetLocalPlayerID());
        if (unitId == -1) unitId = Players.GetLocalPlayerPortraitUnit();
        if(unitId == Players.GetLocalPlayerPortraitUnit())
            unitListener.request(unitId); //update our state
    });
    
    function StartGlow(panel, glowRate) {
        if (panel.visible) {
            panel.ToggleClass("BorderGlow");
        }
        else {
            panel.AddClass("BorderGlow");
        }
        $.Schedule(glowRate, function() { StartGlow(panel, glowRate); });
    }
    
    //StartGlow($("#StaminaTimerProgress"), 0.5);
    
    $.Schedule(UPDATE_RATE, function UpdateTimer() {
        StaminaTick();
        $.Schedule(UPDATE_RATE, UpdateTimer);
    });

})();

$.Msg("stamina.js loaded");
