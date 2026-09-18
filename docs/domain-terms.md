# AI Pop Music - Domain Terms

Canonical vocabulary. **One term per concept, everywhere** - code, database, UI copy, specs,
commits, and conversation.

Spelling is US English throughout (`license`, not `licence`), because Ruby and Rails
ecosystems are US English and a mixed codebase reads as careless.

---

## Catalogue

**Genre**
A catalogue category and the unit of subscription. `Genre` in code, "genre" in the UI.
Never *category*, *style*, or *tag* for this concept. (A track's free-text descriptor is a
**mood**, not a style.)

**Track**
One song as a catalogue record: audio, artwork, metadata, license status. `Track` in code,
"track" in the UI. *Song* is acceptable in marketing prose only; it is never a model name,
route, or column.

**Preview**
The short public excerpt of a track (opening 20-30 seconds). Always public, always
watermark-free, never downloadable as a file. Never *sample* - that word means audio
sampling and is ambiguous in this domain.

**Master**
The full-length audio file. Private. Only ever delivered through an entitled download.
Never *full track file* or *original*.

**Artwork**
The square cover image attached to a track or genre.

**Mood**
A short free-text or enumerated descriptor for browsing ("uplifting", "melancholic").
Not a subscription unit.

**BPM**, **Key**, **Duration**
Technical track metadata. Shown in mono type in the UI. Sourced from the generation run,
never invented.

---

## Commercial

**Plan**
A fixed subscription tier (Starter, Pro, Studio) with a price and a genre limit.
`Plan` in code. Never *package*, *tier*, or *product* in code - *tier* is acceptable in
marketing prose.

**Subscription**
A member's recurring agreement to a plan: status, billing period, and which genres it
unlocks. `Subscription` in code.

**Entitlement**
The grant of access to exactly one genre under a subscription. `GenreEntitlement` in code.
An entitlement - not the subscription, and not the plan - is what a download checks. This
indirection is deliberate: it is what makes "which genres am I paying for?" answerable.

**Order**
A single commercial request for a plan, with an amount and a status. In v1 orders sit in
`awaiting_payment`; a gateway later moves them to `paid`. `Order` in code, "order" in the UI.

**License**
The terms under which a downloaded track may be used by the customer. Versioned
(`license_terms_version`); every download records the version it was granted under.
Capital-L *License* for the concept in prose; `license_` as the column prefix.

**Download**
A recorded act of a member retrieving a master. Written to `TrackDownload` with the user,
track, license version, and time. "Download" is both the action and the noun.

**Member**
An authenticated customer with an account. `User` in code (Devise), "member" in UI copy.
Never *subscriber* in code - a member may have no active subscription.

---

## Generation

**Prompt**
The style text and lyrics that drive a generation. Not *brief*, not *input*.

**Score** (ABC)
YuE2's symbolic melody-and-chord plan, in ABC notation. Stored on the track as `abc_score`.
Also called the *plan* in YuE2's own documentation - this project calls it the **score** to
avoid collision with subscription `Plan`.

**Generation batch**
An admin-authored request to produce N tracks for a genre from one prompt template.
`GenerationBatch` in code.

**Generation run**
One attempt to render one track through ComfyUI. `GenerationRun` in code. Carries the
ComfyUI prompt id, status, timings, and any error. A batch has many runs.

**Seed**
The integer that makes a generation reproducible. Recorded per run, per track.

**ComfyUI**
The local inference server that executes the YuE2 workflow. An external machine, never a
source of truth.

---

## Content & platform

**Page**
A static, editor-managed page (about, terms, license page).

**Post**
A blog entry. Not *article* - that word is reserved for nothing in this project, so it stays
free rather than becoming a synonym for *post*.

**Redirect**
A stored old-path to new-path mapping, used when slugs change.

**Consent record**
An append-only record that a subject granted or withdrew a specific consent kind.

**Data request**
A member-initiated export or deletion request.
