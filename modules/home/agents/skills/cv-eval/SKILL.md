---
name: cv-eval
description: "Evaluates CV/resume quality with multi-dimensional scoring and bullet-level XYZS analysis. Use when user asks to evaluate, review, or score a CV/resume. Intrinsic mode is implemented; JD-alignment is reserved for a later phase."
---

# CV Evaluation Skill

## Workflow

1. **Parse CV** -- Read the CV/resume and extract sections plus bullet-level content.

2. **Gate check** -- Apply G1 minimum-content gate from `references/rubric.md`.

3. **Detect level** -- Infer candidate level and confidence using `references/level-profiles.md`.

4. **Bullet-level XYZS analysis** -- Score bullets on the 0-4 XYZS scale using `references/xyz-examples.md`.

5. **Dimension scoring (D1-D7)** -- Score dimensions on the 1-4 scale using `references/rubric.md` and level calibration from `references/level-profiles.md`.

6. **JD alignment** -- v2.0, not yet implemented.

7. **Output** -- Return structured results using `assets/output-template.md`.
