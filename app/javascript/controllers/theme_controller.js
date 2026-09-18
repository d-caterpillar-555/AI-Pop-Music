import { Controller } from "@hotwired/stimulus"

// Switches the design direction.
//
// The three directions are three sets of design tokens in application.css, so
// toggling one attribute restyles every page at once. This controller only owns
// the switch itself: the choice, its persistence, and telling assistive tech
// what happened.
//
// The initial value is applied by an inline script in <head>, before first
// paint, so a returning visitor never sees a flash of the default direction.
export default class extends Controller {
  static targets = [ "option", "live" ]
  static values = { storageKey: { type: String, default: "apm:theme" } }

  connect() {
    this.render()
  }

  select(event) {
    const theme = event.currentTarget.dataset.theme
    if (!theme) return

    document.documentElement.dataset.theme = theme

    try {
      window.localStorage.setItem(this.storageKeyValue, theme)
    } catch {
      // Private browsing, or storage disabled: the choice simply does not
      // persist. Not worth breaking the page over.
    }

    this.render()

    if (this.hasLiveTarget) {
      this.liveTarget.textContent = `${this.labelFor(theme)} direction applied`
    }
  }

  render() {
    const current = document.documentElement.dataset.theme || "signal"

    this.optionTargets.forEach((option) => {
      option.setAttribute("aria-pressed", option.dataset.theme === current ? "true" : "false")
    })
  }

  labelFor(theme) {
    return theme.charAt(0).toUpperCase() + theme.slice(1)
  }
}
