-- The schedule, the countdown and the wipe itself. Every decision is made here from server data; no client message
-- decides what is deleted. Only world entities are removed, garage rows are never deleted.
Wipe = {}

local RES = GetCurrentResourceName()
local SETTINGS_KVP = 'dqrkuss_carwipe:settings'
local HISTORY_KVP = 'dqrkuss_carwipe:history'

local function readKvp(key)
    local ok, value = pcall(json.decode, GetResourceKvpString(key) or '')
    return ok and type(value) == 'table' and value or nil
end

local saved = readKvp(SETTINGS_KVP)
local history = readKvp(HISTORY_KVP) or {}
local blocks = {}         -- resource -> reason
local savedCars = {}      -- vehicle -> countdown cycle in which /savecar was used
local countdownEnds = nil -- os.time() the running countdown ends at
local wiping = false
local shown = {}
local cycle = 0
local startedBy = 'auto'
local lastWipe = os.time() -- the next scheduled wipe is due one interval after this

function SavedSettings()
    return saved
end

local function settings()
    return CW.settings(saved)
end

function Wipe.saveSettings(clean)
    saved = clean
    SetResourceKvp(SETTINGS_KVP, json.encode(saved))
end

local function dueAt()
    return lastWipe + settings().interval * 60
end

local function blocked()
    return next(blocks) ~= nil
end

-- Other scripts read GlobalState.dqCarwipe = {wiping, countdown}; nil while nothing runs.
local function publish()
    GlobalState.dqCarwipe = (wiping or countdownEnds) and { wiping = wiping, countdown = countdownEnds } or nil
end

local function announce(kind, args)
    TriggerClientEvent('dqrkuss_carwipe:client:announce', -1, kind, args or {}, settings().mode)
end

local function clearSavedCars()
    for vehicle in pairs(savedCars) do savedCars[vehicle] = nil end
end

-- by: who started it, shown in the history ('auto' for the schedule)
function Wipe.start(seconds, by)
    if wiping or countdownEnds or blocked() then return false end
    cycle = cycle + 1
    countdownEnds = os.time() + seconds
    startedBy = by
    shown = {}
    clearSavedCars()
    CW.markShown(settings().notices, shown, seconds)
    publish()
    announce('countdown', { seconds = seconds })
    return true
end

function Wipe.cancel()
    if not countdownEnds or wiping then return false end
    countdownEnds = nil
    lastWipe = os.time()
    clearSavedCars()
    publish()
    announce('cancelled')
    return true
end

function Wipe.saveCar(vehicle)
    if not countdownEnds or wiping or not Vehicles.exists(vehicle) then return false end
    savedCars[vehicle] = cycle
    return true
end

local function protected(vehicle, keys)
    local state = Entity(vehicle).state
    for _, key in ipairs(keys) do
        local value = state[key]
        if value ~= nil and value ~= false then return true end
    end
    return false
end

-- DeleteEntity is asynchronous with OneSync; the garage row is written only once the car is really gone.
local function gone(vehicle)
    for i = 1, 20 do
        if not Vehicles.exists(vehicle) then return true end
        Wait(i == 1 and 0 or 100)
    end
    return false
end

local function decide(vehicle, st, zones)
    local pos = GetEntityCoords(vehicle)
    return CW.decide({
        occupied = Vehicles.occupied(vehicle),
        protected = protected(vehicle, st.states),
        saved = savedCars[vehicle] == cycle,
        kept = Keep.indexOf(vehicle) ~= nil,
        zone = CW.inZone({ x = pos.x, y = pos.y, z = pos.z }, zones),
        idle = Touch.idle(vehicle),
        smart = st.smart,
    })
end

-- -> 'removed' | 'garage' | 'skipped'
local function wipeOne(vehicle, st, zones, plateCounts)
    if not Vehicles.exists(vehicle) or decide(vehicle, st, zones) ~= 'remove' then return 'skipped' end

    local car
    if st.garage then
        car = Garage.lookup(vehicle, plateCounts)
        if car == false or (car and st.garage == 'skip') then return 'skipped' end
    end
    local fuel, engine, body
    if car then fuel, engine, body = Garage.condition(vehicle) end

    -- The lookup above can yield; a player may have got in meanwhile.
    if Vehicles.occupied(vehicle) then return 'skipped' end
    DeleteEntity(vehicle)

    if not car then return 'removed' end
    if not gone(vehicle) then return 'skipped' end
    return Garage.store(car, fuel, engine, body) and 'garage' or 'removed'
end

local function execute()
    if blocked() then return end
    wiping = true
    publish()

    local st = settings()
    Touch.scan()
    local zones = Zones.active()
    local plateCounts = Vehicles.plateCounts()
    local counts = { removed = 0, garage = 0, skipped = 0 }
    for _, vehicle in ipairs(GetAllVehicles()) do
        if blocked() then break end
        local ok, result = pcall(wipeOne, vehicle, st, zones, plateCounts)
        if not ok then
            print(('^1[%s] %s^7'):format(RES, result))
            result = 'skipped'
        end
        counts[result] = counts[result] + 1
        Wait(0)
    end

    wiping, countdownEnds = false, nil
    lastWipe = os.time()
    clearSavedCars()
    local entry = { at = os.time(), removed = counts.removed, garage = counts.garage, skipped = counts.skipped, by = startedBy }
    history = CW.pushHistory(history, entry, st.history)
    SetResourceKvp(HISTORY_KVP, json.encode(history))
    publish()
    announce('finished', { removed = counts.removed + counts.garage, garage = counts.garage })
    Log(0, 'wipe done, %d removed, %d sent to their garage, %d skipped', counts.removed, counts.garage, counts.skipped)
end

local function tick()
    local now, st = os.time(), settings()
    if blocked() then
        if countdownEnds and countdownEnds - now < st.retry then
            countdownEnds = now + st.retry
            publish()
        end
        return
    end

    if not countdownEnds then
        if st.enabled and not wiping and now >= dueAt() then Wipe.start(st.countdown, 'auto') end
        return
    end

    local remaining = countdownEnds - now
    local mark = CW.noticeDue(remaining, st.notices, shown)
    if mark then
        CW.markShown(st.notices, shown, mark)
        announce('countdown', { seconds = math.max(1, remaining) })
    end
    if remaining <= 0 then execute() end
end

CreateThread(function()
    while true do
        local ok, err = pcall(tick)
        if not ok then
            wiping = false
            print(('^1[%s] %s^7'):format(RES, err))
        end
        Wait(1000)
    end
end)

function Wipe.view()
    local st, now = settings(), os.time()
    local reasons = {}
    for resource, why in pairs(blocks) do reasons[#reasons + 1] = resource .. ': ' .. why end
    table.sort(reasons)

    local rows = {}
    for _, h in ipairs(history) do
        rows[#rows + 1] = { when = os.date('%d.%m %H:%M', h.at), removed = h.removed, garage = h.garage, skipped = h.skipped, by = h.by }
    end

    local state = wiping and 'wiping' or countdownEnds and 'countdown' or st.enabled and 'waiting' or 'off'
    local left
    if countdownEnds then
        left = math.max(0, countdownEnds - now)
    elseif st.enabled then
        left = math.max(0, dueAt() - now)
    end
    return {
        state = state, left = left, interval = st.interval, smart = st.smart, blocked = reasons, history = rows,
        keepMax = st.keepMax, zonesMax = st.zonesMax, zonesOn = st.zones, zoneRadius = st.zoneRadius,
    }
end

-- Each calling resource owns one blocker; it is freed when that resource stops.
exports('SetCarwipeBlocked', function(enabled, reason)
    local owner = GetInvokingResource()
    if not owner then return false end
    blocks[owner] = enabled and tostring(reason or 'busy'):sub(1, 120) or nil
    return true
end)

exports('GetCarwipeState', function()
    return { countdown = countdownEnds, blocked = blocked(), wiping = wiping, nextAt = countdownEnds or dueAt() }
end)

AddEventHandler('onResourceStop', function(resource)
    blocks[resource] = nil
    if resource == RES then GlobalState.dqCarwipe = nil end
end)

AddEventHandler('entityRemoved', function(entity)
    savedCars[entity] = nil
end)

-- Used by the specs.
function Wipe.state()
    return { countdown = countdownEnds, wiping = wiping, due = dueAt(), history = history }
end
