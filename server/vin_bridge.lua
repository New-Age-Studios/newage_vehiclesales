--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║              NEWAGE VEHICLESALES — VIN BRIDGE (SERVER)                  ║
    ║                                                                          ║
    ║  This file controls the generation of VIN (Chassis) when inserting a    ║
    ║  vehicle into the player_vehicles table after a purchase or cancel.      ║
    ║                                                                          ║
    ║  To change the VIN generator, edit ONLY this file.                      ║
    ║  To enable/disable, use config.generateVIN = true/false                 ║
    ╚══════════════════════════════════════════════════════════════════════════╝
--]]

VINBridge = {}

---Generates a VIN using the configured resource (piotreq_gpt by default).
---If the resource is not running, it uses a generic 17-character generator.
---@return string|nil Generated VIN or nil on failure
function VINBridge.generate()
    -- ── piotreq_gpt ───────────────────────────────────────────────────────
    -- Uses the official piotreq_gpt export when it's running
    if GetResourceState('piotreq_gpt') == 'started' then
        local ok, vin = pcall(function()
            return exports['piotreq_gpt']:GenerateVIN()
        end)
        if ok and vin and vin ~= '' then
            return vin
        end
    end

    -- ── custom ────────────────────────────────────────────────────────────
    -- Replace the block above with the call to your VIN resource if it's different.
    -- Examples:
    --
    -- if GetResourceState('my_mdt') == 'started' then
    --     local ok, vin = pcall(function()
    --         return exports['my_mdt']:GenerateVIN()
    --     end)
    --     if ok and vin and vin ~= '' then return vin end
    -- end

    -- ── Generic Fallback ─────────────────────────────────────────────────
    -- Used when no VIN resource is available but the column is
    -- required in the database. Generates a random 17-character VIN (ISO 3779 standard).
    local charset = "0123456789ABCDEFGHJKLMNPRSTUVWXYZ" -- no I, O, Q (ISO standard)
    local vin = ""
    for _ = 1, 17 do
        local r = math.random(1, #charset)
        vin = vin .. charset:sub(r, r)
    end
    return vin
end

local cachedPlayerVehicleColumns = nil

---Executes an INSERT into player_vehicles dynamically.
---It automatically detects which columns exist in the server's database to prevent crashes.
---@param fields table { license, citizenid, model, hash, mods, plate, vin, mileage, damage, engine, body, fuel }
function VINBridge.insert(fields)
    local config = require 'config.config'

    -- Cache columns to prevent running SHOW COLUMNS on every purchase
    if not cachedPlayerVehicleColumns then
        cachedPlayerVehicleColumns = {}
        local cols = MySQL.query.await('SHOW COLUMNS FROM player_vehicles')
        if cols then
            for _, col in ipairs(cols) do
                cachedPlayerVehicleColumns[col.Field] = true
            end
        end
    end

    local vin = fields.vin
    if not vin and config.generateVIN and cachedPlayerVehicleColumns['vin'] then
        local ok, genVin = pcall(VINBridge.generate)
        if ok and genVin and genVin ~= '' then
            vin = genVin
        else
            print("^1[newage_vehiclesales]^7 VINBridge.generate() failed. Inserting without generated VIN.")
        end
    end

    -- Base columns that all QBCore/QBox servers have
    local columns = { "license", "citizenid", "vehicle", "hash", "mods", "plate", "state" }
    local values = { fields.license, fields.citizenid, fields.model, fields.hash, fields.mods, fields.plate, 0 }

    -- Dynamically append advanced columns ONLY if they exist in the server's player_vehicles table
    if cachedPlayerVehicleColumns['vin'] and vin then
        table.insert(columns, "vin")
        table.insert(values, vin)
    end
    if cachedPlayerVehicleColumns['mileage'] and fields.mileage then
        table.insert(columns, "mileage")
        table.insert(values, fields.mileage)
    end
    if cachedPlayerVehicleColumns['damage'] and fields.damage then
        table.insert(columns, "damage")
        table.insert(values, fields.damage)
    end
    if cachedPlayerVehicleColumns['engine'] and fields.engine then
        table.insert(columns, "engine")
        table.insert(values, fields.engine)
    end
    if cachedPlayerVehicleColumns['body'] and fields.body then
        table.insert(columns, "body")
        table.insert(values, fields.body)
    end
    if cachedPlayerVehicleColumns['fuel'] and fields.fuel then
        table.insert(columns, "fuel")
        table.insert(values, fields.fuel)
    end

    -- Build the ? placeholders dynamically
    local placeholders = {}
    for i = 1, #columns do
        placeholders[i] = "?"
    end

    local sql = ("INSERT INTO player_vehicles (%s) VALUES (%s)"):format(
        table.concat(columns, ", "), 
        table.concat(placeholders, ", ")
    )

    MySQL.insert.await(sql, values)
end
