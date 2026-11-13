// The light/dark switch in the top bar (spec: "Dark mode"). The page follows the system's
// setting (in CSS) until the visitor chooses a mode here; the choice is kept in this
// browser, and the inline script in <head> applies it before the page is drawn. Without
// this file the switch stays hidden.

const root = document.documentElement;
const button = document.querySelector('.theme-switch');
const systemDark = matchMedia('(prefers-color-scheme: dark)');
const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)');

function isDark() {
  return root.dataset.theme ? root.dataset.theme === 'dark' : systemDark.matches;
}

function showSwitch() {
  button.setAttribute('aria-checked', String(isDark()));
}

function choose(dark) {
  root.dataset.theme = dark ? 'dark' : 'light';
  showSwitch();
}

function save(dark) {
  try { localStorage.setItem('theme', dark ? 'dark' : 'light'); } catch {}   // some private windows refuse
}

button.addEventListener('click', () => {
  const dark = !isDark();
  save(dark);
  // A cross-fade where the browser has one; instant otherwise and with Reduce Motion.
  if (document.startViewTransition && !reduceMotion.matches) {
    document.startViewTransition(() => choose(dark));
  } else {
    choose(dark);
  }
});

// The page follows a system change by itself (CSS); the switch follows it here.
systemDark.addEventListener('change', showSwitch);

showSwitch();
button.hidden = false;
