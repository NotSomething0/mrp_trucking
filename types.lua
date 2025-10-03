---@diagnostic disable: missing-return

---@alias TrailerLocation { coordinates: vector3, heading: number }
---@alias CDeliveryRoute CRoutePointToPoint|CRouteMultiPointFueling|false

---Create a new instance of CDepot
---@see CDepot.constructor
---@param config CTruckingConfig
---@return CDepot
function CDepot:new(config) end

---Create a new instance of CDeliveryManager
---@see CDeliveryManager.constructor
---@param config CTruckingConfig
---@return CDeliveryManager
function CDeliveryManager:new(config) end

---Create a new instance of CDriverManager
---@see CDriverManager.constructor
---@param config CTruckingConfig
---@param deliveryManager CDeliveryManager
---@return CDriverManager
function CDriverManager:new(config, deliveryManager) end

---Create a new instance of CDeliveryController
---@see CDeliveryController.constructor
---@param config CTruckingConfig
---@return CDeliveryController
function CDeliveryController:new(config)
end

---Create a new instance of CTruckingConfig
---@see CTruckingConfig.constructor
---@return CTruckingConfig
function CTruckingConfig:new()
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
---@param rawRoute table
---@return CBaseRoute baseRoute
function CBaseRoute:new(routeIndex, rawRoute) end

---Create a new instance of CRoutePointToPoint
---@see CRoutePointToPoint.constructor 
---@param baseRoute CBaseRoute
---@return CRoutePointToPoint route
function CRoutePointToPoint:new(baseRoute) end

---Create a new instance of CRouteMultiPointFueling
---@see CRouteMultiPointFueling.constructor
---@return CRouteMultiPointFueling
function CRouteMultiPointFueling:new() end