// flash_auto_dismiss.js – Ausblenden aller .alert-flash nach 3 Sekunden (auch Turbo-Streams)

function autoHideFlash(container = document) {
  console.log("flash_auto_dismiss.js wurde geladen!");

  const alerts = container.querySelectorAll('.alert-flash:not([data-auto-hidden])');

  alerts.forEach(alert => {
    alert.dataset.autoHidden = 'true';  // verhindert Mehrfach-Timer

    setTimeout(() => {
      // Bootstrap-Animation nutzen, falls vorhanden
      const bsAlert = bootstrap?.Alert?.getOrCreateInstance(alert);
      if (bsAlert) {
        bsAlert.close();
      } else {
        // Fallback: CSS-Transition + Remove
        alert.classList.remove('show');
        setTimeout(() => alert.remove(), 800); // passt zur 0.8s Transition
      }
    }, 3000);
  });
}

// Bei jedem Turbo-Update den neuen Inhalt prüfen
document.addEventListener('turbo:render', (event) => {
  // event.detail.newBody ist der neu gerenderte Teil
  const newContent = event.detail.newBody || document.body;
  autoHideFlash(newContent);
});

// Sicherheitshalber auch beim ersten Laden
document.addEventListener('turbo:load', () => autoHideFlash());
document.addEventListener('DOMContentLoaded', () => autoHideFlash());

// Optional: MutationObserver als Fallback (sehr robust)
const observer = new MutationObserver(mutations => {
  mutations.forEach(mutation => {
    if (mutation.addedNodes.length) {
      autoHideFlash(mutation.target);
    }
  });
});
observer.observe(document.body, { childList: true, subtree: true });