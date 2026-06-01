local VEHICLES = exports.qbx_core:GetVehiclesByName()
local config = require 'config.config'

local function generateOID()
    local num = math.random(1, 10) .. math.random(111, 999)
    return 'OC' .. num
end

local busyVehicles = {}
local displayVehicles = {} -- { [zone] = { {netId, plate, loc, price, owner, model, desc, mods, fuelType, colorRGB, isExotic, transmission, photo_url}, ... } }

local function refreshDisplayVehicles(zone)
    if not zone or not config.zones[zone] then return end
    
    displayVehicles[zone] = {}
    
    local spots = config.zones[zone].vehicleSpots
    local result = MySQL.query.await('SELECT * FROM newage_vehiclesales WHERE zone = ?', {zone})
    
    if result and #result > 0 then
        local occupiedSpots = {}
        for i = 1, #result do
            if result[i].spot_index then
                occupiedSpots[result[i].spot_index] = true
            end
        end

        for i = 1, #result do
            local v = result[i]
            local spotIndex = v.spot_index
            
            if not spotIndex then
                for s = 1, #spots do
                    if not occupiedSpots[s] then
                        spotIndex = s
                        occupiedSpots[s] = true
                        MySQL.query('UPDATE newage_vehiclesales SET spot_index = ? WHERE id = ?', {spotIndex, v.id})
                        break
                    end
                end
            end
            
            if spotIndex and spots[spotIndex] then
                local coords = spots[spotIndex]
                
                -- Prepare data for clients
                local vData = {
                    plate        = v.plate,
                    model        = v.model,
                    owner        = v.seller,
                    price        = v.price,
                    desc         = v.description,
                    mods         = v.mods,
                    oid          = v.occasionid,
                    fuelType     = v.fuel_type,
                    colorRGB     = v.color_rgb,
                    isExotic     = (v.is_exotic == 1 or v.is_exotic == true),
                    transmission = v.transmission,
                    photo_url    = v.photo_url,
                    vin          = v.vin,
                    mileage      = v.mileage,
                    damage       = v.damage,
                    engine       = v.engine,
                    body         = v.body,
                    fuel         = v.fuel,
                    loc          = coords,
                    zone         = zone,
                    slotIndex    = spotIndex
                }
                
                table.insert(displayVehicles[zone], vData)
            end
        end
    end
    
    -- Sync updated list to all clients
    TriggerClientEvent('qb-occasion:client:syncDisplayVehicles', -1, zone, displayVehicles[zone])
end

lib.callback.register('qb-occasions:server:getDisplayVehicles', function(source, zone)
    return displayVehicles[zone] or {}
end)

local webhooks = require 'config.webhook'

local function sendWebhook(action, title, description, color, fields, image)
    local url = webhooks["webhook_" .. action]
    if not url or url == "" then
        url = webhooks["webhook_all"]
    end
    if not url or url == "" then return end

    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 16711680, -- default red
            ["fields"] = fields or {},
            ["footer"] = {
                ["text"] = "New-Age Studios | " .. os.date("%d/%m/%Y %H:%M:%S"),
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    if image and image ~= "" then
        embed[1]["image"] = { ["url"] = image }
    end

    PerformHttpRequest(url, function(statusCode, response, headers)
        -- Handled or ignored
    end, 'POST', json.encode({
        username = locale('webhook.username'),
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

MySQL.ready(function()
    CreateThread(function()
        -- 1. Auto-Install SQL File (For fresh installs)
        local sqlFile = LoadResourceFile(GetCurrentResourceName(), 'newage-vehiclesales.sql')
        if sqlFile then
            print("^2[newage_vehiclesales]^7 Auto-Installer: Verifying database structure...")
            
            -- Split queries by semicolon to execute them sequentially (safest method for oxmysql)
            local queries = {}
            for query in string.gmatch(sqlFile, "([^;]+);") do
                local trimmed = query:gsub("^%s*(.-)%s*$", "%1")
                if trimmed ~= "" then
                    table.insert(queries, trimmed)
                end
            end
            
            for _, q in ipairs(queries) do
                MySQL.query.await(q)
            end
            print("^2[newage_vehiclesales]^7 Auto-Installer: SQL tables verified/installed successfully!")
        else
            print("^1[newage_vehiclesales]^7 Auto-Installer Error: Could not read newage-vehiclesales.sql file!")
        end

        -- 2. Dynamic schema migrations (For users upgrading from older versions)
        local function checkAndAddColumn(tableName, columnName, columnDef)
            local columns = MySQL.query.await(("SHOW COLUMNS FROM `%s` LIKE '%s'"):format(tableName, columnName))
            if not columns or #columns == 0 then
                MySQL.query.await(("ALTER TABLE `%s` ADD COLUMN `%s` %s"):format(tableName, columnName, columnDef))
                print(("^2[newage_vehiclesales]^7 Schema Update: Added column '%s' to table '%s'"):format(columnName, tableName))
            end
        end
        
        -- Fix existing varchar columns by modifying them to longtext
        MySQL.query.await("ALTER TABLE `newage_vehiclesales` MODIFY COLUMN `photo_url` longtext DEFAULT NULL")
        MySQL.query.await("ALTER TABLE `newage_vehiclesales_history` MODIFY COLUMN `photo_url` longtext DEFAULT NULL")
        
        -- Ensure all newer columns exist for users upgrading
        checkAndAddColumn("newage_vehiclesales", "zone", "varchar(50) DEFAULT NULL")
        checkAndAddColumn("newage_vehiclesales", "spot_index", "int(11) DEFAULT NULL")
        checkAndAddColumn("newage_vehiclesales", "vin", "varchar(50) DEFAULT NULL")
        checkAndAddColumn("newage_vehiclesales", "mileage", "float DEFAULT 0")
        checkAndAddColumn("newage_vehiclesales", "damage", "longtext DEFAULT NULL")
        checkAndAddColumn("newage_vehiclesales", "engine", "float DEFAULT 1000")
        checkAndAddColumn("newage_vehiclesales", "body", "float DEFAULT 1000")
        checkAndAddColumn("newage_vehiclesales", "fuel", "float DEFAULT 100")

        checkAndAddColumn("newage_vehiclesales_history", "zone", "varchar(50) DEFAULT NULL")
        checkAndAddColumn("newage_vehiclesales_history", "vin", "varchar(50) DEFAULT NULL")
        checkAndAddColumn("newage_vehiclesales_history", "mileage", "float DEFAULT 0")
        checkAndAddColumn("newage_vehiclesales_history", "damage", "longtext DEFAULT NULL")
        checkAndAddColumn("newage_vehiclesales_history", "engine", "float DEFAULT 1000")
        checkAndAddColumn("newage_vehiclesales_history", "body", "float DEFAULT 1000")
        checkAndAddColumn("newage_vehiclesales_history", "fuel", "float DEFAULT 100")
        
        -- Spawn display vehicles for all zones after DB is ready
        Wait(2000)
        for z, _ in pairs(config.zones) do
            refreshDisplayVehicles(z)
        end
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

    VINBridge.insert({
        license   = player.PlayerData.license,
        citizenid = player.PlayerData.citizenid,
        model     = vehicleData.model,
        hash      = joaat(vehicleData.model),
        mods      = vehicleData.mods,
        plate     = vehicleData.plate,
        vin       = result[1].vin,
        mileage   = result[1].mileage,
        damage    = result[1].damage,
        engine    = result[1].engine,
        body      = result[1].body,
        fuel      = result[1].fuel
    })
    MySQL.query('DELETE FROM newage_vehiclesales WHERE occasionid = ? AND plate = ?', {vehicleData.oid, vehicleData.plate})
    busyVehicles[vehicleData.plate] = nil
    TriggerClientEvent('qb-occasions:client:ReturnOwnedVehicle', src, result[1], vehicleData.loc)
    
    local zoneStr = result[1].zone or vehicleData.zone
    if zoneStr then refreshDisplayVehicles(zoneStr) end

    local vehicleName = VEHICLES[result[1].model] and VEHICLES[result[1].model].name or result[1].model
    sendWebhook("cancel", locale('webhook.cancel_title'), 
        (locale('webhook.cancel_desc')):format(
            player.PlayerData.charinfo.firstname, 
            player.PlayerData.charinfo.lastname, 
            player.PlayerData.citizenid, 
            vehicleName, 
            result[1].plate, 
            (config.currencySymbol or "R$"),
            result[1].price
        ), 
        16347926, -- Orange (#f97316)
        nil,
        result[1].photo_url
    )
end)

RegisterNetEvent('qb-occasions:server:sellVehicle', function(vehiclePrice, vehicleData, oldVehNetId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    
    if oldVehNetId then
        local ent = NetworkGetEntityFromNetworkId(oldVehNetId)
        if DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
    end
    
    local zone = vehicleData.zone
    local maxSpots = config.zones[zone] and config.zones[zone].vehicleSpots and #config.zones[zone].vehicleSpots or 100
    local existingVehicles = MySQL.query.await('SELECT spot_index FROM newage_vehiclesales WHERE zone = ?', {zone})
    local occupiedSpots = {}
    for _, v in ipairs(existingVehicles) do
        if v.spot_index then
            occupiedSpots[v.spot_index] = true
        end
    end
    
    local freeSpot = nil
    for s = 1, maxSpots do
        if not occupiedSpots[s] then
            freeSpot = s
            break
        end
    end

    local pvData = MySQL.single.await('SELECT vin, mileage, damage, engine, body, fuel FROM player_vehicles WHERE plate = ? AND vehicle = ?', {vehicleData.plate, vehicleData.model})
    local vin = pvData and pvData.vin
    local mileage = vehicleData.mileage or (pvData and pvData.mileage) or 0
    local damage = vehicleData.damage or (pvData and pvData.damage)
    local engine = vehicleData.engine or (pvData and pvData.engine) or 1000.0
    local body = vehicleData.body or (pvData and pvData.body) or 1000.0
    local fuel = vehicleData.fuel or (pvData and pvData.fuel) or 100.0

    if mileage == 0 and config.mileageProvider == "jg-vehiclemileage" and GetResourceState("jg-vehiclemileage") == "started" then
        local ok, result = pcall(function()
            return exports["jg-vehiclemileage"]:getMileageByPlate(vehicleData.plate)
        end)
        if ok and result then
            mileage = tonumber(result) or 0
        end
    end

    local insertId = MySQL.insert.await('INSERT INTO newage_vehiclesales (seller, price, description, plate, model, mods, occasionid, fuel_type, color_rgb, is_exotic, transmission, photo_url, zone, spot_index, vin, mileage, damage, engine, body, fuel) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',{
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
        vehicleData.photoUrl,
        vehicleData.zone,
        freeSpot,
        vin,
        mileage,
        damage,
        engine,
        body,
        fuel
    })
    
    if insertId then
        MySQL.query.await('DELETE FROM player_vehicles WHERE plate = ? AND vehicle = ?',{vehicleData.plate, vehicleData.model})
    end
    TriggerEvent('qb-log:server:CreateLog', 'vehicleshop', 'Vehicle for Sale', 'red','**' .. GetPlayerName(src) .. '** has a ' .. vehicleData.model .. ' priced at ' .. vehiclePrice)
    
    if vehicleData.zone then refreshDisplayVehicles(vehicleData.zone) end

    local vehicleName = VEHICLES[vehicleData.model] and VEHICLES[vehicleData.model].name or vehicleData.model
    sendWebhook("sell", locale('webhook.sell_title'), 
        (locale('webhook.sell_desc')):format(
            player.PlayerData.charinfo.firstname, 
            player.PlayerData.charinfo.lastname, 
            player.PlayerData.citizenid, 
            vehicleName, 
            vehicleData.plate, 
            (config.currencySymbol or "R$"),
            vehiclePrice, 
            vehicleData.desc or locale('ui.none')
        ), 
        2279774, -- Green (#22c55e)
        nil,
        vehicleData.photoUrl
    )
end)

RegisterNetEvent('qb-occasions:server:sellVehicleBack', function(vehData, oldVehNetId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local plate = vehData.plate
    
    if oldVehNetId then
        local ent = NetworkGetEntityFromNetworkId(oldVehNetId)
        if DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
    end
    
    local price = getVehPrice(vehData.model)
    local percentage = config.sellBackPercentage or 50
    local payout = math.floor(price * (percentage / 100))
    player.Functions.AddMoney('bank', payout)
    exports.qbx_core:Notify(src, (locale('success.sold_car_for_price'):format(config.currencySymbol or "R$", payout)), 'success', 5500)
    MySQL.query('DELETE FROM player_vehicles WHERE plate = ?', {plate})

    local vehicleName = VEHICLES[vehData.model] and VEHICLES[vehData.model].name or vehData.model
    sendWebhook("sellback", locale('webhook.sellback_title'), 
        (locale('webhook.sellback_desc')):format(
            player.PlayerData.charinfo.firstname, 
            player.PlayerData.charinfo.lastname, 
            player.PlayerData.citizenid, 
            vehicleName, 
            plate, 
            (config.currencySymbol or "R$"),
            price, 
            percentage, 
            (config.currencySymbol or "R$"),
            payout
        ), 
        11032055, -- Purple (#a855f7)
        nil,
        nil
    )
end)

RegisterNetEvent('qb-occasions:server:buyVehicle', function(vehicleData, paymentMethod)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local result = MySQL.query.await('SELECT * FROM newage_vehiclesales WHERE plate = ? AND occasionid = ?',{vehicleData.plate, vehicleData.oid})
    if not result[1] or not next(result[1]) then return end
    
    local method = paymentMethod == 'cash' and 'cash' or 'bank'
    if not player.PlayerData.money[method] and player.PlayerData.money['money'] then
        method = paymentMethod == 'cash' and 'money' or 'bank'
    end

    if player.PlayerData.money[method] < result[1].price then
        exports.qbx_core:Notify(src, locale('error.not_enough_money'), 'error', 3500)
        return
    end

    local sellerCitizenId = result[1].seller
    local sellerData = exports.qbx_core:GetPlayerByCitizenId(sellerCitizenId)
    local fee = config.dealerFee or 0
    local sellerPayout = math.ceil(result[1].price * (1 - (fee / 100)))
    player.Functions.RemoveMoney(method, result[1].price)
    VINBridge.insert({
        license   = player.PlayerData.license,
        citizenid = player.PlayerData.citizenid,
        model     = result[1].model,
        hash      = GetHashKey(result[1].model),
        mods      = result[1].mods,
        plate     = result[1].plate,
        vin       = result[1].vin,
        mileage   = result[1].mileage,
        damage    = result[1].damage,
        engine    = result[1].engine,
        body      = result[1].body,
        fuel      = result[1].fuel
    })
    if sellerData then
        sellerData.Functions.AddMoney('bank', sellerPayout)
    else
        local buyerData = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?',{sellerCitizenId})
        if buyerData[1] then
            -- oxmysql sometimes auto-decodes JSON columns into tables depending on mysql configuration.
            -- Using type check prevents a critical Lua crash (bad argument #1 to 'decode' (string expected, got table))
            local buyerMoney = type(buyerData[1].money) == "string" and json.decode(buyerData[1].money) or buyerData[1].money
            if buyerMoney then
                buyerMoney.bank = (buyerMoney.bank or 0) + sellerPayout
                MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(buyerMoney), sellerCitizenId})
            end
        end
    end
    TriggerEvent('qb-log:server:CreateLog', 'vehicleshop', 'bought', 'green', '**' .. GetPlayerName(src) .. '** has bought for ' .. result[1].price .. ' (' .. result[1].plate ..') from **' .. sellerCitizenId .. '**')
    
    -- Delete from DB first so refreshDisplayVehicles doesn't send the old showcase to clients
    MySQL.query.await('DELETE FROM newage_vehiclesales WHERE plate = ? AND occasionid = ?',{result[1].plate, result[1].occasionid})
    busyVehicles[result[1].plate] = nil

    TriggerClientEvent('qb-occasions:client:BuyFinished', src, result[1], vehicleData.loc)
    
    local zoneStr = result[1].zone or vehicleData.zone
    if zoneStr then refreshDisplayVehicles(zoneStr) end
    
    -- Insert transaction into history before deleting the active listing
    MySQL.insert([[
        INSERT INTO newage_vehiclesales_history 
        (seller, buyer_name, buyer_citizenid, price, plate, model, description, mods, fuel_type, color_rgb, is_exotic, transmission, photo_url, zone, vin, mileage, damage, engine, body, fuel) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
        result[1].photo_url,
        result[1].zone,
        result[1].vin,
        result[1].mileage,
        result[1].damage,
        result[1].engine,
        result[1].body,
        result[1].fuel
    })
    local vehicleName = VEHICLES[result[1].model] and VEHICLES[result[1].model].name or result[1].model
    TriggerEvent('qb-phone:server:sendNewMailToOffline', sellerCitizenId, {
        sender = locale('mail.sender'),
        subject = locale('mail.subject'),
        message = (locale('mail.message'):format(config.currencySymbol or "R$", sellerPayout, vehicleName))
    })

    sendWebhook("buy", locale('webhook.buy_title'), 
        (locale('webhook.buy_desc')):format(
            player.PlayerData.charinfo.firstname, 
            player.PlayerData.charinfo.lastname, 
            player.PlayerData.citizenid, 
            sellerCitizenId, 
            vehicleName, 
            result[1].plate, 
            (config.currencySymbol or "R$"),
            result[1].price
        ), 
        3899902, -- Blue (#3b82f6)
        nil,
        result[1].photo_url
    )
end)

lib.callback.register('qbx_vehiclesales:server:getPlayerSalesHistory', function(source, zoneName)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {}, {} end
    
    local citizenid = player.PlayerData.citizenid
    
    local activeQuery = 'SELECT * FROM newage_vehiclesales WHERE seller = ?'
    local soldQuery = 'SELECT * FROM newage_vehiclesales_history WHERE seller = ? ORDER BY date DESC'
    local params = {citizenid}

    if zoneName then
        activeQuery = activeQuery .. ' AND zone = ?'
        soldQuery = 'SELECT * FROM newage_vehiclesales_history WHERE seller = ? AND zone = ? ORDER BY date DESC'
        table.insert(params, zoneName)
    end

    local active = MySQL.query.await(activeQuery, params)
    local sold = MySQL.query.await(soldQuery, params)
    
    return active, sold
end)

RegisterNetEvent('qbx_vehiclesales:server:deleteHistoryRecord', function(id)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
    local record = MySQL.single.await('SELECT * FROM newage_vehiclesales_history WHERE id = ?', {id})
    if record and record.seller == citizenid then
        MySQL.query.await('DELETE FROM newage_vehiclesales_history WHERE id = ?', {id})
        TriggerClientEvent('qbx_core:Notify', src, locale('success.history_removed'), "success")

        local vehicleName = VEHICLES[record.model] and VEHICLES[record.model].name or record.model
        sendWebhook("delete", locale('webhook.delete_title'), 
            (locale('webhook.delete_desc')):format(
                player.PlayerData.charinfo.firstname, 
                player.PlayerData.charinfo.lastname, 
                player.PlayerData.citizenid, 
                record.buyer_name or "N/A", 
                vehicleName, 
                record.plate, 
                (config.currencySymbol or "R$"),
                record.price or 0, 
                record.date and tostring(record.date) or "N/A"
            ), 
            15680580, -- Red (#ef4444)
            nil,
            record.photo_url
        )
    else
        TriggerClientEvent('qbx_core:Notify', src, locale('error.no_permission_delete'), "error")
    end
end)

