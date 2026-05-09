document.addEventListener("click", function (e) {
  if (!e.target.classList.contains("toggle-password")) return;

  const fieldId = e.target.dataset.target;
  const field = document.getElementById(fieldId);

  if (!field) return;

  const showText = e.target.dataset.show;
  const hideText = e.target.dataset.hide;

  if (field.type === "password") {
    field.type = "text";
    e.target.textContent = hideText;
  } else {
    field.type = "password";
    e.target.textContent = showText;
  }
});
// Clear password fields
document.addEventListener("click", function (e) {
  if (e.target.dataset.passwordClear !== undefined) {
    const fields = [
      document.getElementById("user_password"),
      document.getElementById("user_password_confirmation")
    ];

    fields.forEach(f => {
      if (f) f.value = "";
    });
  }
});
