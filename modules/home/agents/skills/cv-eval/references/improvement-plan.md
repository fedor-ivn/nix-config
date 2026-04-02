# CV-Eval Improvement Plan

**Source Inspiration:** [job-coach-and-scout](https://github.com/shindo107/job-coach-and-scout)

---

## Current State Summary

Your skill has solid foundations:
- 7-dimension scoring with weights (D1-D7)
- XYZS bullet-level analysis (0-4 scale)
- Level inference with confidence bands
- Composite score normalization (0-100)
- Structured JSON output

---

## Improvement Opportunities

### 1. Bullet-Level XYZS Detail Table

**Gap:** XYZS scores summarized at dimension level, but users don't see per-bullet scoring.

**Inspiration:** job-coach-and-scout tracks individual requirement matches with quoted evidence.

**Improvement:** Add `bullet_analysis` array to D1 and D2:

```json
"bullet_analysis": [
  {
    "text": "Reduced API latency by 40% using Redis caching",
    "xyzs_score": 2,
    "components": { "X": true, "Y": true, "Z": true, "S": false },
    "missing": "S: scale/context not stated",
    "rewrite_hint": "Add user/request volume or business context"
  }
]
```

**Benefit:** Pinpoints exactly which bullets need work; grounds rewrite suggestions.

---

### 2. Scoring Confidence per Dimension

**Gap:** Level inference has confidence, but dimension scores don't.

**Inspiration:** job-coach-and-scout uses confidence bands and explicit uncertainty disclosure.

**Improvement:** Add `score_confidence` to each dimension:

```json
"d6_technical_signal": {
  "score": 3.0,
  "score_confidence": "Medium",
  "confidence_reason": "Skills section comprehensive but limited depth evidence in bullets"
}
```

**Benefit:** Prevents over-reliance on shaky scores; surfaces where evaluation is uncertain.

---

### 3. Rewrite Patterns with Before/After Examples

**Gap:** `top_rewrite_suggestions` exist but could be more systematic.

**Inspiration:** job-coach-and-scout uses structured rewrite templates:
```
[Action verb] [what changed] by [how], resulting in [measured outcome], at [scope/context].
```

**Improvement:** Standardize rewrite suggestions with:

```json
"top_rewrite_suggestions": [
  {
    "original": "Worked on API performance improvements.",
    "rewritten": "Reduced API p95 latency from 420ms to 180ms by replacing synchronous fan-out with batched async workers for 3M daily requests.",
    "xyzs_before": 0,
    "xyzs_after": 4,
    "pattern_applied": "responsibility-to-achievement",
    "data_needed": "If original latency, user volume, or business impact unknown, use conditional phrasing"
  }
]
```

**Benefit:** Concrete, copy-pasteable improvements; teaches the user the pattern.

---

### 8. Enhanced Bias Guardrails

**Gap:** `bias_guardrail_notes` exists but triggers aren't explicit.

**Inspiration:** job-coach-and-scout has mandatory disclosure for specific cases.

**Improvement:** Formalize triggers in rubric:

| Trigger | Mandatory Disclosure |
|---------|---------------------|
| Level inference Medium/Low confidence | State alternative level and scoring impact |
| Role type unclear | Note calibration assumptions |
| Scope inferred not stated | Flag affected XYZS scores |
| Domain outside evaluator knowledge | Reduce technical depth confidence |

**Benefit:** Consistent uncertainty handling; prevents silent bias.
