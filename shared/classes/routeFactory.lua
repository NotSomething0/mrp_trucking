---@class CRouteFactory
CRouteFactory = lib.class('CRouteFactory')

---Create a new instance of CRouteFactory
---@param deliveryManager CDeliveryManager
function CRouteFactory:constructor(deliveryManager)
end

---Create a new delivery route instance route
---@param rawRoute table
---@return CDeliveryRoute?
function CRouteFactory.createRoute(routeIndex, rawRoute)
  local routeType = rawRoute?.routeType and RouteTypes[rawRoute.routeType]

  if not routeType then
    error(string.format('%s is not a valid route type', rawRoute?.routeType))
  end

  if routeType == RouteTypes.POINT_TO_POINT then
    return CRoutePointToPoint:new(routeIndex, rawRoute)
  end

  if routeType == RouteTypes.MULTI_POINT_FUELING then
    --return CRouteMultiPointFueling:new(routeIndex, routeType, routeName, trailerCoordinates)
  end

  warn(('Failed to create route %s at index %d. An unknown route type was specified %s '):format(rawRoute?.routeName or 'Unknown', routeIndex, routeType))
end