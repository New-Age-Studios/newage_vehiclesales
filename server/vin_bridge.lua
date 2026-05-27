--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║              NEWAGE VEHICLESALES — VIN BRIDGE (SERVER)                  ║
    ║                                                                          ║
    ║  Este arquivo controla a geração de VIN (chassi) ao inserir um          ║
    ║  veículo na tabela player_vehicles após uma compra ou cancelamento.      ║
    ║                                                                          ║
    ║  Para trocar o gerador de VIN, edite APENAS este arquivo.               ║
    ║  Para ativar/desativar, use config.generateVIN = true/false             ║
    ╚══════════════════════════════════════════════════════════════════════════╝
--]]

VINBridge = {}

---Gera um VIN usando o resource configurado (piotreq_gpt por padrão).
---Se o resource não estiver rodando, usa um gerador genérico de 17 caracteres.
---@return string|nil  VIN gerado ou nil em caso de falha
function VINBridge.generate()
    -- ── piotreq_gpt ───────────────────────────────────────────────────────
    -- Usa o export oficial do piotreq_gpt quando estiver rodando
    if GetResourceState('piotreq_gpt') == 'started' then
        local ok, vin = pcall(function()
            return exports['piotreq_gpt']:GenerateVIN()
        end)
        if ok and vin and vin ~= '' then
            return vin
        end
    end

    -- ── custom ────────────────────────────────────────────────────────────
    -- Troque o bloco acima pela chamada ao seu resource de VIN caso seja outro.
    -- Exemplos:
    --
    -- if GetResourceState('meu_mdt') == 'started' then
    --     local ok, vin = pcall(function()
    --         return exports['meu_mdt']:GenerateVIN()
    --     end)
    --     if ok and vin and vin ~= '' then return vin end
    -- end

    -- ── Fallback genérico ─────────────────────────────────────────────────
    -- Usado quando nenhum resource de VIN está disponível mas a coluna é
    -- obrigatória no banco. Gera um VIN aleatório de 17 caracteres (padrão ISO 3779).
    local charset = "0123456789ABCDEFGHJKLMNPRSTUVWXYZ" -- sem I, O, Q (norma ISO)
    local vin = ""
    for _ = 1, 17 do
        local r = math.random(1, #charset)
        vin = vin .. charset:sub(r, r)
    end
    return vin
end

---Executa um INSERT em player_vehicles com ou sem a coluna `vin`,
---dependendo da configuração config.generateVIN.
---@param fields table  { license, citizenid, model, hash, mods, plate }
function VINBridge.insert(fields)
    local config = require 'config.config'

    local vin = fields.vin
    if not vin and config.generateVIN then
        local ok, genVin = pcall(VINBridge.generate)
        if ok and genVin and genVin ~= '' then
            vin = genVin
        else
            print("^1[newage_vehiclesales]^7 VINBridge.generate() falhou. Inserindo sem VIN gerado.")
        end
    end

    local mileage = fields.mileage or 0
    local damage = fields.damage
    local engine = fields.engine or 1000.0
    local body = fields.body or 1000.0

    if vin then
        MySQL.insert(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, vin, mileage, damage, engine, body) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            { fields.license, fields.citizenid, fields.model, fields.hash, fields.mods, fields.plate, 0, vin, mileage, damage, engine, body }
        )
    else
        MySQL.insert(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, mileage, damage, engine, body) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            { fields.license, fields.citizenid, fields.model, fields.hash, fields.mods, fields.plate, 0, mileage, damage, engine, body }
        )
    end
end
