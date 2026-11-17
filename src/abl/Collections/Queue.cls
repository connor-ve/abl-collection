/*------------------------------------------------------------------------
    File        : abl/Collections/Queue.cls
    Purpose     : First in, first out. Holds values of any type (boxed).

    Usage
        oQueue = NEW Queue().
        oQueue:Enqueue("first"):Enqueue("second").
        DO WHILE NOT oQueue:IsEmpty:
            cJob = oQueue:Dequeue():AsCharacter().
        END.

    Notes       : Dequeue does not shift the remaining elements. The
                  queue moves a head position forward and compacts its
                  storage now and then, so each operation is cheap on
                  average.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.Object.
USING abl.Collections.ObjSlice.
USING abl.Core.Box.
USING abl.Errors.InvalidStateError.

CLASS abl.Collections.Queue:

    DEFINE PRIVATE VARIABLE oItems AS ObjSlice NO-UNDO.
    DEFINE PRIVATE VARIABLE iHead  AS INTEGER  NO-UNDO INITIAL 1.

    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET():
            RETURN oItems:Length - iHead + 1.
        END GET.

    DEFINE PUBLIC PROPERTY IsEmpty AS LOGICAL NO-UNDO
        GET():
            RETURN oItems:Length - iHead + 1 = 0.
        END GET.

    CONSTRUCTOR PUBLIC Queue():
        oItems = NEW ObjSlice().
    END CONSTRUCTOR.

    METHOD PUBLIC Queue Enqueue(INPUT pcValue AS CHARACTER):
        RETURN EnqueueBox(NEW Box(pcValue)).
    END METHOD.

    METHOD PUBLIC Queue Enqueue(INPUT plcValue AS LONGCHAR):
        RETURN EnqueueBox(NEW Box(plcValue)).
    END METHOD.

    METHOD PUBLIC Queue Enqueue(INPUT piValue AS INTEGER):
        RETURN EnqueueBox(NEW Box(piValue)).
    END METHOD.

    METHOD PUBLIC Queue Enqueue(INPUT piValue AS INT64):
        RETURN EnqueueBox(NEW Box(piValue)).
    END METHOD.

    METHOD PUBLIC Queue Enqueue(INPUT pdValue AS DECIMAL):
        RETURN EnqueueBox(NEW Box(pdValue)).
    END METHOD.

    METHOD PUBLIC Queue Enqueue(INPUT plValue AS LOGICAL):
        RETURN EnqueueBox(NEW Box(plValue)).
    END METHOD.

    METHOD PUBLIC Queue Enqueue(INPUT pdaValue AS DATE):
        RETURN EnqueueBox(NEW Box(pdaValue)).
    END METHOD.

    METHOD PUBLIC Queue Enqueue(INPUT pdtValue AS DATETIME):
        RETURN EnqueueBox(NEW Box(pdtValue)).
    END METHOD.

    METHOD PUBLIC Queue Enqueue(INPUT pdtzValue AS DATETIME-TZ):
        RETURN EnqueueBox(NEW Box(pdtzValue)).
    END METHOD.

    METHOD PUBLIC Queue Enqueue(INPUT phValue AS HANDLE):
        RETURN EnqueueBox(NEW Box(phValue)).
    END METHOD.

    METHOD PUBLIC Queue Enqueue(INPUT poValue AS Object):
        IF VALID-OBJECT(poValue) AND TYPE-OF(poValue, Box) THEN
            RETURN EnqueueBox(CAST(poValue, Box)).
        RETURN EnqueueBox(NEW Box(poValue)).
    END METHOD.

    /* Removes and returns the oldest value. */
    METHOD PUBLIC Box Dequeue():
        DEFINE VARIABLE oFront AS Box NO-UNDO.

        RequireItems("Dequeue").
        oFront = CAST(oItems:Get(iHead), Box).
        oItems:Set(iHead, ?).          /* release the reference */
        iHead = iHead + 1.

        IF iHead > oItems:Length THEN DO:
            /* Empty again: reuse storage from the start. */
            oItems:Clear().
            iHead = 1.
        END.
        ELSE IF iHead > 1024 AND iHead > oItems:Length / 2 THEN DO:
            /* Mostly consumed: copy the live part to fresh storage. */
            oItems = oItems:Sub(iHead, oItems:Length):Copy().
            iHead = 1.
        END.

        RETURN oFront.
    END METHOD.

    /* Returns the oldest value without removing it. */
    METHOD PUBLIC Box Peek():
        RequireItems("Peek").
        RETURN CAST(oItems:Get(iHead), Box).
    END METHOD.

    METHOD PUBLIC Queue Clear():
        oItems:Clear().
        iHead = 1.
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */

    METHOD PRIVATE Queue EnqueueBox(INPUT poValue AS Box):
        oItems:Append(poValue).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PRIVATE VOID RequireItems(INPUT pcOperation AS CHARACTER):
        IF oItems:Length - iHead + 1 <= 0 THEN
            UNDO, THROW NEW InvalidStateError(SUBSTITUTE("&1() called on an empty Queue", pcOperation)).
    END METHOD.

END CLASS.
