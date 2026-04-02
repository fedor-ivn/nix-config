# Evaluation Rubric

**Scope:** Broad tech (SWE, PM, Data roles) | **Mode:** Intrinsic quality (no JD required)

---

## 1. Document Contract

### Purpose
This rubric defines the complete evaluation logic for assessing a tech CV on its intrinsic quality, independent of any specific job description. All scoring decisions must be traceable to a criterion in this document.

### What "Intrinsic Quality" Means
A CV scores well intrinsically when it clearly communicates who the candidate is, what they have accomplished, at what scale and impact, and what trajectory they are on. A high intrinsic score means the CV would perform well across a range of relevant tech roles.

### Out of Scope
- JD keyword alignment or semantic match to a specific role
- ATS parseability or keyword optimization
- Interview performance prediction
- Compensation benchmarking
- Role-specific domain evaluation beyond evidence in the CV

### Source Foundation
Every criterion in this rubric is grounded in at least one of the following:
- **[Orosz]**: *The Tech Resume Inside Out*, Gergely Orosz
- **[Bock-XYZ]**: Google XYZ Formula, Laszlo Bock (*Work Rules!* + public statements)
- **[Burns]**: Burns et al., *The Resume Research Literature*
- **[TIH]**: Tech Interview Handbook

---

## 2. Scoring Schema

### 2.1 Dimensions and Weights

| # | Dimension | Weight | Layer |
|---|---|---|---|
| D1 | Impact & Achievement Communication | 25% | Bullet |
| D2 | Quantification | 20% | Bullet |
| D3 | Clarity & Conciseness | 15% | Bullet + Document |
| D4 | Structure & Formatting | 15% | Document + Section |
| D5 | Career Progression & Trajectory | 10% | Document + Section |
| D6 | Technical Signal Quality | 10% | Section + Bullet |
| D7 | Spelling, Grammar & Professionalism | 5% | Document |

**Total: 100%**

### 2.2 Per-Dimension Scoring Scale

Each dimension is scored **1-4**:

| Score | Label | Meaning |
|---|---|---|
| 4 | Exemplary | Exceeds expectations for inferred level; no meaningful improvements possible |
| 3 | Proficient | Meets expectations for level; minor improvements available |
| 2 | Developing | Partially meets expectations; clear, fixable gaps present |
| 1 | Insufficient | Significantly below expectations; fundamental problems |

Half-scores (for example `2.5`) are permitted when evidence sits clearly between anchors.

### 2.3 Composite Score Formula

```
Composite = sum(dimension_score * dimension_weight)
Normalized to 0-100 by: ((composite - 1) / 3) * 100
```

Composite interpretation:

| Range | Label |
|---|---|
| 85-100 | Exceptional |
| 70-84 | Strong |
| 55-69 | Adequate |
| 40-54 | Weak |
| 0-39 | Poor |

### 2.4 Hard Gates (Pre-Score)

One gate runs before dimensional scoring. Failure blocks a full evaluation.

| Gate | Condition | Action on Failure |
|---|---|---|
| **G1: Minimum Content** | At least one Experience or Project section with at least two entries | Return gate failure; CV is too sparse to evaluate meaningfully. |

### 2.5 Companion References

- Level inference and level-calibrated expectations: `level-profiles.md`
- Bullet-level XYZS calibration (0-4): `xyz-examples.md`
- Required output format: `../assets/output-template.md`

---

## 3. Dimension Rubrics

### D1 - Impact & Achievement Communication
**Weight: 25% | Layer: Bullet | Source: [Bock-XYZ], [Orosz], [Burns]**

#### Definition
Does each bullet communicate what the candidate accomplished, not just what they were responsible for? Achievement bullets describe an outcome or change produced by the candidate's actions.

#### Operationalization
For each bullet, classify it:
- **Achievement bullet:** states a result, outcome, or change.
- **Responsibility bullet:** describes a task or role without outcome.
- **Mixed bullet:** contains task context and partial outcome, but outcome is vague or incomplete.

Apply the **XYZS** test:
- **X (Achievement):** what was accomplished
- **Y (Measurement):** quantified or concrete outcome
- **Z (Method):** how it was done
- **S (Scope/Context):** scale or business/operational context

Use `xyz-examples.md` for calibrated 0-4 XYZS bullet scoring.

Weak patterns to flag:
- "Responsible for..."
- "Worked on..."
- "Helped with..."
- "Assisted in..."
- "Involved in..."
- Vague impact claims such as "improved performance" without magnitude or scope

#### Scoring Guide

| Score | Criteria |
|---|---|
| 4 | >=80% of bullets are achievement bullets; XYZ compliance is high; vague impact language is absent |
| 3 | 60-79% achievement bullets; some mixed bullets; limited responsibility bullets |
| 2 | 40-59% achievement bullets; mixed/responsibility bullets are common |
| 1 | <40% achievement bullets; most bullets describe duties only |

### D2 - Quantification
**Weight: 20% | Layer: Bullet | Source: [Bock-XYZ], [Burns], [Orosz]**

#### Definition
Numbers convert vague claims into verifiable, comparable evidence.

#### Operationalization
For each bullet, check for at least one valid quantifier.

| Type | Examples |
|---|---|
| Percentage change | "reduced by 40%", "increased by 3x" |
| Absolute scale | "serving 10M users", "200+ endpoints" |
| Dollar value | "$2M savings", "$120k/month cloud reduction" |
| Time/speed | "2 hours to 8 minutes", "3x faster deploys" |
| Ranking/tier | "#1 in category", "top 10%" |
| Frequency | "500k events/day", "deployed weekly" |

Quantification rate = bullets with >=1 quantifier / total bullets.

Hedged quantification to flag:
- "significantly improved"
- "large team"
- "millions of records"
- "many customers"

#### Scoring Guide

| Score | Criteria |
|---|---|
| 4 | >=70% of bullets quantified; numbers are specific and credible |
| 3 | 50-69% quantified; most impactful bullets have numbers |
| 2 | 30-49% quantified; key achievements lack numbers |
| 1 | <30% quantified; claims are largely unverifiable |

### D3 - Clarity & Conciseness
**Weight: 15% | Layer: Bullet + Document | Source: [Orosz], [TIH], [Burns]**

#### Definition
Bullets and sections should communicate high signal with minimal friction.

#### Operationalization
Bullet-level checks:
- Target 15-30 words per bullet; flag bullets over 3 lines.
- Flag passive constructions: "was responsible for", "was involved in".
- Flag buzzword padding and redundant verb pairs.
- Flag unclear jargon without context.

Action verb quality:
- Strong verbs: Architected, Reduced, Drove, Shipped, Led, Established, Eliminated, Scaled, Redesigned, Automated, Migrated.
- Weak verbs: Helped, Assisted, Supported, Worked on, Was responsible for, Participated in.
- Flag repeated use of the same verb more than three times within a role.

Document-level checks:
- Summary/objective, if present, should be specific and concise.
- Skills section should list skills, not narrative claims.

#### Scoring Guide

| Score | Criteria |
|---|---|
| 4 | Crisp, direct language; strong verb quality; minimal noise |
| 3 | Mostly clear with minor passive voice/redundancy issues |
| 2 | Noticeable verbosity, weak verbs, or vague phrasing |
| 1 | Pervasive clarity issues; signal extraction is difficult |

### D4 - Structure & Formatting
**Weight: 15% | Layer: Document + Section | Source: [Orosz], [TIH]**

#### Definition
A strong CV has logical section structure and consistent formatting that enables fast scanning.

#### Operationalization
Required section checklist:

| Section | Required | Notes |
|---|---|---|
| Contact information | Yes | Name, email, LinkedIn; location recommended |
| Experience | Yes | Reverse chronological with company/title/dates/bullets |
| Skills / Technical Skills | Yes (tech roles) | Scannable and structured |
| Education | Yes | Degree, institution, graduation year |
| Projects | Recommended | Strongly recommended for early-career candidates |
| Summary / Objective | Optional | Valuable only when specific |

Consistency checks:
- Date format consistency throughout.
- Bullet style consistency throughout.
- Each role clearly shows company, title, and dates.
- Parallel bullet structure within roles.
- Length proportional to experience depth.

Information hierarchy checks:
- Recent role should be prominent.
- Role headers should be visually distinct from bullets.
- Section headers should be easy to identify.

#### Scoring Guide

| Score | Criteria |
|---|---|
| 4 | Complete, consistent structure with clear hierarchy |
| 3 | Strong structure with minor formatting inconsistencies |
| 2 | Noticeable structural/formatting issues or missing recommended sections |
| 1 | Missing required sections or hard-to-navigate layout |

### D5 - Career Progression & Trajectory
**Weight: 10% | Layer: Document + Section | Source: [Orosz], [Burns]**

#### Definition
A strong CV should make growth in scope and responsibility legible over time.

#### Operationalization
Progression signals:
- Title advancement
- Scope growth in bullets
- Team/org scale growth
- Escalating ownership across roles

Context-only flags (do not auto-penalize):
- Long periods with flat title and scope
- Gaps that may need context
- Weak recency weighting in detail

Gap handling:
- <=6 months: do not flag
- 6-18 months: note as context
- >18 months: flag as context recommended

Do not penalize gaps directly.

#### Scoring Guide

| Score | Criteria |
|---|---|
| 4 | Clear upward trajectory; recent roles carry strongest signal |
| 3 | Progression visible with minor narrative gaps |
| 2 | Progression unclear or flat in visible scope |
| 1 | No coherent growth narrative |

### D6 - Technical Signal Quality
**Weight: 10% | Layer: Section + Bullet | Source: [Orosz], [TIH]**

#### Definition
Skills and experience bullets should present a credible, specific picture of technical depth relevant to the candidate's role type.

#### Operationalization
Skills section checks:
- Flag over-listing (especially long uncategorized lists).
- Prefer grouped skill categories.
- Verify proficiency claims against evidence in experience bullets.
- Check for recency plausibility of listed technologies.

Bullet-level depth checks:
- Generic mentions provide weak signal.
- Specific implementation/context details provide strong signal.
- Flag technology name-dropping without concrete contribution details.

Role-type calibration:
- SWE: code, systems, delivery, quality, reliability depth.
- PM: product metrics and cross-functional outcomes; deep coding detail not required.
- Data: SQL/Python baseline and data/ML pipeline scale where applicable.

#### Scoring Guide

| Score | Criteria |
|---|---|
| 4 | Curated skills and strong depth evidence in bullets |
| 3 | Mostly credible signal with minor vagueness/over-listing |
| 2 | Inconsistent or generic technical signal |
| 1 | Superficial or unreliable technical signal |

### D7 - Spelling, Grammar & Professionalism
**Weight: 5% | Layer: Document | Source: [Burns], [Orosz]**

#### Definition
Language quality and professionalism influence trust and readability.

#### Operationalization
Check for:
- Spelling errors (including technology names)
- Grammar issues and tense inconsistency
- Punctuation inconsistency
- Unprofessional contact details or tone
- First-person pronouns in bullets

#### Scoring Guide

| Score | Criteria |
|---|---|
| 4 | Zero meaningful issues; fully consistent and professional |
| 3 | 1-2 minor issues with limited impact |
| 2 | Several noticeable language/professionalism issues |
| 1 | Pervasive errors and inconsistent professionalism |

---

## 4. Hard Constraints

### 4.1 Never Score These Signals
- School prestige
- Company prestige
- Career gaps (context-only)
- Non-linear career paths
- Demographic signals
- Hobbies/personal sections (unless factual errors affect professionalism)
- Number of jobs held by itself

### 4.2 Flag Inferences Under Uncertainty
Whenever conclusions rely on ambiguous evidence, explicitly record the inference in `bias_guardrail_notes`.

#### Mandatory Disclosure Triggers

| Trigger | Required Disclosure |
|---------|---------------------|
| Level inference Medium/Low confidence | State alternative level considered and how scoring would differ |
| Role type unclear | Note which calibration assumptions were applied (SWE/PM/Data) |
| Scope inferred not stated | Flag affected XYZS scores; note which bullets have inferred S component |
| Domain outside evaluator knowledge | Reduce D6 score_confidence to Medium or Low; explain limitation |
| Quantification plausibility uncertain | Flag in D2 confidence_reason; do not penalize but note concern |
| Career gap context missing | Note in D5 gap_flags as context-only; do not penalize |

#### Score Confidence Assignment Rules

Each dimension score must include `score_confidence` based on:

| Confidence | Criteria |
|------------|----------|
| **High** | Clear evidence in CV; no inference required; scoring criteria unambiguous |
| **Medium** | Some inference required; evidence partially supports score; minor ambiguity |
| **Low** | Significant inference; limited evidence; domain unfamiliarity; score could shift ±0.5 with more context |

### 4.3 Never Hallucinate Improvements
Rewrite suggestions must be grounded in actual CV content. Do not invent metrics. Use conditional phrasing when data is missing (for example: "If [metric] is available...").

### 4.4 Level-Appropriate Expectations
Apply level-calibrated thresholds from `level-profiles.md`. Score against the lower plausible level when uncertain and disclose the uncertainty.
