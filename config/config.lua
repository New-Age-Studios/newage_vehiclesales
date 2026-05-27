return {
    -- Configuração geral
    debug = false, -- Ativa o modo de debug (mostra polyzones, vagas de veículos e local de venda)
    
    -- API FiveManage
    FiveManageToken = "r9m4GTCfIFu5BW6Ec5is49MA6PVJOc8u", -- Token da API do FiveManage (Obtenha em https://fivemanage.com/)
    FiveManageEndpoint = "https://api.fivemanage.com/api/v3/file", -- Endpoint da API do FiveManage

    -- Idioma do script ('pt-br' ou 'en')
    language = 'pt-br', -- Idioma do script ('pt-br' ou 'en')

    -- Configurações da Venda
    enableSellBack = true, -- Ativa/desativa a opção de vender veículo de volta para a concessionária
    sellBackPercentage = 50, -- Porcentagem do valor do veículo pago de volta (Ex: 50 para 50% do valor padrão)
    dealerFee = 50, -- Porcentagem da taxa (Ex: 15 para 15%. Coloque 0 para desativar)
    currencySymbol = "R$", -- Símbolo da moeda local (Ex: "R$", "$", "€")
    currencyCode = "BRL", -- Código da moeda local (Ex: "BRL", "USD", "EUR")

    -- Configurações cancelamento de venda
    showLocatorLine = true, -- Mostra uma linha vertical no veículo após o cancelamento para facilitar a localização

    -- ── Quilometragem ──────────────────────────────────────────────────────
    -- Provedor de quilometragem integrado ao contrato de compra/venda.
    --   "jg-vehiclemileage" — usa o resource jg-vehiclemileage (requer que esteja rodando)
    --   "custom"            — implemente em client/mileage_bridge.lua e server/mileage_bridge.lua
    --   "none"              — desativa a exibição de quilometragem no contrato
    mileageProvider = "jg-vehiclemileage",

    -- Unidade de distância exibida no contrato ("km" ou "miles")
    mileageUnit = "km",
    -- ──────────────────────────────────────────────────────────────────────

    -- ── Integração de VIN (Chassi) ─────────────────────────────────────────
    -- Ative se o seu servidor usa um MDT/sistema que exige a coluna `vin`
    -- na tabela player_vehicles (ex: piotreq_gpt).
    -- O gerador e a lógica de integração ficam em: server/vin_bridge.lua
    generateVIN = true,
    -- ──────────────────────────────────────────────────────────────────────

    -- Configurações do Target
    useTarget = true, -- Ativa/desativa o target (Se true, usa ox_target. Se false, usa blips)

    -- Configurações das Zonas
    zones = {
        senoracss = { -- Nome da zona
            businessName = "Concessionária de Usados", -- Nome da empresa
            sellVehicle = vec4(1233.26, 2730.52, 38.01, 270.66), -- Coordenadas da zona de venda (x, y, z, heading)
            buyVehicle = vec4(1213.31, 2735.4, 38.27, 182.5), -- Coordenadas da zona de compra (x, y, z, heading)
            pedModel = 's_m_m_autoshop_01', -- Modelo do NPC vendedor
            pedAnimDict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', -- Dicionário de animação
            pedAnimName = 'base', -- Nome da animação
            pedProp = 'prop_cs_tablet', -- Prop que ele segura (Ex: tablet)
            historyLocation = {
                coords = vec4(1224.23, 2729.02, 38.0, 180.0), -- Coordenadas (x, y, z, heading)
                usePed = true,                             -- Se true, spawna o NPC. Se false, usa apenas zona do ox_target
                pedModel = 's_m_m_autoshop_02',             -- Modelo do Ped (NPC)
                pedAnimDict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', -- Animação
                pedAnimName = 'base',                       -- Nome da animação
                pedProp = 'prop_cs_tablet',                  -- Prop do tablet na mão
                targetLabel = "Acessar Histórico e Anúncios", -- Texto exibido no target
                targetIcon = "fas fa-history",               -- Ícone exibido no target
                distance = 2.5                              -- Distância máxima de interação
            },
            polyzone = { -- The points that form the polyzone.
                vec3(1338.3748779297, 2645.0153808594, 36.0),
                vec3(1098.9381103516, 2621.7487792969, 36.0),
                vec3(1117.9478759766, 2822.0729980469, 36.0),
                vec3(1370.98828125, 2859.197265625, 36.0)
            },
            vehicleSpots = { -- The spots in which for sale cars are placed.
                vec4(1237.07, 2699, 38.27, 1.5),
                vec4(1232.98, 2698.92, 38.27, 2.5),
                vec4(1228.9, 2698.78, 38.27, 3.5),
                vec4(1224.9, 2698.51, 38.27, 2.5),
                vec4(1220.93, 2698.28, 38.27, 2.5),
                vec4(1216.97, 2698.05, 38.27, 0.5),
                vec4(1216.67, 2709.21, 38.27, 1.5),
                vec4(1220.67, 2709.26, 38.27, 1.5),
                vec4(1224.53, 2709.27, 38.27, 2.5),
                vec4(1228.52, 2709.42, 38.27, 1.5),
                vec4(1232.53, 2709.49, 38.27, 1.5),
                vec4(1236.71, 2709.51, 38.27, 1.6),
                vec4(1216.41, 2717.99, 38.27, 1.5),
                vec4(1220.39, 2718, 38.27, 0.5),
                vec4(1224.35, 2718.07, 38.27, 1.5),
                vec4(1228.41, 2718.22, 38.27, 1.5),
                vec4(1249.63, 2707.84, 38.27, 99.5),
                vec4(1248.92, 2712.25, 38.27, 101.5),
                vec4(1247.3, 2716.59, 38.27, 120.5),
                vec4(1244.09, 2720.4, 38.27, 149.5),
                vec4(1239.93, 2722.39, 38.27, 163.5),
                vec4(1248.28, 2727.41, 38.53, 338.5),
                vec4(1251.84, 2725.65, 38.52, 331.5),
                vec4(1255.19, 2723.21, 38.44, 309.5),
                vec4(1257.28, 2719.77, 38.49, 296.5)
            }
        }
    }
}
