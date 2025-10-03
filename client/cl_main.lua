local FIVE_SECONDS <const> = 5000
local config <const> = CTruckingConfig:new()
local deliveryManager <const> = CDeliveryManager:new(config)
local deliveryController <const> = CDeliveryController:new(config)

Depot = CDepot:new(config)

RegisterNetEvent('truckJob:deliveryController:routeAssigned', function(routeIndex)
    if routeIndex == RouteTypes.INVALID then
        deliveryController:setRoute(routeIndex)
    end

    local route = deliveryManager:getRouteAtIndex(routeIndex)

    if not route then
        warn(('Failed to set route index for delivery controller %s is not a valid route index'):format(routeIndex))
        return
    end

    route:setState(RouteStates.waitingForTruck)
    deliveryController:setRoute(route)
end)

RegisterNetEvent('truckJob:deliveryController:truckAssigned', function(networkTruckIndex)
    local route = deliveryController:getRoute()

    if not route then
        error('No route assigned can not set truck index')
    end

    local timeout = GetGameTimer() + FIVE_SECONDS

    while not NetworkDoesNetworkIdExist(networkTruckIndex) == 0 and timeout < FIVE_SECONDS do
        Wait(0)
    end

    if not NetworkDoesNetworkIdExist(networkTruckIndex) then
        warn('Delivery route truck does not exist after five seconds')
        return
    end

    local truckIndex = NetworkGetEntityFromNetworkId(networkTruckIndex)

    route:setTruckIndex(truckIndex)
    route:setState(RouteStates.waitingForTrailer)
end)

RegisterNetEvent('truckJob:deliveryController:trailerAssigned', function(networkTrailerIndex)
    local route = deliveryController:getRoute()

    if not route then
        return
    end

    BusyspinnerOff()

    route:setState(RouteStates.ready)
    route:setNetworkTrailerIndex(networkTrailerIndex)
    route:performRouteTasks()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if cache.resource ~= resourceName then
        return
    end

    AddTextEntry('TJ_UNKNOWN_ERROR',
        'An unknown error occured try repeating your previous action or contact development if this issue persists.')
    AddTextEntry('TJ_ALREADY_CLOCKED_IN', 'You\'re already clocked in your vehicle should be nearby.')
    AddTextEntry('TJ_ALREADY_CLOCKED_OUT', 'You can not clock out as you were never clocked in.')
    AddTextEntry('TJ_SHIFT_ALREADY_STARTED', 'You already began your shift your equipment should be nearby.')

    AddTextEntry('TJ_NO_TRK_SPAWN',
        'No truck spawn avalible wait a couple minutes and retry. Alternatively contact staff if the issue persists.')
    AddTextEntry('TJ_NO_TRL_SPAWN',
        'No trailer spawn avalible wait a couples minutes and retry. Alternatively contact staff if the issue persists.')

    AddTextEntry('TJ_FAILED_TO_ASSIGN_ROUTE', 'Failed to assign route you have been clocked out')

    AddTextEntry('TJ_COLLECT_TRUCK', 'Enter the delivery vehicle marked ~HUD_COLOUR_GREEN~~BLIP_TRUCK~~s~ on your map')
    AddTextEntry('TJ_COLLECT_TRAILER', 'Collect the trailer marked ~HUD_COLOUR_GREEN~~BLIP_TRAILER~~s~ on your map.')

    AddTextEntry('TJ_DELIVER_TRAILER', 'Deliver the trailer to the marked ~HUD_COLOUR_YELLOW~~BLIP_ON_MISSION~~s~ location on your map.')
    AddTextEntry('TJ_TRAILER_TOO_FAR', 'The receiving client thinks the trailer is too far from the drop point. Wait for your trailer to be reconnected and move closer.')

    AddTextEntry('TJ_RETURN_TO_DEPOT', 'Return to the depot ~HUD_COLOUR_ORANGEDARK~~BLIP_CAPTURE_THE_FLAG~~s~ to recieve your payment.')
    AddTextEntry('TJ_RETURN_TRUCK', 'Return your delivery vehicle to the point marked ~HUD_COLOUR_YELLOW~~BLIP_ON_MISSION~~s~  on your map')

    AddTextEntry('TJ_HINT_DROP_TRAILER', 'Hold ~INPUT_VEH_ROOF~ to drop your trailer when the marker turns green.')

    AddTextEntry('TJ_RETURN_TO_MANAGER', 'Speak with the Post OP Manager ~HUD_COLOUR_ORANGEDARK~~BLIP_VIP~~s~ to complete your shift.')
    AddTextEntry('TJ_PAYMENT_RECIEVE', 'Great Work! For finishing ~1~ deliveries you have been payed ~HUD_COLOUR_GREEN~~1~~s~.')
    AddTextEntry('TJ_TIP_SPEAK_TO_MANAGER', 'Speak with the Post OP Depot Manager ~HUD_COLOUR_ORANGEDARK~~BLIP_VIP~~s~ to start your shift.')

    AddTextEntry('TJ_TRAILER_DISCONNECTED_FAR', 'Trailer disconnected! Recover the trailer to complete your job and get payed!')
    AddTextEntry('TJ_TRAILER_DISCONNECTED_CLOSE', 'Trailer disconnected! Disconnect the trailer when the marker turns green.')

    AddTextEntry('TJ_FAILED_TRUCK_DESTROYED', '')

    AddTextEntry('TJ_WAITING_FOR_ROUTE_ASSIGNMENT', 'Waiting for route to be assigned...')
    AddTextEntry('TJ_WAITING_FOR_ROUTE_INIT', 'Waiting for route initialization...')
    AddTextEntry('TJ_INCORRECT_TRUCK', 'You are not in the correct delivery vehicle. Please enter the one marked on your map.')
    AddTextEntry('TJ_INCORRECT_TRAILER', 'You have connected to the incorrect trailer! Your trailer is marked on the map ~HUD_COLOUR_GREEN~~BLIP_TRAILER~~s~')
    AddTextEntry('TJ_HLP_VALIDATING_WITH_SERVER', 'Validating with server....')
    AddTextEntry('TJ_NO_ROUTE_ASSIGNED', 'Failed to perform action, no route was assigned. This is a syncing issue and should be reported to the developers!')
end)