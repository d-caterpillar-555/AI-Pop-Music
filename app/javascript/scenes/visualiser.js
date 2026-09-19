import * as THREE from "three"

// (c) The song, drawn.
//
// Two layers, deliberately different: the *stored* peaks are the whole song's
// shape, drawn as a landscape of bars receding from the camera, and the *live*
// analyser drives the front rank only. Memory behind, the present in front.
//
// The window of buckets on screen follows playback, so the landscape travels as
// the song does, and a control scrubs it by hand when nothing is playing.

const COLUMNS = 128
const ROWS = 5
const SPACING = 0.085
const ROW_GAP = 0.30

export default class Visualiser {
  constructor(canvas, options) {
    this.canvas = canvas
    this.peaks = options.peaks ?? []
    this.url = options.url
    this.seed = options.seed ?? 1
    this.audio = options.audio

    this.window = 0
    this.targetWindow = 0
    this.visible = true
    this.spin = 0
    this.drag = null

    this.setupScene()
    this.setupAudio()
    this.observe()
    this.animate()
  }

  // A seeded generator, so the same track always draws the same field and two
  // tracks never draw the same one.
  random() {
    this.seed = (this.seed * 1664525 + 1013904223) % 4294967296
    return this.seed / 4294967296
  }

  setupScene() {
    const { clientWidth: w, clientHeight: h } = this.canvas

    this.renderer = new THREE.WebGLRenderer({ canvas: this.canvas, antialias: true, alpha: true })
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    this.renderer.setSize(w, h, false)
    this.renderer.outputColorSpace = THREE.SRGBColorSpace
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping

    this.scene = new THREE.Scene()
    this.scene.fog = new THREE.Fog(0x0a0a0c, 4.2, 11.0)

    this.camera = new THREE.PerspectiveCamera(42, w / h, 0.05, 40)
    this.camera.position.set(0, 1.35, 4.6)
    this.camera.lookAt(0, 0.35, -1.2)

    this.scene.add(new THREE.HemisphereLight(0xffffff, 0x111118, 0.7))

    const key = new THREE.DirectionalLight(0xffffff, 1.1)
    key.position.set(1.6, 3.2, 2.4)
    this.scene.add(key)

    const rim = new THREE.DirectionalLight(0xff8a5c, 0.5)
    rim.position.set(-2.4, 0.8, -3.0)
    this.scene.add(rim)

    this.rig = new THREE.Group()
    this.scene.add(this.rig)

    // One instanced box per bar: 640 bars is nothing to draw, but 640 separate
    // meshes would be 640 draw calls.
    const geometry = new THREE.BoxGeometry(1, 1, 1)
    geometry.translate(0, 0.5, 0)   // grow from the floor rather than the middle

    const material = new THREE.MeshStandardMaterial({
      roughness: 0.42,
      metalness: 0.12,
      vertexColors: false
    })

    this.count = COLUMNS * ROWS
    this.bars = new THREE.InstancedMesh(geometry, material, this.count)
    this.bars.instanceMatrix.setUsage(THREE.DynamicDrawUsage)
    this.bars.frustumCulled = false
    this.bars.instanceColor = new THREE.InstancedBufferAttribute(new Float32Array(this.count * 3), 3)

    // Per-bar character from the seed: a field of identical bars reads as a
    // chart, not as a drawing.
    this.jitter = []
    for (let index = 0; index < this.count; index += 1) {
      this.jitter.push({
        x: (this.random() - 0.5) * SPACING * 0.35,
        width: 0.5 + this.random() * 0.4,
        lift: this.random() * 0.02,
        echo: Math.floor(this.random() * 23)
      })
    }

    this.rig.add(this.bars)
    this.matrix = new THREE.Matrix4()
    this.colour = new THREE.Color()
    this.accent = new THREE.Color(0xd8ff3e)
    this.muted = new THREE.Color(0x6f7280)

    this.buildField()
  }

  // Per-bar character from the seed: a field of identical bars reads as a chart,
  // not as a drawing. Rebuilt whenever the track changes, so two tracks never
  // draw the same field.
  buildField() {
    this.seed = this.originalSeed ?? this.seed
    this.jitter = []
    for (let index = 0; index < this.count; index += 1) {
      this.jitter.push({
        x: (this.random() - 0.5) * SPACING * 0.35,
        width: 0.5 + this.random() * 0.4,
        lift: this.random() * 0.02,
        echo: Math.floor(this.random() * 23)
      })
    }
  }

  // Swap the piece onto another track without rebuilding the WebGL context: one
  // canvas, one audio element, as many songs as the page offers.
  load(track) {
    this.peaks = track.peaks ?? []
    this.originalSeed = track.seed ?? 1
    this.seed = this.originalSeed
    this.window = 0
    this.targetWindow = 0

    this.buildField()
    this.pause()

    if (this.element) {
      this.element.src = track.url
      this.element.load()
    }

    this.dispatchState(false)
  }

  dispatchState(playing) {
    this.canvas.dispatchEvent(new CustomEvent("visualiser:state", {
      bubbles: true,
      detail: { playing }
    }))
  }

  setupAudio() {
    if (this.element) return

    this.element = new Audio()
    this.element.crossOrigin = "anonymous"
    this.element.loop = true
    this.element.preload = "none"
    if (this.url) this.element.src = this.url

    this.element.addEventListener("pause", () => this.dispatchState(false))
    this.element.addEventListener("play", () => this.dispatchState(true))

    // The analyser is created on the first play, because a browser will not let
    // an AudioContext exist before a gesture.
    this.analyserData = null
  }

  connectAnalyser() {
    if (this.analyserData || !this.element) return

    const Context = window.AudioContext || window.webkitAudioContext
    if (!Context) return

    if (!this.audio) this.audio = new Context()
    if (this.audio.state === "suspended") this.audio.resume()

    const source = this.audio.createMediaElementSource(this.element)
    const analyser = this.audio.createAnalyser()
    analyser.fftSize = 512
    analyser.smoothingTimeConstant = 0.72

    source.connect(analyser)
    analyser.connect(this.audio.destination)

    this.analyserData = new Uint8Array(analyser.frequencyBinCount)
    this.analyser = analyser
  }

  async play() {
    if (!this.element) return false

    this.connectAnalyser()
    try {
      await this.element.play()
      return true
    } catch (error) {
      console.error("[visualiser] could not play", error)
      return false
    }
  }

  pause() {
    this.element?.pause()
  }

  seek(ratio) {
    if (!this.element) return

    // Scrubbing by hand moves the drawing even when nothing is playing.
    if (Number.isFinite(this.element.duration)) {
      this.element.currentTime = ratio * this.element.duration
    }
    this.targetWindow = ratio
    this.window = ratio
  }

  observe() {
    this.onResize = () => this.resize()
    window.addEventListener("resize", this.onResize)

    this.onPointerDown = (event) => {
      this.drag = { x: event.clientX, spin: this.spin }
      this.canvas.setPointerCapture?.(event.pointerId)
    }

    this.onPointerMove = (event) => {
      if (!this.drag) return
      this.spin = this.drag.spin + (event.clientX - this.drag.x) * 0.005
    }

    this.onPointerUp = (event) => {
      this.drag = null
      this.canvas.releasePointerCapture?.(event.pointerId)
    }

    this.canvas.addEventListener("pointerdown", this.onPointerDown)
    this.canvas.addEventListener("pointermove", this.onPointerMove)
    this.canvas.addEventListener("pointerup", this.onPointerUp)

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => { this.visible = entry.isIntersecting })
    }, { threshold: 0.01 })

    this.observer.observe(this.canvas)
  }

  // Theme tokens are read from the document rather than hard-coded, so the piece
  // restyles with the rest of the site instead of fighting it.
  readTheme() {
    const styles = getComputedStyle(document.documentElement)
    const accent = styles.getPropertyValue("--color-accent").trim()
    const dim = styles.getPropertyValue("--color-paper-dim").trim() || "#8a8d99"

    if (accent) this.accent.set(accent)
    if (dim) this.muted.set(dim)
  }

  resize() {
    const { clientWidth: w, clientHeight: h } = this.canvas
    if (!w || !h) return

    this.camera.aspect = w / h
    this.camera.updateProjectionMatrix()
    this.renderer.setSize(w, h, false)
  }

  animate() {
    this.frameId = requestAnimationFrame(() => this.animate())
    if (this.visible === false) return

    this.frames = (this.frames ?? 0) + 1
    if (this.frames % 90 === 1) this.readTheme()

    // The drawn window follows the song when it is playing, and the control when
    // it is not.
    if (this.element && !this.element.paused && Number.isFinite(this.element.duration)) {
      this.targetWindow = Math.min(this.element.currentTime / this.element.duration, 0.999)
    }

    this.window += (this.targetWindow - this.window) * 0.08

    if (this.analyser && this.analyserData) this.analyser.getByteFrequencyData(this.analyserData)

    const buckets = this.peaks.length || 1
    const span = Math.max(buckets - COLUMNS, 1)
    const start = Math.floor(this.window * span)

    for (let row = 0; row < ROWS; row += 1) {
      for (let column = 0; column < COLUMNS; column += 1) {
        const index = row * COLUMNS + column
        const shape = this.jitter[index]
        const bucket = (start + column + row * 7 + shape.echo) % buckets
        const stored = this.peaks[bucket] ?? 0

        // Only the front rank hears the room: the rest is the song as it was.
        let live = 0
        if (row === 0 && this.analyserData) {
          const band = this.analyserData[Math.floor((column / COLUMNS) * 96)]
          live = (band / 255) * 0.9
        }

        const height = 0.05 + stored * 0.9 + live * 0.5 + shape.lift

        this.matrix.makeScale(SPACING * shape.width, height, SPACING * shape.width)
        this.matrix.setPosition(
          (column - COLUMNS / 2) * SPACING + shape.x,
          0,
          -row * ROW_GAP
        )
        this.bars.setMatrixAt(index, this.matrix)

        // Depth fades toward the background colour, and the live rank is the
        // only one that gets the accent.
        const depth = row / (ROWS - 1)
        this.colour.copy(this.muted).lerp(this.accent, row === 0 ? 0.85 : 0.42 - depth * 0.35)
        this.colour.multiplyScalar(row === 0 ? 1.0 : 0.85 - depth * 0.45)
        this.bars.setColorAt(index, this.colour)
      }
    }

    this.bars.instanceMatrix.needsUpdate = true
    if (this.bars.instanceColor) this.bars.instanceColor.needsUpdate = true
    this.rig.rotation.y = this.spin

    this.renderer.render(this.scene, this.camera)
  }

  dispose() {
    cancelAnimationFrame(this.frameId)
    this.element?.pause()
    this.observer?.disconnect()
    window.removeEventListener("resize", this.onResize)
    this.canvas.removeEventListener("pointerdown", this.onPointerDown)
    this.canvas.removeEventListener("pointermove", this.onPointerMove)
    this.canvas.removeEventListener("pointerup", this.onPointerUp)
    this.renderer.dispose()
  }
}
