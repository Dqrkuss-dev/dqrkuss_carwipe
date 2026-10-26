local RES = GetCurrentResourceName()
local lastUse = {}

local function aceName()
    local ace = (Config.Admin or {}).ace
    return type(ace) == 'string' and ace ~= '' and ace or 'carwipe.admin'
end

-- The console, the ace from Config.Admin.ace or a framework admin.
function IsAdmin(src)
    if src == 0 then return true end
    if math.type(src) ~= 'integer' or src < 0 then return false end
    return Framework.aceAllowed(src, aceName()) or Framework.isAdmin(src)
end

-- True when the player used `scope` less than `ms` ago; otherwise records this use.
function Throttled(src, scope, ms)
    local key = src .. ':' .. scope
    local now = GetGameTimer()
    if lastUse[key] and now - lastUse[key] < ms then return true end
    lastUse[key] = now
    return false
end

function PlayerLabel(src)
    if src == 0 then return 'console' end
    return (GetPlayerName(src) or ('#' .. src)):sub(1, 64)
end

-- Printed on the next tick: a print made while a player's command runs is also sent to that player's chat.
function Log(src, message, ...)
    local line = ('[%s] %s: %s'):format(RES, PlayerLabel(src), message:format(...))
    SetTimeout(0, function() print(line) end)
end

AddEventHandler('playerDropped', function()
    local prefix = source .. ':'
    for key in pairs(lastUse) do
        if key:sub(1, #prefix) == prefix then lastUse[key] = nil end
    end
end)
