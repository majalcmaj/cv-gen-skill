# CV tailoring prompt

Fixed instructions for turning `facts.md` + a job offer into a schema-valid `content.yaml`.
These rules never change per run — only the offer text and the resulting output do.

## Inputs
- `facts.md` — the canonical, superset source of truth for achievement history. Every fact,
  number and bullet you may use lives here. Nothing else is a source.
- The job offer — fetched or pasted text for the specific role being applied to.
- `schema/content.schema.json` — the exact required shape of the output.

## Hard rules
- Do not invent or alter any fact, number, achievement, employer, date or skill not already in
  `facts.md`. You may only select, reorder, compress or rephrase for clarity/ATS fit — never add
  new substance.
- Every number in the output must trace back to `facts.md` verbatim (same figure, same units).
- If `facts.md`'s "Open questions" section flags a number as unconfirmed, prefer omitting or
  softening that bullet over asserting a disputed figure as fact.
- Output is only valid YAML matching `schema/content.schema.json` — nothing else, no prose, no
  code fences, no commentary.
- YAML-safety: never write an unquoted `:` followed by a space inside a scalar value (e.g. a
  bullet like `areas: authored ...`) — PyYAML's scanner breaks on it, especially across a
  wrapped line. Wrap the string in double quotes, or rephrase without the colon (an em dash "—"
  usually reads at least as well).
- Keep the whole document to a 1-page budget once rendered — this is enforced downstream by
  `render_cv.py`'s page-count check, but draft toward it directly rather than relying on that
  check to catch overflow.

## Tailoring heuristics
- Mirror the offer's own job title in `title`.
- Lead `summary` and `skills` with what the offer's "Required"/"Key Responsibilities" sections
  ask for, using the offer's own terminology where truthfully applicable.
- When trimming to fit the 1-page budget, drop least-relevant bullets/roles first: older or
  least-related roles compress to fewer bullets before recent/relevant ones lose any.
- Prefer bullets that carry a number — they're the most concrete, most ATS- and
  reader-legible signal of impact.
- `skills` renders in the final CV as one small, disguised keyword line — not a titled section.
  Keep it a short, comma-friendly list ordered by relevance to the offer, not prose, and don't
  pad it past what's actually relevant to this offer.

## Output contract
Raw YAML only, matching `schema/content.schema.json` exactly — no prose, no commentary, nothing
else in the response. Validate against the schema before considering this step done.
