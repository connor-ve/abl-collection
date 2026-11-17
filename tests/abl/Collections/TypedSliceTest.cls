/*------------------------------------------------------------------------
    File        : tests/abl/Collections/TypedSliceTest.cls
    Purpose     : What differs per element type: IntSlice, DecSlice,
                  LogSlice, DateSlice and ObjSlice. Shared behaviour is
                  covered by CharSliceTest.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Collections.*.
USING abl.Core.Box.
USING abl.Testing.TestCase.

CLASS abl.Collections.TypedSliceTest INHERITS TestCase:

    /* ---------------------------------------------------------------- */
    /* IntSlice                                                         */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestIntZeroValue():
        DEFINE VARIABLE oInts AS IntSlice NO-UNDO.
        oInts = NEW IntSlice(2).
        Expect(oInts:Get(1)):ToEqual(0).
    END METHOD.

    METHOD PUBLIC VOID TestIntSortSumAverage():
        DEFINE VARIABLE oInts AS IntSlice NO-UNDO.
        oInts = IntSlice:Of(30, 10, 20).
        Expect(oInts:Sum()):ToEqual(60).
        Expect(oInts:Average()):ToEqual(20).
        Expect(oInts:Min()):ToEqual(10).
        Expect(oInts:Max()):ToEqual(30).
        Expect(oInts:Sort():ToString()):ToEqualExact("[10, 20, 30]").
    END METHOD.

    /* Numeric sort, not text sort: 9 before 10. */
    METHOD PUBLIC VOID TestIntSortsNumerically():
        Expect(IntSlice:Of(10, 9, 100):Sort():ToString()):ToEqualExact("[9, 10, 100]").
    END METHOD.

    METHOD PUBLIC VOID TestIntHoldsInt64Range():
        DEFINE VARIABLE iBig AS INT64 NO-UNDO INITIAL 9000000000.
        Expect(IntSlice:Of(iBig):Get(1)):ToEqual(iBig).
    END METHOD.

    METHOD PUBLIC VOID TestIntLargeSlice():
        DEFINE VARIABLE oInts AS IntSlice NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER  NO-UNDO.
        oInts = NEW IntSlice().
        DO i = 1 TO 50000:
            oInts:Append(i).
        END.
        Expect(oInts:Sum()):ToEqual(1250025000).
        Expect(oInts:Get(50000)):ToEqual(50000).
    END METHOD.

    METHOD PUBLIC VOID TestIntSumSkipsUnknown():
        DEFINE VARIABLE iNull AS INT64 NO-UNDO INITIAL ?.
        Expect(IntSlice:Of(1, iNull, 2):Sum()):ToEqual(3).
        Expect(IntSlice:Of(iNull):Average()):ToBeUnknown().
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* DecSlice                                                         */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestDecSumAndAverage():
        DEFINE VARIABLE oDecs AS DecSlice NO-UNDO.
        oDecs = DecSlice:Of(1.5, 2.25, 0.25).
        Expect(oDecs:Sum()):ToEqual(4.0).
        Expect(oDecs:Average()):ToBeBetween(1.3333, 1.3334).
    END METHOD.

    METHOD PUBLIC VOID TestDecAcceptsIntegerLiterals():
        Expect(DecSlice:Of(1, 2):Sum()):ToEqual(3).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* LogSlice                                                         */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestLogZeroValueIsFalse():
        DEFINE VARIABLE oLogs AS LogSlice NO-UNDO.
        oLogs = NEW LogSlice(1).
        Expect(oLogs:Get(1)):ToBeFalse().
    END METHOD.

    METHOD PUBLIC VOID TestLogIndexOf():
        Expect(LogSlice:Of(TRUE, TRUE, FALSE):IndexOf(FALSE)):ToEqual(3).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* DateSlice                                                        */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestDateZeroValueIsUnknown():
        DEFINE VARIABLE oDates AS DateSlice NO-UNDO.
        oDates = NEW DateSlice(1).
        Expect(oDates:Get(1)):ToBeUnknown().
    END METHOD.

    METHOD PUBLIC VOID TestDateSortMinMax():
        DEFINE VARIABLE oDates AS DateSlice NO-UNDO.
        oDates = DateSlice:Of(DATE(5, 1, 2026), DATE(1, 1, 2026), DATE(3, 1, 2026)).
        oDates:Sort().
        Expect(oDates:First()):ToEqual(DATE(1, 1, 2026)).
        Expect(oDates:Last()):ToEqual(DATE(5, 1, 2026)).
        Expect(oDates:Max()):ToEqual(DATE(5, 1, 2026)).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* ObjSlice                                                         */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestObjUsesEqualsForSearch():
        DEFINE VARIABLE oObjs AS ObjSlice NO-UNDO.
        oObjs = ObjSlice:Of(NEW Box("a"), NEW Box(5)).
        /* A different Box with the same value is found. */
        Expect(oObjs:IndexOf(NEW Box(5))):ToEqual(2).
        Expect(oObjs:Contains(NEW Box(6))):ToBeFalse().
    END METHOD.

    METHOD PUBLIC VOID TestObjHoldsUnknown():
        DEFINE VARIABLE oNull AS Progress.Lang.Object NO-UNDO.
        DEFINE VARIABLE oObjs AS ObjSlice             NO-UNDO.
        oObjs = ObjSlice:Of(oNull, THIS-OBJECT).
        Expect(oObjs:Get(1)):ToBeUnknown().
        Expect(oObjs:IndexOf(oNull)):ToEqual(1).
        Expect(oObjs:Get(2)):ToBeSameAs(THIS-OBJECT).
    END METHOD.

    METHOD PUBLIC VOID TestObjRemoveReleasesSlot():
        DEFINE VARIABLE oObjs AS ObjSlice NO-UNDO.
        oObjs = ObjSlice:Of(NEW Box(1), NEW Box(2)).
        oObjs:RemoveAt(1).
        Expect(oObjs:Length):ToEqual(1).
        Expect(oObjs:Get(1)):ToEqual(2).
    END METHOD.

END CLASS.
