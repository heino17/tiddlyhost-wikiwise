import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner", "stats", "marketing"]

  connect() {
    const saved = localStorage.getItem("cookie_consent")

    if (saved) {
      const consent = JSON.parse(saved)
      this.statsTarget.checked = consent.stats ?? true
      this.marketingTarget.checked = consent.marketing ?? true
      this.activateScripts(consent)
    } else {
      setTimeout(() => this.show(), 150)
    }
  }

  show(event) {
    if (event) event.preventDefault()
  
    // WICHTIG: alle Störklassen entfernen
    this.bannerTarget.classList.remove("hidden")
    this.bannerTarget.classList.remove("hiding")
    this.bannerTarget.classList.remove("visible") // reset für Bounce
  
    // Animation sauber starten
    requestAnimationFrame(() => {
      this.bannerTarget.classList.add("visible")
    })
  }

  hide() {
    this.bannerTarget.classList.remove("visible")
    this.bannerTarget.classList.add("hiding")
  
    setTimeout(() => {
      this.bannerTarget.classList.add("hidden")
      this.bannerTarget.classList.remove("hiding")
    }, 550) // Bounce dauert 0.55s
  }

  acceptAll(e) {
    e.preventDefault()
    this.statsTarget.checked = true
    this.marketingTarget.checked = true
    this.save()
  }

  rejectAll(e) {
    e.preventDefault()
    this.statsTarget.checked = false
    this.marketingTarget.checked = false
    this.save()
  }

  save(e) {
    if (e) e.preventDefault()
    
    const consent = {
      stats: this.statsTarget.checked,
      marketing: this.marketingTarget.checked
    }

    localStorage.setItem("cookie_consent", JSON.stringify(consent))
    this.activateScripts(consent)
    this.hide()
  }

  activateScripts(consent) {
    document.querySelectorAll("[data-cookie-blocked-script]").forEach(script => {
      const category = script.dataset.cookieCategory
      if (consent[category] === true) {
        const newScript = document.createElement("script")
        newScript.type = "text/javascript"
        if (script.src) newScript.src = script.src
        if (script.textContent) newScript.textContent = script.textContent
        script.replaceWith(newScript)
      }
    })
  }
}
