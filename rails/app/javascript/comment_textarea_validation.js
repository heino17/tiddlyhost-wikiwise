// Kommentar-Formular: Submit-Button nur aktivieren, wenn Text drin ist
document.addEventListener('turbo:load', setupCommentFormValidation);
document.addEventListener('turbo:render', setupCommentFormValidation);

function setupCommentFormValidation() {
  console.log("setupCommentFormValidation wurde aufgerufen!"); // ← Debug 1

  const forms = document.querySelectorAll('form[data-turbo="true"]');
  console.log("Gefundene Formulare:", forms.length); // ← Debug 2

  forms.forEach(form => {
    const textarea = form.querySelector('.comment-body-input');
    const submitBtn = form.querySelector('.comment-submit-btn');

    if (!textarea || !submitBtn) {
      console.log("Textarea oder Button nicht gefunden in diesem Formular");
      return;
    }

    console.log("Textarea und Button gefunden – starte Check"); // ← Debug 3

    const checkInput = () => {
      const hasText = textarea.value.trim().length > 0;
      console.log("Text vorhanden?", hasText, "Wert:", textarea.value.trim());
      submitBtn.disabled = !hasText;
    };

    // Sofort prüfen
    checkInput();

    // Bei Input prüfen
    textarea.addEventListener('input', () => {
      console.log("Input-Event gefeuert");
      checkInput();
    });
  });
}