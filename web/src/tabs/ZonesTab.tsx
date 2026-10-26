import { useState } from 'react';
import { AddCircle, MapArrow, Trash } from '../icons';
import { Stepper } from './Stepper';
import { useArmed, type TabProps } from './shared';

const RADIUS = { min: 5, max: 100, step: 5 };

export function ZonesTab({ view, t, ask, sending }: TabProps) {
  const [radius, setRadius] = useState(view.zoneRadius ?? 25);
  const { armed, arm, disarm } = useArmed();
  const zones = view.zones ?? [];
  const full = zones.length >= (view.zonesMax ?? 100);

  return (
    <>
      {view.zonesOn === false && <p className="note warn">{t('zones_off')}</p>}
      <div className="pgrid">
        <div className="pg-row">
          <span className="pg-name"><span>{t('zone_radius')}</span></span>
          <Stepper value={radius} set={setRadius} range={RADIUS} label={t('zone_radius')} unit={t('unit_m')} />
        </div>
        <div className="cw-save">
          <span className="mono">{zones.length} / {view.zonesMax ?? 100}</span>
          <button className="btn primary" disabled={sending || full} onClick={() => void ask('zoneAdd', { radius }, 'fb_zone_added')}>
            <AddCircle size={16} />{t('zone_add')}
          </button>
        </div>
      </div>

      {zones.length === 0 ? <p className="empty">{t('zones_none')}</p> : (
        <table className="table cw-zones">
          <thead>
            <tr>
              <th>{t('col_zone')}</th>
              <th className="num">{t('col_radius')}</th>
              <th className="num">{t('col_dist')}</th>
              <th className="act" />
            </tr>
          </thead>
          <tbody>
            {zones.map(zone => {
              const key = `${zone.i}:${zone.x}:${zone.y}`;
              const sure = armed === key;
              const target = { i: zone.i, x: zone.x, y: zone.y };
              const remove = () => {
                if (!sure) return arm(key);
                disarm();
                void ask('zoneRemove', target, 'fb_zone_removed');
              };
              return (
                <tr key={key}>
                  <td className="mono">#{zone.i}</td>
                  <td className="num">{zone.radius} {t('unit_m')}</td>
                  <td className="num">{zone.dist === undefined ? '-' : `${zone.dist} ${t('unit_m')}`}</td>
                  <td className="act">
                    <button className="btn" disabled={sending} onClick={() => void ask('zoneGoto', target, 'fb_zone_goto')}>
                      <MapArrow size={15} />{t('btn_goto')}
                    </button>
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
