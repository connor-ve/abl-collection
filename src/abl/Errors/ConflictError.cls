/*------------------------------------------------------------------------
    File        : abl/Errors/ConflictError.cls
    Purpose     : The request clashes with current state: duplicate key,
                  record changed by someone else, record locked.
                  Code "Conflict", HTTP 409.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS abl.Errors.ConflictError INHERITS abl.Errors.AblError:

    CONSTRUCTOR PUBLIC ConflictError(INPUT pcMessage AS CHARACTER):
        SUPER("Conflict", pcMessage, ?).
        HttpStatus = 409.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC ConflictError(INPUT pcMessage AS CHARACTER, INPUT poCause AS Progress.Lang.Error):
        SUPER("Conflict", pcMessage, poCause).
        HttpStatus = 409.
    END CONSTRUCTOR.

END CLASS.
