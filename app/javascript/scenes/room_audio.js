// (b) The room's instruments, as sound.
//
// Nine voices built from oscillators and noise rather than sample files: the
// room has to ship as code, and a few hundred kilobytes of samples for a
// rehearsal-room demo would be the wrong trade.
//
// The guitars, bass and acoustic use Karplus-Strong - a noise burst fed into a
// short delay line with a lowpass in the feedback path. It is a plucked string
// model rather than an approximation of one, which is why it sounds like an
// instrument and a filtered saw does not.

const A_MINOR = { a: 55.0, c: 65.41, d: 73.42, e: 82.41, g: 98.0, a2: 110.0, c2: 130.81, e2: 164.81 }
const CHORD = [110.0, 164.81, 220.0, 261.63]        // A5 shape: A E A C
const POWER = [82.41, 123.47, 164.81]                // E5: root, fifth, octave

export default class RoomAudio {
  constructor() {
    this.context = null
    this.master = null
    this.noise = null
    this.timer = null
    this.step = 0
    this.nextTime = 0
  }

  // Browsers only allow an AudioContext to start inside a gesture, so every
  // entry point pokes this first and the graph is built once.
  start() {
    if (this.context) {
      if (this.context.state === "suspended") this.context.resume()
      return true
    }

    const Context = window.AudioContext || window.webkitAudioContext
    if (!Context) return false

    this.context = new Context()

    this.master = this.context.createGain()
    this.master.gain.value = 0.55

    // Nine voices at once with a sequencer on top will clip without this.
    const compressor = this.context.createDynamicsCompressor()
    compressor.threshold.value = -14
    compressor.knee.value = 24
    compressor.ratio.value = 6

    this.master.connect(compressor)
    compressor.connect(this.context.destination)

    this.noise = this.noiseBuffer()
    return true
  }

  noiseBuffer(seconds = 2) {
    const length = Math.floor(this.context.sampleRate * seconds)
    const buffer = this.context.createBuffer(1, length, this.context.sampleRate)
    const data = buffer.getChannelData(0)

    for (let index = 0; index < length; index += 1) data[index] = Math.random() * 2 - 1
    return buffer
  }

  get now() {
    return this.context ? this.context.currentTime : 0
  }

  // --- voices ---------------------------------------------------------------

  kick(when = this.now, level = 1) {
    if (!this.context) return

    const body = this.context.createOscillator()
    const gain = this.context.createGain()

    body.type = "sine"
    // The pitch drop is the whole sound: a kick is a click plus a falling thump.
    body.frequency.setValueAtTime(140, when)
    body.frequency.exponentialRampToValueAtTime(42, when + 0.11)

    gain.gain.setValueAtTime(0, when)
    gain.gain.linearRampToValueAtTime(0.9 * level, when + 0.005)
    gain.gain.exponentialRampToValueAtTime(0.001, when + 0.42)

    const click = this.context.createBufferSource()
    const clickGain = this.context.createGain()
    click.buffer = this.noise
    clickGain.gain.setValueAtTime(0.35 * level, when)
    clickGain.gain.exponentialRampToValueAtTime(0.001, when + 0.02)

    body.connect(gain).connect(this.master)
    click.connect(clickGain).connect(this.master)

    body.start(when)
    body.stop(when + 0.45)
    click.start(when)
    click.stop(when + 0.03)
  }

  snare(when = this.now, level = 1) {
    if (!this.context) return

    const noise = this.context.createBufferSource()
    const filter = this.context.createBiquadFilter()
    const gain = this.context.createGain()

    noise.buffer = this.noise
    filter.type = "highpass"
    filter.frequency.value = 1600

    gain.gain.setValueAtTime(0.7 * level, when)
    gain.gain.exponentialRampToValueAtTime(0.001, when + 0.22)

    // The shell tone underneath the wires.
    const tone = this.context.createOscillator()
    const toneGain = this.context.createGain()
    tone.type = "triangle"
    tone.frequency.value = 190
    toneGain.gain.setValueAtTime(0.3 * level, when)
    toneGain.gain.exponentialRampToValueAtTime(0.001, when + 0.12)

    noise.connect(filter).connect(gain).connect(this.master)
    tone.connect(toneGain).connect(this.master)

    noise.start(when)
    noise.stop(when + 0.25)
    tone.start(when)
    tone.stop(when + 0.14)
  }

  hat(when = this.now, open = false, level = 1) {
    if (!this.context) return

    const noise = this.context.createBufferSource()
    const filter = this.context.createBiquadFilter()
    const gain = this.context.createGain()

    noise.buffer = this.noise
    filter.type = "highpass"
    filter.frequency.value = 7000

    const decay = open ? 0.32 : 0.06
    gain.gain.setValueAtTime(0.24 * level, when)
    gain.gain.exponentialRampToValueAtTime(0.001, when + decay)

    noise.connect(filter).connect(gain).connect(this.master)
    noise.start(when)
    noise.stop(when + decay + 0.05)
  }

  tom(when = this.now, frequency = 110, level = 1) {
    if (!this.context) return

    const body = this.context.createOscillator()
    const gain = this.context.createGain()

    body.type = "sine"
    body.frequency.setValueAtTime(frequency * 1.5, when)
    body.frequency.exponentialRampToValueAtTime(frequency, when + 0.16)

    gain.gain.setValueAtTime(0.6 * level, when)
    gain.gain.exponentialRampToValueAtTime(0.001, when + 0.35)

    body.connect(gain).connect(this.master)
    body.start(when)
    body.stop(when + 0.38)
  }

  // Karplus-Strong: excite a tuned delay line with a noise burst and let the
  // feedback loop lose its high end the way a real string does.
  pluck(frequency, when = this.now, options = {}) {
    if (!this.context) return

    const { decay = 0.996, damping = 3200, level = 0.5, duration = 1.6 } = options
    const period = 1 / frequency

    const burst = this.context.createBufferSource()
    burst.buffer = this.noise

    const excite = this.context.createGain()
    excite.gain.setValueAtTime(level, when)
    excite.gain.exponentialRampToValueAtTime(0.001, when + 0.02)

    const delay = this.context.createDelay(0.5)
    delay.delayTime.value = period

    const filter = this.context.createBiquadFilter()
    filter.type = "lowpass"
    filter.frequency.value = damping

    const feedback = this.context.createGain()
    feedback.gain.value = decay

    const output = this.context.createGain()
    output.gain.setValueAtTime(1, when)
    // Fade the tail so a long feedback cannot outlive its welcome.
    output.gain.setValueAtTime(1, when + duration - 0.3)
    output.gain.linearRampToValueAtTime(0, when + duration)

    burst.connect(excite).connect(delay)
    delay.connect(filter).connect(feedback).connect(delay)
    delay.connect(output).connect(this.master)

    burst.start(when)
    burst.stop(when + 0.05)
  }

  // A note rather than an effect: this is the guitalele-sized electric on the
  // stand, so three plucked notes a fifth apart.
  chord(when = this.now, notes = POWER, options = {}) {
    notes.forEach((frequency, index) => {
      this.pluck(frequency, when + index * 0.012, { level: 0.34, duration: 1.9, damping: 2600, ...options })
    })
  }

  bass(when = this.now, frequency = A_MINOR.a) {
    this.pluck(frequency, when, { level: 0.75, decay: 0.997, damping: 900, duration: 1.2 })
    const sub = this.context.createOscillator()
    const gain = this.context.createGain()
    sub.type = "sine"
    sub.frequency.value = frequency / 2
    gain.gain.setValueAtTime(0.22, when)
    gain.gain.exponentialRampToValueAtTime(0.001, when + 0.5)
    sub.connect(gain).connect(this.master)
    sub.start(when)
    sub.stop(when + 0.55)
  }

  // Electric piano: a sine carrier with a fast-decaying modulator, which is what
  // gives the attack its bark.
  key(when = this.now, frequency = 261.63, level = 0.3) {
    if (!this.context) return

    const carrier = this.context.createOscillator()
    const modulator = this.context.createOscillator()
    const modGain = this.context.createGain()
    const gain = this.context.createGain()

    carrier.type = "sine"
    carrier.frequency.value = frequency
    modulator.type = "sine"
    modulator.frequency.value = frequency * 2
    modGain.gain.setValueAtTime(frequency * 1.6, when)
    modGain.gain.exponentialRampToValueAtTime(1, when + 0.25)

    gain.gain.setValueAtTime(0, when)
    gain.gain.linearRampToValueAtTime(level, when + 0.008)
    gain.gain.exponentialRampToValueAtTime(0.001, when + 1.4)

    modulator.connect(modGain).connect(carrier.frequency)
    carrier.connect(gain).connect(this.master)

    modulator.start(when)
    carrier.start(when)
    carrier.stop(when + 1.5)
    modulator.stop(when + 1.5)
  }

  keys(when = this.now, notes = CHORD) {
    notes.forEach((frequency, index) => this.key(when + index * 0.02, frequency, 0.22))
  }

  // The amp: a saw through a soft clipper, which is what a cranked valve amp
  // does to a guitar, plus the cab's low end rolled off.
  amp(when = this.now, frequency = 82.41) {
    if (!this.context) return

    const source = this.context.createOscillator()
    const second = this.context.createOscillator()
    const shaper = this.context.createWaveShaper()
    const cab = this.context.createBiquadFilter()
    const gain = this.context.createGain()

    source.type = "sawtooth"
    source.frequency.value = frequency
    second.type = "sawtooth"
    second.frequency.value = frequency * 1.005   // slight detune, as a chord is never exact

    const curve = new Float32Array(1024)
    for (let index = 0; index < curve.length; index += 1) {
      const x = (index / (curve.length - 1)) * 2 - 1
      curve[index] = Math.tanh(x * 3.4)
    }
    shaper.curve = curve
    shaper.oversample = "2x"

    cab.type = "lowpass"
    cab.frequency.value = 3800

    gain.gain.setValueAtTime(0, when)
    gain.gain.linearRampToValueAtTime(0.22, when + 0.006)
    gain.gain.exponentialRampToValueAtTime(0.001, when + 0.7)

    source.connect(shaper)
    second.connect(shaper)
    shaper.connect(cab).connect(gain).connect(this.master)

    source.start(when)
    second.start(when)
    source.stop(when + 0.75)
    second.stop(when + 0.75)
  }

  // The vocal mic: a sawtooth bent into a vowel by two bandpass filters standing
  // in for formants, with a little vibrato so it reads as a voice and not a synth.
  voice(when = this.now, frequency = 220) {
    if (!this.context) return

    const source = this.context.createOscillator()
    const vibrato = this.context.createOscillator()
    const vibratoGain = this.context.createGain()
    const gain = this.context.createGain()

    source.type = "sawtooth"
    source.frequency.value = frequency

    vibrato.frequency.value = 5.2
    vibratoGain.gain.value = 5.5
    vibrato.connect(vibratoGain).connect(source.frequency)

    const formants = [
      { frequency: 730, q: 9, level: 0.9 },     // "ah"
      { frequency: 1090, q: 11, level: 0.5 },
      { frequency: 2440, q: 13, level: 0.22 },
    ]

    gain.gain.setValueAtTime(0, when)
    gain.gain.linearRampToValueAtTime(0.5, when + 0.06)
    gain.gain.setValueAtTime(0.5, when + 0.5)
    gain.gain.exponentialRampToValueAtTime(0.001, when + 1.1)

    formants.forEach((formant) => {
      const filter = this.context.createBiquadFilter()
      const level = this.context.createGain()
      filter.type = "bandpass"
      filter.frequency.value = formant.frequency
      filter.Q.value = formant.q
      level.gain.value = formant.level
      source.connect(filter).connect(level).connect(gain)
    })

    gain.connect(this.master)

    source.start(when)
    vibrato.start(when)
    source.stop(when + 1.2)
    vibrato.stop(when + 1.2)
  }

  // The pedalboard: whatever it is handed, through a slap-back delay.
  pedal(when = this.now, frequency = 164.81) {
    if (!this.context) return

    const delay = this.context.createDelay(1)
    const feedback = this.context.createGain()
    const wet = this.context.createGain()

    delay.delayTime.value = 0.24
    feedback.gain.value = 0.45
    wet.gain.value = 0.6

    delay.connect(feedback).connect(delay)
    delay.connect(wet).connect(this.master)

    const send = this.context.createGain()
    send.connect(delay)
    send.connect(this.master)

    const originalMaster = this.master
    this.master = send
    this.pluck(frequency, when, { level: 0.45, duration: 0.9, damping: 2800 })
    this.master = originalMaster
  }

  // --- the room plays -------------------------------------------------------

  play(name, when = this.now) {
    switch (name) {
      case "drums": {
        // Successive hits walk round the kit, which is what a visitor poking at
        // a drum kit actually does.
        const order = ["kick", "snare", "hat", "tom", "crash"]
        const hit = order[this.kitHit = ((this.kitHit ?? -1) + 1) % order.length]
        if (hit === "kick") this.kick(when)
        else if (hit === "snare") this.snare(when)
        else if (hit === "hat") this.hat(when, true)
        else if (hit === "tom") this.tom(when, 130)
        else { this.hat(when, true, 0.7); this.snare(when, 0.5) }
        return
      }
      case "chord": return this.chord(when)
      case "lead": return this.chord(when, [164.81, 220.0, 329.63], { damping: 4200, level: 0.3 })
      case "bass": return this.bass(when)
      case "acoustic": return this.chord(when, [196.0, 246.94, 329.63, 392.0], { damping: 5200, level: 0.26 })
      case "keys": return this.keys(when)
      case "amp": return this.amp(when)
      case "voice": return this.voice(when)
      case "pedal": return this.pedal(when)
      default: return undefined
    }
  }

  // A two-bar rock pattern, so the room can play itself. Sixteenth notes at
  // 92 BPM; the pattern is data so a different one is a different array.
  groove() {
    if (!this.start()) return
    if (this.timer) return this.stopGroove()

    const steps = [
      { at: 0, play: (when) => { this.kick(when); this.amp(when) } },
      { at: 2, play: (when) => this.hat(when) },
      { at: 3, play: (when) => { this.kick(when); this.bass(when, A_MINOR.a) } },
      { at: 4, play: (when) => this.snare(when) },
      { at: 6, play: (when) => { this.hat(when); this.bass(when, A_MINOR.a) } },
      { at: 8, play: (when) => { this.kick(when); this.chord(when, POWER, { level: 0.22 }) } },
      { at: 10, play: (when) => this.hat(when, true) },
      { at: 11, play: (when) => { this.bass(when, A_MINOR.g); this.amp(when, 61.74) } },
      { at: 12, play: (when) => { this.snare(when); this.voice(when, 196) } },
      { at: 14, play: (when) => { this.hat(when); this.bass(when, A_MINOR.d) } },
      { at: 16, play: (when) => { this.kick(when); this.keys(when, CHORD) } },
      { at: 19, play: (when) => { this.kick(when); this.bass(when, A_MINOR.a) } },
      { at: 20, play: (when) => this.snare(when) },
      { at: 22, play: (when) => { this.hat(when); this.pedal(when, A_MINOR.e) } },
      { at: 24, play: (when) => { this.kick(when); this.amp(when) } },
      { at: 26, play: (when) => this.hat(when) },
      { at: 27, play: (when) => this.bass(when, A_MINOR.c) },
      { at: 28, play: (when) => this.snare(when) },
      { at: 30, play: (when) => { this.hat(when, true); this.chord(when, POWER, { level: 0.2 }) } },
    ]

    const sixteenth = 60 / 92 / 4
    this.step = 0
    this.nextTime = this.now + 0.08

    // Look ahead rather than firing on a timer tick: a JS timer is not accurate
    // enough to keep a groove in time, but it is accurate enough to hand the
    // next window of events to the audio clock, which is.
    const schedule = () => {
      while (this.nextTime < this.now + 0.25) {
        const bar = this.step % 32
        steps.filter((event) => event.at === bar).forEach((event) => event.play(this.nextTime))
        this.nextTime += sixteenth
        this.step += 1
      }
    }

    schedule()
    this.timer = setInterval(schedule, 120)
    return true
  }

  stopGroove() {
    if (this.timer) clearInterval(this.timer)
    this.timer = null
  }
}
