// Page motion: elements appear as they scroll into view, cards catch the light under the
// pointer, and (in Safari) FAQ answers slide. The look is in styles.css; with Reduce Motion
// on, CSS shows everything in place, so this file mostly adds classes and positions. The html.js mark that lets CSS hide
// what will be revealed is set in index.html, before the page is drawn.

// Elements in the hero and in each grid appear one after another.
for (const group of document.querySelectorAll('.hero .container, .grid')) {
  [...group.querySelectorAll(':scope > [data-reveal]')]
    .forEach((element, index) => element.style.setProperty('--reveal-order', index));
}

// Reveal each element once 15% of it is on screen.
const observer = new IntersectionObserver((entries) => {
  for (const entry of entries) {
    if (!entry.isIntersecting) continue;
    entry.target.classList.add('is-visible');
    observer.unobserve(entry.target);
  }
}, { threshold: 0.15 });
document.querySelectorAll('[data-reveal]').forEach((element) => observer.observe(element));

// The glow inside a card follows the pointer.
for (const card of document.querySelectorAll('.card')) {
  card.addEventListener('pointermove', (event) => {
    const box = card.getBoundingClientRect();
    card.style.setProperty('--light-x', `${event.clientX - box.left}px`);
    card.style.setProperty('--light-y', `${event.clientY - box.top}px`);
  });
}

// FAQ answers slide open and shut. Chrome does this in CSS (styles.css, step 7); Safari,
// which every iPhone browser runs on, can't animate to a height of "auto" yet, so there the
// heights are measured and animated here. The native "one open at a time" (name="faq")
// would shut the old answer instantly, so this takes it over to slide that one shut too.
if (!CSS.supports('interpolate-size', 'allow-keywords')
    && matchMedia('(prefers-reduced-motion: no-preference)').matches) {
  const items = [...document.querySelectorAll('.faq-item')];
  for (const item of items) {
    item.removeAttribute('name');
    item.querySelector('summary').addEventListener('click', (event) => {
      event.preventDefault();
      const opening = !item.open || item.classList.contains('is-closing');
      if (opening) {
        for (const other of items) {
          if (other !== item && other.open && !other.classList.contains('is-closing')) slide(other, false);
        }
      }
      slide(item, opening);
    });
  }
}

// Slides one FAQ item open or shut from wherever it is now, even mid-slide. While shutting
// it stays open (so the answer is visible as it slides away); .is-closing turns the chevron.
function slide(item, open) {
  const from = item.offsetHeight;
  item.slide?.cancel();
  item.open = false;
  const closedHeight = item.offsetHeight;
  item.open = true;
  const openHeight = item.offsetHeight;
  item.classList.toggle('is-closing', !open);
  item.style.overflow = 'hidden';
  item.slide = item.animate(
    { height: [`${from}px`, `${open ? openHeight : closedHeight}px`] },
    { duration: 350, easing: 'cubic-bezier(0.3, 1.1, 0.5, 1)' },
  );
  item.slide.onfinish = () => {
    item.open = open;
    item.classList.remove('is-closing');
    item.style.overflow = '';
    item.slide = null;
  };
}

// Section links (Download, FAQ…), and shared links that end in one (…/#faq), scroll to their
// section; then the address drops the #section, so a reload stays where the visitor is
// instead of jumping back to that section. On opening, it waits until the page has loaded
// and the browser has scrolled there.
function dropSection() {
  if (location.hash) history.replaceState(null, '', location.pathname + location.search);
}
addEventListener('hashchange', dropSection);
addEventListener('load', () => setTimeout(dropSection));

// A reload always opens at the top, on the hero: the browser doesn't put the visitor back
// where they were (Safari on iPhone kept putting them back at "Light up your notch").
history.scrollRestoration = 'manual';

// "Light up your notch.": one hot spot per ember, each a copy of the heading's text that
// styles.css lights only where that ember lifts off (motion item 10). Copies, so the light
// falls on the letters themselves, wherever the heading wraps.
const fire = document.querySelector('.fire');
if (fire) {
  const text = fire.firstChild.textContent;
  const spots = fire.querySelector('.hot-spots');
  const count = fire.querySelectorAll('.embers i').length;
  for (let i = 0; i < count; i++) spots.append(Object.assign(document.createElement('span'), { textContent: text }));
}
