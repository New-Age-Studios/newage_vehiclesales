-- shared/locale.lua
-- Custom locale loader that reads from locales/<language>.json
-- Language is configured via config.language in config.lua

local _translations = {}

local config = require 'config.config'

local function loadLocale()
    local lang = config.language or 'pt-br'
    local rawJson = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(lang))

    if not rawJson then
        -- Fallback to pt-br if configured language file is missing
        rawJson = LoadResourceFile(GetCurrentResourceName(), 'locales/pt-br.json')
        if rawJson then
            print(('^3[newage_vehiclesales] ^7Warning: Could not load locale "%s", falling back to "pt-br"'):format(lang))
        else
            print('^1[newage_vehiclesales] ^7Error: Could not load any locale file!')
            return
        end
    end

    local decoded = json.decode(rawJson)
    if not decoded then
        print('^1[newage_vehiclesales] ^7Error: Failed to parse locale JSON!')
        return
    end

    -- Flatten nested keys with dot notation (e.g. "error.not_in_veh")
    local function flatten(tbl, prefix)
        for k, v in pairs(tbl) do
            local key = prefix and (prefix .. '.' .. k) or k
            if type(v) == 'table' then
                flatten(v, key)
            else
                _translations[key] = v
            end
        end
    end

    flatten(decoded, nil)
    print(('^2[newage_vehiclesales] ^7Locale loaded: ^5%s'):format(lang))
end

-- Expose global t() function for Lua scripts
function t(key, ...)
    local str = _translations[key]
    if not str then
        return key -- Return key itself if translation is missing
    end
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end

-- Keep backwards compatibility: locale() = t()
locale = t

-- Expose UI translations table for NUI injection
function getUiTranslations()
    local ui = {}
    for k, v in pairs(_translations) do
        if k:sub(1, 3) == 'ui.' then
            ui[k:sub(4)] = v  -- Strip "ui." prefix
        end
    end
    return ui
end

loadLocale()
