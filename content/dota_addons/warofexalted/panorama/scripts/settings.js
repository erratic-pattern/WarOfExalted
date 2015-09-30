'use strict';
(function() {

    function OnSettingsShowButtonPressed() {
        var panel = $("#SettingsContainer");
        panel.visible = !panel.visible;
        if(panel.visible) {
            var config = CustomNetTables.GetTableValue("PlayerConfig", Game.GetLocalPlayerID().toString());
            $("#VectorTargetClickDragToggle").checked = config.VectorTargetClickDrag;
        }
    }

    function OnSettingsCancelButtonPressed() {
        OnSettingsShowButtonPressed();
    }

    function OnSettingsSaveButtonPressed() {
        var pId = Game.GetLocalPlayerID();
        var config = CustomNetTables.GetTableValue("PlayerConfig", pId);
        config.VectorTargetClickDrag = $("#VectorTargetClickDragToggle").checked;
        GameEvents.SendCustomGameEventToServer("woe_config_save", {playerId: pId});
        OnSettingsShowButtonPressed();
    }
})();
$.Msg("settings.js loaded.");