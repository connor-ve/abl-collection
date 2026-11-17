/*------------------------------------------------------------------------
    File        : abl/Testing/SkipSignal.cls
    Purpose     : Thrown by TestCase:SkipTest(). The runner reports the
                  test as SKIP with the given reason.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS abl.Testing.SkipSignal INHERITS Progress.Lang.AppError:

    CONSTRUCTOR PUBLIC SkipSignal(INPUT pcReason AS CHARACTER):
        SUPER(pcReason, 0).
    END CONSTRUCTOR.

END CLASS.
