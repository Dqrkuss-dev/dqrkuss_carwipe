import { useEffect, useMemo, useRef, useState } from 'react';
import { translator } from './i18n';
import { post, type Countdown, type ToastKind, type View } from './nui';
import { Panel } from './Panel';
import { CountdownCard } from './CountdownCard';
import { Toasts, type ToastItem } from './Toasts';

const CARD_SHOW_MS = 8000; // how long the card stays after each warning
const CARD_FINAL_S = 30;   // and from this many seconds before the wipe until it

type Timed<T> = { value: T; at: number };
type Card = Timed<Countdown> & { total: number };
type Message = { action?: string; data?: unknown; locale?: unknown };

const TOAST_MS = 6000;
const MAX_TOASTS = 3;

export function App() {
  const [locale, setLocale] = useState('en');
  const [view, setView] = useState<Timed<View> | null>(null);
  const [focused, setFocused] = useState(false);
  const [card, setCard] = useState<Card | null>(null);
  const [toasts, setToasts] = useState<ToastItem[]>([]);
  const [now, setNow] = useState(() => Date.now());
  const nextToast = useRef(0);
  const t = useMemo(() => translator(locale), [locale]);

  const addToast = (text: string, kind: ToastKind) => {
    const id = ++nextToast.current;
    setToasts(list => [...list, { id, text, kind }].slice(-MAX_TOASTS));
    window.setTimeout(() => setToasts(list => list.filter(item => item.id !== id)), TOAST_MS);
  };

  useEffect(() => {
    const onMessage = (e: MessageEvent<Message>) => {
      const { action, data, locale: messageLocale } = e.data ?? {};
      const at = Date.now();
      if (typeof messageLocale === 'string') setLocale(messageLocale);

      if ((action === 'open' || action === 'view') && data && typeof data === 'object') {
        setView({ value: data as View, at });
        if (action === 'open') setFocused(false);
      } else if (action === 'focus') {
        setFocused(data === true);
      } else if (action === 'close') {
        setView(null);
        setFocused(false);
      } else if (action === 'countdown' && data && typeof data === 'object') {
        const d = data as Countdown;
        const seconds = Math.max(0, Math.floor(Number(d.seconds) || 0));
        // The bar spans the whole countdown: the first notice sets its length, later ones only correct the time.
        setCard(prev => ({ value: { seconds, command: d.command }, at, total: Math.max(seconds, prev?.total ?? 0, 1) }));
      } else if (action === 'countdown_end') {
        setCard(null);
      } else if (action === 'toast' && data && typeof data === 'object') {
        const d = data as { text?: unknown; kind?: ToastKind };
        if (typeof d.text === 'string') addToast(d.text, d.kind ?? 'inform');
      }
      setNow(at);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') void post('close');
    };
    window.addEventListener('message', onMessage);
    window.addEventListener('keydown', onKey);
    return () => {
      window.removeEventListener('message', onMessage);
      window.removeEventListener('keydown', onKey);
    };
  }, []);

  // The card shows for a few seconds at each warning (10 / 5 / 1 min) and stays only for the last seconds, so it never
  // sits on screen ticking for the whole countdown.
  const left = card ? card.value.seconds - (now - card.at) / 1000 : 0;
  const shown = card !== null && (now - card.at < CARD_SHOW_MS || left <= CARD_FINAL_S);
  const ticking = view !== null || shown;
  useEffect(() => {
    if (!ticking) return;
    const id = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(id);
  }, [ticking]);
  // Hidden between warnings: wake up once when the final seconds start.
  useEffect(() => {
    if (!card || shown) return;
    const id = window.setTimeout(() => setNow(Date.now()), Math.max(0, (left - CARD_FINAL_S) * 1000) + 50);
    return () => window.clearTimeout(id);
  }, [card, shown, left]);

  // A card whose wipe never reported back (resource restart mid-countdown) goes 30 s after zero.
  useEffect(() => {
    if (card && now - card.at > (card.value.seconds + 30) * 1000) setCard(null);
  }, [card, now]);

  return (
    <>
      <div className="top-stack">
        {card && shown && <CountdownCard card={card.value} at={card.at} total={card.total} now={now} t={t} />}
        <Toasts items={toasts} t={t} />
      </div>
      {view && <Panel view={view.value} at={view.at} now={now} focused={focused} t={t} />}
    </>
  );
}
