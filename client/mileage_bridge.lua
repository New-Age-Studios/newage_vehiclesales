--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║              NEWAGE VEHICLESALES — MILEAGE BRIDGE (CLIENT)              ║
    ║                                                                          ║
    ║  Este arquivo é a ponte de quilometragem do sistema de vendas.           ║
    ║  Para trocar o sistema de quilometragem, edite APENAS este arquivo.      ║
    ║                                                                          ║
    ║  Provedores suportados (config.mileageProvider):                         ║
    ║    "jg-vehiclemileage" — usa exports do jg-vehiclemileage                ║
    ║    "custom"            — implemente getRawKm() abaixo                    ║
    ║    "none"              — desativa quilometragem (não exibe no contrato)  ║
    ╚══════════════════════════════════════════════════════════════════════════╝
--]]

local config = require 'config.config'

MileageBridge = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- getRawKm(plate)
-- Retorna a quilometragem numérica em KM para uma placa específica.
-- Implementação varia de acordo com config.mileageProvider.
-- ─────────────────────────────────────────────────────────────────────────────
---@param plate string  Placa do veículo (sem espaços)
---@return number|nil   Quilometragem em km ou nil se não disponível
function MileageBridge.getRawKm(plate)
    local provider = config.mileageProvider or "none"

    -- ── jg-vehiclemileage ─────────────────────────────────────────────────
    if provider == "jg-vehiclemileage" then
        if GetResourceState("jg-vehiclemileage") ~= "started" then
            return nil
        end

        -- Prioridade 1: statebag (já carregado pelo jg, sem roundtrip ao servidor)
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

        -- Prioridade 2: export getMileageByPlate (faz callback ao servidor jg)
        local ok, result = pcall(function()
            return exports["jg-vehiclemileage"]:getMileageByPlate(plate)
        end)
        if ok and result then
            return tonumber(result)
        end

        return nil

    -- ── custom ────────────────────────────────────────────────────────────
    -- Configure config.mileageProvider = "custom" e implemente aqui
    -- a busca pelo seu sistema de quilometragem.
    -- Esta função pode usar lib.callback.await pois é chamada de dentro
    -- de um contexto de thread (openSellContract / openBuyContract).
    elseif provider == "custom" then
        --[[ EXEMPLO 1: via export client-side de outro resource
        local ok, result = pcall(function()
            return exports["meu_mileage"]:getMileageByPlate(plate)
        end)
        if ok and result then return tonumber(result) end
        --]]

        --[[ EXEMPLO 2: via callback ao servidor
        local mileage = lib.callback.await("meu_mileage:getMileage", false, plate)
        return mileage and tonumber(mileage) or nil
        --]]

        return nil -- ← substitua pela sua implementação

    end

    return nil -- provider == "none" ou não reconhecido
end

-- ─────────────────────────────────────────────────────────────────────────────
-- formatMileage(km)
-- Formata um número de quilômetros como string legível para o contrato.
-- Respeita config.mileageUnit ("km" ou "miles").
-- ─────────────────────────────────────────────────────────────────────────────
---@param km number
---@return string
function MileageBridge.formatMileage(km)
    local unit = config.mileageUnit or "km"

    if unit == "miles" then
        local miles = km * 0.621371
        return string.format("%.0f mi", miles)
    else
        -- Formata em km com separador de milhar (ex: "12.543 km")
        local rounded = math.floor(km + 0.5)
        local formatted = tostring(rounded)
        -- Insere pontos como separador de milhar (padrão BR)
        formatted = formatted:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
        return formatted .. " km"
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- getForDisplay(plate)
-- Função principal chamada pelo main.lua.
-- Retorna string formatada para exibir no contrato, ou nil se desativado.
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
