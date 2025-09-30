---@class CDeliveryDropPoint
---@field private private { m_name: string }
CDeliveryDropPoint = lib.class('CTrailerDropPoint')

---comment
---@param trailerIndex number
---@param _name string
---@param _coordinate vector3
---@param _markerDirection vector3
---@param _markerRotation vector3
function CDeliveryDropPoint:constructor(trailerIndex, _name, _coordinate, _markerDirection, _markerRotation)
  self.private.m_name = _name or 'Unknown'
  self.private.m_coordinate = _coordinate
  self.private.m_markerDirection = _markerDirection
  self.private.m_markerRotation = _markerRotation

  local trailerModel = GetEntityModel(trailerIndex)
  local trailerModelMin, trailerModelMax = GetModelDimensions(trailerModel)
  local trailerModelLegth = trailerModelMax.y - trailerModelMin.y
  local trailerModelWidth = trailerModelMax.x - trailerModelMin.x

  self.private.m_marker = lib.marker.new({
    type = 30,
    coords = _coordinate,
    direction = _markerDirection,
    rotation = _markerRotation,
    width = trailerModelWidth,
    height = trailerModelLegth,
    faceCamera = false
  })
end

function CDeliveryDropPoint:getMarker()
  return self.private.m_marker
end