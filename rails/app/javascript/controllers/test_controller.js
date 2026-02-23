import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="test"
export default class extends Controller {
  connect() {
    console.log("Stimulus Test-Controller ist verbunden! 🎉")
    console.log("Element:", this.element)   // zeigt das HTML-Element
  }
}
