/*------------------------------------------------------------------------
    File        : abl/Errors/AblError.cls
    Purpose     : Base error for the library and for application code.
                  Adds three things AppError lacks:
                    Code       - a stable, machine-readable name
                                 ("NotFound", "Validation", ...)
                    Cause      - the error this one wraps, so a chain of
                                 context is kept instead of lost
                    Context    - a JsonObject of extra data (ids, values)
                  plus HttpStatus, which the PASOE layer will use to turn
                  errors into responses.
    Usage       : UNDO, THROW NEW AblError("Billing", "Invoice total is negative").
                  UNDO, THROW Err:Wrap(e, "Loading customer 42").
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.AppError.
USING Progress.Json.ObjectModel.JsonObject.

CLASS abl.Errors.AblError INHERITS AppError:

    DEFINE PUBLIC PROPERTY Code AS CHARACTER NO-UNDO
        GET.
        PROTECTED SET.

    DEFINE PUBLIC PROPERTY Cause AS Progress.Lang.Error NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY HttpStatus AS INTEGER NO-UNDO INITIAL 500
        GET.
        PROTECTED SET.

    DEFINE PRIVATE VARIABLE oContext AS JsonObject NO-UNDO.

    /* Created on first use. */
    DEFINE PUBLIC PROPERTY Context AS JsonObject NO-UNDO
        GET():
            IF NOT VALID-OBJECT(oContext) THEN
                oContext = NEW JsonObject().
            RETURN oContext.
        END GET.

    CONSTRUCTOR PUBLIC AblError(INPUT pcMessage AS CHARACTER):
        THIS-OBJECT("Error", pcMessage, ?).
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC AblError(INPUT pcCode AS CHARACTER, INPUT pcMessage AS CHARACTER):
        THIS-OBJECT(pcCode, pcMessage, ?).
    END CONSTRUCTOR.

    /* When the cause is also a AblError its HttpStatus carries over, so
       wrapping a NotFoundError still produces a 404. */
    CONSTRUCTOR PUBLIC AblError(INPUT pcCode    AS CHARACTER,
                                 INPUT pcMessage AS CHARACTER,
                                 INPUT poCause   AS Progress.Lang.Error):
        SUPER(pcMessage, 0).

        ASSIGN THIS-OBJECT:Code = (IF pcCode = ? OR pcCode = "" THEN "Error" ELSE pcCode)
               THIS-OBJECT:Cause = poCause.

        IF VALID-OBJECT(poCause) AND TYPE-OF(poCause, AblError) THEN
            HttpStatus = CAST(poCause, AblError):HttpStatus.
    END CONSTRUCTOR.

    METHOD PUBLIC LOGICAL HasContext():
        RETURN VALID-OBJECT(oContext).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* AddContext: attach a named value. Returns the error so calls can  */
    /* be chained:  oErr:AddContext("custNum", 42):AddContext("db", "x") */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC AblError AddContext(INPUT pcName AS CHARACTER, INPUT pcValue AS CHARACTER):
        IF Context:Has(pcName) THEN Context:Set(pcName, pcValue).
        ELSE Context:Add(pcName, pcValue).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC AblError AddContext(INPUT pcName AS CHARACTER, INPUT piValue AS INTEGER):
        IF Context:Has(pcName) THEN Context:Set(pcName, piValue).
        ELSE Context:Add(pcName, piValue).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC AblError AddContext(INPUT pcName AS CHARACTER, INPUT piValue AS INT64):
        IF Context:Has(pcName) THEN Context:Set(pcName, piValue).
        ELSE Context:Add(pcName, piValue).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC AblError AddContext(INPUT pcName AS CHARACTER, INPUT pdValue AS DECIMAL):
        IF Context:Has(pcName) THEN Context:Set(pcName, pdValue).
        ELSE Context:Add(pcName, pdValue).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC AblError AddContext(INPUT pcName AS CHARACTER, INPUT plValue AS LOGICAL):
        IF Context:Has(pcName) THEN Context:Set(pcName, plValue).
        ELSE Context:Add(pcName, plValue).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC AblError AddContext(INPUT pcName AS CHARACTER, INPUT pdaValue AS DATE):
        IF Context:Has(pcName) THEN Context:Set(pcName, pdaValue).
        ELSE Context:Add(pcName, pdaValue).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC AblError AddContext(INPUT pcName AS CHARACTER, INPUT pdtValue AS DATETIME):
        IF Context:Has(pcName) THEN Context:Set(pcName, pdtValue).
        ELSE Context:Add(pcName, pdtValue).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC AblError AddContext(INPUT pcName AS CHARACTER, INPUT pdtzValue AS DATETIME-TZ):
        IF Context:Has(pcName) THEN Context:Set(pcName, pdtzValue).
        ELSE Context:Add(pcName, pdtzValue).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC OVERRIDE CHARACTER ToString():
        RETURN SUBSTITUTE("&1 [&2]: &3", THIS-OBJECT:GetClass():TypeName, Code, THIS-OBJECT:GetMessage(1)).
    END METHOD.

END CLASS.
