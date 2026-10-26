export const inGame = typeof window.GetParentResourceName === 'function';
export const RES = inGame ? window.GetParentResourceName!() : 'dqrkuss_carwipe';

export type State = 'waiting' | 'countdown' | 'wiping' | 'off';
export type Kept = { i: number; kind?: 'car' | 'model' | 'plate'; model?: number; label?: string; plate?: string };
export type Zone = { i: number; x: number; y: number; radius: number; dist?: number };
export type Wipe = { when: string; removed?: number; garage?: number; skipped?: number; by?: string };

// server/wipe.lua Wipe.view, server/panel.lua viewFor, plus the command from client/panel.lua
export type View = {
  state: State;
  left?: number;
  interval: number;
  smart: number;
  blocked?: string[];
  kept?: Kept[];
  keepMax?: number;
  zones?: Zone[];
  zonesOn?: boolean;
  zonesMax?: number;
  zoneRadius?: number;
  history?: Wipe[];
  command?: string;
};
export type Countdown = { seconds: number; command?: string | null };
export type ToastKind = 'inform' | 'success' | 'warning' | 'error';
export type Reply = { ok: boolean; err?: string };

export async function post(name: string, data: unknown = {}): Promise<Reply> {
  if (!inGame) return { ok: true };
  try {
    const res = await fetch(`https://${RES}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    return (await res.json()) as Reply;
  } catch {
    return { ok: false, err: 'busy' };
  }
}

// 0:42, 9:05, 1:02:03
export function clock(seconds: number): string {
  const s = Math.max(0, Math.floor(seconds));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const two = (n: number) => String(n).padStart(2, '0');
  return h > 0 ? `${h}:${two(m)}:${two(s % 60)}` : `${m}:${two(s % 60)}`;
}

// Seconds left now, from a value received at `at` (Date.now()).
export function leftNow(left: number | undefined, at: number, now: number): number | undefined {
  if (typeof left !== 'number') return undefined;
  return Math.max(0, left - Math.floor((now - at) / 1000));
}
