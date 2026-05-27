local config = require 'config.config'
local zone
local activeZone = {}
local currentVehicle = {}
local occasionVehicles = {}
local spawnedPeds = {}
local spawnedProps = {}
local debugVehicles = {}

-- ─────────────────────────────────────────────────────────────
-- Deformation helper – mirrors rhd_garage/modules/deformation.lua
-- so that we capture and replay dents using the exact same math.
-- ─────────────────────────────────────────────────────────────
local _Deformation = {}

local function _Round(value, n)
    return math.floor(value * 10^n) / 10^n
end

local function _GetVehicleOffsets(vehicle)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    local X     = _Round((max.x - min.x) * 0.5, 2)
    local Y     = _Round((max.y - min.y) * 0.5, 2)
    local Z     = _Round((max.z - min.z) * 0.5, 2)
    local halfY = _Round(Y * 0.5, 2)
    return {
        vector3(-X, Y, 0.0),    vector3(-X, Y, Z),
        vector3(0.0, Y, 0.0),   vector3(0.0, Y, Z),
        vector3(X, Y, 0.0),     vector3(X, Y, Z),
        vector3(-X, halfY, 0.0),  vector3(-X, halfY, Z),
        vector3(0.0, halfY, 0.0), vector3(0.0, halfY, Z),
        vector3(X, halfY, 0.0),   vector3(X, halfY, Z),
        vector3(-X, 0.0, 0.0),  vector3(-X, 0.0, Z),
        vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, Z),
        vector3(X, 0.0, 0.0),   vector3(X, 0.0, Z),
        vector3(-X, -halfY, 0.0),  vector3(-X, -halfY, Z),
        vector3(0.0, -halfY, 0.0), vector3(0.0, -halfY, Z),
        vector3(X, -halfY, 0.0),   vector3(X, -halfY, Z),
        vector3(-X, -Y, 0.0),   vector3(-X, -Y, Z),
        vector3(0.0, -Y, 0.0),  vector3(0.0, -Y, Z),
        vector3(X, -Y, 0.0),    vector3(X, -Y, Z),
    }
end

--- Reads the current deformation of a vehicle into a table
--- compatible with _Deformation.set (and rhd_garage Deformation.set).
_Deformation.get = function(vehicle)
    local data = {}
    for _, v in ipairs(_GetVehicleOffsets(vehicle)) do
        local dmg = math.floor(#(GetVehicleDeformationAtPos(vehicle, v.x, v.y, v.z)) * 1000.0) / 1000.0
        data[#data + 1] = { offset = { x = v.x, y = v.y, z = v.z }, damage = dmg }
    end
    return data
end

--- Applies a saved deformation table back onto a vehicle.
--- Must be called BEFORE FreezeEntityPosition so GTA physics can process it.
_Deformation.set = function(vehicle, deformation)
    if not deformation or not next(deformation) then return end
    local fMult = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fDeformationDamageMult")
    local damageMult = 20.0
    if     fMult <= 0.55 then damageMult = 1000.0
    elseif fMult <= 0.65 then damageMult = 400.0
    elseif fMult <= 0.75 then damageMult = 200.0
    end
    for _, v in pairs(deformation) do
        local o = v.offset
        local d = (v.damage or 0) * damageMult
        if d > 14.0 then d = 14.5 end
        if o and d > 0 then
            SetVehicleDamage(vehicle, o.x, o.y, o.z, d, 1000.0, true)
        end
    end
end
-- ─────────────────────────────────────────────────────────────


local isPositioningVehicle = false
local pendingSellData = nil
local targetSellSpot = nil
local sellSpotBlip = nil

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

local function DeleteGhostVehicle(plate, immediate)
    print("^2[newage_vehiclesales]^7 DeleteGhostVehicle called for plate:", plate)
    if not zone or not occasionVehicles[zone] then 
        print("^3[newage_vehiclesales]^7 DeleteGhostVehicle cancelled: zone or occasionVehicles[zone] is nil")
        return 
    end
    
    local slotData = occasionVehicles[zone][plate]
    if not slotData then
        print("^3[newage_vehiclesales]^7 DeleteGhostVehicle: no slotData for plate:", plate)
        return
    end

    local veh = slotData.car
    if not veh then
        print("^3[newage_vehiclesales]^7 DeleteGhostVehicle: no vehicle entity stored for plate:", plate)
        return
    end

    if not DoesEntityExist(veh) then
        print("^3[newage_vehiclesales]^7 DeleteGhostVehicle: stored vehicle entity does not exist for plate:", plate)
        occasionVehicles[zone][plate] = nil
        return
    end
    
    if slotData.hasTarget then
        exports.ox_target:removeLocalEntity(veh, locale('menu.view_contract'))
        slotData.hasTarget = false
    end
    
    occasionVehicles[zone][plate] = nil
    
    print("^2[newage_vehiclesales]^7 DeleteGhostVehicle: deleting local entity:", veh)
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
    DeleteEntity(veh)
end

local function teardownDisplayVehicles()
    if not zone then return end
    if occasionVehicles[zone] then
        for slot, data in pairs(occasionVehicles[zone]) do
            if data.plate then
                DeleteGhostVehicle(data.plate)
            end
        end
        occasionVehicles[zone] = nil
    end
end

local function setupDisplayVehicles(vDataList)
    print("^2[newage_vehiclesales]^7 setupDisplayVehicles called. List size:", vDataList and #vDataList or 0)
    if not zone then 
        print("^3[newage_vehiclesales]^7 setupDisplayVehicles: not inside a zone, skipping.")
        return 
    end
    if not occasionVehicles[zone] then occasionVehicles[zone] = {} end
    if not vDataList then return end

    local currentZone = zone
    local currentPlates = {}
    for slot, data in pairs(occasionVehicles[currentZone]) do
        if data.plate and data.car then
            currentPlates[data.plate] = true
            print("^2[newage_vehiclesales]^7 Existing plate in slot:", slot, "plate:", data.plate, "entity:", data.car)
        end
    end

    for i = 1, #vDataList do
        local v = vDataList[i]
        if v.zone == currentZone then
            local plate = v.plate
            print("^2[newage_vehiclesales]^7 Processing vehicle in list index:", i, "plate:", plate, "slotIndex:", v.slotIndex)
            
            if not occasionVehicles[currentZone][plate] then
                occasionVehicles[currentZone][plate] = {}
            end
            
            local slotData = occasionVehicles[currentZone][plate]
            slotData.loc       = v.loc
            slotData.price     = v.price
            slotData.owner     = v.owner
            slotData.model     = v.model
            slotData.plate     = v.plate
            slotData.oid       = v.oid
            slotData.desc      = v.desc
            slotData.mods      = v.mods
            slotData.fuelType  = v.fuelType
            slotData.colorRGB  = v.colorRGB
            slotData.isExotic  = v.isExotic
            slotData.transmission = v.transmission
            slotData.photo_url = v.photo_url
            slotData.mileage   = v.mileage
            slotData.vin       = v.vin
            slotData.damage    = v.damage
            slotData.engine    = v.engine
            slotData.body      = v.body
            slotData.fuel      = v.fuel
            
            currentPlates[plate] = false
            
            if not slotData.car or not DoesEntityExist(slotData.car) then
                print("^2[newage_vehiclesales]^7 SlotData.car does not exist or is nil for plate:", plate)
                if not slotData.isSpawning then
                    print("^2[newage_vehiclesales]^7 isSpawning is false, initiating thread to load model:", v.model)
                    slotData.isSpawning = true
                    CreateThread(function()
                        local model = joaat(v.model)
                        if lib.requestModel(model, 5000) then
                            print("^2[newage_vehiclesales]^7 Model loaded successfully:", v.model)
                            -- Confirm we are still in the same zone and slot wasn't cleared
                            if zone == currentZone and occasionVehicles[currentZone] and occasionVehicles[currentZone][plate] == slotData then
                                if not slotData.car or not DoesEntityExist(slotData.car) then
                                    local coords = v.loc
                                    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, false, false)
                                    print("^2[newage_vehiclesales]^7 CreateVehicle returned entity:", veh)
                                    SetVehicleNumberPlateText(veh, plate)
                                    
                                    if v.mods then
                                        local modTable = type(v.mods) == 'string' and json.decode(v.mods) or v.mods
                                        
                                        lib.setVehicleProperties(veh, modTable)
                                    end
                                    
                                    -- Apply engine/body health for display purposes
                                    SetVehicleEngineHealth(veh, (v.engine or 1000) + 0.0)
                                    SetVehicleBodyHealth(veh, (v.body or 1000) + 0.0)

                                    if v.damage then
                                        local dmgTable = type(v.damage) == 'string' and json.decode(v.damage) or v.damage
                                        if dmgTable and dmgTable.dirt then
                                            SetVehicleDirtLevel(veh, dmgTable.dirt)
                                        end
                                    end

                                    Wait(100)

                                    SetEntityInvincible(veh, true)
                                    SetVehicleDoorsLocked(veh, 2)
                                    FreezeEntityPosition(veh, true)
                                    SetVehicleEngineOn(veh, false, true, true)
                                    SetEntityCollision(veh, true, true)
                                    SetModelAsNoLongerNeeded(model)
                                    
                                    slotData.car = veh
                                    
                                    SetEntityAlpha(veh, 0, false)
                                    CreateThread(function()
                                        for alpha = 0, 255, 15 do
                                            if not DoesEntityExist(veh) then break end
                                            SetEntityAlpha(veh, math.min(alpha, 255), false)
                                            Wait(20)
                                        end
                                        if DoesEntityExist(veh) then ResetEntityAlpha(veh) end
                                    end)
                                    
                                    if config.useTarget then
                                        exports.ox_target:addLocalEntity(veh, {
                                            {
                                                icon = 'fas fa-car',
                                                label = locale('menu.view_contract'),
                                                onSelect = function()
                                                    TriggerEvent('qb-vehiclesales:client:OpenContract', plate)
                                                end,
                                                distance = 2.0
                                            }
                                        })
                                        slotData.hasTarget = true
                                    end
                                else
                                    print("^3[newage_vehiclesales]^7 SlotData.car already spawned after yield, skipping.")
                                    SetModelAsNoLongerNeeded(model)
                                end
                            else
                                print("^3[newage_vehiclesales]^7 Zone changed or slotData mismatch after yield, cancelling spawn.")
                                SetModelAsNoLongerNeeded(model)
                            end
                        else
                            print("^3[newage_vehiclesales]^7 Failed to load model:", v.model)
                            SetModelAsNoLongerNeeded(model)
                        end
                        slotData.isSpawning = false
                    end)
                else
                    print("^2[newage_vehiclesales]^7 isSpawning is already true, skipping thread spawn.")
                end
            else
                print("^2[newage_vehiclesales]^7 SlotData.car already exists:", slotData.car, "for plate:", plate)
            end
        end
    end
    
    for slot, data in pairs(occasionVehicles[currentZone] or {}) do
        if data.plate and currentPlates[data.plate] == true then
            print("^2[newage_vehiclesales]^7 Cleaning up obsolete vehicle:", data.plate, "in slot:", slot)
            DeleteGhostVehicle(data.plate)
            occasionVehicles[currentZone][slot] = nil
        end
    end
end

RegisterNetEvent('qb-occasion:client:syncDisplayVehicles', function(syncZone, vDataList)
    if zone == syncZone then
        CreateThread(function()
            while isProcessingVehicleAction do
                Wait(100)
            end
            setupDisplayVehicles(vDataList)
        end)
    end
end)

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
        allowImageUrl = config.allowImageUrl,
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

        -- Fallback: use the mileage saved in the vitrine DB when the car was listed
        if not mileage and vehicleData.mileage then
            mileage = MileageBridge.formatMileage(tonumber(vehicleData.mileage))
        end
        
        -- Final fallback: server-side callback
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
    local oldVehNetId = nil
    if veh and veh ~= 0 then
        oldVehNetId = VehToNet(veh)
        TaskLeaveVehicle(PlayerPedId(), veh, 0)
        local timeout = 50
        while IsPedInAnyVehicle(PlayerPedId(), false) and timeout > 0 do
            Wait(100)
            timeout = timeout - 1
        end
    end
    TriggerServerEvent('qb-occasions:server:sellVehicle', price, vehicleData, oldVehNetId)

    exports.qbx_core:Notify((locale('success.car_up_for_sale'):format(config.currencySymbol or "R$", price)), 'success')
    
    -- Give time for the server to network the DeleteEntity before allowing the ghost vehicle to spawn
    -- Without this, the ghost vehicle spawns inside the old vehicle and gets physics-launched into oblivion if parked crooked.
    Wait(2000)
    isProcessingVehicleAction = false
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
    if vehicleData.mods then
        -- We keep the damage state so the buyer receives it exactly as it was.
        -- We no longer strip damage here.
    end
    vehicleData.desc = data.desc
    -- New fields from NUI tablet
    vehicleData.fuelType = data.vehicleData.fuelType
    vehicleData.colorRGB = data.vehicleData.colorRGB
    vehicleData.isExotic = data.vehicleData.isExotic
    vehicleData.transmission = data.vehicleData.transmission
    vehicleData.photoUrl = data.vehicleData.photoUrl
    vehicleData.zone = zone
    
    local stateMileage = Entity(vehicleData.ent).state.vehicleMileage
    if stateMileage then
        vehicleData.mileage = tonumber(stateMileage)
    end
    
    vehicleData.engine = GetVehicleEngineHealth(vehicleData.ent)
    vehicleData.body = GetVehicleBodyHealth(vehicleData.ent)
    vehicleData.fuel = GetVehicleFuelLevel(vehicleData.ent)
    -- Capture deformation using the same system as rhd_garage so we can replay it faithfully on the preview vehicle
    vehicleData.damage = json.encode(_Deformation.get(vehicleData.ent))
    
    local vehicles = lib.callback.await('qb-occasions:server:getVehicles', false)
    local count = 0
    local occupiedSpots = {}
    if vehicles then
        for _, v in ipairs(vehicles) do
            if v.zone == zone then
                count = count + 1
                if v.spot_index then
                    occupiedSpots[v.spot_index] = true
                end
            end
        end
    end
    
    local spots = config.zones[zone].vehicleSpots
    if count >= #spots then
        return exports.qbx_core:Notify(locale('error.no_space_on_lot'), 'error', 3500)
    end
    
    local freeSpotIndex = 1
    for s = 1, #spots do
        if not occupiedSpots[s] then
            freeSpotIndex = s
            break
        end
    end
    
    targetSellSpot = spots[freeSpotIndex]
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
        local promptState = nil
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
                        local isStopped = GetEntitySpeed(veh) < 0.5
                        if isStopped then
                            if promptState ~= 'ready' then
                                lib.showTextUI("Pressione [E] para colocar o carro à venda", {position = 'right-center'})
                                promptState = 'ready'
                            end
                            
                            if IsControlJustReleased(0, 38) then
                                promptState = nil
                                lib.hideTextUI()
                                completeVehicleSale()
                                break
                            end
                        else
                            if promptState ~= 'moving' then
                                lib.showTextUI("Pare completamente o veículo", {position = 'right-center'})
                                promptState = 'moving'
                            end
                        end
                    else
                        if promptState then
                            lib.hideTextUI()
                            promptState = nil
                        end
                    end
                else
                    if promptState then
                        lib.hideTextUI()
                        promptState = nil
                    end
                end
            else
                if promptState then
                    lib.hideTextUI()
                    promptState = nil
                end
                cancelVehicleSale("Você saiu do veículo. A venda foi cancelada.")
                break
            end
            Wait(sleep)
        end
        if promptState then
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
                local displayVehicles = lib.callback.await('qb-occasions:server:getDisplayVehicles', false, self.name)
                if zone == self.name then
                    setupDisplayVehicles(displayVehicles)
                end
                spawnSellPed(self.name)
                spawnDebugVehicles(self.name)
            end,
            onExit = function()
                if isPositioningVehicle then
                    cancelVehicleSale("Você se afastou da concessionária. A venda foi cancelada.")
                end
                deleteSellPed(zone)
                despawnDebugVehicles(zone)
                teardownDisplayVehicles()
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
    return occasionVehicles[zone][Car] ~= nil and occasionVehicles[zone][Car].car ~= nil and DoesEntityExist(occasionVehicles[zone][Car].car)
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
        for _, oVeh in pairs(occasionVehicles[zone]) do
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

RegisterNUICallback('buyVehicle', function(data, cb)
    SetNuiFocus(false, false)
    if currentBusyPlate then
        lib.callback.await('qbx_vehiclesales:server:setVehicleBusy', false, currentBusyPlate, false)
        currentBusyPlate = nil
    end
    TriggerServerEvent('qb-occasions:server:buyVehicle', currentVehicle, data.paymentMethod)
    cb('ok')
end)

RegisterNUICallback('takeVehicleBack', function(_, cb)
    -- Pass loc so the server can relay the spawn position back to this client
    local data = currentVehicle
    if zone and occasionVehicles[zone] then
        for _, oVeh in pairs(occasionVehicles[zone]) do
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
local function spawnNetworkedVehicleAtSlot(vehData, spawnCoords, notifyKey)
    DeleteGhostVehicle(vehData.plate, true)
    Wait(300)

    local targetZone = vehData.zone or zone
    local coords = spawnCoords
    if not coords then
        coords = (targetZone and config.zones[targetZone]) and config.zones[targetZone].buyVehicle or vec4(1213.31, 2735.4, 38.27, 182.5)
    end

    local netId = lib.callback.await('qbx_vehiclesales:server:spawnVehicle', false, vehData, coords, false)
    if not netId then
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

    SetVehicleUndriveable(veh, false)
    SetVehicleDoorsLocked(veh, 1) -- unlocked
    FreezeEntityPosition(veh, false)
    Wait(0)
    
    SetVehicleHandbrake(veh, false)

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
                local oldVehNetId = VehToNet(cache.vehicle)
                TriggerServerEvent('qb-occasions:server:sellVehicleBack', vehicleData, oldVehNetId)
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
        teardownDisplayVehicles()
    end
end)

RegisterCommand('minhasvendas', function()
    if QBX and QBX.PlayerData and QBX.PlayerData.charinfo then
        openHistoryTablet(true, zone) -- Defaulting to the current polyzone if they are inside one
    end
end, false)
