---@class CDriver
---@field private private { m_playerIndex: number, m_state: DriverStates, m_truckIndex: number, m_trailerIndex: number, m_route: CDeliveryRoute, m_completedDeliveries: number }
CDriver = lib.class('CDriver')

function CDriver:constructor(playerIndex)
  self.private.m_playerIndex = playerIndex
  self.private.m_state = DriverStates.WAITING_FOR_DELIVERY
  self.private.m_truckIndex = 0
  self.private.m_trailerIndex = 0
  self.private.m_route = nil
  self.private.m_completedDeliveries = 0
end

---Gets the drivers player index or netID
---@return number playerIndex
function CDriver:getPlayerIndex()
  return self.private.m_playerIndex
end

---Get the drivers status
---@return DriverStates driverStatus
function CDriver:getState()
  return self.private.m_state
end

---Set the drivers status
---@param state DriverStates
function CDriver:setState(state)
  self.private.m_state = state
end

---Get the drivers current delivery index
---@return CDeliveryRoute route
function CDriver:getDeliveryRoute()
  return self.private.m_route
end

---comment
---@param route CDeliveryRoute
function CDriver:setDeliveryRoute(route)
  self.private.m_route = route
end

function CDriver:routeAssigned(route)
  self:setDeliveryRoute(route)
  self:setState(DriverStates.WAITING_FOR_ROUTE_INIT)

  TriggerClientEvent('truckJob:deliveryController:routeAssigned', self:getPlayerIndex(), route:getIndex())
end

function CDriver:completeRoute()
  self:setDeliveryRoute(nil)
  self:setState(DriverStates.SPEAKING_WITH_MANAGER)

  self.private.m_completedDeliveries += 1

  TriggerClientEvent('truckJob:deliveryController:routeAssigned', self:getPlayerIndex(), nil)
end

---Gets the drivers delviery vehicle index
---@return number
function CDriver:getTruckIndex()
  return self.private.m_truckIndex
end

---Sets the drivers delviery vehicle index
function CDriver:setTruckIndex(vehicleIndex)
  if not DoesEntityExist(vehicleIndex) then
    warn('Unable to set delivery vehicle for driver %s as the vehicle does not exist.')
    return
  end

  self.private.m_truckIndex = vehicleIndex
end

---Gets the drivers delviery trailer index
---@return number
function CDriver:getTrailerIndex()
  return self.private.m_trailerIndex
end

---Sets the drivers delviery trailer index
function CDriver:setTrailerIndex(trailerIndex)
  if not DoesEntityExist(trailerIndex) then
    warn('Unable to set delivery vehicle for driver %s as the vehicle does not exist.')
    return
  end

  self.private.m_trailerIndex = trailerIndex
end

---comment
function CDriver:deleteTruck()
  local truckIndex = self:getTruckIndex()

  if DoesEntityExist(truckIndex) then
    DeleteEntity(truckIndex)
  end

  self:setTruckIndex(0)
end

---comment
function CDriver:deleteTrailer()
  local trailerIndex = self:getTrailerIndex()

  if DoesEntityExist(trailerIndex) then
    DeleteEntity(trailerIndex)
  end

  self:setTrailerIndex(0)
end

function CDriver:getCompletedDeliveries()
  return self.private.m_completedDeliveries
end