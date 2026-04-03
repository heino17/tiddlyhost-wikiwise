import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "messages", "input"]

  toggle() {
    const body = this.bodyTarget
    const isHidden = body.style.display === "none"
    body.style.display = isHidden ? "block" : "none"
  
    if (isHidden) {
      // WICHTIG: Header statt Widget scrollen
      const header = document.getElementById("shoutbox-header")
      const y = header.getBoundingClientRect().top + window.scrollY - 20
      window.scrollTo({ top: y, behavior: "smooth" })
    }
  }

  submit(event) {
    event.preventDefault()
    const form = event.target
    const input = this.inputTarget

    if (input.value.trim() === "") return

    fetch(form.action, {
      method: "POST",
      body: new FormData(form),
      headers: { "Accept": "text/vnd.turbo-stream.html" }
    }).then(response => {
      if (response.ok) {
        input.value = ""
        // Hier später Turbo Stream für neue Nachricht einbauen
      }
    })
  }
}