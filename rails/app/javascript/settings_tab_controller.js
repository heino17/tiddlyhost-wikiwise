import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.waitForBootstrap()
    this.registerTabClickHandler()
  }

  waitForBootstrap() {
    if (typeof bootstrap !== "undefined" && bootstrap.Tab) {
      this.restoreActiveTab()
    } else {
      setTimeout(() => this.waitForBootstrap(), 50)
    }
  }

  restoreActiveTab() {
    const activeTab = this.element.dataset.activeTab || "general"
    const tabLink = document.querySelector(`#settingsTabs a[data-tab-name="${activeTab}"]`)

    if (tabLink) {
      try {
        const tab = new bootstrap.Tab(tabLink)
        tab.show()
      } catch (e) {
        console.warn("Could not activate tab:", e)
      }
    }
  }

  registerTabClickHandler() {
    document.querySelectorAll('#settingsTabs a[data-tab-name]').forEach(link => {
      link.addEventListener("shown.bs.tab", event => {
        const tabName = event.target.dataset.tabName
        const hiddenField = document.getElementById("active_tab_field")
        if (hiddenField) hiddenField.value = tabName
      })
    })
  }
}
