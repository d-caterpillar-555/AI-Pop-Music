# AI Pop Music

A subscription catalogue where creators license AI-generated songs, organised by genre.

Songs are generated locally with **[YuE2](https://github.com/multimodal-art-projection/YuE)** through
**ComfyUI**, published after an editor reviews them, and downloaded by subscribers under a
licence that is recorded at the moment of download.

**Status: v1.** The website is complete and verified; the generation pipeline is wired but has
not yet produced a track (the YuE2 models are still downloading).

---

## What it does

- **Catalogue** — genres and tracks with real metadata (tempo, key, duration, mood), public
  previews, and search.
- **Subscriptions** — fixed tiers (Starter 1 genre / Pro 3 / Studio 10), each granting
  entitlements to specific genres.
- **Downloads** — full-length 48 kHz masters, gated by entitlement, never served from a public
  storage URL, and recorded in an append-only licence table with the terms version in force.
- **Admin** — Avo, gated to staff, including a one-click queue for generation batches.
- **Accounts** — subscription management, download history, orders, consent records, and
  data export/deletion requests.

## Requirements

- WSL2 Ubuntu with Ruby 3.4.10 available through [`mise`](https://mise.jdx.dev)
- PostgreSQL 18 installed (the server binaries are used by `bin/pg`)
- No Docker required

## Getting started

```bash
bin/pg setup                  # initialise the project-local cluster on 5434 and create the databases
cp .env.example .env
mise exec -- bundle install
mise exec -- bin/rails db:prepare
mise exec -- bin/rails db:seed
mise exec -- bin/dev          # http://localhost:3000
```

Seed accounts (development only): `admin@example.com`, `editor@example.com`,
`member@example.com` — password `password1234`.

The database lives inside the project at `.postgres/`, on port **5434** so it cannot collide
with the system cluster (5432) or a sibling project's cluster (5433).

## Verification

```bash
mise exec -- bundle exec rspec      # 88 examples
mise exec -- bundle exec rubocop    # no offenses
mise exec -- bundle exec brakeman   # no security warnings
mise exec -- bundle exec bundler-audit check --update
./script/db-verify                  # proves 25 database constraints actually fire
```

`script/db-verify` is the one worth knowing about: it attempts real constraint violations
inside transactions, rolls them back, and reports any violation the database *accepted*. It
catches the failure mode where a constraint exists on paper but not in practice.

## How songs are made

```text
GenerationBatch (admin: genre + prompt + count)
      ↓
GenerationRunJob on the `gpu` queue — concurrency 1, one render per GPU
      ↓  POST /prompt → ComfyUI → poll /history → GET /view
Track (draft, audio attached, prompt and seed recorded)
      ↓
Editor reviews, writes metadata, publishes
```

The machine has a single 6 GB GPU, so the workflow runs FP8 autoregressive weights with
AR-stage offload and tiled decoding, and `limits_concurrency` guarantees only one render at a
time no matter how many tracks are queued.

ComfyUI runs on the Windows host; from WSL it must be started with `--listen 0.0.0.0` and
`COMFYUI_URL` pointed at the host address.

## Documentation

| File | Purpose |
|---|---|
| `AGENTS.md` | Canonical context order and non-negotiables for agents |
| `gems.md` | Dependency authority — what may be added and why |
| `skills.md` | Skill routing map (retrieve, don't preload) |
| `docs/project-context.md` | The product overlay: what this is, and where it diverges from the base |
| `docs/domain-terms.md` | One term per concept, everywhere |
| `docs/design/DESIGN.md` | Design tokens and banned patterns |

## Licensing note

YuE2's model weights are licensed **CC BY-NC 4.0 with an additional individual-creator
permission**. An individual creator may monetise generated outputs; commercial use of the
weights by a company requires a commercial licence from the model authors. This is recorded in
`docs/project-context.md` as a release gate, not a detail.

Generated output itself carries no NonCommercial restriction.
