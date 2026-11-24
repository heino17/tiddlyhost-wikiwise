import { Controller } from "@hotwired/stimulus"

// Port of the MultiWikiServer "tap all the animals" login puzzle.
// The board itself comes from the server, so the answer can be checked again
// when the form is submitted.
export default class extends Controller {
  static targets = ["grid", "tile", "feedback", "answer", "token", "submit"]

  connect() {
    this.selected = new Set()
    this.solved = false
    this.errorTimer = null
    this.updateSubmit()
  }

  disconnect() {
    if (this.errorTimer) clearTimeout(this.errorTimer)
  }

  select(event) {
    if (this.solved) return

    const tile = event.currentTarget
    const tileId = tile.dataset.tileId

    if (tile.dataset.animal !== "true") {
      this.showWrong(tile)
      return
    }

    if (this.errorTimer) {
      clearTimeout(this.errorTimer)
      this.errorTimer = null
    }

    if (this.selected.has(tileId)) {
      this.selected.delete(tileId)
    } else {
      this.selected.add(tileId)
    }

    this.updateTiles()

    if (this.selected.size === this.animalCount()) {
      this.markSolved()
    } else {
      this.setFeedback(this.data.get("findText"))
    }
  }

  async refresh() {
    const response = await fetch(this.data.get("newUrl"), {
      headers: { Accept: "application/json" },
    })
    if (!response.ok) return

    const puzzle = await response.json()
    if (this.errorTimer) clearTimeout(this.errorTimer)

    this.tokenTarget.value = puzzle.token
    this.answerTarget.value = ""
    this.selected = new Set()
    this.solved = false
    this.gridTarget.innerHTML = ""

    puzzle.tiles.forEach((tile) => {
      this.gridTarget.appendChild(this.buildTile(tile))
    })

    this.setFeedback(this.data.get("findText"))
    this.updateSubmit()
  }

  buildTile(tile) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "login-puzzle-tile"
    button.setAttribute("aria-pressed", "false")
    button.dataset.action = "login-puzzle#select"
    button.dataset.loginPuzzleTarget = "tile"
    button.dataset.tileId = tile.id
    button.dataset.animal = String(tile.animal)

    const emoji = document.createElement("span")
    emoji.setAttribute("aria-hidden", "true")
    emoji.textContent = tile.emoji
    button.appendChild(emoji)

    return button
  }

  showWrong(tile) {
    tile.classList.add("is-wrong")
    this.element.classList.remove("is-shaking")
    // Force a reflow so the animation restarts on consecutive wrong clicks.
    void this.element.offsetWidth
    this.element.classList.add("is-shaking")
    this.setFeedback(this.data.get("wrongText"))

    if (this.errorTimer) clearTimeout(this.errorTimer)
    this.errorTimer = setTimeout(() => {
      this.selected.clear()
      this.updateTiles()
      tile.classList.remove("is-wrong")
      this.element.classList.remove("is-shaking")
      this.setFeedback(this.data.get("findText"))
      this.errorTimer = null
    }, 700)
  }

  markSolved() {
    this.solved = true
    this.answerTarget.value = [...this.selected].join(",")
    this.updateTiles()
    this.setFeedback(this.data.get("solvedText"))
    this.updateSubmit()
  }

  updateTiles() {
    this.tileTargets.forEach((tile) => {
      const isSelected = this.selected.has(tile.dataset.tileId)
      const isSolved = this.solved && tile.dataset.animal === "true"
      tile.classList.toggle("is-selected", isSelected)
      tile.classList.toggle("is-solved", isSolved)
      tile.setAttribute("aria-pressed", String(isSelected))
    })
  }

  animalCount() {
    return this.tileTargets.filter((tile) => tile.dataset.animal === "true").length
  }

  setFeedback(text) {
    this.feedbackTarget.textContent = text
  }

  updateSubmit() {
    if (this.hasSubmitTarget) this.submitTarget.disabled = !this.solved
  }
}
