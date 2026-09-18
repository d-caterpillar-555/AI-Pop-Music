import { Controller } from "@hotwired/stimulus"

// A small parallax tilt on artwork, in response to the pointer.
//
// Two rules keep this on the right side of gimmick: it moves the element with
// transforms only (so it never triggers layout), and it switches itself off for
// touch pointers and for readers who asked for reduced motion.
export default class extends Controller {
  static values = { max: { type: Number, default: 7 } }

  connect() {
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.coarse = window.matchMedia("(pointer: coarse)").matches

    if (this.reduced || this.coarse) return

    this.onMove = (event) => this.schedule(event)
    this.onLeave = () => this.settle()

    this.element.addEventListener("pointermove", this.onMove)
    this.element.addEventListener("pointerleave", this.onLeave)
    this.element.style.transformStyle = "preserve-3d"
  }

  disconnect() {
    this.element.removeEventListener("pointermove", this.onMove)
    this.element.removeEventListener("pointerleave", this.onLeave)
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  schedule(event) {
    this.pointer = event
    if (this.frame) return

    this.frame = requestAnimationFrame(() => {
      this.frame = null
      this.apply(this.pointer)
    })
  }

  apply(event) {
    const rect = this.element.getBoundingClientRect()
    const x = (event.clientX - rect.left) / rect.width - 0.5
    const y = (event.clientY - rect.top) / rect.height - 0.5
    const max = this.maxValue

    this.element.style.transform =
      `perspective(900px) rotateY(${(x * max * 2).toFixed(2)}deg) rotateX(${(-y * max * 2).toFixed(2)}deg)`
  }

  settle() {
    if (this.frame) {
      cancelAnimationFrame(this.frame)
      this.frame = null
    }

    this.element.style.transform = "perspective(900px) rotateY(0deg) rotateX(0deg)"
  }
}
