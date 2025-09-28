---@class CRouteMultiPoint
---@field private private { m_baseRoute: CBaseRoute }
CRouteMultiPoint = lib.class('CRouteMultiPoint')

---Create a new instance of CRouteMultiPoint
---@param baseRoute CBaseRoute
function CRouteMultiPoint:constructor(baseRoute)
  self.private.m_baseRoute = baseRoute
end

---@see CBaseRoute.getIndex
function CRouteMultiPoint:getIndex()
  return self.private.m_baseRoute:getIndex()
end

---@see CBaseRoute.getType
function CRouteMultiPoint:getType()
  return self.private.m_baseRoute:getType()
end

---@see CBaseRoute.getName
function CRouteMultiPoint:getName()
  return self.private.m_baseRoute:getName()
end

---Set the current state for this route
---@param routeState RouteStates
function CRouteMultiPoint:setState(routeState)
  self.private.m_baseRoute:setState(routeState)
end

---Get the current state of this route
---@see CBaseRoute.getState
---@return RouteStates routeState
function CRouteMultiPoint:getState()
  return self.private.m_baseRoute:getState()
end

---@see CBaseRoute.getDriver
function CRouteMultiPoint:getDriver()
  return self.private.m_baseRoute:getDriver()
end

---Set the driver assigned to this route
---@param driver CDriver 
function CRouteMultiPoint:setDriver(driver)
  self.private.m_baseRoute:setDriver(driver)
end

function CRouteMultiPoint:getTruckIndex()
  return self.private.m_baseRoute:getTruckIndex()
end

function CRouteMultiPoint:setTruckIndex(truckIndex)
  self.private.m_baseRoute:setTruckIndex(truckIndex)
end

---Returns the trailer index for this route
---@return number trailerIndex
function CRouteMultiPoint:getTrailerIndex()
  return self.private.m_baseRoute:getTrailerIndex()
end

---Returns the network trailer index for this route
---@return number networkTrailerIndex
function CRouteMultiPoint:getNetworkTrailerIndex()
  return self.private.m_baseRoute:getNetworkTrailerIndex()
end

function CRouteMultiPoint:setNetworkTrailerIndex(networkTrailerIndex)
  self.private.m_baseRoute:setNetworkTrailerIndex(networkTrailerIndex)
end