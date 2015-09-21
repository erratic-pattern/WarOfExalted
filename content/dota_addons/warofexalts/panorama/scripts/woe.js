'use strict';
var woe = { }; // initialize woe module

woe.listenTable = { };

woe.addRequestType = function(reqName, resName) {
    woe.listenTable[reqName] = {
        responseName: resName,
        listeners: { }
    }
};

woe.request = function(reqName, reqData, cb, idKey) {
    if(idKey === undefined) idKey = "id"
    var reqId = reqData[idKey]
    if (reqId === undefined) {
        reqId = reqData[idKey] = util.uuid()
    }
    var reqType = woe.listenTable[reqName]
    var resName = reqType.responseName
    var listeners = reqType.listeners[reqId]
    if (listeners === undefined) {
        listeners = reqType.listeners[reqId] = []
    }
    if (listeners.length == 0) {
        var hListener = GameEvents.Subscribe(resName, function(resData) {
            if(resData[idKey] == reqId) {
                if(woe.testing)
                    $.Msg(resName, " received: ", resData)
                GameEvents.Unsubscribe(hListener)
                reqType.listeners[reqId] = []
                for(var i in listeners) {
                    listeners[i](resData)
                }
            }
        });
        GameEvents.SendCustomGameEventToServer(reqName, reqData)
        if (woe.testing)
            $.Msg(reqName, " sent: ", reqData);
    }
    listeners.push(cb)
    return {
        unlisten: function() {
            var i = listeners.indexOf(cb);
            if (i > -1) listeners.splice(i, 1);
        }
    };
};

woe.cancelRequestsById = function(reqName, reqId) {
    woe.listenTable[reqName].listeners[reqId] = [];
};

woe.newUniqueListener = function(requestFunc) {
    return {
        request: function() {
            this.unlisten();
            this.currentListener = requestFunc.apply(undefined, arguments);
        },
        unlisten: function() {
            if(this.currentListener) {
                this.currentListener.unlisten();
                this.currentListener = undefined;
            }
        },
    };
};

woe.addRequestType("woe_unit_request", "woe_unit_response")
woe.addRequestType("woe_ability_request", "woe_ability_response")

woe.requestUnitInfo = function( unitId, cb ) {
    return woe.request("woe_unit_request", {id: unitId}, cb);
};

woe.requestAbilityInfo = function( abiId, cb) {
    return woe.request("woe_ability_request", {id: abiId}, cb);
};

woe.testing = CustomNetTables.GetTableValue("GameConfig", "Testing");

woe._Msg = $.Msg;
if(woe.testing !== undefined && !woe.testing)
    $.Msg = function() { };

$.Msg("woe.js loaded")
