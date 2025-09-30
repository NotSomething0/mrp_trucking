local IS_SERVER <const> = IsDuplicityVersion()
local RADAR_TRUCK <const> = 477
local RADAR_TRAILER <const> = 479
local GREEN <const> = 2

---@class CBaseRoute
---@field private private { m_index: number, m_type: RouteTypes, m_name: string, m_state: RouteStates, m_driver: CDriver, m_truckIndex: number, m_trailerIndex: number, m_networkTrailerIndex: number, m_trailerPickUpCoordinate: vector3, m_trailerReturnLocation: vector3 }
CBaseRoute = lib.class('CBaseRoute')

---@param routeIndex number
---@param routeName string
---@param routeType RouteTypes
---@param trailerCoordinates table
function CBaseRoute:constructor(routeIndex, routeType, routeName, trailerCoordinates)
  self.private.m_index = routeIndex
  self.private.m_type = routeType
  self.private.m_name = routeName
  self.private.m_state = RouteStates.unassigned

  self.private.m_truckIndex = 0
  self.private.m_trailerIndex = 0
  self.private.m_networkTrailerIndex = 0
  self.private.m_trailerPickUpCoordinate = vector3(0, 0, 0)

  self:setTrailerCoordinates(trailerCoordinates)
end

---Get this routes index in the route manager
---@return number routeIndex
function CBaseRoute:getIndex()
  return self.private.m_index
end

---Get the type of this route
---@return number routeType
function CBaseRoute:getType()
  return self.private.m_type
end

---Get the name of this route
---@return string routeName
function CBaseRoute:getName()
  return self.private.m_name
end

---Get the current state of this route
---@return RouteStates routeState
function CBaseRoute:getState()
  return self.private.m_state
end

---Set the current state for this route
---@param routeState RouteStates
function CBaseRoute:setState(routeState)
  self.private.m_state = routeState
end

---Get the routes truck index
---@return number truckIndex
function CBaseRoute:getTruckIndex()
  return self.private.m_truckIndex
end

---Sets the routes truck index
---@param truckIndex number
function CBaseRoute:setTruckIndex(truckIndex)
  self.private.m_truckIndex = truckIndex
end

---Get the trailer index of this route
---@return number
function CBaseRoute:getTrailerIndex()
  return self.private.m_trailerIndex
end

---Set the trailer index of this route
---@param trailerIndex number
function CBaseRoute:setTrailerIndex(trailerIndex)
  self.private.m_trailerIndex = trailerIndex
end

---Get the networked trailer index of this route
---@return number
function CBaseRoute:getNetworkTrailerIndex()
  return self.private.m_networkTrailerIndex
end

---Set the networked trailer index of this route
---@param networkTrailerIndex number
function CBaseRoute:setNetworkTrailerIndex(networkTrailerIndex)
  self.private.m_networkTrailerIndex = networkTrailerIndex
end

---Get the current driver assigned to this route
---@return CDriver?
function CBaseRoute:getDriver()
  assert(IS_SERVER, 'getDriver is not implemented on the client')

  return self.private.m_driver
end

---Set the driver assigned to this route
---@param driver CDriver
function CBaseRoute:setDriver(driver)
  assert(IS_SERVER, 'setDriver is not implemented on the client')

  self.private.m_driver = driver
end

function CBaseRoute:getTrailerPickUpCoordinate()
  return self.private.m_trailerPickUpCoordinate
end

function CBaseRoute:setTrailerPickUpCoordinate(trailerPickUpCoordinate)
  self.private.m_trailerPickUpCoordinate = trailerPickUpCoordinate
end

function CBaseRoute:getTrailerReturnLocation()
  return self.private.m_trailerReturnLocation
end

function CBaseRoute:setTrailerCoordinates(trailerCoordinates)
  if type(trailerCoordinates) ~= 'table' then
    error(
    'The \'trailerCoordinates\' entry in the route configuration is missing or invalid. Expected a table containing trailer pickup and return locations, but received ' ..
    type(trailerCoordinates) .. '.')
  end

  if not trailerCoordinates?.trailerPickUpLocation then
    error(
    'The \'trailerCoordinates\' table in the route configuration is missing the required \'trailerPickUpLocation\' entry. This should be a table with x, y, z, and h coordinates.')
  end

  local trailerPickUpLocation, pickUpLocationError = table.vectorize(trailerCoordinates.trailerPickUpLocation)

  if not trailerPickUpLocation then
    error(
    'Failed to process the \'trailerPickUpLocation\' entry in the route configuration. Please ensure it is a valid table with numeric x, y, z, and h coordinates. Error: ' ..
    (pickUpLocationError or 'Unknown error'))
  end

  if not trailerCoordinates?.trailerReturnLocation then
    error(
    'The \'trailerCoordinates\' table in the route configuration is missing the required \'trailerReturnLocation\' entry. This should be a table with x, y, z, and h coordinates.')
  end

  local trailerReturnLocation, returnLocationError = table.vectorize(trailerCoordinates.trailerReturnLocation)

  if not trailerReturnLocation then
    error(
    'Failed to process the \'trailerReturnLocation\' entry in the route configuration. Please ensure it is a valid table with numeric x, y, z, and h coordinates. Error: ' ..
    (returnLocationError or 'Unknown error'))
  end

  self.private.m_trailerPickUpCoordinate = trailerPickUpLocation
  self.private.m_trailerReturnLocation = trailerReturnLocation
end

---Creates a blip for the routes delivery truck
function CBaseRoute:createTruckBlip()
  local truckIndex = self:getTruckIndex()
  local truckBlip = GetBlipFromEntity(truckIndex)

  if not DoesBlipExist(truckBlip) then
    truckBlip = AddBlipForEntity(truckIndex)

    SetBlipSprite(truckBlip, RADAR_TRUCK)
    SetBlipColour(truckBlip, GREEN)
    SetBlipName(truckBlip, 'Post OP Delivery Vehicle')
  end
end

function CBaseRoute:createTrailerBlip()
  CreateThread(function(_)
    local networkTrailerIndex = self:getNetworkTrailerIndex()

    -- If the trailer is spawned out of scope create a coordinate based marker until we get within scope of the trailer
    if not NetworkDoesNetworkIdExist(networkTrailerIndex) then
      local trailerPickUpCoordinate = self:getTrailerPickUpCoordinate()
      local trailerBlip = AddBlipForCoord(trailerPickUpCoordinate.x, trailerPickUpCoordinate.y, trailerPickUpCoordinate
      .z)

      SetBlipSprite(trailerBlip, RADAR_TRAILER)
      SetBlipColour(trailerBlip, GREEN)
      SetBlipName(trailerBlip, 'Post OP Delivery Trailer')
      SetBlipRoute(trailerBlip, true)

      while not NetworkDoesNetworkIdExist(networkTrailerIndex) do
        Wait(0)
      end

      RemoveBlip(trailerBlip)
    end

    local trailerIndex = NetworkGetEntityFromNetworkId(networkTrailerIndex)

    if not DoesEntityExist(trailerIndex) then
      error('this should never happen')
    end

    self:setTrailerIndex(trailerIndex)

    local trailerBlip = AddBlipForEntity(trailerIndex)

    SetBlipSprite(trailerBlip, RADAR_TRAILER)
    SetBlipColour(trailerBlip, GREEN)
    SetBlipName(trailerBlip, 'Post OP Delivery Trailer')
  end)
end
