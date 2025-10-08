---Sets the displayed name for a blip
---@param blip number
---@param name string
function SetBlipName(blip, name)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentString(name)
  EndTextCommandSetBlipName(blip)
end

--- Converts a table into a vector3 or an array of vector3 objects.
--- If the input table is of type 'hash', it expects keys `x`, `y`, and `z` with numeric or convertible string values.
--- If the input table is of type 'array', it recursively processes each element to produce a list of vector3 objects.
--- Returns `false` and an error message if the table is not valid or if any value cannot be converted to a vector3.
--- @param tbl table The input table to be processed (either 'hash' or 'array').
--- @return vector3|vector3[]|false result The converted vector3 object(s) or `false` on error.
--- @return string? errorMessage An error message if the conversion fails, otherwise `nil`.
function table.vectorize(tbl)
  local paramType = type(tbl)

  if paramType ~= 'table' then
    return false, 'expected table got ' .. paramType
  end

  local tableType = table.type(tbl)

  if tableType == 'hash' then
    local x, y, z = tbl.x, tbl.y, tbl.z

    if not x or not y or not z then
      return false, 'missing x, y, or z values'
    end

    local numericX, numericY, numericZ = tonumber(x), tonumber(y), tonumber(z)

    if not numericX then
      return false, 'x could not be converted to a number'
    end

    if not numericY then
      return false, 'y could not be converted to a number'
    end

    if not numericZ then
      return false, 'z could not be converted to a number'
    end

    return vector3(numericX, numericY, numericZ)
  end

  if tableType == 'array' then
    local retval = {}

    for _, entry in ipairs(tbl) do
      local result, errorMessage = table.vectorize(entry)

      if not result then
        return false, errorMessage
      end

      table.insert(retval, result)
    end

    return retval
  end

  return false, string.format('Invalid table type specified. Expected \'hash\' or \'array\', got %s', tableType)
end

function table.shuffle(t)
  local rand = math.random
  local n = #t

  for i = n, 2, -1 do
    local j = rand(1, i)
    t[i], t[j] = t[j], t[i] -- swap elements
  end

  return t
end

---Takes a Convar and attempts to convert it to a vector3
---@param convarName string
---@param default vector3|vector3[]
---@return vector3|vector3[] retval
function GetConvarVector(convarName, default)
  local convarValueRaw = GetConvar(convarName, 'default')

  if convarValueRaw == 'default' then
    warn(('Convar %s was not set. Falling back on default configuration'):format(convarName))
    return default
  end

  local convarValuedDecoded = json.decode(convarValueRaw)
  local convarValueVectorized, errorMessage = table.vectorize(convarValuedDecoded)

  if not convarValueVectorized then
    warn(('Convar %s could not be vectorized %s. Falling back on default configuration'):format(convarName,
      errorMessage))
    return default
  end

  return convarValueVectorized
end

---comment
---@param convarName any
---@param default any
---@return table retval
function GetConvarVectorWithHeading(convarName, default)
  local rawConvarValue = GetConvar(convarName, 'default')

  if rawConvarValue == 'default' then
    warn(('Convar %s was not set. Using default configuration %s'):format(convarName,
      json.encode(default, { indent = true })))
    return default
  end

  local convarValuedDecoded = json.decode(rawConvarValue)

  if type(convarValuedDecoded) ~= 'table' or table.type(convarValuedDecoded) ~= 'array' then
    warn(('Convar %s is not a valid table or array. Using default configuration:\n%s'):format(convarName,
      json.encode(default, { indent = true })))
    return default
  end

  local retval = {}

  for index = 1, #convarValuedDecoded do
    local entry = convarValuedDecoded[index]
    local _heading = entry?.h or entry?.heading

    if type(_heading) ~= 'number' then
      warn(('Convar %s is missing a heading argument at index %d. Using default configuration \n%s'):format(convarName,
        index, json.encode(default, { indent = true })))
      return default
    end

    local _coordinate, errorMessage = table.vectorize(entry)

    if errorMessage then
      warn(('Convar %s could not be vectorized: %s. Using default configuration:\n%s'):format(convarName, errorMessage,
        json.encode(default, { indent = true })))
      return default
    end

    table.insert(retval, {
      heading = _heading,
      coordinate = _coordinate
    })
  end

  return retval
end

---comment
---@param convarName string
---@param default table
---@return table retval
function GetConvarArray(convarName, default)
  local convarValueRaw = GetConvar(convarName, 'default')

  if convarValueRaw == 'default' then
    warn(('Convar %s was not set. Falling back on default configuration'):format(convarName))
    return default
  end

  local convarValueDecoded = json.decode(convarValueRaw)

  if type(convarValueDecoded) ~= 'table' or table.type(convarValueDecoded) ~= 'array' then
    warn(('Convar %s is supposed to be set as an array. Falling back on default configuration'):format(convarName))
    return default
  end

  return convarValueDecoded
end

---@param funcRef function
---@param ... any
---@return any result
---@return string? errorMessage
---@diagnostic disable-next-line: lowercase-global
function try(funcRef, ...)
  local success, result = pcall(funcRef, ...)

  if not success then
    return nil, result
  end

  return result, nil
end

---comment
---@param entity number
---@return number
function GetEntityWidth(entity)
  local entityModel = GetEntityModel(entity)
  local modelMin, modelMax = GetModelDimensions(entityModel)

  return modelMax.x - modelMin.x
end

---comment
function DisplayBusySpinner(labelName)
  BeginTextCommandBusyspinnerOn('STRING')
  AddTextComponentSubstringTextLabel(labelName)
  EndTextCommandBusyspinnerOn(4)
end