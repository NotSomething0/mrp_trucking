local INTERACTION_POINT <const> = lib.points.new({
  coords = Config:getDepotPedCoordinates(),
  distance = 200,
  tipAlreadyDisplayed = false
})

function INTERACTION_POINT:onEnter()
  local depotPedModel = Config:getDepotPedModel()
  local depotPedHeading = Config:getDepotPedHeading()
  local depotPedCoordinates = Config:getDepotPedCoordinates()

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
      TriggerEvent('deliveryController:displayHelpText', 'TJ_TIP_SPEAK_TO_MANAGER')
      SetBlipFlashTimer(self.managerBlip, 5000)
      self.tipAlreadyDisplayed = true
    end
  end
end

function INTERACTION_POINT:nearby()
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

function INTERACTION_POINT:onExit()
  if DoesEntityExist(self.managerPed) then
    DeleteEntity(self.managerPed)
  end

  self.managerBlip = 0
  self.managerPed = 0
end