# abl

A utility library for Progress OpenEdge ABL: the classes and functions ABL leaves out, built so everyday code is shorter and safer.

Target: **OpenEdge 11.7 and later.** Anything that needs 12.x is marked as such.

> Status: early. The code has not yet been compiled against a real OpenEdge install. See [docs/compile-checklist.md](docs/compile-checklist.md).

## What's in it

| Package | What it gives you |
|---|---|
| `abl.Errors` | Error types with a code, a cause chain, context data and an HTTP status. `Err` for wrapping, searching the chain, full descriptions and JSON. `Guard` for one-line argument checks. |
| `abl.Strings` | `Str:Format` with named placeholders and ABL format masks, with no limit of 9 arguments. |
| `abl.Collections` | Go-style slices (`CharSlice`, `IntSlice`, `DecSlice`, `LogSlice`, `DateSlice`, `ObjSlice`), `CharSet`/`IntSet`, `Map`, `Stack`, `Queue`. |
| `abl.Testing` | A test framework: `Expect(x):ToEqual(y)`, discovery by method name, database rollback per test, console and JUnit XML reports. |
| `abl.Core` | `Box`, a typed holder for one value of any ABL type, used across the library. |

## Examples

### Named formatting

```abl
USING abl.Strings.*.

MESSAGE Str:Format("Hello [name], you owe [amt:>>>,>>9.99] by [due:99/99/9999]",
                   Args:Of("name", cName):Add("amt", dOwed):Add("due", dtDue)).
```

- `[name]` inserts a value, and `[name:mask]` applies any ABL format mask.
- The extra mask `iso` gives ISO-8601 dates.
- `[[` and `]]` give literal brackets.
- You can also pass a `JsonObject` instead of `Args`.
- Brackets are used instead of curly braces because ABL treats curly braces inside strings as preprocessor references.

### Collections

```abl
USING abl.Collections.*.

/* Slices: growable typed lists, 1-based like ABL arrays */
oNames = CharSlice:FromList("pear,Apple,banana", ",").
oNames:Append("cherry"):Sort().
MESSAGE oNames:Join(", ").                 /* Apple, banana, cherry, pear */

DO i = 1 TO oNames:Length:
    MESSAGE oNames:Get(i).
END.

oTotals = IntSlice:Of(30, 10, 20).
MESSAGE oTotals:Sum() oTotals:Max().       /* 60 30 */

/* Views share storage, as in Go */
oFirstTwo = oNames:Sub(1, 2).
oFirstTwo:Set(1, "APPLE").                 /* oNames:Get(1) is now "APPLE" too */

/* Sets, maps, stacks, queues */
oSeen = CharSet:Of("a", "b").
oBoth = oSeen:Intersect(CharSet:Of("b", "c")).

oCust = NEW Map().
oCust:Put("name", "Ann"):Put("limit", 5000.00).
dLimit = oCust:GetDec("limit", 0).         /* default only when the key is missing */

oJobs = NEW Queue().
oJobs:Enqueue("first"):Enqueue("second").
cJob = oJobs:Dequeue():AsCharacter().
```

- Slices have no size limit. Storage doubles up to 4096 elements, then grows in blocks of 4096, so a slice isn't capped at the 28,000 elements of a single ABL array.
- Appending to a view never overwrites the slice it came from, which avoids a classic Go bug. `Copy()` gives an independent slice.
- Typed slices and sets are generated from one template in `tools/templates`. Edit the template, then run `bash tools/gen-collections.sh`.
- Sets and map keys compare text case-insensitively, as an ABL index does.

### Errors

```abl
USING abl.Errors.*.

/* Throw with meaning */
UNDO, THROW NEW NotFoundError("Customer", STRING(piCustNum)).    /* 404 */

/* Collect every validation problem, then throw once */
oVal = NEW ValidationError("Customer is invalid").
IF cName = "" THEN oVal:AddFieldError("name", "is required").
IF dLimit < 0 THEN oVal:AddFieldError("creditLimit", "cannot be negative").
oVal:ThrowIfAny().                                               /* 422 */

/* Add context without losing the original error */
CATCH e AS Progress.Lang.Error:
    UNDO, THROW Err:Wrap(e, "Posting invoice " + STRING(piInvoice)).
END CATCH.

/* Inspect */
IF Err:Is(e, "NotFound") THEN ...
LOG-MANAGER:WRITE-MESSAGE(STRING(Err:Describe(e))).   /* full chain + call stacks */
oResponseBody = Err:ToJson(e).                         /* type, code, httpStatus, message, context, cause */

/* Turn NO-ERROR status into a real error */
iQty = INTEGER(cInput) NO-ERROR.
Err:ThrowIfStatus("Parsing quantity").

/* Argument checks */
Guard:NotBlank(pcName, "pcName").
Guard:InRange(piQty, 1, 999, "piQty").
```

### Tests

```abl
CLASS app.InvoiceTest INHERITS abl.Testing.TestCase:

    METHOD PUBLIC OVERRIDE VOID Setup():
        /* runs before each test */
    END METHOD.

    METHOD PUBLIC VOID TestTotalIncludesTax():
        Expect(oInvoice:Total()):ToEqual(107.50).
    END METHOD.

    METHOD PUBLIC VOID TestRejectsNegativeQuantity():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            oInvoice:AddLine("ABC", -1).
            CATCH e AS Progress.Lang.Error:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveErrorCode("Argument"):ToHaveMessage("quantity").
    END METHOD.

END CLASS.
```

- Any `PUBLIC VOID` method with no parameters whose name starts with `Test` is a test. No annotations are needed.
- Each test runs in a transaction that is rolled back, so tests leave no database rows behind.
- Available checks:
  - Equality: `ToEqual`, `ToNotEqual`, `ToEqualExact`
  - Unknown and logical: `ToBeTrue`, `ToBeFalse`, `ToBeUnknown`, `ToBeKnown`
  - Numbers: `ToBeGreaterThan`, `ToBeAtLeast`, `ToBeLessThan`, `ToBeAtMost`, `ToBeBetween`
  - Text: `ToContain`, `ToNotContain`, `ToStartWith`, `ToEndWith`, `ToMatch`, `ToBeEmpty`, `ToHaveLength`
  - Objects and handles: `ToBeValidObject`, `ToBeInstanceOf`, `ToBeSameAs`, `ToBeValidHandle`
  - Errors: `ToHaveErrorCode`, `ToHaveMessage`

## Layout

```
src/abl/        the library (put this folder on PROPATH)
tests/abl/      tests for the library, same package names as src
tools/          compile.p (compile check), test.p (test runner bootstrap),
                gen-collections.sh + templates/ (typed collection generator)
docs/           conventions, compile checklist, roadmap
```

## Running

From the repo root:

```
# 1. Does everything compile?
_progres -b -p tools/compile.p -param "src,tests"

# 2. Run the tests (console report; add junit=... for CI)
_progres -b -p tools/test.p -errorstack -catchStop 1
_progres -b -p tools/test.p -param "filter=Strings,junit=build/test-results/junit.xml" -errorstack -catchStop 1
```

On Windows, use `prowin -b` (or `prowin32 -b` on a 32-bit install) in place of `_progres -b`.

## Using it in a project

Add `src` to your PROPATH and `USING abl.Errors.*.` (and so on) in your code. Packaging as a procedure library (`.pl`) with an installer comes later. See [docs/roadmap.md](docs/roadmap.md).

## License

MIT. See [LICENSE](LICENSE).
