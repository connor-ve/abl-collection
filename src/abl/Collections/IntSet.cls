/*------------------------------------------------------------------------
    File        : abl/Collections/IntSet.cls
    GENERATED   : by tools/gen-collections.sh from tools/templates/Set.cls.tpl.
                  Edit the template and regenerate; edits here are lost.
    Purpose     : A set of unique INT64 values with fast lookup (an
                  indexed temp-table underneath).

    Usage
        oSeen = NEW IntSet().
        IF NOT oSeen:Contains(x) THEN oSeen:Add(x).
        oBoth = oA:Intersect(oB).
        oAll  = oA:Union(oB):ToSlice().     sorted ascending

    Notes       : - Unknown (?) cannot be added.
                  - CHARACTER values compare case-insensitively, as in
                    any ABL index: "abc" and "ABC" are the same element.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Collections.IntSlice.
USING abl.Errors.ArgumentError.

CLASS abl.Collections.IntSet:

    DEFINE PRIVATE TEMP-TABLE ttItem NO-UNDO
        FIELD ItemValue AS INT64
        INDEX ixValue IS PRIMARY UNIQUE ItemValue.

    DEFINE PRIVATE VARIABLE iCount AS INTEGER NO-UNDO.

    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET():
            RETURN iCount.
        END GET.

    DEFINE PUBLIC PROPERTY IsEmpty AS LOGICAL NO-UNDO
        GET():
            RETURN iCount = 0.
        END GET.

    CONSTRUCTOR PUBLIC IntSet():
    END CONSTRUCTOR.

    METHOD PUBLIC STATIC IntSet Of(INPUT piA AS INT64):
        DEFINE VARIABLE oOut AS IntSet NO-UNDO.
        oOut = NEW IntSet().
        RETURN oOut:Add(piA).
    END METHOD.

    METHOD PUBLIC STATIC IntSet Of(INPUT piA AS INT64, INPUT piB AS INT64):
        DEFINE VARIABLE oOut AS IntSet NO-UNDO.
        oOut = NEW IntSet().
        RETURN oOut:Add(piA):Add(piB).
    END METHOD.

    METHOD PUBLIC STATIC IntSet Of(INPUT piA AS INT64, INPUT piB AS INT64, INPUT piC AS INT64):
        DEFINE VARIABLE oOut AS IntSet NO-UNDO.
        oOut = NEW IntSet().
        RETURN oOut:Add(piA):Add(piB):Add(piC).
    END METHOD.

    METHOD PUBLIC STATIC IntSet FromSlice(INPUT poValues AS IntSlice):
        DEFINE VARIABLE oOut AS IntSet NO-UNDO.
        oOut = NEW IntSet().
        RETURN oOut:AddSlice(poValues).
    END METHOD.

    /* ---------------------------------------------------------------- */

    /* Adding a value already present does nothing. */
    METHOD PUBLIC IntSet Add(INPUT piValue AS INT64):
        IF piValue = ? THEN
            UNDO, THROW NEW ArgumentError("Cannot add unknown (?) to a set", "piValue").

        IF NOT CAN-FIND(ttItem WHERE ttItem.ItemValue = piValue) THEN DO:
            CREATE ttItem.
            ttItem.ItemValue = piValue.
            iCount = iCount + 1.
        END.
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC IntSet AddSlice(INPUT poValues AS IntSlice):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poValues) THEN RETURN THIS-OBJECT.
        DO i = 1 TO poValues:Length:
            THIS-OBJECT:Add(poValues:Get(i)).
        END.
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC LOGICAL Contains(INPUT piValue AS INT64):
        IF piValue = ? THEN RETURN FALSE.
        RETURN CAN-FIND(ttItem WHERE ttItem.ItemValue = piValue).
    END METHOD.

    /* TRUE when the value was present. */
    METHOD PUBLIC LOGICAL Remove(INPUT piValue AS INT64):
        IF piValue = ? THEN RETURN FALSE.
        FIND ttItem WHERE ttItem.ItemValue = piValue NO-ERROR.
        IF NOT AVAILABLE ttItem THEN RETURN FALSE.
        DELETE ttItem.
        iCount = iCount - 1.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC IntSet Clear():
        EMPTY TEMP-TABLE ttItem.
        iCount = 0.
        RETURN THIS-OBJECT.
    END METHOD.

    /* Elements in ascending order. */
    METHOD PUBLIC IntSlice ToSlice():
        DEFINE VARIABLE oOut AS IntSlice NO-UNDO.
        oOut = NEW IntSlice(0, MAXIMUM(iCount, 8)).
        FOR EACH ttItem:
            oOut:Append(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    METHOD PUBLIC IntSet Copy():
        DEFINE VARIABLE oOut AS IntSet NO-UNDO.
        oOut = NEW IntSet().
        FOR EACH ttItem:
            oOut:Add(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Set algebra - each returns a new set                             */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC IntSet Union(INPUT poOther AS IntSet):
        DEFINE VARIABLE oOut AS IntSet NO-UNDO.
        oOut = THIS-OBJECT:Copy().
        IF VALID-OBJECT(poOther) THEN
            oOut:AddSlice(poOther:ToSlice()).
        RETURN oOut.
    END METHOD.

    METHOD PUBLIC IntSet Intersect(INPUT poOther AS IntSet):
        DEFINE VARIABLE oOut AS IntSet NO-UNDO.
        oOut = NEW IntSet().
        IF NOT VALID-OBJECT(poOther) THEN RETURN oOut.
        FOR EACH ttItem:
            IF poOther:Contains(ttItem.ItemValue) THEN
                oOut:Add(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    /* Elements of this set that are not in poOther. */
    METHOD PUBLIC IntSet Difference(INPUT poOther AS IntSet):
        DEFINE VARIABLE oOut AS IntSet NO-UNDO.
        IF NOT VALID-OBJECT(poOther) THEN RETURN THIS-OBJECT:Copy().
        oOut = NEW IntSet().
        FOR EACH ttItem:
            IF NOT poOther:Contains(ttItem.ItemValue) THEN
                oOut:Add(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    METHOD PUBLIC LOGICAL IsSubsetOf(INPUT poOther AS IntSet):
        IF NOT VALID-OBJECT(poOther) THEN RETURN iCount = 0.
        FOR EACH ttItem:
            IF NOT poOther:Contains(ttItem.ItemValue) THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    /* ---------------------------------------------------------------- */

    METHOD PUBLIC OVERRIDE LOGICAL Equals(INPUT poOther AS Progress.Lang.Object):
        DEFINE VARIABLE oSet AS IntSet NO-UNDO.
        IF NOT VALID-OBJECT(poOther) THEN RETURN FALSE.
        IF NOT TYPE-OF(poOther, IntSet) THEN RETURN FALSE.
        oSet = CAST(poOther, IntSet).
        RETURN oSet:Count = iCount AND THIS-OBJECT:IsSubsetOf(oSet).
    END METHOD.

    /* Set[a, b, c] */
    METHOD PUBLIC OVERRIDE CHARACTER ToString():
        RETURN "Set" + THIS-OBJECT:ToSlice():ToString().
    END METHOD.

END CLASS.
