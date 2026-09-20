import * as THREE from "three"
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js"

// (a) The exploded guitar, in a light box.
//
// The model lies flat, so this is the studio shot you would actually take of
// it: camera above and off to the corner, a seamless white floor, and the
// model's own materials doing the talking. The camera starts tight on the whole
// instrument and pulls back and up as it opens, so the guitar gets smaller
// exactly as it gets busier - which is the only thing that keeps 66 parts
// readable instead of a cloud.
//
// Parts do not all leave at once: each has a place in the order and its own
// distance, so the break is sequenced rather than a single pop.

// How far each kind lifts off the face, in metres.
//
// The lifts are PER ASSEMBLY, not per part. The LS16 exploded view groups its
// components - headstock assembly, neck assembly, body top, body back and
// sides, bridge assembly, electronics - and that grouping is the whole reason
// its parts look like they came off an instrument. Giving the neck and the
// headstock different lifts tore the neck in half: the headstock walked away
// from the stick it is glued to.
const LIFT = {
  body: 0.00, cavitycover: -0.06,

  // The neck assembly, rigid. Neck, board, frets, nut, headstock, machines.
  neck: 0.06, headstock: 0.06, fretboard: 0.06, nut: 0.06, fret: 0.06,
  tunerpost: 0.06, tunerbutton: 0.06,

  // Everything bolted to the face.
  bridge: 0.12, pickup: 0.12, switch: 0.12, jack: 0.12, knobshaft: 0.12,
  jackplate: 0.12, straptop: 0.12, strapbottom: 0.12,

  // And the small parts that sit on those, a hair above their host.
  saddle: 0.14, intonation: 0.135, pole: 0.14, knob: 0.135, knobcap: 0.15,

  // The strings come off everything.
  string: 0.20
}

// None. Any outward drift is a drift ALONG the instrument, because that is the
// direction its parts are laid out in, and it is what turned the neck, the board
// and the headstock into a row of separate slabs. Straight up, only.
const SPREAD = 0.0

// When each kind starts moving, 0 to 1. Heavier parts commit first.
const ORDER = {
  body: 0.00, neck: 0.04, headstock: 0.08, fretboard: 0.10, pickguard: 0.12,
  cavitycover: 0.12, straptop: 0.12, strapbottom: 0.12, pickup: 0.16,
  bridge: 0.18, switch: 0.20, jack: 0.20, jackplate: 0.22, knobshaft: 0.22,
  saddle: 0.24, intonation: 0.26, pole: 0.26, knob: 0.28, fret: 0.30,
  nut: 0.30, knobcap: 0.30, tunerpost: 0.32, tunerbutton: 0.34, string: 0.36
}

const PAPER = "#f6f5f2"

// Above, and off the corner far enough that the instrument reads long rather
// than as a diagonal. An azimuth of zero would put the length flat across the
// canvas but hide the body's shape, so this keeps a little of both.
const EYE = new THREE.Vector3(0.70, 0.62, 0.35).normalize()

export default class ExplodedGuitar {
  constructor(canvas, url) {
    this.canvas = canvas
    this.url = url
    this.explode = 0
    this.target = 0
    this.parts = []

    // The control that belongs to this piece, so scroll can move it and the
    // number on screen never disagrees with the drawing.
    this.slider = canvas.closest("section")?.querySelector('input[type="range"]') ?? null
    this.manual = false
    this.yaw = 0
    this.pitch = 0
    this.zoom = 1.0

    // Read before anything is built, because it changes what gets built. As a
    // background the instrument is fixed behind the page, so its own rectangle
    // never moves and the studio floor would draw a horizon across the site.
    //
    // Walked up the ancestors rather than read off the canvas: the canvas itself
    // is a plain block, and it is the wrapper around it that is fixed.
    this.fixed = (() => {
      let node = canvas
      while (node && node !== document.documentElement) {
        if (getComputedStyle(node).position === "fixed") return true
        node = node.parentElement
      }
      return false
    })()

    canvas.dataset.variateSection = "exploded-guitar"

    this.setupScene()
    this.load()
    this.observe()
    this.animate()
  }

  setupScene() {
    const { clientWidth: w, clientHeight: h } = this.canvas

    // alpha is load-bearing as a background: without it the canvas clears to
    // opaque black and paints over the entire page behind it.
    this.renderer = new THREE.WebGLRenderer({ canvas: this.canvas, antialias: true, alpha: true })
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    this.renderer.setSize(w, h, false)
    this.renderer.outputColorSpace = THREE.SRGBColorSpace
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping
    this.renderer.toneMappingExposure = 1.3
    this.renderer.shadowMap.enabled = true
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap

    this.scene = new THREE.Scene()

    // No studio when it is a background: an opaque sweep would paint over the
    // page, and the floor would cut a horizon line across the whole site.
    if (!this.fixed) {
      this.scene.background = new THREE.Color(PAPER)
      this.scene.fog = new THREE.Fog(PAPER, 3.2, 11)
    }

    this.camera = new THREE.PerspectiveCamera(32, w / h, 0.05, 40)

    // The guitar is lifted onto the floor once we know how thick it is; until
    // then, aim at the origin.
    this.floor = -0.04

    // A white room, so nothing under the instrument ever goes black.
    this.scene.add(new THREE.HemisphereLight(0x8fa6d8, 0x0b0d12, 0.45))

    const softbox = new THREE.DirectionalLight(0xfff0dc, 4.6)
    softbox.position.set(1.4, 2.6, 1.8)
    softbox.castShadow = true
    softbox.shadow.mapSize.set(2048, 2048)
    softbox.shadow.camera.near = 0.5
    softbox.shadow.camera.far = 9
    softbox.shadow.camera.left = -1.4
    softbox.shadow.camera.right = 1.4
    softbox.shadow.camera.top = 1.4
    softbox.shadow.camera.bottom = -1.4
    softbox.shadow.bias = -0.0014
    softbox.shadow.radius = 3
    this.scene.add(softbox)

    const kicker = new THREE.DirectionalLight(0x9fc0ff, 2.0)
    kicker.position.set(-2.0, 0.7, 0.9)
    this.scene.add(kicker)

    this.rig = new THREE.Group()
    this.scene.add(this.rig)
  }

  load() {
    new GLTFLoader().load(this.url, (gltf) => this.arrive(gltf), undefined, (error) => {
      console.error("[guitar] could not load model", error)
    })
  }

  arrive(gltf) {
    const model = gltf.scene

    const box = new THREE.Box3().setFromObject(model)
    const centre = box.getCenter(new THREE.Vector3())
    model.position.sub(centre)

    model.traverse((node) => {
      if (!node.isMesh) return

      node.castShadow = true
      node.receiveShadow = true

      const kind = node.name.replace(/[0-9-]+/g, "").toLowerCase()
      const away = node.getWorldPosition(new THREE.Vector3()).sub(centre)

      if (away.lengthSq() < 1e-8) away.set(0.2, 0, 0.4)
      away.normalize().multiplyScalar(SPREAD)
      away.y = LIFT[kind] ?? 0.1

      this.parts.push({
        node,
        home: node.position.clone(),
        travel: away,
        order: ORDER[kind] ?? 0.2
      })
    })

    // Sit the instrument on the floor rather than in it.
    this.rig.position.y = this.floor + (box.max.y - box.min.y) / 2 + 0.005

    this.model = model
    this.rig.add(model)

    // Two framings: the instrument whole, and the cloud it becomes. The camera
    // travels between them as the explode does.
    const open = new THREE.Box3()
    this.parts.forEach(({ node, home, travel }) => {
      node.position.copy(home).add(travel)
      open.expandByObject(node)
      node.position.copy(home)
    })

    // Fit the sphere against the VERTICAL field only. On a wide canvas that is
    // the tight axis, and the instrument is long across, so a sphere fit at 1.0
    // leaves the shot looking lost in its own studio.
    this.fit = (box3) => {
      const sphere = box3.getBoundingSphere(new THREE.Sphere())
      const half = THREE.MathUtils.degToRad(this.camera.fov) / 2
      return (sphere.radius * 0.82) / Math.sin(half)
    }

    this.near = this.fit(box)
    this.far = this.fit(open)
    this.aim = new THREE.Vector3(0, this.rig.position.y, 0)

    this.place(0)
    this.painted = false

    this.canvas.dispatchEvent(new CustomEvent("guitar:ready", { bubbles: true }))
  }

  // Where the camera sits for a given amount of explode.
  place(explode) {
    const distance = THREE.MathUtils.lerp(this.near, this.far, explode) * this.zoom
    const lift = THREE.MathUtils.lerp(0, 0.35, explode)

    // The drag is an azimuth and a pitch the viewer owns, applied on top of the
    // fixed three-quarter view, so the instrument can be walked all the way
    // round and looked under.
    const eye = EYE.clone()
      .applyAxisAngle(new THREE.Vector3(1, 0, 0), this.pitch ?? 0)
      .applyAxisAngle(new THREE.Vector3(0, 1, 0), this.yaw)

    this.camera.position.copy(this.aim).addScaledVector(eye, distance)
    this.camera.position.y += lift
    this.camera.lookAt(this.aim)
  }

  observe() {
    this.onResize = () => this.resize()
    window.addEventListener("resize", this.onResize)

    // Drag to turn the instrument. A fixed three-quarter view shows one face of
    // a guitar, and the back of it is most of the instrument.
    this.onPointerDown = (event) => {
      this.drag = { x: event.clientX, yaw: this.yaw }
      this.pitch = this.pitch ?? 0
      this.dragY = event.clientY
      this.dragPitch = this.pitch
      this.canvas.setPointerCapture?.(event.pointerId)
      this.canvas.style.cursor = "grabbing"
    }

    this.onPointerMove = (event) => {
      if (!this.drag) return
      this.yaw = this.drag.yaw - (event.clientX - this.drag.x) * 0.008
      this.pitch = THREE.MathUtils.clamp(this.dragPitch + (event.clientY - this.dragY) * 0.005, -0.5, 0.9)
    }

    this.onPointerUp = (event) => {
      this.drag = null
      this.canvas.releasePointerCapture?.(event.pointerId)
      this.canvas.style.cursor = "grab"
    }

    this.canvas.style.cursor = "grab"
    this.canvas.addEventListener("pointerdown", this.onPointerDown)
    this.canvas.addEventListener("pointermove", this.onPointerMove)
    this.canvas.addEventListener("pointerup", this.onPointerUp)

    // Scroll drives the piece. On a home page nobody is going to find a slider
    // and drag it, but everybody scrolls, so scrolling the instrument through
    // the viewport is what takes it apart.
    this.onScroll = () => {
      // A slider drag wins until the page actually moves again, so the control
      // is not fighting the scroll while someone is holding it.
      if (Math.abs(window.scrollY - (this.lastScrollY ?? window.scrollY)) > 2) {
        this.manual = false
      }
      this.lastScrollY = window.scrollY
    }

    window.addEventListener("scroll", this.onScroll, { passive: true })

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => { this.visible = entry.isIntersecting })
    }, { threshold: 0.01 })

    this.observer.observe(this.canvas)
  }

  // How far this canvas has travelled through the viewport, 0 to 1.
  //
  // Remapped rather than raw: the move is finished by the time the piece is
  // centred, and holds at both ends, so the guitar is not still opening while it
  // slides off the top of the screen.
  scrub() {
    const viewport = window.innerHeight || 1

    // A fixed canvas never travels, so measuring its position would read zero
    // forever. When the instrument is the background, the page's own scroll is
    // the progress: it is fully assembled at the top and fully apart at the
    // bottom.
    if (this.fixed) {
      const span = Math.max(document.documentElement.scrollHeight - viewport, 1)
      return Math.min(Math.max(window.scrollY / span, 0), 1)
    }

    const rect = this.canvas.getBoundingClientRect()
    const raw = (viewport - rect.top) / (viewport + rect.height)

    return Math.min(Math.max((raw - 0.12) / 0.58, 0), 1)
  }

  setExplode(value) {
    // Taking the slider hands control to the person holding it, until the page
    // scrolls again.
    this.manual = true
    this.target = Math.min(Math.max(value, 0), 1)
  }

  resize() {
    const { clientWidth: w, clientHeight: h } = this.canvas
    if (!w || !h) return

    this.camera.aspect = w / h
    this.camera.updateProjectionMatrix()
    this.renderer.setSize(w, h, false)
  }

  animate() {
    this.frame = requestAnimationFrame(() => this.animate())

    // Paint one frame even before the section is scrolled to. Gating the first
    // paint on the observer means an off-screen canvas is a black rectangle in a
    // full-page capture and on a fast scroll, which reads as a broken page.
    if (this.visible === false && this.painted) return
    this.painted = true

    // Scroll owns the explode until someone takes the slider.
    if (!this.manual) {
      this.target = this.scrub()

      // Keep the control honest about what the page is doing.
      if (this.slider) this.slider.value = Math.round(this.target * 100)
    }

    // A background has no pointer to drag it, so it turns itself.
    if (this.fixed) this.yaw += 0.0011

    this.explode += (this.target - this.explode) * 0.075

    this.parts.forEach(({ node, home, travel, order }) => {
      // A part starts the moment the control passes its place in the order,
      // then eases out as it settles.
      const span = Math.max(1 - order, 0.001)
      const raw = Math.min(Math.max((this.explode - order) / span, 0), 1)
      const local = 1 - Math.pow(1 - raw, 3)

      node.position.copy(home).addScaledVector(travel, local)
    })

    if (this.aim) this.place(this.explode)

    this.renderer.render(this.scene, this.camera)
  }

  dispose() {
    cancelAnimationFrame(this.frame)
    this.observer?.disconnect()
    window.removeEventListener("resize", this.onResize)
    window.removeEventListener("scroll", this.onScroll)
    this.canvas.removeEventListener("pointerdown", this.onPointerDown)
    this.canvas.removeEventListener("pointermove", this.onPointerMove)
    this.canvas.removeEventListener("pointerup", this.onPointerUp)
    this.renderer.dispose()
  }
}
