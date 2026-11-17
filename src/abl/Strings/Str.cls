/*------------------------------------------------------------------------
    File        : abl/Strings/Str.cls
    Purpose     : String helpers. This first version holds the named
                  formatter; more helpers (Split, Join, Pad, ...) follow.

    Format syntax
        [name]          value of "name" in its default text form
        [name:mask]     value run through an ABL format mask:
                          [total:>>>,>>9.99]   [due:99/99/9999]
                          [ok:yes/no]          [code:x(5)]
                        Only the first ":" splits, so [t:99:99] works.
                        Extra mask "iso" gives ISO-8601 dates/datetimes.
        [[  and  ]]     a literal [ or ]
        Spaces around the name are ignored: [ name ] = [name].
        Unknown values print as ?.
        A missing name, an unclosed [, a stray ] or a value that does
        not fit its mask raise an error rather than printing wrong text.

        Square brackets, not curly braces: curly braces inside an ABL
        string are preprocessor references and would not compile.

    Usage
        Str:Format("Hello [name], you owe [amt:>>>,>>9.99]",
                   Args:Of("name", cName):Add("amt", dOwed)).

        Str:Format("Order [orderNum] for [customer]", oJsonObject).

        Str:FormatLong(lcBigTemplate, oArgs).   (LONGCHAR in and out)
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Json.ObjectModel.JsonObject.
USING abl.Core.Box.
USING abl.Errors.ArgumentError.
USING abl.Errors.AblError.
USING abl.Strings.Args.

CLASS abl.Strings.Str FINAL:

    CONSTRUCTOR PRIVATE Str():
    END CONSTRUCTOR.

    /* ---------------------------------------------------------------- */
    /* Format                                                           */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC STATIC CHARACTER Format(INPUT pcTemplate AS CHARACTER, INPUT poArgs AS Args):
        DEFINE VARIABLE cOut AS CHARACTER NO-UNDO.
        cOut = FormatLong(pcTemplate, poArgs).
        RETURN cOut.
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER Format(INPUT pcTemplate AS CHARACTER, INPUT poValues AS JsonObject):
        DEFINE VARIABLE cOut AS CHARACTER NO-UNDO.
        cOut = FormatLong(pcTemplate, Args:FromJson(poValues)).
        RETURN cOut.
    END METHOD.

    METHOD PUBLIC STATIC LONGCHAR FormatLong(INPUT plcTemplate AS LONGCHAR, INPUT poValues AS JsonObject):
        RETURN FormatLong(plcTemplate, Args:FromJson(poValues)).
    END METHOD.

    METHOD PUBLIC STATIC LONGCHAR FormatLong(INPUT plcTemplate AS LONGCHAR, INPUT poArgs AS Args):
        DEFINE VARIABLE lcOut  AS LONGCHAR  NO-UNDO.
        DEFINE VARIABLE iPos   AS INT64     NO-UNDO INITIAL 1.
        DEFINE VARIABLE iLen   AS INT64     NO-UNDO.
        DEFINE VARIABLE iOpen  AS INT64     NO-UNDO.
        DEFINE VARIABLE iClose AS INT64     NO-UNDO.
        DEFINE VARIABLE iEnd   AS INT64     NO-UNDO.
        DEFINE VARIABLE cToken AS CHARACTER NO-UNDO.

        IF plcTemplate = ? THEN RETURN ?.

        ASSIGN lcOut = ""
               iLen  = LENGTH(plcTemplate).

        DO WHILE iPos <= iLen:
            ASSIGN iOpen  = INDEX(plcTemplate, "[", iPos)
                   iClose = INDEX(plcTemplate, "]", iPos).

            /* No more brackets: copy the rest and stop. */
            IF iOpen = 0 AND iClose = 0 THEN DO:
                lcOut = lcOut + SUBSTRING(plcTemplate, iPos).
                LEAVE.
            END.

            /* A ] comes first: it must be the escape "]]". */
            IF iClose > 0 AND (iOpen = 0 OR iClose < iOpen) THEN DO:
                IF SUBSTRING(plcTemplate, iClose + 1, 1) <> "]" THEN
                    UNDO, THROW FormatError(SUBSTITUTE("Unmatched ']' at position &1", iClose), plcTemplate).
                lcOut = lcOut + SUBSTRING(plcTemplate, iPos, iClose - iPos + 1).
                iPos  = iClose + 2.
                NEXT.
            END.

            /* A [ comes first: copy the text before it. */
            lcOut = lcOut + SUBSTRING(plcTemplate, iPos, iOpen - iPos).

            /* "[[" is a literal bracket. */
            IF SUBSTRING(plcTemplate, iOpen + 1, 1) = "[" THEN DO:
                lcOut = lcOut + "[".
                iPos  = iOpen + 2.
                NEXT.
            END.

            iEnd = INDEX(plcTemplate, "]", iOpen + 1).
            IF iEnd = 0 THEN
                UNDO, THROW FormatError(SUBSTITUTE("Unclosed '[' at position &1", iOpen), plcTemplate).
            IF iEnd - iOpen - 1 > 500 THEN
                UNDO, THROW FormatError(SUBSTITUTE("Placeholder at position &1 is longer than 500 characters", iOpen), plcTemplate).

            cToken = SUBSTRING(plcTemplate, iOpen + 1, iEnd - iOpen - 1).
            lcOut  = lcOut + RenderToken(cToken, poArgs, plcTemplate).
            iPos   = iEnd + 1.
        END.

        RETURN lcOut.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Comparison                                                       */
    /* ---------------------------------------------------------------- */

    /* Case-sensitive equality. ABL's "=" ignores case (and trailing
       blanks); this does not. Works on LONGCHAR of any length. */
    METHOD PUBLIC STATIC LOGICAL EqualsExact(INPUT plcA AS LONGCHAR, INPUT plcB AS LONGCHAR):
        DEFINE VARIABLE iLen AS INT64     NO-UNDO.
        DEFINE VARIABLE iPos AS INT64     NO-UNDO.
        DEFINE VARIABLE cA   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cB   AS CHARACTER NO-UNDO.

        IF plcA = ? OR plcB = ? THEN
            RETURN (plcA = ?) AND (plcB = ?).

        iLen = LENGTH(plcA).
        IF iLen <> LENGTH(plcB) THEN RETURN FALSE.

        /* Compare in chunks that fit in CHARACTER. */
        DO iPos = 1 TO iLen BY 15000:
            ASSIGN cA = SUBSTRING(plcA, iPos, 15000)
                   cB = SUBSTRING(plcB, iPos, 15000).
            IF COMPARE(cA, "NE", cB, "CASE-SENSITIVE") THEN RETURN FALSE.
        END.

        RETURN TRUE.
    END METHOD.

    /* ---------------------------------------------------------------- */

    METHOD PRIVATE STATIC CHARACTER RenderToken(INPUT pcToken     AS CHARACTER,
                                                INPUT poArgs      AS Args,
                                                INPUT plcTemplate AS LONGCHAR):
        DEFINE VARIABLE cName  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cMask  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iColon AS INTEGER   NO-UNDO.
        DEFINE VARIABLE oValue AS Box       NO-UNDO.
        DEFINE VARIABLE cOut   AS CHARACTER NO-UNDO.

        iColon = INDEX(pcToken, ":").
        IF iColon > 0 THEN
            ASSIGN cName = TRIM(SUBSTRING(pcToken, 1, iColon - 1))
                   cMask = SUBSTRING(pcToken, iColon + 1).
        ELSE
            ASSIGN cName = TRIM(pcToken)
                   cMask = "".

        IF cName = "" THEN
            UNDO, THROW FormatError("Empty placeholder name in '[" + pcToken + "]'", plcTemplate).

        IF NOT VALID-OBJECT(poArgs) THEN
            UNDO, THROW FormatError(SUBSTITUTE("No value given for placeholder '&1'", cName), plcTemplate).
        IF NOT poArgs:Has(cName) THEN
            UNDO, THROW FormatError(SUBSTITUTE("No value given for placeholder '&1'", cName), plcTemplate).

        oValue = poArgs:Get(cName).

        DO ON ERROR UNDO, THROW:
            cOut = oValue:ToString(cMask).
            CATCH eMask AS Progress.Lang.Error:
                UNDO, THROW NEW AblError(
                    "Format",
                    SUBSTITUTE("Cannot format placeholder '&1' (&2) with mask '&3'", cName, oValue:DataType, cMask),
                    eMask).
            END CATCH.
        END.

        RETURN cOut.
    END METHOD.

    METHOD PRIVATE STATIC ArgumentError FormatError(INPUT pcMessage AS CHARACTER, INPUT plcTemplate AS LONGCHAR):
        DEFINE VARIABLE oErr      AS ArgumentError NO-UNDO.
        DEFINE VARIABLE cTemplate AS CHARACTER     NO-UNDO.

        cTemplate = SUBSTRING(plcTemplate, 1, 200).
        oErr = NEW ArgumentError("Str:Format - " + pcMessage, "template").
        oErr:AddContext("template", cTemplate).
        RETURN oErr.
    END METHOD.

END CLASS.
