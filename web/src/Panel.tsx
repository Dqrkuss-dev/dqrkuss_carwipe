import { useState, type ReactNode } from 'react';
import type { T } from './i18n';
import { clock, leftNow, post, type View } from './nui';
import { Bolt, Clock, Close, Danger, History, MapPoint, Play, Settings, Shield, Stop } from './icons';
import type { Ask } from './tabs/shared';
import { SettingsTab } from './tabs/SettingsTab';
import { KeptTab } from './tabs/KeptTab';
import { ZonesTab } from './tabs/ZonesTab';
import { HistoryTab } from './tabs/HistoryTab';

type Props = { view: View; at: number; now: number; focused: boolean; t: T };
type Tab = 'settings' | 'kept' | 'zones' | 'history';
type Note = { text: string; bad: boolean } | null;

const ERRORS: Record<string, string> = {
  denied: 'err_denied', refused: 'fb_refused', invalid: 'err_invalid', unknown: 'err_unknown', full: 'err_full',
  nocar: 'fb_keep_nocar', noplate: 'fb_keep_noplate', copied: 'fb_keep_copied', exists: 'fb_keep_exists',
};

function duration(t: T, minutes: number) {
  const m = Math.max(0, Math.floor(minutes));
  const h = Math.floor(m / 60);
  if (h === 0) return t('dur_m', { m });
  return m % 60 ? t('dur_hm', { h, m: m % 60 }) : t('dur_h', { h });
}

function TabButton({ on, onClick, icon, label }: { on: boolean; onClick: () => void; icon: ReactNode; label: string }) {
  return (
    <button className={on ? 'on' : ''} onClick={onClick}>
      {icon}<span className="tl">{label}</span>
    </button>
  );
}

export function Panel({ view, at, now, focused, t }: Props) {
  const [tab, setTab] = useState<Tab>('settings');
  const [note, setNote] = useState<Note>(null);
  const [sending, setSending] = useState(false);

  const ask: Ask = async (action, data, done, args) => {
    if (sending) return;
    setSending(true);
    const res = await post('request', { action, data });
    setSending(false);
    if (!res.ok) setNote({ text: t(ERRORS[res.err ?? ''] ?? 'err_busy'), bad: true });
    else setNote(done ? { text: t(done, args), bad: false } : null);
  };

  const left = leftNow(view.left, at, now);
  const kept = view.kept ?? [];
  const zones = view.zones ?? [];
  const blocked = view.blocked ?? [];
  const busy = view.state === 'countdown' || view.state === 'wiping';
  const tabProps = { view, t, ask, sending };

  return (
    <div className="stage">
      <section className={focused ? 'cw-frame focused' : 'cw-frame'}>
        <div className="cw-screen">
          <header className="cw-top">
            <h1>{t('panel_title')}</h1>
            {view.command && <span className="cmd">/{view.command}</span>}
            <button className="cw-x" title={t('btn_close')} onClick={() => void post('close')}><Close size={18} /></button>
          </header>

          <div className="live">
            <div className={`lv-cell st-${view.state}`}>
              <div className="lv-k">{t('row_state')}</div>
              <div className="lv-v st">{t(`state_${view.state}`)}</div>
            </div>
            <div className="lv-cell lv-next">
              <div className="lv-k">{t(view.state === 'countdown' ? 'row_wipe_in' : 'row_next')}</div>
              <div className="lv-v">{left !== undefined && view.state !== 'wiping' ? clock(left) : '-'}</div>
            </div>
            <div className="lv-cell">
              <div className="lv-k">{t('row_interval')}</div>
              <div className="lv-v small">{duration(t, view.interval)}</div>
            </div>
            <div className="lv-foot">
              <span><Clock /> {t('row_smart')} <b>{view.smart > 0 ? duration(t, view.smart) : t('off')}</b></span>
              <span><MapPoint /> {t('row_zones')} <b>{zones.length}</b></span>
              <span><Shield /> {t('row_kept')} <b>{kept.length} / {view.keepMax ?? 200}</b></span>
            </div>
          </div>

          {blocked.length > 0 && (
            <p className="note bad cw-blocked"><Danger size={16} /><span>{t('row_blocked')}: <b>{blocked.join(', ')}</b></span></p>
          )}

          <div className="cw-actions">
            <button className="btn tall" title={t('act_start')} disabled={busy || sending} onClick={() => void ask('start', {}, null)}>
              <Play size={16} />{t('btn_start')}
            </button>
            <button className="btn tall" title={t('act_force')} disabled={busy || sending} onClick={() => void ask('force', {}, null)}>
              <Bolt size={16} />{t('btn_force')}
            </button>
            <button className="btn tall danger" title={t('act_cancel')} disabled={view.state !== 'countdown' || sending}
              onClick={() => void ask('cancel', {}, null)}>
              <Stop size={16} />{t('btn_cancel')}
            </button>
          </div>

          <nav className="cw-tabs">
            <TabButton on={tab === 'settings'} onClick={() => setTab('settings')} icon={<Settings size={16} />} label={t('tab_settings')} />
            <TabButton on={tab === 'kept'} onClick={() => setTab('kept')} icon={<Shield size={16} />} label={t('tab_kept')} />
            <TabButton on={tab === 'zones'} onClick={() => setTab('zones')} icon={<MapPoint size={16} />} label={t('tab_zones')} />
            <TabButton on={tab === 'history'} onClick={() => setTab('history')} icon={<History size={16} />} label={t('tab_history')} />
          </nav>

          <div className="cw-body scroll">
            {tab === 'settings' && <SettingsTab {...tabProps} />}
            {tab === 'kept' && <KeptTab {...tabProps} />}
            {tab === 'zones' && <ZonesTab {...tabProps} />}
            {tab === 'history' && <HistoryTab {...tabProps} />}
          </div>

          {note && (
            <footer className={note.bad ? 'statusbar bad' : 'statusbar'}>
              <span className="grow">{note.text}</span>
            </footer>
          )}
        </div>
      </section>
    </div>
  );
}
