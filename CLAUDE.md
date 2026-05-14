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

- Naming: drivers are `smc<Model>.m`; tests are `tSm<Topic>.m`; utility functions are `sm<verb><Noun>.m`
- Scan filenames passed to `smrun` must contain only letters, digits, underscore (`_`), and hyphen (`-`). Enforced by `src/utils/toolbox/smvalidateFilename.m`.
- Test path setup lives in `tests/+smtest/SmchdataFixture.m`. All `src/` subdirectories needed by tests (`src/sm/`, `src/drivers/`, `src/utils/toolbox/`) must be registered there — not in individual test files.
- Tests are auto-discovered by `tests/runAllTests.m` via `TestSuite.fromFolder`. Place new test classes directly in `tests/` (not in subdirectories) to be included.
- MATLAB string vs char: utility functions that accept user-facing text input should convert string scalars to char at the top (`if isstring(x), x = char(x); end`) before passing to `fileparts`, `regexp`, `unique`, or `strjoin`.

## Workflow notes

- Run the full test suite: `results = runAllTests()` from the `tests/` directory (or with `tests/` on the path).
- Manual/visual tests live in `tests/manual/` and are excluded from `runAllTests`.

## Lessons learned (chronological)

### 2026-05-14 — Filename validation and test infrastructure fixes

**Task**: Add input-level filename validation to `smrun` to reject periods, `&`, `*`, and other forbidden characters before a scan runs.

**What went wrong**:

1. `SmchdataFixture` had stale paths (`../../sm`, `../../channels`) from before the repo was restructured into `src/`. All test classes using the fixture failed with `Undefined function 'smaddchannel'`.
2. `SmchdataFixture` did not include `src/drivers/` on the path, so `tSmrunBuf` tests failed with `Undefined function 'smabufconfig2'`.
3. `smvalidateFilename` accepted both char and string input, but when a MATLAB string scalar (`"scan'data"`) was passed, `fileparts` returned strings, and downstream `regexp` rejected the string type with `MATLAB:REGEXP:invalidInputs`.

**Fixes applied**:

1. Updated `SmchdataFixture.initWithQdot` paths: `sm/` to `src/sm/`, removed nonexistent `channels/`, added `src/drivers/` and `src/utils/toolbox/`.
2. Added `isstring` to `char` conversion at the top of `smvalidateFilename`, before any processing.
3. In `oneNotePrep.m`, replaced `fileparts`-based `.mat` extension check with `endsWith(opts.file, '.mat')` to handle periods in data filenames.

**Key takeaway**: When the repo layout changes, `SmchdataFixture` is the single point that must be updated — individual test files should not add their own source paths.
