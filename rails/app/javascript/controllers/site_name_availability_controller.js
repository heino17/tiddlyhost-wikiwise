import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status"]
  static values = {
    url: String,
    siteId: String,
    checkingText: String,
    availableText: String,
    takenText: String
  }

  disconnect() {
    window.clearTimeout(this.timeout)
    if (this.abortController) this.abortController.abort()
  }

  check() {
    window.clearTimeout(this.timeout)
    const name = this.inputTarget.value.trim()

    if (!name) {
      if (this.abortController) this.abortController.abort()
      this.clearStatus()
      return
    }

    this.timeout = window.setTimeout(() => this.checkAvailability(name), 300)
  }

  async checkAvailability(name) {
    if (this.abortController) this.abortController.abort()
    this.abortController = new AbortController()
    this.setStatus(this.checkingTextValue, "text-muted")

    const params = new URLSearchParams({ name })
    if (this.siteIdValue) params.set("site_id", this.siteIdValue)

    try {
      const response = await fetch(`${this.urlValue}?${params}`, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })

      if (!response.ok) throw new Error(response.statusText)

      const data = await response.json()
      if (data.available) {
        this.setStatus(this.availableTextValue, "text-success")
      } else {
        this.setStatus(this.takenTextValue, "text-danger")
      }
    } catch (error) {
      if (error.name !== "AbortError") this.clearStatus()
    }
  }

  setStatus(message, className) {
    this.statusTarget.textContent = message
    this.statusTarget.classList.remove("text-muted", "text-success", "text-danger")
    this.statusTarget.classList.add(className)
  }

  clearStatus() {
    this.statusTarget.textContent = ""
    this.statusTarget.classList.remove("text-muted", "text-success", "text-danger")
  }
}
