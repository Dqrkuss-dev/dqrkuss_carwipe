import type { TabProps } from './shared';

export function HistoryTab({ view, t }: TabProps) {
  const history = view.history ?? [];
  if (history.length === 0) return <p className="empty">{t('hist_none')}</p>;

  return (
    <table className="table cw-hist">
      <thead>
        <tr>
          <th className="when">{t('col_time')}</th>
          <th className="num">{t('col_removed')}</th>
          <th className="num">{t('col_garage')}</th>
          <th className="num">{t('col_skipped')}</th>
          <th>{t('col_by')}</th>
        </tr>
      </thead>
      <tbody>
        {history.map((wipe, i) => {
          const by = wipe.by === 'auto' ? t('by_auto') : wipe.by;
          return (
            <tr key={i}>
              <td className="when mono">{wipe.when}</td>
              <td className="num">{wipe.removed ?? 0}</td>
              <td className="num">{wipe.garage ?? 0}</td>
              <td className="num">{wipe.skipped ?? 0}</td>
              <td aria-label={by}>{by}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
