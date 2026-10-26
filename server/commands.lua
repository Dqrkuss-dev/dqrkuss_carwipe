local RES = GetCurrentResourceName()

local function commandName(value, default)
    return type(value) == 'string' and value:match('^[%w_]+$') and value or default
end

local ADMIN_COMMAND = commandName((Config.Admin or {}).command, 'carwipe')

function Notify(src, key, args, kind)
    if src > 0 then TriggerClientEvent('dqrkuss_carwipe:client:notify', src, key, args or {}, kind or 'inform') end
end

-- -> accepted
function AdminAction(src, action)
    local st = CW.settings(SavedSettings())
    local ok = false
    if action == 'start' then
        ok = Wipe.start(st.start, PlayerLabel(src))
    elseif action == 'force' then
        ok = Wipe.start(st.force, PlayerLabel(src))
    elseif action == 'cancel' then
        ok = Wipe.cancel()
    end
    if ok then Log(src, action) end
    return ok
end

-- kind: 'car' (default), 'model' or 'plate'. -> ok, reason, entry
function KeepCurrentCar(src, add, kind)
    local vehicle = Vehicles.ofPlayer(src)
    if not vehicle then return false, 'nocar' end

    if add then
        local entry, why = Keep.add(vehicle, Vehicles.plateCounts(), PlayerLabel(src), kind or 'car')
        if entry then Log(src, 'keep %s %s', entry.kind, entry.plate) end
        return entry ~= nil, why, entry
    end

    local index = Keep.indexOf(vehicle)
    if not index then return false, 'notkept' end
    local entry = Keep.remove(index)
    Log(src, 'unkeep %s', entry.plate)
    return true, nil, entry
end

local function keepCommand(src, action, kind)
    local ok, why, entry = KeepCurrentCar(src, action == 'keep', kind)
    if ok then
        local key = action == 'unkeep' and 'unkept' or entry.kind == 'car' and 'kept' or 'kept_' .. entry.kind
        Notify(src, key, { plate = entry.plate }, 'success')
    elseif why == 'invalid' then
        Notify(src, 'usage', { command = ADMIN_COMMAND })
    else
        Notify(src, 'keep_' .. why, nil, 'error')
    end
end

RegisterCommand(ADMIN_COMMAND, function(src, args)
    if not IsAdmin(src) then return Notify(src, 'denied', nil, 'error') end
    if src > 0 and Throttled(src, 'command', 1000) then return end

    local action = args[1] and args[1]:lower()
    if not action then
        if src == 0 then return print(('[%s] %s start | force | cancel'):format(RES, ADMIN_COMMAND)) end
        return TriggerClientEvent('dqrkuss_carwipe:client:panel', src)
    end

    if action == 'start' or action == 'force' or action == 'cancel' then
        local ok = AdminAction(src, action)
        if src == 0 then print(('[%s] %s: %s'):format(RES, action, ok and 'ok' or 'refused (running, blocked or nothing to cancel)')) end
        if not ok then Notify(src, 'refused', nil, 'error') end
        return
    end

    if (action == 'keep' or action == 'unkeep') and src > 0 then return keepCommand(src, action, args[2] and args[2]:lower()) end
    Notify(src, 'usage', { command = ADMIN_COMMAND })
end, false)

local saveCar = Config.SaveCar or {}
if saveCar.enabled ~= false then
    RegisterCommand(commandName(saveCar.command, 'savecar'), function(src)
        if src == 0 or Throttled(src, 'savecar', 1500) then return end
        local vehicle = Vehicles.ofPlayer(src)
        local ok = vehicle ~= nil and Wipe.saveCar(vehicle)
        Notify(src, ok and 'saved' or 'save_denied', nil, ok and 'success' or 'error')
    end, false)
end
