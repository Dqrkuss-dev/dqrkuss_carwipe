import type { T } from './i18n';
import type { ToastKind } from './nui';
import { Bell, CheckCircle, Clock, Danger } from './icons';

export type ToastItem = { id: number; text: string; kind: ToastKind };

const ICONS = { inform: Bell, success: CheckCircle, warning: Clock, error: Danger };

export function Toasts({ items, t }: { items: ToastItem[]; t: T }) {
  return (
    <div className="toasts">
      {items.map(item => {
        const Icon = ICONS[item.kind] ?? Bell;
        return (
          <div key={item.id} className={`toast ${item.kind}`} role="status">
            <span className="toast-icon"><Icon size={22} /></span>
            <div className="toast-text">
              <div className="toast-title">{t('title')}</div>
              <div className="toast-body">{item.text}</div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
