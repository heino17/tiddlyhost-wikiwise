document.addEventListener("turbo:load", () => {
  const dropdown = document.getElementById("mobile-main-tabs");
  if (!dropdown) return;

  const currentPath = window.location.pathname;

  // Aktiven Tab automatisch auswählen
  for (const option of dropdown.options) {
    try {
      const optionPath = new URL(option.value, window.location.origin).pathname;
      if (optionPath === currentPath) {
        dropdown.value = option.value;
        break;
      }
    } catch (e) {
      // Falls eine Option keine gültige URL ist → ignorieren
    }
  }

  // Navigation bei Auswahl
  dropdown.addEventListener("change", (e) => {
    const url = e.target.value;
    if (url && url.length > 0) {
      window.location.href = url;
    }
  });
});
