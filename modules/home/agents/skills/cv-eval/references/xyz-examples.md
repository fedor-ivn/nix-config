# XYZS Bullet Examples

This file calibrates bullet scoring on a 0-4 scale using the XYZS framework.

- `X` = Achievement (what changed)
- `Y` = Measurement (how much, how fast, how many, how often)
- `Z` = Method (how it was done)
- `S` = Scope/Context (scale, users, revenue, team, system criticality, constraints)

## 1. Scoring Scale (0-4)

| Score | Pattern | Interpretation |
|---|---|---|
| **0** | No X | Pure responsibility/task statement |
| **1** | X only | Outcome claim exists, but no measurement and no method |
| **2** | Two of XYZ | Partial evidence (XY or XZ), but still incomplete |
| **3** | Full XYZ | Strong bullet with measurable outcome and method, but no scope/context |
| **4** | Full XYZS | Complete, credible, and well-anchored impact statement |

## 2. Calibrated Examples

### Score 0: Responsibility only (no X)

- "Responsible for the backend of the payments service."
- "Worked on the data pipeline for analytics."

Why score 0: these lines describe duties, not outcomes.

### Score 1: X only

- "Improved onboarding completion for new users."
- "Enhanced reliability of the billing workflow."

Why score 1: achievement direction is stated, but there is no quantified result and no method.

### Score 2: Two of XYZ

- **XY example:** "Increased email deliverability from 92% to 98% across lifecycle campaigns."
- **XZ example:** "Reduced incident volume by automating alert deduplication and runbook routing."

Why score 2: each bullet has two components but still lacks one core element.

### Score 3: Full XYZ, no scope

- "Reduced search query latency by 35% by introducing a Redis caching layer for frequent queries."
- "Cut weekly release rollback rate from 8% to 2% by adding canary checks and automated smoke tests."

Why score 3: clear achievement + measurement + method, but the reviewer cannot judge scale/context.

### Score 4: Full XYZS

- "Redesigned the payments service from a monolith to event-driven microservices, reducing p99 latency from 800ms to 120ms and enabling 3x throughput across 12M monthly transactions, unblocking $4M ARR tied to SLA commitments."
- "Reduced failed checkout sessions by 27% by shipping an idempotent retry flow and queue-backed reconciliation for 5M monthly shoppers, lifting conversion by 3.1 points."

Why score 4: complete XYZS evidence with quantification and operational/business scale.

## 3. Fast Classification Rules

- If the bullet starts with "Responsible for", "Worked on", "Helped with", default to 0 unless a concrete outcome is also present.
- If there is no number and no concrete direction of change, never score above 1.
- If XYZ is present but scale is missing, cap at 3.
- If scope is inferred rather than explicit, keep score conservative and note uncertainty.

## 4. Common Rewrite Pattern

Transform weak bullets using this structure:

`[Action verb] [what changed] by [how], resulting in [measured outcome], at [scope/context].`

Example:
- Before: "Worked on API performance improvements."
- After: "Reduced API p95 latency from 420ms to 180ms by replacing synchronous fan-out calls with batched async workers for 3M daily requests."
