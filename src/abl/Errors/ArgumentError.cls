/*------------------------------------------------------------------------
    File        : abl/Errors/ArgumentError.cls
    Purpose     : A caller passed a bad value. Code "Argument", HTTP 400.
    Usage       : UNDO, THROW NEW ArgumentError("custNum must be positive", "custNum").
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS abl.Errors.ArgumentError INHERITS abl.Errors.AblError:

    DEFINE PUBLIC PROPERTY ParamName AS CHARACTER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC ArgumentError(INPUT pcMessage AS CHARACTER):
        THIS-OBJECT(pcMessage, "").
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC ArgumentError(INPUT pcMessage AS CHARACTER, INPUT pcParamName AS CHARACTER):
        SUPER("Argument", pcMessage, ?).
        ASSIGN ParamName  = pcParamName
               HttpStatus = 400.
        IF pcParamName > "" THEN
            AddContext("param", pcParamName).
    END CONSTRUCTOR.

END CLASS.
