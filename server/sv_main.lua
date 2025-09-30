local UNASSIGNED_DRIVERS_POLL_RATE <const> = 1000
local MAXIMUM_DISTANCE_BETWEEN_TRUCK_AND_TRAILER <const> = 50

local config <const> = CTruckingConfig:new()
local deliveryManager <const> = CDeliveryManager:new(config)
local driverManager <const> = CDriverManager:new(config, deliveryManager)

lib.callback.register('mrp:trucking:clockIn', function(source)
    local driver = driverManager:getDriver(source)

    if driver then
        return false, 'TJ_ALREADY_CLOCKED_IN'
    end

    driver = CDriver:new(source)

    if not driver then
        return false, 'TJ_UNKNOWN_ERROR'
    end

    local success = driverManager:addDriver(driver)

    if not success then
        return false, 'TJ_FAILED_TO_ADD_DRIVER'
    end

    return true
end)

lib.callback.register('alrp:truckJob:clockOut', function(source)
    local driver = driverManager:getDriver(source)

    if not driver then
        return false, 'TJ_ALREADY_CLOCKED_OUT'
    end

    if driver:getDeliveryRoute() then
        return false, 'TJ_SHIFT_ALREADY_STARTED'
    end

    driverManager:payOutDriver(driver)
    driverManager:removeDriver(driver)

    return true
end)

lib.callback.register('alrp:truckJob:truckCollected', function(source)
    local driver = driverManager:getDriver(source)

    if not driver then
        return false, 'TJ_NOT_CLOCKED_IN'
    end

    local driverIndex = driver:getPlayerIndex()
    local driverPed = GetPlayerPed(driverIndex)
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

    if GetVehiclePedIsIn(driverPed, false) ~= driverTruck then
        TaskLeaveAnyVehicle(driverPed, 0, 1)
        return false, 'TJ_INCORRECT_TRUCK'
    end

    -- Update driver and route state
    driver:setStatus(DriverStatus.COLLECTING_TRAILER)
    driverRoute:setState(RouteStates.waitingForTrailer)

    return true
end)

lib.callback.register('alrp:truckJob:trailerCollected', function(source)
    local driver = driverManager:getDriver(source)

    if not driver then
        lib.logger(source, 'alrp:truckJob:trailerCollected', 'attempted to mark a trailer as collected but they aren\'t clocked in.')
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
        lib.logger(source, 'alrp:truckJob:trailerCollected', ('Possible cheater detected - egregious distance between truck and trailer: %d meters'):format(distanceBetweenTruckAndTrailer))
        return false, 'TJ_TRAILER_TOO_FAR'
    end

    -- Update driver and route state
    driver:setStatus(DriverStatus.DELIVERING_TRAILER)
    driverRoute:setState(RouteStates.inProgress)

    return true
end)

-- Process waiting drivers periodically
CreateThread(function()
    while true do
        Wait(UNASSIGNED_DRIVERS_POLL_RATE)

        -- Use the new processWaitingDrivers method
        driverManager:processWaitingDrivers()
    end
end)

lib.callback.register('truckJob:trailerDelivered', function(source)
    local driver = driverManager:getDriver(source)

    if not driver then
        lib.logger(source, 'truckJob:trailerDelivered',
            string.format('%s just tried to mark their trailer as delivered but they\'re not a driver.',
                GetPlayerName(source)))
        return false, 'TJ_NOT_CLOCKED_IN'
    end

    local driverRoute = driver:getDeliveryRoute()

    if not driverRoute then
        lib.logger(source, 'truckJob:trailerDelivered',
            string.format('%s just tried to mark their trailer as delivered but they have no route assigned to them.',
                GetPlayerName(source)))
        return false, 'TJ_NO_ROUTE_ASSIGNED'
    end

    local trailerIndex = driver:getTrailerIndex()
    local trailerCoordinate = GetEntityCoords(trailerIndex)
    local trailerDistanceFromDropPoint = #(driverRoute:getTrailerReturnLocation() - trailerCoordinate)

    if trailerDistanceFromDropPoint >= 10 then
        lib.logger(source, 'truckJob:trailerDelivered',
            ('%s just tried to mark their trailer as delivered from an egregious distance (%d) meters'):format(
            GetPlayerName(source), trailerDistanceFromDropPoint))
        return false, 'TJ_TRAILER_TOO_FAR'
    end

    driver:setStatus(DriverStatus.RETURNING_TO_DEPOT)
    driverRoute:setState(RouteStates.completed)

    SetEntityOrphanMode(trailerIndex, 0)

    return true
end)

lib.callback.register('truckJob:truckReturned', function(source)
    local driver = driverManager:getDriver(source)

    if not driver then
        lib.logger(source, 'truckJob:truckReturned',
            string.format('%s just tried to mark their truck as returned but they\'re not a driver.',
                GetPlayerName(source)))
        return false, 'TJ_NOT_CLOCKED_IN'
    end

    driverManager:completeDriverDelivery(driver)

    return true
end)

RegisterNetEvent('truckJob:driver:forceQuit', function(quitReason)
    local driver = driverManager:getDriver(source)

    if not driver then
        return
    end

    -- Log the quit reason
    lib.logger(source, 'truckJob:driver:forceQuit', ('Driver %s force quit with reason: %s'):format(GetPlayerName(source), quitReason or 'unknown'))

    -- Clean up and remove the driver
    driverManager:removeDriver(driver)
end)

AddEventHandler('playerDropped', function()
    local driver = driverManager:getDriver(source)

    if not driver then
        return
    end

    driverManager:removeDriver(driver)
end)