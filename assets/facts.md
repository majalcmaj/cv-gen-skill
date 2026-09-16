<!--
This is your canonical fact base — the ONE source of truth for the LLM tailoring step
(see prompt.md's "Hard rules"). It may only select, reorder, compress or rephrase what's
here; it may never add a fact, number, employer, date or skill that isn't written below.
Keep every ## heading below (check_facts.py enforces Contact/Experience/Skills/Education +
a Summary or Positioning section) but replace the example content with your own.
-->

# facts.md — Alex Nowak (example persona — replace with your own)

## Contact
<!-- one line per channel; keep exact, copy-pasteable values -->
- Phone: +1 555 010 2024
- Email: alex.nowak@example.com
- GitHub: https://github.com/alexnowak-example
- LinkedIn: www.linkedin.com/in/alexnowak-example

## Summary
<!-- 2-4 sentences a tailoring pass can trim from — lead with scope + years, close with your
     strongest numbers so they survive even aggressive compression -->
Senior engineer with 7+ years at Northwind Systems enabling product teams to deploy, run and
optimise applications on secure, scalable infrastructure.

## Experience
<!-- one ### per role, most recent first; first line under the heading is the company/dates
     line, every claim below it is a bullet starting with "-" -->

### Northwind Systems — Tech Lead / DevProd Specialist / Senior Software Engineer
Mar 2018 – Present
<!-- one line per verifiable fact; keep exact numbers — the tailoring step may only
     select/compress these bullets, never add to or round them -->
- Delivered Kubernetes-fleet cost-optimisation and monitoring-plugin rollouts, cutting
  infrastructure spend by ~USD 180K/quarter while improving observability for 5+ product teams.
- Owned CI reliability across the Data Center CI fleet, turning broken-build firefighting into
  repeatable detection and cleanup automation, raising CI success rate from 84% to 93%.
- Led release-engineering improvement for a 7-person team, cutting bugfix release lead time 60%
  (20h -> 8h) by measuring release phases and automating manual steps.
- Defined and owned "Lead Time for Changes" org-wide; built automated measurement pipelines and
  dashboards that drove P80 lead time down 70% (48.0d -> 14.4d).

### Fictive Labs — Fullstack Developer / DevOps Engineer (Side Project / Consulting)
Jun 2016 – Jun 2024
- Built CI/CD pipelines (Jenkins, GitLab) and monitoring/logging (Prometheus, ELK) for a
  service-management platform.
- Implemented GDPR data anonymisation and database maintenance tooling.

## Skills
<!-- group by theme; the tailoring step picks/orders from here, it doesn't invent entries -->
- Cloud/infra: AWS, Kubernetes, Docker, Linux, infrastructure-as-code
- CI/CD: Bamboo, Bitbucket Pipelines, GitHub Actions, Jenkins, GitLab CI
- Observability: Prometheus, ELK, engineering-metrics pipelines

## Education
- M.Sc. in Informatics, Riverbend University, 2016 – 2017
- B.Sc. in Informatics, Riverbend University, 2012 – 2016

## Open questions
<!-- flag any number you're not 100% sure of here; per prompt.md's hard rules, the tailoring
     step must omit or soften a bullet built on a figure flagged as unconfirmed rather than
     assert it as fact -->
- Example: is the "~USD 180K/quarter" savings figure still accurate after the Q3 re-platforming,
  or should it be re-verified with finance before the next application?
