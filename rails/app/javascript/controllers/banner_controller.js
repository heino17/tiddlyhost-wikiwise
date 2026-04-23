import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("✅ Banner controller wurde geladen!");
  }

  dismiss() {
    console.log("✅ Dismiss wurde geklickt!");

    // Sofort die "show"-Klasse entfernen → löst Fade-Out aus
    this.element.classList.remove("show");

    // Rails informieren, dass der Banner dismissed wurde
    fetch('/banner/dismiss', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
        'Content-Type': 'application/json'
      }
    });

    // Element erst nach der CSS-Transition entfernen
    setTimeout(() => {
      this.element.remove();
    }, 800); // gleiche Dauer wie in flash_fade.scss
  }
}
