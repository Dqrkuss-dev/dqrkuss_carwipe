import { useEffect, useRef, useState } from 'react';
import { Save } from '../icons';
import { Stepper } from './Stepper';
import type { TabProps } from './shared';

const INTERVAL = { min: 15, max: 1440, step: 5 };
const SMART = { min: 0, max: 240, step: 1 };

export function SettingsTab({ view, t, ask, sending }: TabProps) {
  const [interval, setIntervalMinutes] = useState(view.interval);
  const [smart, setSmart] = useState(view.smart);

  // The fields follow the server until the admin edits them.
  const last = useRef({ interval: view.interval, smart: view.smart });
  useEffect(() => {
    if (interval === last.current.interval) setIntervalMinutes(view.interval);
    if (smart === last.current.smart) setSmart(view.smart);
    last.current = { interval: view.interval, smart: view.smart };
  }, [view.interval, view.smart]);

  const changed = interval !== view.interval || smart !== view.smart;
  return (
    <div className="pgrid">
      <div className="pg-row">
        <span className="pg-name"><span>{t('set_interval')}</span></span>
        <Stepper value={interval} set={setIntervalMinutes} range={INTERVAL} label={t('set_interval')} unit={t('unit_min')} />
      </div>
      <div className="pg-row">
        <span className="pg-name"><span>{t('set_smart')}</span></span>
        <Stepper value={smart} set={setSmart} range={SMART} label={t('set_smart')} unit={t('unit_min')} />
      </div>
      <div className="cw-save">
        <span>{t('set_desc')}</span>
        <button className="btn primary" disabled={!changed || sending} onClick={() => void ask('settings', { interval, smart }, 'fb_saved_settings')}>
          <Save size={16} />{t('btn_save')}
        </button>
      </div>
    </div>
  );
}
