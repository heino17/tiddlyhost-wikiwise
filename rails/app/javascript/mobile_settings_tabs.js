document.addEventListener("turbo:load", () => {
  const dropdown = document.getElementById("mobile-settings-tabs");
  const desktopTabs = document.querySelectorAll("#settingsTabs .nav-link");

  if (!dropdown || desktopTabs.length === 0) return;

  // Aktiven Tab aus Bootstrap ermitteln
  const activeDesktopTab = document.querySelector("#settingsTabs .nav-link.active");
  if (activeDesktopTab) {
    const activeName = activeDesktopTab.dataset.tabName;
    if (activeName) {
      dropdown.value = activeName;
    }
  }

  // Wenn im Dropdown gewechselt wird → Bootstrap-Tab aktivieren
  dropdown.addEventListener("change", (e) => {
    const targetName = e.target.value;
    const targetTab = document.querySelector(`#settingsTabs .nav-link[data-tab-name="${targetName}"]`);

    if (targetTab) {
      targetTab.click(); // Bootstrap kümmert sich um Tabwechsel
    }
  });

  // Wenn Desktop-Tab geklickt wird → Dropdown synchronisieren
  desktopTabs.forEach((tab) => {
    tab.addEventListener("shown.bs.tab", (e) => {
      const newTabName = e.target.dataset.tabName;
      if (newTabName) {
        dropdown.value = newTabName;
      }
    });
  });
});
