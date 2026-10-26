import { useState } from 'react';
import { AddCircle, Trash } from '../icons';
import { useArmed, type TabProps } from './shared';

type Kind = 'car' | 'model' | 'plate';
const KINDS: Kind[] = ['car', 'model', 'plate'];
const KIND_TEXT: Record<Kind, string> = { car: 'keep_kind_car', model: 'keep_kind_model', plate: 'keep_kind_plate' };

export function KeptTab({ view, t, ask, sending }: TabProps) {
  const [kind, setKind] = useState<Kind>('car');
  const { armed, arm, disarm } = useArmed();
  const kept = view.kept ?? [];

  return (
    <>
      <div className="cw-save">
        <span className="cw-kinds">
          {KINDS.map(k => (
            <button key={k} className={k === kind ? 'btn picked' : 'btn'} onClick={() => setKind(k)}>{t(KIND_TEXT[k])}</button>
          ))}
        </span>
        <button className="btn primary" disabled={sending} onClick={() => void ask('keep', { kind }, null)}>
          <AddCircle size={16} />{t('kept_add')}
        </button>
      </div>

      {kept.length === 0 ? <p className="empty">{t('kept_none', { command: view.command ?? 'carwipe' })}</p> : (
        <table className="table cw-kept">
          <thead>
            <tr><th>{t('col_model')}</th><th className="plate">{t('col_plate')}</th><th className="act" /></tr>
          </thead>
          <tbody>
            {kept.map(entry => {
              const key = `${entry.i}:${entry.plate ?? ''}`;
              const sure = armed === key;
              const remove = () => {
                if (!sure) return arm(key);
                disarm();
                void ask('unkeep', { i: entry.i, plate: entry.plate }, 'fb_unkept', { plate: entry.plate ?? '' });
              };
              return (
                <tr key={key}>
                  <td>{entry.kind === 'plate' ? t('kept_any') : entry.label || '?'}</td>
                  <td className="plate mono">{entry.kind === 'model' ? t('kept_any') : entry.plate || '-'}</td>
                  <td className="act">
                    <button className={sure ? 'btn danger armed' : 'btn danger'} disabled={sending} onClick={remove}>
                      <Trash size={15} />{sure ? t('btn_sure') : t('btn_remove')}
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
    </>
  );
}
