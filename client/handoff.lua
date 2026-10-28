-- Server UI hand-off: popups, key prompts and timed work bars go to the server's own UI when one runs, else the
-- script draws its own. Shared kit: docs/kit/handoff.lua is copied unchanged into each product as client/handoff.lua
-- by docs/tools/sync_handoff_kit.py (edit the kit, never a copy). Settings, read from the script's Config:
--   Config.Notify      'auto' | 'own'   popups                                               default 'auto'
--   Config.Prompt      'auto' | 'own'   key prompts                                          default 'auto'
--   Config.Progress    'auto' | 'own'   timed work bars                                      default 'auto'
--   Config.NotifyOrder resources tried in this order, the first started one that can show it is used
--                      default { 'dqrkuss_lib', 'ox_lib', 'qb-core', 'es_extended' }
-- Any other resource name in the order is called like dqrkuss_lib: Notify{ title, description, type },
-- ShowTextUI(text, { key }) / HideTextUI(), Progress{ duration, label, canCancel, disable, anim }.
Handoff = {}

local ORDER = { 'dqrkuss_lib', 'ox_lib', 'qb-core', 'es_extended' }
local KINDS = { inform = true, success = true, warning = true, error = true }
local QB_KINDS = { inform = 'primary', success = 'success', warning = 'warning', error = 'error' }
local PROMPT_IDLE_MS = 300 -- a prompt not asked for this long hides itself (callers ask every frame, like help text)
local MISS_MS = 1000       -- a prompt no resource could show is drawn by the script for this long before looking again

local function auto(key)
    local value = type(Config) == 'table' and Config[key] or nil
    return value == nil or value == 'auto'
end

local function order()
    local list = type(Config) == 'table' and Config.NotifyOrder
    return type(list) == 'table' and list or ORDER
end

local function started(name)
    return type(name) == 'string' and GetResourceState(name) == 'started'
end

-- What each feature does with a known resource; a name not in the table is called like dqrkuss_lib.
local CAN = {
    notify = { ['qb-core'] = true, es_extended = true, ox_lib = true },
    prompt = { ['qb-core'] = true, es_extended = function() return started('esx_textui') end, ox_lib = true },
    progress = { ['qb-core'] = false, es_extended = false, ox_lib = true },
}

local function provider(feature)
    for _, candidate in ipairs(order()) do
        if started(candidate) then
            local can = CAN[feature][candidate]
            if type(can) == 'function' then can = can() end
            if can ~= false then return candidate end
        end
    end
end

-- === Popups ===

local NOTIFY = {
    ox_lib = function(_, text, kind, title) exports.ox_lib:notify({ title = title, description = text, type = kind }) end,
    ['qb-core'] = function(_, text, kind) TriggerEvent('QBCore:Notify', text, QB_KINDS[kind]) end,
    es_extended = function(_, text) TriggerEvent('esx:showNotification', text) end,
}
local function notifyBy(name, text, kind, title)
    exports[name]:Notify({ title = title, description = text, type = kind })
end

-- Handoff.notify(text, kind, title) -> true when the server's notifications took it; false: show the own popup.
-- kind: 'inform' | 'success' | 'warning' | 'error' (anything else = 'inform').
function Handoff.notify(text, kind, title)
    if not auto('Notify') then return false end
    kind = KINDS[kind] and kind or 'inform'
    local name = provider('notify')
    if not name then return false end
    return (pcall(NOTIFY[name] or notifyBy, name, tostring(text or ''), kind, title))
end

-- === Key prompts ===

-- GTA help text tokens -> key letters (the bound key when the game reports a keyboard key, else the default).
local INPUTS = {
    CONTEXT = { 51, 'E' }, PICKUP = { 38, 'E' }, DETONATE = { 47, 'G' }, ENTER = { 23, 'F' }, COVER = { 44, 'Q' },
    RELOAD = { 45, 'R' }, JUMP = { 22, 'SPACE' }, SPRINT = { 21, 'SHIFT' }, DUCK = { 36, 'CTRL' }, ATTACK = { 24, 'LMB' },
    AIM = { 25, 'RMB' }, VEH_EXIT = { 75, 'F' }, VEH_HORN = { 86, 'E' }, VEH_DUCK = { 73, 'X' }, ARREST = { 49, 'F' },
    FRONTEND_CANCEL = { 177, 'BACKSPACE' }, CELLPHONE_CANCEL = { 177, 'BACKSPACE' }, SELECT_WEAPON = { 37, 'TAB' },
}
local function keyOf(name)
    local input = INPUTS[name]
    if not input then return nil end
    local ok, label = pcall(GetControlInstructionalButton, 0, input[1], true)
    local letter = ok and type(label) == 'string' and label:match('^t_(.+)$')
    return letter or input[2]
end

-- "~INPUT_CONTEXT~ Open~n~~INPUT_DETONATE~ Repair" -> key 'E', rest 'Open', lines { '[E] Open', '[G] Repair' }
local function parse(raw)
    local key
    local lines = {}
    for line in (raw .. '~n~'):gmatch('(.-)~n~') do
        line = line:gsub('~INPUT_([%w_]+)~', function(name)
            local k = keyOf(name)
            if not k then return '' end
            key = key or k
            return '[' .. k .. ']'
        end)
        line = line:gsub('~[%w_]+~', ''):gsub('%s+', ' '):match('^%s*(.-)%s*$')
        if line ~= '' then lines[#lines + 1] = line end
    end
    local text = table.concat(lines, ' / ')
    local rest = text
    if key then
        local at = text:find('[' .. key .. ']', 1, true)
        rest = (text:sub(1, at - 1) .. text:sub(at + #key + 2)):gsub('%s+', ' '):match('^%s*(.-)%s*$')
    end
    return { key = key, text = text, rest = rest, lines = lines }
end

local function keyed(p, sep)
    return p.key and ('[' .. p.key .. ']' .. sep .. p.rest) or p.text
end

local SHOW = {
    ox_lib = function(_, p) exports.ox_lib:showTextUI(keyed(p, ' - ')) end,
    ['qb-core'] = function(_, p) TriggerEvent('qb-core:client:DrawText', keyed(p, ' '), 'left') end,
    es_extended = function(_, p) exports.esx_textui:TextUI(keyed(p, ' '), 'info') end,
}
local HIDE = {
    ox_lib = function() exports.ox_lib:hideTextUI() end,
    ['qb-core'] = function() TriggerEvent('qb-core:client:HideText') end,
    es_extended = function() exports.esx_textui:HideUI() end,
}
local function showBy(name, p) exports[name]:ShowTextUI(p.rest, { key = p.key }) end
local function hideBy(name) exports[name]:HideTextUI() end

local shown = nil   -- { raw, by } of the prompt on screen
local missed = nil  -- { raw, at } of the last prompt no resource could show
local lastAsk = 0
local watching = false

local function hideNow()
    if not shown then return false end
    local by = shown.by
    shown = nil
    pcall(HIDE[by] or hideBy, by)
    return true
end

local function watch()
    if watching then return end
    watching = true
    CreateThread(function()
        while shown do
            Wait(100)
            if shown and GetGameTimer() - lastAsk > PROMPT_IDLE_MS then hideNow() end
        end
        watching = false
    end)
end

-- Handoff.prompt(text) -> true when the server's prompt shows it; false: draw the own help text this frame.
-- Call it every frame while the prompt applies (GTA help text tokens like ~INPUT_CONTEXT~ and ~n~ are understood);
-- it is sent only when the text changes and hides itself shortly after the calls stop.
function Handoff.prompt(text)
    if not auto('Prompt') then return false end
    text = tostring(text or '')
    lastAsk = GetGameTimer()
    if shown and shown.raw == text then return true end
    if not shown and missed and missed.raw == text and lastAsk - missed.at < MISS_MS then return false end
    local name = provider('prompt')
    if shown and shown.by ~= name then hideNow() end
    if not name then
        missed = { raw = text, at = lastAsk }
        return false
    end
    missed = nil
    if not pcall(SHOW[name] or showBy, name, parse(text)) then
        hideNow()
        return false
    end
    shown = { raw = text, by = name }
    watch()
    return true
end

-- Handoff.hidePrompt() -> true when a prompt was on screen. Hides it at once (no need to wait for it to time out).
function Handoff.hidePrompt()
    return hideNow()
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then hideNow()
    elseif shown and shown.by == resource then shown = nil end
end)

-- === Work bars ===

-- Handoff.progress({ duration = ms, label, canCancel, disable = { move, car, combat, mouse }, anim = { dict, clip, flag } })
-- -> true finished, false cancelled, nil when no server bar runs (draw the own bar). Blocks: call it from a thread.
-- Only for plain timed bars (no skill or key games).
function Handoff.progress(opts)
    if not auto('Progress') then return nil end
    local name = provider('progress')
    if not name then return nil end
    opts = type(opts) == 'table' and opts or {}
    local data = {
        duration = math.floor(tonumber(opts.duration) or 1000),
        label = tostring(opts.label or ''),
        canCancel = opts.canCancel == true,
        useWhileDead = false,
        disable = type(opts.disable) == 'table' and opts.disable or nil,
        anim = type(opts.anim) == 'table' and opts.anim or nil,
    }
    local ok, done = pcall(function()
        if name == 'ox_lib' then return exports.ox_lib:progressBar(data) end
        return exports[name]:Progress(data)
    end)
    if not ok then return nil end
    return done == true
end
