# Level Profiles

This document defines how to infer candidate level from CV evidence and how scoring expectations should be calibrated by level.

## 1. Level Inference

Infer level before dimension scoring using years of experience, role titles, and demonstrated scope.

| Level | Typical Signals | Expectation Shift |
|---|---|---|
| **Junior** | 0-3 years, internship/new-grad/junior IC titles | Local feature/team impact is acceptable; ownership may be narrow |
| **Mid** | 3-7 years, independent ownership of projects/features | Consistent measurable outcomes and cross-team/product contribution expected |
| **Senior** | 7-12 years, led systems/projects, mentoring signals | Strong quantification and org/user-facing impact expected |
| **Staff/Principal** | 12+ years or explicit staff+ titles | Leverage and cross-org influence expected in nearly every major bullet |
| **EM/Manager** | Any clear management title | Impact through people, systems, team outcomes, and org execution |

If level is ambiguous, score against the lower plausible level and record the uncertainty in `bias_guardrail_notes`.

## 2. Confidence Rules

| Confidence | Signals |
|---|---|
| **High** | Title, years, and scope all align |
| **Medium** | Two signals align; one is ambiguous |
| **Low** | Conflicting signals or limited experience detail |

## 3. Level-Calibrated Expectations by Dimension

Use this matrix to adjust expectations while keeping the same 1-4 scoring scale from `references/rubric.md`.

| Dimension | Junior | Mid | Senior | Staff/Principal | EM/Manager |
|---|---|---|---|---|---|
| **D1 Impact & Achievement** | A 3:1 achievement-to-responsibility ratio is acceptable. Mixed bullets can still score well if direction is clear. | Most bullets should express outcomes, not duties. | Responsibility bullets are rarely acceptable. High XYZ/XYZS coverage expected. | Bullets should show leverage and org-level outcomes, not only execution. | Bullets must show impact through teams/systems (delivery quality, hiring, retention, org metrics). |
| **D2 Quantification** | ~40% quantified bullets can still support score 3 when work scope is early-career. | Majority of high-impact bullets should be quantified. | <60% quantification is a warning signal; strong numeric evidence expected. | Quantification should cover strategic/system outcomes, not only task metrics. | Team/product/org metrics are expected (delivery, quality, growth, efficiency). |
| **D3 Clarity & Conciseness** | Minor wording noise is tolerable if impact is still legible. | Clear, direct bullets should be the norm. | Dense jargon, weak verbs, or long bullets should be rare. | Communication should be crisp at strategic and technical levels. | Language should clearly communicate leadership outcomes and operating cadence. |
| **D4 Structure & Formatting** | One page is typical and acceptable. Missing Projects is a concern for very early careers. | Structure should be stable and consistent across entries. | Two-page format is acceptable only when justified by depth and recency weighting. | Information hierarchy should make strategic scope easy to scan quickly. | Experience should clearly separate personal execution from team/org leadership scope. |
| **D5 Progression & Trajectory** | Promotion history is not required; internship -> FTE progression is a strong positive. | Increasing ownership should be visible across roles. | Scope growth and leadership signals should be explicit. | Cross-org influence and long-range ownership should be visible. | Progression should show larger teams/systems, not just title changes. |
| **D6 Technical Signal Quality** | Core stack competence with evidence in bullets is sufficient. | Skills should be curated and tied to concrete delivery examples. | Depth and architecture-level signal expected in major projects. | Strong depth plus technology judgment/selection rationale should appear. | For people managers, role-appropriate technical fluency is sufficient; evaluate technical depth relative to management scope. |
| **D7 Spelling/Grammar/Professionalism** | Same quality bar as all levels. | Same quality bar as all levels. | Same quality bar as all levels. | Same quality bar as all levels. | Same quality bar as all levels. |

## 4. Role-Type Calibration Notes

Role type changes emphasis, especially for D2 and D6:

- **SWE:** prioritize architecture, implementation depth, reliability/performance metrics, and delivery signal.
- **PM:** prioritize product and business metrics, decision quality, and cross-functional execution outcomes.
- **Data:** prioritize data scale, model/pipeline impact, experimentation, and productionization evidence.

If role type is unclear, choose the best-supported type from the CV and log uncertainty.
