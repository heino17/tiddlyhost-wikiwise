// --- Drag-Scroll für alle Tabellen ---
// Wird ausgeführt bei:
// - normalem Seitenladen (turbo:load)
// - jedem Turbo-Frame-Reload (turbo:frame-load)

document.addEventListener("turbo:load", initDragScroll);
document.addEventListener("turbo:frame-load", initDragScroll);

function initDragScroll() {
  const wrappers = document.querySelectorAll(".admin-table-wrapper");
  if (!wrappers.length) return;

  wrappers.forEach((el) => {
    // Verhindert doppelte Listener, falls Turbo mehrfach lädt
    if (el.dataset.dragscrollInitialized === "true") return;
    el.dataset.dragscrollInitialized = "true";

    let isDown = false;
    let lastX = 0;
    let velocity = 0;
    let rafID = null;
    let allowSelect = false;

    const stopMomentum = () => cancelAnimationFrame(rafID);

    const momentum = () => {
      el.scrollLeft -= velocity;
      velocity *= 0.95;
      if (Math.abs(velocity) > 0.5) {
        rafID = requestAnimationFrame(momentum);
      }
    };

    el.addEventListener("mousedown", (e) => {
      allowSelect = e.ctrlKey || e.metaKey;

      if (allowSelect) {
        el.classList.add("allow-select");
        return;
      }

      el.classList.remove("allow-select");

      isDown = true;
      el.classList.add("dragging");
      lastX = e.pageX;
      stopMomentum();
      e.preventDefault();
    });

    el.addEventListener("mousemove", (e) => {
      if (!isDown || allowSelect) return;

      const dx = e.pageX - lastX;
      el.scrollLeft -= dx;
      velocity = dx;
      lastX = e.pageX;
    });

    const endDrag = () => {
      if (!isDown) return;
      isDown = false;
      el.classList.remove("dragging");
      if (Math.abs(velocity) > 1) momentum();
    };

    el.addEventListener("mouseup", endDrag);
    el.addEventListener("mouseleave", endDrag);

    document.addEventListener("keydown", (e) => {
      if (e.ctrlKey || e.metaKey) {
        el.classList.add("allow-select");
      }
    });

    document.addEventListener("keyup", () => {
      el.classList.remove("allow-select");
    });
  });
}
