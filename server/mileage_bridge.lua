--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║              NEWAGE VEHICLESALES — MILEAGE BRIDGE (SERVER)              ║
    ║                                                                          ║
    ║  Callback server-side para buscar quilometragem quando o client-side     ║
    ║  não consegue via statebag (ex: veículo não está spawnado no momento).   ║
    ║                                                                          ║
    ║  Para usar outro sistema, edite APENAS este arquivo.                     ║
    ╚══════════════════════════════════════════════════════════════════════════╝
--]]

local config = require 'config.config'

-- ─────────────────────────────────────────────────────────────────────────────
-- Callback: newage_vehiclesales:server:getMileage
-- Busca a quilometragem de um veículo pela placa.
-- Chamado pelo openBuyContract quando o contrato do comprador é aberto.
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
    -- Configure config.mileageProvider = "custom" no config.lua e
    -- implemente aqui a busca via banco de dados ou export do seu resource.
    elseif provider == "custom" then
        --[[ EXEMPLO 1: busca direta no banco (se você armazena na tabela player_vehicles)
        local result = MySQL.scalar.await("SELECT mileage FROM player_vehicles WHERE plate = ?", { plate })
        return result and tonumber(result) or nil
        --]]

        --[[ EXEMPLO 2: via export de outro resource server-side
        local ok, result = pcall(function()
            return exports["meu_mileage"]:getMileageByPlate(plate)
        end)
        if ok and result then return tonumber(result) end
        --]]

        return nil -- ← substitua pela sua implementação
    end

    return nil
end)
