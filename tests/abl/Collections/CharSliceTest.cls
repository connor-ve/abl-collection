/*------------------------------------------------------------------------
    File        : tests/abl/Collections/CharSliceTest.cls
    Purpose     : Tests for CharSlice. CharSlice comes from the same
                  template as every other slice, so these tests cover the
                  shared behaviour in depth; the other slice tests only
                  check what differs per type.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Collections.CharSlice.
USING abl.Errors.ArgumentError.
USING abl.Testing.TestCase.

CLASS abl.Collections.CharSliceTest INHERITS TestCase:

    /* ---------------------------------------------------------------- */
    /* Construction                                                     */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestNewSliceIsEmpty():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        oSlice = NEW CharSlice().
        Expect(oSlice:Length):ToEqual(0).
        Expect(oSlice:IsEmpty):ToBeTrue().
        Expect(oSlice:Capacity):ToBeAtLeast(8).
        Expect(oSlice:ToString()):ToEqualExact("[]").
    END METHOD.

    METHOD PUBLIC VOID TestMakeWithLengthGivesZeroValues():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        oSlice = NEW CharSlice(3).
        Expect(oSlice:Length):ToEqual(3).
        Expect(oSlice:Get(2)):ToEqualExact("").
    END METHOD.

    METHOD PUBLIC VOID TestOfAndFromArray():
        DEFINE VARIABLE aValues AS CHARACTER NO-UNDO EXTENT 3 INITIAL ["x", "y", "z"].
        Expect(CharSlice:Of("a", "b", "c"):ToString()):ToEqualExact("[a, b, c]").
        Expect(CharSlice:FromArray(aValues):ToString()):ToEqualExact("[x, y, z]").
    END METHOD.

    METHOD PUBLIC VOID TestNegativeLengthThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE oSlice  AS CharSlice           NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            oSlice = NEW CharSlice(-1).
            CATCH e AS Progress.Lang.Error:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveErrorCode("Argument").
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Access                                                           */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestGetSetFirstLast():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        oSlice = CharSlice:Of("a", "b", "c").
        oSlice:Set(2, "B").
        Expect(oSlice:Get(2)):ToEqualExact("B").
        Expect(oSlice:First()):ToEqualExact("a").
        Expect(oSlice:Last()):ToEqualExact("c").
    END METHOD.

    METHOD PUBLIC VOID TestIndexOutOfRangeThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE cValue  AS CHARACTER           NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            cValue = CharSlice:Of("a"):Get(2).
            CATCH e AS ArgumentError:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveMessage("out of range 1 to 1").
    END METHOD.

    METHOD PUBLIC VOID TestFirstOnEmptyThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE cValue  AS CHARACTER           NO-UNDO.
        DEFINE VARIABLE oEmpty  AS CharSlice           NO-UNDO.
        oEmpty = NEW CharSlice().
        DO ON ERROR UNDO, LEAVE:
            cValue = oEmpty:First().
            CATCH e AS Progress.Lang.Error:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveErrorCode("InvalidState").
    END METHOD.

    METHOD PUBLIC VOID TestUnknownElementsAreAllowed():
        DEFINE VARIABLE cNull  AS CHARACTER NO-UNDO INITIAL ?.
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        oSlice = CharSlice:Of("a", cNull).
        Expect(oSlice:Get(2)):ToBeUnknown().
        Expect(oSlice:IndexOf(cNull)):ToEqual(2).
        Expect(oSlice:ToString()):ToEqualExact("[a, ?]").
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Growth                                                           */
    /* ---------------------------------------------------------------- */

    /* Crosses the single-chunk limit (4096) and several blocks. */
    METHOD PUBLIC VOID TestAppendPastChunkBoundaries():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.

        oSlice = NEW CharSlice().
        DO i = 1 TO 10000:
            oSlice:Append(STRING(i)).
        END.

        Expect(oSlice:Length):ToEqual(10000).
        Expect(oSlice:Capacity):ToBeAtLeast(10000).
        Expect(oSlice:Get(1)):ToEqualExact("1").
        Expect(oSlice:Get(4096)):ToEqualExact("4096").
        Expect(oSlice:Get(4097)):ToEqualExact("4097").
        Expect(oSlice:Get(8193)):ToEqualExact("8193").
        Expect(oSlice:Get(10000)):ToEqualExact("10000").
    END METHOD.

    /* Past the 28000-element limit of a single ABL array. */
    METHOD PUBLIC VOID TestBeyondAblArrayLimit():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.

        oSlice = NEW CharSlice(0, 30000).
        DO i = 1 TO 30000:
            oSlice:Append("x").
        END.
        oSlice:Set(30000, "last").
        Expect(oSlice:Length):ToEqual(30000).
        Expect(oSlice:Get(30000)):ToEqualExact("last").
    END METHOD.

    METHOD PUBLIC VOID TestAppendSliceAndArray():
        DEFINE VARIABLE aMore  AS CHARACTER NO-UNDO EXTENT 2 INITIAL ["e", "f"].
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        oSlice = CharSlice:Of("a", "b").
        oSlice:AppendSlice(CharSlice:Of("c", "d")):AppendArray(aMore).
        Expect(oSlice:Join("")):ToEqualExact("abcdef").
    END METHOD.

    METHOD PUBLIC VOID TestAppendSliceToItself():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        oSlice = CharSlice:Of("a", "b").
        oSlice:AppendSlice(oSlice).
        Expect(oSlice:Join("")):ToEqualExact("abab").
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Views (Go-style sharing)                                         */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestSubSharesStorage():
        DEFINE VARIABLE oAll  AS CharSlice NO-UNDO.
        DEFINE VARIABLE oView AS CharSlice NO-UNDO.

        oAll  = CharSlice:Of("a", "b", "c", "d").
        oView = oAll:Sub(2, 3).

        Expect(oView:ToString()):ToEqualExact("[b, c]").
        oView:Set(1, "B").
        Expect(oAll:Get(2)):ToEqualExact("B").
        oAll:Set(3, "C").
        Expect(oView:Get(2)):ToEqualExact("C").
    END METHOD.

    /* The Go gotcha this design avoids: appending to a view must not
       overwrite the parent's next element. */
    METHOD PUBLIC VOID TestAppendToViewDoesNotOverwriteParent():
        DEFINE VARIABLE oAll  AS CharSlice NO-UNDO.
        DEFINE VARIABLE oView AS CharSlice NO-UNDO.

        oAll  = CharSlice:Of("a", "b", "c", "d").
        oView = oAll:Sub(2, 3).
        oView:Append("X").

        Expect(oAll:Get(4)):ToEqualExact("d").
        Expect(oView:ToString()):ToEqualExact("[b, c, X]").

        /* The view now has its own storage. */
        oView:Set(1, "z").
        Expect(oAll:Get(2)):ToEqualExact("b").
    END METHOD.

    METHOD PUBLIC VOID TestViewAtEndAppendsInPlace():
        DEFINE VARIABLE oAll  AS CharSlice NO-UNDO.
        DEFINE VARIABLE oView AS CharSlice NO-UNDO.

        oAll  = CharSlice:Of("a", "b").
        oView = oAll:Sub(1, 2).
        oView:Append("c").

        Expect(oAll:Length):ToEqual(2).
        Expect(oView:Length):ToEqual(3).

        /* Parent no longer owns the end, so it detaches instead of
           overwriting the view's "c". */
        oAll:Append("d").
        Expect(oView:Get(3)):ToEqualExact("c").
        Expect(oAll:Get(3)):ToEqualExact("d").
    END METHOD.

    METHOD PUBLIC VOID TestEmptySubIsValid():
        DEFINE VARIABLE oView AS CharSlice NO-UNDO.
        oView = CharSlice:Of("a", "b"):Sub(3, 2).
        Expect(oView:Length):ToEqual(0).
        oView:Append("x").
        Expect(oView:Get(1)):ToEqualExact("x").
    END METHOD.

    METHOD PUBLIC VOID TestSubOutOfRangeThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE oView   AS CharSlice           NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            oView = CharSlice:Of("a", "b"):Sub(2, 3).
            CATCH e AS ArgumentError:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveMessage("out of range").
    END METHOD.

    METHOD PUBLIC VOID TestCopyIsIndependent():
        DEFINE VARIABLE oAll  AS CharSlice NO-UNDO.
        DEFINE VARIABLE oCopy AS CharSlice NO-UNDO.
        oAll  = CharSlice:Of("a", "b").
        oCopy = oAll:Copy().
        oCopy:Set(1, "z").
        Expect(oAll:Get(1)):ToEqualExact("a").
        Expect(oCopy:Equals(CharSlice:Of("z", "b"))):ToBeTrue().
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Insert / remove / clear                                          */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestInsertAt():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        oSlice = CharSlice:Of("a", "c").
        oSlice:InsertAt(2, "b"):InsertAt(1, "start"):InsertAt(5, "end").
        Expect(oSlice:Join(",")):ToEqualExact("start,a,b,c,end").
    END METHOD.

    METHOD PUBLIC VOID TestRemoveAt():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        oSlice = CharSlice:Of("a", "b", "c", "d").
        oSlice:RemoveAt(2):RemoveAt(3).
        Expect(oSlice:Join(",")):ToEqualExact("a,c").
    END METHOD.

    METHOD PUBLIC VOID TestClearKeepsCapacity():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        DEFINE VARIABLE iCap   AS INTEGER   NO-UNDO.
        oSlice = CharSlice:Of("a", "b", "c").
        iCap = oSlice:Capacity.
        oSlice:Clear().
        Expect(oSlice:Length):ToEqual(0).
        Expect(oSlice:Capacity):ToEqual(iCap).
        oSlice:Append("x").
        Expect(oSlice:ToString()):ToEqualExact("[x]").
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Search and order                                                 */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestIndexOfAndContains():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        oSlice = CharSlice:Of("a", "b", "a").
        Expect(oSlice:IndexOf("a")):ToEqual(1).
        Expect(oSlice:IndexOf("B")):ToEqual(2).          /* ABL: case-insensitive */
        Expect(oSlice:IndexOf("zz")):ToEqual(0).
        Expect(oSlice:Contains("b")):ToBeTrue().
    END METHOD.

    METHOD PUBLIC VOID TestReverse():
        Expect(CharSlice:Of("a", "b", "c", "d"):Reverse():Join("")):ToEqualExact("dcba").
        Expect(CharSlice:Of("a", "b", "c"):Reverse():Join("")):ToEqualExact("cba").
    END METHOD.

    METHOD PUBLIC VOID TestSortIsCaseInsensitiveAndStable():
        Expect(CharSlice:Of("pear", "Apple", "banana"):Sort():Join(",")):ToEqualExact("Apple,banana,pear").
        /* "b" and "B" are equal for sorting: original order is kept. */
        Expect(CharSlice:Of("b", "a", "B"):Sort():Join(",")):ToEqualExact("a,b,B").
        Expect(CharSlice:Of("a", "c", "b"):SortDescending():Join(",")):ToEqualExact("c,b,a").
    END METHOD.

    METHOD PUBLIC VOID TestMinMax():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        oSlice = CharSlice:Of("m", "c", "x").
        Expect(oSlice:Min()):ToEqualExact("c").
        Expect(oSlice:Max()):ToEqualExact("x").
        oSlice = NEW CharSlice().
        Expect(oSlice:Min()):ToBeUnknown().
    END METHOD.

    METHOD PUBLIC VOID TestToArray():
        DEFINE VARIABLE aOut AS CHARACTER NO-UNDO EXTENT.
        aOut = CharSlice:Of("a", "b"):ToArray().
        Expect(EXTENT(aOut)):ToEqual(2).
        Expect(aOut[2]):ToEqualExact("b").
    END METHOD.

    METHOD PUBLIC VOID TestEquals():
        Expect(CharSlice:Of("a", "b"):Equals(CharSlice:Of("a", "b"))):ToBeTrue().
        Expect(CharSlice:Of("a", "b"):Equals(CharSlice:Of("a"))):ToBeFalse().
        Expect(CharSlice:Of("a"):Equals(THIS-OBJECT)):ToBeFalse().
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Lists                                                            */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestFromListMatchesEntrySemantics():
        DEFINE VARIABLE oSlice AS CharSlice NO-UNDO.
        oSlice = CharSlice:FromList("a,b,,c,", ",").
        Expect(oSlice:Length):ToEqual(5).
        Expect(oSlice:Get(3)):ToEqualExact("").
        Expect(oSlice:Get(5)):ToEqualExact("").
        Expect(CharSlice:FromList("", ","):Length):ToEqual(0).
    END METHOD.

    METHOD PUBLIC VOID TestFromListMultiCharDelimiter():
        Expect(CharSlice:FromList("a::b::c", "::"):Join("|")):ToEqualExact("a|b|c").
    END METHOD.

    METHOD PUBLIC VOID TestJoinTreatsUnknownAsEmpty():
        DEFINE VARIABLE cNull AS CHARACTER NO-UNDO INITIAL ?.
        Expect(CharSlice:Of("a", cNull, "c"):Join(",")):ToEqualExact("a,,c").
    END METHOD.

END CLASS.
