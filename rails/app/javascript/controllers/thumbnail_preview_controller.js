import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "image", "title"]

  open(event) {
    event.preventDefault()

    const trigger = event.currentTarget
    const url = trigger.dataset.thumbnailUrl
    if (!url) return

    this.imageTarget.src = url
    this.imageTarget.alt = trigger.dataset.thumbnailAlt || ""
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = trigger.dataset.thumbnailTitle || ""
    }

    window.bootstrap.Modal.getOrCreateInstance(this.modalTarget).show()
  }
}
