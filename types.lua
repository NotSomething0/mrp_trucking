---@diagnostic disable: missing-return

---@alias CDeliveryRoute CRoutePointToPoint|CRouteMultiPointFueling

---Create a new instance of CDepot
---@see CDepot.constructor
---@param config CConfigStore
---@return CDepot
function CDepot:new(config) end

---Create a new instance of CDeliveryManager
---@see CDeliveryManager.constructor
---@param config CConfigStore
---@return CDeliveryManager
function CDeliveryManager:new(config) end

---Create a new instance of CDriverManager
---@see CDriverManager.constructor
---@param config CConfigStore
---@param deliveryManager CDeliveryManager
---@return CDriverManager
function CDriverManager:new(config, deliveryManager) end

---Create a new instance of CDeliveryController
---@see CDeliveryController.constructor
---@param config CConfigStore
---@return CDeliveryController
function CDeliveryController:new(config)
end

---Create a new instance of CConfigStore
---@see CConfigStore.constructor
---@return CConfigStore
function CConfigStore:new()
end

---Create a new instance of CRouteFactory
---@see CRouteFactory.constructor
---@return CRouteFactory
function CRouteFactory:new() end

---Create a new instance of CDriver
---@see CDriver.constructor
---@param playerIndex number
---@return CDriver
function CDriver:new(playerIndex) end

---Create a new instance of CBaseRoute
---@see CBaseRoute.constructor
---@param routeIndex number
---@param routeType RouteTypes
---@param routeName string
---@param trailerCoordinates table
---@return CBaseRoute baseRoute
function CBaseRoute:new(routeIndex, routeType, routeName, trailerCoordinates) end

---Create a new instance of CRoutePointToPoint
---@see CRoutePointToPoint.constructor 
---@param baseRoute CBaseRoute
---@return CRoutePointToPoint route
function CRoutePointToPoint:new(baseRoute) end

---Create a new instance of CRouteMultiPointFueling
---@see CRouteMultiPointFueling.constructor
---@return CRouteMultiPointFueling
function CRouteMultiPointFueling:new() end