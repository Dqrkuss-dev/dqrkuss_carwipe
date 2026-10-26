import { useEffect, useState } from 'react';
import { post } from '../nui';

export type Range = { min: number; max: number; step: number };
type Props = { value: number; set: (n: number) => void; range: Range; label: string; unit: string };

export function Stepper({ value, set, range, label, unit }: Props) {
  const [text, setText] = useState(String(value));
  useEffect(() => setText(String(value)), [value]);

  const clamp = (n: number) => Math.max(range.min, Math.min(range.max, Math.round(n)));
  const commit = () => {
    const n = Number(text);
    if (text.trim() !== '' && Number.isFinite(n)) set(clamp(n));
    else setText(String(value));
  };

  return (
    <div className="stepper">
      <button disabled={value <= range.min} onClick={() => set(clamp(value - range.step))} aria-label="-">-</button>
      <label className="val">
        <input
          aria-label={label}
          inputMode="numeric"
          value={text}
          onChange={e => setText(e.target.value.replace(/[^0-9]/g, '').slice(0, 4))}
          onFocus={() => void post('typing', { on: true })}
          onBlur={() => {
            commit();
            void post('typing', { on: false });
          }}
          onKeyDown={e => {
            if (e.key === 'Enter') e.currentTarget.blur();
            e.stopPropagation();
          }}
        />
        <span className="unit">{unit}</span>
      </label>
      <button disabled={value >= range.max} onClick={() => set(clamp(value + range.step))} aria-label="+">+</button>
    </div>
  );
}
