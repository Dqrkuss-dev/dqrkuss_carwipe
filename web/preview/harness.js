// Browser preview only (npx vite, then /preview.html). Plays the Lua side: answers the NUI callbacks and sends sample
// messages. ?screen= panel | kept | zones | history | blocked | card | toast | both   ?lang= any locale   ?shot=1 hides the links
(function () {
  var RES = 'dqrkuss_carwipe';
  var SCREENS = ['panel', 'kept', 'zones', 'history', 'blocked', 'card', 'toast', 'both'];
  var query = new URLSearchParams(location.search);
  var screen = query.get('screen') || 'panel';
  var lang = query.get('lang') || 'en';
  window.GetParentResourceName = function () { return RES; };

  var view = {
    state: screen === 'both' ? 'countdown' : 'waiting', left: screen === 'both' ? 42 : 4231, interval: 120, smart: 15,
    blocked: screen === 'blocked' ? ['heist_script: bank job running'] : [], keepMax: 200, zonesMax: 100, zonesOn: true,
    zoneRadius: 25, command: 'carwipe',
    kept: [{ i: 1, kind: 'car', label: 'Sultan RS', plate: '42JDK118' }, { i: 2, kind: 'model', label: 'Police Cruiser', plate: 'LSPD 014' }, { i: 3, kind: 'plate', plate: 'EVENT01' }],
    zones: [
      { i: 1, x: 215.4, y: -810.2, radius: 25, dist: 12 },
      { i: 2, x: -339.8, y: -136.5, radius: 40, dist: 1184 },
      { i: 3, x: 1736.1, y: 3709.9, radius: 60, dist: 4812 },
    ],
    history: [
      { when: '26.10 14:00', removed: 37, garage: 9, skipped: 21, by: 'auto' },
      { when: '26.10 12:00', removed: 41, garage: 12, skipped: 18, by: 'auto' },
      { when: '26.10 10:47', removed: 12, garage: 3, skipped: 30, by: 'Admin' },
      { when: '26.10 08:00', removed: 18, garage: 4, skipped: 11, by: 'console' },
    ],
  };

  var send = function (action, data) { window.postMessage({ action: action, data: data, locale: lang }, '*'); };
  var reply = function (name, body) {
    if (name === 'close') send('close');
    if (name === 'request') {
      var action = body.action, data = body.data || {};
      if (action === 'start' || action === 'force') {
        view.state = 'countdown';
        view.left = action === 'start' ? 60 : 10;
        send('countdown', { seconds: view.left, command: '/savecar' });
      }
      if (action === 'cancel') { view.state = 'waiting'; view.left = 7200; send('countdown_end'); }
      if (action === 'settings') { view.interval = data.interval; view.smart = data.smart; }
      if (action === 'unkeep') view.kept = view.kept.filter(function (e) { return e.i !== data.i; });
      if (action === 'zoneRemove') view.zones = view.zones.filter(function (z) { return z.i !== data.i; });
      if (action === 'zoneAdd') view.zones.push({ i: view.zones.length + 1, x: 0, y: 0, radius: data.radius, dist: 0 });
      send('view', view);
    }
    return { ok: true };
  };

  var realFetch = window.fetch.bind(window);
  window.fetch = function (url, opts) {
    url = String(url);
    if (url.indexOf('https://' + RES + '/') === 0) {
      var body = JSON.parse((opts && opts.body) || '{}');
      var answer = JSON.stringify(reply(url.slice(RES.length + 9), body));
      return Promise.resolve(new Response(answer, { headers: { 'Content-Type': 'application/json' } }));
    }
    return realFetch(url, opts);
  };
  var click = function (selector) {
    var el = document.querySelector(selector);
    if (el) el.dispatchEvent(new MouseEvent('click', { bubbles: true }));
  };

  var steps = [];
  var at = function (ms, fn) { steps.push([ms, fn]); };
  var withCard = screen === 'card' || screen === 'both';
  var withToast = screen === 'toast' || screen === 'both';
  at(0, function () {
    if (screen !== 'card' && screen !== 'toast') { send('open', view); send('focus', true); }
    if (withCard) send('countdown', { seconds: 42, command: '/savecar' });
  });
  if (withCard) at(-150, function () { send('countdown', { seconds: 60, command: '/savecar' }); });
  if (withToast) {
    at(50, function () { send('toast', { text: 'Empty cars will be removed in 1 min. Sit in your car and type /savecar to keep it.', kind: 'warning' }); });
    at(100, function () { send('toast', { text: 'Your car is kept for this wipe.', kind: 'success' }); });
    at(150, function () { send('toast', { text: 'Sit in a car while a car wipe is counting down.', kind: 'error' }); });
  }
  if (screen === 'kept') at(300, function () { click('.cw-tabs button:nth-child(2)'); });
  if (screen === 'kept') at(500, function () { click('.cw-kept tbody tr:nth-child(2) .btn'); });
  if (screen === 'zones') at(300, function () { click('.cw-tabs button:nth-child(3)'); });
  if (screen === 'zones') at(500, function () { click('.cw-zones tbody tr:nth-child(2) .btn.danger'); });
  if (screen === 'history') at(300, function () { click('.cw-tabs button:nth-child(4)'); });

  window.addEventListener('load', function () {
    document.documentElement.style.background = 'linear-gradient(180deg, #8ea3b3 0%, #b9c3c8 34%, #59605c 35%, #3d423f 70%, #2a2d2b 100%)';
    if (!query.get('shot')) {
      var bar = document.createElement('div');
      bar.style.cssText = 'position:fixed;left:8px;bottom:8px;z-index:99;display:flex;gap:4px;font:12px monospace';
      SCREENS.forEach(function (name) {
        var link = document.createElement('a');
        link.textContent = name;
        link.href = '?screen=' + name + '&lang=' + lang;
        link.style.cssText = 'padding:3px 6px;background:#000a;color:#fff;text-decoration:none';
        bar.appendChild(link);
      });
      document.body.appendChild(bar);
    }
    steps.sort(function (a, b) { return a[0] - b[0]; });
    steps.forEach(function (step) { setTimeout(step[1], 200 + step[0]); });
  });
})();
