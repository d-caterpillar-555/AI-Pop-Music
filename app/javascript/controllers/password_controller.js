import { Controller } from "@hotwired/stimulus"

// Reveals a typed password.
//
// Passwords are the field people most often mistype, and hiding them by default
// is a convention, not a security control - anyone holding the device can read
// the value out of the DOM either way. The toggle keeps the label and the
// pressed state honest so it is usable with a screen reader.
export default class extends Controller {
  static targets = [ "input", "button" ]

  toggle() {
    const revealed = this.inputTarget.type === "text"

    this.inputTarget.type = revealed ? "password" : "text"
    this.buttonTarget.textContent = revealed ? "Show" : "Hide"
    this.buttonTarget.setAttribute("aria-pressed", revealed ? "false" : "true")
    this.buttonTarget.setAttribute("aria-label", revealed ? "Show password" : "Hide password")

    // Keep the caret where the person was typing.
    this.inputTarget.focus()
  }
}
