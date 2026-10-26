-- Owned cars go back to their own garage. An adapter knows where a garage script keeps its cars: the built-in
-- 'framework' adapter reads Qbox / QBCore player_vehicles and ESX owned_vehicles through oxmysql. A garage script with
-- its own table gets its own adapter in server/garages/ (see example.lua there), picked with Config.Garage.adapter.
Garage = {}

local adapters = {}

-- adapter = {
--   lookup = function(vehicle, plate, model) -> car table (the owner and whatever store needs) | nil (not owned, or
--            already stored) | false (ownership unknown: the car is left alone),
--   store  = function(car, fuel, engine, body) -> rows changed (0 when nothing matched) | nil on a database error,
-- }
function Garage.register(name, adapter)
    assert(type(name) == 'string' and type(adapter) == 'table', 'Garage.register(name, adapter)')
    assert(type(adapter.lookup) == 'function' and type(adapter.store) == 'function', 'an adapter needs lookup and store')
    adapters[name] = adapter
end

local function adapterName()
    local name = (Config.Garage or {}).adapter
    return type(name) == 'string' and name ~= '' and name or 'framework'
end

local TABLES = {
    qb = { name = 'player_vehicles', owner = 'citizenid', flag = 'state' },
    esx = { name = 'owned_vehicles', owner = 'owner', flag = 'stored' },
}

local columnCache = {}

-- oxmysql's callback exports work on every oxmysql version. nil when the database does not answer in 10 s.
-- kind: 'query' (rows), 'update' (rows changed), 'scalar', 'single' or 'insert'. Adapters use it as Garage.query.
local function query(kind, sql, params)
    local p = promise.new()
    local done = false
    local function finish(result)
        if done then return end
        done = true
        p:resolve(result)
    end
    exports.oxmysql[kind](exports.oxmysql, sql, params, finish)
    SetTimeout(10000, finish)
    return Citizen.Await(p)
end
Garage.query = query

-- Garage scripts add their own columns (in_garage, impound, fuel, engine, body), so the write
-- adapts to what the table really has.
local function columns(tableName)
    if columnCache[tableName] then return columnCache[tableName] end
    local rows = query('query', 'SELECT COLUMN_NAME AS c FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?', { tableName })
    if type(rows) ~= 'table' or #rows == 0 then return nil end
    local set = {}
    for _, row in ipairs(rows) do set[row.c] = true end
    columnCache[tableName] = set
    return set
end

-- oxmysql returns TINYINT(1) columns as booleans and wider ones as numbers.
local function flag(value)
    if value == true then return 1 end
    if value == false then return 0 end
    return tonumber(value)
end

local function rowModel(row, framework)
    if framework == 'esx' then
        local ok, props = pcall(json.decode, row.vehicle or '')
        return ok and type(props) == 'table' and Vehicles.unsigned(props.model) or nil
    end
    local byName = type(row.vehicle) == 'string' and Vehicles.unsigned(GetHashKey(row.vehicle))
    return Vehicles.unsigned(row.hash) or byName or nil
end

local function isOut(row, t)
    if row.in_garage ~= nil then return flag(row.in_garage) == 0 end
    return flag(row[t.flag]) == 0
end

local function isImpounded(row, t)
    if row.impound ~= nil and flag(row.impound) == 1 then return true end
    return t.flag == 'state' and flag(row.state) == 2
end

local function frameworkLookup(_, plate, model)
    local framework = Framework.name()
    if not framework then return nil end
    if not Framework.hasDatabase() then return false end

    local t = framework == 'esx' and TABLES.esx or TABLES.qb
    local rows = query('query', ('SELECT * FROM `%s` WHERE UPPER(TRIM(plate)) = ? LIMIT 2'):format(t.name), { plate })
    if type(rows) ~= 'table' or #rows > 1 then return false end

    local row = rows[1]
    if not row then return nil end
    local owner = row[t.owner]
    if type(owner) ~= 'string' or owner == '' then return nil end
    if rowModel(row, framework) ~= model then return nil end
    if not isOut(row, t) or isImpounded(row, t) then return nil end

    return { owner = owner, table = t }
end

-- Fuel, engine and body of the car, read before it is deleted. Fuel scripts that sync through the `fuel` state bag
-- (ox_fuel and most others) are read from it; when the level is unknown the stored value is left alone.
function Garage.condition(vehicle)
    local fuel = tonumber(Entity(vehicle).state.fuel)
    if not fuel and GetVehicleFuelLevel then fuel = tonumber(GetVehicleFuelLevel(vehicle)) end
    if fuel then fuel = math.max(0, math.min(100, math.floor(fuel))) end
    return fuel, GetVehicleEngineHealth(vehicle) + 0.0, GetVehicleBodyHealth(vehicle) + 0.0
end

-- ESX keeps fuel, engine and body in the `vehicle` JSON unless a garage script added columns for them.
local function esxProps(cols, fuel, engine, body)
    if not cols.vehicle or cols.fuel or cols.engine or cols.body then return nil end
    local paths, values = {}, {}
    for _, pair in ipairs({ { 'fuelLevel', fuel }, { 'engineHealth', engine }, { 'bodyHealth', body } }) do
        if pair[2] ~= nil then
            paths[#paths + 1] = ("'$.%s', ?"):format(pair[1])
            values[#values + 1] = pair[2]
        end
    end
    if #values == 0 then return nil end
    return ('`vehicle` = IF(JSON_VALID(`vehicle`), JSON_SET(`vehicle`, %s), `vehicle`)'):format(table.concat(paths, ', ')), values
end

-- -> rows changed (0 for a table layout this script does not know) | nil on a database error
local function frameworkStore(car, fuel, engine, body)
    local t = car.table
    local cols = columns(t.name)
    if not cols then return nil end
    if not cols[t.owner] or not (cols.in_garage or cols[t.flag]) then return 0 end

    local sets, params = {}, {}
    local function set(column, value)
        if not cols[column] or value == nil then return end
        sets[#sets + 1] = ('`%s` = ?'):format(column)
        params[#params + 1] = value
    end
    set('in_garage', 1)
    set(t.flag, 1)
    set('fuel', fuel)
    set('engine', engine)
    set('body', body)
    if t.name == 'owned_vehicles' then
        local clause, values = esxProps(cols, fuel, engine, body)
        if clause then
            sets[#sets + 1] = clause
            for _, value in ipairs(values) do params[#params + 1] = value end
        end
    end

    local where = { 'UPPER(TRIM(plate)) = ?', ('`%s` = ?'):format(t.owner), cols.in_garage and '`in_garage` = 0' or ('`%s` = 0'):format(t.flag) }
    if cols.impound then where[#where + 1] = '`impound` = 0' end
    params[#params + 1] = car.plate
    params[#params + 1] = car.owner

    local sql = ('UPDATE `%s` SET %s WHERE %s'):format(t.name, table.concat(sets, ', '), table.concat(where, ' AND '))
    local changed = query('update', sql, params)
    return type(changed) == 'number' and changed or nil
end

Garage.register('framework', { lookup = frameworkLookup, store = frameworkStore })

-- The owned car record of a vehicle about to be wiped. Cars whose plate is on two cars in the world are never looked up.
-- -> car | nil (not owned) | false (ownership unknown)
function Garage.lookup(vehicle, plateCounts)
    local plate = Vehicles.plate(vehicle)
    if not plate or plateCounts[plate] ~= 1 then return nil end
    local adapter = adapters[adapterName()]
    if not adapter then return false end

    local model = Vehicles.model(vehicle)
    local car = adapter.lookup(vehicle, plate, model)
    if type(car) ~= 'table' then return car end
    car.plate, car.model, car.adapter = plate, model, adapter
    return car
end

-- A second car with this plate and model in the world means the row is still in use.
local function copyLeft(car)
    for _, vehicle in ipairs(GetAllVehicles()) do
        if Vehicles.plate(vehicle) == car.plate and Vehicles.model(vehicle) == car.model then return true end
    end
    return false
end

-- Called after the car left the world. -> true when its row is now stored.
function Garage.store(car, fuel, engine, body)
    if copyLeft(car) then
        Log(0, '%s not sent to its garage: another car with this plate is in the world', car.plate)
        return false
    end
    for attempt = 1, 3 do
        local changed = car.adapter.store(car, fuel, engine, body)
        if changed then return changed > 0 end
        Wait(1000 * attempt)
    end
    Log(0, '%s left the world but its garage row could not be written (database error)', car.plate)
    return false
end

CreateThread(function()
    Wait(0) -- the adapters in server/garages/ load after this file
    if not CW.settings(SavedSettings()).garage then return end
    local name = adapterName()
    if not adapters[name] then
        print(("^3[%s] There is no garage adapter '%s' (Config.Garage.adapter), so owned cars cannot be told apart: cars with a plate are not wiped.^7")
            :format(GetCurrentResourceName(), name))
    elseif name == 'framework' and Framework.name() and not Framework.hasDatabase() then
        print(('^3[%s] oxmysql is not running, so owned cars cannot be told apart: cars with a plate are not wiped. Start oxmysql or set Config.Garage.returnOwned = false.^7')
            :format(GetCurrentResourceName()))
    end
end)
