---@diagnostic disable: missing-return

---@alias CDeliveryRoute CRoutePointToPoint|CRouteMultiPointFueling

---Creates a new instance of CDepot
---@see CDepot.constructor
---@param blipCoordinate vector3
---@return CDepot
function CDepot:new(blipCoordinate) end

---comment
---@param config CConfigStore
---@return CDeliveryManager
function CDeliveryManager:new(config) end

---comments
---@param config CConfigStore
---@param deliveryManager CDeliveryManager
---@return CDriverManager
function CDriverManager:new(config, deliveryManager) end

---Creates a new instance of CDeliveryController
---@param config CConfigStore
---@return CDeliveryController
function CDeliveryController:new(config)
end

---Creates a new instance of CConfigStore
---@see CConfigStore.constructor
---@return CConfigStore
function CConfigStore:new()
end

---Creates a new instance of CRouteFactory
---@see CRouteFactory.constructor
---@return CRouteFactory
function CRouteFactory:new() end

---comment
---@param playerIndex number
---@return CDriver
function CDriver:new(playerIndex) end

---Creates a new instance of CBaseRoute
---@see CBaseRoute.constructor
---@param routeIndex number
---@param routeType RouteTypes
---@param routeName string
---@param trailerCoordinates table
---@return CBaseRoute baseRoute
function CBaseRoute:new(routeIndex, routeType, routeName, trailerCoordinates) end

---Creates a new instance of CRoutePointToPoint
---@see CRoutePointToPoint.constructor 
---@param baseRoute CBaseRoute
---@return CRoutePointToPoint route
function CRoutePointToPoint:new(baseRoute) end

---Create a new instance of CRouteMultiPointFueling
---@see CRouteMultiPointFueling.constructor
---@return CRouteMultiPointFueling
function CRouteMultiPointFueling:new() end