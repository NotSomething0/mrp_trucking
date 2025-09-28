local IS_SERVER <const> = IsDuplicityVersion()

---@class CRouteMultiPointFueling
---@field private private { m_baseRoute: CBaseRoute, m_fuelStations: table }
CRouteMultiPointFueling = lib.class('CRouteMultiPointFueling')

---@param routeIndex number
---@param routeType RouteTypes
---@param routeName string
---@param routeCoordinates table
function CRouteMultiPointFueling:constructor(routeIndex, routeType, routeName, routeCoordinates)
  local trailerCoordinates = routeCoordinates?.trailerCoordinates
  local fuelStationCoordinates = routeCoordinates?.fuelStationCoordinates

  self.private.m_baseRoute = CBaseRoute:new(routeIndex, routeType, routeName, trailerCoordinates)

  self:setFuelStations(fuelStationCoordinates)
end

-- Boilerplate
function CRouteMultiPointFueling:getIndex()
  return self.private.m_baseRoute:getIndex()
end

function CRouteMultiPointFueling:getName()
  return self.private.m_baseRoute:getName()
end

function CRouteMultiPointFueling:getTruckIndex()
  return self.private.m_baseRoute:getTruckIndex()
end

function CRouteMultiPointFueling:setTruckIndex(truckIndex)
  self.private.m_baseRoute:setTruckIndex(truckIndex)
end

function CRouteMultiPointFueling:setNetworkTrailerIndex(networkTrailerIndex)
  self.private.m_baseRoute:setNetworkTrailerIndex(networkTrailerIndex)
end

function CRouteMultiPointFueling:taskCollectTruck()
  local truckIndex = self:getTruckIndex()

  if not DoesEntityExist(truckIndex) then
    error('truck does not exist!')
  end
end

-- Getters and setters
function CRouteMultiPointFueling:getFuelStations()
  return self.private.m_fuelStations
end

---comment
---@param fuelStationCoordinates table
function CRouteMultiPointFueling:setFuelStations(fuelStationCoordinates)
  self.private.m_fuelStations = {}

  if not fuelStationCoordinates or type(fuelStationCoordinates) ~= 'table' then
    error(('\'fuelStations\' property is missing or malformed'):format(self:getName()))
  end

  local fuelStations, fuelStationsErr =  table.vectorize(fuelStationCoordinates)

  if not fuelStations then
    error(('failed to vectorize fuelStations %s'):format(fuelStationsErr))
  end

  self.private.m_fuelStations = fuelStations
end

function CRouteMultiPointFueling:performRouteTasks()
  self:taskCollectTruck()
end