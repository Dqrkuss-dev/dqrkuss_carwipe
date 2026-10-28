# Changelog

## 1.0.1 (unreleased)
- Countdown card shows for 8 s at each warning (10 / 5 / 1 min) and stays only for the last 30 s, instead of ticking on screen for the whole countdown.
- Notices go to the server's notifications when one runs (`Config.Notify = 'auto'`, first started of
  `Config.NotifyOrder`), else to the script's own toasts.
- Countdown warnings: `Config.Announce.card = 'top'` (default) shows the script's own countdown card at the top of the
  screen; `'notify'` sends each warning as a notification (the server's notifications when one runs, else the top
  card). The dqrkuss_lib countdown card (`cardOrder`) is gone.
- Popups through the shared hand-off kit (`client/handoff.lua`).
- NUI cost pass: no transitions, filters or hover effects; live panel updates only on change.

## 1.0.0
- First release: scheduled wipe with a countdown card and notices, `/carwipe` admin panel, smart wipe (only cars
  untouched for 15 min), safe zones added in the panel, admin keep list (one car, a whole model or a plate),
  `/savecar`, owned cars back to their garage with fuel, engine and body kept (Qbox, QBCore, ESX with oxmysql; other
  garage scripts through an adapter in `server/garages/`), announcements on screen, in chat or both, 11 languages.
  Standalone: no other resource needed. GPL-3.0.
