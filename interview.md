# Facts interview

Fixed instructions for the `facts` mode: an agent-driven, resumable interview that fills and
extends the user's `facts.yaml`. The file is the only state — every run starts by reading it.

## Preconditions
- `facts.yaml` must exist in the current directory; if not, tell the user to run `init` and stop.
- Run `bash scripts/run.sh python /skill/scripts/validate_facts.py facts.yaml` (non-strict).
  Refuse to interview an invalid file: show the errors, ask the user to fix them, stop.
- `schema/facts.schema.json` is the exact shape of everything you write. Read it once.

## Hard rules
- Never invent, round, embellish or "improve" a fact. Write literally what the user said,
  tidied for grammar only. If the user is unsure of a figure, record it with
  `confidence: estimated` or `unverified` and, if they want to check later, a `todo:`.
- `name` and `contact` belong to the user: never edit them. Report their `<FILL>` gaps once
  per session and move on.
- One question per turn. After every answer write `facts.yaml`, re-run `validate_facts.py`,
  and fix any error before asking the next question. The user may stop at any moment
  ("stop", "later", "enough") — the file must be valid at that point.
- Ask in the user's language; write field values in the language the CV will be in (ask once
  if unclear).

## Resume
1. Run `bash scripts/run.sh python /skill/scripts/facts_outline.py facts.yaml`.
2. Show the outline compactly: each employer with position titles and accomplishment count,
   one line per other section, then the number of gaps.
3. If the mode was invoked with an intent (`facts add cert`, `facts extend Northwind`,
   `facts fill`), go straight to it. Otherwise offer a menu, in this order:
   1. **fill** the next gap — name it (e.g. "Fictive Labs has no accomplishments yet");
   2. **add** a new employer;
   3. **extend** an existing employer — a new accomplishment under a named position, a new
      position (promotion), or a date fix;
   4. **add** to another section — education, skills, projects, certifications, languages;
   5. **edit** an existing entry by outline address (e.g. `experience[0].accomplishments[1]`);
   6. done.
4. After each unit of work (one employer, one accomplishment, one section entry) re-run
   `facts_outline.py` and return to the menu. Never re-ask anything the outline already shows.

## Experience
Per employer (most recent first when starting from scratch), ask in this order:
- employer name; location; one-line `context` (what the company does, domain, team size);
- positions held there with `YYYY-MM` start/end (`present` allowed) — a promotion is another
  position entry, most recent first;
- write the employer immediately with `status: draft` and `accomplishments: []`.
Extending a `complete` employer (new position or accomplishment) keeps `status: complete`.

## Accomplishments
Per position, aim for at least 2; no upper limit. One field per question, in this order:
- **title** — a short handle for the outline;
- **situation** — scope and scale: team size, fleet size, users, budget, what was broken;
- **behavior** — what *the user* did (not the team), the concrete actions and tools;
- **impact** — what changed. Always push once for a measurable figure: before/after, %, time,
  money, users, incidents. If a number exists, capture it in `metrics` (`name`, `before`,
  `after`, `unit`) verbatim; if none exists, keep the qualitative impact and set
  `confidence: estimated` (user's rough figure) or `unverified` (no figure at all);
- **keywords** — technologies, methods, domains (feed the CV's skills line).
Then ask "anything else at <employer>?" — on "no", set `status: complete`; on "yes", loop.

## Other sections
Short structured Q&A, appended in file order:
- **education** — degree, school, `YYYY-MM` start/end, optional notes;
- **skills** — propose groups seeded from the accomplishments' keywords; the user confirms,
  renames or edits; write only what they confirm;
- **projects** — name, dates, one-line description, impact if measurable, keywords;
- **certifications** — name, issuer, date;
- **languages** — language, level;
- **summary** — last; draft 2–4 sentences from the file (scope, years, strongest numbers),
  show it, write only the version the user approves.

## Wrap-up
Run `facts_outline.py` once more. Report: what was added or changed this session, the
remaining gaps, and the exact `<FILL>` keys the user still owns. Remind them the next `facts`
run resumes from the same outline.
