/*------------------------------------------------------------------------
    File        : abl/Strings/Args.cls
    Purpose     : A small set of named values, built fluently, for
                  Str:Format and anything else that takes "named
                  parameters". No limit on how many.
    Usage       :
        Args:Of("name", "Ann"):Add("total", 1234.5):Add("due", TODAY)

        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        DO i = 1 TO 20:
            oArgs:Add("p" + STRING(i), i).
        END.
    Notes       : Names are case-insensitive and trimmed. Adding a name
                  twice replaces the earlier value.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.Object.
USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonDataType.
USING abl.Core.Box.
USING abl.Errors.Guard.

CLASS abl.Strings.Args:

    DEFINE PRIVATE TEMP-TABLE ttArg NO-UNDO
        FIELD ArgName  AS CHARACTER
        FIELD ArgValue AS Progress.Lang.Object
        INDEX ixName IS PRIMARY UNIQUE ArgName.

    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC Args():
    END CONSTRUCTOR.

    /* ---------------------------------------------------------------- */
    /* Static starters: Args:Of(name, value)                             */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC STATIC Args Of(INPUT pcName AS CHARACTER, INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        RETURN oArgs:Add(pcName, pcValue).
    END METHOD.

    METHOD PUBLIC STATIC Args Of(INPUT pcName AS CHARACTER, INPUT plcValue AS LONGCHAR):
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        RETURN oArgs:Add(pcName, plcValue).
    END METHOD.

    METHOD PUBLIC STATIC Args Of(INPUT pcName AS CHARACTER, INPUT piValue AS INTEGER):
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        RETURN oArgs:Add(pcName, piValue).
    END METHOD.

    METHOD PUBLIC STATIC Args Of(INPUT pcName AS CHARACTER, INPUT piValue AS INT64):
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        RETURN oArgs:Add(pcName, piValue).
    END METHOD.

    METHOD PUBLIC STATIC Args Of(INPUT pcName AS CHARACTER, INPUT pdValue AS DECIMAL):
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        RETURN oArgs:Add(pcName, pdValue).
    END METHOD.

    METHOD PUBLIC STATIC Args Of(INPUT pcName AS CHARACTER, INPUT plValue AS LOGICAL):
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        RETURN oArgs:Add(pcName, plValue).
    END METHOD.

    METHOD PUBLIC STATIC Args Of(INPUT pcName AS CHARACTER, INPUT pdaValue AS DATE):
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        RETURN oArgs:Add(pcName, pdaValue).
    END METHOD.

    METHOD PUBLIC STATIC Args Of(INPUT pcName AS CHARACTER, INPUT pdtValue AS DATETIME):
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        RETURN oArgs:Add(pcName, pdtValue).
    END METHOD.

    METHOD PUBLIC STATIC Args Of(INPUT pcName AS CHARACTER, INPUT pdtzValue AS DATETIME-TZ):
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        RETURN oArgs:Add(pcName, pdtzValue).
    END METHOD.

    METHOD PUBLIC STATIC Args Of(INPUT pcName AS CHARACTER, INPUT phValue AS HANDLE):
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        RETURN oArgs:Add(pcName, phValue).
    END METHOD.

    METHOD PUBLIC STATIC Args Of(INPUT pcName AS CHARACTER, INPUT poValue AS Object):
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = NEW Args().
        RETURN oArgs:Add(pcName, poValue).
    END METHOD.

    /* Every property of a JsonObject becomes an arg. Nested objects and
       arrays become their JSON text; JSON null becomes ?. */
    METHOD PUBLIC STATIC Args FromJson(INPUT poJson AS JsonObject):
        DEFINE VARIABLE oArgs  AS Args      NO-UNDO.
        DEFINE VARIABLE cNames AS CHARACTER NO-UNDO EXTENT.
        DEFINE VARIABLE cName  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iType  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.

        oArgs = NEW Args().
        IF NOT VALID-OBJECT(poJson) THEN RETURN oArgs.

        cNames = poJson:GetNames().
        IF EXTENT(cNames) = ? THEN RETURN oArgs.

        DO i = 1 TO EXTENT(cNames):
            ASSIGN cName = cNames[i]
                   iType = poJson:GetType(cName).

            IF iType = JsonDataType:STRING THEN
                oArgs:Add(cName, poJson:GetCharacter(cName)).
            ELSE IF iType = JsonDataType:NUMBER THEN
                oArgs:Add(cName, poJson:GetDecimal(cName)).
            ELSE IF iType = JsonDataType:BOOLEAN THEN
                oArgs:Add(cName, poJson:GetLogical(cName)).
            ELSE IF iType = JsonDataType:NULL THEN
                oArgs:Add(cName, Box:OfUnknown()).
            ELSE
                oArgs:Add(cName, poJson:GetJsonText(cName)).
        END.

        RETURN oArgs.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Add(name, value): returns THIS-OBJECT for chaining                */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC Args Add(INPUT pcName AS CHARACTER, INPUT pcValue AS CHARACTER):
        RETURN Store(pcName, NEW Box(pcValue)).
    END METHOD.

    METHOD PUBLIC Args Add(INPUT pcName AS CHARACTER, INPUT plcValue AS LONGCHAR):
        RETURN Store(pcName, NEW Box(plcValue)).
    END METHOD.

    METHOD PUBLIC Args Add(INPUT pcName AS CHARACTER, INPUT piValue AS INTEGER):
        RETURN Store(pcName, NEW Box(piValue)).
    END METHOD.

    METHOD PUBLIC Args Add(INPUT pcName AS CHARACTER, INPUT piValue AS INT64):
        RETURN Store(pcName, NEW Box(piValue)).
    END METHOD.

    METHOD PUBLIC Args Add(INPUT pcName AS CHARACTER, INPUT pdValue AS DECIMAL):
        RETURN Store(pcName, NEW Box(pdValue)).
    END METHOD.

    METHOD PUBLIC Args Add(INPUT pcName AS CHARACTER, INPUT plValue AS LOGICAL):
        RETURN Store(pcName, NEW Box(plValue)).
    END METHOD.

    METHOD PUBLIC Args Add(INPUT pcName AS CHARACTER, INPUT pdaValue AS DATE):
        RETURN Store(pcName, NEW Box(pdaValue)).
    END METHOD.

    METHOD PUBLIC Args Add(INPUT pcName AS CHARACTER, INPUT pdtValue AS DATETIME):
        RETURN Store(pcName, NEW Box(pdtValue)).
    END METHOD.

    METHOD PUBLIC Args Add(INPUT pcName AS CHARACTER, INPUT pdtzValue AS DATETIME-TZ):
        RETURN Store(pcName, NEW Box(pdtzValue)).
    END METHOD.

    METHOD PUBLIC Args Add(INPUT pcName AS CHARACTER, INPUT phValue AS HANDLE):
        RETURN Store(pcName, NEW Box(phValue)).
    END METHOD.

    /* A Box passed here is stored as-is rather than boxed again. */
    METHOD PUBLIC Args Add(INPUT pcName AS CHARACTER, INPUT poValue AS Object):
        IF VALID-OBJECT(poValue) AND TYPE-OF(poValue, Box) THEN
            RETURN Store(pcName, CAST(poValue, Box)).
        RETURN Store(pcName, NEW Box(poValue)).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Lookup                                                           */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC LOGICAL Has(INPUT pcName AS CHARACTER):
        RETURN CAN-FIND(ttArg WHERE ttArg.ArgName = TRIM(pcName)).
    END METHOD.

    /* The boxed value, or ? when the name is not present. */
    METHOD PUBLIC Box Get(INPUT pcName AS CHARACTER):
        FIND ttArg WHERE ttArg.ArgName = TRIM(pcName) NO-ERROR.
        IF NOT AVAILABLE ttArg THEN RETURN ?.
        RETURN CAST(ttArg.ArgValue, Box).
    END METHOD.

    /* Comma-separated names, in alphabetical order. */
    METHOD PUBLIC CHARACTER Names():
        DEFINE VARIABLE cOut AS CHARACTER NO-UNDO.
        FOR EACH ttArg:
            cOut = cOut + (IF cOut = "" THEN "" ELSE ",") + ttArg.ArgName.
        END.
        RETURN cOut.
    END METHOD.

    /* ---------------------------------------------------------------- */

    METHOD PRIVATE Args Store(INPUT pcName AS CHARACTER, INPUT poValue AS Box):
        DEFINE VARIABLE cName AS CHARACTER NO-UNDO.

        Guard:NotBlank(pcName, "pcName").
        cName = TRIM(pcName).

        FIND ttArg WHERE ttArg.ArgName = cName NO-ERROR.
        IF NOT AVAILABLE ttArg THEN DO:
            CREATE ttArg.
            ttArg.ArgName = cName.
            Count = Count + 1.
        END.
        ttArg.ArgValue = poValue.

        RETURN THIS-OBJECT.
    END METHOD.

END CLASS.
