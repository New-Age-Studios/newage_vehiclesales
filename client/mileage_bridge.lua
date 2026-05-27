--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║              NEWAGE VEHICLESALES — MILEAGE BRIDGE (CLIENT)              ║
    ║                                                                          ║
    ║  This file is the mileage bridge for the sales system.                  ║
    ║  To change the mileage system, edit ONLY this file.                     ║
    ║                                                                          ║
    ║  Supported providers (config.mileageProvider):                          ║
    ║    "jg-vehiclemileage" — uses jg-vehiclemileage exports                 ║
    ║    "custom"            — implement getRawKm() below                     ║
    ║    "none"              — disables mileage (doesn't show in contract)    ║
    ╚══════════════════════════════════════════════════════════════════════════╝
--]]

local config = require 'config.config'

MileageBridge = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- getRawKm(plate)
-- Returns the numeric mileage in KM for a specific plate.
-- Implementation varies based on config.mileageProvider.
-- ─────────────────────────────────────────────────────────────────────────────
---@param plate string Vehicle plate (without spaces)
---@return number|nil  Mileage in km or nil if not available
function MileageBridge.getRawKm(plate)
    local provider = config.mileageProvider or "none"

    -- ── jg-vehiclemileage ─────────────────────────────────────────────────
    if provider == "jg-vehiclemileage" then
        if GetResourceState("jg-vehiclemileage") ~= "started" then
            return nil
        end

        -- Priority 1: statebag (already loaded by jg, no server roundtrip)
        local veh = cache.vehicle
        if veh and veh ~= 0 and DoesEntityExist(veh) then
            local plateTrimmed = plate:gsub("%s+", "")
            local vehPlate = GetVehicleNumberPlateText(veh):gsub("%s+", "")
            if vehPlate == plateTrimmed then
                local stateMileage = Entity(veh).state.vehicleMileage
                if stateMileage then
                    return tonumber(stateMileage)
                end
            end
        end

        -- Priority 2: export getMileageByPlate (triggers a jg server callback)
        local ok, result = pcall(function()
            return exports["jg-vehiclemileage"]:getMileageByPlate(plate)
        end)
        if ok and result then
            return tonumber(result)
        end

        return nil

    -- ── custom ────────────────────────────────────────────────────────────
    -- Set config.mileageProvider = "custom" and implement
    -- the fetch logic for your mileage system here.
    -- This function can use lib.callback.await since it's called from
    -- within a thread context (openSellContract / openBuyContract).
    elseif provider == "custom" then
        --[[ EXAMPLE 1: via client-side export of another resource
        local ok, result = pcall(function()
            return exports["my_mileage"]:getMileageByPlate(plate)
        end)
        if ok and result then return tonumber(result) end
        --]]

        --[[ EXAMPLE 2: via server callback
        local mileage = lib.callback.await("my_mileage:getMileage", false, plate)
        return mileage and tonumber(mileage) or nil
        --]]

        return nil -- ← replace with your implementation

    end

    return nil -- provider == "none" or unrecognized
end

-- ─────────────────────────────────────────────────────────────────────────────
-- formatMileage(km)
-- Formats a number of kilometers into a readable string for the contract.
-- Respects config.mileageUnit ("km" or "miles").
-- ─────────────────────────────────────────────────────────────────────────────
---@param km number
---@return string
function MileageBridge.formatMileage(km)
    local unit = config.mileageUnit or "km"

    if unit == "miles" then
        local miles = km * 0.621371
        return string.format("%.0f mi", miles)
    else
        -- Format in km with thousand separator (e.g. "12.543 km")
        local rounded = math.floor(km + 0.5)
        local formatted = tostring(rounded)
        -- Insert dots as thousand separators (BR standard)
        formatted = formatted:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
        return formatted .. " km"
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- getForDisplay(plate)
-- Main function called by main.lua.
-- Returns formatted string to display in the contract, or nil if disabled.
-- ─────────────────────────────────────────────────────────────────────────────
---@param plate string
---@return string|nil
function MileageBridge.getForDisplay(plate)
    if not config.mileageProvider or config.mileageProvider == "none" then
        return nil
    end
    if not plate or plate == "" then return nil end

    local km = MileageBridge.getRawKm(plate)
    if not km then return nil end

    return MileageBridge.formatMileage(km)
end
