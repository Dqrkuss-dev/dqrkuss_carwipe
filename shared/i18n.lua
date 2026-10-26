local FALLBACK = 'en'
local dictionaries = {}

local function load(locale)
    if dictionaries[locale] == nil then
        local raw = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(locale))
        local ok, data = pcall(json.decode, raw or '')
        dictionaries[locale] = ok and type(data) == 'table' and data or false
    end
    return dictionaries[locale] or nil
end

function Locale()
    local code = Config.Locale
    if type(code) == 'string' and code:match('^%a%a$') and load(code) then return code end
    return FALLBACK
end

-- Text for `key` in Config.Locale, else English, else the key itself. {name} is replaced by args.name.
function Text(key, args)
    local own = load(Locale())
    local template = own and own[key] or (load(FALLBACK) or {})[key]
    if type(template) ~= 'string' then return key end
    return (template:gsub('{([%w_]+)}', function(name)
        local value = args and args[name]
        return value ~= nil and tostring(value) or nil
    end))
end
