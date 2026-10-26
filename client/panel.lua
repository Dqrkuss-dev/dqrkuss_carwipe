-- The admin panel (/carwipe). While it is open the mouse belongs to the panel and the keyboard still drives; only
-- mouse look, shooting, the weapon wheel and the pause menu are blocked. The server checks every request.
local open = false
local focused = false
local typing = false
local opening = false
local pending = {}
local lastRequest = 0

local MOUSE_CONTROLS = { 1, 2, 3, 4, 5, 6, 14, 15, 16, 17, 24, 25, 37, 66, 67, 68, 69, 70, 81, 82, 83, 84, 85, 91, 92, 99, 100, 106, 114, 115, 116, 140, 141, 142, 257, 263, 264 }
local PAUSE_CONTROLS = { 199, 200 }
local ESC = 200
local REFRESH_MS = 5000
local ACTIONS = { start = true, force = true, cancel = true, settings = true, keep = true, unkeep = true, zoneAdd = true, zoneRemove = true, zoneGoto = true }
local ERRORS = {
    denied = 'err_denied', refused = 'fb_refused', invalid = 'err_invalid', unknown = 'err_unknown', full = 'err_full',
    nocar = 'fb_keep_nocar', noplate = 'fb_keep_noplate', copied = 'fb_keep_copied', exists = 'fb_keep_exists',
}

local function request(action, data)
    lastRequest = lastRequest + 1
    local id, p = lastRequest, promise.new()
    pending[id] = p
    TriggerServerEvent('dqrkuss_carwipe:server:panel', id, action, data or {})
    SetTimeout(10000, function()
        if pending[id] then
            pending[id] = nil
            p:resolve({ ok = false, err = 'busy' })
        end
    end)
    return Citizen.Await(p)
end

RegisterNetEvent('dqrkuss_carwipe:client:panelReply', function(id, reply)
    local p = pending[id]
    if not p then return end
    pending[id] = nil
    p:resolve(type(reply) == 'table' and reply or { ok = false, err = 'busy' })
end)

local function carName(model)
    model = math.tointeger(tonumber(model))
    if not model then return nil end
    if model > 0x7FFFFFFF then model = model - 0x100000000 end
    local name = GetDisplayNameFromVehicleModel(model)
    if not name or name == '' or name == 'CARNOTFOUND' then return nil end
    local label = GetLabelText(name)
    return label ~= 'NULL' and label or name
end

local function withCommand(view)
    view.command = CommandOf(Config.Admin, 'carwipe')
    for _, entry in ipairs(view.kept or {}) do
        if entry.kind ~= 'plate' then entry.label = carName(entry.model) end
    end
    return view
end

local function setFocus(on)
    if focused == on then return end
    focused = on
    typing = false
    SetNuiFocus(on, on)
    SetNuiFocusKeepInput(on)
    SendUi('focus', on)
end

-- While a number box has the keyboard, keys go to the box only.
local function setTyping(on)
    if typing == on or not focused then return end
    typing = on
    SetNuiFocusKeepInput(not on)
end

local function close()
    if not open then return end
    open = false
    setFocus(false)
    SendUi('close')
end

local function refresh()
    if not open then return end
    local reply = request('view')
    if open and reply.ok then SendUi('view', withCommand(reply.view)) end
end

function RefreshPanel()
    if open then CreateThread(refresh) end
end

local function blockControls()
    for _, control in ipairs(MOUSE_CONTROLS) do DisableControlAction(0, control, true) end
    for _, control in ipairs(PAUSE_CONTROLS) do DisableControlAction(0, control, true) end
end

local function watch()
    CreateThread(function()
        local nextRefresh = GetGameTimer() + REFRESH_MS
        while open do
            blockControls()
            if not typing and IsDisabledControlJustPressed(0, ESC) then close() end
            if open and GetGameTimer() >= nextRefresh then
                nextRefresh = GetGameTimer() + REFRESH_MS
                CreateThread(refresh)
            end
            Wait(0)
        end
        -- The Esc that closed the panel must not open the pause menu.
        local untilAt = GetGameTimer() + 400
        while not open and GetGameTimer() < untilAt do
            for _, control in ipairs(PAUSE_CONTROLS) do DisableControlAction(0, control, true) end
            Wait(0)
        end
    end)
end

local function openPanel()
    if opening or open then return end
    opening = true
    local reply = request('view')
    opening = false
    if not reply.ok then return Toast(Text(ERRORS[reply.err] or 'err_busy'), 'error') end
    if open then return end
    open = true
    SendUi('open', withCommand(reply.view))
    setFocus(true)
    watch()
end

RegisterNetEvent('dqrkuss_carwipe:client:panel', function()
    if open then close() else CreateThread(openPanel) end
end)

RegisterNUICallback('request', function(data, cb)
    if not open or type(data) ~= 'table' or not ACTIONS[data.action] then return cb({ ok = false, err = 'busy' }) end
    local reply = request(data.action, type(data.data) == 'table' and data.data or {})
    if reply.view and open then SendUi('view', withCommand(reply.view)) end
    if reply.err == 'denied' then close() end
    cb({ ok = reply.ok == true, err = reply.err })
end)

RegisterNUICallback('close', function(_, cb)
    close()
    cb({ ok = true })
end)

RegisterNUICallback('typing', function(data, cb)
    if open and type(data) == 'table' then setTyping(data.on == true) end
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and focused then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)

-- Used by the specs.
PanelClient = { isOpen = function() return open end, close = close }
