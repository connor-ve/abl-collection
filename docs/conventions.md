# Conventions

Rules for code in this library. They keep it compiling on 11.7, safe to drop into any codebase, and consistent to read.

## Compatibility

- Baseline is **OpenEdge 11.7**. Do not use 12.x-only features (`VAR`, newer built-in classes) unless the file is marked 12.x-only and has an 11.7 fallback.
- No dependencies outside the OpenEdge runtime, `Progress.Json` and `Progress.Reflect`. `OpenEdge.Core` and `OpenEdge.Net` are allowed only in packages whose purpose needs them (the HTTP client), so the core stays light.
- The code must work on Windows and Linux. For a backslash use `CHR(92)`, never `"\"`, because backslash is an escape character on Unix.

## Every file

- Start with a header comment: file, purpose, usage example.
- Put `BLOCK-LEVEL ON ERROR UNDO, THROW.` before `USING`/`CLASS`.
- Use `NO-UNDO` on every variable, property and temp-table unless undo behaviour is the point.
- Never put curly braces in strings or comments. The preprocessor treats them as include references. Write `~{` if one is unavoidable.

## Naming

- Root package: `abl`. Packages are plural nouns or areas: `abl.Errors`, `abl.Strings`, `abl.Testing`.
- Static helper classes get a short noun name (`Str`, `Err`, `Guard`), are `FINAL`, and have a private constructor.
- Parameters are prefixed by type: `pc` character, `plc` longchar, `pi` integer/int64, `pd` decimal, `pl` logical, `pda` date, `pdt` datetime, `pdtz` datetime-tz, `ph` handle, `po` object.
- Locals use the same prefixes without the `p`.
- Test classes end in `Test` and test methods start with `Test`.

## Errors

- Throw `abl.Errors` types, never bare strings or `RETURN ERROR`.
- Bad input to a public method: `ArgumentError`, usually through `Guard`.
- Do not catch an error just to log it and rethrow. Wrap it with `Err:Wrap` to add context, or let it pass.

## Members that are ABL keywords

Method names like `Format`, `Add` and `Of` work through the colon (`Str:Format`). Inside the class itself, call them as `THIS-OBJECT:Name(...)` or by the class name, never bare, so the compiler doesn't read them as the statement keyword.

## Tests

- Every public method gets at least one test in `tests/` under the same package.
- Tests must not depend on session settings. Set `SESSION:NUMERIC-FORMAT` and `DATE-FORMAT` in `BeforeAll` and restore them in `AfterAll`, as `StrFormatTest` does.
- To check that something throws, catch the error into a variable inside the block and check it after the block.
