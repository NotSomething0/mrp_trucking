---@class CDepot
---@field private private {  m_blip: number }
CDepot = lib.class('CDepot')

---Creates a new depot object
---@param blipCoordinate vector3
function CDepot:constructor(blipCoordinate)
  self.private.m_blip = self:createBlip(blipCoordinate)

  self:updateBlip()
end

---Get the blip for the depot
---@return number blip
function CDepot:getBlip()
  return self.private.m_blip
end

---Create a blip for the depot
---@param blipCoordinate vector3
---@return number blip
function CDepot:createBlip(blipCoordinate)
  local blip = AddBlipForCoord(blipCoordinate.x, blipCoordinate.y, blipCoordinate.z)

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

function CDepot:getTruckReturnCoordinate()
  local truckSpawns = Config:getTruckSpawns()
  local truckReturnCoordinate = vector3(0, 0, 0)

  for index = 1, #truckSpawns do
    local spawn = truckSpawns[index]
    local spawnFree = true

    for _, vehicleIndex in pairs(GetGamePool('CVehicle')) do
      local vehicleCoords = GetEntityCoords(vehicleIndex)

      if #(spawn.coordinate - vehicleCoords) <= 4 then
        spawnFree = false
        break
      end
    end

    if spawnFree then
      truckReturnCoordinate = spawn.coordinate
      break
    end
  end

  return truckReturnCoordinate
end