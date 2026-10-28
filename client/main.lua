-- Shows what the server announces (countdown card, notices, chat lines) and the answers to commands.
function SendUi(action, data)
    SendNUIMessage({ action = action, data = data, locale = Locale() })
end

-- Popups: the server's notifications when one runs (Config.Notify 'auto', client/handoff.lua), else this script's own toasts.
local NOTIFY_KINDS = { inform = true, success = true, warning = true, error = true }

function Toast(text, kind)
    kind = NOTIFY_KINDS[kind] and kind or 'inform'
    if not Handoff.notify(text, kind, Text('title')) then SendUi('toast', { text = text, kind = kind }) end
end

function CommandOf(cfg, default)
    local name = cfg and cfg.command
    return type(name) == 'string' and name:match('^[%w_]+$') and name or default
end

local function saveCommand()
    local cfg = Config.SaveCar
    if cfg and cfg.enabled == false then return nil end
    return '/' .. CommandOf(cfg, 'savecar')
end

local function timeText(seconds)
    seconds = math.max(1, math.floor(tonumber(seconds) or 0))
    if seconds >= 120 or (seconds >= 60 and seconds % 60 == 0) then
        return Text('time_min', { n = math.ceil(seconds / 60) })
    end
    return Text('time_sec', { n = seconds })
end

local function chatLine(text)
    TriggerEvent('chat:addMessage', { color = { 255, 196, 0 }, multiline = true, args = { Text('title'), text } })
end

local ANNOUNCE_KIND = { countdown = 'warning', cancelled = 'inform', finished = 'success' }

-- Config.Announce.card 'notify': each warning as a server notification (client/handoff.lua) when one runs; 'top' (or no
-- notification resource): this script's countdown card at the top of the screen.
local function warningAsNotice(text)
    local cfg = type(Config.Announce) == 'table' and Config.Announce or {}
    return cfg.card == 'notify' and Handoff.notify(text, 'warning', Text('title'))
end

local function announceText(kind, args)
    if kind == 'countdown' then
        return Text('notice_countdown', { time = timeText(args.seconds), command = saveCommand() or '-' })
    elseif kind == 'cancelled' then
        return Text('notice_cancelled')
    end
    return Text('notice_finished', { removed = tonumber(args.removed) or 0, garage = tonumber(args.garage) or 0 })
end

RegisterNetEvent('dqrkuss_carwipe:client:announce', function(kind, args, mode)
    if not ANNOUNCE_KIND[kind] then return end
    local text = announceText(kind, args)

    if mode == 'chat' or mode == 'both' then chatLine(text) end
    if mode ~= 'chat' then
        if kind == 'countdown' then
            local seconds = math.max(0, math.floor(tonumber(args.seconds) or 0))
            if not warningAsNotice(text) then SendUi('countdown', { seconds = seconds, command = saveCommand() }) end
        else
            SendUi('countdown_end')
            Toast(text, ANNOUNCE_KIND[kind])
        end
    end
    RefreshPanel()
end)

local NOTICES = {
    saved = true, save_denied = true, denied = true, refused = true, kept = true, kept_model = true, kept_plate = true, unkept = true,
    usage = true, keep_nocar = true, keep_noplate = true, keep_copied = true, keep_exists = true, keep_full = true,
    keep_notkept = true,
}

RegisterNetEvent('dqrkuss_carwipe:client:notify', function(key, args, kind)
    if not NOTICES[key] then key = 'refused' end
    Toast(Text('fb_' .. key, args), kind)
end)

CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. CommandOf(Config.Admin, 'carwipe'), Text('help_admin'), {
        { name = 'action', help = Text('help_admin_arg') },
    })
    local save = saveCommand()
    if save then TriggerEvent('chat:addSuggestion', save, Text('help_savecar')) end
end)
