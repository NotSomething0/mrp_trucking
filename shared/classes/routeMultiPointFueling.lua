local IS_SERVER <const> = IsDuplicityVersion()

---@class CRouteMultiPointFueling
---@field private private { m_baseRoute: CBaseRoute, m_fuelStations: table }
CRouteMultiPointFueling = lib.class('CRouteMultiPointFueling')

---@param routeIndex number
---@param rawRoute table
function CRouteMultiPointFueling:constructor(routeIndex, rawRoute)
  local baseRoute, errorMessage = try(function()
    return CBaseRoute:new(routeIndex, rawRoute)
  end)

  if errorMessage then
    error(errorMessage)
  end

  self.private.m_baseRoute = baseRoute
end

---@see CBaseRoute.getIndex
function CRouteMultiPointFueling:getIndex()
  return self.private.m_baseRoute:getIndex()
end

---@see CBaseRoute.getType
function CRouteMultiPointFueling:getType()
  return self.private.m_baseRoute:getType()
end

---@see CBaseRoute.getName
function CRouteMultiPointFueling:getName()
  return self.private.m_baseRoute:getName()
end

---@param routeState RouteStates
---@see CBaseRoute.setState
function CRouteMultiPointFueling:setState(routeState)
  self.private.m_baseRoute:setState(routeState)
end

---Get the current state of this route
---@see CBaseRoute.getState
---@return RouteStates routeState
function CRouteMultiPointFueling:getState()
  return self.private.m_baseRoute:getState()
end

---Get the driver assigned to the route
---@see CBaseRoute.getDriver
function CRouteMultiPointFueling:getDriver()
  return self.private.m_baseRoute:getDriver()
end

---Set the driver assigned to this route
---@param driver CDriver?
function CRouteMultiPointFueling:setDriver(driver)
  self.private.m_baseRoute:setDriver(driver)
end

---@see CBaseRoute.getTruckIndex
---@return number truckIndex
function CRouteMultiPointFueling:getTruckIndex()
  return self.private.m_baseRoute:getTruckIndex()
end

---@see CBaseRoute.setTruckIndex
---@param truckIndex number
function CRouteMultiPointFueling:setTruckIndex(truckIndex)
  self.private.m_baseRoute:setTruckIndex(truckIndex)
end

---Returns the trailer index for this route
---@return number trailerIndex
function CRouteMultiPointFueling:getTrailerIndex()
  return self.private.m_baseRoute:getTrailerIndex()
end

---Returns the network trailer index for this route
---@return number networkTrailerIndex
function CRouteMultiPointFueling:getNetworkTrailerIndex()
  return self.private.m_baseRoute:getNetworkTrailerIndex()
end

---Set the network index for the routes trailer
---@param networkTrailerIndex number
function CRouteMultiPointFueling:setNetworkTrailerIndex(networkTrailerIndex)
  self.private.m_baseRoute:setNetworkTrailerIndex(networkTrailerIndex)
end

---Get the trailer pick up coordinates and heading
---@return { coordinates: table, heading: number }
function CRouteMultiPointFueling:getTrailerPickUpLocation()
  return self.private.m_baseRoute:getTrailerPickUpLocation()
end

---Get the trailers return coordinates and heading
---@return { coordinates: table, heading: number }
function CRouteMultiPointFueling:getTrailerReturnLocation()
  return self.private.m_baseRoute:getTrailerReturnLocation()
end

function CRouteMultiPointFueling:taskCollectTruck()
  self.private.m_baseRoute:createTruckBlip()

  local truckIndex = self:getTruckIndex()

  while true do
    Wait(0)

    DisplayHelpTextThisFrame('TJ_COLLECT_TRUCK', false)

    if IsPedInVehicle(cache.ped, truckIndex, false) then
      local truckCollected, truckCollectError = lib.callback.await('mrp:trucking:truckCollected')

      if truckCollected then
        break
      end

      if not truckCollected then
        ClearHelp(true)
        TriggerEvent('mrp:trucking:displayHelpText', truckCollectError)
      end
    end
  end
end

function CRouteMultiPointFueling:createFuelStationBlips()
  
end

function CRouteMultiPointFueling:taskCollectTrailer()
  self.private.m_baseRoute:createTrailerBlip()

  TriggerEvent('mrp:trucking:displayHelpText', 'TJ_COLLECT_TRAILER')

  while not DoesEntityExist(self:getTrailerIndex()) do
    Wait(1000)
  end

  local driverTruck = self:getTruckIndex()
  local driverTrailer = self:getTrailerIndex()

  while true do
    Wait(500)

    local hasTrailer, truckTrailer = GetVehicleTrailerVehicle(driverTruck)

    if hasTrailer then
      local trailerCollected, trailerCollectionError = lib.callback.await('mrp:trucking:trailerCollected', false)

      if truckTrailer == driverTrailer then
        break
      end

      DetachVehicleFromTrailer(driverTruck)
      TriggerEvent('mrp:trucking:displayHelpText', 'TJ_INCORRECT_TRAILER')
    end
  end
end

function CRouteMultiPointFueling:taskDeliverFuel()

end


function CRouteMultiPointFueling:performRouteTasks()
  self:taskCollectTruck()
end