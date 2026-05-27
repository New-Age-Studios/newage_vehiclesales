--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║              NEWAGE VEHICLESALES — MILEAGE BRIDGE (SERVER)              ║
    ║                                                                          ║
    ║  Server-side callback to fetch mileage when the client-side             ║
    ║  cannot via statebag (e.g. vehicle is not spawned at the moment).        ║
    ║                                                                          ║
    ║  To use another system, edit ONLY this file.                            ║
    ╚══════════════════════════════════════════════════════════════════════════╝
--]]

local config = require 'config.config'

-- ─────────────────────────────────────────────────────────────────────────────
-- Callback: newage_vehiclesales:server:getMileage
-- Fetches a vehicle's mileage by plate.
-- Called by openBuyContract when the buyer's contract is opened.
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('newage_vehiclesales:server:getMileage', function(_, plate)
    if not config.mileageProvider or config.mileageProvider == "none" then
        return nil
    end
    if not plate or plate == "" then return nil end

    local provider = config.mileageProvider

    -- ── jg-vehiclemileage ─────────────────────────────────────────────────
    if provider == "jg-vehiclemileage" then
        if GetResourceState("jg-vehiclemileage") ~= "started" then
            return nil
        end

        local ok, result = pcall(function()
            return exports["jg-vehiclemileage"]:getMileageByPlate(plate)
        end)
        if ok and result then
            return tonumber(result)
        end
        return nil

    -- ── custom ────────────────────────────────────────────────────────────
    -- Set config.mileageProvider = "custom" in config.lua and
    -- implement the fetch via database or your resource's export here.
    elseif provider == "custom" then
        --[[ EXAMPLE 1: direct database fetch (if you store it in player_vehicles table)
        local result = MySQL.scalar.await("SELECT mileage FROM player_vehicles WHERE plate = ?", { plate })
        return result and tonumber(result) or nil
        --]]

        --[[ EXAMPLE 2: via export from another server-side resource
        local ok, result = pcall(function()
            return exports["my_mileage"]:getMileageByPlate(plate)
        end)
        if ok and result then return tonumber(result) end
        --]]

        return nil -- ← replace with your implementation
    end

    return nil
end)
