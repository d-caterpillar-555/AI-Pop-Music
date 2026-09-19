import * as THREE from "three"
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js"

// (b) The band room, loaded from the model Blender bakes.
//
// The geometry comes from script/blender/room/ - nine instruments arranged as a
// band sets up, exported as one glTF with a node per instrument. Every node is
// clickable and every instrument has a voice (room_audio.js), so the room is
// playable rather than a diorama.

// glTF node name -> what the page calls it and which voice it plays. The
// stations Blender builds are the keys; anything else in the file is scenery.
const INSTRUMENTS = {
  Drums: { label: "Drums", voice: "drums", blurb: "Click to hit them" },
  Elec1: { label: "Electric guitar", voice: "chord", blurb: "A5 power chord" },
  Elec2: { label: "Second electric", voice: "lead", blurb: "Cleaner, higher" },
  Bass: { label: "Bass", voice: "bass", blurb: "Low A" },
  Acoustic: { label: "Acoustic", voice: "acoustic", blurb: "Open G chord" },
  Keys: { label: "Keys", voice: "keys", blurb: "A minor" },
  Amp: { label: "Amp stack", voice: "amp", blurb: "Low E, driven" },
  Mic: { label: "Vocal mic", voice: "voice", blurb: "A held note" },
  Board: { label: "Pedalboard", voice: "pedal", blurb: "Through the delay" }
}

const CAMERA_DIRECTION = new THREE.Vector3(0.72, 0.40, 1.0).normalize()

export default class BandRoom {
  constructor(canvas, url, audio) {
    this.canvas = canvas
    this.url = url
    this.audio = audio
    this.stations = new Map()
    this.pulses = []
    this.pointer = new THREE.Vector2()
    this.drag = null
    this.hovered = null
    this.spin = 0
    this.visible = true

    this.setupScene()
    this.load()
    this.observe()
    this.animate()
  }

  setupScene() {
    const { clientWidth: w, clientHeight: h } = this.canvas

    this.renderer = new THREE.WebGLRenderer({ canvas: this.canvas, antialias: true, alpha: true })
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    this.renderer.setSize(w, h, false)
    this.renderer.outputColorSpace = THREE.SRGBColorSpace
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping
    this.renderer.toneMappingExposure = 1.0
    this.renderer.shadowMap.enabled = true
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap

    this.scene = new THREE.Scene()

    this.camera = new THREE.PerspectiveCamera(38, w / h, 0.05, 120)
    this.camera.position.set(5.2, 3.0, 6.2)
    this.camera.lookAt(0, 0.9, 0)

    // The Blender scene lights itself; the browser starts from nothing, so this
    // is a smaller version of the same idea: a cool window on one side, a warm
    // practical above, and a dim sky so nothing is ever pure black.
    this.scene.add(new THREE.HemisphereLight(0x8899bb, 0x2a2118, 0.55))

    const windowLight = new THREE.DirectionalLight(0xc8dcff, 2.1)
    windowLight.position.set(-6, 4.4, 1.4)
    windowLight.target.position.set(1.4, 0.2, -1.2)
    windowLight.castShadow = true
    windowLight.shadow.mapSize.set(1024, 1024)
    windowLight.shadow.camera.near = 0.5
    windowLight.shadow.camera.far = 22
    windowLight.shadow.camera.left = -6
    windowLight.shadow.camera.right = 6
    windowLight.shadow.camera.top = 6
    windowLight.shadow.camera.bottom = -6
    windowLight.shadow.bias = -0.0016
    this.scene.add(windowLight, windowLight.target)

    const practical = new THREE.PointLight(0xffb680, 22, 9, 2)
    practical.position.set(1.2, 2.5, -0.4)
    this.scene.add(practical)

    const rim = new THREE.DirectionalLight(0xffd0a8, 0.5)
    rim.position.set(4.5, 1.6, -4.5)
    this.scene.add(rim)

    this.rig = new THREE.Group()
    this.scene.add(this.rig)

    this.raycaster = new THREE.Raycaster()
  }

  load() {
    new GLTFLoader().load(this.url, (gltf) => this.arrive(gltf), undefined, (error) => {
      console.error("[room] could not load model", error)
    })
  }

  arrive(gltf) {
    const model = gltf.scene

    // Blender exports Y-up, and the room is already centred on its own origin,
    // so there is nothing to recentre - the model is authored in room metres.
    model.traverse((node) => {
      if (!node.isMesh) return
      node.castShadow = true
      node.receiveShadow = true

      // The glass is emissive in Blender; keep it from being a shadow caster and
      // blocking its own light.
      if (/window/i.test(node.name)) node.castShadow = false
    })

    model.traverse((node) => {
      if (node.parent === model && INSTRUMENTS[node.name]) {
        this.stations.set(node.name, {
          node,
          home: node.position.clone(),
          info: INSTRUMENTS[node.name]
        })
      }
    })

    this.rig.add(model)
    this.model = model
    this.frame()

    this.canvas.dispatchEvent(new CustomEvent("room:ready", {
      bubbles: true,
      detail: { instruments: this.stations.size }
    }))
  }

  // Frame the band, not the room: the walls are scenery and framing on them
  // pushes the instruments into the middle distance.
  frame() {
    const box = new THREE.Box3()
    this.stations.forEach(({ node }) => box.expandByObject(node))

    if (box.isEmpty()) box.setFromObject(this.model)

    const sphere = box.getBoundingSphere(new THREE.Sphere())
    const aspect = this.canvas.clientWidth / this.canvas.clientHeight || 1.6

    const halfVertical = THREE.MathUtils.degToRad(this.camera.fov) / 2
    const halfHorizontal = Math.atan(Math.tan(halfVertical) * aspect)
    const halfAngle = Math.min(halfVertical, halfHorizontal)

    this.target = sphere.center.clone()
    this.target.y = Math.max(this.target.y, 0.75)

    const distance = (sphere.radius * 1.25) / Math.sin(halfAngle)
    this.homePosition = this.target.clone().addScaledVector(CAMERA_DIRECTION, distance)

    this.camera.position.copy(this.homePosition)
    this.camera.lookAt(this.target)
  }

  observe() {
    this.onResize = () => this.resize()
    window.addEventListener("resize", this.onResize)

    this.updatePointer = (event) => {
      const rect = this.canvas.getBoundingClientRect()
      this.pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1
      this.pointer.y = -(((event.clientY - rect.top) / rect.height) * 2 - 1)
    }

    this.onPointerDown = (event) => {
      this.updatePointer(event)
      this.drag = { x: event.clientX, y: event.clientY, moved: 0, spin: this.spin }
      this.canvas.setPointerCapture?.(event.pointerId)
    }

    this.onPointerMove = (event) => {
      this.updatePointer(event)

      if (this.drag) {
        const dx = event.clientX - this.drag.x
        const dy = event.clientY - this.drag.y
        this.drag.moved = Math.max(this.drag.moved, Math.abs(dx) + Math.abs(dy))
        this.spin = this.drag.spin + dx * 0.006
        this.camera.position.y = THREE.MathUtils.clamp(this.homePosition.y + dy * 0.012, 0.6, 6.5)
        return
      }

      this.hover(this.pick())
    }

    this.onPointerUp = (event) => {
      const wasClick = this.drag && this.drag.moved < 6
      this.drag = null
      this.canvas.releasePointerCapture?.(event.pointerId)
      if (!wasClick) return

      const hit = this.pick()
      if (!hit) return

      this.audio?.start()
      this.audio?.play(hit.info.voice)
      this.pulse(hit)
      this.canvas.dispatchEvent(new CustomEvent("room:play", {
        bubbles: true,
        detail: { label: hit.info.label, blurb: hit.info.blurb }
      }))
    }

    this.onPointerLeave = () => {
      this.drag = null
      this.hover(null)
    }

    this.canvas.addEventListener("pointerdown", this.onPointerDown)
    this.canvas.addEventListener("pointermove", this.onPointerMove)
    this.canvas.addEventListener("pointerup", this.onPointerUp)
    this.canvas.addEventListener("pointerleave", this.onPointerLeave)

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => { this.visible = entry.isIntersecting })
    }, { threshold: 0.01 })

    this.observer.observe(this.canvas)
  }

  pick() {
    if (!this.model) return null

    this.raycaster.setFromCamera(this.pointer, this.camera)
    const hits = this.raycaster.intersectObject(this.model, true)
    if (!hits.length) return null

    let node = hits[0].object
    while (node && node.parent !== this.model) node = node.parent
    if (!node) return null

    return this.stations.get(node.name) ?? null
  }

  hover(station) {
    if (this.hovered === station) return

    if (this.hovered) this.hovered.node.position.copy(this.hovered.home)
    this.hovered = station
    this.canvas.style.cursor = station ? "pointer" : "grab"

    this.canvas.dispatchEvent(new CustomEvent("room:hover", {
      bubbles: true,
      detail: station ? { label: station.info.label, blurb: station.info.blurb } : null
    }))
  }

  pulse(station) {
    // A hit should move the instrument, not the whole room: one short lift and
    // back down, which is enough to connect the sound to the object.
    const existing = this.pulses.find((entry) => entry.station === station.node)
    if (existing) existing.started = performance.now()
    else this.pulses.push({ station: station.node, home: station.home.clone(), started: performance.now() })
  }

  // Every entry point for sound goes through here, so the buttons under the
  // canvas hit the same voice as clicking the instrument itself.
  playStation(name) {
    const station = this.stations.get(name)
    if (!station) return false

    this.audio?.start()
    this.audio?.play(station.info.voice)
    this.pulse(station)

    this.canvas.dispatchEvent(new CustomEvent("room:play", {
      bubbles: true,
      detail: { label: station.info.label, blurb: station.info.blurb }
    }))
    return true
  }

  play(name) {
    this.audio?.start()
    this.audio?.play(name)
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

    const now = performance.now()

    this.pulses = this.pulses.filter((entry) => {
      const elapsed = (now - entry.started) / 420
      if (elapsed >= 1) {
        entry.station.position.copy(entry.home)
        return false
      }

      entry.station.position.y = entry.home.y + Math.sin(elapsed * Math.PI) * 0.045
      return true
    })

    // Turn slowly on its own until someone drags it.
    if (!this.drag) this.spin += 0.0011
    if (this.rig) this.rig.rotation.y = this.spin

    if (this.target) this.camera.lookAt(this.target)
    this.renderer.render(this.scene, this.camera)
  }

  dispose() {
    cancelAnimationFrame(this.frameId)
    this.audio?.stopGroove()
    this.observer?.disconnect()
    window.removeEventListener("resize", this.onResize)
    this.canvas.removeEventListener("pointerdown", this.onPointerDown)
    this.canvas.removeEventListener("pointermove", this.onPointerMove)
    this.canvas.removeEventListener("pointerup", this.onPointerUp)
    this.canvas.removeEventListener("pointerleave", this.onPointerLeave)
    this.renderer.dispose()
  }
}
