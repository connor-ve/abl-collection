/*------------------------------------------------------------------------
    File        : tests/abl/Errors/ErrTest.cls
    Purpose     : Tests for the error types, Err and Guard.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Json.ObjectModel.JsonObject.
USING abl.Errors.*.
USING abl.Testing.TestCase.

CLASS abl.Errors.ErrTest INHERITS TestCase:

    /* ---------------------------------------------------------------- */
    /* Error types                                                      */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestNotFoundMessageAndStatus():
        DEFINE VARIABLE oErr AS NotFoundError NO-UNDO.
        oErr = NEW NotFoundError("Customer", "42").
        Expect(oErr:GetMessage(1)):ToEqualExact("Customer '42' not found").
        Expect(oErr:Code):ToEqual("NotFound").
        Expect(oErr:HttpStatus):ToEqual(404).
        Expect(oErr:Context:GetCharacter("key")):ToEqual("42").
    END METHOD.

    METHOD PUBLIC VOID TestDefaultCodeIsError():
        DEFINE VARIABLE oErr AS AblError NO-UNDO.
        oErr = NEW AblError("something broke").
        Expect(oErr:Code):ToEqual("Error").
        Expect(oErr:HttpStatus):ToEqual(500).
        Expect(oErr:HasContext()):ToBeFalse().
    END METHOD.

    METHOD PUBLIC VOID TestAddContextChainsAndReplaces():
        DEFINE VARIABLE oErr AS AblError NO-UNDO.
        oErr = NEW AblError("Billing", "bad total").
        oErr:AddContext("invoice", 7):AddContext("invoice", 8):AddContext("currency", "USD").
        Expect(oErr:Context:GetInteger("invoice")):ToEqual(8).
        Expect(oErr:Context:GetCharacter("currency")):ToEqual("USD").
    END METHOD.

    METHOD PUBLIC VOID TestValidationCollectsAllFields():
        DEFINE VARIABLE oVal    AS ValidationError     NO-UNDO.
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.

        oVal = NEW ValidationError("Customer is invalid").
        oVal:AddFieldError("name", "is required"):AddFieldError("creditLimit", "cannot be negative").

        DO ON ERROR UNDO, LEAVE:
            oVal:ThrowIfAny().
            CATCH e AS ValidationError:
                oCaught = e.
            END CATCH.
        END.

        Expect(oCaught):ToBeSameAs(oVal).
        Expect(oVal:FieldCount):ToEqual(2).
        Expect(oVal:HttpStatus):ToEqual(422).
        Expect(oCaught):ToHaveMessage("creditLimit: cannot be negative").
    END METHOD.

    METHOD PUBLIC VOID TestValidationWithNoFieldsDoesNotThrow():
        DEFINE VARIABLE oVal AS ValidationError NO-UNDO.
        oVal = NEW ValidationError("unused").
        oVal:ThrowIfAny().
        Expect(oVal:HasFieldErrors()):ToBeFalse().
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Wrap / Is / Find / Root                                          */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestWrapKeepsCodeStatusAndCause():
        DEFINE VARIABLE oInner AS NotFoundError NO-UNDO.
        DEFINE VARIABLE oOuter AS AblError     NO-UNDO.

        oInner = NEW NotFoundError("Customer", "42").
        oOuter = Err:Wrap(oInner, "Loading order 7").

        Expect(oOuter:GetMessage(1)):ToEqual("Loading order 7").
        Expect(oOuter:Code):ToEqual("NotFound").
        Expect(oOuter:HttpStatus):ToEqual(404).
        Expect(oOuter:Cause):ToBeSameAs(oInner).
    END METHOD.

    METHOD PUBLIC VOID TestIsSearchesWholeChain():
        DEFINE VARIABLE oChain AS AblError NO-UNDO.
        oChain = Err:Wrap(Err:Wrap(NEW ConflictError("row changed"), "saving"), "posting").
        Expect(Err:Is(oChain, "Conflict")):ToBeTrue().
        Expect(Err:Is(oChain, "NotFound")):ToBeFalse().
    END METHOD.

    METHOD PUBLIC VOID TestFindReturnsMatchingType():
        DEFINE VARIABLE oInner AS ExternalError NO-UNDO.
        DEFINE VARIABLE oChain AS AblError     NO-UNDO.

        oInner = NEW ExternalError("TaxService", "timed out").
        oChain = Err:Wrap(oInner, "calculating tax").

        Expect(Err:Find(oChain, "abl.Errors.ExternalError")):ToBeSameAs(oInner).
        Expect(Err:IsType(oChain, "abl.Errors.NotFoundError")):ToBeFalse().
        /* Base types match too. */
        Expect(Err:IsType(oChain, "Progress.Lang.AppError")):ToBeTrue().
    END METHOD.

    METHOD PUBLIC VOID TestRootIsInnermost():
        DEFINE VARIABLE oInner AS AblError NO-UNDO.
        oInner = NEW AblError("root cause").
        Expect(Err:Root(Err:Wrap(Err:Wrap(oInner, "b"), "a"))):ToBeSameAs(oInner).
    END METHOD.

    METHOD PUBLIC VOID TestWrapOfSysErrorUsesGenericCode():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE oOuter  AS AblError           NO-UNDO.
        DEFINE VARIABLE iValue  AS INTEGER             NO-UNDO.

        DO ON ERROR UNDO, LEAVE:
            iValue = INTEGER("not a number").
            CATCH e AS Progress.Lang.SysError:
                oCaught = e.
            END CATCH.
        END.

        oOuter = Err:Wrap(oCaught, "parsing quantity").
        Expect(oOuter:Code):ToEqual("Error").
        Expect(oOuter:HttpStatus):ToEqual(500).
        Expect(Err:Root(oOuter)):ToBeSameAs(oCaught).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Describe / ToJson                                                */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestDescribeShowsChain():
        DEFINE VARIABLE lcText AS LONGCHAR NO-UNDO.
        lcText = Err:Describe(Err:Wrap(NEW NotFoundError("Customer", "42"), "Loading order 7")).
        Expect(lcText):ToContain("Loading order 7").
        Expect(lcText):ToContain("Caused by: abl.Errors.NotFoundError [NotFound]").
    END METHOD.

    METHOD PUBLIC VOID TestToJsonShape():
        DEFINE VARIABLE oJson AS JsonObject NO-UNDO.
        oJson = Err:ToJson(Err:Wrap(NEW NotFoundError("Customer", "42"), "Loading order 7")).
        Expect(oJson:GetCharacter("code")):ToEqual("NotFound").
        Expect(oJson:GetInteger("httpStatus")):ToEqual(404).
        Expect(oJson:GetCharacter("message")):ToEqual("Loading order 7").
        Expect(oJson:GetJsonObject("cause"):GetJsonObject("context"):GetCharacter("entity")):ToEqual("Customer").
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* ThrowIfStatus                                                    */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestThrowIfStatusAfterFailedStatement():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE iValue  AS INTEGER             NO-UNDO.

        DO ON ERROR UNDO, LEAVE:
            iValue = INTEGER("abc") NO-ERROR.
            Err:ThrowIfStatus("Parsing quantity").
            CATCH e AS AblError:
                oCaught = e.
            END CATCH.
        END.

        Expect(oCaught):ToHaveErrorCode("Status"):ToHaveMessage("Parsing quantity").
    END METHOD.

    METHOD PUBLIC VOID TestThrowIfStatusAfterGoodStatement():
        DEFINE VARIABLE iValue AS INTEGER NO-UNDO.
        iValue = INTEGER("12") NO-ERROR.
        Err:ThrowIfStatus("Parsing quantity").
        Expect(iValue):ToEqual(12).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Guard                                                            */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestGuardNotBlank():
        DEFINE VARIABLE oCaught AS ArgumentError NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            Guard:NotBlank("   ", "pcName").
            CATCH e AS ArgumentError:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToBeValidObject().
        Expect(oCaught:ParamName):ToEqual("pcName").
        Expect(oCaught:HttpStatus):ToEqual(400).
    END METHOD.

    METHOD PUBLIC VOID TestGuardInRangeAcceptsBounds():
        Guard:InRange(1, 1, 10, "piQty").
        Guard:InRange(10, 1, 10, "piQty").
        Expect(TRUE):ToBeTrue().
    END METHOD.

    METHOD PUBLIC VOID TestGuardInRangeRejectsOutside():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            Guard:InRange(11, 1, 10, "piQty").
            CATCH e AS ArgumentError:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveMessage("between 1 and 10").
    END METHOD.

END CLASS.
