-- Safe zones: cars inside are never wiped. Added in the panel at the admin's position, saved in the resource KVP.
Zones = {}

local KVP = 'dqrkuss_carwipe:zones'
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
    for _, zone in ipairs(ok and type(data) == 'table' and data or {}) do
        if type(zone) == 'table' and tonumber(zone.x) and tonumber(zone.y) and tonumber(zone.z) and CW.zoneRadius(zone.radius) then
            list[#list + 1] = zone
        end
    end
end

-- -> zone | nil, 'invalid' | 'full'
function Zones.add(coords, radius, by)
    radius = CW.zoneRadius(radius)
    if not radius then return nil, 'invalid' end
    if #list >= CW.settings(SavedSettings()).zonesMax then return nil, 'full' end

    local zone = {
        x = math.floor(coords.x * 100 + 0.5) / 100,
        y = math.floor(coords.y * 100 + 0.5) / 100,
        z = math.floor(coords.z * 100 + 0.5) / 100,
        radius = radius,
        by = by,
        at = os.time(),
    }
    list[#list + 1] = zone
    save()
    return zone
end

-- The zone at `index`, only when it is still at (x, y).
function Zones.find(index, x, y)
    local zone = list[index]
    return CW.zoneMatches(zone, x, y) and zone or nil
end

function Zones.remove(index, x, y)
    if not Zones.find(index, x, y) then return nil end
    local zone = table.remove(list, index)
    save()
    return zone
end

function Zones.list()
    return list
end

-- The zones that count for a wipe (none when safe zones are turned off).
function Zones.active()
    return CW.settings(SavedSettings()).zones and list or {}
end

load()
