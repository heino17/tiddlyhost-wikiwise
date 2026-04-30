// flash_auto_dismiss.js – Slide-Down/Up Version

function autoHideFlash(container = document) {
  const alerts = container.querySelectorAll(
    '.alert-flash:not([data-auto-hidden]):not([data-auto-dismiss])'
  );

  alerts.forEach(alert => {
    alert.dataset.autoHidden = 'true';

    requestAnimationFrame(() => {
      alert.classList.add('showing');
    });

    setTimeout(() => {
      alert.classList.remove('showing');
      alert.classList.add('closing');

      setTimeout(() => alert.remove(), 400);
    }, 3000);
  });
}


// Turbo-Events
document.addEventListener('turbo:render', (event) => {
  const newContent = event.detail.newBody || document.body;
  autoHideFlash(newContent);
});

document.addEventListener('turbo:load', () => autoHideFlash());
document.addEventListener('DOMContentLoaded', () => autoHideFlash());

// Fallback: MutationObserver
const observer = new MutationObserver(mutations => {
  for (const mutation of mutations) {
    if (mutation.addedNodes.length) {
      autoHideFlash(mutation.target);
    }
  }
});

observer.observe(document.body, { childList: true, subtree: true });