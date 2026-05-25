local VEHICLES = exports.qbx_core:GetVehiclesByName()
local config = require 'config.config'

local function generateOID()
    local num = math.random(1, 10) .. math.random(111, 999)
    return 'OC' .. num
end

local busyVehicles = {}

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `newage_vehiclesales_history` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `seller` varchar(50) DEFAULT NULL,
          `buyer_name` varchar(100) DEFAULT NULL,
          `buyer_citizenid` varchar(50) DEFAULT NULL,
          `price` int(11) DEFAULT NULL,
          `plate` varchar(50) DEFAULT NULL,
          `model` varchar(50) DEFAULT NULL,
          `description` longtext DEFAULT NULL,
          `mods` text DEFAULT NULL,
          `fuel_type` varchar(50) DEFAULT 'Gasolina',
          `color_rgb` varchar(50) DEFAULT '#FFFFFF',
          `is_exotic` tinyint(1) DEFAULT 0,
          `transmission` varchar(50) DEFAULT 'Automático',
          `photo_url` varchar(255) DEFAULT NULL,
          `date` timestamp DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Dynamic schema migration for photo_url column
    CreateThread(function()
        local function checkAndAddPhotoColumn(tableName)
            local columns = MySQL.query.await("SHOW COLUMNS FROM `" .. tableName .. "` LIKE 'photo_url'")
            if not columns or #columns == 0 then
                MySQL.query.await("ALTER TABLE `" .. tableName .. "` ADD COLUMN `photo_url` varchar(255) DEFAULT NULL")
                print(("^2[newage_vehiclesales]^7 Adicionada coluna 'photo_url' na tabela '%s'"):format(tableName))
            end
        end
        checkAndAddPhotoColumn("newage_vehiclesales")
        checkAndAddPhotoColumn("newage_vehiclesales_history")
    end)
end)

---@param model number
---@return number price defaults to 0
local function getVehPrice(model)
    for _, v in pairs(VEHICLES) do
        if v.hash == model then
            return tonumber(v.price)
        end
    end
    return 0
end

lib.callback.register('qbx_vehiclesales:server:setVehicleBusy', function(source, plate, isBusy)
    if isBusy then
        if busyVehicles[plate] and busyVehicles[plate] ~= source then
            return false
        end
        busyVehicles[plate] = source
        return true
    else
        if busyVehicles[plate] == source then
            busyVehicles[plate] = nil
        end
        return true
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    for plate, owner in pairs(busyVehicles) do
        if owner == src then
            busyVehicles[plate] = nil
        end
    end
end)

lib.callback.register('qb-occasions:server:getVehicles', function()
    local result = MySQL.query.await('SELECT * FROM newage_vehiclesales')
    if result[1] then
        return result
    end
end)

lib.callback.register('qb-occasions:server:getSellerInformation', function(_, citizenId)
    local result = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {citizenId})
    if result[1] then
        return result[1]
    end
end)

lib.callback.register('qb-vehiclesales:server:CheckModelName', function(_, plate)
    if plate then
        return MySQL.scalar.await('SELECT vehicle FROM player_vehicles WHERE plate = ?', {plate})
    end
end)

lib.callback.register('qbx_vehiclesales:server:spawnVehicle', function (source, vehicle, coords, warp)
    local vehmods = json.decode(vehicle.mods)
    local netId = qbx.spawnVehicle({model = vehicle.model, spawnSource = coords, warp = warp, props = vehmods})
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 then return end
    
    SetVehicleNumberPlateText(veh, vehicle.plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, vehicle.plate)
    return netId
end)

lib.callback.register('qbx_vehiclesales:server:checkVehicleOwner', function(source, plate)
    local player = exports.qbx_core:GetPlayer(source)
    local result = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, player.PlayerData.citizenid})

    if result and result.id then
        local financeRow = MySQL.single.await('SELECT * FROM vehicle_financing WHERE vehicleId = ?', {result.id})
        return true, financeRow?.balance
    end

    return false
end)

lib.callback.register('qbx_vehiclesales:server:getVehicleSellBackPrice', function(_, modelHash)
    local price = getVehPrice(modelHash)
    local percentage = config.sellBackPercentage or 50
    local payout = math.floor(price * (percentage / 100))
    return price, payout, percentage
end)

RegisterNetEvent('qb-occasions:server:ReturnVehicle', function(vehicleData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local result = MySQL.query.await('SELECT * FROM newage_vehiclesales WHERE plate = ? AND occasionid = ?', {vehicleData.plate, vehicleData.oid})

    if not result[1] then
        exports.qbx_core:Notify(src, locale('error.vehicle_does_not_exist'), 'error', 3500)
        return
    end

    if result[1].seller ~= player.PlayerData.citizenid then
        exports.qbx_core:Notify(src, locale('error.not_your_vehicle'), 'error', 3500)
        return
    end

    MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {player.PlayerData.license, player.PlayerData.citizenid, vehicleData.model, joaat(vehicleData.model), vehicleData.mods, vehicleData.plate, 0})
    MySQL.query('DELETE FROM newage_vehiclesales WHERE occasionid = ? AND plate = ?', {vehicleData.oid, vehicleData.plate})
    busyVehicles[vehicleData.plate] = nil
    TriggerClientEvent('qb-occasions:client:ReturnOwnedVehicle', src, result[1])
    TriggerClientEvent('qb-occasion:client:refreshVehicles', -1)
end)

RegisterNetEvent('qb-occasions:server:sellVehicle', function(vehiclePrice, vehicleData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    MySQL.query('DELETE FROM player_vehicles WHERE plate = ? AND vehicle = ?',{vehicleData.plate, vehicleData.model})
    MySQL.insert('INSERT INTO newage_vehiclesales (seller, price, description, plate, model, mods, occasionid, fuel_type, color_rgb, is_exotic, transmission, photo_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',{
        player.PlayerData.citizenid, 
        vehiclePrice, 
        vehicleData.desc, 
        vehicleData.plate, 
        vehicleData.model,
        json.encode(vehicleData.mods), 
        generateOID(),
        vehicleData.fuelType or 'Gasolina',
        vehicleData.colorRGB or '#FFFFFF',
        vehicleData.isExotic and 1 or 0,
        vehicleData.transmission or 'Automático',
        vehicleData.photoUrl
    })
    TriggerEvent('qb-log:server:CreateLog', 'vehicleshop', 'Vehicle for Sale', 'red','**' .. GetPlayerName(src) .. '** has a ' .. vehicleData.model .. ' priced at ' .. vehiclePrice)
    TriggerClientEvent('qb-occasion:client:refreshVehicles', -1)
end)

RegisterNetEvent('qb-occasions:server:sellVehicleBack', function(vehData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local plate = vehData.plate
    local price = getVehPrice(vehData.model)
    local percentage = config.sellBackPercentage or 50
    local payout = math.floor(price * (percentage / 100))
    player.Functions.AddMoney('bank', payout)
    exports.qbx_core:Notify(src, (locale('success.sold_car_for_price'):format(payout)), 'success', 5500)
    MySQL.query('DELETE FROM player_vehicles WHERE plate = ?', {plate})
end)

RegisterNetEvent('qb-occasions:server:buyVehicle', function(vehicleData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local result = MySQL.query.await('SELECT * FROM newage_vehiclesales WHERE plate = ? AND occasionid = ?',{vehicleData.plate, vehicleData.oid})
    if not result[1] or not next(result[1]) then return end
    if player.PlayerData.money.bank < result[1].price then
        exports.qbx_core:Notify(src, locale('error.not_enough_money'), 'error', 3500)
        return
    end

    local sellerCitizenId = result[1].seller
    local sellerData = exports.qbx_core:GetPlayerByCitizenId(sellerCitizenId)
    local fee = config.dealerFee or 0
    local sellerPayout = math.ceil(result[1].price * (1 - (fee / 100)))
    player.Functions.RemoveMoney('bank', result[1].price)
    MySQL.insert(
        'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            player.PlayerData.license,
            player.PlayerData.citizenid, result[1].model,
            GetHashKey(result[1].model),
            result[1].mods,
            result[1].plate,
            0
        })
    if sellerData then
        sellerData.Functions.AddMoney('bank', sellerPayout)
    else
        local buyerData = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?',{sellerCitizenId})
        if buyerData[1] then
            local buyerMoney = json.decode(buyerData[1].money)
            buyerMoney.bank = buyerMoney.bank + sellerPayout
            MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(buyerMoney), sellerCitizenId})
        end
    end
    TriggerEvent('qb-log:server:CreateLog', 'vehicleshop', 'bought', 'green', '**' .. GetPlayerName(src) .. '** has bought for ' .. result[1].price .. ' (' .. result[1].plate ..') from **' .. sellerCitizenId .. '**')
    TriggerClientEvent('qb-occasions:client:BuyFinished', src, result[1])
    TriggerClientEvent('qb-occasion:client:refreshVehicles', -1)
    
    -- Insert transaction into history before deleting the active listing
    MySQL.insert([[
        INSERT INTO newage_vehiclesales_history 
        (seller, buyer_name, buyer_citizenid, price, plate, model, description, mods, fuel_type, color_rgb, is_exotic, transmission, photo_url) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        result[1].seller,
        player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        player.PlayerData.citizenid,
        result[1].price,
        result[1].plate,
        result[1].model,
        result[1].description,
        result[1].mods,
        result[1].fuel_type or 'Gasolina',
        result[1].color_rgb or '#FFFFFF',
        result[1].is_exotic and 1 or 0,
        result[1].transmission or 'Automático',
        result[1].photo_url
    })

    MySQL.query('DELETE FROM newage_vehiclesales WHERE plate = ? AND occasionid = ?',{result[1].plate, result[1].occasionid})
    busyVehicles[result[1].plate] = nil
    local vehicleName = VEHICLES[result[1].model] and VEHICLES[result[1].model].name or result[1].model
    TriggerEvent('qb-phone:server:sendNewMailToOffline', sellerCitizenId, {
        sender = locale('mail.sender'),
        subject = locale('mail.subject'),
        message = (locale('mail.message'):format(sellerPayout, vehicleName))
    })
end)

lib.callback.register('qbx_vehiclesales:server:getPlayerSalesHistory', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {}, {} end
    
    local citizenid = player.PlayerData.citizenid
    
    local active = MySQL.query.await('SELECT * FROM newage_vehiclesales WHERE seller = ?', {citizenid})
    local sold = MySQL.query.await('SELECT * FROM newage_vehiclesales_history WHERE seller = ? ORDER BY date DESC', {citizenid})
    
    return active, sold
end)

