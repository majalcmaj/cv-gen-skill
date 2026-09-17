<!-- plan-status: pending -->
# Phase 04 — interview-mode

> **Status:** ⬜ PENDING

Read `docs/facts-interview/prompt.md` first.

## Goal
A new `facts` mode in `SKILL.md` runs an agent-driven, resumable SBI interview over
`facts.yaml`. "Resumable" means: any later session can fill what's missing **or** add new
material anywhere (new employer, new accomplishment under an existing position, new
cert/project/language/education, edit an existing entry) — the file is the only state. The
behaviour is fixed in `interview.md` and guarded by `scripts/lint_interview.py`, the same way
`prompt.md` is guarded by `lint_prompt.py`.

## Red
1. Write `scripts/lint_interview.py <interview.md>` (mirror `lint_prompt.py`) asserting:
   - a "never invent / never fabricate" clause (agent writes only what the user said);
   - a clause forbidding edits to `name`/`contact` (`has_any(["never touch", "do not edit",
     "leave untouched"])` and `contact` present);
   - `situation`, `behavior`, `impact` all present + `measurable` / `quantif` present;
   - `facts_outline.py` and `validate_facts.py` both referenced (resume + write-validate loop);
   - a "one question at a time" / "write after every answer" clause;
   - a `status: complete` clause (how an employer is marked done);
   - the menu verbs `add`, `extend`, `edit`, `fill` present under the `Resume` heading
     (resume is not gap-filling only);
   - headings: `Resume`, `Experience`, `Accomplishments`, `Other sections`, `Wrap-up`.
2. Selftest: `lint_interview.py /skill/interview.md`; `grep -q '^- \*\*facts\*\*' SKILL.md`;
   `grep -q interview.md SKILL.md`; the existing scripts-mentioned-in-SKILL loop already
   covers any new `.sh` (there should be none).
3. Run selftest → fails: `interview.md` missing.

## Green
Write `interview.md` (≤ ~100 lines) — the complete spec for the `facts` mode:
- **Preconditions**: `facts.yaml` exists (else tell user to run `init`); run
  `validate_facts.py` non-strict, refuse to interview an invalid file (ask user to fix).
- **Resume**: run `facts_outline.py`; show the outline compactly (employers with position
  titles + accomplishment counts, one line per other section) and the gap count. Then ask
  what to do this session — offer, in this order:
  1. **fill** the next gap (name the gap);
  2. **add** a new employer;
  3. **extend** an existing employer — new accomplishment under a named position, new
     position (promotion), or fix dates;
  4. **add** to another section — education / skills / projects / certifications / languages;
  5. **edit** an existing entry by outline address (e.g. `experience[0].accomplishments[1]`);
  6. done.
  The user may also state intent directly in the mode invocation (`facts add cert`,
  `facts extend Northwind`) — skip the menu and go there. After each unit of work
  (one employer, one accomplishment, one section entry) re-run `facts_outline.py` and
  return to the menu. Never re-ask what the outline already shows; `fill:` gaps for
  name/contact are reported once and left to the user — never edit those keys.
- **Experience loop** (per employer, most recent first when filling from scratch): employer,
  location, one-line context (domain, team size, what the company does); positions with
  `YYYY-MM` start/end, promotions as extra positions; write `status: draft` immediately.
  Adding a position to an existing employer or an accomplishment to a `complete` employer is
  allowed — keep `status: complete`, only the new item is drafted via the questions below.
- **Accomplishments loop** (per position, aim for ≥ 2, no hard cap): SBI, one field per
  question. Situation = scope/scale; Behavior = what *you* did; Impact = what changed —
  always push once for a number (before/after, %, time, money, users); if none, record
  `confidence: estimated|unverified` rather than inventing. Ask for keywords (tech, methods)
  last. Offer "anything else at <employer>?" before moving on; on "no", set
  `status: complete`.
- **Other sections**: education, skills (propose groups seeded from accomplishment keywords,
  user confirms/edits), projects, certifications, languages, summary last (draft it from the
  file, user approves). Each one short structured Q&A; each entry appended in file order.
- **Write discipline**: after every answer write `facts.yaml`, run `validate_facts.py`, fix
  before asking the next question; write literally what the user said, tidied for grammar
  only; ask one question per turn; the user may stop at any point ("stop", "later") — file
  stays valid, next `facts` run shows the same outline and menu.
- **Wrap-up**: run `facts_outline.py`; report what was added this session, remaining gaps,
  and the exact `<FILL>` keys the user still owns.
- `SKILL.md`: add `- **facts** [intent] — interview mode …` to Modes with the entry command,
  the optional free-text intent, and a two-line flow (`interview.md` is the spec; don't
  restate it). `README.md` quickstart gets the `facts` step between `init` and `render`.
- Selftest green.

## Refactor
- `lint_prompt.py` and `lint_interview.py` share `has_any`/`has_heading` — extract to a tiny
  `scripts/lintlib.py` only if both import it unchanged; else leave duplicated (2 helpers, not
  worth a module).
- `interview.md`: cut every sentence the agent would do anyway; keep only load-bearing rules.

## Verify
- `bash scripts/selftest.sh` green.
- Manual smoke (not automated): in a scratch dir run `init.sh`, ask the agent for `facts`,
  answer 2 questions, say "stop"; re-run `facts` — outline shows the partial employer, menu
  offers fill/add/extend; pick "add cert", add one, then "extend Northwind" with a new
  accomplishment. `validate_facts.py` must pass after every write.

## Commit
`feat(skill): facts interview mode — resume, extend or fill facts.yaml via interview.md spec`
