# Follica --- Gems & Technology Master Guide

## Rails 8 Doctor/Clinic ↔ Patient Platform

**Status:** Architecture baseline\
**Purpose:** Single source of truth for developers and AI coding
agents.\
**Rule:** Do not add a gem because it is popular. Add it only when this
guide says it is part of the baseline or the feature that requires it is
being built.

------------------------------------------------------------------------

# 1. System Architecture

## Backend

-   **Ruby on Rails 8**
-   Authentication: **Devise**
-   Authorization: **Pundit**
-   Admin panel: **Avo**
-   Background jobs: **Solid Queue** (Rails 8 default)
-   Database: **PostgreSQL**
-   Search: **Meilisearch**, self-hosted on our own computer/server,
    **not Meilisearch Cloud**
-   File storage: **Rails Active Storage + S3-compatible storage**
    unless CarrierWave is explicitly required by an implementation
-   Email: **Resend**
-   SMS/phone OTP: **MSG91**
-   WhatsApp: **Meta Cloud API**
-   Monitoring: **Sentry**
-   Audit history: **PaperTrail**
-   Frontend interaction: **Hotwire (Turbo + Stimulus)**
-   Styling: **Tailwind CSS**
-   Package manager: **Bun** for JavaScript packages
-   Ruby dependencies: **Bundler**

## Mobile

-   **Hotwire Native**

## External services / integrations

-   Calendar: **FullCalendar**
-   Maps: **Leaflet.js + OpenStreetMap**
-   Video: **Daily.co + Pipecat**
-   Flights: **Aviationstack or Duffel**
-   Flight affiliation/booking: **Duffel / Skyscanner / Travelpayouts**,
    subject to commercial/API eligibility
-   Travel insurance: **Ekta / IMG Global / VisitorsCoverage**
-   Villa/travel inventory: **Agoda**, subject to partner/API
    availability
-   Dataset/reference: **ABDM**
-   Test dataset/source: **Kaggle**

## Deployment candidates

Primary preference: - **Coolify** on Oracle Cloud Free Tier /
DigitalOcean / Linode

Alternative managed platforms: - **Render** - **Koyeb**

------------------------------------------------------------------------

# 2. Core Architecture Rules

1.  PostgreSQL is the authoritative application database.
2.  Meilisearch is a search index, never the source of truth.
3.  Meilisearch is self-hosted. Do not introduce Meilisearch Cloud
    unless explicitly approved.
4.  Rails 8 Solid Queue is the default job backend. Do not add Sidekiq
    unless a concrete requirement justifies it.
5.  Rails native Active Storage is preferred for uploads unless a
    concrete CarrierWave requirement exists.
6.  Do not install multiple libraries that solve the same problem.
7.  Do not use PgSearch for application search. Use Meilisearch.
8.  Do not use Searchkick. Elasticsearch/OpenSearch is not part of the
    current search architecture.
9.  Use Pundit for authorization. Do not add CanCanCan.
10. Use Avo for the internal admin panel. Do not add ActiveAdmin unless
    a specific Avo limitation is documented.
11. Use Rails 8 built-ins before adding a gem.
12. Every external API integration must have error handling, timeouts,
    retries where appropriate, logging, and tests.
13. Never put API keys, passwords, tokens, or private keys in source
    control.
14. Patient/clinical data must receive stricter access controls than
    ordinary public content.
15. Never expose private patient documents through public URLs.
16. **Razorpay is Follica's only payment provider — this is final.**
    Do not add Stripe, Braintree, Paddle, or a multi-processor
    abstraction gem (e.g. `pay`) for any reason, including "just in
    case," a watch-list mention, or a future-proofing argument.
    Reopening this requires an explicit, documented, human-approved
    architecture change — not an agent inference from a feature
    request. See Section 20 for implementation rules.
17. A Rails model validation is a UX nicety, not a data-integrity
    guarantee — it can be bypassed by console access, a race condition,
    direct SQL, or a bug in a different code path. Every constraint
    that must actually hold (uniqueness, required associations,
    referential integrity) is enforced at the database level as well.
    See Section 14A.

Uploads are untrusted input. Validate content type, file size, and image
dimensions at the application/model layer before processing or displaying
attachments.

------------------------------------------------------------------------

# 3. Baseline Gemfile

Start with this baseline and add conditional gems only when their
feature is actually implemented.

``` ruby
source "https://rubygems.org"

gem "rails", "~> 8.0"
gem "pg"
gem "puma"

# Authentication / authorization
gem "devise"
gem "devise-two-factor"
gem "pundit"

# File validation
gem "active_storage_validations"

# Search
gem "meilisearch-rails"

# Pagination / URLs
gem "pagy"
gem "friendly_id"

# Forms
gem "simple_form"

# Admin
gem "avo"

# Payments
gem "razorpay"

# Email
gem "resend"

# Monitoring / audit
gem "sentry-rails"
gem "paper_trail"

# Soft deletion
gem "discard"

# Security
gem "brakeman", require: false
gem "bundler-audit", require: false

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "pry-rails"
  gem "rubocop", require: false
  gem "annotate"
  gem "rails-erd"
end

group :development do
  gem "bullet"
  gem "letter_opener"
end

group :test do
  gem "capybara"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "vcr"
  gem "webmock"
end
```

### Important

The baseline intentionally does **not** include:

-   Sidekiq
-   Redis
-   PgSearch
-   Searchkick
-   CarrierWave
-   MiniMagick
-   ActiveAdmin
-   Figaro
-   Guard
-   Rack::Attack
-   Lockbox
-   Kafka
-   Memcached/Dalli
-   Kaminari (replaced by Pagy — see Section 8)

Those are discussed later as conditional/rejected choices.

------------------------------------------------------------------------

# 4. Installation

## 4.1 Create the Rails application

``` bash
gem install rails
rails new follica -d postgresql
cd follica
```

If the project already exists, do not recreate it.

Check:

``` bash
ruby -v
rails -v
bundle -v
```

## 4.2 Install Ruby dependencies

After putting the approved Gemfile in place:

``` bash
bundle install
```

The safest project-level installation method is the Gemfile + Bundler
workflow.

Individual gems can also be added with:

``` bash
bundle add devise
bundle add pundit
bundle add meilisearch-rails
bundle add avo
```

Do not manually `gem install` every dependency when working inside the
application. Bundler must own the project's dependency graph.

## 4.3 Rails setup

``` bash
bin/rails db:create
bin/rails db:migrate
bin/rails server
```

## 4.4 Install/initialize major components

Devise:

``` bash
bin/rails generate devise:install
```

Avo:

``` bash
bundle exec avo install
```

Meilisearch:

``` bash
bin/rails meilisearch:install
```

Then configure the self-hosted Meilisearch URL and key using environment
variables / Rails credentials.

Do not commit the Meilisearch master/admin key.

## 4.5 JavaScript / frontend packages

Bun is the JavaScript package manager:

``` bash
bun install
```

Use Bun for JavaScript dependencies and scripts. Do not introduce
npm/yarn/pnpm unless a dependency specifically requires it and the team
approves the exception.

------------------------------------------------------------------------

# 5. Updating Gems Safely

## Check outdated dependencies

``` bash
bundle outdated
```

## Update one gem

Preferred when changing one dependency:

``` bash
bundle update <gem_name>
```

Example:

``` bash
bundle update devise
```

## Update a controlled group

``` bash
bundle update meilisearch-rails avo
```

Do not routinely run:

``` bash
bundle update
```

on production applications without reviewing the dependency changes.

## After an update

Run:

``` bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman
bundle exec bundler-audit
```

Then run the application/system tests.

Review:

``` text
Gemfile.lock
CHANGELOG / release notes
database migrations
deprecation warnings
```

## Rails upgrades

Do not treat a Rails upgrade like an ordinary gem update.

For example:

``` bash
bundle update rails
```

should be followed by:

``` bash
bin/rails app:update
```

only after reviewing the generated changes.

Test the complete application before deployment.

------------------------------------------------------------------------

# 6. Agent Dependency Decision Rule

Before adding any gem, the coding agent must ask:

1.  Does Rails 8 already provide this?
2.  Is an approved gem already providing it?
3.  Does the feature genuinely require another dependency?
4.  Does the gem support our Rails/Ruby versions?
5.  Is it actively maintained?
6.  Does it introduce infrastructure we do not otherwise need?
7.  Does it duplicate an existing library?
8.  Does it create a security/privacy concern?
9.  Can the feature be implemented more simply with existing Rails code?

If the answer shows duplication, do not install the gem.

------------------------------------------------------------------------

# 7. Authentication & Authorization Gems

## Devise --- MUST INSTALL

**Purpose:** Authentication for Patient, Doctor, Admin and other
authenticated accounts.

Use for: - registration - login - logout - password reset - email
confirmation - account state - session authentication

Agent rule: - Never hand-roll password/session logic when Devise already
provides the required functionality. - Keep authentication separate from
authorization.

------------------------------------------------------------------------

## Devise Two Factor --- MUST INSTALL

``` ruby
gem "devise-two-factor"
```

**Purpose:** TOTP-based 2FA.

Use primarily for: - Admin - Doctor/clinic staff - privileged
operational accounts

Patient 2FA can be optional depending on the final UX/security decision.

Agent rule: - Never store raw TOTP secrets in plaintext. - Require
stronger authentication for privileged actions.

------------------------------------------------------------------------

## Pundit --- MUST INSTALL

**Purpose:** Authorization and policy enforcement.

Use for: - patient access to their own records - doctor access to
assigned patients - clinic access to clinic-owned data - villa-owner
access to owned villas - admin privileges

Agent rule: - Create policies per protected resource. - Use
`authorize`. - Do not scatter role checks through controllers.

------------------------------------------------------------------------

# 8. Search & Data Discovery

## Meilisearch Rails --- MUST INSTALL

``` ruby
gem "meilisearch-rails"
```

**Purpose:** Application search.

Use for: - clinic search - doctor search - villa search - package
search - location/search-as-you-type - typo-tolerant search

Architecture:

``` text
PostgreSQL
    ↓
Rails
    ↓
Meilisearch indexing
    ↓
Search UI
```

PostgreSQL remains authoritative.

Agent rule: - Never use Meilisearch as the database. - Do not use
PgSearch for the same search features. - Use background jobs where
indexing should not block the user request. - Define searchable,
filterable and sortable attributes deliberately. - Never index private
patient data into a public search index.

------------------------------------------------------------------------

## Pagy --- MUST INSTALL (replaces Kaminari)

**Purpose:** Pagination.

Kaminari is dropped from the baseline: it has had no release in over
three years, while Pagy is actively maintained, allocates roughly 30x
fewer objects per page render, and ships native Turbo Frame/Stream
helpers with prebuilt Tailwind templates — a direct fit for Follica's
Hotwire + Tailwind stack. On a platform that needs to keep serving
appointment/booking traffic under load, an unmaintained pagination gem
in the baseline is itself a risk, independent of the performance gap.

Use for: - admin lists - appointment history - clinic lists - doctor
lists - large database-backed index pages

``` ruby
gem "pagy", "~> 43"
```

``` ruby
# config/initializers/pagy.rb
require "pagy/extras/limit"     # if user-controlled page size is needed

# ApplicationController
include Pagy::Method
```

``` ruby
# before (Kaminari)
@doctors = Doctor.page(params[:page]).per(20)

# after (Pagy)
@pagy, @doctors = pagy(:offset, Doctor.all, limit: 20)
```

Do not confuse database pagination (Pagy) with Meilisearch's
search-result pagination — they are separate concerns and Pagy does not
replace or wrap Meilisearch's own pagination.

------------------------------------------------------------------------

## FriendlyId --- MUST INSTALL

**Purpose:** Human-readable public URLs.

Use for: - clinic profiles - doctor profiles - villas - public packages

Example:

``` text
/clinics/radiant-roots
```

Do not expose sensitive patient identifiers in slugs.

------------------------------------------------------------------------

## Ransack --- CAN INSTALL

Use only if a specific admin/search workflow requires advanced
ActiveRecord filtering.

Do not add it merely because ActiveAdmin previously used it. Avo is now
the selected admin framework.

------------------------------------------------------------------------

# 9. Admin

## Avo --- MUST INSTALL

``` ruby
gem "avo"
```

Avo is the selected admin panel instead of ActiveAdmin.

Reason: - Rails-native - Hotwire-based - Tailwind-based -
resource-oriented - customizable with normal Rails code - suitable for
CRUD and internal operations - works inside the existing application

Agent rule: - Use Avo for internal operational/admin CRUD. - Keep
patient-facing UI outside Avo. - Use Pundit/authorization policies for
sensitive resources. - Do not assume that because an admin can see a
model, every field should be visible. - Hide sensitive patient fields by
default. - Use custom Avo tools/actions only where a workflow requires
them.

## Pretender --- CAN INSTALL / SUPPORT

Use Pretender when authorized support/admin staff need to reproduce a
patient or doctor experience without knowing or changing that account
password.

Recommended use:

- Avo support workflows
- Reproducing account-specific UI/authorization problems
- Debugging appointment/booking issues from the affected user's view

Security requirements:

- Restrict impersonation to explicitly authorized admin roles.
- Require an intentional admin action to start impersonation.
- Show a persistent "Viewing as" indicator while impersonating.
- Provide an obvious exit/back-to-admin action.
- Audit who impersonated whom, when, and why.
- Do not allow impersonation to silently bypass Pundit authorization.
- Be especially careful with patient clinical data and destructive actions.

Environment restriction:

- Enable Pretender freely against staging/demo/seed data.
- Do not enable impersonation of any account with access to real,
  production patient records by default. Ship it disabled/gated for
  those accounts until a separate, explicitly justified, audit-logged
  design is reviewed against the HIPAA/PHI Compliance requirements in
  `skills.md`. "Pretender is installed" is not the same thing as
  "impersonation of PHI-holding accounts is approved."

Pretender is a support/debugging tool, not a replacement for Devise or
Pundit.

Potential admin areas:

``` text
Patients
Clinics
Doctors
Villas
Bookings
Appointments
Packages
Documents
Verification
Payments
Travel
Leads
Reviews
Audit history
System health
```

Avo is currently the preferred admin choice for this project.

------------------------------------------------------------------------

# 10. Email

## Resend --- MUST INSTALL

``` ruby
gem "resend"
```

**Purpose:** Transactional email.

Use for: - account verification - password reset - login/security
notifications - appointment confirmation - booking confirmation -
operational notifications

Agent rule: - Never send transactional email directly from a controller
if the operation can be queued. - Use Solid Queue for asynchronous
delivery. - Keep email templates version-controlled. - Store API keys in
credentials/environment variables.

Marketing email remains separate.

------------------------------------------------------------------------

# 11. Monitoring

## Sentry Rails --- MUST INSTALL

``` ruby
gem "sentry-rails"
```

**Purpose:** Production error monitoring.

Use for: - exceptions - failed external API calls - unexpected
background job failures - critical application errors

Agent rule: - Do not swallow exceptions just to make Sentry quiet. - Add
useful context without sending unnecessary patient/clinical data. -
Never put secrets into Sentry event metadata.

------------------------------------------------------------------------

# 12. Audit

## PaperTrail --- MUST INSTALL

**Purpose:** Version/audit history.

Use for important operational records where historical changes matter.

Potential models: - Patient - Doctor - Clinic - Appointment - Booking -
Villa - Verification - Payment

Agent rule: - Record who changed important data. - Do not assume every
low-value model needs unlimited version history. - Define retention
carefully. - Do not store sensitive plaintext values in audit logs if
they should be encrypted.

------------------------------------------------------------------------

# 13. Soft Delete

## Discard --- MUST INSTALL

**Purpose:** Safe logical deletion.

Use where records should not be physically destroyed immediately.

Potential examples: - clinic - doctor - villa - appointment - booking

Agent rule: - Do not automatically apply soft deletion to every table. -
Define whether a record is legally/business-required to remain. - Never
let discarded records accidentally appear in public search. - Remove
discarded records from Meilisearch indexes.

------------------------------------------------------------------------

# 14. Security

## Brakeman --- MUST INSTALL

Static Rails security analysis.

Run:

``` bash
bundle exec brakeman
```

Use in CI.

------------------------------------------------------------------------

## Bundler Audit --- MUST INSTALL

Dependency vulnerability scanning.

Run:

``` bash
bundle exec bundler-audit
```

Update the vulnerability database as appropriate.

------------------------------------------------------------------------

## Safe Migrations --- strong_migrations (CAN INSTALL) + online_migrations (CAN INSTALL)

Follica runs on PostgreSQL and is a 24/7 clinic platform: an
`ADD COLUMN ... DEFAULT` or a non-concurrent index on `patients` or
`appointments` can lock the table and take booking down mid-shift. Two
complementary gems address this at different points in the workflow:

- **strong_migrations** — catches unsafe migration patterns at
  development/CI time and raises before they ship.
- **online_migrations** — orchestrates the actual multi-step
  zero-downtime patterns in production (concurrent index creation,
  backfilling column defaults, adding foreign keys without a full table
  lock).

Use strong_migrations as the baseline linter and add online_migrations
once the team is running large-table migrations against production
data (patients, appointments, doctors, PaperTrail versions) rather than
during early schema iteration on an empty database.

------------------------------------------------------------------------

## Rack Attack --- CAN INSTALL

Do not install initially just because rate limiting exists.

Rails 8 has native controller-level `rate_limit`.

Add Rack::Attack if we need: - broad IP blocking - cross-controller
throttling - abuse rules - more complex request filtering

Agent rule: - Use native Rails rate limiting first. - Add Rack::Attack
only when the threat model requires it.

------------------------------------------------------------------------

## Lockbox --- CAN INSTALL

Rails has Active Record Encryption.

Use native:

``` ruby
encrypts :field
```

first.

Consider Lockbox only when a concrete requirement exists that Rails
encryption does not cover cleanly.

Do not encrypt everything blindly.

------------------------------------------------------------------------

## Encryption & Key Rotation --- required before production

Encrypting a field is not the whole job. Before any encrypted field
holds real patient data:

- Document, per field, which mechanism encrypts it (Active Record
  Encryption `encrypts` vs Lockbox) and why — do not let this be an
  implicit, undocumented per-model decision.
- Configure Active Record Encryption's key **rotation** support
  (`active_record_encryption.support_unencrypted_data` and multiple
  keys via `previous` in `config/credentials`) before launch, not
  after a suspected leak. Rotating a key you never planned to rotate,
  under incident pressure, is how re-encryption jobs corrupt data.
- Define a rotation cadence for external provider secrets too
  (Razorpay keys, Resend/Postmark API keys, MSG91, AWS IAM
  credentials, Meilisearch master key) — a fixed schedule (e.g.
  quarterly) plus immediate rotation on suspected compromise. "We'll
  rotate it if something happens" is not a plan; see Section 38A.
- Never log a decrypted value, and never send one to Sentry — check
  this explicitly whenever a new encrypted field is added (Sentry
  scrubbing config must know about it too, not just the logger).
- A key-rotation drill (rotate a non-critical key end-to-end in
  staging) should happen at least once before this is needed for real
  in production.

------------------------------------------------------------------------

# 14A. Database Integrity, Constraints & Concurrency

Rule 17 (Section 2) means every one of the following is a database
constraint, not only a model-level validation, wherever it must
actually hold:

## Required at the schema level

- `NOT NULL` on any column the application logic assumes is always
  present — not just `validates :field, presence: true`.
- A unique **index** (not just `validates_uniqueness_of`) on any column
  that must be unique — e.g. `patients.email`,
  `appointments (doctor_id, starts_at)` if double-booking the same
  slot must be structurally impossible. `validates_uniqueness_of`
  alone has a well-known race condition: two requests can both pass
  the Rails-level check before either commits.
- Foreign key constraints (`add_foreign_key`) on every `belongs_to`,
  so an application bug can't leave an `appointment` pointing at a
  deleted `doctor`.
- `CHECK` constraints for invariants the database can enforce cheaply
  — e.g. an appointment's `ends_at > starts_at`, a payment `amount > 0`.

## Concurrency / race conditions

Booking a slot and processing a payment are exactly the kind of
operation where "it worked in my manual test" hides a race condition
that only appears under real concurrent load:

- Use a DB-level unique index (above) as the actual source of truth
  for "this slot is taken," and handle the resulting
  `ActiveRecord::RecordNotUnique` as an expected, user-facing outcome
  ("that slot was just booked"), not an unhandled exception.
- For read-then-write sequences that must not race (e.g. "check
  remaining villa inventory, then decrement it"), use row-level
  locking — `with_lock` / `SELECT ... FOR UPDATE` — or an atomic
  `UPDATE ... WHERE quantity > 0` rather than a Ruby-level
  read-check-write.
- Use PostgreSQL advisory locks (`pg_advisory_lock` /
  `with_advisory_lock` via a gem, or raw SQL) for cross-request
  coordination that isn't naturally expressed as a row lock — e.g.
  serializing a specific doctor's slot-generation job.
- Optimistic locking (`lock_version` / `ActiveRecord::StaleObjectError`)
  is appropriate for admin/Avo edit conflicts where a human retrying is
  fine. It is not a substitute for the above on the booking/payment
  hot path, where the correct behavior is "reject the second attempt
  automatically," not "ask a human to retry."

Agent rule: when adding a new `belongs_to`, a new "must be unique"
requirement, or a new booking/inventory-decrement path, add the
migration-level constraint in the same PR as the model validation —
never ship the validation alone and treat the DB constraint as
follow-up work.

------------------------------------------------------------------------

# 14B. Transactions, Idempotency & Booking/Payment Workflow Rules

A booking + payment is a multi-step process (reserve slot → create
booking → create Razorpay order → charge → confirm) that must not be
allowed to leave the database in a half-finished state, and must not
double-charge or double-book on retry.

## Transactions

- Wrap the reserve-slot + create-booking step in a single
  `ActiveRecord::Base.transaction` — a slot must never be marked taken
  without a corresponding booking record existing, or vice versa.
- Do not perform external network calls (Razorpay order creation,
  sending a confirmation email) *inside* that same transaction — hold
  the DB transaction open only for the DB work, then make external
  calls after it commits, in a Solid Queue job. A slow/failed external
  call must never hold row locks open.
- Any batch operation running under `maintenance_tasks` that mutates
  patient/booking records follows the same rule: transactional at the
  DB-write step, not around external calls.

## Idempotency

- Every booking-creation endpoint must be idempotent against
  double-submit (this is the exact bug referenced in `skills.md`'s
  "patient booking double-submit" example). Use a client-generated
  idempotency key (stored, unique-indexed) or a DB-level unique
  constraint on `(patient_id, doctor_id, slot_id)` so a resubmitted
  form does not create a second booking.
- Razorpay webhook handlers must be idempotent: Razorpay retries
  delivery, so the same event ID can arrive more than once. Record
  processed webhook event IDs (unique-indexed) and no-op on a repeat
  before touching booking/payment state.
- Treat the webhook, not the client-side "payment succeeded" redirect,
  as the source of truth for payment status — this is already stated
  in Section 20; this section is what makes it concrete at the
  database/transaction level.

## Webhook replay & race conditions

- Verify the Razorpay webhook signature before doing anything else
  with the payload — an unverified webhook is untrusted input, full
  stop.
- Reject webhook payloads outside a reasonable timestamp window (where
  the provider supplies one) as a defense against replayed requests.
- Guard against the webhook and a concurrent user action (e.g. the
  patient cancelling the appointment) racing each other: reload the
  booking/payment row with a lock before applying the webhook's status
  change, don't blind-`update` based on a stale in-memory copy.

------------------------------------------------------------------------

# 14C. Query Performance & N+1 Rules

- Bullet (Section 15) must be clean — zero warnings — before a PR
  merges. A Bullet warning is not "fix later" debt; it's treated the
  same as a failing test in CI gating (Section 35B).
- No index/list view loads an un-paginated `Model.all` or
  `Model.where(...)` — every list-rendering controller action uses
  Pagy. This applies to Avo-adjacent custom views too, not only
  patient-facing pages.
- Association access in views/serializers/Avo resources uses explicit
  `.includes`/`.preload`/`.eager_load` — do not rely on incidental
  caching from an earlier query in the same request.
- Background jobs (Meilisearch indexing, PaperTrail version cleanup,
  `maintenance_tasks` batches) must not load full tables into memory —
  use `find_each`/`in_batches`, never `Model.all.each`.
- Do not "fix" an N+1 by blindly wrapping everything in
  `includes(:everything)` — over-eager-loading unused associations is
  its own performance problem. Match the eager-load to what the view
  actually renders.

------------------------------------------------------------------------

# 15. Testing

## RSpec --- MUST INSTALL

Primary Ruby/Rails testing framework.

Every meaningful feature should have tests.

------------------------------------------------------------------------

## Factory Bot --- MUST INSTALL

Test data factories.

Example:

``` ruby
create(:patient)
create(:doctor, :verified)
create(:clinic)
```

------------------------------------------------------------------------

## Capybara --- MUST INSTALL

Browser/system testing.

Use for: - registration - login - booking - appointment flows - admin
workflows where appropriate

Capybara-driven RSpec system specs are the permanent, CI-run regression
suite. This is separate from the **Playwright CLI** agent skill (see
`skills.md`), which the coding agent uses to drive the actual running
application interactively — bug reproduction, cross-browser/visual
checks, staging verification — rather than to write spec-suite coverage.
Do not treat the two as interchangeable or as a choice to make per task:
specs go in Capybara, live/ad hoc verification goes through Playwright
CLI.

------------------------------------------------------------------------

## Shoulda Matchers --- MUST INSTALL

Concise tests for: - validations - associations - model behavior

Do not use it as a replacement for behavioral tests.

------------------------------------------------------------------------

## SimpleCov --- MUST INSTALL

Test coverage.

Agent rule: - Coverage is a signal, not a vanity target. - Do not write
meaningless tests just to raise the percentage.

------------------------------------------------------------------------

## VCR --- CAN INSTALL

Use when external API interactions need deterministic recorded test
fixtures.

Good candidates: - flight APIs - insurance APIs - travel APIs

Do not record secrets or real patient information.

------------------------------------------------------------------------

## WebMock --- CAN INSTALL

Prevent tests from making accidental external HTTP requests.

Use together with VCR when appropriate.

------------------------------------------------------------------------

## Bullet --- MUST INSTALL

Development-time N+1 detection.

Use:

``` ruby
includes
preload
eager_load
```

when appropriate.

Never blindly add eager loading without understanding the query.

------------------------------------------------------------------------

## test-prof --- CAN INSTALL (development, test only)

``` ruby
group :test do
  gem "test-prof"
end
```

Use once the RSpec suite is slow enough to matter — a healthcare app
with a wide authorization matrix (Devise, Pundit, PaperTrail) tends to
accumulate cascading FactoryBot associations that quietly balloon test
runtime. test-prof diagnoses factory cascades, slow examples, and N+1
factory creation, before the suite becomes slow enough to bottleneck
CI.

Development/test group only — never a production dependency.

------------------------------------------------------------------------

# 15A. Authorization Test Matrix --- required for every resource

A Pundit policy existing is not the same as a Pundit policy being
tested. For every resource that has a policy (Patient, Doctor, Clinic,
Appointment, Villa, Booking, Payment, and every new one added later),
tests must cover the actual actor × action matrix — not just "an admin
can do it":

```text
For resource X, for each action (index/show/create/update/destroy
where applicable), test:

  Patient  → own record       → allowed (where applicable)
  Patient  → someone else's   → denied
  Doctor   → own record       → allowed (where applicable)
  Doctor   → someone else's   → denied
  Doctor   → a Patient's PHI  → denied unless an explicit
                                 clinical relationship grants it
  Admin    → any record       → allowed per documented admin scope
                                 (not blanket — see Section 38)
  Guest / unauthenticated     → denied
```

Agent rule:

- A new Pundit policy ships with a matching `spec/policies/*_spec.rb`
  covering the full matrix above for that resource, not only the
  happy path.
- A controller/request spec must assert that `authorize` was actually
  invoked for the action under test (Pundit's
  `Pundit::NotAuthorizedError`/`after_action :verify_authorized` should
  be enabled application-wide) — a controller silently missing an
  `authorize` call is a bypass, not a passing test.
- Default-deny is itself a tested behavior: a resource with no
  matching policy rule must deny, and there is a test proving that,
  not an assumption that Pundit's default handles it correctly.
- This matrix requirement applies in addition to, not instead of, the
  general Section 38 sensitive-data checklist.

------------------------------------------------------------------------

# 16. Development Tools

## RuboCop --- MUST INSTALL

Code style/linting.

Run:

``` bash
bundle exec rubocop
```

Agent rule: - Fix offenses. - Do not disable rules casually. - Document
deliberate exceptions.

------------------------------------------------------------------------

## Pry Rails --- CAN INSTALL

Interactive debugging.

Use:

``` ruby
binding.pry
```

during development.

Never leave debugging breakpoints in production code.

------------------------------------------------------------------------

## Annotate --- CAN INSTALL

Adds schema information to models.

Useful while the database schema is evolving.

------------------------------------------------------------------------

## Rails ERD --- CAN INSTALL

Useful for visualizing database relationships.

Particularly useful during: - schema design - review - onboarding -
architecture work

------------------------------------------------------------------------

## Letter Opener --- CAN INSTALL

Local development email preview.

Use instead of accidentally sending development emails to real users.

------------------------------------------------------------------------

## Guard --- DO NOT INSTALL BY DEFAULT

It was discussed previously, but it is not necessary for the baseline.

Use modern test/lint commands or editor tooling.

------------------------------------------------------------------------

# 16A. Dependency & Version Verification Rules

This document previously contained a real, resolved instance of the
failure mode this section exists to prevent: a reviewer flagged
`gem "pagy", "~> 43"` as an invented version number, on the reasonable
assumption that Pagy's versioning was still in the single digits.
Direct verification against the live RubyGems listing showed 43.x is
genuinely the current, actively-published major line (a deliberate
"leap version" the maintainer chose on purpose). The pin was correct;
the assumption was stale. Both directions of this mistake are real
risks — inventing a version, and "correcting" a real one back to a
remembered-but-outdated one — and this section exists to stop either
from reaching the Gemfile.

Agent rule:

- Before adding, pinning, or changing a gem version in this document
  or in code, verify the current real version against
  **rubygems.org** (or `bundle info <gem>` / `gem list <gem> --remote`
  in the actual project environment) rather than relying on trained/
  memorized knowledge. Training data goes stale; a gem's versioning
  scheme, module API (see the Pagy `Pagy::Method` example in Section
  8), and even its maintenance status can all change after any
  knowledge cutoff.
- When retrieving current library/API documentation, use the
  **Context7** skill (see `skills.md`) rather than writing code
  against a remembered API shape — this applies especially to gems
  that have had a major-version jump.
- Do not "round-trip" a version pin back to what looks more familiar
  just because it looks more plausible. Plausibility is not evidence;
  the published version list is.
- If bundler actually fails to resolve a version pin in this document,
  that is a signal to re-verify against rubygems.org before editing
  the pin — a real resolution failure and a reviewer's stale
  assumption produce the same symptom ("this version seems wrong") but
  require opposite fixes.
- Before recommending a new gem at all, confirm it is still maintained
  (recent commits/releases, not just an old high download count) —
  the earlier stack-review already applied this check to the current
  baseline (e.g. ruling Kaminari out for exactly this reason); apply
  the same check to anything proposed later.

------------------------------------------------------------------------

# 17. Rails 8 Built-ins --- DO NOT ADD GEMS

Rails 8 already provides important functionality.

Do not add duplicate libraries for:

-   Solid Queue
-   Solid Cache
-   Solid Cable
-   Active Record Encryption
-   Propshaft
-   Active Storage
-   Turbo
-   Stimulus
-   ActiveJob
-   native controller `rate_limit`
-   Rails credentials
-   Active Record enums
-   concerns
-   `try`
-   `touch`
-   time zone support
-   Rails inflection

------------------------------------------------------------------------

# 18. Background Jobs

## Solid Queue --- DEFAULT

Use Rails 8 Solid Queue.

Use for: - email sending - Meilisearch indexing - appointment
reminders - document processing - cleanup - notification delivery -
flight/travel API synchronization - villa availability synchronization

Agent rule: - Jobs must be idempotent where practical. - External calls
require timeouts and retry strategy. - Do not enqueue sensitive payloads
unnecessarily. - Do not switch to Sidekiq without a documented reason.

## Mission Control Jobs --- CAN INSTALL

``` ruby
gem "mission_control-jobs"
```

Use if the team needs a web UI for: - inspecting jobs - retrying jobs -
diagnosing failures

## Maintenance Tasks --- CAN INSTALL

``` ruby
gem "maintenance_tasks"
```

Use for batch operations on live data that a raw `rake task` would run
unsafely against a production healthcare database: - backfilling
encrypted patient attributes - migrating historical
appointments/bookings - re-indexing discarded records into/out of
Meilisearch - any long-running data change that needs to be
throttled, paused, resumed, and audited rather than run blind.

Runs natively on ActiveJob, so it works directly on Solid Queue —
no Redis required. Ships an embeddable web dashboard.

Agent rule: - Gate the dashboard behind the same admin
authentication/Pundit checks as Avo — it is an operational surface that
can touch patient data, not a public page. - Every maintenance task
that touches patient/clinical data follows the same Section 38 (Agent
Rules for Sensitive Patient Data) requirements as any other code path
that touches PHI.

------------------------------------------------------------------------

## Sidekiq --- CAN INSTALL

Only introduce if there is a concrete reason such as: - existing Redis
infrastructure - Sidekiq-specific operational requirements - Sidekiq
Pro/Enterprise features - workload characteristics that justify it

Do not run Solid Queue and Sidekiq as competing default job systems.

------------------------------------------------------------------------

# 19. File Uploads

## Active Storage --- DEFAULT

Use Rails Active Storage.

Recommended architecture:

``` text
Rails
  ↓
Active Storage
  ↓
S3-compatible object storage
```

Use private storage for patient/clinical documents.

## active_storage_validations --- MUST INSTALL

Use this gem to enforce model-level validation for Active Storage
attachments. Active Storage itself does not provide application-level
content-type, file-size, and dimension validation rules for your models.

Use it for: - patient documents - identity documents - medical reports -
patient photos - clinic/doctor images - villa images

Agent rule:

- Validate allowed content types explicitly.
- Set maximum file sizes per attachment category.
- Set image dimensions where appropriate.
- Reject unexpected file types before processing.
- Keep patient-document rules stricter than ordinary marketing images.
- Never rely only on a browser-side file input restriction.
- Add model and request tests for rejected uploads.

Do not make all uploads share one universal limit if the business rules
require different limits for documents, medical images, and public media.

## image_processing --- CAN INSTALL

Use when image variants are required.

Examples: - thumbnails - resized clinic photos - doctor profile images -
villa gallery images

Default backend: **ruby-vips** (libvips). This is Rails' current
`variant_processor` default and is significantly faster and far lighter
on memory than ImageMagick, which matters for a server handling patient
document/image uploads. Pair it as:

``` ruby
gem "image_processing"
gem "ruby-vips"
```

## ruby-vips --- CAN INSTALL (default image backend)

Use alongside `image_processing` for all standard variant generation
(thumbnails, resized photos, galleries). This is the preferred backend —
prefer it over MiniMagick for new work.

## CarrierWave --- CAN INSTALL

Only use if a concrete upload workflow requires CarrierWave's
API/features.

Do not install CarrierWave and Active Storage simply because both exist.

## MiniMagick --- DO NOT INSTALL

Superseded by ruby-vips. If the agent hits an image-variant error, the
correct response is to debug the vips pipeline, not to install
ImageMagick/MiniMagick as a shortcut. A genuine ImageMagick-only need
(some format libvips can't handle) is a deliberate, human-approved
architecture exception — not something the agent decides on its own
mid-task. Do not install `mini_magick` alongside `ruby-vips` "just in
case."

------------------------------------------------------------------------

# 20. Optional Feature Gems

These are NOT baseline dependencies.

## Noticed

Use for unified notification objects across: - email - SMS - in-app
notifications

Add when notification complexity justifies it.

## Twilio Ruby

Use only if Twilio is selected for: - SMS - voice - video-related
services

Current phone OTP provider is MSG91, so do not add Twilio solely for
OTP.

## Ice Cube

Use for recurring doctor availability schedules.

## Geocoder

Use for simple geocoding/proximity workflows.

For serious geospatial queries, evaluate PostgreSQL/PostGIS before
building complex distance logic in Ruby.

## Razorpay — BASELINE (see Section 3)

Follica's payment provider is **Razorpay**, not Stripe/Braintree/Paddle.
Use the official gem directly rather than a multi-processor abstraction
gem (`pay`) built around providers Razorpay isn't one of:

``` ruby
gem "razorpay"
```

This is a baseline dependency, not a "when payments are built" addition —
foreign package/villa booking requires payment at launch, so it ships in
the Gemfile from day one (Section 3) rather than as a later conditional
gem. It's listed here because this section groups the integration
guidance, not because it's optional.

Use for: - consultation/appointment payment - villa/package
booking payment - refunds - payment webhooks

Agent rule:

- Verify webhook signatures before trusting any payload.
- Never log full payment payloads, card/bank/UPI details, or API
  secrets (key id/secret in Rails encrypted credentials or env vars,
  never source control).
- Treat webhooks as the source of truth for payment status; make
  webhook handling idempotent (Razorpay can retry delivery).
- Reconcile Razorpay order/payment status against Follica's own
  booking/payment records — do not trust client-side confirmation
  alone.
- Add VCR/WebMock fixtures for payment flows in tests; never hit the
  live Razorpay API in the test suite.

## ViewComponent

Use if the UI develops many reusable/testable components.

Examples: - DoctorCard - ClinicCard - AppointmentCard - VillaCard -
PackageCard

## Cocoon

Use only for genuinely dynamic nested forms.

## Ranked-model

Use only for manual drag-and-drop ordering.

## Scenic

Use only for database views needed by reporting/analytics.

## MailerLite

Use for marketing/newsletters.

Keep separate from Resend transactional email.

## Recaptcha / invisible_captcha

Use if public forms show bot abuse.

## JSONAPI Serializer

Use only if a public/mobile API needs a structured JSON serialization
layer.

## Dotenv Rails

Optional local `.env` convenience.

Production secrets remain in deployment secrets/Rails credentials.

## Strong Migrations

Recommended when the production database becomes large enough that
migration safety is a serious concern.

## Lograge

Use if structured request logs are required by the
deployment/observability stack.

## Grover

Not every "PDF" need is a backend problem. Route by what the feature
actually requires:

- **Patient just wants to view/print their own copy, no storage or
  emailing needed** (e.g. "print this appointment summary"): use plain
  Tailwind `@media print` styles on the existing view. Zero gems, zero
  backend code, zero Chromium footprint. Prefer this by default.
- **The file must be stored, emailed, or shared with a third party**
  (Razorpay invoice attached to a confirmation email, an
  ABDM-shared prescription, any document that needs to exist as a
  retrievable record): a server-generated file is genuinely required —
  a browser print dialog can't produce that. Use Grover or hexapdf
  below.

Use Grover for: consultation summaries, prescriptions,
appointment/booking receipts, travel vouchers, Razorpay invoices —
specifically the subset of these that must exist as a stored,
retrievable, or emailable file rather than a one-off print.

``` ruby
gem "grover"
```

The Fit: renders standard ERB + Tailwind views straight to PDF via
headless Chromium — no separate layout DSL (e.g. Prawn) to maintain in
parallel with the actual UI.

Agent rule: - Headless Chromium has a real memory/CPU footprint;
confirm the deployment target (Coolify on Oracle Free Tier /
DigitalOcean / Linode) has the headroom before adding it, especially if
PDF generation runs inline in a web request rather than a background
job. - Generate PDFs in a Solid Queue job, not inline in the request
cycle. - A generated PDF of clinical/patient data is PHI the moment it
exists: store it in private Active Storage, never a public URL, and it
falls under the same Section 38 rules as any other patient document
(access control, retention, no public search indexing).
- **Alternative:** if the deployment target can't comfortably run
headless Chromium, use `hexapdf` instead — pure Ruby, near-zero memory
footprint, no browser dependency. Do not install both; pick one per
Core Architecture Rule 6 ("do not install multiple libraries that
solve the same problem").

## rqrcode

Use for ABDM "Scan & Share" QR workflows and clinic desk check-in
tokens.

``` ruby
gem "rqrcode"
```

Pure Ruby, no C-extensions, no external service. Pair with the ABDM
integration — see the ABDM entry in Section 1 and Section 34.

## Turbo Power — watch list, not a default install

`turbo_power` adds extra server-driven Turbo Stream actions
(`dispatch_event`, `redirect_to`, `set_cookie`, `scroll_into_view`,
etc.) beyond what ships in Turbo 8.

Per Core Architecture Rule 11 ("use Rails 8 built-ins before adding a
gem"): check whether Turbo 8's native actions (including
`broadcasts_refreshes`/morphing) and a small Stimulus controller
already cover the need — FullCalendar updates, Leaflet marker syncing,
drawer open/close — before adding this dependency. It's actively
maintained, so there's no staleness concern; the open question is
whether Follica actually needs the extra actions yet. Add it only once
a concrete pattern (not a hypothetical one) shows the team repeatedly
hand-rolling Stimulus controllers for things this gem provides
out of the box.

------------------------------------------------------------------------

# 21. Gems / Technologies Explicitly Rejected

Do not install:

### CanCanCan

Pundit is the authorization system.

### Searchkick

Meilisearch is the search system.

### PgSearch

Meilisearch is the search system.

### Kafka

Not justified for the current clinic/travel platform.

### Memcached / Dalli

Rails 8 Solid Cache is sufficient initially.

### Figaro

Use Rails credentials/environment variables.

### GoodJob

Do not introduce a second Rails database-backed job system when Solid
Queue is selected.

### Sprockets

Rails 8 uses Propshaft by default.

### Attr-encrypted

Use Rails Active Record Encryption or Lockbox when justified.

### React component libraries

Material UI and Ant Design are not part of the current frontend
architecture.

### Bootstrap

Do not add alongside Tailwind.

------------------------------------------------------------------------

# 22. Frontend

## Hotwire

Use: - Turbo - Stimulus

Do not build a React frontend unless the architecture explicitly
changes.

## Tailwind CSS

Use for application styling.

Pick Tailwind instead of Bootstrap.

## Simple Form + Tailwind — setup required, do not skip

Simple Form's default wrappers are not styled for Tailwind out of the
box (they target Bootstrap-era markup). This is a one-time setup cost,
not a per-form cost — do not use it as a reason to hand-roll every
form's label/hint/error markup instead across dozens of forms (patient
intake, doctor onboarding, clinic onboarding, villa onboarding, admin).

Pick one path and do it before building the first real form:

- **Fast path:** `gem "simple_form_tailwind_css"` — a maintained
  community gem that ships a working Tailwind wrapper config and
  `SimpleForm::Tailwind::FormBuilder` out of the box.
- **Manual path:** write `config/initializers/simple_form_tailwind.rb`
  with custom wrappers once, and add that file's path to
  `tailwind.config.js`'s `content` array so Tailwind's JIT compiler
  doesn't purge classes that only appear inside the Ruby wrapper
  definitions rather than in `.erb` files.

Do not let the agent discover this gap mid-feature and improvise
inconsistent per-form styling — resolve it once, up front.

## Bun

Use Bun as the JavaScript package manager.

Typical workflow:

``` bash
bun install
bun add <package>
bun remove <package>
bun update
```

Do not mix npm/yarn/pnpm lockfiles into the repository.

------------------------------------------------------------------------

# 23. Mobile

## Hotwire Native

37signals consolidated **Turbo Native** and **Strada** into a single
framework, **Hotwire Native**, in 2024. Strada's native-control features
now ship built in as "Bridge Components." The standalone Turbo
Native/Strada libraries are deprecated — do not retrieve or install
them for new work; use Hotwire Native's iOS/Android libraries directly.

Use when building the native mobile shell around the Rails application.

Architecture:

``` text
Rails web application
       ↓
   Hotwire (Turbo + Stimulus)
       ↓
   Hotwire Native
       ↓
 Native iOS / Android shell
       ↓
 Bridge Components (native controls driven by the web)
```

Agent rule: - Keep business logic on the Rails backend. - Use native
code only where the mobile experience genuinely needs native
capabilities. - If a prompt, doc, or old tutorial references "Turbo
Native" or "Strada" as separate libraries, treat that as legacy —
resolve it to Hotwire Native, not the deprecated originals.

------------------------------------------------------------------------

# 24. Calendar

## FullCalendar

Frontend calendar.

Use for: - doctor availability - appointments - clinic schedules -
patient appointment views

Backend remains authoritative for: - availability - booking conflicts -
appointment state

Never trust the browser calendar to prevent double booking.

------------------------------------------------------------------------

# 25. Maps

## Leaflet.js + OpenStreetMap

Use for: - clinic location - villa location - travel maps - nearby
services

Do not assume OpenStreetMap tiles are an unlimited production tile
service. Select an appropriate tile provider or self-host if traffic
requires it.

------------------------------------------------------------------------

# 26. Video

## Daily.co + Pipecat

Daily.co: - video infrastructure

Pipecat: - AI/voice/video agent pipelines where needed

Agent rule: - Do not expose provider secrets to browsers. - Create
sessions/tokens server-side. - Recordings and clinical video data
require explicit privacy/retention rules.

------------------------------------------------------------------------

# 27. Phone Authentication

## MSG91

Use MSG91 for: - Indian phone OTP - OTP verification - transactional SMS

The integration should be treated as an external API service, not
assumed to be a Rails authentication gem.

Agent rule: - Store API credentials securely. - Rate-limit OTP
requests. - Add resend cooldowns. - Prevent OTP enumeration. - Verify
webhook signatures where supported. - Do not log OTP values.

Phone authentication is separate from Devise's password authentication
strategy and should be integrated deliberately.

------------------------------------------------------------------------

# 28. Email Authentication

## Resend

Use for: - email confirmation - password reset - transactional
notifications

Do not use MailerLite for authentication emails.

------------------------------------------------------------------------

# 29. WhatsApp

## Meta Cloud API

Use for: - WhatsApp notifications - appointment updates - booking
updates - patient communication - approved template messages

Agent rule: - Templates and WhatsApp policy constraints must be
respected. - Do not send arbitrary promotional messages through
transactional workflows. - Keep consent/status in the database.

------------------------------------------------------------------------

# 30. Flight Integration

Candidate providers:

### Duffel

Potentially preferred when actual flight search/booking capabilities are
required.

### Aviationstack

Useful primarily as a flight-data source depending on the required
capabilities.

Agent rule: - Separate flight data from flight booking. - Never assume
an API that provides flight data also provides ticketing/booking. -
Store provider booking/reference IDs. - Make external booking operations
idempotent.

------------------------------------------------------------------------

# 31. Affiliate / Travel Monetization

Candidates: - Duffel - Skyscanner - Travelpayouts

Do not integrate all three initially.

Choose based on: - country availability - affiliate terms - API access -
commission structure - booking flow - technical capabilities

------------------------------------------------------------------------

# 32. Travel Insurance

Candidate providers: - Ekta - IMG Global - VisitorsCoverage

Treat these as external insurance partners.

Do not represent insurance as merely a static database record if the
user must actually purchase a policy.

Store: - provider - quote/reference ID - policy ID - coverage details -
purchase status - dates - traveller association

------------------------------------------------------------------------

# 33. Villa / Accommodation

Current candidate: - Agoda

Do not hardwire the entire villa architecture to Agoda before confirming
the exact partner/API/affiliate capabilities.

Follica's own villa inventory should remain independent:

``` text
Follica Villa
    ↓
availability
pricing
photos
amenities
owner
inspection
booking rules
```

External inventory can be integrated later.

------------------------------------------------------------------------

# 34. ABDM

ABDM is an important healthcare ecosystem consideration.

Treat it as an integration/data-standard workstream, not as a random
Gemfile dependency.

Agent rule: - Do not invent ABDM APIs or identifiers. - Confirm the
exact ABDM workflow and authorization requirements before
implementation. - Patient consent and health-data access must be
explicit. - Never expose ABDM-linked health data to unauthorized roles.

------------------------------------------------------------------------

# 35. Kaggle

Kaggle datasets are for development/testing/research only unless
licensing explicitly permits another use.

Agent rule: - Never put Kaggle sample data into production. - Never
treat synthetic/test patient data as real patient records. - Label
fixtures and seed data clearly.

------------------------------------------------------------------------

# 35A. Worth Watching As Follica Scales

These are architecture watchpoints, not dependencies to install now.

## Typesense vs Meilisearch

Keep **Meilisearch** as the current search engine. Typesense is a future
alternative worth evaluating if clinic/villa discovery develops demanding
native geo-search requirements that are not adequately handled by the
PostgreSQL/PostGIS + Meilisearch architecture.

Do not introduce both search engines. Revisit only when a measured product
requirement justifies the migration cost.

## LiveKit vs Daily.co + Pipecat

Keep **Daily.co + Pipecat** as the current video architecture. Revisit
LiveKit only when actual video volume, cost, latency, infrastructure
control, or AI-agent requirements create a measurable reason to migrate.
Do not encode a fixed pricing break-even point into the architecture
document because provider pricing and usage patterns change.

## Resend + Postmark

Keep **Resend** as the primary transactional email provider. Postmark is a
possible future secondary/failover provider for high-value account
recovery and transactional mail.

Do not add Postmark merely for redundancy at the current stage. If a
secondary provider is introduced, define explicit failover rules, delivery
monitoring, idempotency, and provider-specific credentials before using it
in production.

---

# 35B. CI/CD Release Gates

"The tests exist" is not the same as "the tests block a bad merge."
The following are required, non-bypassable gates — not suggestions the
agent can decide to skip because a change "seems small":

## Required before merge (PR-level CI)

```text
bundle exec rspec              — must pass, zero pending-as-passing tricks
bundle exec rubocop             — zero offenses, or a documented exception
bundle exec brakeman             — zero new high/critical findings
bundle exec bundler-audit        — zero known CVEs
Bullet                           — zero N+1 warnings in the affected specs
SimpleCov                        — coverage does not regress below the
                                    prior baseline
strong_migrations checks         — any new migration passes its lint
```

A PR that fails any of the above does not merge. An agent does not
mark a task complete with a red or skipped check — see the Definition
of Done in `skills.md`.

## Required before deploy (release-level)

- Migrations for the release are reviewed against Section 14A/36
  (zero-downtime pattern, not just "does it run").
- Any new `maintenance_tasks` batch touching patient data has been
  reviewed per Section 38A and is not scheduled to run unattended on
  its first execution.
- No secrets, API keys, or `.env` content are present in the diff
  (Section 37 already prohibits committing them — CI should also
  scan for accidental inclusion, e.g. via `gitleaks` or an equivalent
  check, not rely on humans catching it in review).

## Branch/release discipline

- No direct push to the production deployment branch — every change
  reaches production through the PR + CI gate above.
- Deploys are traceable to a specific passing CI run and commit SHA,
  not "whatever's currently checked out."

------------------------------------------------------------------------

# 36. Deployment

Preferred self-hosted direction:

``` text
Coolify
   ↓
Oracle Cloud Free Tier
or
DigitalOcean
or
Linode
```

Managed alternatives:

``` text
Render
Koyeb
```

Production architecture should include:

``` text
Internet
   ↓
Reverse proxy / TLS
   ↓
Rails application
   ├── PostgreSQL
   ├── Solid Queue
   ├── Meilisearch
   ├── Active Storage
   └── monitoring
```

## Thruster --- MUST INSTALL for the self-hosted path

Rails 8 ships `gem "thruster"` in the generated Dockerfile by default.
For Follica's preferred self-hosted direction (Coolify on Oracle Free
Tier/DigitalOcean/Linode, no separate Nginx layer), keep it: it gives
Puma HTTP/2, asset compression, basic caching, and X-Sendfile
acceleration with zero configuration, avoiding an Nginx layer to
operate and patch.

``` ruby
gem "thruster", require: false
```

Do not remove Thruster to add Nginx unless a specific edge feature
(WAF rules, complex routing, CDN-specific behavior) requires it — see
Core Architecture Rule 6 (don't run two things that solve the same
problem).

If Meilisearch is self-hosted, protect it from public exposure.

Do not expose the Meilisearch master key to the browser.

## Health checks

- Wire Rails 8's built-in health-check endpoint (`/up`) into Coolify's
  container health check — do not build a custom one unless a specific
  gap (e.g. checking Meilisearch/Solid Queue connectivity, not just
  "Rails booted") requires extending it.
- A failing health check must stop a rollout from completing, not just
  log a warning — confirm Coolify is actually configured to gate on it,
  not merely display it.

## Migration sequencing

Deploys are sequenced, not "push code and run migrations whenever":

```text
1. Run migrations (expand step only — see below) against production.
2. Deploy the new application code.
3. Verify the health check and a small smoke-test path
   (e.g. login + one booking-search query).
4. Only then consider the release complete.
```

- Use the expand/contract pattern for any schema change that isn't
  purely additive: **expand** (add the new column/table, deploy code
  that writes to both old and new) → **migrate data** → **contract**
  (deploy code that only uses the new shape, then drop the old
  column/table in a later, separate release). Never combine "add
  column" and "remove old column" in the same deploy — see Production
  Rollback Rules (Section 37B) for why.
- `online_migrations`/`strong_migrations` (Section 14) enforce the
  mechanics of this; this section is the sequencing policy they
  operate under.

------------------------------------------------------------------------

# 37. Deployment Environment Separation

Maintain:

``` text
development
test
staging
production
```

Never use production patient data in development.

Staging should use: - synthetic data - test accounts - sandbox provider
credentials where available

Secrets belong in: - deployment secret store - environment variables -
Rails encrypted credentials where appropriate

Never commit:

``` text
.env
API keys
private keys
provider secrets
Meilisearch master key
database passwords
```

------------------------------------------------------------------------

# 37A. Backup, Restore & Disaster Recovery

An untested backup is a hope, not a backup.

## What must be backed up

- **PostgreSQL** — automated backups on a defined schedule (minimum:
  daily full + continuous WAL archiving for point-in-time recovery),
  encrypted at rest, retained for a defined window, and stored in a
  location independent of the primary host (not just a snapshot on the
  same Oracle/DigitalOcean/Linode instance).
- **Active Storage / S3-compatible object storage** — patient
  documents, reports, generated PDFs need versioning or equivalent
  protection against accidental overwrite/deletion, in addition to the
  bucket's own durability.
- **Meilisearch is explicitly NOT a backup target.** It is a
  rebuildable index (Core Architecture Rule 2) — recovery for it is
  "reindex from PostgreSQL," not "restore a Meilisearch snapshot." Do
  not spend backup effort here.
- Rails encrypted credentials / key material — the key itself must be
  recoverable through a process independent of the primary database
  backup (a database restore is useless if the encryption key that
  unlocks its data was only ever stored on the same compromised host).

## Required practice, not just infrastructure

- Define an explicit RPO (how much data loss is acceptable — e.g. "≤
  15 minutes" via WAL archiving) and RTO (how long restoration is
  allowed to take) even at an early, approximate stage. "We have
  backups" without these numbers is not a disaster-recovery plan.
- **Run an actual restore drill** on a defined cadence (e.g. quarterly)
  against a non-production environment. A backup that has never been
  restored is unverified.
- Document who is authorized to trigger a production restore and what
  the rollback-to-restore decision process is — this is not a decision
  an agent makes autonomously mid-incident (see Section 38A).

------------------------------------------------------------------------

# 37B. Production Rollback Rules

Rolling back application code is routine. Rolling back a schema change
underneath running code is how routine rollbacks turn into incidents —
this section exists to keep those separate.

- **Code rollback must always be safe.** Because Section 36 requires
  the expand/contract migration pattern, the previous release's code
  should still run correctly against the current schema after a
  rollback — this is the actual reason that pattern is mandatory, not
  just a zero-downtime nicety.
- Keep the previous N deployable release artifacts/images available
  (Coolify's rollback mechanism depends on this) — do not treat "roll
  back" as "manually redeploy an old commit and hope the build cache
  cooperates."
- **Never roll back a destructive migration by re-running an inverse
  migration under incident pressure.** If a contract-step migration
  (one that drops a column/table) already ran and needs to be undone,
  that is a restore-from-backup decision (Section 37A), not a
  hot-written reverse migration against live data.
- A rollback decision is a stop-and-escalate point, not a
  fully-autonomous agent action: an agent identifying that a rollback
  is needed reports it and the reasoning; a human confirms the
  rollback-vs-fix-forward call, consistent with Section 38A.
- After any production rollback, treat it as an incident for the
  purposes of Section 38A even if no data was affected — the
  underlying cause still needs review before the next deploy.

------------------------------------------------------------------------

# 38. Agent Rules for Sensitive Patient Data

The agent must assume that patient/clinical data is sensitive.

Before implementing a feature involving patient data:

1.  Identify who can access it.
2.  Add/update the Pundit policy.
3.  Decide whether the field should be encrypted.
4.  Decide whether it belongs in PaperTrail.
5.  Decide whether it may enter logs.
6.  Decide whether it may enter Sentry.
7.  Decide whether it may be indexed by Meilisearch.
8.  Decide retention/deletion behavior.
9.  Add tests for unauthorized access.

Never put: - clinical notes - identity documents - insurance
information - private medical images - authentication secrets

into public search indexes.

------------------------------------------------------------------------

# 38A. Incident & Security Event Handling

This section applies the moment any of the following is discovered —
during normal development, a code review, an audit (Section 2.12 in
`skills.md`), or in production:

```text
- An authorization bypass (a user accessed data/actions they shouldn't)
- A leaked credential/API key (in a commit, a log, a Sentry event, a chat)
- Evidence of webhook forgery or replay against a payment endpoint
- Unexplained/suspicious Avo admin access to patient records
- A data exposure (PHI in a log, a public URL, a search index, an
  email to the wrong recipient)
- A production rollback (Section 37B) — always treated as an incident
  for review purposes
```

## Immediate agent rule

1.  **Do not silently patch and move on.** Fixing the code without
    surfacing what happened is itself a failure mode this section
    exists to prevent — "it's fixed now" is not a substitute for
    "here is what happened, here is the blast radius, here is the
    fix."
2.  **Escalate to a human immediately** — an agent does not
    unilaterally decide an incident is minor enough not to mention.
    This is a stop-and-report point, the same as a rollback decision
    (Section 37B).
3.  **Contain before investigating at leisure**: rotate any credential
    that may be compromised (Section 14 Key Rotation), revoke active
    sessions if account compromise is plausible, and — for a suspected
    data exposure — remove the exposed data from wherever it leaked to
    (public URL, search index, log aggregator) as the first action, not
    the last.
4.  **Preserve evidence.** Do not delete or rewrite logs, PaperTrail
    versions, or the offending commit history to "clean up" — a
    security review needs to see what actually happened.
5.  Once contained, produce a short factual account: what happened,
    what data/accounts were affected, what was done, what remains to
    be verified. This is required output, not optional documentation.

## What this is not

- This is not a reason to avoid reporting near-misses or things that
  turned out fine — a caught-in-code-review authorization bug is worth
  the same brief factual note, at lower urgency, so patterns are
  visible over time.
- This does not replace Section 38 (sensitive-data-by-design checklist)
  or Rails Security Audit / HIPAA-PHI Compliance review (`skills.md`)
  — those are preventive; this section is what happens when prevention
  already failed.

------------------------------------------------------------------------

# 39. Agent Workflow for Every New Feature

Before coding:

``` text
1. Identify the domain model.
2. Identify the actor/role.
3. Define authorization.
4. Check existing Rails functionality.
5. Check this Gem Guide.
6. Reuse an approved gem if applicable.
7. Decide whether the operation is synchronous or a Solid Queue job.
8. Decide whether data enters Meilisearch.
9. Decide whether data requires encryption.
10. Decide whether changes require audit history.
11. Write tests.
12. Implement.
13. Run security/lint/test checks.
```

Minimum validation:

``` bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman
bundle exec bundler-audit
```

------------------------------------------------------------------------

# 40. Final Approved Dependency Philosophy

## MUST INSTALL / BASELINE

``` text
Rails 8
pg
puma

devise
devise-two-factor
pundit

active_storage_validations

meilisearch-rails

pagy
friendly_id

simple_form
avo

razorpay

resend

sentry-rails
paper_trail
discard

brakeman
bundler-audit

rspec-rails
factory_bot_rails
capybara
shoulda-matchers
simplecov
bullet

rubocop
```

## CAN INSTALL WHEN NEEDED

``` text
vcr
webmock
pretender          # demo/staging impersonation only by default — see Section 9
pry-rails
annotate
rails-erd
letter_opener
test-prof          # dev/test only

mission_control-jobs
sidekiq
maintenance_tasks  # batch/backfill ops on live data, runs on Solid Queue

image_processing
ruby-vips          # default image backend, pair with image_processing
carrierwave

ransack
lockbox
rack-attack

noticed
twilio-ruby
ice_cube
geocoder
view_component
cocoon
ranked-model
scenic
mailerlite-ruby
recaptcha
jsonapi-serializer
dotenv-rails
strong_migrations
online_migrations # zero-downtime PG migrations, pairs with strong_migrations
lograge

grover             # PDF from Rails views (headless Chromium) — or hexapdf if VPS-constrained
rqrcode            # ABDM Scan & Share / check-in QR codes
turbo_power        # watch list — confirm Turbo 8 native actions don't already cover it
```

## DO NOT INSTALL

``` text
CanCanCan
Searchkick
PgSearch
Kafka
Dalli / Memcached
Figaro
GoodJob
Sprockets
Attr-encrypted
Guard
Bootstrap alongside Tailwind
Material UI
Ant Design
mini_magick        # superseded by ruby-vips (Section 19). Do not install
                    # on the first image-variant error as a shortcut —
                    # debug the vips pipeline. A genuine ImageMagick-only
                    # need is an explicit, human-approved architecture
                    # exception, not an autonomous agent fallback.
```

------------------------------------------------------------------------

# 41. One-Line Agent Reference

  Technology                  Agent should use it for
  --------------------------- -------------------------------------------
  Rails 8                     Backend/application framework
  Devise                      Authentication
  Devise Two Factor           Doctor/Admin 2FA
  Pundit                      Authorization
  Avo                         Internal admin panel
  Pretender                   Admin impersonation — demo/staging only by default
  Meilisearch                 Application search
  Pagy                        Database pagination
  FriendlyId                  Public slugs
  Resend                      Transactional email
  Solid Queue                 Background jobs
  PaperTrail                  Audit/version history
  Discard                     Soft deletion
  Sentry                      Production errors
  Brakeman                    Rails security scanning
  Bundler Audit               Dependency CVE scanning
  RSpec                       Unit/integration testing
  Capybara                    Browser/system testing (CI spec suite)
  FactoryBot                  Test fixtures/factories
  Shoulda Matchers            Model/association tests
  SimpleCov                   Coverage
  Bullet                      N+1 detection
  RuboCop                     Ruby linting/style
  Active Storage              File uploads
  active_storage_validations  Upload type/size/dimension validation
  image_processing            Image variants (paired with ruby-vips)
  ruby-vips                   Default image-processing backend (libvips)
  Razorpay                    Payment provider (consultations, bookings)
  Tailwind                    Styling
  Hotwire/Turbo               Server-driven UI/navigation
  Stimulus                    Small frontend interactions
  Bun                         JavaScript package management
  FullCalendar                Calendar UI
  Leaflet                     Maps
  OpenStreetMap               Map data/tiles, with appropriate provider
  MSG91                       Phone OTP/SMS
  Meta Cloud API              WhatsApp
  Daily.co                    Video
  Pipecat                     AI/voice/video pipelines
  Hotwire Native               Mobile Rails shell + native controls (Bridge Components)
  Duffel/Aviationstack        Flight integration
  Ekta/IMG/VisitorsCoverage   Travel insurance integration
  Agoda                       Accommodation partner/inventory candidate
  ABDM                        Healthcare ecosystem integration
  Kaggle                      Test/research datasets
  Coolify                     Deployment management
  Thruster                    HTTP/2 proxy for Puma (self-hosted path)
  Grover                      PDF from Rails views (headless Chromium)
  rqrcode                     ABDM/check-in QR generation
  maintenance_tasks           Audited batch ops on live data (Solid Queue)
  online_migrations           Zero-downtime PostgreSQL migrations
  test-prof                   RSpec factory/performance profiling (dev/test)

------------------------------------------------------------------------

# 42. Final Rule

**The agent must not install every item in this document.**

This document deliberately contains three levels:

``` text
MUST
  ↓
baseline architecture

CAN
  ↓
feature-driven additions

DO NOT
  ↓
explicit architectural exclusions
```

When a new feature appears, the agent must first identify which existing
component already solves the problem before adding another dependency.
