---@class CRouteMultiPointVehicles
---@field private private { m_baseRoute: CBaseRoute }
CRouteMultiPointVehicles = lib.class('CRouteMultiPointVehicles')

---@param routeIndex number
---@param rawRoute table
function CRouteMultiPointVehicles:constructor(routeIndex, rawRoute)
  self.private.m_baseRoute = CBaseRoute:new(routeIndex, rawRoute)
end

function CRouteMultiPointVehicles:performRouteTasks()
  print('performing route tasks ')
end