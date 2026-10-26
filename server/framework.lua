Framework = {}

local function started(name)
    return GetResourceState(name) == 'started'
end

-- IsPlayerAceAllowed answers true or 1 depending on the server build.
function Framework.aceAllowed(src, ace)
    local allowed = IsPlayerAceAllowed(src, ace)
    return allowed == true or allowed == 1
end

local function listOf(value, default)
    local out = {}
    for _, item in ipairs(type(value) == 'table' and value or default) do
        if type(item) == 'string' then out[#out + 1] = item end
    end
    return out
end

-- 'qbx' | 'qb' | 'esx' | nil. Checked on every call, so a framework started late is still found.
function Framework.name()
    if started('qbx_core') then return 'qbx' end
    if started('qb-core') then return 'qb' end
    if started('es_extended') then return 'esx' end
    return nil
end

function Framework.hasDatabase()
    return started('oxmysql')
end

-- Qbox gives its permission groups to players as aces (add_ace group.admin admin allow).
local function qbxAdmin(src, groups)
    for _, group in ipairs(groups) do
        if Framework.aceAllowed(src, group) then return true end
    end
    return false
end

local function qbAdmin(src, groups)
    local QBCore = exports['qb-core']:GetCoreObject()
    for _, group in ipairs(groups) do
        if QBCore.Functions.HasPermission(src, group) then return true end
    end
    return false
end

local function esxAdmin(src, groups)
    local xPlayer = exports.es_extended:getSharedObject().GetPlayerFromId(src)
    if not xPlayer then return false end
    local group = xPlayer.getGroup()
    for _, name in ipairs(groups) do
        if group == name then return true end
    end
    return false
end

function Framework.isAdmin(src)
    local admin = Config.Admin or {}
    if admin.framework == false then return false end

    local name = Framework.name()
    local check = name == 'qbx' and qbxAdmin or name == 'qb' and qbAdmin or name == 'esx' and esxAdmin
    if not check then return false end

    local groups = name == 'esx' and listOf(admin.esxGroups, { 'admin', 'superadmin' }) or listOf(admin.groups, { 'admin', 'god' })
    local ok, result = pcall(check, src, groups)
    return ok and result == true
end
