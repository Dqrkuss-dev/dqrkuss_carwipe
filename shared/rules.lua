-- Pure rules without natives, shared by the server files and the specs.
CW = {}

-- A whole number clamped to [lo, hi]; anything that is not a finite number gives `default`.
function CW.int(value, lo, hi, default)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return default end
    return math.max(lo, math.min(hi, math.floor(value)))
end

local function tbl(value) return type(value) == 'table' and value or {} end

local function garageMode(value)
    if value == false or value == 'skip' then return value end
    return 'garage'
end

-- The settings in force: the config files, with the values saved in the panel on top.
function CW.settings(saved)
    local schedule, smart, zones, adv = tbl(Config.Schedule), tbl(Config.Smart), tbl(Config.SafeZones), tbl(Config.Advanced)
    saved = tbl(saved)
    local out = {
        enabled = schedule.enabled ~= false,
        interval = CW.int(schedule.intervalMinutes, 15, 1440, 120),
        countdown = CW.int(schedule.countdownMinutes, 1, 30, 10) * 60,
        smart = smart.enabled ~= false and CW.int(smart.minutes, 1, 240, 15) or 0,
        zones = zones.enabled ~= false,
        zoneRadius = CW.int(zones.radius, 5, 100, 25),
        start = CW.int(adv.startSeconds, 10, 1800, 60),
        force = CW.int(adv.forceSeconds, 5, 60, 10),
        retry = CW.int(adv.retrySeconds, 10, 600, 60),
        scan = CW.int(adv.scanSeconds, 5, 60, 10),
        move = CW.int(adv.moveMetres, 1, 50, 3),
        keepMax = CW.int(adv.keepMax, 1, 200, 200),
        zonesMax = CW.int(adv.zonesMax, 1, 100, 100),
        history = CW.int(adv.historySize, 1, 10, 10),
        garage = garageMode(tbl(Config.Garage).returnOwned),
        notices = {},
        states = {},
    }
    if saved.interval ~= nil then out.interval = CW.int(saved.interval, 15, 1440, out.interval) end
    if saved.smart ~= nil then out.smart = CW.int(saved.smart, 0, 240, out.smart) end

    local seen = {}
    for _, seconds in ipairs(tbl(schedule.notices)) do
        seconds = CW.int(seconds, 5, 1800, nil)
        if seconds and not seen[seconds] then
            seen[seconds] = true
            out.notices[#out.notices + 1] = seconds
        end
    end
    table.sort(out.notices, function(a, b) return a > b end)

    for _, key in ipairs(tbl(adv.protectedStates)) do
        if type(key) == 'string' and key ~= '' then out.states[#out.states + 1] = key end
    end

    local mode = tbl(Config.Announce).mode
    out.mode = (mode == 'chat' or mode == 'both') and mode or 'notify'
    return out
end

-- Panel settings: interval 15-1440 minutes, smart 0-240 minutes (0 = off). Out of range is refused, not clamped.
function CW.cleanSaved(data)
    if type(data) ~= 'table' then return nil end
    local interval, smart = tonumber(data.interval), tonumber(data.smart)
    if not interval or not smart or interval ~= interval or smart ~= smart then return nil end
    if interval < 15 or interval > 1440 or smart < 0 or smart > 240 then return nil end
    return { interval = math.floor(interval), smart = math.floor(smart) }
end

-- The smallest notice mark at or above the seconds left that was not shown yet.
function CW.noticeDue(remaining, notices, shown)
    if remaining <= 0 then return nil end
    local due
    for _, mark in ipairs(notices) do
        if remaining <= mark and not shown[mark] then due = due and math.min(due, mark) or mark end
    end
    return due
end

-- A short countdown shows one notice, so every bigger mark counts as shown too.
function CW.markShown(notices, shown, mark)
    for _, s in ipairs(notices) do
        if s >= mark then shown[s] = true end
    end
end

function CW.dist(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, (a.z or 0) - (b.z or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Last-used record of one car. A car seen for the first time counts as used now.
function CW.touch(record, pos, inUse, now, moveMetres)
    if not record then return { at = now, x = pos.x, y = pos.y, z = pos.z } end
    if inUse or CW.dist(record, pos) > moveMetres then record.at = now end
    record.x, record.y, record.z = pos.x, pos.y, pos.z
    return record
end

function CW.inZone(pos, zones)
    for _, zone in ipairs(zones) do
        if CW.dist(pos, zone) <= zone.radius then return true end
    end
    return false
end

-- A new safe zone radius from the panel: whole metres 5 to 100, anything else is refused.
function CW.zoneRadius(value)
    value = tonumber(value)
    if not value or value ~= value or value < 5 or value > 100 then return nil end
    return math.floor(value)
end

-- The panel names a zone by its index and position, so a list changed by another admin never removes the wrong one.
function CW.zoneMatches(zone, x, y)
    x, y = tonumber(x), tonumber(y)
    if not zone or not x or not y then return false end
    return math.abs(zone.x - x) < 0.5 and math.abs(zone.y - y) < 0.5
end

-- Keep-list keys. 'car': plate plus model, so a copied plate on another model never matches;
-- 'model': every car of that model; 'plate': every car with that plate.
CW.KEEP_KINDS = { car = true, model = true, plate = true }

function CW.keepKey(kind, plate, model)
    local hasPlate = type(plate) == 'string' and plate ~= ''
    if kind == 'car' and hasPlate and model then return ('%s:%d'):format(plate, model) end
    if kind == 'model' and model then return ('model:%d'):format(model) end
    if kind == 'plate' and hasPlate then return 'plate:' .. plate end
    return nil
end

-- Order matters: a player in a seat first, then other scripts' marks, /savecar, the keep list, safe zones, smart wipe.
function CW.decide(car)
    if car.occupied then return 'occupied' end
    if car.protected then return 'protected' end
    if car.saved then return 'saved' end
    if car.kept then return 'kept' end
    if car.zone then return 'zone' end
    if (car.smart or 0) > 0 and (car.idle or 0) < car.smart * 60 then return 'recent' end
    return 'remove'
end

function CW.pushHistory(list, entry, size)
    local out = { entry }
    for _, e in ipairs(tbl(list)) do
        if #out >= size then break end
        out[#out + 1] = e
    end
    return out
end
