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
| Blender | **Not usable.** Store package data exists at `AppData\Local\Packages\BlenderFoundation.Blender_ppwjx1n5r4v9t` but the binary is in the ACL-protected `WindowsApps` store, with no PATH alias and no Start-menu entry. Do not plan around it. |
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

## Next actions, in order

1. Fix the player (1) — nothing visual matters until it plays.
2. Debug `/lab` (2) and hide the player bar (3).
3. Fix the FAQ layout (4).
4. Stored waveform peaks: decode each master once at publish time into a peaks
   array on the track, so motion exists on a *silent* page. This is the unlock
   for scrollable audio artifacts.
5. Then (b) the nine-instrument room and (c) the artistic visualiser, both in
   Three.js (`app/javascript/scenes/`, pinned `three` 0.186).
