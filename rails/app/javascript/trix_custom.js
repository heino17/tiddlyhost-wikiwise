import { Trix } from "trix"

// Custom Toolbar für alle Editoren
document.addEventListener("trix-initialize", function(event) {
  const editor = event.target;
  // Toolbar bereits korrekt verknüpft
  console.log("Trix ready:", editor.toolbarElement);
});