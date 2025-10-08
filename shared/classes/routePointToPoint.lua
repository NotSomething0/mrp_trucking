---@class CRoutePointToPoint
---@field private private { m_baseRoute: CBaseRoute, m_routeBlip: number }
CRoutePointToPoint = lib.class('CRoutePointToPoint')

---@param routeIndex number
---@param rawRoute table
function CRoutePointToPoint:constructor(routeIndex, rawRoute)
  local baseRoute, errorMessage = try(function()
    return CBaseRoute:new(routeIndex, rawRoute)
  end)

  if errorMessage then
    error(errorMessage)
  end

  self.private.m_baseRoute = baseRoute
end

---@see CBaseRoute.getIndex
function CRoutePointToPoint:getIndex()
  return self.private.m_baseRoute:getIndex()
end

---@see CBaseRoute.getType
function CRoutePointToPoint:getType()
  return self.private.m_baseRoute:getType()
end

---@see CBaseRoute.getName
function CRoutePointToPoint:getName()
  return self.private.m_baseRoute:getName()
end

---@param routeState RouteStates
---@see CBaseRoute.setState
function CRoutePointToPoint:setState(routeState)
  self.private.m_baseRoute:setState(routeState)
end

---Get the current state of this route
---@see CBaseRoute.getState
---@return RouteStates routeState
function CRoutePointToPoint:getState()
  return self.private.m_baseRoute:getState()
end

---Get the driver assigned to the route
---@see CBaseRoute.getDriver
function CRoutePointToPoint:getDriver()
  return self.private.m_baseRoute:getDriver()
end

---Set the driver assigned to this route
---@param driver CDriver?
function CRoutePointToPoint:setDriver(driver)
  self.private.m_baseRoute:setDriver(driver)
end

---@see CBaseRoute.getTruckIndex
---@return number truckIndex
function CRoutePointToPoint:getTruckIndex()
  return self.private.m_baseRoute:getTruckIndex()
end

---@see CBaseRoute.setTruckIndex
---@param truckIndex number
function CRoutePointToPoint:setTruckIndex(truckIndex)
  self.private.m_baseRoute:setTruckIndex(truckIndex)
end

---Returns the trailer index for this route
---@return number trailerIndex
function CRoutePointToPoint:getTrailerIndex()
  return self.private.m_baseRoute:getTrailerIndex()
end

---Returns the network trailer index for this route
---@return number networkTrailerIndex
function CRoutePointToPoint:getNetworkTrailerIndex()
  return self.private.m_baseRoute:getNetworkTrailerIndex()
end

---Set the network index for the routes trailer
---@param networkTrailerIndex number
function CRoutePointToPoint:setNetworkTrailerIndex(networkTrailerIndex)
  self.private.m_baseRoute:setNetworkTrailerIndex(networkTrailerIndex)
end

---Get the trailer pick up coordinates and heading
---@return { coordinates: table, heading: number }
function CRoutePointToPoint:getTrailerPickUpLocation()
  return self.private.m_baseRoute:getTrailerPickUpLocation()
end

---Get the trailers return coordinates and heading
---@return { coordinates: table, heading: number }
function CRoutePointToPoint:getTrailerReturnLocation()
  return self.private.m_baseRoute:getTrailerReturnLocation()
end

function CRoutePointToPoint:taskCollectTruck()
  self.private.m_baseRoute:createTruckBlip()

  local truckIndex = self:getTruckIndex()

  while true do
    Wait(0)

    DisplayHelpTextThisFrame('TJ_COLLECT_TRUCK', false)

    if IsPedInVehicle(cache.ped, truckIndex, false) then
      -- Server side GetVehiclePedIsIn sometimes returns 0 give a chance for the SyncTree to update
      Wait(500)

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

function CRoutePointToPoint:taskCollectTrailer()
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

      if not trailerCollected then
        DetachVehicleFromTrailer(driverTruck)
        TriggerEvent('mrp:trucking:displayHelpText', trailerCollectionError)
      end

      if truckTrailer == driverTrailer then
        break
      end
    end
  end
end

function CRoutePointToPoint:taskDeliverTrailer()
  self:createRouteBlip()

  TriggerEvent('mrp:trucking:displayHelpText', 'TJ_DELIVER_TRAILER')

  local truckIndex = self:getTruckIndex()
  local trailerIndex = self:getTrailerIndex()
  local trailerReturnLocation = self:getTrailerReturnLocation()

  local trailerWidth = GetEntityWidth(trailerIndex)
  local trailerDropAreaOrigin = trailerReturnLocation.coordinates + trailerWidth
  local trailerDropAreaExtent = trailerReturnLocation.coordinates - trailerWidth

  local trailerDropMarker = lib.marker.new({
    type = 30,
    coords = trailerReturnLocation.coordinates,
    width = 5,
    height = 5,
    faceCamera = false,
    bobUpAndDown = true
  })

  while true do
    Wait(0)

    local playerWithinDrawDistance = #(cache.coords - trailerReturnLocation.coordinates) <= 50

    if not IsVehicleAttachedToTrailer(truckIndex) and not playerWithinDrawDistance then
      DisplayHelpTextThisFrame('TJ_TRAILER_DISCONNECTED_FAR', false)
    end

    if GetEntityHealth(trailerIndex) <= 100 then
      TriggerServerEvent('truckJob:forceQuit', 'TRAILER_DESTROYED')
      break
    end

    if playerWithinDrawDistance then
      trailerDropMarker:draw()

      local playerTrailerInArea = IsEntityInAngledArea(trailerIndex,
        trailerDropAreaOrigin.x, trailerDropAreaOrigin.y, trailerDropAreaOrigin.z,
        trailerDropAreaExtent.x, trailerDropAreaExtent.y, trailerDropAreaExtent.z,
        trailerWidth, false, false, 0)

      if not playerTrailerInArea then
        trailerDropMarker.color = { r = 255, g = 0, b = 0, a = 100 }

        if not IsVehicleAttachedToTrailer(truckIndex) then
          DisplayHelpTextThisFrame('TJ_TRAILER_DISCONNECTED_CLOSE', false)
        end
      end

      if playerTrailerInArea then
        trailerDropMarker.color = { r = 0, g = 255, b = 91, a = 100 }
        DisplayHelpTextThisFrame('TJ_HINT_DROP_TRAILER', false)

        if not IsVehicleAttachedToTrailer(truckIndex) then
          local trailerDelivered, trailerDeliveryError = lib.callback.await('mrp:trucking:trailerDelivered', false)

          if not trailerDelivered then
            ClearHelp(true)
            FreezeEntityPosition(truckIndex, true)
            TriggerEvent('mrp:trucking:displayHelpText', trailerDeliveryError)

            Wait(4000) -- Arbitrary wait so the player has time to read the message

            FreezeEntityPosition(truckIndex, false)
            SetTrailerAttachmentEnabled(trailerIndex, true)
            AttachVehicleToTrailer(truckIndex, trailerIndex, 1.0)
          end

          if trailerDelivered then
            SetEntityNoCollisionEntity(trailerIndex, truckIndex, true)
            SetTrailerAttachmentEnabled(trailerIndex, false)
            ---@diagnostic disable-next-line: redundant-parameter
            SetTrailerLegsLowered(trailerIndex)
            DetachVehicleFromTrailer(truckIndex)
            SetEntityHeading(trailerIndex, trailerReturnLocation.heading)
            SetEntityCoords(trailerIndex, trailerReturnLocation.coordinates.x, trailerReturnLocation.coordinates.y,
              trailerReturnLocation.coordinates.z, false, false, false, false)

            local trailerBlip = GetBlipFromEntity(trailerIndex)

            RemoveBlip(trailerBlip)
            RemoveBlip(self.private.m_routeBlip)
            break
          end
        end
      end
    end
  end
end

---@todo This can probably be apart of the base route class
function CRoutePointToPoint:taskReturnToDepot()
  local depotBlip = Depot:getBlip()
  local depotBlipCoords = GetBlipCoords(depotBlip)

  SetBlipRoute(depotBlip, true)
  TriggerEvent('mrp:trucking:displayHelpText', 'TJ_RETURN_TO_DEPOT')

  while #(cache.coords - depotBlipCoords) >= 200 do
    Wait(1000)
  end

  SetBlipRoute(depotBlip, false)
end

function CRoutePointToPoint:taskReturnTruck()
  local truckReturnPoint = Depot:getTruckReturnCoordinate()
  local truckReturnBlip = AddBlipForCoord(truckReturnPoint.x, truckReturnPoint.y, truckReturnPoint.z)

  local truckReturnMarker = lib.marker.new({
    type = 30,
    coords = truckReturnPoint,
    width = 5,
    height = 5,
    faceCamera = false,
    bobUpAndDown = true,
    color = { r = 255, g = 0, b = 0, a = 200}
  })

  SetBlipRoute(truckReturnBlip, true)
  TriggerEvent('mrp:trucking:displayHelpText', 'TJ_RETURN_TRUCK')

  local truckIndex = self:getTruckIndex()
  local truckWidth = GetEntityWidth(truckIndex)
  local truckReturnAreaOrigin = truckReturnPoint + truckWidth
  local truckReturnAreaExtent = truckReturnPoint - truckWidth

  while true do
    Wait(0)
    local truckInArea = IsEntityInAngledArea(truckIndex,
      truckReturnAreaOrigin.x, truckReturnAreaOrigin.y, truckReturnAreaOrigin.z,
      truckReturnAreaExtent.x, truckReturnAreaExtent.y, truckReturnAreaExtent.z,
      truckWidth, false, false, 0)
    if not truckInArea then
      truckReturnMarker.color = { r = 255, g = 0, b = 0, a = 200 }
    end

    if truckInArea then
      truckReturnMarker.color = { r = 0, g = 255, b = 0, a = 200 }

      DisplayBusySpinner('TJ_HLP_VALIDATING_WITH_SERVER')

      local truckReturned, truckReturnError = lib.callback.await('mrp:trucking:truckReturned')

      if not truckReturned then
        TriggerEvent('mrp:trucking:displayHelpText', truckReturnError)
      else
        break
      end
    end

    truckReturnMarker:draw()
  end

  BusyspinnerOff()
  RemoveBlip(truckReturnBlip)
  TaskLeaveAnyVehicle(cache.ped, 0, 0)

  local managerBlip = GetFirstBlipInfoId(480)

  SetBlipFlashTimer(managerBlip, 5000)

  TriggerEvent('mrp:trucking:displayHelpText', 'TJ_RETURN_TO_MANAGER')
end

function CRoutePointToPoint:createRouteBlip()
  local trailerReturnLocation = self:getTrailerReturnLocation()

  local routeBlip = AddBlipForCoord(trailerReturnLocation.coordinates.x, trailerReturnLocation.coordinates.y, trailerReturnLocation.coordinates.z)

  SetBlipRoute(routeBlip, true)
  SetBlipName(routeBlip, 'Post OP Trailer Drop Point')

  self.private.m_routeBlip = routeBlip
end

function CRoutePointToPoint:performRouteTasks()
  self:taskCollectTruck()
  self:taskCollectTrailer()
  self:taskDeliverTrailer()
  self:taskReturnToDepot()
  self:taskReturnTruck()
end