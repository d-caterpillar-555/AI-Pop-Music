import { Controller } from "@hotwired/stimulus"

// Mounts (c) and wires the transport under it.
//
// The peaks arrive as Stimulus array values, which are JSON in the attribute:
// 512 numbers per track, no request and no decode, so the drawing exists before
// anything is played. Every track on the page shares one canvas and one audio
// element - a WebGL context per track would run the browser out of them.
//
// The scene is imported lazily, for the same reason as the room controller: a
// static `import Visualiser from "scenes/visualiser"` makes the bundler emit
// chunk requests the dev server never mapped.
export default class extends Controller {
  static targets = [ "canvas", "play", "scrub", "readout", "picker" ]
  static values = { peaks: Array, url: String, seed: Number, title: String, tracks: Array }

  async connect() {
    this.index = 0
    const { default: Visualiser } = await import("scenes/visualiser")

    requestAnimationFrame(() => {
      this.scene = new Visualiser(this.canvasTarget, {
        peaks: this.peaksValue,
        url: this.hasUrlValue ? this.urlValue : null,
        seed: this.seedValue || 1
      })

      this.onState = (event) => this.state(event.detail.playing)
      this.canvasTarget.addEventListener("visualiser:state", this.onState)
      this.state(false)
    })
  }

  choose(event) {
    const index = Number(event.params.index)
    const track = this.tracksValue[index]
    if (!track || index === this.index) return

    this.index = index
    this.titleValue = track.title
    this.scene?.load(track)

    this.pickerTargets.forEach((button) => {
      const active = Number(button.dataset.visualiserIndexParam) === index
      button.classList.toggle("chip-accent", active)
      button.setAttribute("aria-pressed", active ? "true" : "false")
    })

    this.state(false)
  }

  async toggle(event) {
    event.preventDefault()
    if (!this.scene) return

    const playing = this.scene.element?.paused ?? false
    if (playing) await this.scene.play()
    else this.scene.pause()
  }

  scrub(event) {
    this.scene?.seek(Number(event.target.value) / 1000)
  }

  state(playing) {
    if (this.hasPlayTarget) {
      this.playTarget.textContent = playing ? "Pause" : "Play the shape"
      this.playTarget.setAttribute("aria-pressed", playing ? "true" : "false")
    }

    if (this.hasReadoutTarget) {
      this.readoutTarget.textContent = playing
        ? `${this.titleValue} — the front rank is live`
        : `${this.titleValue} — drawn from ${this.peaksValue.length} stored measurements`
    }
  }

  disconnect() {
    this.canvasTarget.removeEventListener("visualiser:state", this.onState)
    this.scene?.dispose()
    this.scene = null
  }
}
