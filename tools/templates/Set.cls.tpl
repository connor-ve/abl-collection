/*------------------------------------------------------------------------
    File        : abl/Collections/@NAME@Set.cls
    GENERATED   : by tools/gen-collections.sh from tools/templates/Set.cls.tpl.
                  Edit the template and regenerate; edits here are lost.
    Purpose     : A set of unique @TYPE@ values with fast lookup (an
                  indexed temp-table underneath).

    Usage
        oSeen = NEW @NAME@Set().
        IF NOT oSeen:Contains(x) THEN oSeen:Add(x).
        oBoth = oA:Intersect(oB).
        oAll  = oA:Union(oB):ToSlice().     sorted ascending

    Notes       : - Unknown (?) cannot be added.
                  - CHARACTER values compare case-insensitively, as in
                    any ABL index: "abc" and "ABC" are the same element.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Collections.@NAME@Slice.
USING abl.Errors.ArgumentError.

CLASS abl.Collections.@NAME@Set:

    DEFINE PRIVATE TEMP-TABLE ttItem NO-UNDO
        FIELD ItemValue AS @TYPE@
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

    CONSTRUCTOR PUBLIC @NAME@Set():
    END CONSTRUCTOR.

    METHOD PUBLIC STATIC @NAME@Set Of(INPUT @P@A AS @TYPE@):
        DEFINE VARIABLE oOut AS @NAME@Set NO-UNDO.
        oOut = NEW @NAME@Set().
        RETURN oOut:Add(@P@A).
    END METHOD.

    METHOD PUBLIC STATIC @NAME@Set Of(INPUT @P@A AS @TYPE@, INPUT @P@B AS @TYPE@):
        DEFINE VARIABLE oOut AS @NAME@Set NO-UNDO.
        oOut = NEW @NAME@Set().
        RETURN oOut:Add(@P@A):Add(@P@B).
    END METHOD.

    METHOD PUBLIC STATIC @NAME@Set Of(INPUT @P@A AS @TYPE@, INPUT @P@B AS @TYPE@, INPUT @P@C AS @TYPE@):
        DEFINE VARIABLE oOut AS @NAME@Set NO-UNDO.
        oOut = NEW @NAME@Set().
        RETURN oOut:Add(@P@A):Add(@P@B):Add(@P@C).
    END METHOD.

    METHOD PUBLIC STATIC @NAME@Set FromSlice(INPUT poValues AS @NAME@Slice):
        DEFINE VARIABLE oOut AS @NAME@Set NO-UNDO.
        oOut = NEW @NAME@Set().
        RETURN oOut:AddSlice(poValues).
    END METHOD.

    /* ---------------------------------------------------------------- */

    /* Adding a value already present does nothing. */
    METHOD PUBLIC @NAME@Set Add(INPUT @P@Value AS @TYPE@):
        IF @P@Value = ? THEN
            UNDO, THROW NEW ArgumentError("Cannot add unknown (?) to a set", "@P@Value").

        IF NOT CAN-FIND(ttItem WHERE ttItem.ItemValue = @P@Value) THEN DO:
            CREATE ttItem.
            ttItem.ItemValue = @P@Value.
            iCount = iCount + 1.
        END.
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC @NAME@Set AddSlice(INPUT poValues AS @NAME@Slice):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poValues) THEN RETURN THIS-OBJECT.
        DO i = 1 TO poValues:Length:
            THIS-OBJECT:Add(poValues:Get(i)).
        END.
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC LOGICAL Contains(INPUT @P@Value AS @TYPE@):
        IF @P@Value = ? THEN RETURN FALSE.
        RETURN CAN-FIND(ttItem WHERE ttItem.ItemValue = @P@Value).
    END METHOD.

    /* TRUE when the value was present. */
    METHOD PUBLIC LOGICAL Remove(INPUT @P@Value AS @TYPE@):
        IF @P@Value = ? THEN RETURN FALSE.
        FIND ttItem WHERE ttItem.ItemValue = @P@Value NO-ERROR.
        IF NOT AVAILABLE ttItem THEN RETURN FALSE.
        DELETE ttItem.
        iCount = iCount - 1.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC @NAME@Set Clear():
        EMPTY TEMP-TABLE ttItem.
        iCount = 0.
        RETURN THIS-OBJECT.
    END METHOD.

    /* Elements in ascending order. */
    METHOD PUBLIC @NAME@Slice ToSlice():
        DEFINE VARIABLE oOut AS @NAME@Slice NO-UNDO.
        oOut = NEW @NAME@Slice(0, MAXIMUM(iCount, 8)).
        FOR EACH ttItem:
            oOut:Append(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    METHOD PUBLIC @NAME@Set Copy():
        DEFINE VARIABLE oOut AS @NAME@Set NO-UNDO.
        oOut = NEW @NAME@Set().
        FOR EACH ttItem:
            oOut:Add(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Set algebra - each returns a new set                             */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC @NAME@Set Union(INPUT poOther AS @NAME@Set):
        DEFINE VARIABLE oOut AS @NAME@Set NO-UNDO.
        oOut = THIS-OBJECT:Copy().
        IF VALID-OBJECT(poOther) THEN
            oOut:AddSlice(poOther:ToSlice()).
        RETURN oOut.
    END METHOD.

    METHOD PUBLIC @NAME@Set Intersect(INPUT poOther AS @NAME@Set):
        DEFINE VARIABLE oOut AS @NAME@Set NO-UNDO.
        oOut = NEW @NAME@Set().
        IF NOT VALID-OBJECT(poOther) THEN RETURN oOut.
        FOR EACH ttItem:
            IF poOther:Contains(ttItem.ItemValue) THEN
                oOut:Add(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    /* Elements of this set that are not in poOther. */
    METHOD PUBLIC @NAME@Set Difference(INPUT poOther AS @NAME@Set):
        DEFINE VARIABLE oOut AS @NAME@Set NO-UNDO.
        IF NOT VALID-OBJECT(poOther) THEN RETURN THIS-OBJECT:Copy().
        oOut = NEW @NAME@Set().
        FOR EACH ttItem:
            IF NOT poOther:Contains(ttItem.ItemValue) THEN
                oOut:Add(ttItem.ItemValue).
        END.
        RETURN oOut.
    END METHOD.

    METHOD PUBLIC LOGICAL IsSubsetOf(INPUT poOther AS @NAME@Set):
        IF NOT VALID-OBJECT(poOther) THEN RETURN iCount = 0.
        FOR EACH ttItem:
            IF NOT poOther:Contains(ttItem.ItemValue) THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    /* ---------------------------------------------------------------- */

    METHOD PUBLIC OVERRIDE LOGICAL Equals(INPUT poOther AS Progress.Lang.Object):
        DEFINE VARIABLE oSet AS @NAME@Set NO-UNDO.
        IF NOT VALID-OBJECT(poOther) THEN RETURN FALSE.
        IF NOT TYPE-OF(poOther, @NAME@Set) THEN RETURN FALSE.
        oSet = CAST(poOther, @NAME@Set).
        RETURN oSet:Count = iCount AND THIS-OBJECT:IsSubsetOf(oSet).
    END METHOD.

    /* Set[a, b, c] */
    METHOD PUBLIC OVERRIDE CHARACTER ToString():
        RETURN "Set" + THIS-OBJECT:ToSlice():ToString().
    END METHOD.

END CLASS.
