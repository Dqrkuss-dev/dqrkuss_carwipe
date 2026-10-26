-- Example garage adapter for a garage script that keeps cars in its own table instead of the framework's.
-- Copy this file next to it, give the adapter its own name, change the table and column names to your garage
-- script's and set Config.Garage.adapter to that name. Every .lua file in this folder is loaded.
--
-- The made-up table here:  my_garage_vehicles (plate, owner, model, stored, fuel)

Garage.register('example', {
    -- Is this car owned and out of its garage? -> {owner = ...} | nil (not owned / already stored) | false (unknown)
    lookup = function(vehicle, plate, model)
        local rows = Garage.query('query', 'SELECT owner, model, stored FROM my_garage_vehicles WHERE plate = ? LIMIT 2', { plate })
        if type(rows) ~= 'table' or #rows > 1 then return false end

        local row = rows[1]
        if not row or tonumber(row.stored) == 1 then return nil end
        if Vehicles.unsigned(GetHashKey(row.model)) ~= model then return nil end
        return { owner = row.owner }
    end,

    -- The car left the world: mark it stored. Only while it still belongs to the same owner and is still out.
    store = function(car, fuel, engine, body)
        return Garage.query('update', 'UPDATE my_garage_vehicles SET stored = 1, fuel = COALESCE(?, fuel) WHERE plate = ? AND owner = ? AND stored = 0',
            { fuel, car.plate, car.owner })
    end,
})
