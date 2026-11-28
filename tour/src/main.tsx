import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import '@fontsource/figtree/400.css';
import '@fontsource/figtree/500.css';
import '@fontsource/figtree/600.css';
import '@fontsource/figtree/700.css';
import '@fontsource/figtree/800.css';
import '@fontsource/figtree/900.css';
import 'material-icons/iconfont/round.css';
import 'material-icons/iconfont/outlined.css';
import 'material-icons/iconfont/filled.css';
import './styles/tokens.css';
import './styles/tour.css';
import './styles/app.css';
import { TourShell } from './tour/TourShell';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <TourShell />
  </StrictMode>,
);
