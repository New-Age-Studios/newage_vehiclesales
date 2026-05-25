local config = require 'config.config'
local zone
local activeZone = {}
local currentVehicle = {}
local entityZones = {}
local occasionVehicles = {}
local spawnedPeds = {}
local spawnedProps = {}

local function spawnOccasionsVehicles(vehicles)
    if zone then
        local oSlot = config.zones[zone].vehicleSpots
        if not occasionVehicles[zone] then occasionVehicles[zone] = {} end
        if vehicles then
            for i = 1, #vehicles, 1 do
                local model = joaat(vehicles[i].model)
                lib.requestModel(model)
                occasionVehicles[zone][i] = {
                    car = CreateVehicle(model, oSlot[i].x, oSlot[i].y, oSlot[i].z, false, false),
                    loc = vector3(oSlot[i].x, oSlot[i].y, oSlot[i].z),
                    price = vehicles[i].price,
                    owner = vehicles[i].seller,
                    model = vehicles[i].model,
                    plate = vehicles[i].plate,
                    oid = vehicles[i].occasionid,
                    desc = vehicles[i].description,
                    mods = vehicles[i].mods,
                    fuelType = vehicles[i].fuel_type,
                    colorRGB = vehicles[i].color_rgb,
                    isExotic = vehicles[i].is_exotic,
                    transmission = vehicles[i].transmission,
                    photo_url = vehicles[i].photo_url
                }

                lib.setVehicleProperties(occasionVehicles[zone][i].car, json.decode(vehicles[i].mods))

                SetModelAsNoLongerNeeded(model)
                SetVehicleOnGroundProperly(occasionVehicles[zone][i].car)
                SetEntityInvincible(occasionVehicles[zone][i].car,true)
                SetEntityHeading(occasionVehicles[zone][i].car, oSlot[i].w)
                SetVehicleDoorsLocked(occasionVehicles[zone][i].car, 3)
                SetVehicleNumberPlateText(occasionVehicles[zone][i].car, occasionVehicles[zone][i].plate)
                FreezeEntityPosition(occasionVehicles[zone][i].car,true)
                if config.useTarget then
                    if not entityZones then entityZones = {} end
                    entityZones[i] = exports.ox_target:addLocalEntity(occasionVehicles[zone][i].car, {
                        {
                            icon = 'fas fa-car',
                            label = locale('menu.view_contract'),
                            onSelect = function()
                                TriggerEvent('qb-vehiclesales:client:OpenContract', i)
                            end,
                            distance = 2.0
                        }
                    })
                end
            end
        end
    end
end

local function despawnOccasionsVehicles()
    if not zone then return end
    local oSlot = config.zones[zone].vehicleSpots
    for i = 1, #oSlot, 1 do
        local loc = oSlot[i]
        local oldVehicle = GetClosestVehicle(loc.x, loc.y, loc.z, 1.3, 0, 70)
        if oldVehicle then
            DeleteVehicle(oldVehicle)
        end

        if entityZones[i] and config.useTarget then
            exports.ox_target:removeLocalEntity(occasionVehicles[zone][i].car, locale('menu.view_contract'))
        end
    end
    table.wipe(entityZones)
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
        bizName = config.zones[zone].businessName,
        enableSellBack = config.enableSellBack ~= false,
        options = {
            sell = {
                title = locale('menu.sell_vehicle'),
                desc = locale('menu.sell_vehicle_help')
            },
            sellBack = {
                title = locale('menu.sell_back'),
                desc = locale('menu.sell_back_help')
            }
        },
        vehicleData = vehicleData
    })
end

local function openHistoryTablet(bool)
    if not bool then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        return
    end

    local active, sold = lib.callback.await('qbx_vehiclesales:server:getPlayerSalesHistory', false)

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
        bizName = zone and config.zones[zone].businessName or "Concessionária de Usados",
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

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'sellVehicle',
        bizName = config.zones[zone].businessName,
        dealerFee = config.dealerFee or 0,
        sellerData = {
            firstname = QBX.PlayerData.charinfo.firstname,
            lastname = QBX.PlayerData.charinfo.lastname,
            account = QBX.PlayerData.charinfo.account,
            phone = QBX.PlayerData.charinfo.phone
        },
        vehicleData = {
            model = GetDisplayNameFromVehicleModel(GetEntityModel(veh)):lower(),
            plate = qbx.getVehiclePlate(veh),
            fuel = math.floor(GetVehicleFuelLevel(veh)),
            engine = math.floor(GetVehicleEngineHealth(veh) / 10), -- Simulating KM/Condition
            body = math.floor(GetVehicleBodyHealth(veh) / 10),
            color = "Personalizada" -- Can be expanded later
        }
    })
end

local function openBuyContract(sellerData, vehicleData)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'buyVehicle',
        showTakeBackOption = sellerData.charinfo.firstname == QBX.PlayerData.charinfo.firstname and sellerData.charinfo.lastname == QBX.PlayerData.charinfo.lastname,
        bizName = config.zones[zone].businessName,
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

local function sellVehicleWait(price)
    DoScreenFadeOut(250)
    Wait(250)
    DeleteVehicle(cache.vehicle)
    Wait(1500)
    DoScreenFadeIn(250)
    exports.qbx_core:Notify((locale('success.car_up_for_sale'):format(price)), 'success')
    PlaySound(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false, 0, true)
end

local function sellData(data, plate)
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
    
    TriggerServerEvent('qb-occasions:server:sellVehicle', data.price, vehicleData)
    sellVehicleWait(data.price)
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
            debug = false,
            onEnter = function(self)
                zone = self.name
                local vehicles = lib.callback.await('qb-occasions:server:getVehicles', false)
                despawnOccasionsVehicles()
                spawnOccasionsVehicles(vehicles)
                spawnSellPed(self.name)
            end,
            onExit = function()
                deleteSellPed(zone)
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
    if occasionVehicles and next(occasionVehicles) then
        for k in pairs(occasionVehicles[zone]) do
            if k == Car then
                return true
            end
        end
    end
    return false
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
    TriggerServerEvent('qb-occasions:server:ReturnVehicle', data)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('selectHistory', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
    openHistoryTablet(true)
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
    TriggerServerEvent('qb-occasions:server:ReturnVehicle', currentVehicle)
    cb('ok')
end)

RegisterNetEvent('qb-occasions:client:BuyFinished', function(vehData)
    DoScreenFadeOut(250)
    Wait(500)
    local netId = lib.callback.await('qbx_vehiclesales:server:spawnVehicle', false, vehData, config.zones[zone].buyVehicle, false)
    local timeout = 100
    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout > 0 do
        Wait(10)
        timeout -= 1
    end
    local veh = NetToVeh(netId)
    SetEntityHeading(veh, config.zones[zone].buyVehicle.w)
    SetVehicleFuelLevel(veh, 100)
    exports.qbx_core:Notify(locale('success.vehicle_bought'), 'success', 2500)
    Wait(500)
    DoScreenFadeIn(250)
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
                DeleteVehicle(cache.vehicle)
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

RegisterNetEvent('qb-occasions:client:ReturnOwnedVehicle', function(vehData)
    DoScreenFadeOut(250)
    Wait(500)
    local netId = lib.callback.await('qbx_vehiclesales:server:spawnVehicle', false, vehData, config.zones[zone].buyVehicle, false)
    local timeout = 100
    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout > 0 do
        Wait(10)
        timeout -= 1
    end
    local veh = NetToVeh(netId)
    SetEntityHeading(veh, config.zones[zone].buyVehicle.w)
    SetVehicleFuelLevel(veh, 100)
    exports.qbx_core:Notify(locale('success.vehicle_bought'), 'success', 2500)
    Wait(500)
    DoScreenFadeIn(250)
    currentVehicle = {}
end)

RegisterNetEvent('qb-occasion:client:refreshVehicles', function()
    if zone then
        local vehicles = lib.callback.await('qb-occasions:server:getVehicles')
        despawnOccasionsVehicles()
        spawnOccasionsVehicles(vehicles)
    end
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
                    debug = false,
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
    if not config.historyLocations then return end

    for i, loc in ipairs(config.historyLocations) do
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
                        openHistoryTablet(true)
                    end,
                    distance = distance
                }
            })
        else
            local zoneId = exports.ox_target:addBoxZone({
                coords = vec3(loc.coords.x, loc.coords.y, loc.coords.z),
                size = loc.size or vec3(1.5, 1.5, 2.0),
                rotation = loc.coords.w or 0.0,
                debug = false,
                options = {
                    {
                        icon = icon,
                        label = label,
                        onSelect = function()
                            openHistoryTablet(true)
                        end,
                        distance = distance
                    }
                }
            })
            table.insert(historyZones, zoneId)
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
        if cache.vehicle and cache.vehicle ~= 0 then
            FreezeEntityPosition(cache.vehicle, false)
        end
        deleteZones()
        cleanupHistoryLocations()
        despawnOccasionsVehicles()
    end
end)

RegisterCommand('minhasvendas', function()
    if QBX and QBX.PlayerData and QBX.PlayerData.charinfo then
        openHistoryTablet(true)
    end
end, false)
