import { useEffect, useRef, useState } from 'react';
import type { T, TextArgs } from '../i18n';
import type { View } from '../nui';

// Sends one panel request; `done` is the text shown when the server accepts it (null: the view change says enough).
export type Ask = (action: string, data: Record<string, unknown>, done: string | null, args?: TextArgs) => Promise<void>;
export type TabProps = { view: View; t: T; ask: Ask; sending: boolean };

// Destructive buttons need a second press within 4 s.
export function useArmed() {
  const [armed, setArmed] = useState<string | null>(null);
  const timer = useRef(0);
  useEffect(() => () => window.clearTimeout(timer.current), []);
  const arm = (key: string) => {
    window.clearTimeout(timer.current);
    setArmed(key);
    timer.current = window.setTimeout(() => setArmed(null), 4000);
  };
  return { armed, arm, disarm: () => setArmed(null) };
}
