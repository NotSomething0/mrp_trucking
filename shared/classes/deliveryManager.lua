---@class CDeliveryManager
---@field private private { m_config: CTruckingConfig, m_routes: table<CDeliveryRoute>, m_availableRoutes: table, m_assignedRoutes: table }
CDeliveryManager = lib.class('CDeliveryManager')

---@param config CTruckingConfig
function CDeliveryManager:constructor(config)
  self.private.m_config = config
  self.private.m_availableRoutes = {}
  self.private.m_assignedRoutes = {}

  self:createRoutes()
end

---comment
---@return CTruckingConfig
function CDeliveryManager:getConfig()
  return self.private.m_config
end

function CDeliveryManager:getRouteAtIndex(routeIndex)
  return self.private.m_availableRoutes[routeIndex]
end

function CDeliveryManager:createRoutes()
  local config = self:getConfig()
  local rawRoutes = config:getDeliveryRoutes()
  local routeFactory = CRouteFactory:new()

  for routeIndex = 1, #rawRoutes do
    local rawRoute = rawRoutes[routeIndex]
    local route, errorMessage = try(routeFactory.createRoute, routeIndex, rawRoute)

    if errorMessage then
      warn(('Failed to create route at index %d: %s'):format(routeIndex, errorMessage))
    else
      table.insert(self.private.m_availableRoutes, routeIndex, route)
    end
  end
end

---Get the first available route
---@return CDeliveryRoute|false route
function CDeliveryManager:getAvailableRoute()
  self:processCompletedRoutes()

  if #self.private.m_availableRoutes < 1 then
    return false
  end

  local route = table.remove(self.private.m_availableRoutes, 1)

  table.insert(self.private.m_assignedRoutes, route)

  return route
end

---Get all available routes
---@return CDeliveryRoute[]
function CDeliveryManager:getAvailableRoutes()
  return self.private.m_availableRoutes
end

---Get all assigned routes
---@return table<CDeliveryRoute>
function CDeliveryManager:getAssignedRoutes()
  return self.private.m_assignedRoutes
end

---Get a random free truck spawn point
---@return vector3|false truckSpawnPoint
function CDeliveryManager:getFreeTruckSpawn()
  local truckSpawns = self.private.m_config:getTruckSpawns()

  table.shuffle(truckSpawns)

  for spawnIndex = 1, #truckSpawns do
    local truckSpawn = truckSpawns[spawnIndex]
    local isSpawnFree = true
    local vehiclePool = GetGamePool('CVehicle')

    for vehicleIndex = 1, #vehiclePool do
      local vehicle = vehiclePool[vehicleIndex]
      local coordinates = GetEntityCoords(vehicle)

      -- Break there's a vehicle in the way
      if #(coordinates - truckSpawn.coordinate) <= 5 then
        isSpawnFree = false
        break
      end
    end

    if isSpawnFree == true then
      return truckSpawn
    end
  end

  return false
end

---Add a route to the available routes pool
---@param route CDeliveryRoute
function CDeliveryManager:addRoute(route)
  if not route then
    warn('CDeliveryManager:addRoute - Cannot add nil route')
    return
  end

  -- Check if route is already in available pool
  for _, availableRoute in pairs(self.private.m_availableRoutes) do
    if availableRoute:getIndex() == route:getIndex() then
      warn(('CDeliveryManager:addRoute - Route %s (index %d) is already in available pool'):format(route:getName(), route:getIndex()))
      return
    end
  end

  -- Set route state to unassigned and add to available pool
  route:setState(RouteStates.unassigned)
  route:setDriver(nil)
  table.insert(self.private.m_availableRoutes, route)
end

---comment
---@param route CDeliveryRoute
function CDeliveryManager:makeRouteAvaliable(route)
  if not route then
    return
  end

  route:setDriver(nil)
  route:setState(RouteStates.unassigned)
end

---Process completed routes and move them back to available pool
function CDeliveryManager:processCompletedRoutes()
  local assignedRoutes = self:getAssignedRoutes()

  for idx = 1, #assignedRoutes do
    local route = assignedRoutes[idx]

    if route:getState() == RouteStates.completed then
      table.remove(assignedRoutes, idx)
      self:addRoute(route)
    end
  end
end