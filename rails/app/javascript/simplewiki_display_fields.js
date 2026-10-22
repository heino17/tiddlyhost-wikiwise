// Display name and subtitle only apply to SimpleWiki.
// On the create form the wiki type can still be changed, so the fields are
// shown or hidden depending on which type is currently selected.
// See also app/views/sites/_simplewiki_display_fields.html.haml
//
function initSimplewikiDisplayFields(container = document) {
  const fields = container.querySelector(".js-simplewiki-display-fields");
  if (!fields) return;

  // Only the create form can change the type, so only there we need to
  // toggle the fields. For existing sites the server decides.
  if (fields.dataset.simplewikiToggleable !== "true") return;

  const radios = container.querySelectorAll('.type-chooser input[name="site[empty_id]"]');
  if (!radios.length) return;

  const toggle = () => {
    const selected = container.querySelector('.type-chooser input[name="site[empty_id]"]:checked');
    const isSimplewiki = selected && selected.dataset.simplewiki === "true";

    fields.classList.toggle("simplewiki-fields-hidden", !isSimplewiki);

    // Don't submit values for fields that don't apply
    fields.querySelectorAll(".js-simplewiki-display-field").forEach((input) => {
      input.disabled = !isSimplewiki;
    });
  };

  radios.forEach((radio) => radio.addEventListener("change", toggle));
  toggle();
}

document.addEventListener("turbo:load", () => initSimplewikiDisplayFields());

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => initSimplewikiDisplayFields());
} else {
  initSimplewikiDisplayFields();
}
