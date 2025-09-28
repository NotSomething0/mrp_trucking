local TJ_DEPOT_MENU_OPTIONS = {
  id = 'TJ_DEPOT_MENU',
  title = 'Post OP Depot Menu',
  options = {
    {
      title = 'Start Shift',
      description = 'Start your shift!',
      icon = 'fa-solid fa-business-time',
      disabled = false,
      event = 'deliveryController:clockIn'
    },
    {
      title = 'End Shift',
      description = 'End your shift!',
      icon = 'fa-solid fa-business-time',
      disabled = true,
      event = 'deliveryController:clockOut'
    }
  }
}

---@class CPoint
---@field coords vector3
---@field distance number
---@field onEnter function
---@field onExit function
---@field nearby function

---@class CDeliveryController
---@field private private { m_config: CConfigStore, m_watchDogAlerted: boolean, m_watchDogAlertReason: string, m_clockedIn: boolean, m_depotBlip: number, m_trailerCollectCoordinate: vector3, m_trailerDropCoordinate: vector3, m_route: CDeliveryRoute }
CDeliveryController = lib.class('CDeliveryController')

---@param config CConfigStore
function CDeliveryController:constructor(config)
  self.private.m_config = config
  self.private.m_clockedIn = false
  self.private.m_route = nil


  self.private.m_watchDogAlerted = false
  self.private.m_watchDogAlertReason = ''


  self.private.m_trailerCollectCoordinate = vector3(0, 0, 0)
  self.private.m_trailerDropCoordinate = vector3(0, 0, 0)

  lib.registerContext(TJ_DEPOT_MENU_OPTIONS)

  ---@todo: move these into cl_main
  AddEventHandler('deliveryController:clockIn', function()
    self:clockIn()
  end)

  RegisterNetEvent('deliveryController:clockOut', function()
    self:clockOut()
  end)

  RegisterNetEvent('truckJob:deliveryController:displayHelpText', function(inputType, components)
    self:displayHelpText(inputType, components)
  end)
end

---Uses the built in game notification system to display help text
---@param inputType string
---@param components table?
function CDeliveryController:displayHelpText(inputType, components)
  if IsHelpMessageBeingDisplayed() then
    ClearHelp(true)
  end

  BeginTextCommandDisplayHelp(inputType)

  if type(components) == 'table' and next(components) then
    for componentIndex = 1, #components do
      local component = components[componentIndex]
      local componentType = type(component)

      if componentType == 'string' then
        AddTextComponentSubstringTextLabel(component)
      elseif componentType == 'number' then
        AddTextComponentInteger(component)
      else
        warn(('Could not display help text a invalid component type (%s) specified for help message %s at index %d.')
          :format(componentType, inputType, componentIndex))
        return
      end
    end
  end

  EndTextCommandDisplayHelp(0, false, true, -1)
end

function CDeliveryController:displayBusySpinner(labelName)
  BeginTextCommandBusyspinnerOn('STRING')
  AddTextComponentSubstringTextLabel(labelName)
  EndTextCommandBusyspinnerOn(4)
end

---Get the width of the passed entitys model
---@param entity number
---@return number entityWidth
function CDeliveryController:getEntityWidth(entity)
  local entityModel = GetEntityModel(entity)
  local modelMin, modelMax = GetModelDimensions(entityModel)

  return modelMax.x - modelMin.x
end

---Gets the current assigned route or nil if no route is assigned
---@return CDeliveryRoute
function CDeliveryController:getRoute()
  return self.private.m_route
end

---Set the current assigned delivery route
---@param route CDeliveryRoute
function CDeliveryController:setRoute(route)
  if not route then return end

  self.private.m_route = route
  self:displayBusySpinner('TJ_WAITING_FOR_ROUTE_INIT')
end

---comment
---@return CConfigStore
function CDeliveryController:getConfig()
  return self.private.m_config
end

---comment
function CDeliveryController:getWatchDogAlerted()
  return self.private.m_watchDogAlerted
end

---comment
---@param alerted any
function CDeliveryController:setWatchDogAlerted(alerted)
  self.private.m_watchDogAlerted = alerted
end

---Looks for a free truck spawn at the depot and returns it's coordinate or vector3(0, 0, 0) if no free spawn was found
---@return vector3 truckReturnCoordinate
function CDeliveryController:getTruckReturnCoordinate()
  local truckSpawns = self.private.m_config:getTruckSpawns()
  local truckReturnCoordinate = vector3(0, 0, 0)

  for index = 1, #truckSpawns do
    local spawn = truckSpawns[index]
    local spawnFree = true

    for _, vehicleIndex in pairs(GetGamePool('CVehicle')) do
      local vehicleCoords = GetEntityCoords(vehicleIndex)

      if #(spawn.coordinate - vehicleCoords) <= 4 then
        spawnFree = false
        break
      end
    end

    if spawnFree then
      truckReturnCoordinate = spawn.coordinate
      break
    end
  end

  return truckReturnCoordinate
end

---comment
---@return boolean clockedIn
function CDeliveryController:getClockedIn()
  return self.private.m_clockedIn
end

---Set the state of m_clockedIn
---@param clockedIn boolean
function CDeliveryController:setClockedIn(clockedIn)
  self.private.m_clockedIn = clockedIn

  if clockedIn then
    -- Disable clock in option
    TJ_DEPOT_MENU_OPTIONS.options[1].disabled = true
    -- Enable clock out option
    TJ_DEPOT_MENU_OPTIONS.options[2].disabled = false
  else
    -- Enable clock in option
    TJ_DEPOT_MENU_OPTIONS.options[1].disabled = false
    -- Disable clock out option
    TJ_DEPOT_MENU_OPTIONS.options[2].disabled = true
  end

  lib.registerContext(TJ_DEPOT_MENU_OPTIONS)
end

---Request the server to clock us in and set our delivery status as awaiting delivery
function CDeliveryController:clockIn()
  local canClockIn, clockInError = lib.callback.await('alrp:truckJob:clockIn', false)

  if not canClockIn then
    self:displayHelpText(clockInError)
    return
  end

  self:setClockedIn(true)
  self:displayBusySpinner('TJ_WAITING_FOR_ROUTE_ASSIGNMENT')
end

---comments
function CDeliveryController:clockOut()
  local canClockOut, clockOutError = lib.callback.await('alrp:truckJob:clockOut', false)

  if not canClockOut then
    self:displayHelpText(clockOutError)
    return
  end

  self:setClockedIn(false)
end

function CDeliveryController:destroyTrailerBlip()
  local trailerIndex = self:getTrailerIndex()
  local trailerBlip = GetBlipFromEntity(trailerIndex)

  if not DoesBlipExist(trailerBlip) then return end

  RemoveBlip(trailerBlip)
end

function CDeliveryController:createTrailerDropBlip()
  local trailerDropCoordinate = self:getTrailerDropCoordinate()
  local trailerDropBlip = AddBlipForCoord(trailerDropCoordinate.coordinate.x, trailerDropCoordinate.coordinate.y,
    trailerDropCoordinate.coordinate.z)

  SetBlipRoute(trailerDropBlip, true)
  SetBlipName(trailerDropBlip, 'Post OP Trailer Drop Point')

  return trailerDropBlip
end

function CDeliveryController:createTrailerDropMarker()
  local trailerDropPoint = self:getTrailerDropCoordinate()

  local trailerDropMarker = lib.marker.new({
    type = 0,
    coords = trailerDropPoint.coordinate,
    width = 5,
    height = 5,
    faceCamera = false,
    bobUpAndDown = true
  })

  return trailerDropMarker
end

function CDeliveryController:taskCollectTrailer()
  self:createDeliveryTrailerBlip()
  self:displayHelpText('TJ_COLLECT_TRAILER')

  while self:getClockedIn() do
    Wait(0)

    if #(cache.coords - self.private.m_trailerCollectCoordinate) <= 10 then
      local driverTruck = self:getTruckIndex()

      if IsVehicleAttachedToTrailer(driverTruck) then
        TriggerServerEvent('truckJob:trailerCollected')
        break
      end
    end
  end
end

function CDeliveryController:taskDeliverTrailer()
  local truckIndex = self:getTruckIndex()
  local trailerIndex = self:getTrailerIndex()
  local trailerDropPoint = self:getTrailerDropCoordinate()
  local trailerWidth = self:getEntityWidth(trailerIndex)

  -- Angled area
  local trailerDropAreaOrigin = trailerDropPoint.coordinate + trailerWidth
  local trailerDropAreaExtent = trailerDropPoint.coordinate - trailerWidth

  local trailerDropBlip = self:createTrailerDropBlip()
  local trailerDropMarker = self:createTrailerDropMarker()

  self:displayHelpText('TJ_DELIVER_TRAILER')

  while self:getClockedIn() do
    Wait(0)

    local playerCoordinate         = cache.coords
    local playerWithinDrawDistance = #(playerCoordinate - trailerDropPoint.coordinate) <= 25

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
            self:displayHelpText(trailerDeliveryError)
            FreezeEntityPosition(truckIndex, true)

            Wait(4000) -- Arbitrary wait so the player has time to read the message

            FreezeEntityPosition(truckIndex, false)
            SetTrailerAttachmentEnabled(trailerIndex, true)
            AttachVehicleToTrailer(truckIndex, trailerIndex, 1.0)
          end

          if trailerDelivered then
            SetEntityAsMissionEntity(trailerIndex, false, false)
            SetTrailerAttachmentEnabled(trailerIndex, false)
            ---@diagnostic disable-next-line: redundant-parameter
            SetTrailerLegsLowered(trailerIndex)
            DetachVehicleFromTrailer(truckIndex)
            ---@diagnostic disable-next-line: undefined-field
            SetEntityHeading(trailerIndex, trailerDropPoint.heading)
            ---@diagnostic disable-next-line: undefined-field
            SetEntityCoords(trailerIndex, trailerDropPoint.coordinate.x, trailerDropPoint.coordinate.y,
              trailerDropPoint.coordinate.z, false, false, false, false)
            RemoveBlip(trailerDropBlip)
            break
          end
        end
      end
    end
  end

  self:destroyTrailerBlip()
end

function CDeliveryController:taskReturnTruck()
  local truckReturnPoint = self:getTruckReturnCoordinate()
  local truckReturnBlip = AddBlipForCoord(truckReturnPoint.x, truckReturnPoint.y, truckReturnPoint.z)

  print(truckReturnPoint)

  local truckReturnMarker = lib.marker.new({
    type = 1,
    coords = truckReturnPoint,
    color = { 255, 0, 0 },
    width = 2,
    height = 4,
    faceCamera = false
  })

  print(truckReturnMarker)

  SetBlipRoute(truckReturnBlip, true)
  self:displayHelpText('TJ_RETURN_TRUCK')

  local truckIndex = self:getTruckIndex()
  local truckWidth = self:getEntityWidth(truckIndex)
  local truckReturnAreaOrigin = truckReturnPoint + truckWidth
  local truckReturnAreaExtent = truckReturnPoint - truckWidth

  local truckInArea = false

  while not truckInArea do
    Wait(0)

    truckInArea = IsEntityInAngledArea(truckIndex,
      truckReturnAreaOrigin.x, truckReturnAreaOrigin.y, truckReturnAreaOrigin.z,
      truckReturnAreaExtent.x, truckReturnAreaExtent.y, truckReturnAreaExtent.z,
      truckWidth, false, false, 0)

    if not truckInArea then
      truckReturnMarker.color = { 255, 0, 0 }
    end

    if truckInArea then
      truckReturnMarker.color = { 0, 255, 0 }
    end

    truckReturnMarker:draw()
  end

  RemoveBlip(truckReturnBlip)
  TaskLeaveAnyVehicle(cache.ped, 0, 0)

  local managerBlip = GetFirstBlipInfoId(480)

  SetBlipFlashTimer(managerBlip, 5000)

  TriggerServerEvent('truckJob:truckReturned')

  self:displayHelpText('TJ_RETURN_TO_MANAGER')
end

function CDeliveryController:createWatchDog()
  CreateThread(function()
    while self:getClockedIn() do
      Wait(0)

      local truckIndex = self:getTruckIndex()
      local trailerIndex = self:getTrailerIndex()

      if not DoesEntityExist(truckIndex) or not IsVehicleDriveable(truckIndex, true) then
        TriggerServerEvent('truckJob:deliveryManager:forceQuit', 'TRUCK_DESTROYED')
        self:setWatchDogAlerted(true)
        return
      end

      if DoesEntityExist(trailerIndex) then
        if GetEntityHealth(trailerIndex) <= 100.0 then
          self:setWatchDogAlerted(true)
          TriggerServerEvent('truckJob:deliveryManager:forceQuit', 'TRAILER_DESTROYED')
          return
        end
      end

      if IsControlPressed(1, 73) then
        TriggerServerEvent('truckJob:deliveryManager:forceQuit')
        return
      end
    end
  end)
end

function CDeliveryController:startJob()
  self:createWatchDog()

  self:taskCollectTrailer()
  self:taskDeliverTrailer()
  self:taskReturnToDepot()
  self:taskReturnTruck()
end