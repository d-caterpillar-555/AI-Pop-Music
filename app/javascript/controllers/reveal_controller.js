import { Controller } from "@hotwired/stimulus"

// Reveals elements as they enter the viewport, once. Transform and opacity only,
// so it costs no layout, and it stands down entirely when the reader has asked
// for reduced motion.
export default class extends Controller {
  connect() {
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches

    if (this.reduced || !("IntersectionObserver" in window)) {
      this.elements.forEach((element) => element.classList.add("is-visible"))
      return
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return

        entry.target.classList.add("is-visible")
        this.observer.unobserve(entry.target)
      })
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.1 })

    this.elements.forEach((element) => this.observer.observe(element))
  }

  disconnect() {
    this.observer?.disconnect()
  }

  get elements() {
    const marked = Array.from(this.element.querySelectorAll("[data-reveal]"))
    return this.element.hasAttribute("data-reveal") ? [ this.element, ...marked ] : marked
  }
}
