return {
    -- General Settings
    debug = false, -- Enables debug mode (shows polyzones, vehicle spots and sell locations)
    
    -- FiveManage API
    FiveManageToken = "PUT YOUR TOKEN HERE", -- FiveManage API Token (Get it at https://fivemanage.com/)
    FiveManageEndpoint = "https://api.fivemanage.com/api/v3/file", -- FiveManage API Endpoint

    -- Script language ('pt-br' or 'en')
    language = 'en', -- Script language ('pt-br' or 'en')

    -- Sales Settings
    enableSellBack = true, -- Enable/disable the option to sell the vehicle back to the dealership
    sellBackPercentage = 50, -- Percentage of the vehicle's value paid back (Ex: 50 for 50% of the default value)
    dealerFee = 50, -- Fee percentage (Ex: 15 for 15%. Set to 0 to disable)
    currencySymbol = "$", -- Local currency symbol (Ex: "R$", "$", "€")
    currencyCode = "USD", -- Local currency code (Ex: "BRL", "USD", "EUR")
    allowImageUrl = true, -- Allows the player to use an Image Link (URL) instead of the in-game camera

    -- Sale Cancellation Settings
    showLocatorLine = true, -- Shows the location where the vehicle is after being returned

    -- Blacklist (Vehicles that cannot be sold at the dealership)
    blacklistedVehicles = {
        'adder',
        'zentorno'
    },

    -- ── Mileage ────────────────────────────────────────────────────────────
    -- Mileage provider integrated with the buy/sell contract.
    --   "jg-vehiclemileage" — uses the jg-vehiclemileage resource (must be running)
    --   "custom"            — implement in client/mileage_bridge.lua and server/mileage_bridge.lua
    --   "none"              — disables mileage display in the contract
    mileageProvider = "jg-vehiclemileage",

    -- Distance unit displayed in the contract ("km" or "miles")
    mileageUnit = "miles",
    -- ──────────────────────────────────────────────────────────────────────

    -- ── VIN (Chassis) Integration ──────────────────────────────────────────
    -- Enable if your server uses an MDT/system that requires the `vin` column
    -- in the player_vehicles table (ex: piotreq_gpt).
    -- The generator and integration logic are located in: server/vin_bridge.lua
    generateVIN = false,
    -- ──────────────────────────────────────────────────────────────────────

    -- Target Settings
    useTarget = true, -- Enable/disable target (If true, uses ox_target. If false, uses blips)

    -- Zones Settings
    zones = {
        senoracss = { -- Zone name
            businessName = "Used Car Dealership", -- Business name
            -- Allowed Vehicle Classes (GTA 5 vehicle classes)
            -- Common classes: 0-12 (Cars/SUVs/Vans), 8 (Motorcycles), 13 (Bicycles), 14 (Boats), 15 (Helicopters), 16 (Planes), 20 (Commercial), 22 (Open Wheel)
            -- If empty or missing, all classes are allowed.
            allowedClasses = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 20, 22 },
            sellVehicle = vec4(1233.26, 2730.52, 38.01, 270.66), -- Sell zone coordinates (x, y, z, heading)
            buyVehicle = vec4(1213.31, 2735.4, 38.27, 182.5), -- Buy zone coordinates (x, y, z, heading)
            pedModel = 's_m_m_autoshop_01', -- Seller NPC model
            pedAnimDict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', -- Animation dictionary
            pedAnimName = 'base', -- Animation name
            pedProp = 'prop_cs_tablet', -- Prop held by the NPC (Ex: tablet)
            historyLocation = {
                coords = vec4(1224.23, 2729.02, 38.0, 180.0), -- Coordinates (x, y, z, heading)
                usePed = true,                             -- If true, spawns the NPC. If false, only uses ox_target zone
                pedModel = 's_m_m_autoshop_02',             -- Ped (NPC) Model
                pedAnimDict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', -- Animation dictionary
                pedAnimName = 'base',                       -- Animation name
                pedProp = 'prop_cs_tablet',                  -- Tablet prop in hand
                targetLabel = "Access History and Ads", -- Text displayed on target
                targetIcon = "fas fa-history",               -- Icon displayed on target
                distance = 2.5                              -- Maximum interaction distance
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
