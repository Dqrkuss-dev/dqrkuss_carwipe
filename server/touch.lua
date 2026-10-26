-- When each car was last used, read on the server only (seats and positions), never from a client message.
Touch = {}

local records = {}

local function position(entity)
    local coords = GetEntityCoords(entity)
    return { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 }
end

function Touch.scan()
    local now = os.time()
    local move = CW.settings(SavedSettings()).move
    local seated = Vehicles.seated()
    local live = {}
    for _, vehicle in ipairs(GetAllVehicles()) do
        live[vehicle] = true
        records[vehicle] = CW.touch(records[vehicle], position(vehicle), seated[vehicle] == true, now, move)
    end
    for vehicle in pairs(records) do
        if not live[vehicle] then records[vehicle] = nil end
    end
end

-- Seconds since the car was last used.
function Touch.idle(vehicle)
    local record = records[vehicle]
    return record and os.time() - record.at or 0
end

AddEventHandler('entityCreated', function(entity)
    if not Vehicles.exists(entity) or GetEntityType(entity) ~= 2 then return end
    local pos = position(entity)
    records[entity] = { at = os.time(), x = pos.x, y = pos.y, z = pos.z }
end)

AddEventHandler('entityRemoved', function(entity)
    records[entity] = nil
end)

CreateThread(function()
    while true do
        Touch.scan()
        Wait(CW.settings(SavedSettings()).scan * 1000)
    end
end)
