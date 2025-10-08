---@class CDriverManager
---@field private private { m_config: CTruckingConfig, m_deliveryManager: CDeliveryManager, m_drivers: table } 
CDriverManager = lib.class('CDriverManager')

---@param config CTruckingConfig
---@param deliveryManager CDeliveryManager
function CDriverManager:constructor(config, deliveryManager)
  self.private.m_config = config
  self.private.m_deliveryManager = deliveryManager
  self.private.m_drivers = {}
end

---@return CTruckingConfig
function CDriverManager:getConfig()
  return self.private.m_config
end

---@return CDeliveryManager
function CDriverManager:getRouteManager()
  return self.private.m_deliveryManager
end

---Gets the specified driver 
---@param playerIndex number
---@return CDriver|false driver
function CDriverManager:getDriver(playerIndex)
  return self.private.m_drivers[playerIndex] or false
end

---Adds a driver to the driver pool
---@param driver CDriver
---@return boolean success
function CDriverManager:addDriver(driver)
  local playerIndex = driver:getPlayerIndex()

  if self:getDriver(playerIndex) then
    warn(('Unable to add driver by player index %d they already exist in the driver pool'):format(playerIndex))
    return false
  end

  self.private.m_drivers[playerIndex] = driver
  return true
end

---Removes a driver from the driver pool and cleans up their resources
---@param driver CDriver
function CDriverManager:removeDriver(driver)
  local playerIndex = driver:getPlayerIndex()
  local driverRoute = driver:getDeliveryRoute()
  local driverTruck = driver:getTruckIndex()
  local driverTrailer = driver:getTrailerIndex()

  if DoesEntityExist(driverTruck) then
    DeleteEntity(driverTruck)
  end

  if DoesEntityExist(driverTrailer) then
    DeleteEntity(driverTrailer)
  end

  if driverRoute ~= RouteTypes.INVALID then
    local routeManager = self:getRouteManager()

    routeManager:makeRouteAvaliable(driverRoute)
  end

  self.private.m_drivers[playerIndex] = nil
end

---Try to assign a driver a delivery route
---@param driver CDriver
---@return boolean success, string? errorMessage
function CDriverManager:assignDriverRoute(driver)
  local driverCurrentRoute = driver:getDeliveryRoute()

  if driverCurrentRoute then
    return false, 'TJ_DRIVER_ALREADY_HAS_ROUTE'
  end

  local routeManager = self:getRouteManager()
  local nextRoute = routeManager:getAvailableRoute()

  if not nextRoute then
    return false, 'TJ_NO_ROUTES_AVAILABLE'
  end

  -- Set the driver on the route and route on the driver
  nextRoute:setDriver(driver)
  driver:routeAssigned(nextRoute)

  -- Create and assign vehicles
  local truckSuccess, truckError = self:assignDriverTruck(driver)
  if not truckSuccess then
    -- Cleanup and return route to pool
    routeManager:makeRouteAvaliable(nextRoute)
    driver:setDeliveryRoute(nil)
    return false, truckError
  end

  local trailerSuccess, trailerError = self:assignDriverTrailer(driver)
  if not trailerSuccess then
    -- Cleanup truck and return route to pool
    local truck = nextRoute:getTruckIndex()
    if DoesEntityExist(truck) then
      DeleteEntity(truck)
    end
    routeManager:makeRouteAvaliable(nextRoute)
    driver:setDeliveryRoute(nil)
    return false, trailerError
  end

  return true
end

---Create a truck for the driver
---@param driver CDriver
---@param truckModel string?
---@return table|false truck, string? errorMessage
function CDriverManager:createDriverTruck(driver, truckModel)
  local route = driver:getDeliveryRoute()

  if not route then
    return false, 'TJ_NO_ROUTE_ASSIGNED'
  end

  local routeManager = self:getRouteManager()
  local truckSpawn = routeManager:getFreeTruckSpawn()

  if not truckSpawn then
    return false, 'TJ_NO_TRK_SPAWN'
  end

  if not truckModel or truckModel == '' then
    local config = self:getConfig()
    truckModel = config:getRandomTruckModel()
  end

  local truck, truckCreationError = try(Ox.CreateVehicle, {model = truckModel}, truckSpawn.coordinates, truckSpawn.heading)

  if truckCreationError then
    warn(truckCreationError)
    return false, 'TJ_TRUCK_CREATION_FAILED'
  end

  return truck
end

---Create a trailer for the driver
---@param driver CDriver Driver to create the trailer for
---@param trailerModel string? Optionally pass a trailer model or get a random trailer model if no model is specified
---@return OxVehicleServer|false trailer The trailer that was created or false if the trailer failed to create
---@return string? trailerCreationError Why the trailer failed to create
function CDriverManager:createDriverTrailer(driver, trailerModel)
  local route = driver:getDeliveryRoute()

  if not route then
    return false, 'TJ_NO_ROUTE_ASSIGNED'
  end

  if not trailerModel or trailerModel == '' then
    local config = self:getConfig()
    trailerModel = config:getRandomTrailerModel()
  end

  local trailerPickUpLocation = route:getTrailerPickUpLocation()
  local trailer, trailerCreationError = try(Ox.CreateVehicle, {model = trailerModel,}, trailerPickUpLocation.coordinates, trailerPickUpLocation.heading)

  if trailerCreationError then
    warn(trailerCreationError)
    return false, 'TJ_TRAILER_CREATION_FAILED'
  end

  return trailer
end

---Assign a truck to the driver
---@param driver CDriver
---@return boolean success, string? errorMessage
function CDriverManager:assignDriverTruck(driver)
  local truck, errorMessage = self:createDriverTruck(driver)

  if not truck then
    driver:setStatus(DriverStatus.WAITING_FOR_DELIVERY)
    TriggerClientEvent('mrp:trucking:displayHelpText', driver:getPlayerIndex(), errorMessage)
    return false, errorMessage
  end

  local driverRoute = driver:getDeliveryRoute()

  if not driverRoute then
    DeleteEntity(truck.entity)
    driver:setStatus(DriverStatus.WAITING_FOR_DELIVERY)
    return false, 'TJ_NO_ROUTE_ASSIGNED'
  end

  driver:setTruckIndex(truck.entity)
  driverRoute:setTruckIndex(truck.entity)

  -- Give the truck a chance to settle in the sync tree otherwise NetworkGetEntityFromNetworkId and NetworkGetEntityFromNetworkId become super inconsistent
  Wait(1000)

  TriggerClientEvent('mrp:trucking:truckAssigned', driver:getPlayerIndex(), NetworkGetNetworkIdFromEntity(truck.entity))

  return true
end

---Assign a trailer to the driver
---@param driver CDriver
---@return boolean success, string? errorMessage
function CDriverManager:assignDriverTrailer(driver)
  local trailer, errorMessage = self:createDriverTrailer(driver)

  if not trailer then
    driver:setStatus(DriverStatus.WAITING_FOR_DELIVERY)
    TriggerClientEvent('mrp:trucking:displayHelpText', driver:getPlayerIndex(), errorMessage)
    return false, errorMessage
  end

  driver:setTrailerIndex(trailer.entity)

  TriggerClientEvent('mrp:trucking:trailerAssigned', driver:getPlayerIndex(), NetworkGetNetworkIdFromEntity(trailer.entity))

  return true
end

---Mark a driver's delivery as completed
---@param driver CDriver
function CDriverManager:completeDriverDelivery(driver)
  local route = driver:getDeliveryRoute()

  if not route then
    warn(('Driver %s tried to complete delivery but has no assigned route'):format(driver:getPlayerIndex()))
    return
  end

  route:setState(RouteStates.completed)

  driver:completeRoute()
end

---Process all drivers and assign routes to waiting drivers
function CDriverManager:processWaitingDrivers()
  for _, driver in pairs(self.private.m_drivers) do
    if driver:getStatus() == DriverStatus.WAITING_FOR_DELIVERY then
      local success, errorMessage = self:assignDriverRoute(driver)

      if not success and errorMessage ~= 'TJ_NO_ROUTES_AVAILABLE' then
        -- Log non-route-availability errors
        warn(('Failed to assign route to driver %s: %s'):format(driver:getPlayerIndex(), errorMessage))
      end
    end
  end
end

---comment
---@param driver CDriver
function CDriverManager:payOutDriver(driver)
  local playerIndex = driver:getPlayerIndex()
  local player = Ox.GetPlayer(playerIndex)

  if not player then
    warn(('Attempted to pay out driver %s but failed to get the framework player'):format(playerIndex))
    return
  end

  local playerAccount = player.getAccount()
  -- This is crude and needs improvement but I suppose it's fine for now
  ---@todo: please add good logic to payout
  local payout = math.random(1000, 5000)
  local success = playerAccount.addBalance({amount = payout, message = 'Post OP Salary/Regular Income'})

  TriggerClientEvent('mrp:trucking:displayHelpText', playerIndex, 'TJ_PAYMENT_RECIEVE', {driver:getCompletedDeliveries(), payout})
end