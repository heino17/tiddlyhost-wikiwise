import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["textarea", "progressBar", "countDisplay"];

  connect() {
    this.MAX = 1500;
    this.updateCounter();
    this.textareaTarget.addEventListener('input', this.updateCounter.bind(this));
  }

  disconnect() {
    this.textareaTarget.removeEventListener('input', this.updateCounter.bind(this));
  }

  updateCounter() {
    const len = this.textareaTarget.value.length;
    const percent = (len / this.MAX) * 100;

    this.progressBarTarget.style.width = `${percent}%`;

    if (len < 769) {
      this.progressBarTarget.className = 'progress-bar bg-success';
    } else if (len < 1107) {
      this.progressBarTarget.className = 'progress-bar bg-warning';
    } else {
      this.progressBarTarget.className = 'progress-bar bg-danger';
    }

    this.countDisplayTarget.textContent = `${len} / ${this.MAX}`;
    this.countDisplayTarget.className = len > this.MAX * 0.95 ? 'text-danger' : 'text-muted';
  }
}