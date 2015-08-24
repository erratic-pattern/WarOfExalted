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
        reqId = reqData[idKey] = woe.uuid()
    }
    var reqType = woe.listenTable[reqName]
    var resName = reqType.responseName
    var listeners = reqType.listeners[reqId]
    if (!listeners) {
        listeners = reqType.listeners[reqId] = []
    }
    if (listeners.length == 0) {
        var hListener = GameEvents.Subscribe(resName, function(resData) {
            $.Msg(resName, " received: ", resData)
            if(resData[idKey] == reqId) {
                GameEvents.Unsubscribe(hListener)
                reqType.listeners[reqId] = []
                for(var i in listeners) {
                    listeners[i](resData)
                }
            }
        });
        GameEvents.SendCustomGameEventToServer(reqName, reqData)
        $.Msg(reqName, " sent: ", reqData)
    }
    listeners.push(cb)
    return {
        unlisten: function() {
            listeners.splice(listeners.indexOf(cb), 1)
        }
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

woe.uuid = function() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
        return v.toString(16);
    });
};

$.Msg("woe.js loaded")

