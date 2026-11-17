/*------------------------------------------------------------------------
    File        : abl/Collections/CharSet.cls
    GENERATED   : by tools/gen-collections.sh from tools/templates/Set.cls.tpl.
                  Edit the template and regenerate; edits here are lost.
    Purpose     : A set of unique CHARACTER values with fast lookup (an
                  indexed temp-table underneath).

    Usage
        oSeen = NEW CharSet().
        IF NOT oSeen:Contains(x) THEN oSeen:Add(x).
        oBoth = oA:Intersect(oB).
        oAll  = oA:Union(oB):ToSlice().     sorted ascending

    Notes       : - Unknown (?) cannot be added.
                  - CHARACTER values compare case-insensitively, as in
                    any ABL index: "abc" and "ABC" are the same element.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Collections.CharSlice.
USING abl.Errors.ArgumentError.

CLASS abl.Collections.CharSet:

    DEFINE PRIVATE TEMP-TABLE ttItem NO-UNDO
        FIELD ItemValue AS CHARACTER
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

    CONSTRUCTOR PUBLIC CharSet():
    END CONSTRUCTOR.

    METHOD PUBLIC STATIC CharSet Of(INPUT pcA AS CHARACTER):
        DEFINE VARIABLE oOut AS CharSet NO-UNDO.
        oOut = NEW CharSet().
        RETURN oOut:Add(pcA).
    END METHOD.

    METHOD PUBLIC STATIC CharSet Of(INPUT pcA AS CHARACTER, INPUT pcB AS CHARACTER):
        DEFINE VARIABLE oOut AS CharSet NO-UNDO.
        oOut = NEW CharSet().
        RETURN oOut:Add(pcA):Add(pcB).
    END METHOD.

    METHOD PUBLIC STATIC CharSet Of(INPUT pcA AS CHARACTER, INPUT pcB AS CHARACTER, INPUT pcC AS CHARACTER):
        DEFINE VARIABLE oOut AS CharSet NO-UNDO.
        oOut = NEW CharSet().
        RETURN oOut:Add(pcA):Add(pcB):Add(pcC).
    END METHOD.

    METHOD PUBLIC STATIC CharSet FromSlice(INPUT poValues AS CharSlice):
        DEFINE VARIABLE oOut AS CharSet NO-UNDO.
        oOut = NEW CharSet().
        RETURN oOut:AddSlice(poValues).
    END METHOD.

    /* ---------------------------------------------------------------- */

    /* Adding a value already present does nothing. */
    METHOD PUBLIC CharSet Add(INPUT pcValue AS CHARACTER):
        IF pcValue = ? THEN
            UNDO, THROW NEW ArgumentError("Cannot add unknown (?) to a set", "pcValue").

        IF NOT CAN-FIND(ttItem WHERE ttItem.ItemValue = pcValue) THEN DO:
            CREATE ttItem.
            ttItem.ItemValue = pcValue.
            iCount = iCount + 1.
        END.
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC CharSet AddSlice(INPUT poValues AS CharSlice):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poValues) THEN RETURN THIS-OBJECT.
        DO i = 1 TO poValues:Length:
            THIS-OBJECT:Add(poValues:Get(i)).
        END.
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC LOGICAL Contains(INPUT pcValue AS CHARACTER):
        IF pcValue = ? THEN RETURN FALSE.
        RETURN CAN-FIND(ttItem WHERE ttItem.ItemValue = pcValue).
    END METHOD.

    /* TRUE when the value was present. */
    METHOD PUBLIC LOGICAL Remove(INPUT pcValue AS CHARACTER):
        IF pcValue = ? THEN RETURN FALSE.
        FIND ttItem WHERE ttItem.ItemValue = pcValue NO-ERROR.
        IF NOT AVAILABLE ttItem THEN RETURN FALSE.
        DELETE ttItem.
        iCount = iCount - 1.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC CharSet Clear():
        EMPTY TEMP-TABLE ttItem.
        iCount = 0.
        RETURN THIS-OBJECT.
    END METHOD.

    /* Elements in ascending order. */
    METHOD PUBLIC CharSlice ToSlice():
        DEFINE VARIABLE oOut AS CharSlice NO-UNDO.
        oOut = NEW CharSlice(0, MAXIMUM(iCount, 8)).
        FOR EACH ttItem:
            oOut:Append(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    METHOD PUBLIC CharSet Copy():
        DEFINE VARIABLE oOut AS CharSet NO-UNDO.
        oOut = NEW CharSet().
        FOR EACH ttItem:
            oOut:Add(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Set algebra - each returns a new set                             */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC CharSet Union(INPUT poOther AS CharSet):
        DEFINE VARIABLE oOut AS CharSet NO-UNDO.
        oOut = THIS-OBJECT:Copy().
        IF VALID-OBJECT(poOther) THEN
            oOut:AddSlice(poOther:ToSlice()).
        RETURN oOut.
    END METHOD.

    METHOD PUBLIC CharSet Intersect(INPUT poOther AS CharSet):
        DEFINE VARIABLE oOut AS CharSet NO-UNDO.
        oOut = NEW CharSet().
        IF NOT VALID-OBJECT(poOther) THEN RETURN oOut.
        FOR EACH ttItem:
            IF poOther:Contains(ttItem.ItemValue) THEN
                oOut:Add(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    /* Elements of this set that are not in poOther. */
    METHOD PUBLIC CharSet Difference(INPUT poOther AS CharSet):
        DEFINE VARIABLE oOut AS CharSet NO-UNDO.
        IF NOT VALID-OBJECT(poOther) THEN RETURN THIS-OBJECT:Copy().
        oOut = NEW CharSet().
        FOR EACH ttItem:
            IF NOT poOther:Contains(ttItem.ItemValue) THEN
                oOut:Add(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    METHOD PUBLIC LOGICAL IsSubsetOf(INPUT poOther AS CharSet):
        IF NOT VALID-OBJECT(poOther) THEN RETURN iCount = 0.
        FOR EACH ttItem:
            IF NOT poOther:Contains(ttItem.ItemValue) THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    /* ---------------------------------------------------------------- */

    METHOD PUBLIC OVERRIDE LOGICAL Equals(INPUT poOther AS Progress.Lang.Object):
        DEFINE VARIABLE oSet AS CharSet NO-UNDO.
        IF NOT VALID-OBJECT(poOther) THEN RETURN FALSE.
        IF NOT TYPE-OF(poOther, CharSet) THEN RETURN FALSE.
        oSet = CAST(poOther, CharSet).
        RETURN oSet:Count = iCount AND THIS-OBJECT:IsSubsetOf(oSet).
    END METHOD.

    /* Set[a, b, c] */
    METHOD PUBLIC OVERRIDE CHARACTER ToString():
        RETURN "Set" + THIS-OBJECT:ToSlice():ToString().
    END METHOD.

END CLASS.
