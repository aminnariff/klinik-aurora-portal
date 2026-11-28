import { create } from 'zustand';
import { useApp } from '../app/store';
import { relRect } from '../app/ui';
import { CHAPTERS, audienceOf, type Audience, type Chapter } from './chapters';

export type Status = 'playing' | 'paused' | 'ended';
export type ThemePref = 'device' | 'light' | 'dark';

interface TourState {
  chapter: number;
  step: number;
  status: Status;
  speed: 1 | 2;
  theme: ThemePref;
  /** The viewer clicked into the replica, so its state may differ from the script. */
  explored: boolean;
  /** Bumped to remount the replica with fresh local state. */
  frameKey: number;
  error: string | null;
}

export const useTour = create<TourState>(() => ({
  chapter: 0, step: 0, status: 'paused', speed: 1, theme: 'device', explored: false, frameKey: 0, error: null,
}));

/** Chapter indexes for one tab, in order. Discontinued chapters stay listed but are skipped by autoplay and prev/next. */
export const chaptersFor = (aud: Audience, includeDiscontinued = false) =>
  CHAPTERS.map((c, i) => ({ c, i })).filter(({ c }) => c.steps.length > 0 && audienceOf(c) === aud && (includeDiscontinued || !c.discontinued));
export const firstOf = (aud: Audience) => chaptersFor(aud)[0]!.i;
/** Next chapter in the same tab, or undefined at the end. */
export const nextAfter = (index: number) => chaptersFor(audienceOf(CHAPTERS[index]!)).find((p) => p.i > index);

class Aborted extends Error {}

// ── Cursor ─────────────────────────────────────────────────
let cursorEl: HTMLDivElement | null = null;
let rippleLayer: HTMLDivElement | null = null;
let pos = { x: 1180, y: 640 };
let frameScale = 1;

function applyCursor(ms: number) {
  if (!cursorEl) return;
  cursorEl.style.transitionDuration = `${ms}ms`;
  cursorEl.style.transform = `translate(${pos.x}px, ${pos.y}px) scale(${Math.min(1 / frameScale, 1.6)})`;
}
export const cursor = {
  attach(el: HTMLDivElement | null, layer: HTMLDivElement | null) { cursorEl = el; rippleLayer = layer; applyCursor(0); },
  setScale(s: number) { frameScale = s; applyCursor(0); },
  teleport(x: number, y: number) { pos = { x, y }; applyCursor(0); },
  move(x: number, y: number, ms: number) { pos = { x, y }; applyCursor(ms); },
  press(down: boolean) { cursorEl?.classList.toggle('pressed', down); },
  ripple() {
    if (!rippleLayer) return;
    const r = document.createElement('div');
    r.className = 'tour-ripple';
    r.style.left = `${pos.x}px`;
    r.style.top = `${pos.y}px`;
    rippleLayer.appendChild(r);
    setTimeout(() => r.remove(), 600);
  },
};

// ── Timing helpers ─────────────────────────────────────────
const nextFrame = () => new Promise<void>((r) => requestAnimationFrame(() => r()));
let resumeWaiters: (() => void)[] = [];
const releaseWaiters = () => { const w = resumeWaiters; resumeWaiters = []; w.forEach((f) => f()); };

function check(sig: AbortSignal) { if (sig.aborted) throw new Aborted(); }

function sleep(ms: number, sig: AbortSignal) {
  return new Promise<void>((resolve, reject) => {
    const t = setTimeout(resolve, ms);
    sig.addEventListener('abort', () => { clearTimeout(t); reject(new Aborted()); }, { once: true });
  });
}

async function whilePaused(sig: AbortSignal) {
  while (useTour.getState().status !== 'playing') {
    check(sig);
    await new Promise<void>((r) => resumeWaiters.push(r));
  }
  check(sig);
}

async function wait(ms: number, sig: AbortSignal, instant: boolean) {
  check(sig);
  if (instant) return;
  let left = ms;
  while (left > 0) {
    await whilePaused(sig);
    const slice = Math.min(left, 40);
    await sleep(slice, sig);
    left -= slice * useTour.getState().speed;
  }
}

// ── Element helpers ────────────────────────────────────────
function query(target: string): HTMLElement | null {
  return document.querySelector(`#ka-root [data-tour="${target}"]`);
}

async function find(target: string, sig: AbortSignal, timeout = 4000): Promise<HTMLElement> {
  const t0 = performance.now();
  for (;;) {
    check(sig);
    const el = query(target);
    if (el && el.getClientRects().length) return el;
    if (performance.now() - t0 > timeout) throw new Error(`Tour target not found: ${target}`);
    await nextFrame();
  }
}

/** Scroll the nearest scrollable ancestor inside the replica so `el` is in view. */
async function ensureVisible(el: HTMLElement, sig: AbortSignal, instant: boolean) {
  const root = document.getElementById('ka-root');
  let p = el.parentElement;
  while (p && p !== root) {
    const st = getComputedStyle(p);
    if (/(auto|scroll)/.test(st.overflowY) && p.scrollHeight > p.clientHeight + 2) {
      const er = relRect(el), pr = relRect(p);
      const top = er.top - pr.top, bottom = top + er.height;
      if (top < 8 || bottom > p.clientHeight - 8) {
        const delta = top < 8 ? top - 24 : bottom - p.clientHeight + 24;
        p.scrollTo({ top: p.scrollTop + delta, behavior: instant ? 'auto' : 'smooth' });
        await wait(420, sig, instant);
      }
    }
    p = p.parentElement;
  }
}

function setNativeValue(el: HTMLInputElement | HTMLTextAreaElement, value: string) {
  const proto = el instanceof HTMLTextAreaElement ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
  Object.getOwnPropertyDescriptor(proto, 'value')!.set!.call(el, value);
  el.dispatchEvent(new Event('input', { bubbles: true }));
}

// ── Step context ───────────────────────────────────────────
export interface Ctx {
  wait(ms: number): Promise<void>;
  move(target: string, opts?: { at?: [number, number] }): Promise<HTMLElement>;
  click(target: string, opts?: { at?: [number, number] }): Promise<void>;
  clickNth(prefix: string, n: number): Promise<void>;
  /** How many enabled elements whose data-tour starts with `prefix` are on screen. */
  count(prefix: string): number;
  type(target: string, text: string): Promise<void>;
  app: typeof useApp.getState;
}

function makeCtx(sig: AbortSignal, instant: boolean): Ctx {
  const move = async (target: string, opts?: { at?: [number, number] }) => {
    const el = await find(target, sig);
    await ensureVisible(el, sig, instant);
    const r = relRect(el);
    const [fx, fy] = opts?.at ?? [0.5, 0.5];
    const x = r.left + r.width * fx, y = r.top + r.height * fy;
    if (instant) { cursor.teleport(x, y); return el; }
    await whilePaused(sig);
    const dist = Math.hypot(x - posNow().x, y - posNow().y);
    const ms = Math.min(950, 280 + dist * 0.45) / useTour.getState().speed;
    cursor.move(x, y, ms);
    await wait(ms * useTour.getState().speed + 60, sig, false);
    return el;
  };
  const clickEl = async (el: HTMLElement) => {
    if (!instant) {
      cursor.press(true);
      await wait(110, sig, false);
      cursor.ripple();
    }
    el.click();
    if (!instant) {
      cursor.press(false);
      await wait(260, sig, false);
    }
    await nextFrame();
  };
  return {
    wait: (ms) => wait(ms, sig, instant),
    move,
    click: async (target, opts) => { const el = await move(target, opts); await clickEl(el); },
    clickNth: async (prefix, n) => {
      const t0 = performance.now();
      let els: HTMLElement[] = [];
      while (performance.now() - t0 < 4000) {
        check(sig);
        els = [...document.querySelectorAll<HTMLElement>(`#ka-root [data-tour^="${prefix}"]`)].filter((e) => !(e as HTMLButtonElement).disabled);
        if (els.length > n) break;
        await nextFrame();
      }
      const el = els[Math.min(n, els.length - 1)];
      if (!el) throw new Error(`Tour target not found: ${prefix}[${n}]`);
      await move(el.dataset.tour!);
      await clickEl(el);
    },
    count: (prefix) => [...document.querySelectorAll<HTMLElement>(`#ka-root [data-tour^="${prefix}"]`)].filter((e) => !(e as HTMLButtonElement).disabled).length,
    type: async (target, text) => {
      const box = await move(target);
      const input = (box.matches('input,textarea') ? box : box.querySelector('input,textarea')) as HTMLInputElement;
      if (!instant) { cursor.press(true); await wait(90, sig, false); cursor.press(false); }
      input.focus({ preventScroll: true });
      if (instant) { setNativeValue(input, text); await nextFrame(); return; }
      let v = '';
      for (const ch of text) {
        v += ch;
        setNativeValue(input, v);
        await wait(ch === ' ' ? 70 : 42, sig, false);
      }
      await wait(200, sig, false);
    },
    app: useApp.getState,
  };
}
const posNow = () => pos;

// ── Runner ─────────────────────────────────────────────────
let current: AbortController | null = null;
let autoAdvance: ReturnType<typeof setTimeout> | null = null;

export function effectiveDark(theme = useTour.getState().theme) {
  return theme === 'dark' || (theme === 'device' && window.matchMedia('(prefers-color-scheme: dark)').matches);
}

export async function playChapter(index: number, fromStep = 0) {
  const chapter: Chapter | undefined = CHAPTERS[index];
  if (!chapter || !chapter.steps.length) return;
  current?.abort();
  releaseWaiters();
  if (autoAdvance) clearTimeout(autoAdvance);
  const ctrl = new AbortController();
  current = ctrl;
  const sig = ctrl.signal;

  if (location.hash !== `#${chapter.id}`) history.replaceState(null, '', `#${chapter.id}`);
  useApp.getState().reset(chapter.role);
  useApp.setState({ dark: effectiveDark() });
  chapter.setup?.(useApp.getState());
  useTour.setState((s) => ({ chapter: index, step: fromStep, status: 'playing', explored: false, frameKey: s.frameKey + 1, error: null }));
  await nextFrame();
  await nextFrame();
  cursor.teleport(1180, 640);

  try {
    for (let i = 0; i < fromStep; i++) await chapter.steps[i]!.run(makeCtx(sig, true));
    for (let i = fromStep; i < chapter.steps.length; i++) {
      useTour.setState({ step: i });
      await wait(350, sig, false);
      await chapter.steps[i]!.run(makeCtx(sig, false));
      await wait(1100, sig, false);
    }
    useTour.setState({ step: chapter.steps.length, status: 'ended' });
    const next = CHAPTERS[index]!.discontinued ? undefined : nextAfter(index);
    if (next) {
      autoAdvance = setTimeout(() => {
        const s = useTour.getState();
        if (s.status === 'ended' && !s.explored && s.chapter === index && current === ctrl) playChapter(next.i);
      }, 3200);
    }
  } catch (e) {
    if (e instanceof Aborted) return;
    console.error(e);
    useTour.setState({ status: 'paused', explored: true, error: 'This step could not play. Press Play to try it again.' });
  }
}

export function pause() {
  if (useTour.getState().status === 'playing') useTour.setState({ status: 'paused' });
}

/** The viewer clicked the replica: stop and let them explore. */
export function pauseForExplore() {
  const s = useTour.getState();
  if (autoAdvance) clearTimeout(autoAdvance);
  if (s.status === 'playing') useTour.setState({ status: 'paused', explored: true });
  else if (!s.explored) useTour.setState({ explored: true });
}

export function play() {
  const s = useTour.getState();
  if (s.status === 'ended') {
    const next = nextAfter(s.chapter);
    playChapter(next ? next.i : firstOf(audienceOf(CHAPTERS[s.chapter]!)));
  } else if (s.explored || s.error) {
    playChapter(s.chapter, s.step);
  } else {
    useTour.setState({ status: 'playing' });
    releaseWaiters();
  }
}

export function togglePlay() {
  if (useTour.getState().status === 'playing') pause();
  else play();
}

export function goChapter(delta: 1 | -1) {
  const s = useTour.getState();
  const list = chaptersFor(audienceOf(CHAPTERS[s.chapter]!)).map((p) => p.i);
  const at = list.indexOf(s.chapter);
  const target = list[at + delta];
  if (target != null) playChapter(target);
}
