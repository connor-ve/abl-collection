/*------------------------------------------------------------------------
    File        : abl/Errors/InvalidStateError.cls
    Purpose     : An object or process is in a state where the requested
                  operation makes no sense (reading a number from a box
                  that holds text, closing a file twice). Usually a bug.
                  Code "InvalidState", HTTP 500.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS abl.Errors.InvalidStateError INHERITS abl.Errors.AblError:

    CONSTRUCTOR PUBLIC InvalidStateError(INPUT pcMessage AS CHARACTER):
        SUPER("InvalidState", pcMessage, ?).
    END CONSTRUCTOR.

END CLASS.
