import type { T } from './i18n';
import { clock, leftNow, type Countdown } from './nui';
import { Clock } from './icons';

type Props = { card: Countdown; at: number; total: number; now: number; t: T };

export function CountdownCard({ card, at, total, now, t }: Props) {
  const left = leftNow(card.seconds, at, now) ?? 0;
  const percent = Math.max(0, Math.min(100, (left / Math.max(1, total)) * 100));
  return (
    <div className={left <= 30 ? 'cd-card urgent' : 'cd-card'} role="status">
      <span className="cd-icon"><Clock size={26} /></span>
      <div className="cd-text">
        <div className="cd-title">{left > 0 ? t('cd_title', { time: clock(left) }) : t('cd_now')}</div>
        <div className="cd-hint">{card.command ? t('cd_hint', { command: card.command }) : t('cd_hint_plain')}</div>
      </div>
      <div className="cd-bar"><i style={{ width: `${percent}%` }} /></div>
    </div>
  );
}
