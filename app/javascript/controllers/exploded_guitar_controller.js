import { Controller } from "@hotwired/stimulus"


// Mounts the exploded guitar and wires the "take it apart" control to it.
//
// WebGL work is deferred to the next frame: creating a renderer during connect
// is exactly the kind of synchronous DOM work that has bitten the player
// controller, and it is never worth risking a dead canvas.
export default class extends Controller {
  static targets = [ "canvas", "slider", "readout" ]
  static values = { url: String }

  async connect() {
    const { default: ExplodedGuitar } = await import("scenes/exploded_guitar")
    requestAnimationFrame(() => {
      this.scene = new ExplodedGuitar(this.canvasTarget, this.urlValue)

      if (this.hasSliderTarget) {
        this.scene.setExplode(this.sliderTarget.value / 100)
        this.readout()
      }
    })
  }

  explode(event) {
    this.scene?.setExplode(event.target.value / 100)
    this.readout()
  }

  // Assembled, half apart, or fully exploded - the label should say what the
  // number means, not print a percentage at someone.
  readout() {
    if (!this.hasReadoutTarget || !this.hasSliderTarget) return

    const value = Number(this.sliderTarget.value)
    const label = value < 12 ? "Assembled" : value < 60 ? "Opening" : value < 92 ? "Apart" : "Fully exploded"

    this.readoutTarget.textContent = label
  }

  disconnect() {
    this.scene?.dispose()
    this.scene = null
  }
}
