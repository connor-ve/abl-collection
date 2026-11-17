/*------------------------------------------------------------------------
    File        : tests/abl/Collections/StackQueueTest.cls
    Purpose     : Tests for Stack and Queue.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Collections.Queue.
USING abl.Collections.Stack.
USING abl.Testing.TestCase.

CLASS abl.Collections.StackQueueTest INHERITS TestCase:

    /* ---------------------------------------------------------------- */
    /* Stack                                                            */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestStackIsLastInFirstOut():
        DEFINE VARIABLE oStack AS Stack NO-UNDO.
        oStack = NEW Stack().
        oStack:Push("a"):Push(2):Push(TRUE).

        Expect(oStack:Count):ToEqual(3).
        Expect(oStack:Peek()):ToEqual(TRUE).
        Expect(oStack:Pop()):ToEqual(TRUE).
        Expect(oStack:Pop()):ToEqual(2).
        Expect(oStack:Pop()):ToEqual("a").
        Expect(oStack:IsEmpty):ToBeTrue().
    END METHOD.

    METHOD PUBLIC VOID TestPopOnEmptyStackThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE oStack  AS Stack               NO-UNDO.
        oStack = NEW Stack().
        DO ON ERROR UNDO, LEAVE:
            oStack:Pop().
            CATCH e AS Progress.Lang.Error:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveErrorCode("InvalidState").
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Queue                                                            */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestQueueIsFirstInFirstOut():
        DEFINE VARIABLE oQueue AS Queue NO-UNDO.
        oQueue = NEW Queue().
        oQueue:Enqueue("first"):Enqueue("second").
        Expect(oQueue:Peek()):ToEqual("first").
        Expect(oQueue:Dequeue()):ToEqual("first").
        Expect(oQueue:Dequeue()):ToEqual("second").
        Expect(oQueue:IsEmpty):ToBeTrue().
    END METHOD.

    METHOD PUBLIC VOID TestQueueReusableAfterEmptying():
        DEFINE VARIABLE oQueue AS Queue NO-UNDO.
        oQueue = NEW Queue().
        oQueue:Enqueue(1).
        oQueue:Dequeue().
        oQueue:Enqueue(2):Enqueue(3).
        Expect(oQueue:Count):ToEqual(2).
        Expect(oQueue:Dequeue()):ToEqual(2).
    END METHOD.

    /* Enough traffic to trigger compaction, with values still queued. */
    METHOD PUBLIC VOID TestQueueKeepsOrderThroughCompaction():
        DEFINE VARIABLE oQueue AS Queue   NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE lInOrder AS LOGICAL NO-UNDO INITIAL TRUE.

        oQueue = NEW Queue().
        DO i = 1 TO 5000:
            oQueue:Enqueue(i).
        END.
        DO i = 1 TO 4000:
            IF oQueue:Dequeue():AsInt64() <> i THEN lInOrder = FALSE.
        END.
        DO i = 5001 TO 6000:
            oQueue:Enqueue(i).
        END.

        Expect(oQueue:Count):ToEqual(2000).
        DO i = 4001 TO 6000:
            IF oQueue:Dequeue():AsInt64() <> i THEN lInOrder = FALSE.
        END.
        Expect(lInOrder):ToBeTrue().
        Expect(oQueue:IsEmpty):ToBeTrue().
    END METHOD.

    METHOD PUBLIC VOID TestDequeueOnEmptyQueueThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE oQueue  AS Queue               NO-UNDO.
        oQueue = NEW Queue().
        DO ON ERROR UNDO, LEAVE:
            oQueue:Dequeue().
            CATCH e AS Progress.Lang.Error:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveErrorCode("InvalidState").
    END METHOD.

END CLASS.
