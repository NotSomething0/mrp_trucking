---@class CRouteMultiPointVehicles
---@field private private { m_baseRoute: CBaseRoute }
CRouteMultiPointVehicles = lib.class('CRouteMultiPointVehicles')

---@param routeIndex number
---@param routeType RouteTypes
---@param routeName string
---@param routeCoordinates table
function CRouteMultiPointVehicles:constructor(routeIndex, routeType, routeName, routeCoordinates)
  self.private.m_baseRoute = CBaseRoute:new(routeIndex, routeType, routeName, routeCoordinates)
end

function CRouteMultiPointVehicles:performRouteTasks()
  print('performing route tasks ')
end