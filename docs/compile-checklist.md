# Compile checklist

This code was written without an OpenEdge install available. The items below are the language and API details it depends on that have not yet been confirmed on a real 11.7 compiler. Work through them the first time you compile, and delete each one once it's confirmed or fixed.

Start with:

```
_progres -b -p tools/compile.p -param "src,tests"
_progres -b -p tools/test.p -errorstack -catchStop 1
```

## Language

- [ ] **Member names that are ABL keywords.** These are called through a colon (`Str:Format`, `Args:Of`, `oArgs:Add`), the same way the built-in `JsonObject:Set` and `JsonObject:Add` are, so they should compile. If `Format` or `Of` are rejected, rename them to `Fmt` / `From` in `Str.cls`, `Args.cls` and the tests.
- [ ] **Chaining off a method's return value as a statement**, e.g. `Expect(x):ToEqual(5).` If the compiler rejects the unqualified form, `THIS-OBJECT:Expect(x):ToEqual(5).` is the fallback.
- [ ] **Overload resolution with widening:** INTEGER arguments to DECIMAL parameters (`Guard:InRange(1, 1, 10, ...)`, `ToBeBetween(10, 10)`), and CHARACTER to LONGCHAR (`ToEqualExact("abc")`).
- [ ] **Interface references passed to `Progress.Lang.Object` parameters**, e.g. `Expect(oCaught)` where `oCaught` is `Progress.Lang.Error`.
- [ ] **`THIS-OBJECT(..., ?)` and `SUPER(..., ?)`** passing `?` for an object parameter where only one overload has that many parameters.
- [ ] **`CASE ... WHEN "A" OR WHEN "B" THEN`** with `RETURN` inside property getters.
- [ ] **Temp-table field of class type:** `FIELD ArgValue AS Progress.Lang.Object` in `Args.cls`.
- [ ] **`DEFINE PRIVATE STREAM`** inside a class (`TestRunner.cls`).

## Built-in classes and functions

- [ ] `Progress.Lang.Class:IsA(typeName)` (used by `Err:Find`, `ToBeInstanceOf`).
- [ ] `Progress.Lang.Error:CallStack` reachable through the interface type (`Err:Describe`).
- [ ] `Progress.Reflect.Flags:Public OR Progress.Reflect.Flags:Instance` combined with `OR` (`TestRunner:CollectTestMethods`).
- [ ] `Progress.Reflect.Method:GetParameters()` returns an empty or unfixed extent for no parameters.
- [ ] `Progress.Lang.Stop` exists for `CATCH` (added in 11.7; needs `-catchStop 1` at runtime to be caught).
- [ ] `JsonObject:GetJsonText(name)` for nested objects and arrays (`Args:FromJson`).
- [ ] `JsonObject:Set` / `Add` overloads for DATE, DATETIME and DATETIME-TZ (`AblError:AddContext`).
- [ ] `STRING(value, mask)` raises an error, rather than returning `?` or `###`, when the value does not fit (`TestValueTooBigForMaskThrows`).
- [ ] `INTERVAL(NOW, dtzStart, "milliseconds")` with DATETIME-TZ on both sides.
- [ ] `OS-CREATE-DIR` creates intermediate folders (`build/test-results/`). If not, create `build/` once by hand.

## Collections

- [ ] **The 28000-element limit is real** for indeterminate arrays. The storage design assumes it. If 11.7 allows larger arrays, the chunking still works; it's just more than needed.
- [ ] `EXTENT(arr) = n` (EXTENT statement) fixes an indeterminate class member array (`RefArray`, the `*Chunk` classes, `ToArray`).
- [ ] `DEFINE PUBLIC VARIABLE Items AS ... EXTENT` in a class, and writing one element from another object: `oChunk:Items[i] = x`.
- [ ] Methods returning arrays: `METHOD PUBLIC CHARACTER EXTENT ToArray()`.
- [ ] `DEFINE INPUT ... EXTENT` parameters on static methods (`FromArray`, `AppendArray`).
- [ ] A temp-table defined in a class body after the variable definitions (`ttSort` in the sortable slices).
- [ ] `INITIAL ["x", "y", "z"]` on an EXTENT 3 variable (tests).
- [ ] `FOR EACH ttEntry USE-INDEX ixSeq` returns rows in `Seq` order (`Map:Keys`).
- [ ] Rough speed check: 50000 appends in `TypedSliceTest:TestIntLargeSlice` should take well under a second. If it's slow, profile `GetAt`/`SetAt` first.

## Behaviour

- [ ] An error thrown inside a `CATCH` block propagates out of the surrounding `DO ON ERROR UNDO, LEAVE`. The tests avoid relying on this by storing the caught error and checking it after the block.
- [ ] `ERROR-STATUS` survives a static method call made right after the `NO-ERROR` statement (`Err:ThrowIfStatus`).
- [ ] `UNDO TestTx, LEAVE TestTx` inside the runner undoes database changes made by the test, and leaves the `NO-UNDO` result temp-table untouched.
- [ ] The JUnit file opens cleanly in a CI tool or XML viewer (UTF-8, escaped messages).
