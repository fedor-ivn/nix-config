# Output Template

This file defines the required structured output for CV evaluation results.

## 1. JSON Template

```json
{
  "meta": {
    "evaluation_mode": "intrinsic",
    "inferred_level": "<Junior|Mid|Senior|Staff/Principal|EM/Manager>",
    "inferred_level_confidence": "<High|Medium|Low>",
    "inferred_primary_role_type": "<SWE|PM|Data|Mixed|Unclear>",
    "word_count_approximate": "<integer>",
    "page_count_approximate": "<integer>"
  },
  "gates": {
    "g1_minimum_content": "<Pass|Fail>",
    "gate_failure_reason": "<string or null>"
  },
  "dimensions": {
    "d1_impact_achievement": {
      "score": "<1.0-4.0>",
      "score_confidence": "<High|Medium|Low>",
      "confidence_reason": "<string explaining confidence level>",
      "weight": 0.25,
      "achievement_bullet_rate": "<percentage>",
      "responsibility_bullet_count": "<integer>",
      "key_strengths": ["<string>"],
      "key_weaknesses": ["<string>"],
      "bullet_analysis": [
        {
          "text": "<original bullet text>",
          "xyzs_score": "<0-4>",
          "components": { "X": "<boolean>", "Y": "<boolean>", "Z": "<boolean>", "S": "<boolean>" },
          "missing": "<which components missing and why, or null>",
          "rewrite_hint": "<brief suggestion to improve, or null if score 4>"
        }
      ],
      "top_rewrite_suggestions": [
        {
          "original": "<original bullet text>",
          "rewritten": "<improved bullet text>",
          "xyzs_before": "<0-4>",
          "xyzs_after": "<0-4>",
          "pattern_applied": "<responsibility-to-achievement|add-quantification|add-scope|add-method>",
          "data_needed": "<what info candidate must supply if metrics unknown, or null>"
        }
      ]
    },
    "d2_quantification": {
      "score": "<1.0-4.0>",
      "score_confidence": "<High|Medium|Low>",
      "confidence_reason": "<string explaining confidence level>",
      "weight": 0.20,
      "quantification_rate": "<percentage>",
      "key_strengths": ["<string>"],
      "key_weaknesses": ["<string>"],
      "bullet_analysis": [
        {
          "text": "<original bullet text>",
          "xyzs_score": "<0-4>",
          "components": { "X": "<boolean>", "Y": "<boolean>", "Z": "<boolean>", "S": "<boolean>" },
          "missing": "<which components missing and why, or null>",
          "rewrite_hint": "<brief suggestion to improve, or null if score 4>"
        }
      ],
      "top_rewrite_suggestions": [
        {
          "original": "<original bullet text>",
          "rewritten": "<improved bullet text>",
          "xyzs_before": "<0-4>",
          "xyzs_after": "<0-4>",
          "pattern_applied": "<responsibility-to-achievement|add-quantification|add-scope|add-method>",
          "data_needed": "<what info candidate must supply if metrics unknown, or null>"
        }
      ]
    },
    "d3_clarity_conciseness": {
      "score": "<1.0-4.0>",
      "score_confidence": "<High|Medium|Low>",
      "confidence_reason": "<string explaining confidence level>",
      "weight": 0.15,
      "flagged_patterns": ["<string>"],
      "weak_verbs_found": ["<verb>"],
      "buzzwords_found": ["<word>"],
      "key_strengths": ["<string>"],
      "key_weaknesses": ["<string>"]
    },
    "d4_structure_formatting": {
      "score": "<1.0-4.0>",
      "score_confidence": "<High|Medium|Low>",
      "confidence_reason": "<string explaining confidence level>",
      "weight": 0.15,
      "sections_present": ["<section>"],
      "sections_missing": ["<section>"],
      "formatting_issues": ["<string>"],
      "hierarchy_issues": ["<string>"],
      "length_flag": "<string or null>"
    },
    "d5_career_progression": {
      "score": "<1.0-4.0>",
      "score_confidence": "<High|Medium|Low>",
      "confidence_reason": "<string explaining confidence level>",
      "weight": 0.10,
      "progression_signals": ["<string>"],
      "stagnation_flags": ["<string>"],
      "gap_flags": ["<string>"],
      "recency_weighting_ok": "<boolean>"
    },
    "d6_technical_signal": {
      "score": "<1.0-4.0>",
      "score_confidence": "<High|Medium|Low>",
      "confidence_reason": "<string explaining confidence level>",
      "weight": 0.10,
      "skills_list_size": "<integer>",
      "over_listing_flag": "<boolean>",
      "categorized_flag": "<boolean>",
      "depth_signal_assessment": "<string>",
      "skill_bullet_inconsistencies": ["<string>"]
    },
    "d7_spelling_grammar": {
      "score": "<1.0-4.0>",
      "score_confidence": "<High|Medium|Low>",
      "confidence_reason": "<string explaining confidence level>",
      "weight": 0.05,
      "error_count_approximate": "<integer>",
      "errors_found": ["<string>"],
      "tense_consistency": "<Consistent|Minor issues|Major issues>",
      "professionalism_flags": ["<string>"]
    }
  },
  "composite": {
    "raw_weighted_score": "<1.0-4.0>",
    "normalized_score": "<0-100>",
    "label": "<Exceptional|Strong|Adequate|Weak|Poor>"
  },
  "flags": {
    "hard_flags": ["<string>"],
    "soft_flags": ["<string>"],
    "bias_guardrail_notes": ["<string>"]
  },
  "priority_improvements": [
    {
      "rank": 1,
      "dimension": "<D1-D7>",
      "issue": "<string>",
      "suggestion": "<string>",
      "example_before": "<optional string>",
      "example_after": "<optional string>"
    }
  ],
  "summary_narrative": "<3-5 sentence summary with level, overall quality, top strengths, and top weaknesses>"
}
```

## 2. Field Descriptions

| Field | Required | Description |
|---|---|---|
| `meta.evaluation_mode` | Yes | Evaluation mode. Current default is `intrinsic`. |
| `meta.inferred_level` | Yes | Seniority inferred from CV signals (see `references/level-profiles.md`). |
| `meta.inferred_level_confidence` | Yes | Confidence in level inference: `High`, `Medium`, or `Low`. |
| `meta.inferred_primary_role_type` | Yes | Dominant role type used for calibration (SWE, PM, Data, Mixed, or Unclear). |
| `meta.word_count_approximate` | Yes | Approximate CV word count. |
| `meta.page_count_approximate` | Yes | Approximate CV page count. |
| `gates.g1_minimum_content` | Yes | Gate result for minimum evaluable content. |
| `gates.gate_failure_reason` | Yes | Null on pass; concise reason on fail. |
| `dimensions.*.score` | Yes | Per-dimension score on 1.0-4.0 scale; half-steps allowed. |
| `dimensions.*.score_confidence` | Yes | Confidence in this dimension's score: `High`, `Medium`, or `Low`. |
| `dimensions.*.confidence_reason` | Yes | Brief explanation of why confidence is at this level. |
| `dimensions.*.weight` | Yes | Static dimension weight used in composite. |
| `dimensions.*.key_strengths` | Yes | Evidence-based strengths for that dimension. |
| `dimensions.*.key_weaknesses` | Yes | Evidence-based weaknesses for that dimension. |
| `dimensions.d1.bullet_analysis` | Yes | Per-bullet XYZS breakdown with scores, components, and rewrite hints. |
| `dimensions.d2.bullet_analysis` | Yes | Per-bullet XYZS breakdown (same structure as D1). |
| `dimensions.d1.top_rewrite_suggestions` | Yes | Structured rewrites with original, rewritten, XYZS delta, pattern, and data needed. |
| `dimensions.d2.top_rewrite_suggestions` | Yes | Structured rewrites to improve quantification (same structure as D1). |
| `dimensions.d3.flagged_patterns` | Yes | Clarity issues such as passive voice, long bullets, or jargon overload. |
| `dimensions.d4.sections_present` | Yes | Detected document sections. |
| `dimensions.d4.sections_missing` | Yes | Missing expected sections. |
| `dimensions.d5.progression_signals` | Yes | Evidence of growth in scope/seniority. |
| `dimensions.d5.stagnation_flags` | Yes | Context-only concerns; do not use for automatic penalties. |
| `dimensions.d5.gap_flags` | Yes | Context-only timeline observations; do not penalize directly. |
| `dimensions.d6.depth_signal_assessment` | Yes | Concise judgment of technical depth and credibility. |
| `dimensions.d7.errors_found` | Yes | Concrete spelling/grammar/professionalism issues with location context when possible. |
| `composite.raw_weighted_score` | Yes | Weighted score on 1.0-4.0 scale before normalization. |
| `composite.normalized_score` | Yes | 0-100 normalized score using rubric formula. |
| `composite.label` | Yes | Overall label mapped from normalized score bands. |
| `flags.hard_flags` | Yes | High-priority risks requiring immediate attention. |
| `flags.soft_flags` | Yes | Context-helpful notes that should not drive heavy penalties. |
| `flags.bias_guardrail_notes` | Yes | Explicit uncertainty and inference disclosures. |
| `priority_improvements` | Yes | Ranked, actionable improvements with concrete suggestions. |
| `summary_narrative` | Yes | Brief plain-language summary that synthesizes the evaluation. |

## 3. Validation Rules

- Return all top-level keys in the template.
- Keep every score within its declared range.
- If gate `g1_minimum_content` fails, still return the full object and explain the failure in `gate_failure_reason`.
- Every major inference under uncertainty must be documented in `flags.bias_guardrail_notes`.
