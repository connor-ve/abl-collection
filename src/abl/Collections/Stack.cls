/*------------------------------------------------------------------------
    File        : abl/Collections/Stack.cls
    Purpose     : Last in, first out. Holds values of any type (boxed).

    Usage
        oStack = NEW Stack().
        oStack:Push("a"):Push(42).
        iTop  = oStack:Pop():AsInt64().      42
        cNext = oStack:Peek():AsCharacter(). "a", still on the stack
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.Object.
USING abl.Collections.ObjSlice.
USING abl.Core.Box.
USING abl.Errors.InvalidStateError.

CLASS abl.Collections.Stack:

    DEFINE PRIVATE VARIABLE oItems AS ObjSlice NO-UNDO.

    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET():
            RETURN oItems:Length.
        END GET.

    DEFINE PUBLIC PROPERTY IsEmpty AS LOGICAL NO-UNDO
        GET():
            RETURN oItems:Length = 0.
        END GET.

    CONSTRUCTOR PUBLIC Stack():
        oItems = NEW ObjSlice().
    END CONSTRUCTOR.

    METHOD PUBLIC Stack Push(INPUT pcValue AS CHARACTER):
        RETURN PushBox(NEW Box(pcValue)).
    END METHOD.

    METHOD PUBLIC Stack Push(INPUT plcValue AS LONGCHAR):
        RETURN PushBox(NEW Box(plcValue)).
    END METHOD.

    METHOD PUBLIC Stack Push(INPUT piValue AS INTEGER):
        RETURN PushBox(NEW Box(piValue)).
    END METHOD.

    METHOD PUBLIC Stack Push(INPUT piValue AS INT64):
        RETURN PushBox(NEW Box(piValue)).
    END METHOD.

    METHOD PUBLIC Stack Push(INPUT pdValue AS DECIMAL):
        RETURN PushBox(NEW Box(pdValue)).
    END METHOD.

    METHOD PUBLIC Stack Push(INPUT plValue AS LOGICAL):
        RETURN PushBox(NEW Box(plValue)).
    END METHOD.

    METHOD PUBLIC Stack Push(INPUT pdaValue AS DATE):
        RETURN PushBox(NEW Box(pdaValue)).
    END METHOD.

    METHOD PUBLIC Stack Push(INPUT pdtValue AS DATETIME):
        RETURN PushBox(NEW Box(pdtValue)).
    END METHOD.

    METHOD PUBLIC Stack Push(INPUT pdtzValue AS DATETIME-TZ):
        RETURN PushBox(NEW Box(pdtzValue)).
    END METHOD.

    METHOD PUBLIC Stack Push(INPUT phValue AS HANDLE):
        RETURN PushBox(NEW Box(phValue)).
    END METHOD.

    METHOD PUBLIC Stack Push(INPUT poValue AS Object):
        IF VALID-OBJECT(poValue) AND TYPE-OF(poValue, Box) THEN
            RETURN PushBox(CAST(poValue, Box)).
        RETURN PushBox(NEW Box(poValue)).
    END METHOD.

    /* Removes and returns the top value. */
    METHOD PUBLIC Box Pop():
        DEFINE VARIABLE oTop AS Box NO-UNDO.
        RequireItems("Pop").
        oTop = CAST(oItems:Last(), Box).
        oItems:RemoveAt(oItems:Length).
        RETURN oTop.
    END METHOD.

    /* Returns the top value without removing it. */
    METHOD PUBLIC Box Peek():
        RequireItems("Peek").
        RETURN CAST(oItems:Last(), Box).
    END METHOD.

    METHOD PUBLIC Stack Clear():
        oItems:Clear().
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */

    METHOD PRIVATE Stack PushBox(INPUT poValue AS Box):
        oItems:Append(poValue).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PRIVATE VOID RequireItems(INPUT pcOperation AS CHARACTER):
        IF oItems:Length = 0 THEN
            UNDO, THROW NEW InvalidStateError(SUBSTITUTE("&1() called on an empty Stack", pcOperation)).
    END METHOD.

END CLASS.
