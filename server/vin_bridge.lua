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

---Executes an INSERT into player_vehicles with or without the `vin` column,
---depending on the config.generateVIN setting.
---@param fields table { license, citizenid, model, hash, mods, plate }
function VINBridge.insert(fields)
    local config = require 'config.config'

    local vin = fields.vin
    if not vin and config.generateVIN then
        local ok, genVin = pcall(VINBridge.generate)
        if ok and genVin and genVin ~= '' then
            vin = genVin
        else
            print("^1[newage_vehiclesales]^7 VINBridge.generate() failed. Inserting without generated VIN.")
        end
    end

    local mileage = fields.mileage or 0
    local damage = fields.damage
    local engine = fields.engine or 1000.0
    local body = fields.body or 1000.0
    local fuel = fields.fuel or 100.0

    if vin then
        MySQL.insert(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, vin, mileage, damage, engine, body, fuel) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            { fields.license, fields.citizenid, fields.model, fields.hash, fields.mods, fields.plate, 0, vin, mileage, damage, engine, body, fuel }
        )
    else
        MySQL.insert(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, mileage, damage, engine, body, fuel) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            { fields.license, fields.citizenid, fields.model, fields.hash, fields.mods, fields.plate, 0, mileage, damage, engine, body, fuel }
        )
    end
end
