/*------------------------------------------------------------------------
    File        : tests/abl/Testing/ExpectationTest.cls
    Purpose     : Tests for the test framework itself: passing checks stay
                  quiet, failing checks throw AssertionFailure with a
                  useful message.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Testing.AssertionFailure.
USING abl.Testing.TestCase.

CLASS abl.Testing.ExpectationTest INHERITS TestCase:

    METHOD PUBLIC VOID TestPassingChecksDoNotThrow():
        Expect(5):ToEqual(5).
        Expect(5):ToEqual(5.0).
        Expect("abc"):ToEqual("ABC").
        Expect("abc"):ToEqualExact("abc").
        Expect(TRUE):ToBeTrue().
        Expect(FALSE):ToBeFalse().
        Expect(10):ToBeGreaterThan(9):ToBeLessThan(11):ToBeBetween(10, 10).
        Expect("hello world"):ToContain("lo w"):ToStartWith("hel"):ToEndWith("rld").
        Expect("hello"):ToMatch("h*o"):ToHaveLength(5).
        Expect(""):ToBeEmpty().
        Expect(TODAY):ToEqual(TODAY).
        Expect(SESSION):ToBeValidHandle().
        Expect(THIS-OBJECT):ToBeInstanceOf("abl.Testing.TestCase"):ToBeSameAs(THIS-OBJECT).
    END METHOD.

    METHOD PUBLIC VOID TestToEqualFailureMessage():
        DEFINE VARIABLE cMessage AS CHARACTER NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            Expect(5):ToEqual(6).
            CATCH e AS AssertionFailure:
                cMessage = e:GetMessage(1).
            END CATCH.
        END.
        Expect(cMessage):ToEqualExact("Expected 6 (INTEGER) but got 5 (INTEGER)").
    END METHOD.

    METHOD PUBLIC VOID TestToEqualExactCatchesCase():
        DEFINE VARIABLE lFailed AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            Expect("abc"):ToEqualExact("ABC").
            CATCH e AS AssertionFailure:
                lFailed = TRUE.
            END CATCH.
        END.
        Expect(lFailed):ToBeTrue().
    END METHOD.

    METHOD PUBLIC VOID TestTypeMismatchFailsInsteadOfCrashing():
        DEFINE VARIABLE cMessage AS CHARACTER NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            Expect("not a number"):ToBeGreaterThan(1).
            CATCH e AS AssertionFailure:
                cMessage = e:GetMessage(1).
            END CATCH.
        END.
        Expect(cMessage):ToContain("needs a number").
    END METHOD.

    METHOD PUBLIC VOID TestToBeSameAsOnNonObjectFails():
        DEFINE VARIABLE lFailed AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            Expect(5):ToBeSameAs(THIS-OBJECT).
            CATCH e AS AssertionFailure:
                lFailed = TRUE.
            END CATCH.
        END.
        Expect(lFailed):ToBeTrue().
    END METHOD.

    METHOD PUBLIC VOID TestFailThrowsAssertionFailure():
        DEFINE VARIABLE cMessage AS CHARACTER NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            Fail("custom reason").
            CATCH e AS AssertionFailure:
                cMessage = e:GetMessage(1).
            END CATCH.
        END.
        Expect(cMessage):ToEqualExact("custom reason").
    END METHOD.

    METHOD PUBLIC VOID TestSkipTestIsReportedAsSkip():
        SkipTest("demonstrates SKIP in the report").
    END METHOD.

END CLASS.
