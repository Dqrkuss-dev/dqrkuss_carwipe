import { useEffect, useRef, useState } from 'react';
import { Save } from '../icons';
import { POSITIONS, type Position } from '../nui';
import { Stepper } from './Stepper';
import type { TabProps } from './shared';

const INTERVAL = { min: 15, max: 1440, step: 5 };
const SMART = { min: 0, max: 240, step: 1 };
const POSITION_TEXT: Record<Position, string> = {
  'top-left': 'pos_top_left', top: 'pos_top', 'top-right': 'pos_top_right',
  'bottom-left': 'pos_bottom_left', bottom: 'pos_bottom', 'bottom-right': 'pos_bottom_right',
};

export function SettingsTab({ view, t, ask, sending }: TabProps) {
  const [interval, setIntervalMinutes] = useState(view.interval);
  const [smart, setSmart] = useState(view.smart);
  const [position, setPosition] = useState<Position>(view.position ?? 'top');

  // The fields follow the server until the admin edits them.
  const last = useRef({ interval: view.interval, smart: view.smart, position: view.position ?? 'top' });
  useEffect(() => {
    const serverPosition = view.position ?? 'top';
    if (interval === last.current.interval) setIntervalMinutes(view.interval);
    if (smart === last.current.smart) setSmart(view.smart);
    if (position === last.current.position) setPosition(serverPosition);
    last.current = { interval: view.interval, smart: view.smart, position: serverPosition };
  }, [view.interval, view.smart, view.position]);

  const changed = interval !== view.interval || smart !== view.smart || position !== (view.position ?? 'top');
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
      <div className="pg-row">
        <span className="pg-name"><span>{t('set_position')}</span></span>
        <span className="cw-kinds cw-positions">
          {POSITIONS.map(p => (
            <button key={p} className={p === position ? 'btn picked' : 'btn'} onClick={() => setPosition(p)}>{t(POSITION_TEXT[p])}</button>
          ))}
        </span>
      </div>
      <div className="cw-save">
        <span>{t('set_desc')}</span>
        <button className="btn primary" disabled={!changed || sending} onClick={() => void ask('settings', { interval, smart, position }, 'fb_saved_settings')}>
          <Save size={16} />{t('btn_save')}
        </button>
      </div>
    </div>
  );
}
