# abl

A utility library for Progress OpenEdge ABL: the classes and functions ABL leaves out, built so everyday code is shorter and safer.

Target: **OpenEdge 11.7 and later.** Anything that needs 12.x is marked as such.

> Status: early. The code has not yet been compiled against a real OpenEdge install. See [docs/compile-checklist.md](docs/compile-checklist.md).

## What's in it

| Package | What it gives you |
|---|---|
| `abl.Errors` | Error types with a code, a cause chain, context data and an HTTP status. `Err` for wrapping, searching the chain, full descriptions and JSON. `Guard` for one-line argument checks. |
| `abl.Strings` | `Str:Format` with named placeholders and ABL format masks, with no limit of 9 arguments. |
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
src/abl/       the library (put this folder on PROPATH)
tests/abl/     tests for the library, same package names as src
tools/          compile.p (compile check), test.p (test runner bootstrap)
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
