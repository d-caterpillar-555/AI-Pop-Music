import { Controller } from "@hotwired/stimulus"

// Mounts the band room and wires the controls to it.
//
// Scene construction is deferred by one frame for the same reason the guitar
// viewer does it: a WebGL context created during connect is synchronous DOM work
// inside Stimulus's own lifecycle, and that is what killed the audio player.
//
// Note on imports: stimulus-loading registers every controller as a dynamic
// import, and a static `import X from "scenes/..."` inside a controller makes
// the bundler emit chunk requests the dev server never mapped (the dead /_/*.js
// 404s). Importing lazily inside connect() keeps the graph inside importmap
// pins, which is how the sibling guitar controller already works.
export default class extends Controller {
  static targets = [ "canvas", "readout", "status", "groove" ]
  static values = { url: String }

  async connect() {
    // Captured before the await: if the controller disconnects while the
    // scene modules are still loading (a Turbo navigation mid-import), the
    // scope is torn down and touching this.canvasTarget afterwards throws
    // "Missing target element", which Stimulus swallows into a missing
    // controller with no error anywhere.
    const canvas = this.canvasTarget
    const url = this.urlValue
    const [{ default: BandRoom }, { default: RoomAudio }] = await Promise.all([
      import("scenes/band_room"),
      import("scenes/room_audio")
    ])
    this.audio = new RoomAudio()

    requestAnimationFrame(() => {
      this.scene = new BandRoom(canvas, url, this.audio)

      this.onHover = (event) => this.describe(event.detail)
      this.onPlay = (event) => this.describe(event.detail)
      this.onReady = (event) => {
        if (this.hasStatusTarget) {
          this.statusTarget.textContent = `${event.detail.instruments} instruments, all playable`
        }
      }

      this.element.addEventListener("room:hover", this.onHover)
      this.element.addEventListener("room:play", this.onPlay)
      this.element.addEventListener("room:ready", this.onReady)
    })
  }

  describe(detail) {
    if (!this.hasReadoutTarget) return

    if (!detail) {
      this.readoutTarget.textContent = "Nine instruments. Click one."
      return
    }

    this.readoutTarget.textContent = `${detail.label} — ${detail.blurb}`
  }

  // One button per instrument, so the room is usable without finding a small
  // object in a 3D view on a touch screen.
  instrument(event) {
    this.scene?.playStation(event.params.name)
  }

  groove() {
    const playing = this.audio.groove()

    if (this.hasGrooveTarget) {
      this.grooveTarget.textContent = playing === false ? "The room plays" : "Stop the room"
      this.grooveTarget.setAttribute("aria-pressed", playing === false ? "false" : "true")
    }
  }

  disconnect() {
    this.element.removeEventListener("room:hover", this.onHover)
    this.element.removeEventListener("room:play", this.onPlay)
    this.element.removeEventListener("room:ready", this.onReady)
    this.audio?.stopGroove()
    this.scene?.dispose()
    this.scene = null
  }
}
