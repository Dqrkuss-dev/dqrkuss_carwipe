-- The admin keep list: one car (plate + model), a whole model or a plate that is never wiped, saved in the resource KVP.
Keep = {}

local KVP = 'dqrkuss_carwipe:keep'
local list = {}

local function save()
    if #list == 0 then
        DeleteResourceKvp(KVP)
    else
        SetResourceKvp(KVP, json.encode(list))
    end
end

local function load()
    local ok, data = pcall(json.decode, GetResourceKvpString(KVP) or '[]')
    list = {}
    for _, entry in ipairs(ok and type(data) == 'table' and data or {}) do
        if type(entry) == 'table' and type(entry.pm) == 'string' then
            entry.kind = CW.KEEP_KINDS[entry.kind] and entry.kind or 'car'
            list[#list + 1] = entry
        end
    end
end

local function keysOf(vehicle)
    local plate, model = Vehicles.plate(vehicle), Vehicles.model(vehicle)
    local keys = {}
    for kind in pairs(CW.KEEP_KINDS) do
        local key = CW.keepKey(kind, plate, model)
        if key then keys[key] = true end
    end
    return keys
end

-- The first entry that keeps this car, whatever its kind.
function Keep.indexOf(vehicle)
    local keys = keysOf(vehicle)
    for i, entry in ipairs(list) do
        if keys[entry.pm] then return i end
    end
    return nil
end

-- -> entry | nil, 'invalid' | 'noplate' | 'copied' | 'exists' | 'full'
function Keep.add(vehicle, plateCounts, by, kind)
    if not CW.KEEP_KINDS[kind] then return nil, 'invalid' end
    local plate, model = Vehicles.plate(vehicle), Vehicles.model(vehicle)
    local key = CW.keepKey(kind, plate, model)
    if not key then return nil, 'noplate' end
    if kind == 'car' and plateCounts[plate] ~= 1 then return nil, 'copied' end
    for _, entry in ipairs(list) do
        if entry.pm == key then return nil, 'exists' end
    end
    if #list >= CW.settings(SavedSettings()).keepMax then return nil, 'full' end

    local entry = { pm = key, kind = kind, plate = plate, model = model, by = by, at = os.time() }
    list[#list + 1] = entry
    save()
    return entry
end

function Keep.remove(index)
    if not list[index] then return nil end
    local entry = table.remove(list, index)
    save()
    return entry
end

function Keep.list()
    return list
end

load()
