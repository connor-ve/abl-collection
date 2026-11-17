/*------------------------------------------------------------------------
    File        : abl/Collections/Internal/RefArray.cls
    Purpose     : Fixed-size array of object references, sized once at
                  construction. The stores use it as their chunk
                  directory. Not for direct use; use ObjSlice instead.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS abl.Collections.Internal.RefArray FINAL:

    DEFINE PRIVATE VARIABLE oItems AS Progress.Lang.Object EXTENT NO-UNDO.

    DEFINE PUBLIC PROPERTY Size AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC RefArray(INPUT piSize AS INTEGER):
        EXTENT(oItems) = piSize.
        Size = piSize.
    END CONSTRUCTOR.

    METHOD PUBLIC Progress.Lang.Object GetAt(INPUT piPos AS INTEGER):
        RETURN oItems[piPos].
    END METHOD.

    METHOD PUBLIC VOID SetAt(INPUT piPos AS INTEGER, INPUT poValue AS Progress.Lang.Object):
        oItems[piPos] = poValue.
    END METHOD.

END CLASS.
