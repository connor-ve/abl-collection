/*------------------------------------------------------------------------
    File        : abl/Errors/NotFoundError.cls
    Purpose     : A requested record or resource does not exist.
                  Code "NotFound", HTTP 404.
    Usage       : UNDO, THROW NEW NotFoundError("Customer", STRING(piCustNum)).
                  -> message "Customer '42' not found"
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS abl.Errors.NotFoundError INHERITS abl.Errors.AblError:

    CONSTRUCTOR PUBLIC NotFoundError(INPUT pcMessage AS CHARACTER):
        SUPER("NotFound", pcMessage, ?).
        HttpStatus = 404.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC NotFoundError(INPUT pcEntity AS CHARACTER, INPUT pcKey AS CHARACTER):
        SUPER("NotFound", SUBSTITUTE("&1 '&2' not found", pcEntity, pcKey), ?).
        HttpStatus = 404.
        AddContext("entity", pcEntity).
        AddContext("key", pcKey).
    END CONSTRUCTOR.

END CLASS.
