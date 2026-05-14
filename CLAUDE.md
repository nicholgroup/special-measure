# Special Measure — project notes for Claude

MATLAB framework for automated instrument control and scan-based data acquisition. See `README.md` for user-facing docs.

The deep SM knowledge (scan struct, smrun, drivers, buffered acq, etc.) lives in the `smskill` skill at `.claude/skills/smskill/`. When the user mentions SM concepts, prefer the skill's references over recalling from memory.

## Layout

- `src/sm/` — core framework (`smrun`, `smset`, `smget`, ~40 helpers)
- `src/drivers/` — instrument drivers, `smc*.m` (one per model)
- `src/utils/{plotting,analysis}/` — post-scan utilities
- `tests/` — `tSm*.m` unit tests
- `examples/` — runnable mock quantum-dot sandbox
- `gui/` — optional GUIDE GUI (`smgui.m`)

## Conventions

<!-- Fill in as patterns emerge. Examples to consider: -->
<!-- - Naming: drivers are `smc<Model>.m`; tests are `tSm<Topic>.m` -->
<!-- - Style: which MATLAB version, formatting rules, error-handling preferences -->
<!-- - Testing: how to run the test suite, what counts as "tested" -->

## Workflow notes

<!-- Anything you want Claude to do or avoid by default in this repo. -->
