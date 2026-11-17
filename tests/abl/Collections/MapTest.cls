/*------------------------------------------------------------------------
    File        : tests/abl/Collections/MapTest.cls
    Purpose     : Tests for Map.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Collections.Map.
USING abl.Core.Box.
USING abl.Testing.TestCase.

CLASS abl.Collections.MapTest INHERITS TestCase:

    METHOD PUBLIC VOID TestPutAndTypedGetters():
        DEFINE VARIABLE oMap AS Map NO-UNDO.
        oMap = NEW Map().
        oMap:Put("name", "Ann"):Put("count", 3):Put("limit", 12.5):Put("active", TRUE):Put("since", DATE(1, 2, 2026)).

        Expect(oMap:Count):ToEqual(5).
        Expect(oMap:GetChar("name", "")):ToEqualExact("Ann").
        Expect(oMap:GetInt("count", 0)):ToEqual(3).
        Expect(oMap:GetDec("limit", 0)):ToEqual(12.5).
        Expect(oMap:GetLog("active", FALSE)):ToBeTrue().
        Expect(oMap:GetDate("since", ?)):ToEqual(DATE(1, 2, 2026)).
    END METHOD.

    METHOD PUBLIC VOID TestDefaultsOnlyForMissingKeys():
        DEFINE VARIABLE cNull AS CHARACTER NO-UNDO INITIAL ?.
        DEFINE VARIABLE oMap  AS Map       NO-UNDO.
        oMap = NEW Map().
        oMap:Put("blank", cNull).
        Expect(oMap:GetChar("missing", "dflt")):ToEqualExact("dflt").
        Expect(oMap:GetChar("blank", "dflt")):ToBeUnknown().
        Expect(oMap:GetInt("missing", 7)):ToEqual(7).
    END METHOD.

    METHOD PUBLIC VOID TestPutReplacesAndKeysAreCaseInsensitive():
        DEFINE VARIABLE oMap AS Map NO-UNDO.
        oMap = NEW Map().
        oMap:Put("Key", 1):Put("KEY", 2).
        Expect(oMap:Count):ToEqual(1).
        Expect(oMap:GetInt("key", 0)):ToEqual(2).
    END METHOD.

    METHOD PUBLIC VOID TestKeysKeepInsertionOrder():
        DEFINE VARIABLE oMap AS Map NO-UNDO.
        oMap = NEW Map().
        oMap:Put("zebra", 1):Put("apple", 2):Put("mango", 3).
        Expect(oMap:Keys():Join(",")):ToEqualExact("zebra,apple,mango").
        Expect(oMap:SortedKeys():Join(",")):ToEqualExact("apple,mango,zebra").
        Expect(oMap:ToString()):ToEqualExact("Map[zebra=1, apple=2, mango=3]").
    END METHOD.

    METHOD PUBLIC VOID TestValuesAreBoxes():
        DEFINE VARIABLE oMap AS Map NO-UNDO.
        oMap = NEW Map().
        oMap:Put("a", 10):Put("b", "x").
        Expect(oMap:Values():Length):ToEqual(2).
        Expect(oMap:Values():Get(1)):ToEqual(10).
        Expect(oMap:Get("b")):ToBeInstanceOf("abl.Core.Box").
    END METHOD.

    METHOD PUBLIC VOID TestGetMissingIsUnknown():
        DEFINE VARIABLE oMap AS Map NO-UNDO.
        oMap = NEW Map().
        Expect(oMap:Get("nope")):ToBeUnknown().
    END METHOD.

    METHOD PUBLIC VOID TestRemoveAndClear():
        DEFINE VARIABLE oMap AS Map NO-UNDO.
        oMap = NEW Map().
        oMap:Put("a", 1):Put("b", 2).
        Expect(oMap:Remove("a")):ToBeTrue().
        Expect(oMap:Remove("a")):ToBeFalse().
        Expect(oMap:Has("a")):ToBeFalse().
        oMap:Clear().
        Expect(oMap:IsEmpty):ToBeTrue().
    END METHOD.

    METHOD PUBLIC VOID TestObjectValues():
        DEFINE VARIABLE oMap AS Map NO-UNDO.
        oMap = NEW Map().
        oMap:Put("me", THIS-OBJECT).
        Expect(oMap:GetObj("me")):ToBeSameAs(THIS-OBJECT).
        Expect(oMap:GetObj("missing")):ToBeUnknown().
    END METHOD.

    METHOD PUBLIC VOID TestWrongTypeThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE oMap    AS Map                 NO-UNDO.
        DEFINE VARIABLE lValue  AS LOGICAL             NO-UNDO.
        oMap = NEW Map().
        oMap:Put("n", "not a logical").
        DO ON ERROR UNDO, LEAVE:
            lValue = oMap:GetLog("n", FALSE).
            CATCH e AS Progress.Lang.Error:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveErrorCode("InvalidState").
    END METHOD.

    METHOD PUBLIC VOID TestCopyIsIndependent():
        DEFINE VARIABLE oMap  AS Map NO-UNDO.
        DEFINE VARIABLE oCopy AS Map NO-UNDO.
        oMap = NEW Map().
        oMap:Put("a", 1).
        oCopy = oMap:Copy().
        oCopy:Put("b", 2).
        Expect(oMap:Count):ToEqual(1).
        Expect(oCopy:Count):ToEqual(2).
    END METHOD.

END CLASS.
