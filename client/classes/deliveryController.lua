local CLOCK_IN_OPTION <const> = 1
local CONTINUE_SHIFT_OPTION <const> = 2
local CLOCK_OUT_OPTION <const> = 3

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
      title = 'Continue Shift',
      description = 'Resume your current shift!',
      icon = 'fa-solid fa-truck',
      disabled = true,
      event = 'deliveryController:continueShift'
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

---@class CDeliveryController
---@field private private { m_config: CTruckingConfig, m_clockedIn: boolean, m_route: CDeliveryRoute?, m_trailerCollectCoordinate: vector3, m_trailerDropCoordinate: vector3 }
CDeliveryController = lib.class('CDeliveryController')

---Create a new instance of CDeliveryController
---@param config CTruckingConfig
function CDeliveryController:constructor(config)
  self.private.m_config = config
  self.private.m_clockedIn = false
  self.private.m_route = nil

  lib.registerContext(TJ_DEPOT_MENU_OPTIONS)

  ---@todo: move these into cl_main
  AddEventHandler('deliveryController:clockIn', function()
    self:setClockedIn(true)
  end)

  RegisterNetEvent('deliveryController:clockOut', function()
    self:setClockedIn(false)
  end)

  RegisterNetEvent('mrp:trucking:displayHelpText', function(inputType, components)
    DisplayHelpText(inputType, components)
  end)
end

---Gets the current assigned route or nil if no route is assigned
---@return CDeliveryRoute?
function CDeliveryController:getRoute()
  return self.private.m_route
end

---Set the current assigned delivery route
---@param route CDeliveryRoute?
function CDeliveryController:setRoute(route)
  if route then
    DisplayBusySpinner('TJ_WAITING_FOR_ROUTE_INIT')
  end

  self.private.m_route = route
end

---Get is the driver clocked in
---@return boolean clockedIn
function CDeliveryController:getClockedIn()
  return self.private.m_clockedIn
end

---Set the state of m_clockedIn
---@param clockedIn boolean
function CDeliveryController:setClockedIn(clockedIn)
  if clockedIn then
    local canClockIn, clockInError = lib.callback.await('mrp:trucking:clockIn', false)

    if not canClockIn then
      DisplayHelpText(clockInError)
      return
    end

    TJ_DEPOT_MENU_OPTIONS.options[CLOCK_IN_OPTION].disabled = true
    TJ_DEPOT_MENU_OPTIONS.options[CONTINUE_SHIFT_OPTION].disabled = true
    TJ_DEPOT_MENU_OPTIONS.options[CLOCK_OUT_OPTION].disabled = false

    DisplayBusySpinner('TJ_WAITING_FOR_ROUTE_ASSIGNMENT')
    self.private.m_clockedIn = true
  else
    local canClockOut, clockOutError = lib.callback.await('mrp:trucking:clockOut', false)

    if not canClockOut then
      DisplayHelpText(clockOutError)
      return
    end

    TJ_DEPOT_MENU_OPTIONS.options[CLOCK_IN_OPTION].disabled = false
    TJ_DEPOT_MENU_OPTIONS.options[CONTINUE_SHIFT_OPTION].disabled = true
    TJ_DEPOT_MENU_OPTIONS.options[CLOCK_OUT_OPTION].disabled = true

    self.private.m_clockedIn = false
  end

  lib.registerContext(TJ_DEPOT_MENU_OPTIONS)
end
