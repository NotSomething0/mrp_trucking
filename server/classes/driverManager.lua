---@class CDriverManager
---@field private private { m_config: CTruckingConfig, m_routeManager: CDeliveryManager, m_drivers: table } 
CDriverManager = lib.class('CDriverManager')

---@param config CTruckingConfig
---@param deliveryManager CDeliveryManager
function CDriverManager:constructor(config, deliveryManager)
  self.private.m_config = config
  self.private.m_routeManager = deliveryManager
  self.private.m_drivers = {}
end

---Gets the specified driver 
---@param playerIndex number
---@return CDriver? driver
function CDriverManager:getDriver(playerIndex)
  return self.private.m_drivers[playerIndex]
end

---Clock in a player and add them to the driver pool
---@param playerIndex number
function CDriverManager:clockInPlayer(playerIndex)
  if self:getDriver(playerIndex) then
    return false, 'TJ_ALREADY_CLOCKED_IN'
  end

  self.private.m_drivers[playerIndex] = CDriver:new(playerIndex)

  return true
end

---Removes a driver from the driver pool and cleans up their entities
---@param driver CDriver
function CDriverManager:removeDriver(driver)
  local driverTruck = driver:getTruckIndex()
  local driverTrailer = driver:getTrailerIndex()

  if DoesEntityExist(driverTruck) then
    DeleteEntity(driverTruck)
  end

  if DoesEntityExist(driverTrailer) then
    DeleteEntity(driverTrailer)
  end

  self.private.m_drivers[driver:getPlayerIndex()] = nil
end

---Clocks out a driver ensures they are not completing a delivery and are paid out.
---@param playerIndex number
---@return boolean success, string? errorMessage
function CDriverManager:clockOutPlayer(playerIndex)
  local driver = self:getDriver(playerIndex)

  if type(driver) ~= 'table' or getmetatable(driver) ~= CDriver then
    return false, 'TJ_ALREADY_CLOCKED_OUT'
  end

  local driverRoute = driver:getDeliveryRoute()

  if driverRoute and driverRoute:getType() ~= RouteTypes.INVALID then
    if driverRoute:getState() ~= RouteStates.completed then
      return false, 'TJ_ROUTE_NOT_COMPLETE'
    end

    -- Driver still has a route assigned to them mark it as avaliable
    self.private.m_routeManager:makeRouteAvaliable(driverRoute)
  end

  self:payOutDriver(driver)
  self:removeDriver(driver)

  return true
end

---Assign a player a delivery route
---@param playerIndex number
---@return boolean success, string? errorMessage
function CDriverManager:assignPlayerRoute(playerIndex)
  local driver = self:getDriver(playerIndex)

  if not driver then
    return false, 'TJ_NOT_CLOCKED_IN'
  end

  if driver:getDeliveryRoute() then
    return false, 'TJ_ROUTE_NOT_COMPLETE'
  end

  local nextRoute = self.private.m_routeManager:getAvailableRoute()

  if not nextRoute then
    return false, 'TJ_NO_ROUTES_AVAILABLE'
  end

  driver:assignRoute(nextRoute)

  local success, errorMessage = self:createDriverEntities(driver)

  if not success then
    driver:setDeliveryRoute(nil)
    self.private.m_routeManager:makeRouteAvaliable(nextRoute)

    return false, errorMessage
  end

  return true
end

---Create entities for a drivers delivery route
---@param driver CDriver
---@return boolean success, string? errorMessage
function CDriverManager:createDriverEntities(driver)
  local truckCreated, truckCreationError = self:assignDriverTruck(driver)

  if not truckCreated then
    return false, truckCreationError
  end

  local trailerCreated, trailerCreationError = self:assignDriverTrailer(driver)

  if not trailerCreated then
    if DoesEntityExist(driver:getTruckIndex()) then
      DeleteEntity(driver:getTruckIndex())
    end

    return false, trailerCreationError
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

  local truckSpawn = self.private.m_routeManager:getFreeTruckSpawn()

  if not truckSpawn then
    return false, 'TJ_NO_TRK_SPAWN'
  end

  if not truckModel or truckModel == '' then
    local config = self.private.m_config
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
    local config = self.private.m_config
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
  local previousDriverTruck = driver:getTruckIndex()

  if DoesEntityExist(previousDriverTruck) then
    local driverRoute = driver:getDeliveryRoute()

    driverRoute:setTruckIndex(previousDriverTruck)
    TriggerClientEvent('mrp:trucking:truckAssigned', driver:getPlayerIndex(), NetworkGetNetworkIdFromEntity(previousDriverTruck))

    return true
  end

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

  -- Give the truck a chance to settle in the sync tree 
  -- Otherwise NetworkGetEntityFromNetworkId and NetworkGetEntityFromNetworkId become super inconsistent
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

  local driverRoute = driver:getDeliveryRoute()

  if not driverRoute then
    DeleteEntity(trailer.entity)
    driver:setStatus(DriverStatus.WAITING_FOR_DELIVERY)
    return false, 'TJ_NO_ROUTE_ASSIGNED'
  end

  driverRoute:setTrailerIndex(trailer.entity)

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
      local success, errorMessage = self:assignPlayerRoute(driver:getPlayerIndex())

      if not success and errorMessage ~= 'TJ_NO_ROUTES_AVAILABLE' then
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