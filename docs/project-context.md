# AI Pop Music - Project Context

> **This is the overlay file.** `gems.md` and `skills.md` were written for **Follica**, a
> medical-tourism coordination platform. AI Pop Music borrows that project's *engineering
> discipline* - dependency restraint, database-level integrity, transactional writes,
> tested authorisation, deliberate design - but it is a **different product**.
>
> Where the Follica base and this file disagree, **this file wins.** The base files are not
> edited to record the divergence; it is recorded here.

---

## 1. What AI Pop Music is

A subscription catalogue of AI-generated songs that independent creators can license for
their own content - videos, podcasts, streams, ads, games.

It is a **licensing business, not a streaming service.** The customer does not come here to
listen; they come to find a track that fits their project, confirm they are allowed to use
it, and download it.

Three consequences follow, and they shape the whole application:

1. **The catalogue is the product.** Browsing, previewing and searching must be excellent,
   because that is the customer's actual job.
2. **Rights are the promise.** Every download must be traceable to a license version and an
   active entitlement. "Can I use this?" is the question the site exists to answer.
3. **Local generation is the supply chain.** Songs are produced on one owned GPU with YuE2,
   not bought from a third-party API.

## 2. Positioning

The category norm for AI music tools is neon gradients, glowing waveforms, "unlimited
royalties-free music" shouted at the top of the page, and a pricing table designed to be
misread. AI Pop Music does the opposite: it presents as a **small, credible record label
with a clear license.**

- **Catalogue over promises.** Genres, tracks, durations, keys, BPM, moods - real metadata,
  not adjectives.
- **The license stated once, plainly.** What a subscription grants is written on one page
  and linked from every download.
- **No fake scarcity.** No countdown timers, no "3 seats left", no invented testimonials.

The name is deliberately plain: *AI Pop Music* says what it is. The design carries the
credibility the name does not.

## 3. Deliberate divergences from the Follica base

| Follica base | AI Pop Music | Why |
|---|---|---|
| Razorpay is the only payment provider (§2 rule 16) | **No payment provider in v1.** Orders are created in `awaiting_payment` and the subscription domain ships with gateway plug points. | Checkout mechanics are a product decision that has not been made. The domain is built to the transactional standard so a gateway drops into existing plug points. |
| HIPAA / PHI compliance is a first-class concern | **Not applicable.** No clinical data, no health inferences. | Different industry. The privacy posture is ordinary SaaS care, not regulatory. |
| Medical-tourism integrations: ABDM, MSG91, WhatsApp Cloud API, Daily.co, Pipecat, FullCalendar, Leaflet, Duffel, insurance, villas | **Not installed.** | No equivalent need here. |
| Devise + devise-two-factor for doctors and admin | **Devise for customers. No 2FA in v1.** | Admin 2FA is a deferred follow-up, not a silent omission. |
| Meilisearch self-hosted on our own server | **Meilisearch as a project-local binary**, run from `.tools/` and proxied through Rails so no key reaches the browser. | Docker Desktop's WSL integration is not enabled on this machine. Functionally equivalent. |
| Bundler + Bun for JavaScript | **Importmap only. Bun is not installed.** | The app ships no bundled JavaScript; Tailwind is built by `tailwindcss-rails`. |
| RSpec (per `gems.md` §15) | **RSpec retained.** | The `rails-conventions` skill says Minitest and forbids factory gems. `gems.md` is the declared dependency authority and this project's tooling is RSpec. Recorded as a deliberate, reasoned deviation. |
| Clinical/PHI skills in `skills.md` (HIPAA, ABDM, clinical documents) | **Not applicable.** | See section 7. |

**Everything else in `gems.md` still applies**: Rails 8 built-ins before gems, dependency
restraint, database-level constraints, transactional and idempotent writes, Pundit on every
action, expand/contract migrations, CI gates.

## 4. Actors

| Actor | Can |
|---|---|
| **Visitor** | Browse genres, play previews, search, read the license page, see plans, start a subscription request |
| **Member** | Everything a visitor can, plus: download licensed tracks in entitled genres, manage the subscription, see download history, manage consent and data requests |
| **Editor** | Manage genres, tracks, prompts and catalogue content in admin |
| **Admin** | Full operational access, including plans, subscriptions, orders, generation batches, and publishing |

Authorisation is Pundit, server-side, on every action. Default deny. Hiding a link is never
authorisation.

## 5. The subscription model

Fixed tiers, not per-genre line items:

| Plan | Price | Genres |
|---|---|---|
| Starter | $5 / month | 1 genre |
| Pro | $15 / month | 3 genres |
| Studio | $50 / month | 10 genres |

A subscription grants `GenreEntitlement` rows - one per chosen genre - and the plan's
`genre_limit` caps how many can exist. Entitlements, not plans, are what a download checks.

Prices and limits are **data, not code** (`plans` table), so tiers change without a deploy.

## 6. The generation pipeline

Songs are produced locally with **YuE2** (m-t-a-p/YuE2-3B) through **ComfyUI**, which runs on
the Windows host at `D:\Installed Apps\ComfyUI`. The Rails app drives ComfyUI's HTTP API.

```text
Admin creates a GenerationBatch (genre + style/lyrics prompt + count)
        ↓
GenerationRun rows (one per song), queued on the `gpu` queue
        ↓
GenerationRunJob → POST /prompt  → ComfyUI (YuE2 workflow)
        ↓  poll /history, fetch /view
Track (draft) with audio + artwork attached, score and metadata recorded
        ↓
Editor reviews, writes metadata, publishes
```

Hard rules:

- **Concurrency 1 on the GPU queue.** The machine has a single 6 GB RTX 4050. Two
  concurrent YuE2 runs do not fit; they thrash and fail.
- **Low-VRAM settings are deliberate**: FP8 autoregressive weights (Ada Lovelace supports
  them), AR-stage offload, tiled decode.
- **Failures are data.** A failed run keeps its error and timings; it is never silently
  dropped, because generation cost is the main cost of this business.
- **ComfyUI is not a source of truth.** It is a machine we send work to. All state lives in
  Postgres.

### License gate (open item)

YuE2's weights are **CC BY-NC 4.0 with an additional individual-creator permission**: an
individual creator may monetise outputs, but *commercial use of the model weights by a
company* requires a commercial license from the model authors. A subscription business that
generates at scale looks like company use.

This is **an accepted, documented risk to be resolved before public launch** - either by
obtaining a commercial license, or by operating the generation under the individual-creator
terms. It must be visible in the release checklist, not buried.

## 7. Skills that do not apply

From `skills.md`, the following are medical-industry skills with no use here: the
HIPAA/PHI compliance skill, ABDM/check-in token guidance, clinical document generation, and
the clinic/patient-specific routing examples. The corpus still lives at `.skills-mcp/`, and
the applicable skills (Rails conventions, Context7, design and review skills, Playwright,
security audit, scraping, SEO) are used normally.

## 8. Content rules

- **Never invent facts.** No fabricated artists, biographies, statistics, certifications,
  licenses, or prices. A generated track's metadata must come from the run that produced it.
- **Seed data is synthetic and labelled as such.** Demo genres, demo tracks (from real local
  runs or obvious placeholders), demo plans. Nothing in the seed set may look like a real
  artist's catalogue.
- **No unlicensed audio ever.** Do not attach third-party music. Generated or silence only.
- Copy uses hyphens, not em-dashes.
