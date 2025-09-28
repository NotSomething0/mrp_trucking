---@class CDriverManager
---@field private private { m_config: CConfigStore, m_deliveryManager: CDeliveryManager, m_drivers: table } 
CDriverManager = lib.class('CDriverManager')

---@param config CConfigStore
---@param deliveryManager CDeliveryManager
function CDriverManager:constructor(config, deliveryManager)
  self.private.m_config = config
  self.private.m_deliveryManager = deliveryManager
  self.private.m_drivers = {}
end

---Check if a driver exists in the driver pool
---@param playerIndex number
---@return boolean exists
function CDriverManager:doesDriverExist(playerIndex)
  return self.private.m_drivers[playerIndex] ~= nil
end

---Gets the specified driver 
---@param playerIndex number
---@return CDriver? driver
function CDriverManager:getDriver(playerIndex)
  return self.private.m_drivers[playerIndex]
end

---Gets the entire driver pool
---@return table<CDriver>
function CDriverManager:getDrivers()
  return self.private.m_drivers
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

  local driverTruck = driver:getTruckIndex()
  local driverTrailer = driver:getTrailerIndex()

  if DoesEntityExist(driverTruck) then
    DeleteEntity(driverTruck)
  else
    print('Drivers truck does not exist?? ', driverTruck)
  end

  if DoesEntityExist(driverTrailer) then
    DeleteEntity(driverTrailer)
  else
    print('Trailer does not exist? ' .. driverTrailer)
  end

  self.private.m_drivers[playerIndex] = nil
end

---Try to assign a driver a delivery route
---@param driver CDriver
---@return boolean success, string? errorMessage
function CDriverManager:assignDriverRoute(driver)
  if driver:getDeliveryRoute() then
    return false, 'TJ_DRIVER_ALREADY_HAS_ROUTE'
  end
  
  local route = self.private.m_deliveryManager:getAvailableRoute()

  if not route then
    return false, 'TJ_NO_ROUTES_AVAILABLE'
  end

  -- Set the driver on the route and route on the driver
  route:setDriver(driver)
  driver:routeAssigned(route)

  -- Create and assign vehicles
  local truckSuccess, truckError = self:assignDriverTruck(driver)
  if not truckSuccess then
    -- Cleanup and return route to pool
    self.private.m_deliveryManager:removeAssignedRoute(route)
    driver:setDeliveryRoute(nil)  --- @todo: we really shouldn't be calling a private function but this is a later problem
    return false, truckError
  end

  local trailerSuccess, trailerError = self:assignDriverTrailer(driver)
  if not trailerSuccess then
    -- Cleanup truck and return route to pool
    local truck = route:getTruckIndex()
    if DoesEntityExist(truck) then
      DeleteEntity(truck)
    end
    self.private.m_deliveryManager:removeAssignedRoute(route)
    driver:setDeliveryRoute(nil)
    return false, trailerError
  end

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

  -- Reset driver state
  ---@todo: We should probably use something else instead of nil
  driver:completeRoute()
end

---Create a truck for the driver
---@param driver CDriver
---@return table|false truck, string? errorMessage
function CDriverManager:createDriverTruck(driver)
  local route = driver:getDeliveryRoute()

  if not route then
    return false, 'TJ_NO_ROUTE_ASSIGNED'
  end

  local truckSpawn = self.private.m_deliveryManager:getFreeTruckSpawn()

  if not truckSpawn then
    return false, 'TJ_NO_TRK_SPAWN'
  end

  local truck = Ox.CreateVehicle({
    model = self.private.m_config:getRandomTruckModel(),
  }, truckSpawn.coordinate, truckSpawn.heading)

  local truckIndex = truck?.entity

  if not truckIndex or not DoesEntityExist(truckIndex) then
    return false, 'TJ_TRUCK_CREATION_FAILED'
  end

  SetEntityHeading(truckIndex, truckSpawn.heading)

  return truck
end

---Create a trailer for the driver
---@param driver CDriver
---@return table|false trailer, string? errorMessage
function CDriverManager:createDriverTrailer(driver)
  local route = driver:getDeliveryRoute()

  if not route then 
    return false, 'TJ_NO_ROUTE_ASSIGNED'
  end

  local trailerModel = self.private.m_config:getRandomTrailerModel()
  local trailerPickUpCoordinate = route:getTrailerPickUpCoordinate()

  if not trailerPickUpCoordinate then
    return false, 'TJ_NO_TRAILER_COORDINATES'
  end

  local trailer = Ox.CreateVehicle({model = trailerModel,}, trailerPickUpCoordinate, trailerPickUpCoordinate.h)

  if not trailer?.entity or not DoesEntityExist(trailer.entity) then
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
    driver:setState(DriverStates.WAITING_FOR_DELIVERY)
    TriggerClientEvent('truckJob:deliveryController:displayHelpText', driver:getPlayerIndex(), errorMessage)
    return false, errorMessage
  end

  local driverRoute = driver:getDeliveryRoute()

  if not driverRoute then
    DeleteEntity(truck.entity)
    driver:setState(DriverStates.WAITING_FOR_DELIVERY)
    return false, 'TJ_NO_ROUTE_ASSIGNED'
  end

  driver:setTruckIndex(truck.entity)
  driverRoute:setTruckIndex(truck.entity)

  Wait(0) -- arbitrary wait I guess??? 
  TriggerClientEvent('truckJob:deliveryController:truckAssigned', driver:getPlayerIndex(), NetworkGetNetworkIdFromEntity(truck.entity))

  return true
end

---Assign a trailer to the driver
---@param driver CDriver
---@return boolean success, string? errorMessage
function CDriverManager:assignDriverTrailer(driver)
  local trailer, errorMessage = self:createDriverTrailer(driver)

  if not trailer then
    driver:setState(DriverStates.WAITING_FOR_DELIVERY)
    TriggerClientEvent('truckJob:deliveryController:displayHelpText', driver:getPlayerIndex(), errorMessage)
    return false, errorMessage
  end

  driver:setTrailerIndex(trailer.entity)

  TriggerClientEvent('truckJob:deliveryController:trailerAssigned', driver:getPlayerIndex(), NetworkGetNetworkIdFromEntity(trailer.entity))
  
  return true
end

---Process all drivers and assign routes to waiting drivers
function CDriverManager:processWaitingDrivers()
  for _, driver in pairs(self.private.m_drivers) do
    if driver:getState() == DriverStates.WAITING_FOR_DELIVERY then
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

  TriggerClientEvent('truckJob:deliveryController:displayHelpText', playerIndex, 'TJ_PAYMENT_RECIEVE', {driver:getCompletedDeliveries(), payout})
end