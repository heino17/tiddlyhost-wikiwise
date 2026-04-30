document.addEventListener("turbo:load", () => {
  document.querySelectorAll(".flash-persistent[data-flash_persistent]").forEach(alert => {
    // Einblenden (Slide-Down)
    setTimeout(() => {
      alert.classList.add("showing");
    }, 40);

    // Auto-Dismiss (optional)
    const auto = alert.dataset.auto_dismiss === "true";
    if (auto) {
      setTimeout(() => {
        closeAlert(alert);
      }, 3000);
    }
  });

  // Schließen per Klick
  document.addEventListener("click", (e) => {
    const closeBtn = e.target.closest(".flash-persistent .btn-close");
    if (!closeBtn) return;

    const alert = closeBtn.closest(".flash-persistent");
    if (!alert) return;

    e.preventDefault();
    closeAlert(alert);
  });
});

function closeAlert(alert) {
  alert.classList.remove("showing");
  alert.classList.add("closing");

  setTimeout(() => {
    alert.remove();
  }, 900);
}
