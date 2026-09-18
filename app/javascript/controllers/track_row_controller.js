import { Controller } from "@hotwired/stimulus"

// A row in the catalogue.
//
// It owns no audio: it asks the one player to play, then reflects whatever the
// player reports. That keeps a single source of truth for "what is playing" even
// though Turbo replaces this markup on every navigation.
export default class extends Controller {
  static targets = [ "button", "trace" ]
  static values = {
    id: Number,
    url: String,
    title: String,
    subtitle: String,
    artwork: String,
    duration: Number,
    downloadable: Boolean,
    download: String
  }

  connect() {
    this.onState = (event) => this.reflect(event.detail)
    this.onError = (event) => this.reflect({ id: null, playing: false })

    document.addEventListener("player:state", this.onState)
    document.addEventListener("player:error", this.onError)

    // Deferred for the same reason the player defers its announcement: during
    // connect, sibling controllers are still being set up.
    requestAnimationFrame(() => {
      this.reflect({ id: this.nowPlayingId, playing: this.isPlaying })
    })
  }

  disconnect() {
    document.removeEventListener("player:state", this.onState)
    document.removeEventListener("player:error", this.onError)
  }

  play() {
    document.dispatchEvent(new CustomEvent("player:play", {
      detail: {
        id: this.idValue,
        url: this.urlValue,
        title: this.titleValue,
        subtitle: this.subtitleValue,
        artwork: this.artworkValue || null,
        duration: this.durationValue || 0,
        downloadable: this.downloadableValue,
        download: this.downloadValue || null
      }
    }))
  }

  reflect({ id, playing }) {
    const mine = id != null && Number(id) === this.idValue
    const live = mine && playing

    this.element.dataset.playing = live ? "true" : "false"

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-pressed", live ? "true" : "false")
      this.buttonTarget.setAttribute("aria-label", live ? `Pause ${this.titleValue}` : `Play ${this.titleValue}`)
    }
  }

  get nowPlayingId() {
    const value = document.documentElement.dataset.nowPlaying
    return value ? Number(value) : null
  }

  get isPlaying() {
    return document.documentElement.dataset.playerState === "playing"
  }
}
