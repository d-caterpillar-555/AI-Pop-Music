import * as THREE from "three"
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js"

// (a) The exploded guitar, loaded from the model Blender bakes.
//
// The geometry comes from script/blender/exploded_guitar.py - 66 named parts,
// authored to real guitar dimensions in metres. This class only frames it,
// decides how far each part travels when the instrument comes apart, and draws.
export default class ExplodedGuitar {
  constructor(canvas, url) {
    this.canvas = canvas
    this.url = url
    this.explode = 0
    this.target = 0
    this.spin = 0
    this.parts = []
    this.pointer = { x: 0, y: 0 }

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
    this.renderer.toneMappingExposure = 1.05

    this.scene = new THREE.Scene()

    // A guitar is about a metre long, so the camera sits close and looks at its
    // middle. Framed slightly high, which is how you photograph an instrument.
    this.camera = new THREE.PerspectiveCamera(34, w / h, 0.01, 50)
    this.camera.position.set(0, 0.05, 1.35)
    this.camera.lookAt(0, 0.08, 0)

    this.scene.add(new THREE.AmbientLight(0xffffff, 0.5))

    const key = new THREE.DirectionalLight(0xfff2e2, 2.4)
    key.position.set(0.8, 1.2, 1.6)
    this.scene.add(key)

    const fill = new THREE.DirectionalLight(0x9fc0ff, 0.7)
    fill.position.set(-1.4, -0.3, 0.8)
    this.scene.add(fill)

    const rim = new THREE.DirectionalLight(0xffd9c0, 1.1)
    rim.position.set(-0.4, 0.6, -1.6)
    this.scene.add(rim)

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

    // Blender's glTF is Y-up, so this is already the right way round. Centre it
    // on the origin so the explode spreads evenly instead of drifting.
    const box = new THREE.Box3().setFromObject(model)
    const centre = box.getCenter(new THREE.Vector3())
    model.position.sub(centre)

    model.traverse((node) => {
      if (!node.isMesh) return

      node.castShadow = true
      node.receiveShadow = true

      // Parts travel away from the middle of the instrument, then get pulled
      // apart further by a factor derived from their name - so strings lift as
      // a group, frets fan out together, and hardware separates last.
      const home = node.getWorldPosition(new THREE.Vector3()).sub(centre)
      const direction = home.clone()

      if (direction.lengthSq() < 1e-8) direction.set(0, 0, 1)
      direction.normalize()

      const kind = node.name.replace(/[0-9]+/g, "").toLowerCase()
      const weight = {
        string: 1.5,
        fret: 1.15,
        pole: 1.1,
        saddle: 1.05,
        tunerpost: 0.95,
        tunerbutton: 1.1,
        cavitycover: 1.35,
        pickguard: 1.3,
        knob: 1.3,
        knobshaft: 1.25,
        pickup: 1.0
      }[kind] ?? 0.8

      this.parts.push({
        node,
        home: node.position.clone(),
        travel: direction.multiplyScalar(0.42 * weight)
      })
    })

    this.rig.add(model)
    this.model = model

    if (this.framed !== true) {
      this.framed = true
      this.dispatchReady()
    }
  }

  dispatchReady() {
    this.canvas.dispatchEvent(new CustomEvent("guitar:ready", { bubbles: true }))
  }

  observe() {
    this.onResize = () => this.resize()
    window.addEventListener("resize", this.onResize)

    this.onPointerMove = (event) => {
      const rect = this.canvas.getBoundingClientRect()
      this.pointer.x = ((event.clientX - rect.left) / rect.width - 0.5) * 2
      this.pointer.y = ((event.clientY - rect.top) / rect.height - 0.5) * 2
    }

    this.onPointerLeave = () => {
      this.pointer.x = 0
      this.pointer.y = 0
    }

    this.canvas.addEventListener("pointermove", this.onPointerMove)
    this.canvas.addEventListener("pointerleave", this.onPointerLeave)

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => { this.visible = entry.isIntersecting })
    }, { threshold: 0.01 })

    this.observer.observe(this.canvas)
  }

  setExplode(value) {
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
    if (this.visible === false) return

    // Eased, so dragging the control feels mechanical rather than linear.
    this.explode += (this.target - this.explode) * 0.075

    this.parts.forEach(({ node, home, travel }) => {
      node.position.copy(home).addScaledVector(travel, this.explode)
    })

    // Turn slowly, and lean into the pointer.
    this.spin += 0.0014
    this.rig.rotation.y = this.spin + this.pointer.x * 0.45
    this.rig.rotation.x = -this.pointer.y * 0.2

    this.renderer.render(this.scene, this.camera)
  }

  dispose() {
    cancelAnimationFrame(this.frame)
    this.observer?.disconnect()
    window.removeEventListener("resize", this.onResize)
    this.canvas.removeEventListener("pointermove", this.onPointerMove)
    this.canvas.removeEventListener("pointerleave", this.onPointerLeave)
    this.renderer.dispose()
  }
}
