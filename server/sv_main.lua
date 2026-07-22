local UNASSIGNED_DRIVERS_POLL_RATE <const> = 1000
local MAXIMUM_DISTANCE_BETWEEN_TRUCK_AND_TRAILER <const> = 50

local config <const> = CTruckingConfig:new()
local deliveryManager <const> = CDeliveryManager:new(config)
local driverManager <const> = CDriverManager:new(config, deliveryManager)

lib.callback.register('mrp:trucking:clockIn', function(source)
    return driverManager:clockInPlayer(source)
end)

lib.callback.register('mrp:trucking:clockOut', function(source)
    return driverManager:clockOutPlayer(source)
end)

lib.callback.register('mrp:trucking:continueShift', function(source)
    return driverManager:assignPlayerRoute(source)
end)

lib.callback.register('mrp:trucking:truckCollected', function(source)
    local driver = driverManager:getDriver(source)

    if not driver then
        return false, 'TJ_NOT_CLOCKED_IN'
    end

    local driverIndex = driver:getPlayerIndex()
    local driverRoute = driver:getDeliveryRoute()

    if not driverRoute then
        warn(('Driver %s just tried to mark their truck as collected but they do not have a route assigned to them. Resetting driver state to waiting for delivery'):format(GetPlayerName(driverIndex)))
        driver:setStatus(DriverStatus.WAITING_FOR_DELIVERY)
        return false, 'TJ_NO_ROUTE_ASSIGNED'
    end

    local driverTruck = driverRoute:getTruckIndex()

    if not DoesEntityExist(driverTruck) then
        warn(('Driver %s just tried to mark their truck as collected but the truck doesn\'t exist. Resetting driver state to waiting for delivery'):format(GetPlayerName(driverIndex)))
        driver:setStatus(DriverStatus.WAITING_FOR_DELIVERY)
        return false, 'TJ_TRUCK_DOES_NOT_EXIST'
    end

    local driverPed = GetPlayerPed(driverIndex)

    if GetVehiclePedIsIn(driverPed, false) ~= driverTruck then
        TaskLeaveAnyVehicle(driverPed, 0, 1)
        return false, 'TJ_INCORRECT_TRUCK'
    end

    driver:setStatus(DriverStatus.COLLECTING_TRAILER)
    driverRoute:setState(RouteStates.waitingForTrailer)

    return true
end)

lib.callback.register('mrp:trucking:trailerCollected', function(source)
    local driver = driverManager:getDriver(source)

    if not driver then
        lib.logger(source, 'mrp:trucking:trailerCollected', 'attempted to mark a trailer as collected but they aren\'t clocked in.')
        return false, 'TJ_NOT_CLOCKED_IN'
    end

    local driverRoute = driver:getDeliveryRoute()

    if not driverRoute then
        return false, 'TJ_NO_ROUTE_ASSIGNED'
    end

    local driverTruck = driverRoute:getTruckIndex()
    local driverTruckCoordinate = GetEntityCoords(driverTruck)
    local driverTrailer = driverRoute:getTrailerIndex()
    local driverTrailerCoordinate = GetEntityCoords(driverTrailer)
    local distanceBetweenTruckAndTrailer = #(driverTruckCoordinate - driverTrailerCoordinate)

    if distanceBetweenTruckAndTrailer >= MAXIMUM_DISTANCE_BETWEEN_TRUCK_AND_TRAILER then
        lib.logger(source, 'mrp:trucking:trailerCollected', string.format('tried to mark their trailer as collected but they\'re %d meters away.', distanceBetweenTruckAndTrailer))
        return false, 'TJ_TRAILER_TOO_FAR'
    end

    driver:setStatus(DriverStatus.DELIVERING_TRAILER)
    driverRoute:setState(RouteStates.inProgress)

    return true
end)

lib.callback.register('mrp:trucking:trailerDelivered', function(source)
    local driver = driverManager:getDriver(source)

    if not driver then
        lib.logger(source, 'mrp:trucking:trailerDelivered', string.format('%s just tried to mark their trailer as delivered but they\'re not a driver.', GetPlayerName(source)))
        return false, 'TJ_NOT_CLOCKED_IN'
    end

    local driverRoute = driver:getDeliveryRoute()

    if not driverRoute then
        lib.logger(source, 'mrp:trucking:trailerDelivered', string.format('%s just tried to mark their trailer as delivered but they have no route assigned to them.', GetPlayerName(source)))
        return false, 'TJ_NO_ROUTE_ASSIGNED'
    end

    local trailerIndex = driver:getTrailerIndex()
    local trailerCoordinate = GetEntityCoords(trailerIndex)
    local trailerReturnCoordinates = driverRoute:getTrailerReturnLocation().coordinates
    local trailerDistanceFromDropPoint = #(trailerReturnCoordinates - trailerCoordinate)

    if trailerDistanceFromDropPoint >= 10 then
        lib.logger(source, 'mrp:trucking:trailerDelivered',
            string.format(
                '%s just tried to mark their trailer as delivered from an egregious distance (%d) meters',
                GetPlayerName(source),
                trailerDistanceFromDropPoint
            ))
        return false, 'TJ_TRAILER_TOO_FAR'
    end

    driver:setStatus(DriverStatus.RETURNING_TO_DEPOT)

    SetEntityOrphanMode(trailerIndex, 0)

    return true
end)

lib.callback.register('mrp:trucking:truckReturned', function(source)
    local driver = driverManager:getDriver(source)

    if not driver then
        lib.logger(source, 'mrp:trucking:truckReturned',
            string.format('%s just tried to mark their truck as returned but they\'re not a driver.',
                GetPlayerName(source)))
        return false, 'TJ_NOT_CLOCKED_IN'
    end

    driver:setStatus(DriverStatus.SPEAKING_WITH_MANAGER)
    driverManager:completeDriverDelivery(driver)

    return true
end)

RegisterNetEvent('mrp:trucking:routeAbandonded', function()
    local source = source --[[@as number]]
    local driver = driverManager:getDriver(source)

    if not driver then
        return
    end

    driverManager:removeDriver(driver)
end)

AddEventHandler('playerDropped', function()
    local driver = driverManager:getDriver(source)

    if not driver then
        return
    end

    driverManager:removeDriver(driver)
end)

-- Process waiting drivers periodically
CreateThread(function()
    while true do
        Wait(UNASSIGNED_DRIVERS_POLL_RATE)

        -- Use the new processWaitingDrivers method
        driverManager:processWaitingDrivers()
    end
end)
