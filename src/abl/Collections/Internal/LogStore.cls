/*------------------------------------------------------------------------
    File        : abl/Collections/Internal/LogStore.cls
    GENERATED   : by tools/gen-collections.sh from tools/templates/Store.cls.tpl.
                  Edit the template and regenerate; edits here are lost.
    Purpose     : Storage behind LogSlice. Not for direct use.

    Layout
        While capacity is at most 4096 there is one chunk, and growing
        copies it into a chunk twice the size (like Go). Past 4096 every
        chunk is exactly 4096 long and growing adds chunks without
        copying any elements. This also avoids the ABL limit of 28000
        elements per array.

    Positions are 1-based and run from 1 to Capacity. Bounds checks are
    the slice's job; this class assumes valid positions.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Collections.Internal.LogChunk.
USING abl.Collections.Internal.RefArray.

CLASS abl.Collections.Internal.LogStore FINAL:

    DEFINE PRIVATE VARIABLE oFirst  AS LogChunk NO-UNDO.   /* the only chunk while iChunks = 1 */
    DEFINE PRIVATE VARIABLE oDir    AS RefArray    NO-UNDO.   /* all chunks once iChunks > 1 */
    DEFINE PRIVATE VARIABLE iChunks AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE iBlock  AS INTEGER     NO-UNDO INITIAL 4096.

    DEFINE PUBLIC PROPERTY Capacity AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Highest position holding data, across every slice sharing this
       storage. A slice may append in place only when it ends here. */
    DEFINE PUBLIC PROPERTY Used AS INTEGER NO-UNDO
        GET.
        SET.

    CONSTRUCTOR PUBLIC LogStore(INPUT piCapacity AS INTEGER):
        DEFINE VARIABLE iFirst AS INTEGER NO-UNDO.

        iFirst = MINIMUM(MAXIMUM(piCapacity, 4), iBlock).
        oFirst = NEW LogChunk(iFirst).
        ASSIGN iChunks  = 1
               Capacity = iFirst.

        EnsureCapacity(piCapacity).
    END CONSTRUCTOR.

    METHOD PUBLIC LOGICAL GetAt(INPUT piPos AS INTEGER):
        DEFINE VARIABLE oChunk AS LogChunk NO-UNDO.

        IF iChunks = 1 THEN
            RETURN oFirst:Items[piPos].

        oChunk = CAST(oDir:GetAt(INTEGER(TRUNCATE((piPos - 1) / iBlock, 0)) + 1), LogChunk).
        RETURN oChunk:Items[(piPos - 1) MOD iBlock + 1].
    END METHOD.

    METHOD PUBLIC VOID SetAt(INPUT piPos AS INTEGER, INPUT plValue AS LOGICAL):
        DEFINE VARIABLE oChunk AS LogChunk NO-UNDO.

        IF iChunks = 1 THEN DO:
            oFirst:Items[piPos] = plValue.
            RETURN.
        END.

        oChunk = CAST(oDir:GetAt(INTEGER(TRUNCATE((piPos - 1) / iBlock, 0)) + 1), LogChunk).
        oChunk:Items[(piPos - 1) MOD iBlock + 1] = plValue.
    END METHOD.

    METHOD PUBLIC VOID EnsureCapacity(INPUT piNeeded AS INTEGER):
        DEFINE VARIABLE oBigger AS LogChunk NO-UNDO.
        DEFINE VARIABLE iNew    AS INTEGER     NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER     NO-UNDO.

        IF piNeeded <= Capacity THEN RETURN.

        /* Phase 1: one chunk smaller than a block - double it by copying. */
        IF iChunks = 1 AND Capacity < iBlock THEN DO:
            iNew = MINIMUM(MAXIMUM(Capacity * 2, piNeeded), iBlock).
            oBigger = NEW LogChunk(iNew).
            DO i = 1 TO Capacity:
                oBigger:Items[i] = oFirst:Items[i].
            END.
            ASSIGN oFirst   = oBigger
                   Capacity = iNew.
            IF piNeeded <= Capacity THEN RETURN.
        END.

        /* Phase 2: full-size blocks, added without copying elements. */
        IF iChunks = 1 THEN DO:
            oDir = NEW RefArray(8).
            oDir:SetAt(1, oFirst).
        END.

        DO WHILE Capacity < piNeeded:
            IF iChunks = oDir:Size THEN GrowDirectory().
            iChunks = iChunks + 1.
            oDir:SetAt(iChunks, NEW LogChunk(iBlock)).
            Capacity = Capacity + iBlock.
        END.
    END METHOD.

    METHOD PRIVATE VOID GrowDirectory():
        DEFINE VARIABLE oNew AS RefArray NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER  NO-UNDO.

        oNew = NEW RefArray(oDir:Size * 2).
        DO i = 1 TO oDir:Size:
            oNew:SetAt(i, oDir:GetAt(i)).
        END.
        oDir = oNew.
    END METHOD.

END CLASS.
