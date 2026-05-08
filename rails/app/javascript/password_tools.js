document.addEventListener("DOMContentLoaded", () => {
  const genBtn = document.querySelector("[data-password-generator]");
  const pwField = document.querySelector("#user_password");
  const pwConfField = document.querySelector("#user_password_confirmation");
  const plain = document.querySelector("[data-password-plain]");
  const strength = document.querySelector("[data-password-strength]");

  // Passwort generieren
  if (genBtn) {
    genBtn.addEventListener("click", (e) => {
      e.preventDefault();

      const password = generatePassword(16);

      if (pwField) pwField.value = password;
      if (pwConfField) pwConfField.value = password;

      // Stärke neu berechnen
      pwField.dispatchEvent(new Event("input"));

      // Klartext anzeigen
      if (plain) plain.textContent = password;
    });
  }

  // Klartext beim Tippen aktualisieren
  if (pwField && plain) {
    pwField.addEventListener("input", () => {
      plain.textContent = pwField.value;
    });
  }

  // Stärke-Anzeige beim Tippen
  if (pwField && strength) {
    pwField.addEventListener("input", () => {
      const score = passwordStrength(pwField.value);
      updateStrengthIndicator(strength, score);
    });
  }
});

function generatePassword(length) {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%&*?";
  let pw = "";
  for (let i = 0; i < length; i++) {
    pw += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return pw;
}

document.addEventListener("DOMContentLoaded", () => {
  const pwField = document.querySelector("#user_password");
  const strength = document.querySelector("[data-password-strength]");

  if (pwField && strength) {
    pwField.addEventListener("input", () => {
      const score = passwordStrength(pwField.value);
      updateStrengthIndicator(strength, score);
    });
  }
});

function passwordStrength(pw) {
  let score = 0;
  if (pw.length >= 8) score++;
  if (pw.length >= 12) score++;
  if (/[A-Z]/.test(pw)) score++;
  if (/[a-z]/.test(pw)) score++;
  if (/[0-9]/.test(pw)) score++;
  if (/[^A-Za-z0-9]/.test(pw)) score++;
  return score;
}

function updateStrengthIndicator(el, score) {
  const strengthTexts = JSON.parse(el.dataset.strengthTexts);

  const levels = [
    { key: "0", color: "red" },
    { key: "1", color: "orangered" },
    { key: "2", color: "orange" },
    { key: "3", color: "gold" },
    { key: "4", color: "green" },
    { key: "5", color: "darkgreen" }
  ];

  const level = levels[Math.min(score, levels.length - 1)];

  const valueEl = el.querySelector("[data-password-strength-value]");
  if (valueEl) {
    valueEl.textContent = strengthTexts[level.key];
    valueEl.style.color = level.color;
  }
}
