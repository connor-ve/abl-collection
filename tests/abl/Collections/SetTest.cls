/*------------------------------------------------------------------------
    File        : tests/abl/Collections/SetTest.cls
    Purpose     : Tests for CharSet and IntSet.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Collections.*.
USING abl.Testing.TestCase.

CLASS abl.Collections.SetTest INHERITS TestCase:

    METHOD PUBLIC VOID TestAddIgnoresDuplicates():
        DEFINE VARIABLE oSet AS IntSet NO-UNDO.
        oSet = IntSet:Of(1, 2, 2).
        oSet:Add(1).
        Expect(oSet:Count):ToEqual(2).
        Expect(oSet:Contains(2)):ToBeTrue().
        Expect(oSet:Contains(3)):ToBeFalse().
    END METHOD.

    METHOD PUBLIC VOID TestCharSetIsCaseInsensitive():
        DEFINE VARIABLE oSet AS CharSet NO-UNDO.
        oSet = CharSet:Of("abc", "ABC").
        Expect(oSet:Count):ToEqual(1).
        Expect(oSet:Contains("Abc")):ToBeTrue().
    END METHOD.

    METHOD PUBLIC VOID TestRemove():
        DEFINE VARIABLE oSet AS IntSet NO-UNDO.
        oSet = IntSet:Of(1, 2).
        Expect(oSet:Remove(1)):ToBeTrue().
        Expect(oSet:Remove(1)):ToBeFalse().
        Expect(oSet:Count):ToEqual(1).
    END METHOD.

    METHOD PUBLIC VOID TestUnknownIsRejected():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE iNull   AS INT64               NO-UNDO INITIAL ?.
        DEFINE VARIABLE oSet    AS IntSet              NO-UNDO.
        oSet = NEW IntSet().
        DO ON ERROR UNDO, LEAVE:
            oSet:Add(iNull).
            CATCH e AS Progress.Lang.Error:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveErrorCode("Argument").
    END METHOD.

    METHOD PUBLIC VOID TestToSliceIsSorted():
        Expect(IntSet:Of(3, 1, 2):ToSlice():ToString()):ToEqualExact("[1, 2, 3]").
        Expect(CharSet:Of("b", "a"):ToString()):ToEqualExact("Set[a, b]").
    END METHOD.

    METHOD PUBLIC VOID TestFromSliceRemovesDuplicates():
        Expect(CharSet:FromSlice(CharSlice:FromList("a,b,a,c,b", ",")):Count):ToEqual(3).
    END METHOD.

    METHOD PUBLIC VOID TestUnionIntersectDifference():
        DEFINE VARIABLE oA AS IntSet NO-UNDO.
        DEFINE VARIABLE oB AS IntSet NO-UNDO.
        oA = IntSet:Of(1, 2, 3).
        oB = IntSet:Of(2, 3, 4).
        Expect(oA:Union(oB):ToString()):ToEqualExact("Set[1, 2, 3, 4]").
        Expect(oA:Intersect(oB):ToString()):ToEqualExact("Set[2, 3]").
        Expect(oA:Difference(oB):ToString()):ToEqualExact("Set[1]").
        /* Inputs are unchanged. */
        Expect(oA:Count):ToEqual(3).
    END METHOD.

    METHOD PUBLIC VOID TestSubsetAndEquals():
        Expect(IntSet:Of(1, 2):IsSubsetOf(IntSet:Of(1, 2, 3))):ToBeTrue().
        Expect(IntSet:Of(1, 4):IsSubsetOf(IntSet:Of(1, 2, 3))):ToBeFalse().
        Expect(IntSet:Of(1, 2):Equals(IntSet:Of(2, 1))):ToBeTrue().
        Expect(IntSet:Of(1, 2):Equals(IntSet:Of(1))):ToBeFalse().
    END METHOD.

END CLASS.
