/*------------------------------------------------------------------------
    File        : abl/Collections/DecSlice.cls
    GENERATED   : by tools/gen-collections.sh from tools/templates/Slice.cls.tpl.
                  Edit the template and regenerate; edits here are lost.
    Purpose     : A growable list of DECIMAL values, modelled on Go slices.

    Indexes are 1-based, like ABL arrays.

    Usage
        oItems = NEW DecSlice().          empty
        oItems = NEW DecSlice(10).        10 zero values (like Go make)
        oItems = DecSlice:Of(a, b, c).    up to 6 values
        oItems = DecSlice:FromArray(aValues).

        oItems:Append(x):Append(y).
        DO i = 1 TO oItems:Length:
            ... oItems:Get(i) ...
        END.

    Sharing
        Sub(from, to) returns a view of elements from..to over the same
        storage, without copying. Set() through either one is visible in
        the other, as in Go.
        Unlike Go, appending to a view never overwrites elements of the
        slice it came from: a view that does not own the end of the
        storage copies itself first. Copy() always gives an independent
        slice.

    Size
        Storage doubles up to 4096 elements, then grows in blocks of
        4096. There is no fixed maximum (ABL arrays stop at 28000) and
        large slices never copy everything when they grow.

    Zero value for new elements: 0
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Collections.Internal.DecStore.
USING abl.Errors.ArgumentError.
USING abl.Errors.InvalidStateError.

CLASS abl.Collections.DecSlice:

    DEFINE PRIVATE VARIABLE oStore AS DecStore NO-UNDO.
    DEFINE PRIVATE VARIABLE iStart AS INTEGER     NO-UNDO INITIAL 1.  /* store position of element 1 */
    DEFINE PRIVATE VARIABLE iLen   AS INTEGER     NO-UNDO.

    /* Work table for Sort(). */
    DEFINE PRIVATE TEMP-TABLE ttSort NO-UNDO
        FIELD SortValue AS DECIMAL
        FIELD Seq       AS INTEGER
        INDEX ixValue SortValue Seq.


    DEFINE PUBLIC PROPERTY Length AS INTEGER NO-UNDO
        GET():
            RETURN iLen.
        END GET.

    /* Elements this slice can hold before its storage must grow. */
    DEFINE PUBLIC PROPERTY Capacity AS INTEGER NO-UNDO
        GET():
            RETURN oStore:Capacity - iStart + 1.
        END GET.

    DEFINE PUBLIC PROPERTY IsEmpty AS LOGICAL NO-UNDO
        GET():
            RETURN iLen = 0.
        END GET.

    /* ---------------------------------------------------------------- */
    /* Construction                                                     */
    /* ---------------------------------------------------------------- */

    CONSTRUCTOR PUBLIC DecSlice():
        THIS-OBJECT(0, 8).
    END CONSTRUCTOR.

    /* piLength zero-value elements. */
    CONSTRUCTOR PUBLIC DecSlice(INPUT piLength AS INTEGER):
        THIS-OBJECT(piLength, MAXIMUM(piLength, 8)).
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC DecSlice(INPUT piLength AS INTEGER, INPUT piCapacity AS INTEGER):
        IF piLength = ? OR piLength < 0 THEN
            UNDO, THROW NEW ArgumentError(SUBSTITUTE("Length must be 0 or more (got &1)", piLength), "piLength").
        IF piCapacity = ? OR piCapacity < piLength THEN
            UNDO, THROW NEW ArgumentError(SUBSTITUTE("Capacity &1 is less than length &2", piCapacity, piLength), "piCapacity").

        oStore = NEW DecStore(piCapacity).
        oStore:Used = piLength.
        ASSIGN iStart = 1
               iLen   = piLength.
    END CONSTRUCTOR.

    /* A view over existing storage; used by Sub(). */
    CONSTRUCTOR PRIVATE DecSlice(INPUT poStore AS DecStore, INPUT piStart AS INTEGER, INPUT piLength AS INTEGER):
        ASSIGN oStore = poStore
               iStart = piStart
               iLen   = piLength.
    END CONSTRUCTOR.

    METHOD PUBLIC STATIC DecSlice FromArray(INPUT pdValues AS DECIMAL EXTENT):
        DEFINE VARIABLE oOut   AS DecSlice NO-UNDO.
        DEFINE VARIABLE iCount AS INTEGER     NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER     NO-UNDO.

        iCount = EXTENT(pdValues).
        IF iCount = ? THEN iCount = 0.

        oOut = NEW DecSlice(0, MAXIMUM(iCount, 8)).
        DO i = 1 TO iCount:
            oOut:Append(pdValues[i]).
        END.
        RETURN oOut.
    END METHOD.

    METHOD PUBLIC STATIC DecSlice Of(INPUT pdA AS DECIMAL):
        DEFINE VARIABLE oOut AS DecSlice NO-UNDO.
        oOut = NEW DecSlice().
        RETURN oOut:Append(pdA).
    END METHOD.

    METHOD PUBLIC STATIC DecSlice Of(INPUT pdA AS DECIMAL, INPUT pdB AS DECIMAL):
        DEFINE VARIABLE oOut AS DecSlice NO-UNDO.
        oOut = NEW DecSlice().
        RETURN oOut:Append(pdA):Append(pdB).
    END METHOD.

    METHOD PUBLIC STATIC DecSlice Of(INPUT pdA AS DECIMAL, INPUT pdB AS DECIMAL, INPUT pdC AS DECIMAL):
        DEFINE VARIABLE oOut AS DecSlice NO-UNDO.
        oOut = NEW DecSlice().
        RETURN oOut:Append(pdA):Append(pdB):Append(pdC).
    END METHOD.

    METHOD PUBLIC STATIC DecSlice Of(INPUT pdA AS DECIMAL, INPUT pdB AS DECIMAL, INPUT pdC AS DECIMAL,
                                        INPUT pdD AS DECIMAL):
        DEFINE VARIABLE oOut AS DecSlice NO-UNDO.
        oOut = NEW DecSlice().
        RETURN oOut:Append(pdA):Append(pdB):Append(pdC):Append(pdD).
    END METHOD.

    METHOD PUBLIC STATIC DecSlice Of(INPUT pdA AS DECIMAL, INPUT pdB AS DECIMAL, INPUT pdC AS DECIMAL,
                                        INPUT pdD AS DECIMAL, INPUT pdE AS DECIMAL):
        DEFINE VARIABLE oOut AS DecSlice NO-UNDO.
        oOut = NEW DecSlice().
        RETURN oOut:Append(pdA):Append(pdB):Append(pdC):Append(pdD):Append(pdE).
    END METHOD.

    METHOD PUBLIC STATIC DecSlice Of(INPUT pdA AS DECIMAL, INPUT pdB AS DECIMAL, INPUT pdC AS DECIMAL,
                                        INPUT pdD AS DECIMAL, INPUT pdE AS DECIMAL, INPUT pdF AS DECIMAL):
        DEFINE VARIABLE oOut AS DecSlice NO-UNDO.
        oOut = NEW DecSlice().
        RETURN oOut:Append(pdA):Append(pdB):Append(pdC):Append(pdD):Append(pdE):Append(pdF).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Reading and writing                                              */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC DECIMAL Get(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN oStore:GetAt(iStart + piIndex - 1).
    END METHOD.

    METHOD PUBLIC DecSlice Set(INPUT piIndex AS INTEGER, INPUT pdValue AS DECIMAL):
        CheckIndex(piIndex).
        oStore:SetAt(iStart + piIndex - 1, pdValue).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC DECIMAL First():
        RequireItems("First").
        RETURN oStore:GetAt(iStart).
    END METHOD.

    METHOD PUBLIC DECIMAL Last():
        RequireItems("Last").
        RETURN oStore:GetAt(iStart + iLen - 1).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Growing and shrinking                                            */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC DecSlice Append(INPUT pdValue AS DECIMAL):
        PrepareAppend(1).
        oStore:SetAt(iStart + iLen, pdValue).
        iLen = iLen + 1.
        oStore:Used = iStart + iLen - 1.
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC DecSlice AppendSlice(INPUT poOther AS DecSlice):
        DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.

        IF NOT VALID-OBJECT(poOther) THEN RETURN THIS-OBJECT.

        /* Read the length first: poOther may be this slice. */
        iCount = poOther:Length.
        IF iCount = 0 THEN RETURN THIS-OBJECT.

        PrepareAppend(iCount).
        DO i = 1 TO iCount:
            oStore:SetAt(iStart + iLen + i - 1, poOther:Get(i)).
        END.
        iLen = iLen + iCount.
        oStore:Used = iStart + iLen - 1.
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC DecSlice AppendArray(INPUT pdValues AS DECIMAL EXTENT):
        DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.

        iCount = EXTENT(pdValues).
        IF iCount = ? OR iCount = 0 THEN RETURN THIS-OBJECT.

        PrepareAppend(iCount).
        DO i = 1 TO iCount:
            oStore:SetAt(iStart + iLen + i - 1, pdValues[i]).
        END.
        iLen = iLen + iCount.
        oStore:Used = iStart + iLen - 1.
        RETURN THIS-OBJECT.
    END METHOD.

    /* Inserts before piIndex; piIndex = Length + 1 appends. */
    METHOD PUBLIC DecSlice InsertAt(INPUT piIndex AS INTEGER, INPUT pdValue AS DECIMAL):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.

        IF piIndex = ? OR piIndex < 1 OR piIndex > iLen + 1 THEN
            UNDO, THROW NEW ArgumentError(SUBSTITUTE("Insert position &1 is out of range 1 to &2", piIndex, iLen + 1), "piIndex").

        PrepareAppend(1).
        DO i = iLen TO piIndex BY -1:
            oStore:SetAt(iStart + i, oStore:GetAt(iStart + i - 1)).
        END.
        oStore:SetAt(iStart + piIndex - 1, pdValue).
        iLen = iLen + 1.
        oStore:Used = iStart + iLen - 1.
        RETURN THIS-OBJECT.
    END METHOD.

    /* Removes one element and closes the gap. On a view this shifts the
       shared storage, as the equivalent Go code would. */
    METHOD PUBLIC DecSlice RemoveAt(INPUT piIndex AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.

        CheckIndex(piIndex).
        DO i = piIndex TO iLen - 1:
            oStore:SetAt(iStart + i - 1, oStore:GetAt(iStart + i)).
        END.

        IF OwnsTail() THEN DO:
            /* Release the vacated slot (matters for object references). */
            oStore:SetAt(iStart + iLen - 1, 0).
            oStore:Used = oStore:Used - 1.
        END.
        iLen = iLen - 1.
        RETURN THIS-OBJECT.
    END METHOD.

    /* Length becomes 0; capacity is kept for reuse. */
    METHOD PUBLIC DecSlice Clear():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.

        IF OwnsTail() THEN DO:
            DO i = 1 TO iLen:
                oStore:SetAt(iStart + i - 1, 0).
            END.
            oStore:Used = iStart - 1.
        END.
        iLen = 0.
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Views and copies                                                 */
    /* ---------------------------------------------------------------- */

    /* Elements piFrom to piTo inclusive, sharing storage.
       Sub(n + 1, n) is a valid empty view. */
    METHOD PUBLIC DecSlice Sub(INPUT piFrom AS INTEGER, INPUT piTo AS INTEGER):
        IF piFrom = ? OR piTo = ? OR piFrom < 1 OR piFrom > iLen + 1 OR piTo < piFrom - 1 OR piTo > iLen THEN
            UNDO, THROW NEW ArgumentError(
                SUBSTITUTE("Sub(&1, &2) is out of range for length &3", piFrom, piTo, iLen), "piFrom").

        RETURN NEW DecSlice(oStore, iStart + piFrom - 1, piTo - piFrom + 1).
    END METHOD.

    /* Independent copy with its own storage. */
    METHOD PUBLIC DecSlice Copy():
        DEFINE VARIABLE oOut AS DecSlice NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER     NO-UNDO.

        oOut = NEW DecSlice(0, MAXIMUM(iLen, 8)).
        DO i = 1 TO iLen:
            oOut:Append(oStore:GetAt(iStart + i - 1)).
        END.
        RETURN oOut.
    END METHOD.

    METHOD PUBLIC DECIMAL EXTENT ToArray():
        DEFINE VARIABLE aOut AS DECIMAL EXTENT NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.

        IF iLen = 0 THEN RETURN aOut.
        EXTENT(aOut) = iLen.
        DO i = 1 TO iLen:
            aOut[i] = oStore:GetAt(iStart + i - 1).
        END.
        RETURN aOut.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Searching and reordering                                         */
    /* ---------------------------------------------------------------- */

    /* First index holding the value, or 0. */
    METHOD PUBLIC INTEGER IndexOf(INPUT pdValue AS DECIMAL):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO iLen:
            IF ItemEquals(oStore:GetAt(iStart + i - 1), pdValue) THEN RETURN i.
        END.
        RETURN 0.
    END METHOD.

    METHOD PUBLIC LOGICAL Contains(INPUT pdValue AS DECIMAL):
        RETURN THIS-OBJECT:IndexOf(pdValue) > 0.
    END METHOD.

    METHOD PUBLIC DecSlice Reverse():
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE j     AS INTEGER NO-UNDO.
        DEFINE VARIABLE xTemp AS DECIMAL  NO-UNDO.

        ASSIGN i = iStart
               j = iStart + iLen - 1.
        DO WHILE i < j:
            xTemp = oStore:GetAt(i).
            oStore:SetAt(i, oStore:GetAt(j)).
            oStore:SetAt(j, xTemp).
            ASSIGN i = i + 1
                   j = j - 1.
        END.
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Element comparison and text (scalar types)                       */
    /* ---------------------------------------------------------------- */

    /* ABL equality: ? equals ?, text ignores case and trailing blanks. */
    METHOD PRIVATE LOGICAL ItemEquals(INPUT pdA AS DECIMAL, INPUT pdB AS DECIMAL):
        RETURN pdA = pdB.
    END METHOD.

    METHOD PRIVATE CHARACTER ItemText(INPUT pdA AS DECIMAL):
        DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
        IF pdA = ? THEN RETURN "?".
        cText = STRING(pdA).
        IF LENGTH(cText) > 200 THEN cText = SUBSTRING(cText, 1, 200) + "...".
        RETURN cText.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Ordering (types that support < and >)                            */
    /* ---------------------------------------------------------------- */

    /* Sorts in place, ascending. Stable: equal values keep their order.
       Text sorts case-insensitively. Unknown values sort together at
       one end. On a view this reorders the shared storage. */
    METHOD PUBLIC DecSlice Sort():
        RETURN SortBy(FALSE).
    END METHOD.

    METHOD PUBLIC DecSlice SortDescending():
        RETURN SortBy(TRUE).
    END METHOD.

    /* Smallest known value; ? when there is none. */
    METHOD PUBLIC DECIMAL Min():
        DEFINE VARIABLE xBest AS DECIMAL  NO-UNDO INITIAL ?.
        DEFINE VARIABLE xItem AS DECIMAL  NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.

        DO i = 1 TO iLen:
            xItem = oStore:GetAt(iStart + i - 1).
            IF xItem = ? THEN NEXT.
            IF xBest = ? THEN xBest = xItem.
            ELSE IF xItem < xBest THEN xBest = xItem.
        END.
        RETURN xBest.
    END METHOD.

    /* Largest known value; ? when there is none. */
    METHOD PUBLIC DECIMAL Max():
        DEFINE VARIABLE xBest AS DECIMAL  NO-UNDO INITIAL ?.
        DEFINE VARIABLE xItem AS DECIMAL  NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.

        DO i = 1 TO iLen:
            xItem = oStore:GetAt(iStart + i - 1).
            IF xItem = ? THEN NEXT.
            IF xBest = ? THEN xBest = xItem.
            ELSE IF xItem > xBest THEN xBest = xItem.
        END.
        RETURN xBest.
    END METHOD.

    METHOD PRIVATE DecSlice SortBy(INPUT plDescending AS LOGICAL):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.

        EMPTY TEMP-TABLE ttSort.
        DO i = 1 TO iLen:
            CREATE ttSort.
            ASSIGN ttSort.SortValue = oStore:GetAt(iStart + i - 1)
                   ttSort.Seq       = i.
        END.

        i = 0.
        IF plDescending THEN
            FOR EACH ttSort BY ttSort.SortValue DESCENDING BY ttSort.Seq:
                i = i + 1.
                oStore:SetAt(iStart + i - 1, ttSort.SortValue).
            END.
        ELSE
            FOR EACH ttSort BY ttSort.SortValue BY ttSort.Seq:
                i = i + 1.
                oStore:SetAt(iStart + i - 1, ttSort.SortValue).
            END.

        EMPTY TEMP-TABLE ttSort.
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Arithmetic (numeric types)                                       */
    /* ---------------------------------------------------------------- */

    /* Total of the known values; unknown elements are skipped. */
    METHOD PUBLIC DECIMAL Sum():
        DEFINE VARIABLE xTotal AS DECIMAL  NO-UNDO INITIAL 0.
        DEFINE VARIABLE xItem  AS DECIMAL  NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.

        DO i = 1 TO iLen:
            xItem = oStore:GetAt(iStart + i - 1).
            IF xItem <> ? THEN xTotal = xTotal + xItem.
        END.
        RETURN xTotal.
    END METHOD.

    /* Mean of the known values; ? when there are none. */
    METHOD PUBLIC DECIMAL Average():
        DEFINE VARIABLE dTotal AS DECIMAL NO-UNDO.
        DEFINE VARIABLE iKnown AS INTEGER NO-UNDO.
        DEFINE VARIABLE xItem  AS DECIMAL  NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.

        DO i = 1 TO iLen:
            xItem = oStore:GetAt(iStart + i - 1).
            IF xItem = ? THEN NEXT.
            ASSIGN dTotal = dTotal + xItem
                   iKnown = iKnown + 1.
        END.
        IF iKnown = 0 THEN RETURN ?.
        RETURN dTotal / iKnown.
    END METHOD.


    /* ---------------------------------------------------------------- */
    /* Object overrides                                                 */
    /* ---------------------------------------------------------------- */

    /* Same type, same length, equal elements in the same order. */
    METHOD PUBLIC OVERRIDE LOGICAL Equals(INPUT poOther AS Progress.Lang.Object):
        DEFINE VARIABLE oSlice AS DecSlice NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER     NO-UNDO.

        IF NOT VALID-OBJECT(poOther) THEN RETURN FALSE.
        IF NOT TYPE-OF(poOther, DecSlice) THEN RETURN FALSE.
        oSlice = CAST(poOther, DecSlice).
        IF oSlice:Length <> iLen THEN RETURN FALSE.

        DO i = 1 TO iLen:
            IF NOT ItemEquals(oStore:GetAt(iStart + i - 1), oSlice:Get(i)) THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    /* [a, b, c] - at most 100 elements shown. */
    METHOD PUBLIC OVERRIDE CHARACTER ToString():
        DEFINE VARIABLE cOut AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.

        DO i = 1 TO MINIMUM(iLen, 100):
            cOut = cOut + (IF i > 1 THEN ", " ELSE "") + ItemText(oStore:GetAt(iStart + i - 1)).
        END.
        IF iLen > 100 THEN
            cOut = cOut + SUBSTITUTE(", ... (&1 more)", iLen - 100).
        RETURN "[" + cOut + "]".
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Internals                                                        */
    /* ---------------------------------------------------------------- */

    /* TRUE when this slice ends where the shared storage's data ends, so
       it may append in place. */
    METHOD PRIVATE LOGICAL OwnsTail():
        RETURN iStart + iLen - 1 = oStore:Used.
    END METHOD.

    METHOD PRIVATE VOID PrepareAppend(INPUT piExtra AS INTEGER):
        IF NOT OwnsTail() THEN
            Detach(iLen + piExtra).
        oStore:EnsureCapacity(iStart + iLen - 1 + piExtra).
    END METHOD.

    /* Move this slice onto its own storage. */
    METHOD PRIVATE VOID Detach(INPUT piMinCapacity AS INTEGER):
        DEFINE VARIABLE oNew AS DecStore NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER     NO-UNDO.

        oNew = NEW DecStore(MAXIMUM(piMinCapacity, iLen * 2, 8)).
        DO i = 1 TO iLen:
            oNew:SetAt(i, oStore:GetAt(iStart + i - 1)).
        END.
        oNew:Used = iLen.
        ASSIGN oStore = oNew
               iStart = 1.
    END METHOD.

    METHOD PRIVATE VOID CheckIndex(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 1 OR piIndex > iLen THEN
            UNDO, THROW NEW ArgumentError(SUBSTITUTE("Index &1 is out of range 1 to &2", piIndex, iLen), "piIndex").
    END METHOD.

    METHOD PRIVATE VOID RequireItems(INPUT pcOperation AS CHARACTER):
        IF iLen = 0 THEN
            UNDO, THROW NEW InvalidStateError(SUBSTITUTE("&1() called on an empty DecSlice", pcOperation)).
    END METHOD.

END CLASS.
