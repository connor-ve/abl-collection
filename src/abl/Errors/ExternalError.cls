/*------------------------------------------------------------------------
    File        : abl/Errors/ExternalError.cls
    Purpose     : Something outside this process failed: a REST call, a
                  file share, another AppServer. Code "External", HTTP 502.
    Usage       : UNDO, THROW NEW ExternalError("TaxService", "Timed out after 30s", e).
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS abl.Errors.ExternalError INHERITS abl.Errors.AblError:

    DEFINE PUBLIC PROPERTY SystemName AS CHARACTER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC ExternalError(INPUT pcSystem AS CHARACTER, INPUT pcMessage AS CHARACTER):
        THIS-OBJECT(pcSystem, pcMessage, ?).
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC ExternalError(INPUT pcSystem  AS CHARACTER,
                                     INPUT pcMessage AS CHARACTER,
                                     INPUT poCause   AS Progress.Lang.Error):
        SUPER("External", SUBSTITUTE("&1: &2", pcSystem, pcMessage), poCause).
        ASSIGN SystemName = pcSystem
               HttpStatus = 502.
        AddContext("system", pcSystem).
    END CONSTRUCTOR.

END CLASS.
