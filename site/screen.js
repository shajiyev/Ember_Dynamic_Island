// Sizes the hero's mock screen and runs its menu bar clock. The screen is drawn at 1280 px
// wide (styles.css) and scaled down to fit, so the open panel keeps its true share of the
// width; below 800 px the screen is a close-up instead, and the open panel is scaled to fit.
import { clockText } from './clock.js';

const SCREEN_WIDTH = 1280;
const PANEL_WIDTH = 620;   // the app's open panel

const screen = document.querySelector('.screen');
const wallpaper = screen.querySelector('.wallpaper');
const clock = screen.querySelector('.menu-clock');

function fit() {
  screen.style.setProperty('--screen-scale', Math.min(1, screen.clientWidth / SCREEN_WIDTH));
  const room = wallpaper.clientWidth - 16;
  // On the screen, so the pill and, below 800 px, the wallpaper's height both use it.
  screen.style.setProperty('--open-scale', Math.min(1, room / PANEL_WIDTH));
}

function showTime() {
  clock.textContent = clockText(new Date());
}

fit();
addEventListener('resize', fit);
showTime();
setInterval(showTime, 10 * 1000);
