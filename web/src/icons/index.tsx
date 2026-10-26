// Panel icons: one 96 x 96 PNG per icon in ./png, drawn for this script. Swap a file to change an icon.
import add from './png/add.png';
import bell from './png/bell.png';
import bolt from './png/bolt.png';
import check from './png/check.png';
import clock from './png/clock.png';
import close from './png/close.png';
import danger from './png/danger.png';
import history from './png/history.png';
import mapArrow from './png/maparrow.png';
import mapPoint from './png/mappoint.png';
import play from './png/play.png';
import save from './png/save.png';
import settings from './png/settings.png';
import shield from './png/shield.png';
import stop from './png/stop.png';
import trash from './png/trash.png';

type Props = { size?: number | string };

const icon = (src: string) => function Icon({ size = '1em' }: Props) {
  return <img className="ico" src={src} width={size} height={size} alt="" aria-hidden="true" draggable={false} />;
};

export const AddCircle = icon(add);
export const Bell = icon(bell);
export const Bolt = icon(bolt);
export const CheckCircle = icon(check);
export const Clock = icon(clock);
export const Close = icon(close);
export const Danger = icon(danger);
export const History = icon(history);
export const MapArrow = icon(mapArrow);
export const MapPoint = icon(mapPoint);
export const Play = icon(play);
export const Save = icon(save);
export const Settings = icon(settings);
export const Shield = icon(shield);
export const Stop = icon(stop);
export const Trash = icon(trash);
