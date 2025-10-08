local IS_SERVER <const> = IsDuplicityVersion()
local CONFIG_DEFAULTS <const> = {
  PED_MODEL = 's_m_m_ups_01',
  PED_COORDINATES = vector3(-494.58, -2910.04, 5.00),
  PED_HEADING = 225.24,

  DEPOT_BLIP_COORDINATES = vector3(-506.63, -2915.31, 40.1),

  TRUCK_MODELS = {
    "hauler",
    "packer",
    "phantom"
  },
  TRUCK_SPAWNS = {
    { coordinate = vector3(-512.41, -2858.46, 5.42), heading = 46.37 },
    { coordinate = vector3(-507.93, -2853.55, 5.42), heading = 47.76 },
    { coordinate = vector3(-503.66, -2849.16, 5.42), heading = 42.28 },
  },
  TRAILER_MODELS = {
    "trailerlarge",
    "docktrailer",
    "tr4",
    "tr2",
    "trflat",
    "trailers4",
    "trailers3",
    "trailers2",
    "trailers",
    "tvtrailer",
    "trailerlogs",
    "tanker2",
    "tanker"
  },
  TRAILER_SPAWNS = {
    { coordinate = vector3(326.93, 3422.85, 36.59), heading = 45.1 },
    { coordinate = vector3(324.74, 3420.49, 36.65), heading = 45.1 }
  },
  DELIVERY_ROUTES = {
    {
      routeType = 'POINT_TO_POINT',
      routeName = 'Default point to point',
      trailerPickUpLocation = {
        coordinates = {
          x = -483.49,
          y = -2824.99,
          z = 6
        },
        heading = 43.66
      },
      trailerReturnLocation = {
        coordinates = {
          x = -372.51,
          y = -2800.28,
          z = 6
        },
        heading = 136
      },
    },
  }
}

---@class CTruckingConfig
---@field private private { m_depotPedModel: number,  m_depotPedCoordinates: vector3, m_depotPedHeading: number, m_depotBlipCoordinates: vector3, m_deliveryRoutes: table, truckModels: table, trailerModels: table, truckSpawns: table, trailerSpawns: table, deliveryRoutes: table, _deliveryRoutes: table }
CTruckingConfig = lib.class('CTruckingConfig')

function CTruckingConfig:constructor()
  self.private.m_depotBlipCoordinates = vector3(0, 0, 0)

  self.private.truckModels = {}
  self.private.trailerModels = {}
  self.private.truckSpawns = {}
  self.private.trailerSpawns = {}
  self.private.m_deliveryRoutes = {}

  if not IS_SERVER then
    self:setDepotPedModel()
    self:setDepotPedCoordinates()
    self:setDepotPedHeading()
    self:setDepotBlipCoordinates()
  end

  if IS_SERVER then
    self:setTruckModels()
    self:setTrailerModels()
  end

  self:setTruckSpawnCoordinates()
  self:setDeliveryRoutes()
end

---Get the depot ped model
---@return number pedModelHash
function CTruckingConfig:getDepotPedModel()
  assert(not IS_SERVER, 'CTruckingConfig:getDepotPedMode is only available on the client')

  return self.private.m_depotPedModel
end

---Set the depot ped model
function CTruckingConfig:setDepotPedModel()
  assert(not IS_SERVER, 'CTruckingConfig:setDepotPedModel is only avaliable on the client')

  local pedModel = GetConvar('mrp:trucking:depotPedModel', CONFIG_DEFAULTS.PED_MODEL)

  if not IsModelInCdimage(pedModel) or not IsModelAPed(pedModel) then
    warn('CTruckingConfig:setDepotPedModel: %s is not a valid ped model. Falling back on default ped model "s_m_m_ups_01"')
    pedModel = CONFIG_DEFAULTS.PED_MODEL
  end

  self.private.m_depotPedModel = GetHashKey(pedModel)
end

---Set the coordinates for the depot ped
function CTruckingConfig:setDepotPedCoordinates()
  assert(not IS_SERVER, 'CTruckingConfig:setDepotPedCoordinates is only avaliable on the client')

  self.private.m_depotPedCoordinates = GetConvarVector('mrp:trucking:depotPedCoordinates', CONFIG_DEFAULTS.PED_COORDINATES)
end

---Get the depot ped coordinates 
---@return vector3 pedCoordinates
function CTruckingConfig:getDepotPedCoordinates()
  assert(not IS_SERVER, 'CTruckingConfig:getDepotPedCoordinates is only avaliable on the client')

  return self.private.m_depotPedCoordinates
end

function CTruckingConfig:setDepotPedHeading()
  assert(not IS_SERVER, 'CTruckingConfig:setDepotPedHeading is only avaliable on the client')

  local pedHeading = GetConvarFloat('mrp:trucking:depotPedHeading', CONFIG_DEFAULTS.PED_HEADING)

  self.private.m_depotPedHeading = pedHeading
end

---Get the heading for the depot ped
---@return number pedHeading
function CTruckingConfig:getDepotPedHeading()
  assert(not IS_SERVER, 'CTruckingConfig:getDepotPedHeading is only avaliable on the client')

  return self.private.m_depotPedHeading
end

---Set the depot blip coordinates
function CTruckingConfig:setDepotBlipCoordinates()
  assert(not IS_SERVER, 'CTruckingConfig:setDepotBlipCoordinates is only avaliable on the client')

  self.private.m_depotBlipCoordinates = GetConvarVector('mrp:trucking:depotBlipCoordinates', CONFIG_DEFAULTS.DEPOT_BLIP_COORDINATES)
end

---Get the depot blip coordinates
---@return vector3
function CTruckingConfig:getDepotBlipCoordinates()
  assert(not IS_SERVER, 'CTruckingConfig:getDepotBlipCoordinates is only avaliable on the client')

  return self.private.m_depotBlipCoordinates
end

---Get a random truck model from the loaded truck models.
---@return string truckModel The randomly selected truck model.
function CTruckingConfig:getRandomTruckModel()
  assert(IS_SERVER, 'CTruckingConfig:getRandomTruckModel is only available on the server')

  local truckModels = self.private.truckModels
  local truckModelIndex = math.random(#truckModels)

  return truckModels[truckModelIndex]
end

---Sets the truck models by loading them from the configuration using a Convar.
function CTruckingConfig:setTruckModels()
  assert(IS_SERVER, 'CTruckingConfig:setTruckModels is only available on the server')

  local truckModels = GetConvarArray('mrp:trucking:truckModels', CONFIG_DEFAULTS.TRAILER_MODELS)

  for truckModelIndex = 1, #truckModels do
    local model = truckModels[truckModelIndex]

    table.insert(self.private.truckModels, model)
  end
end

---Get a random trailer model hash
---@return string trailerModels
function CTruckingConfig:getRandomTrailerModel()
  assert(IS_SERVER, 'CTruckingConfig:getRandomTrailerModel is only available on the server')

  local trailerModels = self.private.trailerModels
  local trailerModelIndex = math.random(#trailerModels)

  return trailerModels[trailerModelIndex]
end

---Sets the trailer models by loading them from the configuration using a Convar.
function CTruckingConfig:setTrailerModels()
  assert(IS_SERVER, 'CTruckingConfig:setTrailerModels is only available on the server')

  local trailerModels = GetConvarArray('mrp:trucking:trailerModels', CONFIG_DEFAULTS.TRAILER_MODELS)

  for index = 1, #trailerModels do
    local model = trailerModels[index]

    table.insert(self.private.trailerModels, model)
  end
end

---Gets the truck spawn locations stored in the configuration.
---@return table # A table containing the truck spawn locations with position and heading.
function CTruckingConfig:getTruckSpawns()
  return self.private.truckSpawns
end

---Sets the truck spawn locations by loading them from the configuration using a Convar.
function CTruckingConfig:setTruckSpawnCoordinates()
  local truckSpawns = GetConvarVectorWithHeading('mrp:trucking:truckSpawnLocations', CONFIG_DEFAULTS.TRUCK_SPAWNS)

  for index = 1, #truckSpawns do
    local spawn = truckSpawns[index]
    local _coordinate = spawn.coordinate
    local _heading = spawn.heading

    table.insert(self.private.truckSpawns, {
      coordinates = _coordinate,
      heading = _heading
    })
  end
end

---Get raw delivery routes
---@return table
function CTruckingConfig:getDeliveryRoutes()
  return self.private.m_deliveryRoutes
end

---Set raw delivery routes
function CTruckingConfig:setDeliveryRoutes()
  local rawRoutes = GetConvar('mrp:trucking:deliveryRoutes', 'default')

  if rawRoutes == 'default' then
    warn('CTruckingConfig:setDeliveryRoutes mrp:trucking:deliveryRoutes is unset falling back to default routes.')
    self.private.m_deliveryRoutes = CONFIG_DEFAULTS.DELIVERY_ROUTES
    return
  end

  local routesDecoded = json.decode(rawRoutes)

  if not routesDecoded then
    warn('CTruckingConfig:setDeliveryRoutes could not decode mrp:trucking:deliveryRoutes falling back to default routes.')
    self.private.m_deliveryRoutes = CONFIG_DEFAULTS.DELIVERY_ROUTES
    return
  end

  self.private.m_deliveryRoutes = routesDecoded
end