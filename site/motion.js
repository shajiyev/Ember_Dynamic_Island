// Page motion: elements appear as they scroll into view, and cards catch the light under
// the pointer. The look is in styles.css; with Reduce Motion on, CSS shows everything in
// place, so this file only adds classes and positions.

// Lets CSS hide what will be revealed. Set here, not inline, so that if this file fails
// to load, nothing stays hidden.
document.documentElement.classList.add('js');

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
