---@class CDepot
---@field private private {  m_config: CTruckingConfig, m_blip: number, m_interactionPoint: CPoint }
CDepot = lib.class('CDepot')

---Create a new instance of CDepot
---@param config CTruckingConfig
function CDepot:constructor(config)
  self.private.m_config = config
  self.private.m_blip = self:createBlip()

  self:updateBlip()
  self:createInteractionPed()
end

---Get the config for the depot
---@return CTruckingConfig
function CDepot:getConfig()
  return self.private.m_config
end

---Get the blip for the depot
---@return number blip
function CDepot:getBlip()
  return self.private.m_blip
end

---Create a blip for the depot
---@return number blip
function CDepot:createBlip()
  local config = self:getConfig()
  local blipCoordinates = config:getDepotBlipCoordinates()
  local blip = AddBlipForCoord(blipCoordinates.x, blipCoordinates.y, blipCoordinates.z)

  SetBlipSprite(blip, 457)
  SetBlipDisplay(blip, 6)
  SetBlipColour(blip, 21)
  SetBlipAsShortRange(blip, true)
  SetBlipName(blip, 'Post OP Delivery')

  return blip
end

---Update the blip for the depot
function CDepot:updateBlip()
  local blip = self.private.m_blip

  exports['kBlipInfo']:UpdateBlipInfo(blip, {
    setTitle = "Post OP Delivery",
    setType = 1,
    setTexture = { dict = "kblipinfo", name = "pm_post_op" },
    setCashText = "$400",
    components = {
      { type = 'icon', title = 'Job Type',         value = 'Supply Chain & Logistics',                    iconIndex = 16, iconHudColor = 1, isTicked = false },
      { type = 'icon', title = 'Total Deliveries', value = GetResourceKvpInt('truckJob:totalDeliveries'), iconIndex = 0,  iconHudColor = 1, isTicked = false },
      {
        type = 'social',
        title = 'Author',
        value = 'NotSomething',
        isSocialClubName = false,
        crew = {
          tag = 'ALRP',
          isPrivate = true,
          isRockstar = true,
          lvl = 5,
          lvlColor = '#00FFBF'
        }
      },
      { type = 'divider' },
      { type = 'description', value = 'A fast-paced delivery job across a sprawling cityscape featuring congested streets, unpredictable traffic, and demanding drop-off locations.' },
    }
  })
end


---@return vector3 truckSpawn
function CDepot:getTruckReturnCoordinate()
  local config = self:getConfig()
  local truckSpawns = config:getTruckSpawns()
  local truckReturnCoordinates = vector3(0, 0, 0)

  for index = 1, #truckSpawns do
    local spawn = truckSpawns[index]
    local spawnFree = true
    local vehiclePool = GetGamePool('CVehicle')

    for poolIndex = 1, #vehiclePool do
      local vehicleIndex = vehiclePool[poolIndex]
      local vehicleCoords = GetEntityCoords(vehicleIndex)

      if #(spawn.coordinates - vehicleCoords) <= 4 then
        spawnFree = false
        break
      end
    end

    if spawnFree then
      truckReturnCoordinates = spawn.coordinates
      break
    end
  end

  return truckReturnCoordinates
end

function CDepot:createInteractionPed()
  local config = self.private.m_config

  self.private.m_interactionPoint = lib.points.new({
    coords = config:getDepotPedCoordinates(),
    distance = 200,
    tipAlreadyDisplayed = false
  })

  function self.private.m_interactionPoint:onEnter()
    local depotPedModel = config:getDepotPedModel()
    local depotPedHeading = config:getDepotPedHeading()
    local depotPedCoordinates = config:getDepotPedCoordinates()

    lib.requestModel(depotPedModel, 1000)

    self.managerPed = CreatePed(0, depotPedModel, depotPedCoordinates.x, depotPedCoordinates.y,
      depotPedCoordinates.z, depotPedHeading, false, false)

    if not DoesEntityExist(self.managerPed) then
      error('Failed to create Post OP Depot Manager')
    end

    SetModelAsNoLongerNeeded(depotPedModel)
    SetPedCanBeTargetted(self.managerPed, false)
    FreezeEntityPosition(self.managerPed, true)
    SetEntityInvincible(self.managerPed, true)
    SetBlockingOfNonTemporaryEvents(self.managerPed, true)

    exports.ox_target:addLocalEntity(self.managerPed, {
      label = 'Post OP Depot Manager',
      name = 'name',
      icon = 'fa-brands fa-usps',
      iconColor = 'white',
      distance = 10,
      onSelect = function()
        lib.showContext('TJ_DEPOT_MENU')
      end
    })

    if not DoesBlipExist(self.managerBlip) then
      local managerBlip = AddBlipForEntity(self.managerPed)

      SetBlipSprite(managerBlip, 480)
      SetBlipColour(managerBlip, 21)
      SetBlipAsShortRange(managerBlip, true)
      SetBlipName(managerBlip, 'Post OP Depot Manager')

      self.managerBlip = managerBlip

      if not self.tipAlreadyDisplayed then
        TriggerEvent('mrp:trucking:displayHelpText', 'TJ_TIP_SPEAK_TO_MANAGER')
        SetBlipFlashTimer(self.managerBlip, 5000)
        self.tipAlreadyDisplayed = true
      end
    end
  end

  function self.private.m_interactionPoint:nearby()
    if self.currentDistance > 5 then
      return
    end

    if IsScriptedSpeechPlaying(self.managerPed) then
      return
    end

    local pedHasGreetedDriver = Entity(self.managerPed).state.hasGreetedDriver or false

    if pedHasGreetedDriver then
      return
    end

    TaskLookAtEntity(self.managerPed, cache.ped, 1000, 2048, 3)
    PlayPedAmbientSpeechNative(self.managerPed, 'GENERIC_HI', 'SPEECH_PARAMS_STANDARD')
    Entity(self.managerPed).state.hasGreetedDriver = true
  end

  function self.private.m_interactionPoint:onExit()
    if DoesEntityExist(self.managerPed) then
      DeleteEntity(self.managerPed)
    end

    self.managerBlip = 0
    self.managerPed = 0
  end
end
