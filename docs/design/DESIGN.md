# AI Pop Music - Design System

Design tokens and rules for this application. Tailwind is the implementation; this file is
the authority. Where a template and this file disagree, this file wins and the template is
wrong.

Read this before building or reviewing any UI, together with the `impeccable` and
`web-design-guidelines` skills.

---

## 1. Direction

**A small record label's catalogue, not a music-streaming app.**

The reference feeling is a printed label sleeve and a well-set liner-notes page: typographic,
confident, restrained, with one loud accent used sparingly. The audio player is the only
element allowed to draw the eye.

Three rules that keep it there:

1. **Type does the work.** No decorative imagery, no glow, no gradient mesh. Hierarchy comes
   from scale and weight.
2. **Metadata is visible and mono.** BPM, key, duration, genre, seed and model are set in
   monospace, the way a liner note lists credits.
3. **Colour is used once per screen.** The accent marks the primary action and the play
   control. Nothing else.

## 2. Colour tokens

Defined as CSS custom properties in `app/assets/tailwind/application.css` and surfaced to
Tailwind as theme colours. Never hard-code a hex value in a view.

| Token | Value | Use |
|---|---|---|
| `--color-ink-950` | `#0B0B0D` | Page background (dark sections), primary text on paper |
| `--color-ink-800` | `#17171B` | Raised surfaces on ink |
| `--color-ink-600` | `#3A3A42` | Borders on ink, secondary text on ink |
| `--color-ink-400` | `#6E6E78` | Muted text |
| `--color-paper-50` | `#FAF9F7` | Page background (default), text on ink-950 |
| `--color-paper-100` | `#F1EFEA` | Subtle fills, table striping |
| `--color-accent` | `#D8FF3E` | Primary action, play control, active nav. **Once per screen.** |
| `--color-accent-ink` | `#0B0B0D` | Text on accent |
| `--color-danger` | `#E5484D` | Destructive actions, error text |
| `--color-warn` | `#B7791F` | Warnings, `past_due` subscription state |
| `--color-ok` | `#2F855A` | Success, `active` state |

Rules:

- The accent is never used for body text, borders, or large fills except the single primary
  button per screen.
- Colour is never the only signal. Status is colour **and** a word.
- Contrast: body text meets WCAG AA (4.5:1) against its background. The accent on ink-950 is
  for large text and controls only.

## 3. Typography

| Role | Family | Notes |
|---|---|---|
| Display / headings | A high-contrast serif, self-hosted | Uses: page titles, track titles, plan names. Weights 400 and 600 only. |
| UI / body | System sans stack | Everything else. Never below 14px. |
| Metadata | Monospace stack | BPM, key, duration, slug, seed, model id, invoice amounts. |

Scale (rem): `0.75 / 0.875 / 1 / 1.125 / 1.5 / 2 / 2.75 / 3.5`

- Line height: 1.1 for display, 1.5 for body, 1.35 for UI.
- Measure: body text capped at 68 characters.
- No letter-spacing tricks except uppercase metadata labels, which get `0.08em`.
- Headings are sentence case. No title case, no all-caps headings.

## 4. Space, radius, borders

- Spacing scale: 4px base (`4 8 12 16 24 32 48 64 96`). Never use arbitrary values.
- Radius: `2px` for controls and cards. This is an editorial system, not a bubbly one.
  Pills (`9999px`) exist only for status chips and tags.
- Borders: 1px, `ink-600` on dark, `paper-100`-adjacent on light. **Borders before shadows.**
- Elevation: at most one shadow definition (`0 1px 2px rgba(0,0,0,.06)`), used for overlays
  and dropdowns only. Cards are not shadowed.

## 5. Motion

- Durations: 120ms for state changes, 240ms for enter/exit, 400ms for a deliberate reveal.
- Easing: `cubic-bezier(.2,.8,.2,1)` for entry, linear only for progress bars.
- Motion must convey state. Nothing animates on scroll for decoration.
- `prefers-reduced-motion: reduce` disables transforms and non-essential transitions.
- Audio never autoplays with sound. Playback is always user-initiated.

## 6. Components

- **Track row**: title (serif), genre + BPM + key + duration (mono, muted), play button,
  download affordance (visible only when entitled, otherwise "Subscribe to download").
- **Player**: one persistent player element. Never two players that can sound at once;
  starting a second preview stops the first.
- **Plan card**: name, price, genre limit, what it includes, one primary action.
- **Status chip**: `active`, `past_due`, `canceled`, `awaiting_payment` - always paired with
  an icon-free plain word.
- **Empty states**: state what is missing and the next action. Never a shrug illustration.

## 7. Banned patterns

Do not ship any of these:

- Neon glow, gradient meshes, glassmorphism, dark-mode-by-default "AI tool" aesthetics.
- Animated waveform decorations that do not represent real audio.
- Emoji in UI chrome or headings.
- Stock imagery of brains, circuits, headphones-on-a-desk, or glowing orbs.
- Fake scarcity ("3 spots left"), countdown timers, or invented testimonials and artist names.
- Silent autoplay with sound; audio that plays when a page loads.
- Paywall dark patterns: hiding the price, hiding the license terms, or a cancel flow that
  takes more steps than signup.
- Rounded-everything (`rounded-3xl` on every surface) and drop shadows on flat cards.
- Text over imagery without a contrast-guaranteed backing.
- Em-dashes in copy. Use hyphens.

## 8. Accessibility

- Every interactive element is reachable and operable by keyboard, with a visible focus ring
  (`2px` accent outline, offset 2px).
- The player is a real `<audio>` element with labelled controls; no custom control surface
  that drops keyboard support.
- Colour contrast meets AA; status is never conveyed by colour alone.
- Forms: labels are always visible (never placeholder-as-label), errors are announced, and
  the error message says what to do next.
- Touch targets are at least 44x44px.
