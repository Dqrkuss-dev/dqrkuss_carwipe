# Car Wipe

![Car Wipe](https://raw.githubusercontent.com/Dqrkuss-dev/dqrkuss_carwipe/main/.github/images/banner.jpg)

<p>
  <img src="https://raw.githubusercontent.com/Dqrkuss-dev/dqrkuss_carwipe/main/.github/images/1.jpg" alt="Countdown" width="49%">
  <img src="https://raw.githubusercontent.com/Dqrkuss-dev/dqrkuss_carwipe/main/.github/images/2.jpg" alt="Panel" width="49%">
  <img src="https://raw.githubusercontent.com/Dqrkuss-dev/dqrkuss_carwipe/main/.github/images/3.jpg" alt="Keep list and safe zones" width="49%">
  <img src="https://raw.githubusercontent.com/Dqrkuss-dev/dqrkuss_carwipe/main/.github/images/4.jpg" alt="Owned cars back to their garage" width="49%">
</p>

Scheduled, announced removal of empty cars for FiveM, with an admin panel, safe zones, a keep list and `/savecar`.
Owned cars go back to their garage instead of being lost.

## Requirements

None. Optional: `oxmysql` for sending owned cars back to their garage (Qbox, QBCore or ESX).

OneSync must be on (it is by default on current servers).

## Install

1. Put the `dqrkuss_carwipe` folder in your `resources` folder.
2. Add `ensure dqrkuss_carwipe` to `server.cfg` (after your framework and `oxmysql`, if you use them).

Give your admins the panel:

```cfg
add_ace group.admin carwipe.admin allow
```

Framework admins (Qbox and QBCore `admin` / `god`, ESX `admin` / `superadmin`) can use it without this line.

## Commands and permissions

| Command | Who | What |
| --- | --- | --- |
| `/carwipe` | Admins | Opens or closes the panel |
| `/carwipe start` | Admins, console | Starts a wipe with a 60 s countdown |
| `/carwipe force` | Admins, console | Starts a wipe with a 10 s countdown |
| `/carwipe cancel` | Admins, console | Cancels the countdown |
| `/carwipe keep [model\|plate]` | Admins | The car you sit in is never wiped; `model` keeps every car of that model, `plate` every car with that plate (also in the panel, Kept tab) |
| `/carwipe unkeep` | Admins | Takes the keep entry that matches the car you sit in off the list |
| `/savecar` | Everyone | Keeps the car you sit in for the coming wipe (only during a countdown) |

Admins are the server console, players with the ace `carwipe.admin` (`Config.Admin.ace`) and framework admins
(`Config.Admin.framework`, `groups`, `esxGroups`).

The panel has four tabs: Settings (interval and smart wipe minutes, saved at once), Kept cars, Safe zones (add a zone
where you stand, go to a zone, remove one) and Last wipes.

## Configuration

| I want to change | File | Setting |
| --- | --- | --- |
| Language | `config/main.lua` | `Config.Locale` |
| Who counts as admin | `config/main.lua` | `Config.Admin` |
| Time between wipes | `config/main.lua` (or the panel) | `Config.Schedule.intervalMinutes` |
| Turn automatic wipes off | `config/main.lua` | `Config.Schedule.enabled` |
| Warning time and warnings | `config/main.lua` | `Config.Schedule.countdownMinutes`, `notices` |
| On-screen notices, chat lines or both | `config/main.lua` | `Config.Announce.mode` |
| Minutes a used car stays safe | `config/main.lua` (or the panel) | `Config.Smart.minutes` |
| Wipe every empty car | `config/main.lua` | `Config.Smart.enabled = false` |
| Safe zones on or off, radius preset | `config/main.lua` | `Config.SafeZones` |
| Turn `/savecar` off or rename it | `config/main.lua` | `Config.SaveCar` |
| What happens to owned cars | `config/main.lua` | `Config.Garage.returnOwned` (`'garage'`, `'skip'`, `false`) |
| Garage script with its own table | `server/garages/` + `config/main.lua` | an adapter file, `Config.Garage.adapter` |
| Countdown of start / force | `config/advanced.lua` | `startSeconds`, `forceSeconds` |
| State bag keys that protect a car | `config/advanced.lua` | `protectedStates` |
| Size of the keep list and zone list | `config/advanced.lua` | `keepMax`, `zonesMax` |
| Texts | `locales/<language>.json` | |

Languages: English, Bulgarian, German, Spanish, French, Italian, Dutch, Polish, Portuguese, Russian, Turkish.

Settings saved in the panel, the keep list, safe zones and the history are stored in the resource KVP. No database
tables, no items.

## Exports

```lua
-- Pause wipes while your script needs the cars (a heist, an event). false releases it; stopping your resource does too.
exports.dqrkuss_carwipe:SetCarwipeBlocked(true, 'event running')

-- { countdown = os.time() it ends | nil, blocked = bool, wiping = bool, nextAt = os.time() }
local state = exports.dqrkuss_carwipe:GetCarwipeState()
```

`GlobalState.dqCarwipe` is `{ wiping, countdown }` while a countdown or wipe runs, else `nil`.

To protect a car from your own script, set one of the `protectedStates` keys on it:
`Entity(vehicle).state:set('dqProtected', true, true)`.

## Other garage scripts

Owned cars are found in the framework's table (`player_vehicles` on Qbox / QBCore, `owned_vehicles` on ESX). That
covers qb-garages, qbx_garages, esx_garage, jg-advancedgarages and every garage script that stores cars there; extra
columns such as `in_garage`, `impound`, `fuel`, `engine` and `body` are used when the table has them.

For a garage script with its own table, write an adapter:

1. Copy `server/garages/example.lua` to `server/garages/<your garage>.lua` (every `.lua` file there is loaded).
2. Change the adapter name, the table and the column names in it.
3. Set `Config.Garage.adapter = '<adapter name>'` in `config/main.lua`.

An adapter has two functions: `lookup(vehicle, plate, model)` returns `{ owner = ... }` for an owned car that is out,
`nil` when it is not owned or already stored, `false` when ownership is unknown (the car is then left alone);
`store(car, fuel, engine, body)` marks it stored and returns the rows changed. `Garage.query(kind, sql, params)` runs
oxmysql (`'query'`, `'update'`, `'scalar'`, `'single'`, `'insert'`).

## Troubleshooting

- **No wipe happens:** another script holds a block (shown as "Blocked by" in the panel), or `Config.Schedule.enabled = false`.
- **Nothing with a plate is wiped:** a framework runs without `oxmysql`, so owned cars cannot be told apart. The console says so at start. Start `oxmysql` or set `Config.Garage.returnOwned = false`.
- **A car I just used was wiped:** smart wipe is off, or set to 0 in the panel.
- **"There is no garage adapter" at start:** `Config.Garage.adapter` names an adapter that no file in `server/garages/` registers.
- **Owned cars do not come back to the garage:** the console prints a line for each car whose row could not be written. Check `oxmysql`.
- **`/carwipe` says you may not use it:** add the ace line above, or check `Config.Admin`.
- **The panel or the countdown card does not show:** the folder must contain `web/dist/`. Restart the resource.

## License

GPL-3.0, see `LICENSE`.
