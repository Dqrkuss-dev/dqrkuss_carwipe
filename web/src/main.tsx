import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import en from '../../locales/en.json';
import bg from '../../locales/bg.json';
import de from '../../locales/de.json';
import es from '../../locales/es.json';
import fr from '../../locales/fr.json';
import it from '../../locales/it.json';
import nl from '../../locales/nl.json';
import pl from '../../locales/pl.json';
import pt from '../../locales/pt.json';
import ru from '../../locales/ru.json';
import tr from '../../locales/tr.json';
import { registerDictionaries } from './i18n';
import { App } from './App';
import './fonts/fonts.css';
import './styles/tokens.css';
import './styles/tool.css';
import './styles/panel.css';
import './styles/toast.css';

registerDictionaries({ en, bg, de, es, fr, it, nl, pl, pt, ru, tr });

// Sizes are designed for 1080p; other screen heights scale the whole page.
function fitScreen() {
  const scale = Math.min(2, Math.max(0.6, window.innerHeight / 1080));
  const root = document.documentElement;
  root.style.zoom = String(scale);
  root.style.setProperty('--page-h', `${window.innerHeight / scale}px`);
}
fitScreen();
window.addEventListener('resize', fitScreen);

createRoot(document.getElementById('root')!).render(<StrictMode><App /></StrictMode>);
