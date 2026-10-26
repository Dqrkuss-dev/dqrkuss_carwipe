Vehicles = {}

function Vehicles.normalizePlate(text)
    if type(text) ~= 'string' then return nil end
    local plate = text:upper():match('^%s*(.-)%s*$')
    return plate ~= '' and plate or nil
end

function Vehicles.plate(vehicle)
    return Vehicles.normalizePlate(GetVehicleNumberPlateText(vehicle))
end

-- Model hashes come back signed from some natives and unsigned from others; compare them unsigned.
function Vehicles.unsigned(hash)
    hash = math.tointeger(tonumber(hash))
    return hash and hash & 0xFFFFFFFF or nil
end

function Vehicles.model(vehicle)
    return Vehicles.unsigned(GetEntityModel(vehicle))
end

function Vehicles.exists(entity)
    local exists = DoesEntityExist(entity)
    return exists == true or exists == 1
end

-- {[plate] = number of cars in the world carrying it}
function Vehicles.plateCounts()
    local counts = {}
    for _, vehicle in ipairs(GetAllVehicles()) do
        local plate = Vehicles.plate(vehicle)
        if plate then counts[plate] = (counts[plate] or 0) + 1 end
    end
    return counts
end

-- Vehicles a player sits in right now (any seat).
function Vehicles.seated()
    local set = {}
    for _, id in ipairs(GetPlayers()) do
        local vehicle = GetVehiclePedIsIn(GetPlayerPed(tonumber(id)), false)
        if vehicle ~= 0 then set[vehicle] = true end
    end
    return set
end

function Vehicles.occupied(vehicle)
    for _, id in ipairs(GetPlayers()) do
        if GetVehiclePedIsIn(GetPlayerPed(tonumber(id)), false) == vehicle then return true end
    end
    return false
end

function Vehicles.ofPlayer(src)
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(src), false)
    return vehicle ~= 0 and vehicle or nil
end
