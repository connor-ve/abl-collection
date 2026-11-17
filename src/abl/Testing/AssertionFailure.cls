/*------------------------------------------------------------------------
    File        : abl/Testing/AssertionFailure.cls
    Purpose     : Thrown when an expectation does not hold. The runner
                  reports it as FAIL; any other error is reported as ERROR.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS abl.Testing.AssertionFailure INHERITS Progress.Lang.AppError:

    CONSTRUCTOR PUBLIC AssertionFailure(INPUT pcMessage AS CHARACTER):
        SUPER(pcMessage, 0).
    END CONSTRUCTOR.

END CLASS.
