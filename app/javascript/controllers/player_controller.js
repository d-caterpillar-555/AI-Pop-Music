import { Controller } from "@hotwired/stimulus"

// The listening room's engine.
//
// One <audio> element for the whole site, marked data-turbo-permanent so it
// survives navigation: a track keeps playing while you browse, which is the
// difference between a catalogue and a record shop.
//
// Everything visual here is driven by the real analyser. There is no decorative
// waveform: if nothing is playing, the trace is a flat resting line, because a
// fake bar moving to imaginary audio would be a lie about what you are hearing.
//
// Rows talk to this controller by dispatching events on document, and listen for
// `player:state` to reflect it. That keeps the player decoupled from markup that
// Turbo replaces on every navigation.
export default class extends Controller {
  static targets = [
    "bar", "ambient", "title", "subtitle", "artwork",
    "seek", "seekFill", "elapsed", "playButton", "download"
  ]

  connect() {
    this.context = null
    this.analyser = null
    this.source = null
    this.frequency = null
    this.frame = null
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)")

    // The audio element is permanent across navigation, so IT - not this
    // controller instance - is the source of truth about what is playing. Turbo
    // builds a new controller on every page; each one adopts whatever the
    // element already holds, and playback continues uninterrupted.
    this.current = this.rememberedTrack
    this.adoptGraph()

    this.listen()

    // Deferred by one frame, and this is load-bearing.
    //
    // Stimulus connects a controller as soon as its module definition finishes
    // loading, which can happen after scopes already exist. In that path the
    // scope is not attached yet, and touching ANY target (this.barTarget, and so
    // on) throws "Cannot read properties of undefined (reading 'targets')"
    // inside Stimulus. Doing the DOM work on the next frame is always safe.
    requestAnimationFrame(() => {
      this.render()
      this.announce()
    })
  }

  get rememberedTrack() {
    try {
      return JSON.parse(this.audio.dataset.track || "null")
    } catch {
      return null
    }
  }

  remember(track) {
    if (track) this.audio.dataset.track = JSON.stringify(track)
    else delete this.audio.dataset.track
  }

  // createMediaElementSource may only be called once per element, for that
  // element's whole lifetime - which now outlives this controller. The graph
  // therefore lives on the element and is adopted, never rebuilt.
  adoptGraph() {
    const existing = this.audio.__apmGraph

    if (!existing) return this.buildGraph()

    this.context = existing.context
    this.analyser = existing.analyser
    this.source = existing.source
    this.frequency = new Uint8Array(this.analyser.frequencyBinCount)
  }

  // THE trick that makes a persistent player work under Turbo.
  //
  // Turbo replaces <body> on every navigation, so anything in the markup dies
  // with it - which would stop the music. An element attached directly to
  // <html> is outside Turbo's swap, so it survives. Creating it here, rather
  // than in the layout, also means Stimulus never has to share ownership of it
  // with Turbo, which is the conflict that breaks a naive permanent player.
  get audio() {
    if (this._audio?.isConnected) return this._audio

    let element = document.documentElement.querySelector("audio[data-apm-player]")

    if (!element) {
      element = document.createElement("audio")
      element.setAttribute("data-apm-player", "")
      element.preload = "none"
      document.documentElement.appendChild(element)
    }

    this._audio = element
    return element
  }

  disconnect() {
    this.stopFrame()

    if (!this.handlers) return

    const handlers = this.handlers

    document.removeEventListener("player:play", handlers.play)
    document.removeEventListener("player:toggle", handlers.toggle)
    document.removeEventListener("player:seek", handlers.seek)
    document.removeEventListener("player:request-state", handlers.state)
    document.removeEventListener("turbo:load", handlers.state)
    document.removeEventListener("keydown", handlers.keydown)
    document.removeEventListener("visibilitychange", handlers.visibility)

    // Use the element we actually attached to, never the getter: a disconnect
    // must not create an audio element as a side effect.
    const audio = this._audio
    if (!audio) return

    audio.removeEventListener("timeupdate", handlers.timeupdate)
    audio.removeEventListener("loadedmetadata", handlers.loadedmetadata)
    audio.removeEventListener("play", handlers.audioPlay)
    audio.removeEventListener("pause", handlers.audioPause)
    audio.removeEventListener("ended", handlers.ended)
    audio.removeEventListener("error", handlers.error)
  }

  listen() {
    this.handlers = {
      play: (event) => this.play(event.detail),
      toggle: () => this.toggle(),
      seek: (event) => this.seekTo(event.detail.ratio),
      state: () => this.announce(),
      keydown: (event) => this.keydown(event),
      visibility: () => this.visibility(),
      timeupdate: () => this.renderProgress(),
      loadedmetadata: () => this.renderProgress(),
      audioPlay: () => { this.render(); this.announce(); this.startFrame() },
      audioPause: () => { this.render(); this.announce(); this.stopFrame() },
      ended: () => this.finish(),
      error: () => this.fail()
    }

    const handlers = this.handlers

    document.addEventListener("player:play", handlers.play)
    document.addEventListener("player:toggle", handlers.toggle)
    document.addEventListener("player:seek", handlers.seek)
    document.addEventListener("player:request-state", handlers.state)
    document.addEventListener("turbo:load", handlers.state)
    document.addEventListener("keydown", handlers.keydown)
    document.addEventListener("visibilitychange", handlers.visibility)

    // The audio element outlives this controller, so every one of these has a
    // matching removal in #disconnect. Without that, each navigation would add
    // another set of handlers to the same element.
    const audio = this.audio
    audio.addEventListener("timeupdate", handlers.timeupdate)
    audio.addEventListener("loadedmetadata", handlers.loadedmetadata)
    audio.addEventListener("play", handlers.audioPlay)
    audio.addEventListener("pause", handlers.audioPause)
    audio.addEventListener("ended", handlers.ended)
    audio.addEventListener("error", handlers.error)
  }

  visibility() {
    if (document.hidden) this.stopFrame()
    else if (this.playing) this.startFrame()
  }

  // Space toggles playback the way a player should, unless you are typing or
  // focused on a control that already handles it.
  keydown(event) {
    if (event.key !== " " || event.metaKey || event.ctrlKey || event.altKey) return

    const tag = document.activeElement?.tagName
    if ([ "INPUT", "TEXTAREA", "SELECT", "BUTTON", "A" ].includes(tag)) return
    if (!this.current) return

    event.preventDefault()
    this.toggle()
  }

  // --- Commands ------------------------------------------------------------

  play(track) {
    if (this.current?.id === track.id) return this.toggle()

    this.current = track
    this.remember(track)
    this.audio.src = track.url
    this.buildGraph()

    this.audio.play().catch(() => this.fail())
    this.setMediaSession()
  }

  toggle() {
    if (!this.current) return
    if (this.audio.paused) this.audio.play().catch(() => this.fail())
    else this.audio.pause()
  }

  seekTo(ratio) {
    if (!this.audio.duration) return
    this.audio.currentTime = Math.min(Math.max(ratio, 0), 1) * this.audio.duration
  }

  // Clicking or tapping the progress line seeks there.
  scrub(event) {
    const rect = event.currentTarget.getBoundingClientRect()
    this.seekTo((event.clientX - rect.left) / rect.width)
    this.renderProgress()
  }

  seekBy(seconds) {
    if (!this.audio.duration) return
    this.audio.currentTime = Math.min(Math.max(this.audio.currentTime + seconds, 0), this.audio.duration)
  }

  nudge(event) {
    if (!this.audio.duration) return

    const ratio = this.audio.currentTime / this.audio.duration
    const step = event.key === "ArrowRight" ? 5 / this.audio.duration : -5 / this.audio.duration
    const next = Math.min(Math.max(ratio + step, 0), 1)

    this.seekTo(next)
    this.renderProgress()
  }

  get playing() { return Boolean(this.current) && !this.audio.paused }

  // --- The audio graph -----------------------------------------------------

  // Created on the first play, because browsers only allow an AudioContext to
  // start inside a user gesture. The source node may be created once per element
  // for the lifetime of the page, so this is guarded rather than idempotent.
  buildGraph() {
    if (this.audio.__apmGraph) return

    const Context = window.AudioContext || window.webkitAudioContext
    if (!Context) return

    this.context = new Context()
    this.source = this.context.createMediaElementSource(this.audio)
    this.analyser = this.context.createAnalyser()
    this.analyser.fftSize = 2048
    this.analyser.smoothingTimeConstant = 0.82
    this.frequency = new Uint8Array(this.analyser.frequencyBinCount)

    this.source.connect(this.analyser)
    this.analyser.connect(this.context.destination)

    // Parked on the element, which outlives every controller instance.
    this.audio.__apmGraph = { context: this.context, analyser: this.analyser, source: this.source }
  }

  // --- Painting ------------------------------------------------------------

  startFrame() {
    if (this.frame) return

    const paint = () => {
      this.frame = requestAnimationFrame(paint)
      this.paint()
    }

    this.frame = requestAnimationFrame(paint)
  }

  stopFrame() {
    if (!this.frame) return

    cancelAnimationFrame(this.frame)
    this.frame = null
    this.paint()
  }

  paint() {
    const spectrum = this.spectrum()

    this.paintTraces(spectrum)
    this.paintAmbient(spectrum)
  }

  spectrum() {
    if (!this.analyser || !this.playing) return null

    this.analyser.getByteFrequencyData(this.frequency)
    return this.frequency
  }

  // Every trace on the page is painted from the same analyser, but only the row
  // that is actually playing gets real data - the others rest.
  paintTraces(spectrum) {
    document.querySelectorAll("[data-trace]").forEach((canvas) => {
      // The player bar's own trace has no track id: it follows whatever is
      // playing. A row's trace only comes alive when that row is the one.
      const id = canvas.dataset.trackId
      const follows = id === undefined || id === ""
      const live = spectrum && (follows || id.toString() === this.current?.id?.toString())

      this.paintTrace(canvas, live ? spectrum : null)
    })
  }

  paintTrace(canvas, spectrum) {
    const ratio = window.devicePixelRatio || 1
    const width = canvas.clientWidth
    const height = canvas.clientHeight
    if (!width || !height) return

    if (canvas.width !== width * ratio || canvas.height !== height * ratio) {
      canvas.width = width * ratio
      canvas.height = height * ratio
    }

    const ctx = canvas.getContext("2d")
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0)
    ctx.clearRect(0, 0, width, height)

    const baseline = height - 1

    if (!spectrum) {
      ctx.fillStyle = "rgba(255,255,255,0.14)"
      ctx.fillRect(0, baseline - 1, width, 1)
      return
    }

    // 48 bars across the audible range; the top two thirds of the FFT are mostly
    // empty air and would make the trace look lifeless.
    const bars = Math.max(24, Math.floor(width / 4))
    const usable = Math.floor(spectrum.length * 0.62)
    const gap = 2
    const barWidth = Math.max(1.5, width / bars - gap)

    for (let i = 0; i < bars; i++) {
      const sample = Math.floor((i / bars) * usable)
      const value = spectrum[sample] / 255
      const barHeight = Math.max(2, value * value * height)

      const hue = 68 + (i / bars) * 200
      ctx.fillStyle = `hsl(${hue} 90% ${52 + value * 18}%)`
      ctx.fillRect(i * (barWidth + gap), baseline - barHeight, barWidth, barHeight)
    }
  }

  // The room lighting: three soft pools whose brightness follows the low, mid
  // and high bands, so the page breathes with the track instead of glowing for
  // no reason.
  paintAmbient(spectrum) {
    if (!this.hasAmbientTarget) return

    const canvas = this.ambientTarget
    const ratio = window.devicePixelRatio || 1
    const width = canvas.clientWidth
    const height = canvas.clientHeight
    if (!width || !height) return

    if (canvas.width !== width * ratio || canvas.height !== height * ratio) {
      canvas.width = width * ratio
      canvas.height = height * ratio
    }

    const ctx = canvas.getContext("2d")
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0)
    ctx.clearRect(0, 0, width, height)

    const energy = spectrum ? this.bands(spectrum) : { low: 0, mid: 0, high: 0 }
    const pools = [
      { x: 0.22, y: 0.3, hue: 68, level: energy.low },
      { x: 0.74, y: 0.24, hue: 190, level: energy.mid },
      { x: 0.5, y: 0.72, hue: 285, level: energy.high }
    ]

    pools.forEach((pool) => {
      const alpha = 0.05 + pool.level * 0.16
      const radius = Math.max(width, height) * (0.34 + pool.level * 0.22)
      const gradient = ctx.createRadialGradient(
        width * pool.x, height * pool.y, 0,
        width * pool.x, height * pool.y, radius
      )

      gradient.addColorStop(0, `hsl(${pool.hue} 90% 55% / ${alpha})`)
      gradient.addColorStop(1, "transparent")

      ctx.fillStyle = gradient
      ctx.fillRect(0, 0, width, height)
    })
  }

  bands(spectrum) {
    const average = (from, to) => {
      let total = 0
      for (let i = from; i < to; i++) total += spectrum[i]
      return total / (to - from) / 255
    }

    const third = Math.floor(spectrum.length / 3)
    return { low: average(0, third), mid: average(third, third * 2), high: average(third * 2, spectrum.length) }
  }

  // --- Chrome --------------------------------------------------------------

  render() {
    const playing = this.playing

    // `barTarget`, not `bar`: Stimulus accessors are <name>Target, and using the
    // bare name silently yields undefined until something touches it.
    this.barTarget.classList.toggle("translate-y-full", !this.current)
    this.barTarget.dataset.state = this.current ? (playing ? "playing" : "paused") : "idle"

    if (this.hasTitleTarget) this.titleTarget.textContent = this.current?.title || ""
    if (this.hasSubtitleTarget) this.subtitleTarget.textContent = this.current?.subtitle || ""
    if (this.hasArtworkTarget) {
      this.artworkTarget.src = this.current?.artwork || ""
      this.artworkTarget.classList.toggle("hidden", !this.current?.artwork)
    }
    if (this.hasDownloadTarget) {
      this.downloadTarget.classList.toggle("hidden", !this.current?.downloadable)
      if (this.current?.download) this.downloadTarget.action = this.current.download
    }

    this.playButtonTarget.setAttribute("aria-pressed", playing ? "true" : "false")
    this.playButtonTarget.setAttribute("aria-label", playing ? "Pause" : "Play")
    this.playButtonTarget.disabled = !this.current

    const playIcon = this.playButtonTarget.querySelector(".player-icon-play")
    const pauseIcon = this.playButtonTarget.querySelector(".player-icon-pause")
    if (playIcon && pauseIcon) {
      playIcon.classList.toggle("hidden", playing)
      pauseIcon.classList.toggle("hidden", !playing)
    }
  }

  renderProgress() {
    const duration = this.audio.duration
    const ratio = duration ? this.audio.currentTime / duration : 0

    if (this.hasSeekFillTarget) this.seekFillTarget.style.transform = `scaleX(${ratio})`
    if (this.hasElapsedTarget) this.elapsedTarget.textContent = this.clock(this.audio.currentTime)
    if (this.hasSeekTarget) this.seekTarget.setAttribute("aria-valuenow", Math.round(ratio * 100))
  }

  clock(seconds) {
    if (!Number.isFinite(seconds)) return "0:00"
    const total = Math.floor(seconds)
    return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`
  }

  announce() {
    // Published on the document element, not just as an event: a row that Turbo
    // renders later can read the current state on connect instead of asking for
    // it, which keeps a page of rows from dispatching a request each.
    document.documentElement.dataset.nowPlaying = this.current?.id ?? ""
    document.documentElement.dataset.playerState = this.playing ? "playing" : "paused"

    document.dispatchEvent(new CustomEvent("player:state", {
      detail: {
        id: this.current?.id ?? null,
        playing: this.playing,
        time: this.audio.currentTime,
        duration: this.audio.duration || this.current?.duration || 0
      }
    }))
  }

  finish() {
    this.announce()
    this.stopFrame()
    this.render()
  }

  fail() {
    document.dispatchEvent(new CustomEvent("player:error", { detail: { id: this.current?.id } }))
    this.current = null
    this.remember(null)
    this.render()
    this.announce()
  }

  // OS-level media keys and lock-screen controls, for free.
  setMediaSession() {
    if (!("mediaSession" in navigator) || !this.current) return

    navigator.mediaSession.metadata = new MediaMetadata({
      title: this.current.title,
      artist: this.current.subtitle || "AI Pop Music",
      album: "AI Pop Music",
      artwork: this.current.artwork ? [{ src: this.current.artwork, sizes: "512x512", type: "image/jpeg" }] : []
    })

    navigator.mediaSession.setActionHandler("play", () => this.audio.play())
    navigator.mediaSession.setActionHandler("pause", () => this.audio.pause())
    navigator.mediaSession.setActionHandler("seekbackward", () => this.seekBy(-5))
    navigator.mediaSession.setActionHandler("seekforward", () => this.seekBy(5))
  }
}
