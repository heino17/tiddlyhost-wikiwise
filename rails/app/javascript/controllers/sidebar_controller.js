import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid", "button"]

  connect() {
    // Zustand aus LocalStorage laden
    const hidden = localStorage.getItem("sidebarHidden") === "true"
    if (hidden) {
      this.gridTarget.classList.add("sidebar-hidden")
    }
  }

  toggle() {
    this.gridTarget.classList.toggle("sidebar-hidden")

    // Zustand speichern
    const isHidden = this.gridTarget.classList.contains("sidebar-hidden")
    localStorage.setItem("sidebarHidden", isHidden)
  }
}
