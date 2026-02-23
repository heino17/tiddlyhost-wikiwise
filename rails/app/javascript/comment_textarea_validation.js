// app/javascript/comment_counter.js

function initCommentCounter(container = document) {
  container.querySelectorAll('.comment-body-input').forEach(textarea => {
    // Vermeide doppelte Listener (wichtig bei Turbo!)
    if (textarea.dataset.counterInitialized) return;
    textarea.dataset.counterInitialized = 'true';

    const form = textarea.closest('form');
    if (!form) return;

    const progressBar = form.querySelector('#comment-progress-bar');
    const countDisplay = form.querySelector('#current-count');

    if (!progressBar || !countDisplay) return;

    const MAX = 1500;

    function updateCounter() {
      const len = textarea.value.length;
      const percent = Math.min((len / MAX) * 100, 100); // nicht über 100%

      progressBar.style.width = `${percent}%`;

      if (len < 769) {
        progressBar.className = 'progress-bar bg-success';
      } else if (len < 1107) {
        progressBar.className = 'progress-bar bg-warning';
      } else {
        progressBar.className = 'progress-bar bg-danger';
      }

      countDisplay.textContent = `${len} / ${MAX}`;
      countDisplay.className = len > MAX * 0.95 ? 'text-danger fw-bold' : 'text-muted';
    }

    textarea.addEventListener('input', updateCounter);
    updateCounter(); // Sofort initialisieren
  });
}

// Initial beim Laden
document.addEventListener('turbo:load', () => initCommentCounter());

// Bei jedem Turbo-Update (Frame, Stream, etc.)
document.addEventListener('turbo:render', (event) => {
  // event.detail.newBody ist der neu gerenderte Teil – aber meist reicht document
  initCommentCounter(document);
  // Oder genauer: initCommentCounter(event.target);  // ← oft besser
});