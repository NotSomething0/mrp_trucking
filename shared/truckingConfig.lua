local IS_SERVER <const> = IsDuplicityVersion()
local CONFIG_DEFAULTS <const> = {
  PED_MODEL = `s_m_m_ups_01`,
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
  DELIVERY_DROP_POINTS = {
    --{ coordinate = vector3(-3169.63, 1102.37, 20.74), heading = },
    --{ coordinate = vector3(31.54, 6287.21, 31.24), heading = } ,
    --{ coordinate = vector3(-360.2, 6073.27, 31.5), heading = } ,
    --{ coordinate = vector3(3640.62, 3766.41, 28.52), heading = }
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

  self:setDepotPedModel()
  self:setDepotPedCoordinates()
  self:setDepotPedHeading()

  self:setDepotPedCoordinates()
  self:setDepotBlipCoordinates()
  self:setDepotPedHeading()
  self:setTrailerSpawnLocations()
  self:setTruckSpawnLocations()
  self:setTruckModels()
  self:setTrailerModels()
  self:setPayoutRates()
  self:_setDeliveryRoutes()
end

---@return number pedModelHash
function CTruckingConfig:getDepotPedModel()
  ---@diagnostic disable-next-line: missing-return-value
  if IS_SERVER then return end

  return self.private.m_depotPedModel
end

---comment
function CTruckingConfig:setDepotPedModel()
  if IS_SERVER then return end

  local pedModel = GetConvar('truckJob:depotPedModel', CONFIG_DEFAULTS.PED_MODEL)

  if not IsModelInCdimage(pedModel) or not IsModelAPed(pedModel) then
    warn('CTruckingConfig:setDepotPedModel: %s is not a valid ped model. Falling back on default ped model "s_m_m_ups_01"')
    pedModel = CONFIG_DEFAULTS.PED_MODEL
  end

  self.private.m_depotPedModel = GetHashKey(pedModel)
end

function CTruckingConfig:setDepotPedCoordinates()
  local pedLocation = GetConvarVector('truckJob:depotPedLocation', CONFIG_DEFAULTS.PED_COORDINATES)

  if type(pedLocation) ~= 'vector3' then
    error('Failed to set depot ped coordinates')
  end

  self.private.m_depotPedCoordinates = pedLocation
end

---@return vector3 pedCoordinates
function CTruckingConfig:getDepotPedCoordinates()
  return self.private.m_depotPedCoordinates
end

function CTruckingConfig:setDepotPedHeading()
  local pedHeading = GetConvarFloat('truckJob:depotPedHeading', 225.24)

  self.private.m_depotPedHeading = pedHeading
end

function CTruckingConfig:getDepotPedHeading()
  return self.private.m_depotPedHeading
end

function CTruckingConfig:setDepotBlipCoordinates()
  self.private.m_depotBlipCoordinates = GetConvarVector('truckJob:depotBlipLocation',
    CONFIG_DEFAULTS.DEPOT_BLIP_COORDINATES)
end

---comment
---@return vector3
function CTruckingConfig:getDepotBlipCoordinates()
  return self.private.m_depotBlipCoordinates
end

---Gets a random truck model hash from the loaded truck models.
---@return number # The hash of a randomly selected truck model.
function CTruckingConfig:getRandomTruckModel()
  ---@diagnostic disable-next-line: missing-return-value
  if not IS_SERVER then return end

  local truckModels = self.private.truckModels

  if type(truckModels) ~= 'table' or table.type(truckModels) ~= 'array' or #truckModels < 1 then
    error('no truck models')
  end

  local truckModelIndex = math.random(#truckModels)

  return truckModels[truckModelIndex]
end

---Sets the truck models by loading them from the configuration using a Convar.
function CTruckingConfig:setTruckModels()
  if not IS_SERVER then return end

  local truckModels = GetConvarArray('truckJob:truckModels', CONFIG_DEFAULTS.TRAILER_MODELS)

  if #self.private.truckModels >= 1 then
    table.clear(self.private.truckModels)
  end

  for index = 1, #truckModels do
    local model = truckModels[index]

    table.insert(self.private.truckModels, model)
  end
end

---Gets a random trailer model hash from the loaded trailer models.
---@return number # The hash of a randomly selected trailer model.
function CTruckingConfig:getRandomTrailerModel()
  ---@diagnostic disable-next-line: missing-return-value
  if not IS_SERVER then return end

  local trailerModels = self.private.trailerModels

  if type(trailerModels) ~= 'table' or table.type(trailerModels) ~= 'array' or #trailerModels < 1 then
    error('no trailer models')
  end

  local trailerModelIndex = math.random(#trailerModels)

  return trailerModels[trailerModelIndex]
end

---Sets the trailer models by loading them from the configuration using a Convar.
function CTruckingConfig:setTrailerModels()
  ---@diagnostic disable-next-line: missing-return-value
  if not IS_SERVER then return end

  local trailerModels = GetConvarArray('truckJob:trailerModels', CONFIG_DEFAULTS.TRAILER_MODELS)

  if not trailerModels then
    error('Failed to parse alrp:truckJob:trailerModels, check your configuration file and restart the resource.')
  end

  if #self.private.trailerModels >= 1 then
    table.clear(self.private.trailerModels)
  end

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
function CTruckingConfig:setTruckSpawnLocations()
  local truckSpawns = GetConvarVectorWithHeading('truckJob:truckSpawnLocations', CONFIG_DEFAULTS.TRUCK_SPAWNS)

  if #self.private.truckSpawns >= 1 then
    table.clear(self.private.truckSpawns)
  end

  for index = 1, #truckSpawns do
    local spawn = truckSpawns[index]
    local _coordinate = spawn.coordinate
    local _heading = spawn.heading

    table.insert(self.private.truckSpawns, {
      coordinate = _coordinate,
      heading = _heading
    })
  end
end

---Gets the trailer spawn locations stored in the configuration.
---@return table # A table containing the trailer spawn locations with position and heading.
function CTruckingConfig:getTrailerSpawns()
  return self.private.trailerSpawns
end

---Sets the trailer spawn locations by loading them from the configuration using a Convar.
function CTruckingConfig:setTrailerSpawnLocations()
  local trailerSpawns = GetConvarVectorWithHeading('truckJob:trailerSpawnLocations', CONFIG_DEFAULTS.TRAILER_SPAWNS)

  table.clear(self.private.trailerSpawns)

  for trailerSpawnIndex = 1, #trailerSpawns do
    local trailerSpawn = trailerSpawns[trailerSpawnIndex]

    table.insert(self.private.trailerSpawns, trailerSpawn)
  end
end

function CTruckingConfig:getRandomDeliveryRoute()
  local deliveryRoutes = self.private.m_deliveryRoutes
  local deliveryRouteIndex = math.random(#deliveryRoutes)

  return self.private.m_deliveryRoutes[deliveryRouteIndex]
end

function CTruckingConfig:getPayPerDelivery()
  --return self.private.m_payPerDelivery
end

function CTruckingConfig:getPayPerMile()
  --return self.private.m_payPerMile
end

-- Method to set payout multipliers from the configuration
function CTruckingConfig:setPayoutRates()
  if not IS_SERVER then return end

  --self.private.m_payPerDelivery = GetConvarFloat('truckJob:payPerDelivery', 50.0)
  --self.private.m_payPerMile = GetConvarFloat('truckJob:payPerMile', 50.0)
end

---Gets the route at the specified index
---@param index number
---@return CDeliveryRoute
function CTruckingConfig:getRouteAtIndex(index)
  local route = self.private.m_deliveryRoutes[index]

  return route
end

function CTruckingConfig:_getDeliveryRoutes()
  return self.private.m_deliveryRoutes
end

---comment
function CTruckingConfig:_setDeliveryRoutes()
  local rawRoutes = GetConvar('truckJob:_deliveryRoutes', 'default')

  if rawRoutes == 'default' then
    warn('CTruckingConfig:setDeliveryRoutes is unset falling back to default routes.')
    self.private.m_deliveryRoutes = CONFIG_DEFAULTS.DELIVERY_DROP_POINTS
    return
  end

  local routesDecoded = json.decode(rawRoutes)

  if not routesDecoded then
    warn('CTruckingConfig:setDeliveryRoutes could not decode truckJob:_deliveryRoutes falling back to default routes.')
    self.private.m_deliveryRoutes = CONFIG_DEFAULTS.DELIVERY_DROP_POINTS
    return
  end

  local routeFactory = CRouteFactory:new()

  self.private.m_deliveryRoutes = {}

  for routeIndex, routeData in ipairs(routesDecoded) do
    local route, errorMessage = try(routeFactory.createRoute, routeIndex, routeData.routeType, routeData.routeName, routeData.trailerCoordinates,
    routeData.routeTrailerModel)

    if not errorMessage  then
      table.insert(self.private.m_deliveryRoutes, route)
    else
      warn(('Failed to create route %s at index %d: %s'):format(routeData.routeName, routeIndex, errorMessage))
    end
  end
end