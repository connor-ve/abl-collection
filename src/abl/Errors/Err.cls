/*------------------------------------------------------------------------
    File        : abl/Errors/Err.cls
    Purpose     : Static helpers for working with any Progress.Lang.Error,
                  not only AblError: wrapping with context, walking the
                  cause chain, full descriptions for logs, JSON for API
                  responses, and turning NO-ERROR status into a throw.
    Usage       :
        CATCH e AS Progress.Lang.Error:
            UNDO, THROW Err:Wrap(e, "Posting invoice " + STRING(piInvoice)).
        END CATCH.

        IF Err:Is(e, "NotFound") THEN ...
        oLog:Error(Err:Describe(e)).

        ASSIGN iQty = INTEGER(cInput) NO-ERROR.
        Err:ThrowIfStatus("Parsing quantity").
    Notes       : Call stacks only appear when the session runs with the
                  -errorstack startup parameter.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Json.ObjectModel.JsonObject.
USING abl.Errors.AblError.

CLASS abl.Errors.Err FINAL:

    CONSTRUCTOR PRIVATE Err():
    END CONSTRUCTOR.

    /* New AblError with pcMessage, keeping poCause underneath. The code
       and HTTP status of a AblError cause carry over. */
    METHOD PUBLIC STATIC AblError Wrap(INPUT poCause AS Progress.Lang.Error, INPUT pcMessage AS CHARACTER):
        DEFINE VARIABLE cCode AS CHARACTER NO-UNDO INITIAL "Error".

        IF VALID-OBJECT(poCause) AND TYPE-OF(poCause, AblError) THEN
            cCode = CAST(poCause, AblError):Code.

        RETURN NEW AblError(cCode, pcMessage, poCause).
    END METHOD.

    /* TRUE when any AblError in the chain has this Code. */
    METHOD PUBLIC STATIC LOGICAL Is(INPUT poErr AS Progress.Lang.Error, INPUT pcCode AS CHARACTER):
        DEFINE VARIABLE oCur   AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE iDepth AS INTEGER             NO-UNDO.

        oCur = poErr.
        DO WHILE VALID-OBJECT(oCur) AND iDepth < 50:
            /* Nested IF: do not rely on AND short-circuiting before the CAST. */
            IF TYPE-OF(oCur, AblError) THEN
                IF CAST(oCur, AblError):Code = pcCode THEN
                    RETURN TRUE.
            ASSIGN oCur   = NextCause(oCur)
                   iDepth = iDepth + 1.
        END.

        RETURN FALSE.
    END METHOD.

    /* First error in the chain that is, or inherits from, pcTypeName.
       Returns ? when none is. Equivalent of Go's errors.As. */
    METHOD PUBLIC STATIC Progress.Lang.Error Find(INPUT poErr AS Progress.Lang.Error, INPUT pcTypeName AS CHARACTER):
        DEFINE VARIABLE oCur   AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE iDepth AS INTEGER             NO-UNDO.

        oCur = poErr.
        DO WHILE VALID-OBJECT(oCur) AND iDepth < 50:
            IF CAST(oCur, Progress.Lang.Object):GetClass():IsA(pcTypeName) THEN
                RETURN oCur.
            ASSIGN oCur   = NextCause(oCur)
                   iDepth = iDepth + 1.
        END.

        RETURN ?.
    END METHOD.

    METHOD PUBLIC STATIC LOGICAL IsType(INPUT poErr AS Progress.Lang.Error, INPUT pcTypeName AS CHARACTER):
        RETURN VALID-OBJECT(Err:Find(poErr, pcTypeName)).
    END METHOD.

    /* The innermost error: the original failure. */
    METHOD PUBLIC STATIC Progress.Lang.Error Root(INPUT poErr AS Progress.Lang.Error):
        DEFINE VARIABLE oCur   AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE oNext  AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE iDepth AS INTEGER             NO-UNDO.

        oCur = poErr.
        DO WHILE VALID-OBJECT(oCur) AND iDepth < 50:
            oNext = NextCause(oCur).
            IF NOT VALID-OBJECT(oNext) THEN LEAVE.
            ASSIGN oCur   = oNext
                   iDepth = iDepth + 1.
        END.

        RETURN oCur.
    END METHOD.

    /* All messages of one error (not its causes), joined with "; ". */
    METHOD PUBLIC STATIC CHARACTER Messages(INPUT poErr AS Progress.Lang.Error):
        DEFINE VARIABLE cOut AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.

        IF NOT VALID-OBJECT(poErr) THEN RETURN "".

        DO i = 1 TO poErr:NumMessages:
            cOut = cOut + (IF cOut = "" THEN "" ELSE "; ") + poErr:GetMessage(i).
        END.

        /* RETURN ERROR "text" produces an AppError with only ReturnValue. */
        IF cOut = "" AND TYPE-OF(poErr, Progress.Lang.AppError) THEN
            cOut = CAST(poErr, Progress.Lang.AppError):ReturnValue.

        IF cOut = ? THEN cOut = "".
        RETURN cOut.
    END METHOD.

    /* Multi-line description of the whole chain, for logs:
         abl.Errors.AblError [NotFound]: Loading order 7
             at ...
         Caused by: abl.Errors.NotFoundError [NotFound]: Customer '42' not found  */
    METHOD PUBLIC STATIC LONGCHAR Describe(INPUT poErr AS Progress.Lang.Error):
        DEFINE VARIABLE lcOut  AS LONGCHAR            NO-UNDO.
        DEFINE VARIABLE cLine  AS CHARACTER           NO-UNDO.
        DEFINE VARIABLE cStack AS CHARACTER           NO-UNDO.
        DEFINE VARIABLE oCur   AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE iDepth AS INTEGER             NO-UNDO.

        lcOut = "".
        oCur  = poErr.

        DO WHILE VALID-OBJECT(oCur) AND iDepth < 50:
            cLine = (IF iDepth = 0 THEN "" ELSE "Caused by: ") + TypeNameOf(oCur).
            IF TYPE-OF(oCur, AblError) THEN
                cLine = cLine + " [" + CAST(oCur, AblError):Code + "]".
            cLine = cLine + ": " + Messages(oCur).
            lcOut = lcOut + cLine + "~n".

            cStack = oCur:CallStack.
            IF cStack <> ? AND cStack <> "" THEN
                lcOut = lcOut + "    at " + REPLACE(TRIM(cStack), "~n", "~n    at ") + "~n".

            ASSIGN oCur   = NextCause(oCur)
                   iDepth = iDepth + 1.
        END.

        RETURN lcOut.
    END METHOD.

    /* JSON object with properties type, code, httpStatus, message,
       context and cause - the shape the PASOE layer will send back to
       clients. (No curly braces in comments: the preprocessor may read
       them as include references.) */
    METHOD PUBLIC STATIC JsonObject ToJson(INPUT poErr AS Progress.Lang.Error):
        DEFINE VARIABLE oJson AS JsonObject NO-UNDO.
        DEFINE VARIABLE oAbl AS AblError  NO-UNDO.

        IF NOT VALID-OBJECT(poErr) THEN RETURN ?.

        oJson = NEW JsonObject().
        oJson:Add("type", TypeNameOf(poErr)).

        IF TYPE-OF(poErr, AblError) THEN DO:
            oAbl = CAST(poErr, AblError).
            oJson:Add("code", oAbl:Code).
            oJson:Add("httpStatus", oAbl:HttpStatus).
        END.
        ELSE DO:
            oJson:Add("code", "Error").
            oJson:Add("httpStatus", 500).
        END.

        oJson:Add("message", Messages(poErr)).

        IF VALID-OBJECT(oAbl) THEN DO:
            IF oAbl:HasContext() THEN
                oJson:Add("context", CAST(oAbl:Context:Clone(), JsonObject)).
            IF VALID-OBJECT(oAbl:Cause) THEN
                oJson:Add("cause", ToJson(oAbl:Cause)).
        END.

        RETURN oJson.
    END METHOD.

    /* After a statement run with NO-ERROR: throws a AblError (code
       "Status") holding every ERROR-STATUS message, or does nothing when
       the statement succeeded. */
    METHOD PUBLIC STATIC VOID ThrowIfStatus(INPUT pcContext AS CHARACTER):
        DEFINE VARIABLE oErr  AS AblError NO-UNDO.
        DEFINE VARIABLE cMsgs AS CHARACTER NO-UNDO EXTENT 50.
        DEFINE VARIABLE iNums AS INTEGER   NO-UNDO EXTENT 50.
        DEFINE VARIABLE iMax  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cHead AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.

        IF NOT ERROR-STATUS:ERROR THEN RETURN.

        /* Copy everything out first; later statements may reset ERROR-STATUS. */
        iMax = MINIMUM(ERROR-STATUS:NUM-MESSAGES, 50).
        DO i = 1 TO iMax:
            ASSIGN cMsgs[i] = ERROR-STATUS:GET-MESSAGE(i)
                   iNums[i] = ERROR-STATUS:GET-NUMBER(i).
        END.

        cHead = (IF iMax > 0 THEN cMsgs[1] ELSE "Statement failed").
        IF pcContext > "" THEN cHead = pcContext + ": " + cHead.

        oErr = NEW AblError("Status", cHead, ?).
        DO i = 2 TO iMax:
            oErr:AddMessage(cMsgs[i], iNums[i]).
        END.

        UNDO, THROW oErr.
    END METHOD.

    /* ---------------------------------------------------------------- */

    METHOD PRIVATE STATIC Progress.Lang.Error NextCause(INPUT poErr AS Progress.Lang.Error):
        IF VALID-OBJECT(poErr) AND TYPE-OF(poErr, AblError) THEN
            RETURN CAST(poErr, AblError):Cause.
        RETURN ?.
    END METHOD.

    METHOD PRIVATE STATIC CHARACTER TypeNameOf(INPUT poErr AS Progress.Lang.Error):
        RETURN CAST(poErr, Progress.Lang.Object):GetClass():TypeName.
    END METHOD.

END CLASS.
