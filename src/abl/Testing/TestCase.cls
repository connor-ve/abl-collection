/*------------------------------------------------------------------------
    File        : abl/Testing/TestCase.cls
    Purpose     : Base class for tests. Inherit from it and write PUBLIC
                  VOID methods with no parameters whose names start with
                  "Test". The runner finds them by name, so there are no
                  annotations to forget.

    Example
        CLASS app.InvoiceTest INHERITS abl.Testing.TestCase:
            METHOD PUBLIC VOID TestTotalIncludesTax():
                Expect(oInvoice:Total()):ToEqual(107.50).
            END METHOD.
        END CLASS.

    Lifecycle (override any of them)
        BeforeAll()   once, before the first test in the class
        Setup()       before every test
        Teardown()    after every test, even a failed one
        AfterAll()    once, after the last test

    Database changes
        Each test (Setup + test + Teardown) runs inside a transaction
        that is undone afterwards, so tests leave no rows behind. Set
        RollbackDb = FALSE in the constructor to keep changes.
        Temp-tables defined NO-UNDO are not affected.

    Testing that something throws
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            oSvc:Post(-1).
            CATCH e AS Progress.Lang.Error:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveErrorCode("Argument").
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.Object.
USING abl.Core.Box.
USING abl.Testing.AssertionFailure.
USING abl.Testing.Expectation.
USING abl.Testing.SkipSignal.

CLASS abl.Testing.TestCase ABSTRACT:

    DEFINE PUBLIC PROPERTY RollbackDb AS LOGICAL NO-UNDO INITIAL TRUE
        GET.
        PROTECTED SET.

    CONSTRUCTOR PUBLIC TestCase():
    END CONSTRUCTOR.

    /* ---------------------------------------------------------------- */
    /* Lifecycle hooks                                                  */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID BeforeAll():
    END METHOD.

    METHOD PUBLIC VOID Setup():
    END METHOD.

    METHOD PUBLIC VOID Teardown():
    END METHOD.

    METHOD PUBLIC VOID AfterAll():
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Expect(value)                                                    */
    /* ---------------------------------------------------------------- */

    METHOD PROTECTED Expectation Expect(INPUT pcValue AS CHARACTER):
        RETURN NEW Expectation(NEW Box(pcValue)).
    END METHOD.

    METHOD PROTECTED Expectation Expect(INPUT plcValue AS LONGCHAR):
        RETURN NEW Expectation(NEW Box(plcValue)).
    END METHOD.

    METHOD PROTECTED Expectation Expect(INPUT piValue AS INTEGER):
        RETURN NEW Expectation(NEW Box(piValue)).
    END METHOD.

    METHOD PROTECTED Expectation Expect(INPUT piValue AS INT64):
        RETURN NEW Expectation(NEW Box(piValue)).
    END METHOD.

    METHOD PROTECTED Expectation Expect(INPUT pdValue AS DECIMAL):
        RETURN NEW Expectation(NEW Box(pdValue)).
    END METHOD.

    METHOD PROTECTED Expectation Expect(INPUT plValue AS LOGICAL):
        RETURN NEW Expectation(NEW Box(plValue)).
    END METHOD.

    METHOD PROTECTED Expectation Expect(INPUT pdaValue AS DATE):
        RETURN NEW Expectation(NEW Box(pdaValue)).
    END METHOD.

    METHOD PROTECTED Expectation Expect(INPUT pdtValue AS DATETIME):
        RETURN NEW Expectation(NEW Box(pdtValue)).
    END METHOD.

    METHOD PROTECTED Expectation Expect(INPUT pdtzValue AS DATETIME-TZ):
        RETURN NEW Expectation(NEW Box(pdtzValue)).
    END METHOD.

    METHOD PROTECTED Expectation Expect(INPUT phValue AS HANDLE):
        RETURN NEW Expectation(NEW Box(phValue)).
    END METHOD.

    /* A Box is checked by its value; any other object as an object. */
    METHOD PROTECTED Expectation Expect(INPUT poValue AS Object):
        IF VALID-OBJECT(poValue) AND TYPE-OF(poValue, Box) THEN
            RETURN NEW Expectation(CAST(poValue, Box)).
        RETURN NEW Expectation(NEW Box(poValue)).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Control                                                          */
    /* ---------------------------------------------------------------- */

    METHOD PROTECTED VOID Fail(INPUT pcMessage AS CHARACTER):
        UNDO, THROW NEW AssertionFailure(pcMessage).
    END METHOD.

    /* Ends the test and reports it as SKIP. */
    METHOD PROTECTED VOID SkipTest(INPUT pcReason AS CHARACTER):
        UNDO, THROW NEW SkipSignal(pcReason).
    END METHOD.

END CLASS.
