---@alias playerIndex number

---@class CDeliveryManager
---@field private private { m_config: CConfigStore, m_routes: table<CDeliveryRoute>, m_availableRoutes: table, m_assignedRoutes: table }
CDeliveryManager = lib.class('CDeliveryManager')

---@param config CConfigStore
function CDeliveryManager:constructor(config)
  self.private.m_config = config
  self.private.m_routes = config:_getDeliveryRoutes()
  self.private.m_availableRoutes = config:_getDeliveryRoutes()
  self.private.m_assignedRoutes = {}
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

---Get an available route for assignment
---@return CDeliveryRoute|false route
function CDeliveryManager:getAvailableRoute()
  if #self.private.m_availableRoutes < 1 then
    return false
  end

  -- Clean up completed routes first
  self:processCompletedRoutes()

  local route = table.remove(self.private.m_availableRoutes, 1)

  table.insert(self.private.m_assignedRoutes, route)

  return route
end

---Process completed routes and move them back to available pool
function CDeliveryManager:processCompletedRoutes()
  for i = #self.private.m_assignedRoutes, 1, -1 do
    local route = self.private.m_assignedRoutes[i]
    
    if route:getState() == RouteStates.completed then
      -- Remove from assigned routes
      table.remove(self.private.m_assignedRoutes, i)
      
      -- Reset route state and add back to available routes
      self:addRoute(route)
    end
  end
end

---Remove a route from assigned routes (used when a route is abandoned or cancelled)
---@param route CDeliveryRoute
function CDeliveryManager:removeAssignedRoute(route)
  for i, assignedRoute in pairs(self.private.m_assignedRoutes) do
    if assignedRoute:getIndex() == route:getIndex() then
      table.remove(self.private.m_assignedRoutes, i)
      self:addRoute(route)
      break
    end
  end
end

---Get all assigned routes
---@return table<CDeliveryRoute>
function CDeliveryManager:getAssignedRoutes()
  return self.private.m_assignedRoutes
end

---Get all available routes
---@return table<CDeliveryRoute>
function CDeliveryManager:getAvailableRoutes()
  return self.private.m_availableRoutes
end

---Get total number of routes
---@return number
function CDeliveryManager:getTotalRouteCount()
  return #self.private.m_routes
end