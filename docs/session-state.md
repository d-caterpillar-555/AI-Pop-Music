# Session state

A handoff note so a fresh session can pick this up with no re-discovery.

Last worked on: the motion studies. Four variate rounds are live on the site, and
the guitar render was re-lit from scratch. Everything below is committed to
`github.com/d-caterpillar-555/AI-Pop-Music`.

## Environment facts worth not rediscovering

| Fact | Detail |
|---|---|
| Project | `\\wsl.localhost\Ubuntu\home\dcate\ai-pop-music`, WSL2 Ubuntu |
| Run | `bin/pg start` (Postgres 18 on **5434**), then `mise exec -- bin/dev` on :3000 |
| Ruby | 3.4.10 via `mise`, never the system 3.3.8 |
| Seed logins | `admin@` / `editor@` / `member@example.com`, password `password1234` |
| Blender | **Moved.** `D:\Installed Apps\Blender\blender-4.5.9-windows-x64\blender.exe` (4.5.9 LTS). `D:\Program Apps\Blender` is gone. Headless: `& "<that path>" --background --python <script>.py -- <out.png>` |
| Write scope | Only `D:\Program Apps\AI Pop Music` and the project. Not `D:\apm-shots` any more. |
| Screenshots | `agent-browser screenshot` writes fine to a path containing spaces; that old silent-failure bug is gone. |
| Kill the server | `kill_shell` with the task id. `pkill -f puma` kills the shell running it. **Never pipe `bin/dev` into `head`** — the SIGPIPE takes the server down. |
| Blender staging | Copy the script to `D:\Program Apps\AI Pop Music\Blender\work\`, run with local paths, then check the PNG exists. UNC paths are still fatal and still silent. |
| Blender exit code | Still 0 on a Python traceback. Assert the artifact, never the exit code. |

## Variate rounds (all live)

Four sets, one card. `[` and `]` move between sets; if the card is showing a set
that does not belong to the page you are on, use the card's own set control.

| Set | File | Live | Recommendation |
|---|---|---|---|
| `exploded-guitar` | `app/javascript/scenes/exploded_guitar.js` | 3 of 4 | 3, the light box |
| `band-room` | `app/javascript/scenes/band_room.js` | 4 of 4 | 4, the presentation |
| `visualiser` | `app/javascript/scenes/visualiser.js` | 2 of 4 | 2, the ridge |
| `index-html` | `app/views/genres/index.html.erb` | 4 of 4 | 4, the halved |

Each position's angle and cost ride the card. The reasoning behind the picks is
in the round handoffs, not repeated here.

**Editing a variant file while it is live makes variate adopt the old target as a
new position on the next switch.** That is how phantom `5.js` files appeared
three times. Edit, then `use` again, then delete any stray.

## Three classes of bug worth knowing, because all three were silent

1. **Stimulus identifiers.** `track_row_controller.js` registers as `track-row`,
   not `track_row`. The markup said `track_row`, so the controller never bound
   and `player:play` was never dispatched — with a clean console. Check
   `Array.from(Stimulus.router.modulesByIdentifier.keys())` before believing any
   markup.
2. **`stylesheet_link_tag :app` expands to EVERY stylesheet in the asset paths.**
   That pulled Avo's 318 KB admin bundle into every public page, and its bare
   `dl { display: grid; grid-template-columns: max-content 1fr }` is what
   collapsed the FAQ into a ribbon. The layout now names `"tailwind"`; Avo's own
   layout loads `avo/application` itself, so `/admin` is unaffected.
3. **`vertexColors: true` on an InstancedMesh renders every instance black.** It
   makes the shader want a per-vertex `color` attribute a BoxGeometry has not
   got. Instance colours need no flag.

Also fixed this session: the player's AudioContext was built during `connect()`,
outside a user gesture, so Chrome created it suspended and playback was silent.
It is now built and resumed inside the click.

## Model axis facts, learned the hard way

- The **guitar** model lies flat: 900 mm on Z, 330 mm on X, only 77 mm thick on
  Y. Any camera level with it watches it edge-on, which is why the original view
  read as stacked slabs. Put the camera above it.
- The **room** model has 16 top-level nodes: `Room`, the nine playable
  instruments (`Drums`, `Elec1`, `Elec2`, `Bass`, `Acoustic`, `Keys`, `Amp`,
  `Mic`, `Board`), four `*_Stand` nodes, `Furniture` and an empty `CameraPivot`.
- **Fit a box, not a sphere.** A bounding-sphere fit against the vertical FOV is
  wildly conservative for a wide flat subject and leaves it a toy in frame. The
  new variants carry a `fit(box, direction)` spanning the box against the
  camera's own basis.

## The guitar render

`script/blender/guitar/m1_silhouette.py`. Render cost is **about 2m50s per still
at 128 samples, 1600x900, CPU**. Measured, not guessed.

What was actually wrong, and what fixed it:

| Problem | Cause | Fix |
|---|---|---|
| Deep red read as pale pink | `Coat Weight` 1.0 with `Coat Roughness` 0.03 — a near-mirror coat spreading white specular across the whole body | coat 0.5, coat roughness 0.09 |
| No separation between subject and background | the world was light grey (0.42, 0.44, 0.48) at strength 0.30, so ambient did as much work as the key | world (0.055, 0.060, 0.075) at 0.5 |
| Backdrop and floor the same value | ground colour 0.30 grey against a 0.42 world | ground (0.055, 0.055, 0.062) |
| Still hot after those | lights 110/42/60/48 W | 90/34/50/38 W, exposure -0.15 |
| Body corner cropped | margin 1.25 | margin 1.42 |

Latest verified still: `Screenshots/17-guitar-lit.png`.

### Still to do for (a)

The plan's full part count is not reached. Missing: screw slots, the cavity and
its cover, wiring, dressed fret ends, edge wear driven by pointiness, and a
shadow-catcher floor. The geometry that shipped to `exploded_guitar.glb` has 66
named parts and is sound; what is missing is what a macro pass would show.

Then the macro + explode two-shot with the camera dollying **out**, then the
480-frame WebP sequence and the home-page scroll scrub. **Measure the first frame
before committing to a count** — 480 frames at these settings is about 23 hours.

## Definition of done, current standing

- rspec 88 examples, 0 failures
- rubocop 178 files, no offences
- brakeman 0 warnings
- `script/db-verify` not re-run this session
- Previews are still the synthesised `Catalogue::PreviewTone` sine pad, not
  music, and seeded tracks still have no masters, so downloads end in "not
  available yet"
- No artwork anywhere
- The generation pipeline has not produced a track. `docs/project-context.md` §6
  carries the YuE2 licence gate as an open release item.
