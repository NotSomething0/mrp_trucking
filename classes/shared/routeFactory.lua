---@class CRouteFactory
CRouteFactory = lib.class('CRouteFactory')

---Creates a new instance of CRouteFactory
---@param deliveryManager CDeliveryManager
function CRouteFactory:constructor(deliveryManager)
end

---Creates a new delivery route
---@param routeIndex number
---@param routeType RouteTypes
---@param routeName string
---@param trailerCoordinates table
---@param routeCoordinates table
---@return CDeliveryRoute?
function CRouteFactory.createRoute(routeIndex, routeType, routeName, trailerCoordinates, routeCoordinates)
  local baseRoute = CBaseRoute:new(routeIndex, routeType, routeName, trailerCoordinates)

  if not baseRoute then
    error('Failed to create new instance of CBaseRoute')
  end

  if routeType == RouteTypes.POINT_TO_POINT then
    return CRoutePointToPoint:new(baseRoute)
  end

  if routeType == RouteTypes.MULTI_POINT then
    return CRouteMultiPoint(baseRoute, routeCoordinates)
  end

  if routeType == RouteTypes.MULTI_POINT_FUELING then
    --return CRouteMultiPointFueling:new(routeIndex, routeType, routeName, trailerCoordinates)
  end

  warn(('Failed to create route %s at index %d. An unknown route type was specified %s '):format(routeName, routeIndex, routeType))
end