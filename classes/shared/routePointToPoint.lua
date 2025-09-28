---@class CRoutePointToPoint
---@field private private { m_baseRoute: CBaseRoute, m_routeBlip: number }
CRoutePointToPoint = lib.class('CRoutePointToPoint')

---@param baseRoute CBaseRoute
function CRoutePointToPoint:constructor(baseRoute)
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

---Set the current state for this route
---@param routeState RouteStates
function CRoutePointToPoint:setState(routeState)
  self.private.m_baseRoute:setState(routeState)
end

---Get the current state of this route
---@see CBaseRoute.getState
---@return RouteStates routeState
function CRoutePointToPoint:getState()
  return self.private.m_baseRoute:getState()
end

---@see CBaseRoute.getDriver
function CRoutePointToPoint:getDriver()
  return self.private.m_baseRoute:getDriver()
end

---Set the driver assigned to this route
---@param driver CDriver 
function CRoutePointToPoint:setDriver(driver)
  self.private.m_baseRoute:setDriver(driver)
end

function CRoutePointToPoint:getTruckIndex()
  return self.private.m_baseRoute:getTruckIndex()
end

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

function CRoutePointToPoint:setNetworkTrailerIndex(networkTrailerIndex)
  self.private.m_baseRoute:setNetworkTrailerIndex(networkTrailerIndex)
end

function CRoutePointToPoint:getTrailerPickUpCoordinate()
  return self.private.m_baseRoute:getTrailerPickUpCoordinate()
end

function CRoutePointToPoint:getTrailerReturnLocation()
  return self.private.m_baseRoute:getTrailerReturnLocation()
end

function CRoutePointToPoint:taskCollectTruck()
  self.private.m_baseRoute:createTruckBlip()

  local truckIndex = self:getTruckIndex()

  while true do
    Wait(0)

    DisplayHelpTextThisFrame('TJ_COLLECT_TRUCK', false)

    local playerVehicle = GetVehiclePedIsIn(cache.ped, false)

    if playerVehicle == truckIndex then
      local truckCollected, truckCollectError = lib.callback.await('alrp:truckJob:truckCollected')

      if truckCollected then
        break
      end

      if not truckCollected then
        ClearHelp(true)
        TriggerEvent('truckJob:deliveryController:displayHelpText', truckCollectError)
        Wait(4000)
      end
    end
  end
end

function CRoutePointToPoint:taskCollectTrailer()
  self.private.m_baseRoute:createTrailerBlip()

  TriggerEvent('truckJob:deliveryController:displayHelpText', 'TJ_COLLECT_TRAILER')

  while not DoesEntityExist(self:getTrailerIndex()) do
    Wait(1000)
  end

  local driverTruck = self:getTruckIndex()
  local driverTrailer = self:getTrailerIndex()

  while true do
    Wait(500)

    local hasTrailer, truckTrailer = GetVehicleTrailerVehicle(driverTruck)

    if hasTrailer then
      if truckTrailer == driverTrailer then
        break
      end

      DetachVehicleFromTrailer(driverTruck)
      TriggerEvent('truckJob:deliveryController:displayHelpText', 'TJ_INCORRECT_TRAILER')
    end
  end

  TriggerServerEvent('alrp:truckJob:trailerCollected')
end

function CRoutePointToPoint:taskDeliverTrailer()
  self:createRouteBlip()

  TriggerEvent('truckJob:deliveryController:displayHelpText', 'TJ_DELIVER_TRAILER')

  local truckIndex = self:getTruckIndex()
  local trailerIndex = self:getTrailerIndex()
  local trailerReturnLocation = self:getTrailerReturnLocation()

  local trailerWidth = GetEntityWidth(trailerIndex)
  local trailerDropAreaOrigin = trailerReturnLocation + trailerWidth
  local trailerDropAreaExtent = trailerReturnLocation - trailerWidth

  local trailerDropMarker = lib.marker.new({
    type = 30,
    coords = trailerReturnLocation,
    width = 5,
    height = 5,
    faceCamera = false,
    bobUpAndDown = true
  })

  while true do
    Wait(0)

    local playerCoordinate = cache.coords
    local playerWithinDrawDistance = #(playerCoordinate - trailerReturnLocation) <= 50

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
          local trailerDelivered, trailerDeliveryError = lib.callback.await('truckJob:trailerDelivered')

          if not trailerDelivered then
            ClearHelp(true)
            FreezeEntityPosition(truckIndex, true)
            TriggerEvent('truckJob:deliveryController:displayHelpText', trailerDeliveryError)

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
            ---@diagnostic disable-next-line: undefined-field
            SetEntityHeading(trailerIndex, trailerReturnLocation.heading)
            ---@diagnostic disable-next-line: undefined-field
            SetEntityCoords(trailerIndex, trailerReturnLocation.x, trailerReturnLocation.y,
              trailerReturnLocation.z, false, false, false, false)

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
  TriggerEvent('truckJob:deliveryController:displayHelpText', 'TJ_RETURN_TO_DEPOT')

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
    bobUpAndDown = true
  })

  print('truckReturnMarker', truckReturnMarker)
  print('truckReturnMarker:draw', truckReturnMarker.draw)

  SetBlipRoute(truckReturnBlip, true)
  TriggerEvent('truckJob:deliveryController:displayHelpText', 'TJ_RETURN_TRUCK')

  local truckIndex = self:getTruckIndex()
  local truckWidth = GetEntityWidth(truckIndex)
  local truckReturnAreaOrigin = truckReturnPoint + truckWidth
  local truckReturnAreaExtent = truckReturnPoint - truckWidth

  local truckInArea = false

  while true do
    Wait(0)

    -- For whatever reason this doesn't work but the trailer return marker does
    -- Leaving this here in case it magically starts working
    truckReturnMarker:draw()

    truckInArea = IsEntityInAngledArea(truckIndex,
      truckReturnAreaOrigin.x, truckReturnAreaOrigin.y, truckReturnAreaOrigin.z,
      truckReturnAreaExtent.x, truckReturnAreaExtent.y, truckReturnAreaExtent.z,
      truckWidth, false, false, 0)

    if not truckInArea then
      truckReturnMarker.color = { 255, 0, 0 }
    end

    if truckInArea then
      truckReturnMarker.color = { 0, 255, 0 }
      break
    end
  end

  RemoveBlip(truckReturnBlip)
  TaskLeaveAnyVehicle(cache.ped, 0, 0)

  local managerBlip = GetFirstBlipInfoId(480)

  SetBlipFlashTimer(managerBlip, 5000)

  local res = lib.callback.await('truckJob:truckReturned')

  print('Got ' .. res .. ' from truckJob:truckReturned')


  TriggerEvent('truckJob:deliveryController:displayHelpText', 'TJ_RETURN_TO_MANAGER')
end

function CRoutePointToPoint:createRouteBlip()
  local trailerReturnLocation = self.private.m_baseRoute:getTrailerReturnLocation()

  local routeBlip = AddBlipForCoord(trailerReturnLocation.x, trailerReturnLocation.y, trailerReturnLocation.z)

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