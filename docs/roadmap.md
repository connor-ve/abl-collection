# Roadmap

## Phase 1

1. **Foundation** (in progress)
   - [x] Error types, `Err`, `Guard`
   - [x] `Str:Format` with named placeholders
   - [x] Test framework: `TestCase`, `Expect`, runner, JUnit output
   - [ ] Compile and pass on a real 11.7 install (see compile-checklist.md)
2. **Core**
   - [ ] `Slice` types (Go-style: growable, sub-slices that share the backing array). Typed versions for CHARACTER, INT64, DECIMAL, LOGICAL, DATE and Object, generated from one template.
   - [ ] `List`, `Map`, `Set`, `Stack`, `Queue` on top of slices
   - [ ] Logging: levels, categories, outputs (file, LOG-MANAGER, stdout), JSON lines, request IDs
   - [ ] Timing: `Stopwatch`, named laps, a scope that logs on dispose
   - [ ] UUID v4 and v7 (time-ordered), hashing, Base64 wrappers
3. **JSON, config, environment**
   - [ ] JSON path get/set (`orders[0].lines[2].qty`), safe getters with defaults, builder, merge, diff, pretty-print
   - [ ] YAML subset parser (maps, lists, scalars, comments)
   - [ ] Config: JSON, INI or YAML file, then environment variables, then overrides, with typed getters
   - [ ] Environment detection: PASOE, classic AppServer, WebSpeed, GUI, batch, PROPATH, databases
4. **Data**
   - [ ] Fluent dynamic query builder with automatic cleanup
   - [ ] Buffer copy, compare and diff, and dump-to-string
   - [ ] Temp-table filter, sort and group
   - [ ] Configurable temp-table/JSON mapping
   - [ ] Typed CSV import and export
   - [ ] Validation rules that produce a `ValidationError`
   - [ ] Temp-table and dataset equality in `Expect`
5. **PASOE**
   - [ ] Router over `WebHandler` with path parameters
   - [ ] Middleware: logging, auth, CORS, request IDs, errors returned as JSON (via `Err:ToJson`)
   - [ ] Request and response helpers
   - [ ] Leak guard per request
   - [ ] HTTP client behind an interface (`OpenEdge.Net` implementation first)
6. **Native bridge** (spike)
   - [ ] Go shared library for HTTP, regex and YAML, called with `PROCEDURE EXTERNAL`. Needs builds per OS and bitness.

## Phase 2

- Packaging: source, r-code and `.pl` builds
- Installer that prints the PROPATH entry
- Language server integration (completion and docs for abl classes)
- Mock generation from interfaces for the test framework
