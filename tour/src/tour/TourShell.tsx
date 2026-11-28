import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { AppFrame } from '../app/AppFrame';
import { useApp } from '../app/store';
import { Icon } from '../app/ui';
import { CHAPTERS, audienceOf, type Audience } from './chapters';
import { chaptersFor, cursor, effectiveDark, firstOf, goChapter, nextAfter, pauseForExplore, playChapter, togglePlay, useTour, type ThemePref } from './engine';

function CursorLayer() {
  const ref = useRef<HTMLDivElement>(null);
  const layer = useRef<HTMLDivElement>(null);
  useEffect(() => { cursor.attach(ref.current, layer.current); return () => cursor.attach(null, null); }, []);
  return (
    <div ref={layer} style={{ position: 'absolute', inset: 0, pointerEvents: 'none', zIndex: 9999 }}>
      <div ref={ref} className="tour-cursor">
        <svg width="26" height="28" viewBox="0 0 26 28"><path d="M3 2.5 L3 22 L8.2 17.4 L11.6 25 L15.2 23.4 L11.9 16 L19 16 Z" fill="#0f172a" stroke="#fff" strokeWidth="1.6" strokeLinejoin="round" /></svg>
      </div>
    </div>
  );
}

function Frame() {
  const outer = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);
  const frameKey = useTour((s) => s.frameKey);
  const status = useTour((s) => s.status);
  const explored = useTour((s) => s.explored);
  const swallow = useRef(false);

  useLayoutEffect(() => {
    const el = outer.current!;
    const ro = new ResizeObserver(() => { const s = el.clientWidth / 1600; setScale(s); cursor.setScale(s); });
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  return (
    <div
      ref={outer}
      className="tour-frame"
      onPointerDownCapture={(e) => {
        if (!e.isTrusted) return;
        if (useTour.getState().status === 'playing') {
          e.preventDefault();
          e.stopPropagation();
          swallow.current = true;
        }
        pauseForExplore();
      }}
      onClickCapture={(e) => {
        if (swallow.current && e.isTrusted) { e.preventDefault(); e.stopPropagation(); swallow.current = false; }
      }}
    >
      <div className="tour-frame-inner" style={{ transform: `scale(${scale})` }}>
        <AppFrame key={frameKey} />
        <CursorLayer />
      </div>
      {status === 'paused' && explored && (
        <div className="tour-paused-badge"><Icon n="touch_app" size={16} />You're exploring. Press Play to pick the tour back up.</div>
      )}
    </div>
  );
}

function ThemeSeg() {
  const theme = useTour((s) => s.theme);
  const set = (t: ThemePref) => { useTour.setState({ theme: t }); useApp.setState({ dark: effectiveDark(t) }); };
  return (
    <div className="tour-seg" role="group" aria-label="Theme">
      <button type="button" aria-pressed={theme === 'device'} aria-label="Follow device" title="Follow device" onClick={() => set('device')}><Icon n="desktop_windows" v="o" size={17} /></button>
      <button type="button" aria-pressed={theme === 'light'} aria-label="Light" title="Light" onClick={() => set('light')}><Icon n="light_mode" v="o" size={17} /></button>
      <button type="button" aria-pressed={theme === 'dark'} aria-label="Dark" title="Dark" onClick={() => set('dark')}><Icon n="dark_mode" v="o" size={17} /></button>
    </div>
  );
}

function TopBar() {
  const status = useTour((s) => s.status);
  const speed = useTour((s) => s.speed);
  const chapter = useTour((s) => s.chapter);
  const list = chaptersFor(audienceOf(CHAPTERS[chapter]!)).map((p) => p.i);
  const at = list.indexOf(chapter);
  return (
    <header className="tour-top">
      <a className="tour-brand" href="/" aria-label="Klinik Aurora Portal">
        <img src={`${import.meta.env.BASE_URL}logo.png`} alt="" />
        <b>KLINIK AURORA</b>
        <span className="tour-brand-sep" />
        <span>Product tour</span>
      </a>
      <span className="tour-top-spacer" />
      <div className="tour-controls">
        <button type="button" className="tour-icon-btn" aria-label="Previous chapter" disabled={at <= 0} onClick={() => goChapter(-1)}><Icon n="skip_previous" size={22} /></button>
        <button type="button" className="tour-play" onClick={togglePlay} aria-label={status === 'playing' ? 'Pause the tour' : 'Play the tour'}>
          <Icon n={status === 'playing' ? 'pause' : 'play_arrow'} size={20} />{status === 'playing' ? 'Pause' : 'Play'}
        </button>
        <button type="button" className="tour-icon-btn" aria-label="Next chapter" disabled={at >= list.length - 1} onClick={() => goChapter(1)}><Icon n="skip_next" size={22} /></button>
        <div className="tour-seg speed" role="group" aria-label="Speed">
          <button type="button" aria-pressed={speed === 1} onClick={() => useTour.setState({ speed: 1 })}>1×</button>
          <button type="button" aria-pressed={speed === 2} onClick={() => useTour.setState({ speed: 2 })}>2×</button>
        </div>
        <ThemeSeg />
        <a className="tour-open-app" href="/"><span>Open the portal</span><Icon n="open_in_new" size={16} /></a>
      </div>
    </header>
  );
}

function ChapterCard() {
  const { chapter: ci, step, status, explored, error } = useTour();
  const ch = CHAPTERS[ci]!;
  const aud = audienceOf(ch);
  const groupList = CHAPTERS.filter((c) => c.group === ch.group && audienceOf(c) === aud);
  const posInGroup = groupList.indexOf(ch) + 1;
  const nextRef = ch.discontinued ? undefined : nextAfter(ci);
  const next = nextRef?.c;
  const n = ch.steps.length;
  let line: string;
  if (error) line = error;
  else if (status === 'playing') line = `Playing · step ${step + 1} of ${n}. Click the screen to stop and explore.`;
  else if (status === 'paused') line = explored ? `Paused at step ${step + 1} of ${n}. Try it yourself, then press Play to carry on.` : `Paused at step ${step + 1} of ${n}.`;
  else if (ch.discontinued) line = 'Done. This chapter is kept for reference only, so the tour does not continue from here.';
  else if (next) line = `Done. "${next.title}" starts in a moment. Click the screen to stay here and explore.`;
  else line = aud === 'staff'
    ? "That's the end of the Branch staff tour. Click the screen to explore, or open the Superadmin tab above."
    : "That's the end of the Superadmin tour. Click the screen to explore, or open the portal.";
  return (
    <section className="tour-card tour-chapter" aria-live="polite">
      <div className="tour-chapter-head">
        <span className="tour-chip-icon" style={{ background: ch.color }}><Icon n={ch.icon} size={21} /></span>
        <div>
          <div className="tour-eyebrow">{ch.group} · {posInGroup} of {groupList.length}</div>
          <div className="tour-title">{ch.title}{ch.discontinued && <span className="tour-tag-disc">Discontinued</span>}</div>
        </div>
      </div>
      <p className="tour-summary">{ch.summary}</p>
      <ol className="tour-steps">
        {ch.steps.map((s, i) => {
          const done = i < step || status === 'ended';
          const active = i === step && status !== 'ended';
          return (
            <li key={i} className={`tour-step${active ? ' active' : ''}${done ? ' done' : ''}`} onClick={() => playChapter(ci, i)}>
              <span className="tour-step-num">{done ? <Icon n="check" size={15} /> : i + 1}</span>
              <span>{s.text}</span>
            </li>
          );
        })}
      </ol>
      <div className="tour-status">{line}</div>
      {status === 'ended' && next && (
        <button type="button" className="tour-next" onClick={() => playChapter(nextRef!.i)}>Next: {next.title}<Icon n="arrow_forward" size={17} /></button>
      )}
    </section>
  );
}

function RoleTabs() {
  const ci = useTour((s) => s.chapter);
  const aud = audienceOf(CHAPTERS[ci]!);
  const tab = (a: Audience, label: string, icon: string, hint: string) => (
    <button type="button" role="tab" aria-selected={aud === a} className={`tour-role${aud === a ? ' on' : ''}`} onClick={() => aud !== a && playChapter(firstOf(a))}>
      <Icon n={icon} size={18} />
      <span><b>{label}</b><small>{hint}</small></span>
    </button>
  );
  return (
    <div className="tour-card tour-roles" role="tablist" aria-label="Who is this tour for">
      {tab('staff', 'Branch staff', 'storefront', 'Front desk & branch')}
      {tab('superadmin', 'Superadmin', 'admin_panel_settings', 'HQ & management')}
    </div>
  );
}

function ChapterList() {
  const ci = useTour((s) => s.chapter);
  const aud = audienceOf(CHAPTERS[ci]!);
  const items = chaptersFor(aud, true);
  const groups = [...new Set(items.map(({ c }) => c.group))];
  return (
    <nav className="tour-card tour-list" aria-label="Chapters">
      {groups.map((g) => (
        <div key={g}>
          <div className="tour-list-group">{g}</div>
          {items.filter(({ c }) => c.group === g).map(({ c, i }) => (
            <button key={c.id} type="button" className={`tour-list-item${i === ci ? ' active' : ''}`} onClick={() => playChapter(i)} style={c.discontinued ? { color: 'var(--muted)' } : undefined}>
              <span className="tour-chip-icon sm" style={{ background: c.discontinued ? 'var(--border-strong)' : c.color }}><Icon n={c.icon} size={15} /></span>
              {c.title}
              {c.discontinued && <span className="tour-tag-disc" style={{ marginLeft: 'auto' }}>Discontinued</span>}
            </button>
          ))}
        </div>
      ))}
    </nav>
  );
}

export function TourShell() {
  const theme = useTour((s) => s.theme);
  const [dark, setDark] = useState(effectiveDark(theme));

  useEffect(() => {
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const update = () => { const d = effectiveDark(); setDark(d); useApp.setState({ dark: d }); };
    update();
    mq.addEventListener('change', update);
    return () => mq.removeEventListener('change', update);
  }, [theme]);

  useEffect(() => {
    const fromHash = () => {
      const id = location.hash.slice(1);
      const i = CHAPTERS.findIndex((c) => c.id === id && c.steps.length);
      return i >= 0 ? i : firstOf('staff');
    };
    playChapter(fromHash());
    const onHash = () => { const i = fromHash(); if (i !== useTour.getState().chapter) playChapter(i); };
    window.addEventListener('hashchange', onHash);
    const onKey = (e: KeyboardEvent) => {
      const t = e.target as HTMLElement;
      if (t.closest('input, textarea, [contenteditable]')) return;
      if (e.code === 'Space') { e.preventDefault(); togglePlay(); }
    };
    window.addEventListener('keydown', onKey);
    return () => { window.removeEventListener('hashchange', onHash); window.removeEventListener('keydown', onKey); };
  }, []);

  return (
    <div className={`tour ${dark ? 'ka-theme-dark' : 'ka-theme-light'}`}>
      <TopBar />
      <main className="tour-main">
        <div className="tour-stage">
          <Frame />
          <div className="tour-hint"><Icon n="mouse" v="o" size={16} />Click anywhere on the screen to stop the tour and try it yourself. Nothing you do here is saved.</div>
        </div>
        <aside className="tour-side">
          <RoleTabs />
          <ChapterCard />
          <ChapterList />
        </aside>
      </main>
    </div>
  );
}
