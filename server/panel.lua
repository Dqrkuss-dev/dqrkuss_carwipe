-- Requests from the admin panel. Each one is checked here: admin, rate limit, known action, values. The client only
-- asks and shows the answer.
local VIEW_MS, WRITE_MS = 500, 1000
local refusedAt = {}

local function viewFor(src)
    local view = Wipe.view()

    view.kept = {}
    for i, entry in ipairs(Keep.list()) do
        view.kept[i] = { i = i, kind = entry.kind, model = entry.model, plate = entry.plate }
    end

    local ped = GetPlayerPed(src)
    local here = ped ~= 0 and GetEntityCoords(ped)
    view.zones = {}
    for i, zone in ipairs(Zones.list()) do
        view.zones[i] = {
            i = i, x = zone.x, y = zone.y, radius = zone.radius,
            dist = here and math.floor(CW.dist(here, zone) + 0.5) or nil,
        }
    end
    return view
end

local function ok(src)
    return { ok = true, view = viewFor(src) }
end

local function fail(err)
    return { ok = false, err = err }
end

local handlers = {}

function handlers.view(src)
    return ok(src)
end

for _, action in ipairs({ 'start', 'force', 'cancel' }) do
    handlers[action] = function(src)
        if not AdminAction(src, action) then return fail('refused') end
        return ok(src)
    end
end

function handlers.settings(src, data)
    local clean = CW.cleanSaved(data)
    if not clean then return fail('invalid') end
    Wipe.saveSettings(clean)
    Log(src, 'settings: every %d min, smart %d min', clean.interval, clean.smart)
    return ok(src)
end

function handlers.keep(src, data)
    local done, why = KeepCurrentCar(src, true, data.kind or 'car')
    if not done then return fail(why) end
    return ok(src)
end

function handlers.unkeep(src, data)
    local index = math.tointeger(tonumber(data.i))
    local entry = index and Keep.list()[index]
    if not entry or entry.plate ~= data.plate then return fail('unknown') end
    Keep.remove(index)
    Log(src, 'unkeep %s', entry.plate)
    return ok(src)
end

function handlers.zoneAdd(src, data)
    local ped = GetPlayerPed(src)
    if ped == 0 then return fail('busy') end
    local zone, why = Zones.add(GetEntityCoords(ped), data.radius, PlayerLabel(src))
    if not zone then return fail(why) end
    Log(src, 'safe zone added at %.1f %.1f, %d m', zone.x, zone.y, zone.radius)
    return ok(src)
end

function handlers.zoneRemove(src, data)
    local index = math.tointeger(tonumber(data.i))
    local zone = index and Zones.remove(index, data.x, data.y)
    if not zone then return fail('unknown') end
    Log(src, 'safe zone removed at %.1f %.1f', zone.x, zone.y)
    return ok(src)
end

function handlers.zoneGoto(src, data)
    local index = math.tointeger(tonumber(data.i))
    local zone = index and Zones.find(index, data.x, data.y)
    local ped = GetPlayerPed(src)
    if not zone or ped == 0 then return fail('unknown') end
    SetEntityCoords(ped, zone.x, zone.y, zone.z + 0.5, false, false, false, false)
    return ok(src)
end

-- -> reply, quiet (true: a repeated refusal that gets no answer)
function PanelRequest(src, action, data)
    local now = GetGameTimer()
    if refusedAt[src] and now - refusedAt[src] < 1000 then return fail('denied'), true end
    if type(action) ~= 'string' or not handlers[action] then return fail('unknown') end
    if src <= 0 or not IsAdmin(src) then
        refusedAt[src] = now
        return fail('denied')
    end
    refusedAt[src] = nil

    local isView = action == 'view'
    if Throttled(src, isView and 'panel:view' or 'panel:write', isView and VIEW_MS or WRITE_MS) then return fail('busy') end
    return handlers[action](src, type(data) == 'table' and data or {})
end

RegisterNetEvent('dqrkuss_carwipe:server:panel', function(requestId, action, data)
    local src = source
    if math.type(requestId) ~= 'integer' then return end
    local reply, quiet = PanelRequest(src, action, data)
    if not quiet then TriggerClientEvent('dqrkuss_carwipe:client:panelReply', src, requestId, reply) end
end)

AddEventHandler('playerDropped', function()
    refusedAt[source] = nil
end)
