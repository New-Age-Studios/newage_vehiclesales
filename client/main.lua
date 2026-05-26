local config = require 'config.config'
local zone
local activeZone = {}
local currentVehicle = {}
local occasionVehicles = {}
local spawnedPeds = {}
local spawnedProps = {}
local debugVehicles = {}

local isPositioningVehicle = false
local pendingSellData = nil
local targetSellSpot = nil
local sellSpotBlip = nil

-- ─────────────────────────────────────────────────────────────────────────────
-- Zone vehicle display mutex
-- All operations that create or destroy local display entities MUST hold this
-- lock. This prevents the mass duplication caused by concurrent coroutines
-- (lib.requestModel / lib.callback.await yield points) interleaving:
--   • zone onEnter spawn
--   • refreshVehicles despawn+spawn
--   • spawnNetworkedVehicleAtSlot (buy/return)
-- ─────────────────────────────────────────────────────────────────────────────
local vehicleZoneLock = false

local function acquireZoneLock()
    local waited = 0
    while vehicleZoneLock and waited < 10000 do
        Wait(50)
        waited = waited + 50
    end
    vehicleZoneLock = true
end

local function releaseZoneLock()
    vehicleZoneLock = false
end

local function spawnDebugVehicles(zoneName)
    if not config.debug then return end
    local cfg = config.zones[zoneName]
    if not cfg then return end

    local model = joaat('blista') -- Modelo de carro padrão para debug
    lib.requestModel(model)

    debugVehicles[zoneName] = {}

    for i, spot in ipairs(cfg.vehicleSpots) do
        local veh = CreateVehicle(model, spot.x, spot.y, spot.z, spot.w, false, false)
        SetEntityAlpha(veh, 100, false)
        SetEntityCollision(veh, false, false)
        FreezeEntityPosition(veh, true)
        SetVehicleDoorsLocked(veh, 2)
        SetModelAsNoLongerNeeded(model)
        table.insert(debugVehicles[zoneName], veh)
    end
end

local function despawnDebugVehicles(zoneName)
    if not debugVehicles[zoneName] then return end
    for _, veh in ipairs(debugVehicles[zoneName]) do
        if DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
    end
    debugVehicles[zoneName] = nil
end

local function DeleteDisplayVehicle(veh)
    if not veh or not DoesEntityExist(veh) then return end

    -- SetEntityAsMissionEntity prevents the GTA streaming bug where nearby map models
    -- disappear when a local entity is deleted.
    SetEntityAsMissionEntity(veh, true, true)
    SetEntityAsNoLongerNeeded(veh)

    -- SYNCHRONOUS retry loop — all callers are inside a coroutine/thread so Wait() is safe.
    -- Keeping this synchronous is critical: async deletion (CreateThread) causes race conditions
    -- where refreshVehicles spawns a new display entity on top of the still-existing vehicle.
    for _ = 1, 10 do
        if not DoesEntityExist(veh) then break end
        DeleteVehicle(veh)
        Wait(50)
    end
end

local function spawnOccasionsVehicles(vehicles)
    -- Must be called with vehicleZoneLock held.
    -- lib.requestModel yields, so without the lock a concurrent refreshVehicles
    -- could start a second spawn on top of this one, causing mass duplication.
    if not zone then return end
    local currentZone = zone -- snapshot; zone may change during awaits
    local oSlot = config.zones[currentZone].vehicleSpots
    occasionVehicles[currentZone] = {}
    if not vehicles then return end

    local count = 0
    for i = 1, #vehicles do
        if zone ~= currentZone then break end -- exited zone mid-spawn, abort
        local v = vehicles[i]
        if v.zone == currentZone then
            count = count + 1
            if count > #oSlot then break end

            local model = joaat(v.model)
            lib.requestModel(model) -- yields — lock prevents concurrent entry here

            if zone ~= currentZone then
                -- Zone changed while we were loading the model; clean up and abort
                SetModelAsNoLongerNeeded(model)
                break
            end

            local car = CreateVehicle(model, oSlot[count].x, oSlot[count].y, oSlot[count].z, false, false)
            SetModelAsNoLongerNeeded(model)

            occasionVehicles[currentZone][count] = {
                car       = car,
                loc       = oSlot[count],
                price     = v.price,
                owner     = v.seller,
                model     = v.model,
                plate     = v.plate,
                oid       = v.occasionid,
                desc      = v.description,
                mods      = v.mods,
                fuelType  = v.fuel_type,
                colorRGB  = v.color_rgb,
                isExotic  = v.is_exotic,
                transmission = v.transmission,
                photo_url = v.photo_url,
                hasTarget = false, -- set below if ox_target is active
            }

            lib.setVehicleProperties(car, json.decode(v.mods))
            -- Apply heading BEFORE grounding so vehicle settles at correct angle
            SetEntityHeading(car, oSlot[count].w)
            SetVehicleOnGroundProperly(car)
            SetEntityInvincible(car, true)
            SetVehicleDoorsLocked(car, 3)
            SetVehicleNumberPlateText(car, v.plate)
            FreezeEntityPosition(car, true)

            if config.useTarget then
                exports.ox_target:addLocalEntity(car, {
                    {
                        icon = 'fas fa-car',
                        label = locale('menu.view_contract'),
                        onSelect = function()
                            TriggerEvent('qb-vehiclesales:client:OpenContract', count)
                        end,
                        distance = 2.0
                    }
                })
                occasionVehicles[currentZone][count].hasTarget = true
            end
        end
    end
end

local function despawnOccasionsVehicles()
    -- Must be called with vehicleZoneLock held (or during onExit after lock force-release).
    if not zone then return end
    local oSlot = config.zones[zone].vehicleSpots

    -- Iterate with PAIRS, not ipairs.
    -- ipairs stops at the first nil hole (created by deleteDisplayVehicleByPlate);
    -- pairs visits every non-nil entry regardless of gaps in the sequence.
    if occasionVehicles[zone] then
        for _, data in pairs(occasionVehicles[zone]) do
            if data and data.car then
                if data.hasTarget and config.useTarget then
                    exports.ox_target:removeLocalEntity(data.car, locale('menu.view_contract'))
                end
                DeleteDisplayVehicle(data.car)
            end
        end
        occasionVehicles[zone] = nil
    end

    -- Safety sweep: catch any stray local (non-networked) vehicles still sitting
    -- at a display spot that weren't tracked (e.g. orphaned from a previous crash).
    for i = 1, #oSlot do
        local loc = oSlot[i]
        local strayVeh = GetClosestVehicle(loc.x, loc.y, loc.z, 1.5, 0, 70)
        if strayVeh and strayVeh ~= 0 and not NetworkGetEntityIsNetworked(strayVeh) then
            DeleteDisplayVehicle(strayVeh)
        end
    end
end

local function deleteDisplayVehicleByPlate(plate)
    if not zone or not occasionVehicles[zone] then return end
    for i = 1, #occasionVehicles[zone] do
        local data = occasionVehicles[zone][i]
        if data and data.plate == plate then
            -- Remove ox_target interaction first
            if data.hasTarget and config.useTarget then
                exports.ox_target:removeLocalEntity(data.car, locale('menu.view_contract'))
            end
            -- Nil the entry BEFORE deleting so despawnOccasionsVehicles (pairs loop)
            -- skips it and cannot attempt a second deletion on the same handle.
            occasionVehicles[zone][i] = nil
            if DoesEntityExist(data.car) then
                DeleteDisplayVehicle(data.car) -- synchronous
            end
            break
        end
    end
end

local function openMainMenu(bool)
    if not bool then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        return
    end

    local veh = cache.vehicle
    local vehicleData = nil

    if veh then
        local modelHash = GetEntityModel(veh)
        local modelName = GetDisplayNameFromVehicleModel(modelHash):lower()
        -- Capitalize first letter of vehicle name
        local formattedName = modelName:gsub("^%l", string.upper)
        local plate = qbx.getVehiclePlate(veh)

        local owned, balance = lib.callback.await('qbx_vehiclesales:server:checkVehicleOwner', false, plate)
        local price, payout, percentage = lib.callback.await('qbx_vehiclesales:server:getVehicleSellBackPrice', false, modelHash)

        vehicleData = {
            name = formattedName,
            plate = plate,
            price = price or 0,
            payout = payout or 0,
            percentage = percentage or 50,
            isOwned = owned == true,
            hasFinancing = (balance and balance > 0) == true
        }
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'mainMenu',
        currencySymbol = config.currencySymbol or "R$",
        currencyCode = config.currencyCode or "BRL",
        bizName = config.zones[zone].businessName,
        enableSellBack = config.enableSellBack ~= false,
        uiTranslations = getUiTranslations(),
        options = {
            sell = {
                title = t('menu.sell_vehicle'),
                desc = t('menu.sell_vehicle_help')
            },
            sellBack = {
                title = t('menu.sell_back'),
                desc = t('menu.sell_back_help')
            }
        },
        vehicleData = vehicleData
    })
end

local function openHistoryTablet(bool, targetZone)
    if not bool then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        return
    end

    local active, sold = lib.callback.await('qbx_vehiclesales:server:getPlayerSalesHistory', false, targetZone)

    local formattedActive = {}
    if active then
        for i = 1, #active do
            local item = active[i]
            table.insert(formattedActive, {
                oid = item.occasionid,
                plate = item.plate,
                model = item.model,
                price = item.price,
                description = item.description,
                mods = item.mods,
                fuelType = item.fuel_type,
                colorRGB = item.color_rgb,
                isExotic = item.is_exotic == 1 or item.is_exotic == true,
                transmission = item.transmission,
                photoUrl = item.photo_url
            })
        end
    end

    local formattedSold = {}
    if sold then
        for i = 1, #sold do
            local item = sold[i]
            table.insert(formattedSold, {
                id = item.id,
                buyerName = item.buyer_name,
                buyerCitizenId = item.buyer_citizenid,
                plate = item.plate,
                model = item.model,
                price = item.price,
                description = item.description,
                mods = item.mods,
                fuelType = item.fuel_type,
                colorRGB = item.color_rgb,
                isExotic = item.is_exotic == 1 or item.is_exotic == true,
                transmission = item.transmission,
                photoUrl = item.photo_url,
                date = item.date
            })
        end
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openHistoryTablet',
        currencySymbol = config.currencySymbol or "R$",
        currencyCode = config.currencyCode or "BRL",
        bizName = targetZone and config.zones[targetZone] and config.zones[targetZone].businessName or "Concessionária de Usados",
        uiTranslations = getUiTranslations(),
        active = formattedActive,
        sold = formattedSold,
        sellerData = {
            firstname = QBX.PlayerData.charinfo.firstname,
            lastname = QBX.PlayerData.charinfo.lastname,
            account = QBX.PlayerData.charinfo.account,
            phone = QBX.PlayerData.charinfo.phone
        }
    })
end


local function openSellContract(bool)
    if not bool then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        return
    end

    local veh = cache.vehicle
    if not veh then return end

    -- Fetch mileage from the mileage bridge (uses jg-vehiclemileage or custom)
    local plate = qbx.getVehiclePlate(veh)
    local mileage = MileageBridge.getForDisplay(plate)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'sellVehicle',
        currencySymbol = config.currencySymbol or "R$",
        currencyCode = config.currencyCode or "BRL",
        bizName = config.zones[zone].businessName,
        dealerFee = config.dealerFee or 0,
        uiTranslations = getUiTranslations(),
        sellerData = {
            firstname = QBX.PlayerData.charinfo.firstname,
            lastname = QBX.PlayerData.charinfo.lastname,
            account = QBX.PlayerData.charinfo.account,
            phone = QBX.PlayerData.charinfo.phone
        },
        vehicleData = {
            model = GetDisplayNameFromVehicleModel(GetEntityModel(veh)):lower(),
            plate = plate,
            mileage = mileage, -- nil when mileageProvider = "none"
            fuel = math.floor(GetVehicleFuelLevel(veh)),
            engine = math.floor(GetVehicleEngineHealth(veh) / 10),
            body = math.floor(GetVehicleBodyHealth(veh) / 10),
            color = "Personalizada"
        }
    })
end

local function openBuyContract(sellerData, vehicleData)
    -- Try to get mileage for the display vehicle.
    -- Priority 1: statebag of the local display entity (no server round-trip)
    -- Priority 2: server-side lookup via mileage_bridge callback
    local mileage = nil
    if config.mileageProvider and config.mileageProvider ~= "none" then
        -- Try statebag first using the local display entity
        local displayVeh = nil
        if zone and occasionVehicles[zone] then
            for _, data in pairs(occasionVehicles[zone]) do
                if data and data.plate == vehicleData.plate then
                    displayVeh = data.car
                    break
                end
            end
        end

        if displayVeh and DoesEntityExist(displayVeh) then
            local stateMileage = Entity(displayVeh).state.vehicleMileage
            if stateMileage then
                mileage = MileageBridge.formatMileage(tonumber(stateMileage))
            end
        end

        -- Fallback: server-side callback (reads from DB)
        if not mileage then
            local rawKm = lib.callback.await('newage_vehiclesales:server:getMileage', false, vehicleData.plate)
            if rawKm then
                mileage = MileageBridge.formatMileage(tonumber(rawKm))
            end
        end
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'buyVehicle',
        currencySymbol = config.currencySymbol or "R$",
        currencyCode = config.currencyCode or "BRL",
        showTakeBackOption = sellerData.charinfo.firstname == QBX.PlayerData.charinfo.firstname and sellerData.charinfo.lastname == QBX.PlayerData.charinfo.lastname,
        bizName = config.zones[zone].businessName,
        uiTranslations = getUiTranslations(),
        sellerData = {
            firstname = sellerData.charinfo.firstname,
            lastname = sellerData.charinfo.lastname,
            account = sellerData.charinfo.account,
            phone = sellerData.charinfo.phone
        },
        buyerData = {
            firstname = QBX.PlayerData.charinfo.firstname,
            lastname = QBX.PlayerData.charinfo.lastname
        },
        vehicleData = {
            desc = vehicleData.desc,
            price = vehicleData.price,
            mileage = mileage, -- nil when mileageProvider = "none"
            fuelType = vehicleData.fuelType,
            colorRGB = vehicleData.colorRGB,
            isExotic = vehicleData.isExotic == 1 or vehicleData.isExotic == true,
            transmission = vehicleData.transmission,
            photoUrl = vehicleData.photo_url or vehicleData.photoUrl
        },
        model = vehicleData.model,
        plate = vehicleData.plate
    })
end

local function cancelVehicleSale(reason)
    isPositioningVehicle = false
    pendingSellData = nil
    targetSellSpot = nil
    if sellSpotBlip then
        RemoveBlip(sellSpotBlip)
        sellSpotBlip = nil
    end
    lib.hideTextUI()
    exports.qbx_core:Notify(reason or "Venda cancelada.", 'error', 3500)
end

local function completeVehicleSale()
    local price = pendingSellData.price
    local vehicleData = pendingSellData.vehicleData

    isPositioningVehicle = false
    pendingSellData = nil
    targetSellSpot = nil
    if sellSpotBlip then
        RemoveBlip(sellSpotBlip)
        sellSpotBlip = nil
    end
    lib.hideTextUI()

    PlaySound(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false, 0, true)

    -- Block refreshVehicles from running while we delete the driven vehicle.
    -- Without this, refreshVehicles can arrive (triggered by the server event below)
    -- and spawn a display entity on top of the vehicle before it finishes deleting.
    isProcessingVehicleAction = true

    local veh = cache.vehicle
    if veh and veh ~= 0 then
        -- DeleteDisplayVehicle is synchronous: this line blocks until the vehicle is
        -- actually gone from the world before we continue.
        DeleteDisplayVehicle(veh)
    end

    isProcessingVehicleAction = false

    -- Only trigger the server event AFTER the vehicle is confirmed deleted.
    -- This way, when the server broadcasts refreshVehicles, there is no stray
    -- entity left at the spot for the new display vehicle to overlap with.
    TriggerServerEvent('qb-occasions:server:sellVehicle', price, vehicleData)

    exports.qbx_core:Notify((locale('success.car_up_for_sale'):format(config.currencySymbol or "R$", price)), 'success')
end

local function sellData(data, plate)
    if isPositioningVehicle then
        return exports.qbx_core:Notify("Você já está posicionando um veículo!", "error", 3500)
    end

    local dataReturning = lib.callback.await('qb-vehiclesales:server:CheckModelName', false, plate)
    local vehicleData = {}
    vehicleData.ent = cache.vehicle
    vehicleData.model = dataReturning
    vehicleData.plate = plate
    vehicleData.mods = lib.getVehicleProperties(vehicleData.ent)
    vehicleData.desc = data.desc
    -- New fields from NUI tablet
    vehicleData.fuelType = data.vehicleData.fuelType
    vehicleData.colorRGB = data.vehicleData.colorRGB
    vehicleData.isExotic = data.vehicleData.isExotic
    vehicleData.transmission = data.vehicleData.transmission
    vehicleData.photoUrl = data.vehicleData.photoUrl
    vehicleData.zone = zone
    
    local vehicles = lib.callback.await('qb-occasions:server:getVehicles', false)
    local count = 0
    if vehicles then
        for _, v in ipairs(vehicles) do
            if v.zone == zone then
                count = count + 1
            end
        end
    end
    
    local spots = config.zones[zone].vehicleSpots
    if count >= #spots then
        return exports.qbx_core:Notify(locale('error.no_space_on_lot'), 'error', 3500)
    end
    
    targetSellSpot = spots[count + 1]
    pendingSellData = {
        price = data.price,
        vehicleData = vehicleData
    }
    
    sellSpotBlip = AddBlipForCoord(targetSellSpot.x, targetSellSpot.y, targetSellSpot.z)
    SetBlipSprite(sellSpotBlip, 615)
    SetBlipColour(sellSpotBlip, 2)
    SetBlipRoute(sellSpotBlip, true)
    SetBlipRouteColour(sellSpotBlip, 2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName("Vaga de Exposição")
    EndTextCommandSetBlipName(sellSpotBlip)
    
    exports.qbx_core:Notify("Dirija até a vaga demarcada no mapa para posicionar o veículo.", "primary", 6000)
    
    isPositioningVehicle = true
    
    CreateThread(function()
        local isShowingPrompt = false
        while isPositioningVehicle do
            local sleep = 500
            local ped = PlayerPedId()
            local veh = cache.vehicle
            
            if veh and veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                local coords = GetEntityCoords(veh)
                local dist = #(coords - targetSellSpot.xyz)
                
                if dist < 30.0 then
                    sleep = 0
                    
                    -- Get the actual ground height from collision to prevent floating markers
                    local success, groundZ = GetGroundZFor_3dCoord(targetSellSpot.x, targetSellSpot.y, targetSellSpot.z, false)
                    local markerZ = success and groundZ or (targetSellSpot.z - 0.95)
                    
                    -- Flat circle flat on the pavement
                    DrawMarker(27, targetSellSpot.x, targetSellSpot.y, markerZ + 0.05, 
                               0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                               3.0, 3.0, 1.0, 
                               46, 204, 113, 150, 
                               false, false, 2, false, nil, nil, false)
                               
                    -- Vertical cylinder starting at pavement and going 2m up
                    DrawMarker(1, targetSellSpot.x, targetSellSpot.y, markerZ, 
                               0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                               3.0, 3.0, 2.0, 
                               46, 204, 113, 80, 
                               false, false, 2, false, nil, nil, false)
                    
                    local dist2D = #(coords.xy - targetSellSpot.xy)
                    local distZ = math.abs(coords.z - markerZ)
                    
                    if dist2D < 2.0 and distZ < 2.0 then
                        if not isShowingPrompt then
                            lib.showTextUI("Pressione [E] para colocar o carro à venda", {position = 'right-center'})
                            isShowingPrompt = true
                        end
                        
                        if IsControlJustReleased(0, 38) then
                            isShowingPrompt = false
                            lib.hideTextUI()
                            completeVehicleSale()
                            break
                        end
                    else
                        if isShowingPrompt then
                            lib.hideTextUI()
                            isShowingPrompt = false
                        end
                    end
                else
                    if isShowingPrompt then
                        lib.hideTextUI()
                        isShowingPrompt = false
                    end
                end
            else
                if isShowingPrompt then
                    lib.hideTextUI()
                    isShowingPrompt = false
                end
                cancelVehicleSale("Você saiu do veículo. A venda foi cancelada.")
                break
            end
            Wait(sleep)
        end
        if isShowingPrompt then
            lib.hideTextUI()
        end
    end)
end

local function spawnSellPed(zoneName)
    local cfg = config.zones[zoneName]
    if not cfg or not cfg.pedModel then return end

    if spawnedPeds[zoneName] then return end

    local model = joaat(cfg.pedModel)
    lib.requestModel(model)

    local coords = cfg.sellVehicle
    -- Spawn the ped. Subtract 1.0 from z to align with the ground.
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
    
    SetPedDefaultComponentVariation(ped)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(model)

    spawnedPeds[zoneName] = ped

    -- Handle animation
    if cfg.pedAnimDict and cfg.pedAnimName then
        lib.requestAnimDict(cfg.pedAnimDict)
        TaskPlayAnim(ped, cfg.pedAnimDict, cfg.pedAnimName, 8.0, -8.0, -1, 49, 0, false, false, false)
        RemoveAnimDict(cfg.pedAnimDict)
    end

    -- Handle prop (e.g. tablet)
    if cfg.pedProp then
        local propModel = joaat(cfg.pedProp)
        lib.requestModel(propModel)
        
        local prop = CreateObject(propModel, coords.x, coords.y, coords.z, false, false, false)
        -- Attach to Left Hand (Bone 60309) for standard tablet holding animation
        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 60309), 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, true, false, true, 2, true)
        SetModelAsNoLongerNeeded(propModel)
        
        spawnedProps[zoneName] = prop
    end

    -- Add target option
    exports.ox_target:addLocalEntity(ped, {
        {
            icon = 'fas fa-handshake',
            label = locale('menu.sell_vehicle'),
            onSelect = function()
                if cache.vehicle then
                    TriggerEvent('qb-occasions:client:MainMenu')
                else
                    exports.qbx_core:Notify(locale('error.not_in_veh'), 'error', 4500)
                end
            end,
            distance = 3.0
        }
    })
end

local function deleteSellPed(zoneName)
    if spawnedPeds[zoneName] then
        exports.ox_target:removeLocalEntity(spawnedPeds[zoneName], locale('menu.sell_vehicle'))
        DeleteEntity(spawnedPeds[zoneName])
        spawnedPeds[zoneName] = nil
    end

    if spawnedProps[zoneName] then
        DeleteEntity(spawnedProps[zoneName])
        spawnedProps[zoneName] = nil
    end
end

local function createZones()
    for k, v in pairs(config.zones) do

        local SellSpot = lib.zones.poly({
            name = k,
            points = v.polyzone,
            thickness = 50,
            debug = config.debug,
            onEnter = function(self)
                zone = self.name
                -- Acquire the zone lock before any await so that a concurrent
                -- refreshVehicles event cannot start a second spawn cycle while
                -- lib.requestModel yields inside spawnOccasionsVehicles.
                acquireZoneLock()
                local vehicles = lib.callback.await('qb-occasions:server:getVehicles', false)
                -- Re-check zone: player might have exited during the await
                if zone == self.name then
                    despawnOccasionsVehicles()
                    spawnOccasionsVehicles(vehicles)
                end
                releaseZoneLock()
                spawnSellPed(self.name)
                spawnDebugVehicles(self.name)
            end,
            onExit = function()
                if isPositioningVehicle then
                    cancelVehicleSale("Você se afastou da concessionária. A venda foi cancelada.")
                end
                -- Force-release the lock: if the player exits while a spawn is
                -- mid-execution (e.g. during lib.requestModel), we must unblock
                -- other waiters rather than leaving them stuck.
                vehicleZoneLock = false
                deleteSellPed(zone)
                despawnDebugVehicles(zone)
                despawnOccasionsVehicles()
                zone = nil
            end,
        })
        
        activeZone[k] = SellSpot
    end
end

local function deleteZones()
    for k in pairs(activeZone) do
        activeZone[k]:remove()
        deleteSellPed(k)
    end
    table.wipe(activeZone)
end

local function isCarSpawned(Car)
    if not zone or not occasionVehicles or not occasionVehicles[zone] then return false end
    return occasionVehicles[zone][Car] ~= nil
end

RegisterNUICallback('sellVehicle', function(data, cb)
    local plate = qbx.getVehiclePlate(cache.vehicle)
    sellData(data, plate)
    SetNuiFocus(false, false)
    cb('ok')
end)

local cameraActive = false

RegisterNUICallback('startVehicleCamera', function(_, cb)
    local ped = PlayerPedId()
    local veh = cache.vehicle
    if not veh or veh == 0 then
        exports.qbx_core:Notify("Você não está em um veículo!", "error")
        SendNUIMessage({ action = 'showTabletAfterPhoto' })
        SetNuiFocus(true, true)
        cb('ok')
        return
    end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'openCameraOverlay' })
    
    Wait(500)

    cameraActive = true
    FreezeEntityPosition(veh, true) -- Freeze vehicle position
    
    local radius = 6.0
    local angleX = 0.0 -- horizontal orbit angle around car
    local angleY = 15.0 -- vertical orbit pitch
    local fov = 50.0
    
    local dict = "anim@mp_player_intselfiethumbs_up"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(ped, dict, "idle_a", 8.0, 8.0, -1, 49, 0, false, false, false)
    
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    HideHudAndRadarThisFrame()
    
    local customCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamFov(customCam, fov)
    SetCamActive(customCam, true)
    RenderScriptCams(true, false, 0, true, false)

    CreateThread(function()
        while cameraActive do
            Wait(0)
            
            HideHudComponentThisFrame(1)
            HideHudAndRadarThisFrame()
            DisableFrontendThisFrame() -- Disable GTA pause/frontend menu this frame
            
            -- Block standard look / attack inputs
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 177, true) -- Esc / Cancel / Backspace
            DisableControlAction(0, 202, true) -- Cancel / Backspace
            DisableControlAction(0, 38, true)  -- E key
            
            -- Block exiting the vehicle
            DisableControlAction(0, 75, true) -- INPUT_VEH_EXIT
            
            -- Block vehicle movement / controls
            DisableControlAction(0, 71, true) -- Accelerate
            DisableControlAction(0, 72, true) -- Brake/Reverse
            DisableControlAction(0, 59, true) -- Steering
            DisableControlAction(0, 60, true) -- Steering UD
            DisableControlAction(0, 76, true) -- Handbrake
            
            -- Read mouse raw inputs
            local rightAxisX = GetDisabledControlNormal(0, 220)
            local rightAxisY = GetDisabledControlNormal(0, 221)
            
            -- Orbit angles update
            angleX = angleX + rightAxisX * -8.0
            angleY = math.max(math.min(angleY + rightAxisY * 8.0, 80.0), -5.0)
            
            -- Radius Zoom (Scroll wheel)
            if IsDisabledControlJustPressed(0, 241) or IsControlJustPressed(0, 241) then -- Scroll Up
                radius = math.max(radius - 0.4, 3.0)
            end
            if IsDisabledControlJustPressed(0, 242) or IsControlJustPressed(0, 242) then -- Scroll Down
                radius = math.min(radius + 0.4, 10.0)
            end
            
            -- Calculate polar position relative to vehicle
            local radX = math.rad(angleX)
            local radY = math.rad(angleY)
            local xOffset = radius * math.cos(radY) * math.sin(radX)
            local yOffset = radius * math.cos(radY) * math.cos(radX)
            local zOffset = radius * math.sin(radY) + 0.5
            
            local camCoords = GetOffsetFromEntityInWorldCoords(veh, xOffset, yOffset, zOffset)
            SetCamCoord(customCam, camCoords.x, camCoords.y, camCoords.z)
            PointCamAtEntity(customCam, veh, 0.0, 0.0, 0.2, true)
            
            if IsDisabledControlJustPressed(0, 38) or IsControlJustPressed(0, 38) then -- E
                cameraActive = false
                exports.qbx_core:Notify("Enviando foto...", "primary")
                
                Wait(200) -- delay for clean frame
                
                exports['screenshot-basic']:requestScreenshotUpload(config.FiveManageEndpoint, "file", {
                    headers = {
                        ["Authorization"] = config.FiveManageToken
                    }
                }, function(res)
                    RenderScriptCams(false, false, 0, true, false)
                    DestroyCam(customCam, false)
                    ClearPedTasks(ped)
                    FreezeEntityPosition(veh, false) -- Unfreeze vehicle position
                    Wait(100)
 
                    local response = json.decode(res)
                    if response and response.data and response.data.url then
                        local imageUrl = response.data.url
                        exports.qbx_core:Notify("Foto enviada com sucesso!", "success")
                        SendNUIMessage({ 
                            action = 'showTabletAfterPhoto', 
                            url = imageUrl 
                        })
                    else
                        print("^1[newage_vehiclesales]^7 Falha no upload:", res)
                        exports.qbx_core:Notify("Erro ao enviar foto. Tente novamente.", "error")
                        SendNUIMessage({ action = 'showTabletAfterPhoto' })
                    end
                    SetNuiFocus(true, true)
                end)
            elseif IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 202) or IsControlJustPressed(0, 177) or IsControlJustPressed(0, 202) then -- ESC / Backspace
                cameraActive = false
                
                -- Swallow pause menu inputs for the next 15 frames to consume residual key release events
                CreateThread(function()
                    for i = 1, 15 do
                        DisableControlAction(0, 177, true)
                        DisableControlAction(0, 202, true)
                        DisableControlAction(0, 199, true)
                        DisableControlAction(0, 200, true)
                        DisableFrontendThisFrame()
                        Wait(0)
                    end
                end)

                RenderScriptCams(false, false, 0, true, false)
                DestroyCam(customCam, false)
                ClearPedTasks(ped)
                FreezeEntityPosition(veh, false) -- Unfreeze vehicle position
                Wait(100)
                SendNUIMessage({ action = 'showTabletAfterPhoto' })
                SetNuiFocus(true, true)
            end
        end
    end)
    cb('ok')
end)

RegisterNUICallback('selectSell', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
    TriggerEvent('qb-vehiclesales:client:SellVehicle')
end)

RegisterNUICallback('selectSellBack', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
    TriggerEvent('qb-occasions:client:SellBackCar')
end)

RegisterNUICallback('cancelSale', function(data, cb)
    local foundLoc = nil
    if zone and occasionVehicles[zone] then
        for i = 1, #occasionVehicles[zone] do
            local oVeh = occasionVehicles[zone][i]
            if oVeh and oVeh.plate == data.plate then
                foundLoc = oVeh.loc
                break
            end
        end
    end
    
    if foundLoc then
        data.loc = foundLoc
    end

    TriggerServerEvent('qb-occasions:server:ReturnVehicle', data)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('selectHistory', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
    openHistoryTablet(true, zone)
end)

RegisterNUICallback('deleteHistoryRecord', function(data, cb)
    TriggerServerEvent('qbx_vehiclesales:server:deleteHistoryRecord', data.id)
    cb('ok')
end)

local currentBusyPlate = nil

RegisterNUICallback('close', function(_, cb)
    if currentBusyPlate then
        lib.callback.await('qbx_vehiclesales:server:setVehicleBusy', false, currentBusyPlate, false)
        currentBusyPlate = nil
    end
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buyVehicle', function(_, cb)
    SetNuiFocus(false, false)
    if currentBusyPlate then
        lib.callback.await('qbx_vehiclesales:server:setVehicleBusy', false, currentBusyPlate, false)
        currentBusyPlate = nil
    end
    TriggerServerEvent('qb-occasions:server:buyVehicle', currentVehicle)
    cb('ok')
end)

RegisterNUICallback('takeVehicleBack', function(_, cb)
    -- Pass loc so the server can relay the spawn position back to this client
    local data = currentVehicle
    if zone and occasionVehicles[zone] then
        for i = 1, #occasionVehicles[zone] do
            local oVeh = occasionVehicles[zone][i]
            if oVeh and oVeh.plate == currentVehicle.plate then
                data = table.clone and table.clone(currentVehicle) or {}
                for k, v in pairs(currentVehicle) do data[k] = v end
                data.loc = oVeh.loc
                break
            end
        end
    end
    TriggerServerEvent('qb-occasions:server:ReturnVehicle', data)
    cb('ok')
end)

-- Shared helper: spawn a networked vehicle at the display slot coords after purchase or return.
-- Holds vehicleZoneLock for its entire duration so that refreshVehicles (broadcast to ALL
-- clients by the server) cannot run a conflicting despawn+spawn on the buying player's client
-- while this coroutine is suspended waiting for the spawn callback or collision load.
local function spawnNetworkedVehicleAtSlot(vehData, spawnCoords, notifyKey)
    acquireZoneLock()

    -- Synchronously remove the local display entity for this plate.
    -- Entry is nil'd in occasionVehicles BEFORE deletion (see deleteDisplayVehicleByPlate)
    -- so the pairs loop in despawnOccasionsVehicles skips it and cannot double-delete.
    deleteDisplayVehicleByPlate(vehData.plate)

    local targetZone = vehData.zone or zone
    local coords = spawnCoords
    if not coords then
        coords = (targetZone and config.zones[targetZone]) and config.zones[targetZone].buyVehicle or vec4(1213.31, 2735.4, 38.27, 182.5)
    end

    local netId = lib.callback.await('qbx_vehiclesales:server:spawnVehicle', false, vehData, coords, true)
    if not netId then
        releaseZoneLock()
        exports.qbx_core:Notify("Erro ao spawnar veículo. Contacte um administrador.", 'error', 4000)
        return
    end

    -- Wait for the entity to replicate to this client (max 1 s)
    local timeout = 100
    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout > 0 do
        Wait(10)
        timeout -= 1
    end

    local veh = NetToVeh(netId)
    if not veh or veh == 0 then
        releaseZoneLock()
        exports.qbx_core:Notify("Veículo não encontrado após spawn.", 'error', 4000)
        return
    end

    -- Place and align the vehicle at the exact slot position
    FreezeEntityPosition(veh, true)
    SetEntityCoords(veh, coords.x, coords.y, coords.z + 0.5, false, false, false, false)
    SetEntityHeading(veh, coords.w)
    SetVehicleFuelLevel(veh, 100)

    -- Wait for surrounding collision to load before grounding (avoids falling through floor)
    local collisionTimeout = 3000
    while not HasCollisionLoadedAroundEntity(veh) and collisionTimeout > 0 do
        Wait(100)
        collisionTimeout -= 100
    end

    SetVehicleOnGroundProperly(veh)
    Wait(50)
    SetVehicleOnGroundProperly(veh)

    SetVehicleFixed(veh)
    SetVehicleUndriveable(veh, false)
    SetVehicleDoorsLocked(veh, 1) -- unlocked
    FreezeEntityPosition(veh, false)
    Wait(0)
    SetVehicleHandbrake(veh, false)

    -- Release lock BEFORE the notification so refreshVehicles can proceed immediately
    releaseZoneLock()

    exports.qbx_core:Notify(locale(notifyKey or 'success.vehicle_bought'), 'success', 2500)
    return veh
end

RegisterNetEvent('qb-occasions:client:BuyFinished', function(vehData, spawnCoords)
    local veh = spawnNetworkedVehicleAtSlot(vehData, spawnCoords, 'success.vehicle_bought')
    currentVehicle = {}
end)

AddEventHandler('qb-occasions:client:SellBackCar', function()
    if cache.vehicle then
        local vehicleData = {}
        vehicleData.model = GetEntityModel(cache.vehicle)
        vehicleData.plate = GetVehicleNumberPlateText(cache.vehicle)
        local owned, balance = lib.callback.await('qbx_vehiclesales:server:checkVehicleOwner', false, vehicleData.plate)
        if owned then
            if not balance or balance < 1 then
                TriggerServerEvent('qb-occasions:server:sellVehicleBack', vehicleData)
                -- Use safe deletion to avoid streaming/prop-disappearance bug
                DeleteDisplayVehicle(cache.vehicle)
            else
                exports.qbx_core:Notify(locale('error.finish_payments'), 'error', 3500)
            end
        else
            exports.qbx_core:Notify(locale('error.not_your_vehicle'), 'error', 3500)
        end
    else
        exports.qbx_core:Notify(locale('error.not_in_veh'), 'error', 4500)
    end
end)

RegisterNetEvent('qb-occasions:client:ReturnOwnedVehicle', function(vehData, spawnCoords)
    local veh = spawnNetworkedVehicleAtSlot(vehData, spawnCoords, 'success.vehicle_returned')
    if not veh then
        currentVehicle = {}
        return
    end

    -- Optional locator: 3D outline + overhead chevron arrow so the player can find the car easily
    if config.showLocatorLine then
        CreateThread(function()
            local lineTimeout = 15000 -- 15 segundos

            if DoesEntityExist(veh) then
                SetEntityDrawOutlineColor(46, 204, 113, 200)
                SetEntityDrawOutlineShader(1)
                SetEntityDrawOutline(veh, true)
            end

            while lineTimeout > 0 and DoesEntityExist(veh) do
                Wait(0)
                lineTimeout = lineTimeout - (GetFrameTime() * 1000)

                -- Stop drawing once the player enters the vehicle
                if cache.vehicle == veh then break end

                local vCoords = GetEntityCoords(veh)
                -- Downward chevron arrow hovering above the car roof
                DrawMarker(0, vCoords.x, vCoords.y, vCoords.z + 2.0,
                           0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                           0.5, 0.5, 0.5,
                           46, 204, 113, 180,
                           true, true, 2, false, nil, nil, false)
            end

            if DoesEntityExist(veh) then
                SetEntityDrawOutline(veh, false)
            end
        end)
    end

    currentVehicle = {}
end)

RegisterNetEvent('qb-occasion:client:refreshVehicles', function()
    if not zone then return end

    -- acquireZoneLock blocks until the zone lock is free.
    -- This handles ALL of the following concurrent scenarios:
    --   • Another refreshVehicles is already despawn+spawning
    --   • zone onEnter is mid-spawn (suspended at lib.requestModel)
    --   • spawnNetworkedVehicleAtSlot (buy/return) is mid-execution
    -- Without this lock all three could interleave their Wait() yields and
    -- create multiple overlapping sets of display entities (mass duplication).
    acquireZoneLock()

    if not zone then
        -- Player exited the zone while we were waiting for the lock
        releaseZoneLock()
        return
    end

    local vehicles = lib.callback.await('qb-occasions:server:getVehicles')
    if zone then -- recheck after await
        despawnOccasionsVehicles()
        spawnOccasionsVehicles(vehicles)
    end

    releaseZoneLock()
end)

AddEventHandler('qb-vehiclesales:client:SellVehicle', function()
    local VehiclePlate = qbx.getVehiclePlate(cache.vehicle)
    local owned, balance = lib.callback.await('qbx_vehiclesales:server:checkVehicleOwner', false, VehiclePlate)

    if not owned then
        return exports.qbx_core:Notify(locale('error.not_your_vehicle'), 'error', 3500)
    end

    if balance and balance > 0 then
        return exports.qbx_core:Notify(locale('error.finish_payments'), 'error', 3500)
    end

    local vehicles = lib.callback.await('qb-occasions:server:getVehicles', false)
    if not vehicles or #vehicles < #config.zones[zone].vehicleSpots then
        openSellContract(true)
    else
        exports.qbx_core:Notify(locale('error.no_space_on_lot'), 'error', 3500)
    end
end)

AddEventHandler('qb-vehiclesales:client:OpenContract', function(contract)
    currentVehicle = occasionVehicles[zone][contract]
    if not currentVehicle then
        exports.qbx_core:Notify(locale('error.not_for_sale'), 'error', 7500)
        return
    end

    local isAvailable = lib.callback.await('qbx_vehiclesales:server:setVehicleBusy', false, currentVehicle.plate, true)
    if not isAvailable then
        exports.qbx_core:Notify('Este contrato já está sendo analisado por outro interessado.', 'error', 3500)
        return
    end

    currentBusyPlate = currentVehicle.plate

    local info = lib.callback.await('qb-occasions:server:getSellerInformation', false, currentVehicle.owner)
    if info then
        info.charinfo = json.decode(info.charinfo)
    else
        info = {}
        info.charinfo = {
            firstname = locale('charinfo.firstname'),
            lastname = locale('charinfo.lastname'),
            account = locale('charinfo.account'),
            phone = locale('charinfo.phone')
        }
    end

    openBuyContract(info, currentVehicle)
end)

AddEventHandler('qb-occasions:client:MainMenu', function()
    openMainMenu(true)
end)

CreateThread(function()
    for k, cars in pairs(config.zones) do
        if not config.useTarget then
            for k2, v in pairs(config.zones[k].vehicleSpots) do
                lib.zones.box({
                    coords = vec3(v.x, v.y, v.z),
                    size = vec3(4.0, 5.0, 3.0),
                    rotation = 0,
                    debug = config.debug,
                    onEnter = function()
                        if isCarSpawned(k2) then
                            lib.showTextUI(locale('menu.view_contract_int'), {position = 'right-center'})
                        end
                    end,
                    onExit = function()
                        lib.hideTextUI()
                    end,
                    inside = function()
                        if IsControlJustReleased(0, 38) then
                            TriggerEvent('qb-vehiclesales:client:OpenContract', k2)
                        end
                    end
                })
            end
        end

        local occasionBlip = AddBlipForCoord(cars.sellVehicle.x, cars.sellVehicle.y, cars.sellVehicle.z)
        SetBlipSprite(occasionBlip, 326)
        SetBlipDisplay(occasionBlip, 4)
        SetBlipScale(occasionBlip, 0.75)
        SetBlipAsShortRange(occasionBlip, true)
        SetBlipColour(occasionBlip, 3)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(locale('info.used_vehicle_lot'))
        EndTextCommandSetBlipName(occasionBlip)
    end
end)

CreateThread(function()
    if not config.debug then return end

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for k, v in pairs(config.zones) do
            if #(coords - vec3(v.sellVehicle.x, v.sellVehicle.y, v.sellVehicle.z)) < 50.0 then
                sleep = 0
                -- Draw sell vehicle spot
                DrawMarker(2, v.sellVehicle.x, v.sellVehicle.y, v.sellVehicle.z + 0.3, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.4, 0.4, 0.4, 255, 0, 0, 150, false, true, 2, false, nil, nil, false)
            end
        end

        Wait(sleep)
    end
end)

local historyPeds = {}
local historyProps = {}
local historyZones = {}
local function cleanupHistoryLocations()
    for i = 1, #historyPeds do
        if DoesEntityExist(historyPeds[i]) then
            exports.ox_target:removeLocalEntity(historyPeds[i], 'Acessar Histórico e Anúncios')
            DeleteEntity(historyPeds[i])
        end
    end
    table.wipe(historyPeds)

    for i = 1, #historyProps do
        if DoesEntityExist(historyProps[i]) then
            DeleteEntity(historyProps[i])
        end
    end
    table.wipe(historyProps)

    for i = 1, #historyZones do
        exports.ox_target:removeZone(historyZones[i])
    end
    table.wipe(historyZones)
end

local function setupHistoryLocations()
    cleanupHistoryLocations()
    if not config.zones then return end

    for zoneId, zoneData in pairs(config.zones) do
        local loc = zoneData.historyLocation
        if loc then
            local label = loc.targetLabel or "Acessar Histórico e Anúncios"
            local icon = loc.targetIcon or "fas fa-history"
            local distance = loc.distance or 3.0

            if loc.usePed then
                local model = joaat(loc.pedModel or 's_m_m_autoshop_01')
                lib.requestModel(model)

                local coords = loc.coords
                local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)

                SetPedDefaultComponentVariation(ped)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                FreezeEntityPosition(ped, true)
                SetModelAsNoLongerNeeded(model)

                table.insert(historyPeds, ped)

                if loc.pedProp then
                    local propModel = joaat(loc.pedProp)
                    lib.requestModel(propModel)

                    local prop = CreateObject(propModel, coords.x, coords.y, coords.z, false, false, false)
                    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 60309), 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, true, false, true, 2, true)
                    SetModelAsNoLongerNeeded(propModel)

                    table.insert(historyProps, prop)
                end

                if loc.pedAnimDict and loc.pedAnimName then
                    lib.requestAnimDict(loc.pedAnimDict)
                    TaskPlayAnim(ped, loc.pedAnimDict, loc.pedAnimName, 8.0, -8.0, -1, 49, 0, false, false, false)
                    RemoveAnimDict(loc.pedAnimDict)
                end

                exports.ox_target:addLocalEntity(ped, {
                    {
                        icon = icon,
                        label = label,
                        onSelect = function()
                            openHistoryTablet(true, zoneId)
                        end,
                        distance = distance
                    }
                })
            else
                local targetZoneId = exports.ox_target:addBoxZone({
                    coords = vec3(loc.coords.x, loc.coords.y, loc.coords.z),
                    size = loc.size or vec3(1.5, 1.5, 2.0),
                    rotation = loc.coords.w or 0.0,
                    debug = false,
                    options = {
                        {
                            icon = icon,
                            label = label,
                            onSelect = function()
                                openHistoryTablet(true, zoneId)
                            end,
                            distance = distance
                        }
                    }
                })
                table.insert(historyZones, targetZoneId)
            end
        end
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createZones()
    setupHistoryLocations()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    deleteZones()
    cleanupHistoryLocations()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if cache.resource == resourceName then
        createZones()
        setupHistoryLocations()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if cache.resource == resourceName then
        cameraActive = false
        if isPositioningVehicle then
            cancelVehicleSale()
        end
        if cache.vehicle and cache.vehicle ~= 0 then
            FreezeEntityPosition(cache.vehicle, false)
        end
        deleteZones()
        cleanupHistoryLocations()
        if config.debug and zone then
            despawnDebugVehicles(zone)
        end
        despawnOccasionsVehicles()
    end
end)

RegisterCommand('minhasvendas', function()
    if QBX and QBX.PlayerData and QBX.PlayerData.charinfo then
        openHistoryTablet(true, zone) -- Defaulting to the current polyzone if they are inside one
    end
end, false)
