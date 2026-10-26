-- Fine tuning. The defaults suit most servers.
Config.Advanced = {
    startSeconds = 60, -- countdown of /carwipe start in seconds; 10 to 1800, default 60
    forceSeconds = 10, -- countdown of /carwipe force in seconds; 5 to 60, default 10
    retrySeconds = 60, -- while another script blocks the wipe, the countdown never ends sooner than this; 10 to 600, default 60
    scanSeconds = 10,  -- how often cars are checked for being used or moved; 5 to 60, default 10
    moveMetres = 3,    -- a car that moved more than this between two checks counts as used; 1 to 50, default 3
    keepMax = 200,     -- most cars on the admin keep list; 1 to 200, default 200
    zonesMax = 100,    -- most safe zones; 1 to 100, default 100
    historySize = 10,  -- wipes listed in the panel; 1 to 10, default 10

    -- Cars carrying one of these entity state bag keys are never wiped. Other scripts set them on mission cars, job
    -- cars, test drives, gang and fleet cars. Add the keys your own scripts use.
    protectedStates = { 'dqProtected', 'careerOwner', 'dqrkussTestDrive', 'gangVehicle', 'dqFleet' },
}
