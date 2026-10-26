-- Car Wipe settings. Edit the values, then restart the resource.
-- The wipe interval and the smart wipe minutes can also be changed in game (/carwipe). Values saved there win over
-- this file until they are changed again in the panel.
Config = {
    Locale = 'en', -- language of all texts: en, bg, de, es, fr, it, nl, pl, pt, ru, tr; default 'en'

    Admin = {
        command = 'carwipe',       -- admin chat command, default 'carwipe'
        ace = 'carwipe.admin',     -- ace that grants the admin tools, default 'carwipe.admin'
        framework = true,          -- true: framework admins may use it too (Qbox, QBCore, ESX), default true
        groups = { 'admin', 'god' },           -- Qbox / QBCore permission groups that count as admin, default { 'admin', 'god' }
        esxGroups = { 'admin', 'superadmin' }, -- ESX groups that count as admin, default { 'admin', 'superadmin' }
    },

    Schedule = {
        enabled = true,          -- false: no automatic wipes (/carwipe start still works), default true
        intervalMinutes = 120,   -- minutes between two wipes; 15 to 1440, default 120
        countdownMinutes = 10,   -- warning time before a scheduled wipe in minutes; 1 to 30, default 10
        notices = { 600, 300, 60, 30 }, -- seconds left when a warning is shown; each 5 to 1800, default { 600, 300, 60, 30 }
    },

    Announce = {
        mode = 'notify', -- 'notify' (countdown card and notices on screen), 'chat' (chat lines) or 'both'; default 'notify'
    },

    -- Smart wipe: a car that was entered, driven or moved recently stays.
    Smart = {
        enabled = true, -- false: every empty car is wiped, default true
        minutes = 15,   -- minutes a used car stays safe; 1 to 240, default 15
    },

    -- Safe zones are added in game: /carwipe -> Safe zones.
    SafeZones = {
        enabled = true, -- false: safe zones are ignored, default true
        radius = 25,    -- radius preset for a new zone in metres; 5 to 100, default 25
    },

    SaveCar = {
        enabled = true,      -- players keep the car they sit in for the coming wipe, default true
        command = 'savecar', -- chat command, default 'savecar'
    },

    Garage = {
        -- What happens to a player-owned car that is wiped. Needs oxmysql and Qbox, QBCore or ESX.
        --   'garage': it leaves the world and is marked stored in its garage (fuel, engine and body kept, no fee)
        --   'skip':   owned cars are never wiped
        --   false:    wiped like any other car, the garage row is not touched
        -- When ownership cannot be checked (oxmysql not running, database error) the car is skipped.
        -- Default 'garage'.
        returnOwned = 'garage',

        -- Where owned cars are looked up. 'framework' (default): the framework's own table (Qbox / QBCore
        -- player_vehicles, ESX owned_vehicles), which covers qb-garages, qbx_garages, esx_garage, jg-advancedgarages and
        -- every other garage script that stores cars there. A garage script with its own table: add an adapter in
        -- server/garages/ (copy example.lua) and put its name here.
        adapter = 'framework',
    },
}
