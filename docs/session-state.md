# Session state

A handoff note so a fresh session can pick this up with no re-discovery. Delete
it once the motion work is finished and the fluff is gone.

Last worked on: v2 frontend (three design directions) plus the start of the
motion studies. Everything below is committed and pushed to
`github.com/d-caterpillar-555/AI-Pop-Music`.

## Environment facts worth not rediscovering

| Fact | Detail |
|---|---|
| Project | `\\wsl.localhost\Ubuntu\home\dcate\ai-pop-music`, WSL2 Ubuntu |
| Run | `bin/pg start` (Postgres 18 on **5434**), then `mise exec -- bin/dev`, or `bin/rails server -p 5000 -b 0.0.0.0` |
| Ruby | 3.4.10 via `mise`, never the system 3.3.8 |
| Seed logins | `admin@` / `editor@` / `member@example.com`, password `password1234` |
| Blender | **Works.** Portable build at `D:\Program Apps\Blender\blender-4.5.9-windows-x64\blender.exe` (4.5.9 LTS). Headless: `& "<that path>" --background --python <script>.py`. The Store package is a dead end — its binary sits in the ACL-protected `WindowsApps` store with no PATH alias and no Start-menu entry; ignore it. |
| Screenshots | **agent-browser silently fails when the output path contains a space** — it prints "saved" and writes nothing. Stage to `D:\apm-shots\`, then `Copy-Item` into `D:\Program Apps\AI Pop Music\Screenshots\`. |
| Restart after adding pins | Adding a `pin_all_from` directory to `config/importmap.rb` requires a **server restart**; otherwise controllers fail with "Failed to fetch dynamically imported module". |
| Kill the server carefully | `pkill -f puma` killed the shell running it. Prefer `kill_shell` with the task id. |

## Rules discovered the hard way

- **Never touch Stimulus targets inside `connect()`.** Stimulus connects a
  controller from `loadDefinition` when its module resolves, and in that path
  the scope is not attached yet — any target access throws
  `Cannot read properties of undefined (reading 'targets')`. Defer DOM work by
  one frame.
- **Do not put `data-controller` on an element that also carries
  `data-turbo-permanent`.** Stimulus and Turbo fight over ownership and the
  controller throws. The audio element is therefore created in JS and attached
  to `<html>`, outside Turbo's swap.
- **Class bodies do not warn about duplicate getters.** A second `get audio()`
  silently overrode the first and cost an hour. Search before assuming.
- Legacy `paper-100` tokens were re-pointed for the dark world and are wrong
  when used as a *fill* — that is what made the recommended pricing column
  black-on-black. Use `ink-*` for surfaces and hairlines.

## What works

- Catalogue, genres, track pages, plans, account area, admin (Avo, staff-gated)
- Three design directions via the switcher (`label` / `signal` / `gallery`),
  persisted in `localStorage`, applied pre-paint
- Licence-gated downloads with an append-only audit trail
- 88 rspec examples, rubocop clean, brakeman clean, `script/db-verify` (25
  constraint proofs)
- Screenshot pipeline (staging + move)

## What is broken

1. **The audio player does not play.** `data-player-state` is never written and
   clicks do nothing. Console is clean, so it is a wiring bug, not a throw.
   Every visual idea in the design depends on this thread.
2. **`/lab` guitar canvas draws nothing.** Geometry builds, slider moves, canvas
   is sized — nothing renders. Check the console on that page first; the
   dynamic-import error is the prime suspect.
3. **The player bar renders as an empty full-width band** in the layout, because
   `render()` never runs to translate it off-screen.
4. **The FAQ section on the home page is broken** — the `dl` collapses and its
   text overflows as a thin ribbon down the right edge, creating ~2000px of dead
   space.
5. **Every preview is a synthesised sine pad** (`Catalogue::PreviewTone`), not
   music. Labelled on the track page, not on the home page where people press
   play.
6. **No artwork anywhere**, and seeded tracks have no masters, so downloads end
   in "not available yet".

## Photoreal guitar rebuild — state

Plan: `~/.commandcode/plans/photoreal-guitar-explosion.md` (approved).
Work: `script/blender/guitar/` in the project, working copies in
`D:\Program Apps\AI Pop Music\Blender\`.

**Milestone 1 is done; milestone 2 (materials) is partly done.**
`script/blender/guitar/m1_silhouette.py` now renders a recognisable electric
guitar: body from a spline outline (Catmull-Rom through 31 landmark points with a
real neck pocket between two horns), bevel + light subsurf, tapered neck, radiused
fretboard, bone nut, headstock with six tuners, pickguard, three pickups with pole
pieces, bridge with six saddles and intonation screws, three knobs, jack plate,
strap buttons, 22 frets placed by the rule of eighteen, and six strings at real
gauges. Latest verified still: `Screenshots/14-guitar.png`.

### The iteration loop that works

Edit → copy to `D:\apm-shots\guitar\m1.py` → run Blender with **local** paths →
confirm the PNG exists → copy into `Screenshots/` → **read the image**. Roughly
1m50s per still at 128 samples, so batch several fixes per render; single-line
tweaks are not worth a render cycle.

### Fixes that mattered most, in order of impact

1. **Cut the neck pocket out of the outline.** Filling it in produced a blob —
   this was the single biggest reason it did not read as a guitar.
2. **Bevel width must stay well under part thickness** (a 16 mm bevel on a 3 mm
   plate bulged the guard into a cushion; 9 mm on the 44 mm body inflated it into
   a pillow). Body is 4.5 mm, guard 6 mm.
3. **Keep subsurf at 1** on the body, or the horns round off.
4. **Add the hardware.** Guard, pickups, bridge, knobs and a headstock do more for
   recognition than any amount of surface detail.
5. **Don't over-stretch the wood noise.** `scale=(1, 46, 1)` at high detail made
   fretboard grain look like a barcode. `(1, 12, 1)` at detail 6 reads as wood.
6. **Compute camera distance from the bounding box** (`frame_camera`) instead of
   guessing, and stop down to f/11. Guessing cropped the instrument twice.

### What still looks wrong in 14-guitar.png

- Headstock is too small and narrow for the neck; the tuner buttons read as
  floating sticks rather than machines. Needs a wider paddle and proper
  post/worm/button assembly with screws.
- Fretboard too narrow relative to the maple neck, so the pale neck dominates.
  The board should be the widest surface under the strings.
- A concave notch on the treble-side waist is too deep and reads as a hook.
- Strings are too thick and too bright; they should be near-invisible wire.
- Pickups blend into the guard — the bobbins need to read black against cream.
- Still no cavity, no neck pocket interior, no screws, no springs, no wiring, and
  no edge wear. Those are the detail that sells realism at macro range.

### Remaining for (a), then (b) and (c)

Macro pass (rakes across grain, fret ends, wound strings), then the explode with
the camera dollying *out*, then the 480-frame WebP sequence and home-page scrub.
Then (b) the nine-instrument room and (c) the visualiser. Render cost remains the
binding constraint — measure before committing to a frame count.

### Hard numbers and gotchas learned here

| Finding | Detail |
|---|---|
| **Render cost is the project's main constraint** | **3m32s for one 1600×900 still at 220 samples on CPU.** 480 frames at these settings is ~28 hours. Before rendering any sequence, cut samples to ~96 with denoise and drop to 960×540 (~30–40 s/frame ≈ 4–5 h), or find a way to get EEVEE a GL context. Measure the first frame before committing to a count. |
| **Blender exits 0 even when the script raises** | A Python traceback still returns exit code 0 and writes no output file. **Never trust the exit code — assert the artifact exists.** This cost two silent failures. |
| DOF attribute | `camera.data.dof.aperture_fstop`, not `aperture_fcs` (which does not exist in 4.5). |
| View transform | `scene.view_settings.look` **raises** on an unrecognised name instead of falling back — wrap it in a try/except over candidate names. |
| UNC paths | Still fatal and still silent. Copy the script local, run, move results. |

### What is wrong with the current still (m1-body.png)

1. **Blown out.** Big clipped-white region on the body; the red reads as pale pink.
   The four area lights at 420/220/180/150 W plus a 0.75 world are far too hot.
   Needs exposure set on `scene.view_settings.exposure` (negative) and lights
   cut by roughly 3–4×.
2. **Camera too close, again.** The body is cropped. Stop guessing distance —
   compute it from the subject's bounding box (frame the Box3 corners), the same
   way `three`'s `fitToBox` would.
3. **f/4 is far too shallow** at this distance. Use the equivalent of f/8–f/11.

### Still to do for (a)

Full part count from the plan (~350–400 objects: 6 tuners × 8 pieces, 22 frets
with dressed ends, 6 saddles + intonation screws + springs, 3 pickups × 6 pole
pieces, 3 pots, 5-way switch, jack plate, cavity covers + screws, strap buttons).
Then: HDRI environment, shadow-catcher floor, edge wear driven by pointiness, the
macro + explode two-shot, then the 480-frame WebP sequence and the home-page
scroll scrub. Then (b) and (c) with the same rig.

### Suggested next action

Fix exposure, camera framing (computed from bounding box) and DOF on
`m1_silhouette.py`, re-render one still, and **look at it** before adding a single
new part. The shape is right; the cinematography is what is failing.

## Next actions, in order

1. Fix the player (1) — nothing visual matters until it plays.
2. Debug `/lab` (2) and hide the player bar (3).
3. Fix the FAQ layout (4).
4. Stored waveform peaks: decode each master once at publish time into a peaks
   array on the track, so motion exists on a *silent* page. This is the unlock
   for scrollable audio artifacts.
5. Then (b) the nine-instrument room and (c) the artistic visualiser, both in
   Three.js (`app/javascript/scenes/`, pinned `three` 0.186).
