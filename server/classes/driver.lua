---@class CDriver
---@field private private { m_playerIndex: number, m_status: DriverStatus, m_truckIndex: number, m_trailerIndex: number, m_route: CDeliveryRoute? , m_completedDeliveries: number }
CDriver = lib.class('CDriver')

function CDriver:constructor(playerIndex)
  self.private.m_playerIndex = playerIndex
  self.private.m_status = DriverStatus.WAITING_FOR_DELIVERY
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
---@return DriverStatus driverStatus
function CDriver:getStatus()
  return self.private.m_status
end

---Get the drivers current delivery route
---@return CDeliveryRoute route
function CDriver:getDeliveryRoute()
  return self.private.m_route
end

---Set the drivers status
---@param status DriverStatus
function CDriver:setStatus(status)
  self.private.m_status = status
end

---Set the driver current delivery route
---@param route CDeliveryRoute?
function CDriver:setDeliveryRoute(route)
  self.private.m_route = route
end

---Set the drivers delivery route
---@param route CDeliveryRoute
function CDriver:routeAssigned(route)
  self:setDeliveryRoute(route)
  self:setStatus(DriverStatus.WAITING_FOR_ROUTE_INIT)

  TriggerClientEvent('mrp:trucking:routeAssigned', self:getPlayerIndex(), route:getIndex())
end

---Complete the currently assigned delivery route
function CDriver:completeRoute()
  self:setDeliveryRoute(nil)
  self:setStatus(DriverStatus.SPEAKING_WITH_MANAGER)

  self.private.m_completedDeliveries += 1

  TriggerClientEvent('mrp:trucking:routeAssigned', self:getPlayerIndex(), RouteTypes.INVALID)
end

---Gets the driver vehicle index
---@return number
function CDriver:getTruckIndex()
  return self.private.m_truckIndex
end

---Set the driver vehicle index
---@param truckIndex number
function CDriver:setTruckIndex(truckIndex)
  if not DoesEntityExist(truckIndex) then
    warn(('Unable to set truck index for driver %s as the truck does not exist.'):format(self:getPlayerIndex()))
    return
  end

  self.private.m_truckIndex = truckIndex
end

---Get the driver trailer index
---@return number
function CDriver:getTrailerIndex()
  return self.private.m_trailerIndex
end

---Set the driver trailer index
function CDriver:setTrailerIndex(trailerIndex)
  if not DoesEntityExist(trailerIndex) then
    warn(('Unable to set trailer index for driver %s as the trailer does not exist.'):format(self:getPlayerIndex()))
    return
  end

  self.private.m_trailerIndex = trailerIndex
end

---Get the drivers total completed deliveries
---@return number completedDeliveries
function CDriver:getCompletedDeliveries()
  return self.private.m_completedDeliveries
end