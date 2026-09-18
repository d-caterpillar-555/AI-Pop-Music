# Follica — AI Agent Skills Master Guide

## Rails 8 Doctor/Clinic ↔ Patient Platform

**Status:** Architecture baseline  
**Purpose:** Single source of truth for coding agents and development workflows.  
**Rule:** Agents should activate the smallest relevant skill set for the current task. Do not activate every skill on every task.

---

# 1. Core Skill Philosophy — RETRIEVE, DON'T LOAD

Follica uses **skill-retrieval-mcp as the skill router**.

The coding agent must **NOT load this entire skills catalogue into its active context for every task**.

This file is a **routing map and policy**, not a collection of skill instructions to preload.

## Mandatory Skill-Retrieval Protocol

For every non-trivial task:

```text
User task
   ↓
Identify the job being requested
   ↓
Query skill-retrieval-mcp
   ↓
Retrieve ONLY the skill(s) relevant to that job
   ↓
Read/activate those skill instructions
   ↓
Inspect Follica code + gems.md
   ↓
Plan
   ↓
Implement
   ↓
Test
   ↓
Review
```

### The agent must do this

1. **Classify the job first.**
2. Identify the capability required to complete that job.
3. **Ask `skill-retrieval-mcp` which approved skill is appropriate.**
4. Load only the returned/recommended skill instructions.
5. Use multiple skills only when the task genuinely crosses multiple capabilities.
6. Do not load unrelated skills.
7. Do not keep the entire skill library in context just because it exists.
8. If unsure which skill applies, query `skill-retrieval-mcp` instead of guessing.
9. If the task changes during implementation, perform another targeted skill lookup.
10. After completing the work, unload/stop carrying unnecessary skill context where the agent runtime supports it.

## Important distinction

`skills.md` tells the agent:

> **"For this kind of job, look up this skill."**

It does **not** mean:

> **"Load every skill listed here before starting."**

The actual skill implementation/instructions must come from **skill-retrieval-mcp**.

## Skill lookup examples

### Job: Build a new Rails feature

```text
Query skill-retrieval-mcp:
"Which approved skill should I use for implementing a new Rails feature
while following an existing Rails application's conventions?"
```

Expected relevant skill:
- Rails Conventions

Possible additional retrieval:
- Superpowers — if the feature is substantial
- Graphify — if architecture/code relationships are unclear
- Context7 — if current API/library documentation is needed
- CodeBurn — for general code-quality review after implementation
- Rails Security Audit — for Rails-specific security review (Brakeman, Pundit, OWASP Top 10)
- HIPAA/PHI Compliance — for patient/clinical-data privacy and healthcare compliance review

Do **not** automatically load Frontend Design, SEO, scraping, or image-to-code skills unless the task actually requires them.

---

### Job: Understand an unfamiliar part of the codebase

```text
Query skill-retrieval-mcp:
"Which approved skill should I use to understand relationships between
files, models, schemas, and architecture in this codebase?"
```

Expected relevant skill:
- Graphify

---

### Job: Build a new UI

```text
Query skill-retrieval-mcp:
"Which approved skills should I use to design and implement a new
production-quality Rails/Hotwire frontend interface?"
```

Expected relevant skills:
- Frontend Design
- Web Design Guidelines

Then retrieve additional skills only if needed:
- Impeccable — visual polish
- Human Review — human visual approval
- Variate — multiple design alternatives
- Image-to-Code — screenshot/design reproduction

---

### Job: Polish an existing UI

```text
Query skill-retrieval-mcp:
"Which approved skill should I use to audit and polish an existing
interface for hierarchy, spacing, typography, and interaction quality?"
```

Expected relevant skill:
- Impeccable

Potential follow-up:
- Human Review if human visual approval is needed.

---

### Job: Test the actual website

```text
Query skill-retrieval-mcp:
"Which approved skill should I use for browser-based end-to-end testing
of the actual website?"
```

Expected relevant skill:
- Playwright CLI

---

### Job: General code-quality review

```text
Query skill-retrieval-mcp:
"Which approved skill should I use to review generated code for quality,
maintainability, and problematic implementation?"
```

Expected relevant skill:
- CodeBurn

### Job: Rails security audit

```text
Query skill-retrieval-mcp:
"Which approved skill should I use for a read-only Rails security audit
covering Brakeman, Pundit authorization policies, and OWASP Top 10 risks?"
```

Expected relevant skill:
- Rails Security Audit

### Job: HIPAA / PHI compliance

```text
Query skill-retrieval-mcp:
"Which approved skill should I use to review Rails application handling of
PHI and HIPAA-sensitive healthcare data, including identifiers, encryption,
access control, audit logging, retention, and exposure risks?"
```

Expected relevant skill:
- HIPAA/PHI Compliance

---

### Job: Use a current gem/library API

```text
Query skill-retrieval-mcp:
"Which approved skill should I use to retrieve current documentation
for this library/framework/API?"
```

Expected relevant skill:
- Context7

---

### Job: Screenshot → frontend code

```text
Query skill-retrieval-mcp:
"Which approved skill should I use to convert this screenshot/design
reference into frontend code?"
```

Expected relevant skill:
- Image-to-Code Skill

Potential follow-up:
- Frontend Design
- Web Design Guidelines
- Human Review

---

### Job: SEO

```text
Query skill-retrieval-mcp:
"Which approved skill should I use for SEO analysis and search visibility
optimization?"
```

Expected relevant skill:
- Claude-SEO

---

### Job: Scrape public websites

```text
Query skill-retrieval-mcp:
"Which approved skills should I use for production-grade public web
scraping and structured extraction?"
```

Expected relevant skills:
- Scrapling
- ScrapeGraphAI

Use Agent-Reach only when the task specifically needs its broader web-source access.

---

### Job: Extract information from a PDF/DOCX/PPTX/XLSX

```text
Query skill-retrieval-mcp:
"Which approved skill should I use to convert this document into
AI-readable Markdown/text?"
```

Expected relevant skill:
- MarkItDown

---

### Job: Long coding session / large context

```text
Query skill-retrieval-mcp:
"Which approved skill should I use to prevent a long coding session
from becoming bloated with unnecessary context?"
```

Expected relevant skill:
- Headroom

---

### Job: Generate several UI alternatives

```text
Query skill-retrieval-mcp:
"Which approved skill should I use to generate, compare, and select
multiple design variations for a UI section?"
```

Expected relevant skill:
- Variate

---

### Job: Product/business conversion workflow

```text
Query skill-retrieval-mcp:
"Which approved skill should I use when implementing onboarding,
conversion, paywall, or churn-reduction business logic?"
```

Expected relevant skill:
- Marketing Skills

---

### Job: Make an application controllable through CLI

```text
Query skill-retrieval-mcp:
"Which approved skill should I use to turn an application workflow
into a CLI-accessible tool an AI agent can operate?"
```

Expected relevant skill:
- CLI-Anything

---

## Minimal-context rule

**Never do this:**

```text
Load all 20+ skills
        ↓
Start coding
```

**Do this:**

```text
Task
 ↓
Skill Retrieval
 ↓
1–3 relevant skills
 ↓
Work
```

A task may require more than three skills, but the agent must have a concrete reason for each additional skill.

## Overlapping skills — retrieve one primary, not the group

Several approved skills cover adjacent ground. `skill-retrieval-mcp` should return the smallest set that satisfies the job — the agent should not stack every skill in a category "to be safe." Default to:

**UI polish/design (pick one primary):**
- Building new UI → **Frontend Design**.
- Auditing/polishing existing UI → **Impeccable**.
- Retrieve **Web Design Guidelines** additionally only for a pre-ship usability/accessibility pass, not as a default add-on.
- Retrieve **Variate** only when the task explicitly asks for multiple comparable design alternatives.

**Security/quality review (pick one primary):**
- Rails-specific authorization/security concerns → **Rails Security Audit**.
- General AI-code quality/hygiene → **CodeBurn**.
- Retrieve both only when the task genuinely needs both a security audit and a broader quality pass — not by default on every change.

**Research/scraping (pick one primary):**
- Default to **Scrapling** alone for standard public data collection (clinics, villas, listings).
- Add **ScrapeGraphAI** only when source structure varies enough to need AI-driven extraction pipelines.
- Add **Agent-Reach** only when the task genuinely needs broad cross-platform research, not routine single-site scraping.

If a task only needs one skill from a group, retrieving the whole group is a retrieval error, not thoroughness.

## When no skill is needed

Not every task requires a specialist skill.

For a trivial change, the agent may only need:

```text
Rails Conventions
```

or, if the change is obvious and covered by the existing project conventions, it may not need a specialist skill at all.

The agent should not invoke skill retrieval merely to inflate the workflow for trivial work.

## When to retrieve again

Perform a new targeted lookup when:

- The task expands into a different domain.
- A new technical capability becomes necessary.
- The agent encounters an unfamiliar library/API.
- UI work becomes necessary during a backend task.
- Browser testing becomes necessary.
- A scraping task becomes a structured-data pipeline.
- Security review becomes necessary.

## Golden Rule

> **`skill-retrieval-mcp` is the gatekeeper. `skills.md` is the routing map. Actual skill instructions are loaded only after targeted retrieval.**

---

# 2. Everyday Skills

## 2.1 Skill Retrieval — skill-retrieval-mcp

**Purpose:** Select the most relevant approved skills from the skill library for the current task.

### Use when

- Starting a substantial task.
- Unsure which specialist skill is appropriate.
- Several skills could apply and the agent needs to select the smallest useful set.
- Working on an unfamiliar part of the application.

### Agent rule

Do not activate the entire skill library by default.

First determine:
- What is being built?
- Which layer is affected?
- Which specialist skills are required?
- Which skills are unnecessary?

### Expected workflow

```text
Task
 ↓
Retrieve relevant skills
 ↓
Activate only required skills
 ↓
Plan
 ↓
Implement
 ↓
Test
 ↓
Review
```

---

## 2.2 Graphify — Graphify Labs

**Purpose:** Build a queryable knowledge graph of the codebase so agents understand relationships between files, code, schemas, models, and architecture.

### Use when

- Entering an unfamiliar codebase.
- Making changes that cross multiple models/controllers/services.
- Investigating dependencies between files.
- Understanding database relationships.
- Planning refactors.
- Checking whether an existing implementation already solves a problem.

### Especially useful for Follica

```text
Patient
  ↓
Appointment
  ↓
Doctor
  ↓
Clinic

Patient
  ↓
Booking
  ↓
Villa
  ↓
Travel / Package
```

### Agent rule

Before changing architecture, understand existing relationships instead of guessing from filenames.

---

## 2.3 Superpowers — obra

**Purpose:** Structured software-development workflow covering planning, design, implementation, testing, debugging, and review.

### Use when

- Building a new feature.
- Making a significant refactor.
- Fixing a complex bug.
- Changing architecture.
- Implementing multi-step workflows.

### Required workflow

```text
Understand
 ↓
Plan
 ↓
Design
 ↓
Implement
 ↓
Test
 ↓
Debug
 ↓
Review
```

### Agent rule

Do not jump directly from a vague feature request to code when the change is structurally significant.

---

## 2.4 Context7 — Upstash

**Purpose:** Retrieve current library/framework documentation and examples.

### Use when

- Using a Rails API whose exact behavior matters.
- Working with a gem or JavaScript package.
- Unsure about current syntax.
- Implementing an integration.
- Updating dependencies.
- Avoiding outdated or hallucinated APIs.

### Priority

Use current documentation over remembered API syntax.

### Agent rule

If an API may have changed between versions, verify it before coding.

---

## 2.5 Human Review — Peter Yang

**Purpose:** Human-in-the-loop visual review and feedback to the coding agent.

### Use when

- A UI change needs visual approval.
- Layout/spacing feels subjective.
- A patient/doctor/admin workflow needs human usability review.
- Comparing multiple interface implementations.

### Agent rule

Use human review for decisions that cannot reliably be judged from code alone.

---

## 2.6 Impeccable — pbakaus

**Purpose:** Audit, critique, and polish interfaces for visual quality.

### Review areas

- Visual hierarchy
- Spacing
- Typography
- Alignment
- Density
- Interaction states
- Consistency
- Component polish

### Use when

- Reviewing existing Follica dashboards.
- Improving patient dashboards.
- Improving clinic/doctor dashboards.
- Improving Avo-facing operational interfaces where applicable.
- Preparing production UI.

### Agent rule

Do not redesign working UI merely for novelty. Improve measurable usability and visual quality.

---

## 2.7 Rails Conventions — ethos-link

**Purpose:** Implement Rails features according to the existing application's architecture, patterns, and conventions.

### Use when

- Adding models.
- Adding controllers.
- Adding routes.
- Adding services/jobs.
- Adding validations.
- Modifying database behavior.
- Implementing Rails-native workflows.

### Agent rule

First inspect how Follica already solves similar problems.

Prefer:

```text
existing Follica convention
        ↓
Rails 8 convention
        ↓
approved gem
        ↓
new dependency only if justified
```

Never introduce a new pattern simply because another Rails project uses it.

---

## 2.8 Frontend Design — Anthropic

**Purpose:** Generate distinctive, production-quality frontend interfaces with deliberate visual direction.

### Use when

- Creating a new dashboard.
- Designing patient onboarding.
- Designing clinic/doctor interfaces.
- Creating landing pages.
- Creating booking flows.
- Building new visual components.

### Follica frontend baseline

```text
Hotwire
 ├── Turbo
 └── Stimulus

Tailwind CSS
```

### Agent rule

Do not introduce React merely because a design task is complex.

---

## 2.9 Web Design Guidelines — Vercel Labs

**Purpose:** Review usability, accessibility, responsiveness, interaction quality, and web best practices.

### Use when

- Reviewing an existing interface.
- Before shipping a major UI.
- Testing mobile responsiveness.
- Reviewing forms.
- Reviewing navigation.
- Reviewing accessibility.

### Review checklist

- Keyboard navigation
- Focus states
- Form errors
- Loading states
- Empty states
- Responsive layouts
- Touch targets
- Contrast
- Semantic HTML
- Error recovery
- Performance

---

## 2.10 Playwright CLI — Microsoft

**Purpose:** Browser automation and end-to-end testing of the actual website.

### Use when

- Testing registration.
- Testing login.
- Testing patient dashboard flows.
- Testing clinic/doctor workflows.
- Testing villa workflows.
- Testing booking.
- Testing admin workflows.
- Regression testing after UI changes.

### Agent rule

Prefer testing the actual deployed/local application for critical user journeys.

Example:

```text
Open application
 ↓
Login
 ↓
Perform real user actions
 ↓
Verify visible result
 ↓
Check database/API state where appropriate
```

### Relationship to Capybara — both are used, for different jobs

Follica's test suite uses **Capybara** (see `gems.md`) for RSpec system specs. These are the permanent, CI-run, in-process regression tests written whenever a feature is built — that's ordinary Rails Conventions/Superpowers work, not a reason to retrieve this skill.

Retrieve **Playwright CLI** instead when the agent needs to drive the actual running application interactively rather than extend the spec suite:

- Reproducing a bug live before writing a fix.
- Cross-browser or visual regression checks.
- Verifying a deployed/staging environment.
- Ad hoc exploratory testing of a flow that doesn't yet have (or doesn't need) a permanent spec.

**Rule of thumb:** writing a spec that lives in the repo → Capybara, no skill retrieval needed. Driving the live app for verification, reproduction, or a one-off check → Playwright CLI. Do not treat these as competing choices for the same job.

---

## 2.11 CodeBurn — GetAgentSeal

**Purpose:** Review generated code for general quality, maintainability, and problematic implementation patterns. **CodeBurn does not own security review** — see Rails Security Audit (2.12) and HIPAA/PHI Compliance (2.13) for that. This split is deliberate, not an oversight: retrieving CodeBurn does not satisfy a security-review requirement, and a task needing both retrieves both explicitly.

### Use when

- Reviewing AI-generated code for maintainability/hygiene.
- Before merging significant changes, as the general-quality pass.
- After external API integrations, for implementation quality (error handling shape, retry logic, dependency choices) — not for the security posture of the integration, which is Rails Security Audit's job.

### Agent rule

Look for:

- Duplicate logic
- Fragile/brittle code
- Poor naming
- Unnecessary dependencies
- Bad error handling (shape/robustness, not security implications)
- Hidden performance problems

Do **not** treat "security vulnerabilities," "authorization bypasses," or "data leaks" as CodeBurn's findings to make — those are Rails Security Audit's / HIPAA-PHI Compliance's scope. If CodeBurn incidentally surfaces one, route it to the appropriate skill rather than resolving it under CodeBurn's authority.

CodeBurn and Rails Security Audit are frequently both run on the same significant change — that's retrieving two skills for two distinct concerns, not redundancy.

---

## 2.12 Rails Security Audit — thibautbaissac/rails_ai_agents

**Purpose:** Rails-specific, read-only security auditing focused on the controls that matter to Follica's Rails application.

### Use when

- Reviewing authentication or authorization changes.
- Reviewing Pundit policies and policy enforcement.
- Auditing Avo/admin access.
- Reviewing patient/clinical-data access paths.
- Reviewing external API/webhook endpoints.
- Performing a pre-release Rails security audit.
- Verifying that a new or changed resource has full authorization test coverage across every actor/resource combination (Patient/Doctor/Admin/Guest × own/other's/nonexistent record) — see `gems.md` Section 15A for the required matrix. A policy existing without this test coverage is an audit finding, not a pass.

### Review scope

- Run/analyze **Brakeman** findings.
- Validate **Pundit** policies and authorization enforcement.
- Review against the **OWASP Top 10**.
- Look for authentication, authorization, injection, session, file-upload, SSRF, secrets, and data-exposure risks.
- Remain **read-only**: do not modify application code while auditing.

### Agent rule

For Rails security audits, prefer this skill over CodeBurn. CodeBurn remains useful for general code-quality review, but it is not the authoritative Rails security-audit route.

---

## 2.13 HIPAA/PHI Compliance — healthcare compliance

**Purpose:** Review and guide implementation handling protected health information (PHI) and healthcare-sensitive data.

### Use when

- Adding or modifying patient/clinical data models.
- Handling medical records, clinical notes, medical images, insurance data, identity data, or other PHI.
- Designing access-control boundaries for patients, doctors, clinics, staff, and admins.
- Designing encryption and secrets handling.
- Designing audit logging and change history.
- Reviewing logs, Sentry, search indexes, exports, backups, or integrations for PHI exposure.
- Defining retention/deletion workflows for healthcare data.
- Performing a healthcare privacy/compliance review.

### Review scope

- PHI identifiers and data classification.
- Least-privilege access control.
- Encryption at rest/in transit where applicable.
- Audit logging and accountability.
- Secure private document storage.
- Logging/error-monitoring minimization.
- Search-index and analytics exposure.
- Retention and deletion controls.
- Third-party/service-provider exposure and contractual/compliance considerations.

### Agent rule

This skill provides an engineering/compliance review framework. It does **not** by itself certify Follica as HIPAA compliant. Legal, organizational, infrastructure, contractual, and operational requirements must also be satisfied.

---

## 2.14 MarkItDown — Microsoft

**Purpose:** Convert PDFs, DOCX, PPTX, XLSX and other files into AI-readable Markdown/text.

### Use when

- Reading external documentation.
- Extracting structured information from documents.
- Converting reference files into agent-readable content.
- Reviewing requirements supplied as office documents.

### Agent rule

Do not manually infer document contents when the source can be converted and inspected.

---

## 2.15 Image-to-Code Skill — Leonxlnx

**Purpose:** Convert screenshots/design references into frontend code.

### Use when

- The user provides a screenshot to reproduce.
- Converting a Figma/design reference into Rails views.
- Recreating a dashboard layout.
- Matching an existing visual reference.

### Agent rule

Use the screenshot as a visual specification, but preserve Follica's existing architecture and reusable components.

---

## 2.16 Claude-SEO — agricDaniel

**Purpose:** SEO analysis and website/content optimization.

### Use when

- Building public clinic pages.
- Building doctor pages.
- Building villa pages.
- Building medical-tourism landing pages.
- Improving search visibility.
- Reviewing metadata and structured content.

### Agent rule

SEO optimization must not expose private patient data.

---

## 2.17 Headroom — Headroom Labs AI

**Purpose:** Manage LLM context so long agent sessions remain efficient.

### Use when

- Long coding sessions.
- Large repositories.
- Large documentation sets.
- Multi-stage debugging.
- Long-running agent workflows.

### Agent rule

Keep the active context focused on the current task. Retrieve additional context only when necessary.

---

## 2.18 Variate

**Purpose:** Add an in-app menu for generating, comparing, and selecting multiple design variations for specific UI sections.

### Use when

- A UI section has multiple viable design directions.
- Comparing dashboard cards.
- Comparing hero sections.
- Testing different booking-flow layouts.
- Exploring navigation alternatives.

### Agent rule

Generate variations for a specific decision, not random redesigns of the whole application.

---

## 2.19 Marketing Skills

**Purpose:** Integrate business logic such as onboarding, paywalls, conversion optimization, and churn reduction directly into the application.

### Use when

- Building clinic onboarding.
- Building villa-owner onboarding.
- Designing package conversion flows.
- Building lead capture.
- Designing upgrade/paywall flows.
- Improving patient conversion.
- Building retention workflows.

### Agent rule

Business logic must remain explicit and testable. Do not hide critical rules inside presentation-only code.

---

# 3. Scraping Skills

## 3.1 Scrapling — d4vinci

**Purpose:** Production-grade adaptive web scraping and crawling.

### Use when

- Collecting structured public information from websites.
- Building data-ingestion pipelines.
- Researching clinics, villas, travel providers, or public listings.
- Maintaining crawlers where websites change structure.

### Agent rule

Respect:
- robots.txt where applicable
- website terms
- rate limits
- privacy requirements
- copyright
- authentication boundaries

Never scrape private accounts or restricted data.

---

## 3.2 Agent-Reach — Panniantong

**Purpose:** Give AI agents broad access to information across web platforms and online sources.

### Use when

- A research task requires information across multiple online platforms.
- Comparing public information from different sources.
- Gathering broad market intelligence.

### Agent rule

Treat retrieved information as external data that must be evaluated for reliability.

Do not treat third-party claims as verified facts without appropriate validation.

---

## 3.3 ScrapeGraphAI

**Purpose:** AI-powered extraction pipelines that turn websites and documents into structured data.

### Use when

- Website structures vary substantially.
- Information must be extracted into structured records.
- Building research datasets.
- Converting unstructured web/document content into normalized data.

### Agent rule

Validate extracted data before writing it into authoritative Follica tables.

Recommended flow:

```text
Source
 ↓
Extract
 ↓
Validate
 ↓
Normalize
 ↓
Human/automated verification
 ↓
PostgreSQL
 ↓
Meilisearch if appropriate
```

Never allow raw scraper output to become trusted clinical or operational data automatically.

---

# 4. Tools

## 4.1 CLI-Anything — HKUDS

**Purpose:** Turn applications into CLI-accessible tools that AI agents can operate.

### Use when

- An application needs repeatable CLI automation.
- An agent needs deterministic command-based control.
- Building local developer workflows.
- Automating supported application operations.

### Agent rule

Prefer deterministic CLI commands over fragile UI automation when the application provides a reliable CLI interface.

Use Playwright when browser behavior itself needs to be tested.

---

# 5. Skill Selection Matrix

| Task | Primary skills | Secondary skills |
|---|---|---|
| New Rails feature | Rails Conventions, Superpowers | Graphify, Context7, CodeBurn |
| Understand existing code | Graphify, Rails Conventions | Skill Retrieval |
| New UI | Frontend Design | Impeccable, Web Design Guidelines, Variate |
| UI polish | Impeccable | Human Review, Web Design Guidelines |
| Screenshot → UI | Image-to-Code | Frontend Design, Human Review |
| Browser testing | Playwright CLI | Superpowers, CodeBurn |
| General code-quality review | CodeBurn | Rails Conventions, Superpowers |
| Rails security audit | Rails Security Audit | CodeBurn |
| HIPAA / PHI review | HIPAA/PHI Compliance | Rails Security Audit |
| Gem/API usage | Context7 | Rails Conventions |
| Long coding session | Headroom | Skill Retrieval |
| SEO | Claude-SEO | Web Design Guidelines |
| Clinic/villa research | Agent-Reach, Scrapling | ScrapeGraphAI |
| Structured scraping | Scrapling, ScrapeGraphAI | Agent-Reach |
| Document extraction | MarkItDown | Context7 |
| Admin/support workflow | Rails Conventions | Avo architecture + Human Review |
| Clinic onboarding | Marketing Skills, Rails Conventions | Frontend Design, Playwright |
| Villa onboarding | Marketing Skills, Rails Conventions | Frontend Design, Playwright |
| Design alternatives | Variate | Impeccable, Human Review |
| CLI automation | CLI-Anything | Superpowers |
| Large repository task | Graphify, Headroom | Skill Retrieval |

---

# 6. Recommended Skill Combinations for Follica

**These are feature-lifecycle roadmaps, not single retrieval batches.** Each combination below spans a feature's full build across multiple separate tasks over time — it is never one `skill-retrieval-mcp` call. Every phase shown is its own task with its own targeted retrieval, returning the 1–3 skills that phase needs (Section 1). Retrieving an entire combination at once for a single task is the exact "load everything" failure mode Section 1 prohibits — it burns context and stalls the agent before it writes any code. If a real task somehow needs more than 3 skills at once, that is a sign the task should be broken into smaller phases like the ones below, not a reason to retrieve them all together.

## Patient Dashboard

```text
Phase 1 — Understand & build the data/backend layer
Skill Retrieval → Graphify → Rails Conventions

Phase 2 — Security/compliance pass on that data layer
Skill Retrieval → Rails Security Audit → HIPAA/PHI Compliance

Phase 3 — Build the UI
Skill Retrieval → Frontend Design

Phase 4 — Pre-ship UI review
Skill Retrieval → Web Design Guidelines

Phase 5 — Verify & review
Skill Retrieval → Playwright CLI → CodeBurn
```

Add Impeccable/Human Review as its own phase only when visual polish is explicitly required — not by default.

---

## Foreigner Medical-Tourism Dashboard

```text
Phase 1 — Understand & build the data/backend layer
Skill Retrieval → Graphify → Rails Conventions

Phase 2 — Security/compliance pass (only for the clinic/consultation parts)
Skill Retrieval → Rails Security Audit → HIPAA/PHI Compliance (when clinic/consultation data is involved)

Phase 3 — Build the UI + conversion flow
Skill Retrieval → Frontend Design → Marketing Skills

Phase 4 — Pre-ship UI review
Skill Retrieval → Web Design Guidelines

Phase 5 — Verify
Skill Retrieval → Playwright CLI
```

Relevant areas:

- Clinic discovery
- Consultation
- Travel planning
- Flights
- Visa information
- Villa/recovery stay
- Transfers
- Entertainment
- Packages
- Booking

---

## Clinic Onboarding

```text
Phase 1 — Build the flow
Skill Retrieval → Rails Conventions → Marketing Skills

Phase 2 — Build the UI
Skill Retrieval → Frontend Design

Phase 3 — Verify & review
Skill Retrieval → Playwright CLI → CodeBurn
```

Must verify:

- Registration
- Clinic profile
- Doctor association
- Documents
- Verification status
- Admin review
- Public visibility
- Search indexing

---

## Villa Onboarding

```text
Phase 1 — Build the flow
Skill Retrieval → Rails Conventions → Marketing Skills

Phase 2 — Build the UI
Skill Retrieval → Frontend Design

Phase 3 — Verify & review
Skill Retrieval → Playwright CLI → CodeBurn
```

Must verify:

- Owner identity/account
- Villa listing
- Photos
- Amenities
- Location
- Pricing
- Availability
- Verification
- Inspection workflow
- Public search visibility

---

## Admin / Avo

```text
Phase 1 — Understand & build
Skill Retrieval → Rails Conventions → Graphify

Phase 2 — Security/compliance pass
Skill Retrieval → Rails Security Audit → HIPAA/PHI Compliance (when patient data is exposed)

Phase 3 — Verify & review
Skill Retrieval → CodeBurn → Playwright CLI
```

Avo is the operational console.

Agent must enforce:

- Pundit authorization
- Sensitive-field restrictions
- Audit history
- Pretender impersonation is permitted only against non-production/demo/seed data. It must not be usable to impersonate an account that can access real patient records in production. If a legitimate production impersonation need arises, it requires its own audit-logged, HIPAA/PHI Compliance-reviewed design — do not extend Pretender's default behavior to cover it.
- No accidental patient-data exposure

---

## External API Integration

```text
Phase 1 — Understand the API + plan
Skill Retrieval → Context7 → Rails Conventions (add Superpowers only if the integration is substantial)

Phase 2 — Security/compliance pass
Skill Retrieval → Rails Security Audit → HIPAA/PHI Compliance (when PHI crosses the integration boundary)

Phase 3 — Verify & review
Skill Retrieval → CodeBurn → Playwright / integration tests
```

Required:

- Timeouts
- Error handling
- Retry strategy
- Logging without secrets/PHI
- Webhook verification where applicable
- Idempotency
- Test fixtures
- Provider failure handling

---

# 7. Medical Data Rules

This section is an application-level policy baseline. It is **not a substitute for a specialist skill**.

Whenever a task touches patient/clinical data, the agent must query `skill-retrieval-mcp` for **HIPAA/PHI Compliance** and, when Rails security/authorization is involved, **Rails Security Audit**.

Skills do not override application security.

For patient/clinical data:

1. Identify who may access the data.
2. Apply Pundit authorization.
3. Decide whether fields require encryption.
4. Decide whether PaperTrail should record changes.
5. Decide whether data may appear in logs.
6. Decide whether data may appear in Sentry.
7. Decide whether data may enter Meilisearch.
8. Define retention/deletion behavior.
9. Test unauthorized access.
10. Keep private documents in private storage.
11. Restrict Pretender-based account impersonation to non-production/demo data. Production impersonation of any account with access to real patient records is disabled by default and requires a separate, audit-logged, HIPAA/PHI Compliance-reviewed design.
12. A generated artifact (PDF report/prescription, ABDM QR token, export file) is PHI the moment it's created if it contains or resolves to patient/clinical data — apply the same access/storage/retention rules to it as to the source record. See Section 11 for the Grover/hexapdf and rqrcode routing.
13. Batch/backfill operations against production tables holding patient data (`maintenance_tasks`, `online_migrations`) require the same Rails Security Audit / HIPAA/PHI Compliance review as any other code path touching PHI — "it's just a data migration" is not an exemption.

Never put these into public search indexes:

```text
Clinical notes
Identity documents
Insurance information
Private medical images
Authentication secrets
```

---

# 8. Skill Activation Rules for AI Coding Agents

## Mandatory operating procedure

When receiving a new Follica task:

```text
1. Read the task.
2. Identify the job/capability required.
3. Query skill-retrieval-mcp for the approved skill for that job.
4. Load ONLY the returned relevant skill instructions.
5. Inspect the existing Follica architecture.
6. Check gems.md.
7. Plan the change.
8. Implement.
9. Test the actual behavior.
10. Run security/code review when appropriate.
11. Run visual review when UI is involved.
12. Report what changed, tests performed, and remaining issues.
```

## Explicit prohibition

The agent must **not** preload or activate every skill in `skills.md`.

`skills.md` is intentionally designed to be lightweight enough to act as a routing reference.

The detailed skill content belongs to the individual skill packages and should be retrieved through `skill-retrieval-mcp` only when required.

## Examples

### "Fix the patient booking double-submit bug"

Retrieve:
- Rails Conventions

Potentially retrieve:
- Playwright CLI — if reproducing the issue in the browser
- Rails Security Audit — if the fix touches authorization/security (this is a double-submit/booking bug — also check it against the idempotency rules in `gems.md` Section 14B)
- CodeBurn — for a general code-quality pass on the fix itself, separate from the security question

Do not retrieve:
- Frontend Design
- Claude-SEO
- Scrapling
- MarkItDown
- Image-to-Code

unless the task expands to require them.

### "Redesign the foreigner dashboard"

Retrieve:
- Frontend Design
- Web Design Guidelines

Then retrieve only if needed:
- Impeccable
- Human Review
- Variate
- Image-to-Code

### "Add Duffel flight search"

Retrieve:
- Context7
- Rails Conventions

Then potentially:
- Superpowers
- CodeBurn
- Rails Security Audit
- HIPAA/PHI Compliance
- Playwright CLI

### "Research 50 clinics and import public information"

Retrieve:
- Scrapling
- ScrapeGraphAI

Potentially:
- Agent-Reach

Then validate the resulting data before writing to PostgreSQL.

---

# 9. Skill Routing Priority

These levels are **routing hints**, not preload instructions.

## Build-phase gating

Follica's scope spans a clinical/telehealth core (scheduling, PHI, ABDM, Devise 2FA) and a full travel OTA layer (flights, villas, insurance, maps). Building both simultaneously is a bloat risk in itself, independent of skill count.

Until the core clinical booking + villa/travel workflows work end-to-end (patient can find a doctor, book, pay, and see the booking; a villa/package can be listed and booked), do **not** retrieve:

- Level 3 (Specialized): Claude-SEO, MarkItDown, Headroom, CLI-Anything
- Level 4 (Research/data collection): Scrapling, Agent-Reach, ScrapeGraphAI
- Marketing Skills

These are growth/scale-phase concerns — public SEO, bulk clinic/villa data ingestion, marketing/conversion optimization, and CLI tooling — appropriate once the core platform is live, not during initial build.

## Level 0 — Router

- Skill Retrieval

Always use this when the task is non-trivial and the correct specialist skill is not already obvious.

## Level 1 — Core development

Retrieve when the job requires them:

- Rails Conventions
- Superpowers
- Graphify
- Context7
- CodeBurn
- Rails Security Audit
- HIPAA/PHI Compliance
- Playwright CLI

## Level 2 — UI / product

Retrieve only for relevant UI/product work:

- Frontend Design
- Web Design Guidelines
- Impeccable
- Human Review
- Image-to-Code Skill
- Variate
- Marketing Skills

## Level 3 — Specialized

Retrieve only when the task requires them:

- Claude-SEO
- MarkItDown
- Headroom
- CLI-Anything

## Level 4 — Research / data collection

Retrieve only for research/scraping work:

- Scrapling
- Agent-Reach
- ScrapeGraphAI

---

# 10. Golden Rule

> **Use the smallest set of approved skills that can complete the task correctly.**

The agent should not activate a skill because it is available.

It should activate a skill because the current task requires that capability.

---

# 11. Named Follica Integration / Platform Skills

## Razorpay

When implementing or modifying Razorpay payments, checkout, refunds, subscriptions, payment webhooks, or payment-related data flows:

```text
Query skill-retrieval-mcp
        ↓
Context7 — current Razorpay API/docs
        ↓
Rails Conventions
        ↓
Rails Security Audit
        ↓
Playwright / integration tests when applicable
```

Required regardless of provider:

- Verify webhook signatures before trusting payload data.
- Never log full card/bank/UPI details or API secrets.
- Idempotency on payment-status webhooks (Razorpay can retry).
- Reconcile Razorpay payment/order status against Follica's own booking/payment records rather than trusting client-side confirmation alone.

Do not treat payment-provider documentation or remembered API syntax as authoritative; retrieve current documentation before implementation.

## Meilisearch

When implementing or modifying Meilisearch indexing, search behavior, filters, synchronization, or searchable-data design:

```text
Query skill-retrieval-mcp
        ↓
Context7 — current Meilisearch API/docs
        ↓
Rails Conventions
        ↓
HIPAA/PHI Compliance when patient/clinical data could enter the index
        ↓
Rails Security Audit when access-control/data-exposure risks are involved
```

PostgreSQL remains Follica's source of truth. Never put clinical notes, identity documents, insurance information, private medical images, authentication secrets, or other restricted PHI into public search indexes.

## Clinical Document Generation (Grover / hexapdf)

This routing exists for the compliance dimension, not the library API — calling Grover/hexapdf is a few lines and doesn't need a skill lookup on its own. A plain `@media print` view (no stored file, no patient data leaving the browser) doesn't need this either; use Rails Conventions directly.

Retrieve this specifically when the PDF will be **stored, emailed, or shared** — that's when a generated file becomes PHI the instant it exists, which is the actual thing worth a compliance check. When generating such a PDF from Rails views — consultation summaries, prescriptions, appointment/booking receipts, travel vouchers, Razorpay invoices:

```text
Query skill-retrieval-mcp
        ↓
Context7 — current Grover/hexapdf API docs
        ↓
Rails Conventions
        ↓
HIPAA/PHI Compliance — the generated file is PHI the moment it exists, whenever it contains patient/clinical data
        ↓
Rails Security Audit — private storage, access control, no public URL
```

Generate in a Solid Queue job, not inline in the request cycle. The resulting PDF follows the same private-storage/no-public-search/retention rules as any other patient document (see Medical Data Rules).

## ABDM QR / Check-in Tokens (rqrcode)

Generating a QR code with rqrcode is a few lines of Ruby and doesn't need a skill lookup by itself. This routing exists because of what the QR code *encodes*: if it resolves to a patient/health identifier, that's PHI-adjacent regardless of how trivial the QR-generation code is. When implementing ABDM "Scan & Share" QR generation or clinic desk check-in tokens:

```text
Query skill-retrieval-mcp
        ↓
Context7 — current ABDM/rqrcode API docs
        ↓
Rails Conventions
        ↓
HIPAA/PHI Compliance — a QR token that encodes or resolves to a patient/health identifier is PHI-adjacent
```

Do not invent ABDM workflows or token formats; confirm the exact ABDM specification before implementation (see `gems.md` Section 34).

## Batch/Backfill Data Operations (maintenance_tasks / online_migrations)

When backfilling encrypted attributes, migrating historical records, re-indexing discarded data, or running a zero-downtime schema change against production tables that hold patient/clinical data:

```text
Query skill-retrieval-mcp
        ↓
Rails Conventions
        ↓
Rails Security Audit — this is exactly the kind of large-scale, production-data-touching change it exists to review
        ↓
HIPAA/PHI Compliance — when the task or backfill touches patient/clinical fields
```

Gate any `maintenance_tasks` dashboard behind the same admin authentication/Pundit checks as Avo — it is an operational surface, not a public page. Throttle/pause rather than running unattended against production PHI for the first execution.

---

# 12. Relationship With gems.md

`gems.md` controls:

- Rails architecture
- Ruby dependencies
- Gem selection
- Installation
- Updating
- Security dependencies
- External services
- Agent dependency rules

`skills.md` controls:

- Agent capabilities
- Skill selection
- Development workflow
- UI review
- Browser testing
- Code review
- Research/scraping
- Context management
- Product/marketing workflows

They work together:

```text
                 Follica
                    │
          ┌─────────┴─────────┐
          │                   │
       gems.md            skills.md
          │                   │
   What the app uses     How agents work
          │                   │
          └─────────┬─────────┘
                    │
             AI coding agent
                    │
              Rails 8 app
```

---

# 12A. Definition of Done

Writing code that appears to work is not the finish line. A Follica
task is done only when every applicable item below is true — "applicable"
meaning the agent has actually checked each one against the task, not
skipped the check because the task "seemed simple."

```text
[ ] The actual requested behavior works, including edge cases
    identified during implementation, not just the happy path.

[ ] Tests exist and pass:
      - Model/request/system specs for the new behavior (gems.md §15)
      - If a new/changed Pundit policy is involved: the full
        actor × resource authorization matrix is tested
        (gems.md §15A), not just "an admin can do it"
      - No new Bullet (N+1) warnings introduced (gems.md §14C)

[ ] Data integrity is enforced at the DB level where it must hold
    (uniqueness, foreign keys, NOT NULL, check constraints) —
    not only as a model validation (gems.md §14A / Core Rule 17)

[ ] If the change touches booking, payment, or any multi-step write:
    it is transactional and idempotent per gems.md §14B —
    double-submit and webhook-retry cases are handled, not assumed away

[ ] If the change touches patient/clinical data: the Section 7 /
    gems.md §38 checklist has actually been walked, not assumed —
    access control, encryption, PaperTrail, logs, Sentry, search
    indexing, and retention are each a deliberate decision

[ ] Security/compliance review has been retrieved and applied where
    the task warrants it (Rails Security Audit and/or HIPAA/PHI
    Compliance — §2.12/§2.13) — "I wrote the code carefully" is not a
    substitute for retrieving the review skill when the task type
    calls for it

[ ] CodeBurn or an equivalent general-quality pass has been applied to
    non-trivial changes — a separate concern from the security review
    above, not a replacement for it

[ ] Migrations (if any) follow the expand/contract sequencing in
    gems.md §36 and pass strong_migrations/online_migrations checks

[ ] CI gates in gems.md §35B are green: rspec, rubocop, brakeman,
    bundler-audit, Bullet, coverage — the agent does not report a task
    complete with a red or skipped check, and does not disable a check
    to make it pass

[ ] A rollback path exists and was considered for anything shipping to
    production (gems.md §37B) — not necessarily executed, but thought
    through

[ ] The agent's final report states what changed, what was tested,
    what was deliberately deferred (and why), and any remaining risk —
    not just "done."
```

If any box can't honestly be checked, the task is not done — say so
explicitly, rather than reporting completion and letting the gap
surface later as a bug, an incident (§38A), or a failed audit.

---

# 13. Final Agent Instruction

For every substantial Follica task:

> **Do not load all skills. First identify the job, then ask `skill-retrieval-mcp` which approved skill(s) are appropriate for that exact job. Load only those skill instructions. Then finish the job against the Definition of Done (Section 12A) — writing the code is the midpoint of this workflow, not the end of it.**

**"Write the code" is never a complete interpretation of this instruction on its own.** A task is not finished when the code compiles, runs, or looks correct on inspection. It is finished when Section 12A can honestly be checked off — tests written and passing, authorization matrix covered where relevant, DB integrity enforced, security/compliance review retrieved where the task calls for it, CI gates green, and a final report stating what was actually verified. An agent that stops at working code and reports the task complete has not followed this instruction, regardless of code quality.

The agent should think in terms of:

```text
WHAT JOB AM I DOING?
        ↓
WHICH SKILL OWNS THIS JOB?
        ↓
ASK skill-retrieval-mcp
        ↓
LOAD ONLY THAT SKILL
        ↓
DO THE WORK
        ↓
WHICH REVIEW SKILL(S) DOES THIS TASK REQUIRE?
        ↓
RETRIEVE AND APPLY THEM
        (Rails Security Audit / HIPAA-PHI Compliance / CodeBurn —
         not optional add-ons, required steps for the applicable task type)
        ↓
CHECK AGAINST SECTION 12A, ITEM BY ITEM
        ↓
ONLY NOW: REPORT THE TASK AS DONE
        (and if a box can't be checked, report that gap explicitly
         instead of reporting completion)
```

Skipping straight from "DO THE WORK" to "REPORT THE TASK AS DONE" is the exact failure mode this section exists to prevent. The review and verification steps are part of the task, not a separate task the agent may or may not get to.

If the work crosses domains, retrieve the additional skill only when the new capability is actually needed.

Examples:

```text
New Rails model
→ Rails Conventions

Complex feature
→ Superpowers + Rails Conventions

Understand architecture
→ Graphify

Current API documentation
→ Context7

New UI
→ Frontend Design + Web Design Guidelines

UI polish
→ Impeccable

Visual approval
→ Human Review

Screenshot recreation
→ Image-to-Code

Browser E2E
→ Playwright CLI

General code-quality audit
→ CodeBurn

Rails security audit
→ Rails Security Audit

HIPAA / PHI review
→ HIPAA/PHI Compliance + Rails Security Audit

SEO
→ Claude-SEO

Document conversion
→ MarkItDown

Public web scraping
→ Scrapling / ScrapeGraphAI

Long context session
→ Headroom

Design alternatives
→ Variate

Onboarding/conversion logic
→ Marketing Skills

CLI automation
→ CLI-Anything
```

**Never treat the list above as a command to preload those skills. It is a routing table for targeted retrieval through `skill-retrieval-mcp`.**
