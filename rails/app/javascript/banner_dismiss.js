document.addEventListener("turbo:load", () => {
  document.querySelectorAll(".banner-message[data-banner]").forEach(banner => {
    // Banner einblenden (Slide-Down)
    setTimeout(() => {
      banner.classList.add("showing");
    }, 40);
  });

  // Schließen per Klick
  document.addEventListener("click", (e) => {
    const closeBtn = e.target.closest(".banner-message .btn-close");
    if (!closeBtn) return;

    const banner = closeBtn.closest(".banner-message");
    if (!banner) return;

    e.preventDefault();

    // Animation starten
    banner.classList.remove("showing");
    banner.classList.add("closing");

    // Cookie für 7 Tage setzen
    setBannerDismissedCookie(7);

    // Element nach Animation entfernen
    setTimeout(() => {
      banner.remove();
    }, 800);
  });
});

function setBannerDismissedCookie(days) {
  const expiresDate = new Date();
  expiresDate.setDate(expiresDate.getDate() + days);

  const expires = expiresDate.toUTCString();
  const value = Date.now() + (days * 86400000);

  document.cookie = `banner_dismissed_until=${value}; expires=${expires}; path=/; SameSite=Lax`;
}