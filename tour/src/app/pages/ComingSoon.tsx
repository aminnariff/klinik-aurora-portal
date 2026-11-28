import { ROUTE_TITLES, type Route } from '../store';
import { Icon } from '../ui';

/** Screens that a later chapter of the tour will cover. */
export function ComingSoon({ route }: { route: Route }) {
  return (
    <div className="ka-page" style={{ height: '100%' }}>
      <div className="ka-card ka-empty" style={{ borderRadius: 12 }}>
        <div>
          <div className="ka-empty-icon"><Icon n="construction" /></div>
          <b>{ROUTE_TITLES[route]}</b>
          This screen is part of a later chapter of the tour.
        </div>
      </div>
    </div>
  );
}
