local IS_SERVER <const> = IsDuplicityVersion()
local HALF_A_SECOND <const> = 500
local RADAR_TRUCK <const> = 477
local RADAR_TRAILER <const> = 479
local GREEN <const> = 2

---@class CBaseRoute
---@field private private { m_index: number, m_type: RouteTypes, m_name: string, m_state: RouteStates, m_driver: CDriver?, m_truckIndex: number, m_trailerIndex: number, m_networkTrailerIndex: number, m_trailerPickUpLocation: TrailerLocation, m_trailerReturnLocation: TrailerLocation }
CBaseRoute = lib.class('CBaseRoute')

---@param routeIndex number
---@param rawRoute table
function CBaseRoute:constructor(routeIndex, rawRoute)
  self.private.m_index = routeIndex

  if type(rawRoute?.routeName) ~= 'string' or rawRoute.routeName == '' then
    error('routeName is missing or empty')
  end

  self.private.m_name = rawRoute.routeName

  if type(rawRoute?.routeType) ~= 'string' or not RouteTypes[rawRoute.routeType] then
    error(('routeType %s is not a valid route type'):format(rawRoute?.routeType))
  end

  self.private.m_type = rawRoute.routeType
  self.private.m_state = RouteStates.unassigned
  self.private.m_truckIndex = 0
  self.private.m_trailerIndex = 0
  self.private.m_networkTrailerIndex = 0

  self:setTrailerPickUpLocation(rawRoute?.trailerPickUpLocation)
  self:setTrailerReturnLocation(rawRoute?.trailerReturnLocation)
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

---Get the coordinates and heading for the trailers pick up location
---@return TrailerLocation
function CBaseRoute:getTrailerPickUpLocation()
  return self.private.m_trailerPickUpLocation
end

---Sets the coordinates and heading for a trailers pick up location
---@param trailerPickUpLocation TrailerLocation
function CBaseRoute:setTrailerPickUpLocation(trailerPickUpLocation)
  if type(trailerPickUpLocation) ~= 'table' then
    error('trailerPickupLocation must be a table containing an entry for coordinates and heading')
  end

  if type(trailerPickUpLocation?.coordinates) ~= 'table' then
    error('trailerPickupLocation is missing the required coordinates entry')
  end

  if type(trailerPickUpLocation.coordinates?.x) ~= 'number' or type(trailerPickUpLocation.coordinates?.y) ~= 'number' or type(trailerPickUpLocation.coordinates?.z) ~= 'number' then
    error('trailerPickupLocation coordinates is missing one or more of the required x, y and z values')
  end

  if type(trailerPickUpLocation?.heading) ~= 'number' then
    error('trailerPickUpLocation is missing the required numeric heading entry')
  end

  local trailerPickUpCoordinates, errorMessage = table.vectorize(trailerPickUpLocation.coordinates)

  if not trailerPickUpCoordinates then
    error(('Failed to vectorize trailer trailerPickUpCoordinates coordinates: %s'):format(errorMessage))
  end

  self.private.m_trailerPickUpLocation = {
    coordinates = trailerPickUpCoordinates,
    heading = trailerPickUpLocation.heading
  }
end

---Get the coordinates and heading for the trailers return location
---@return TrailerLocation
function CBaseRoute:getTrailerReturnLocation()
  return self.private.m_trailerReturnLocation
end

---Sets the coordinates and heading for a trailers return location
---@param trailerReturnLocation TrailerLocation
function CBaseRoute:setTrailerReturnLocation(trailerReturnLocation)
  if type(trailerReturnLocation) ~= 'table' then
    error('trailerReturnLocation must be a table containing an entry for coordinates and heading')
  end

  if type(trailerReturnLocation?.coordinates) ~= 'table' then
    error('trailerReturnLocation is missing the required coordinates entry')
  end

  if type(trailerReturnLocation.coordinates?.x) ~= 'number' or type(trailerReturnLocation.coordinates?.y) ~= 'number' or type(trailerReturnLocation.coordinates?.z) ~= 'number' then
    error('trailerReturnLocation coordinates is missing one or more of the required x, y and z values')
  end

  if type(trailerReturnLocation?.heading) ~= 'number' then
    error('trailerReturnLocation is missing the required numeric heading entry')
  end

  local trailerReturnCoordinates, errorMessage = table.vectorize(trailerReturnLocation.coordinates)

  if not trailerReturnCoordinates then
    error(('Failed to vectorize trailer trailerReturnCoordinates coordinates: %s'):format(errorMessage))
  end

  self.private.m_trailerReturnLocation = {
    coordinates = trailerReturnCoordinates,
    heading = trailerReturnLocation.heading
  }
end


---Get the current driver assigned to this route
---@return CDriver?
function CBaseRoute:getDriver()
  assert(IS_SERVER, 'getDriver is not implemented on the client')

  return self.private.m_driver
end

---Set the driver assigned to this route
---@param driver CDriver?
function CBaseRoute:setDriver(driver)
  assert(IS_SERVER, 'setDriver is not implemented on the client')

  self.private.m_driver = driver
end

---Reset route to its orignal unassigned state
function CBaseRoute:reset()
  self:setTruckIndex(0)
  self:setTrailerIndex(0)
  self:setDriver(nil)
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
      local trailerPickUpLocation = self:getTrailerPickUpLocation()
      local trailerPickUpCoordinates = trailerPickUpLocation.coordinates
      local trailerBlip = AddBlipForCoord(trailerPickUpCoordinates.x, trailerPickUpCoordinates.y, trailerPickUpCoordinates.z)

      SetBlipSprite(trailerBlip, RADAR_TRAILER)
      SetBlipColour(trailerBlip, GREEN)
      SetBlipName(trailerBlip, 'Post OP Delivery Trailer')
      SetBlipRoute(trailerBlip, true)

      while not NetworkDoesNetworkIdExist(networkTrailerIndex) do
        Wait(HALF_A_SECOND)
      end

      RemoveBlip(trailerBlip)
    end

    local trailerIndex = NetworkGetEntityFromNetworkId(networkTrailerIndex)
    local trailerBlip = AddBlipForEntity(trailerIndex)

    SetBlipSprite(trailerBlip, RADAR_TRAILER)
    SetBlipColour(trailerBlip, GREEN)
    SetBlipName(trailerBlip, 'Post OP Delivery Trailer')
    SetBlipRoute(trailerBlip, true)

    self:setTrailerIndex(trailerIndex)
  end)
end