/*------------------------------------------------------------------------
    File        : abl/Core/Box.cls
    Purpose     : Holds one value of any ABL primitive type (or an object
                  reference) together with the name of its type. Used
                  wherever the library needs "a value of some type":
                  format arguments, test expectations, and later the
                  collections.
    Notes       : - Numeric types compare by value across INTEGER, INT64
                    and DECIMAL (5 = 5.0).
                  - Text comparison follows ABL rules: case-insensitive,
                    trailing blanks ignored. Use Str:EqualsExact for a
                    case-sensitive check.
                  - Unknown values: create with Box:OfUnknown() or pass a
                    variable that holds ?. A bare ? literal cannot pick
                    between constructor overloads.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.Object.
USING abl.Errors.InvalidStateError.

CLASS abl.Core.Box FINAL:

    /* One of: CHARACTER LONGCHAR INTEGER INT64 DECIMAL LOGICAL DATE
       DATETIME DATETIME-TZ HANDLE OBJECT */
    DEFINE PUBLIC PROPERTY DataType AS CHARACTER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PRIVATE VARIABLE cChar  AS CHARACTER   NO-UNDO.
    DEFINE PRIVATE VARIABLE lcLong AS LONGCHAR    NO-UNDO.
    DEFINE PRIVATE VARIABLE iInt   AS INT64       NO-UNDO.
    DEFINE PRIVATE VARIABLE deDec  AS DECIMAL     NO-UNDO.
    DEFINE PRIVATE VARIABLE lLog   AS LOGICAL     NO-UNDO.
    DEFINE PRIVATE VARIABLE daDate AS DATE        NO-UNDO.
    DEFINE PRIVATE VARIABLE dtDt   AS DATETIME    NO-UNDO.
    DEFINE PRIVATE VARIABLE dtzDt  AS DATETIME-TZ NO-UNDO.
    DEFINE PRIVATE VARIABLE hHdl   AS HANDLE      NO-UNDO.
    DEFINE PRIVATE VARIABLE oObj   AS Object      NO-UNDO.

    DEFINE PUBLIC PROPERTY IsUnknown AS LOGICAL NO-UNDO
        GET():
            CASE DataType:
                WHEN "CHARACTER"   THEN RETURN cChar = ?.
                WHEN "LONGCHAR"    THEN RETURN lcLong = ?.
                WHEN "INTEGER" OR WHEN "INT64" THEN RETURN iInt = ?.
                WHEN "DECIMAL"     THEN RETURN deDec = ?.
                WHEN "LOGICAL"     THEN RETURN lLog = ?.
                WHEN "DATE"        THEN RETURN daDate = ?.
                WHEN "DATETIME"    THEN RETURN dtDt = ?.
                WHEN "DATETIME-TZ" THEN RETURN dtzDt = ?.
                WHEN "HANDLE"      THEN RETURN hHdl = ?.
                WHEN "OBJECT"      THEN RETURN NOT VALID-OBJECT(oObj).
            END CASE.
            RETURN TRUE.
        END GET.

    DEFINE PUBLIC PROPERTY IsNumeric AS LOGICAL NO-UNDO
        GET():
            RETURN LOOKUP(DataType, "INTEGER,INT64,DECIMAL") > 0.
        END GET.

    DEFINE PUBLIC PROPERTY IsText AS LOGICAL NO-UNDO
        GET():
            RETURN LOOKUP(DataType, "CHARACTER,LONGCHAR") > 0.
        END GET.

    /* ---------------------------------------------------------------- */
    /* Constructors                                                     */
    /* ---------------------------------------------------------------- */

    CONSTRUCTOR PUBLIC Box(INPUT pcValue AS CHARACTER):
        ASSIGN DataType = "CHARACTER"
               cChar    = pcValue.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC Box(INPUT plcValue AS LONGCHAR):
        ASSIGN DataType = "LONGCHAR"
               lcLong   = plcValue.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC Box(INPUT piValue AS INTEGER):
        ASSIGN DataType = "INTEGER"
               iInt     = piValue.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC Box(INPUT piValue AS INT64):
        ASSIGN DataType = "INT64"
               iInt     = piValue.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC Box(INPUT pdValue AS DECIMAL):
        ASSIGN DataType = "DECIMAL"
               deDec    = pdValue.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC Box(INPUT plValue AS LOGICAL):
        ASSIGN DataType = "LOGICAL"
               lLog     = plValue.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC Box(INPUT pdaValue AS DATE):
        ASSIGN DataType = "DATE"
               daDate   = pdaValue.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC Box(INPUT pdtValue AS DATETIME):
        ASSIGN DataType = "DATETIME"
               dtDt     = pdtValue.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC Box(INPUT pdtzValue AS DATETIME-TZ):
        ASSIGN DataType = "DATETIME-TZ"
               dtzDt    = pdtzValue.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC Box(INPUT phValue AS HANDLE):
        ASSIGN DataType = "HANDLE"
               hHdl     = phValue.
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC Box(INPUT poValue AS Object):
        ASSIGN DataType = "OBJECT"
               oObj     = poValue.
    END CONSTRUCTOR.

    /* A CHARACTER box holding ?. */
    METHOD PUBLIC STATIC Box OfUnknown():
        DEFINE VARIABLE cNull AS CHARACTER NO-UNDO INITIAL ?.
        RETURN NEW Box(cNull).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Typed access                                                     */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC CHARACTER AsCharacter():
        DEFINE VARIABLE cOut AS CHARACTER NO-UNDO.
        IF IsUnknown THEN RETURN ?.
        IF DataType = "CHARACTER" THEN RETURN cChar.
        IF DataType = "LONGCHAR" THEN DO:
            cOut = lcLong. /* raises an error past the CHARACTER limit */
            RETURN cOut.
        END.
        RETURN THIS-OBJECT:ToString().
    END METHOD.

    METHOD PUBLIC LONGCHAR AsLongchar():
        DEFINE VARIABLE lcOut AS LONGCHAR NO-UNDO.
        IF IsUnknown THEN RETURN ?.
        IF DataType = "LONGCHAR" THEN RETURN lcLong.
        IF DataType = "CHARACTER" THEN lcOut = cChar.
        ELSE lcOut = THIS-OBJECT:ToString().
        RETURN lcOut.
    END METHOD.

    METHOD PUBLIC DECIMAL AsDecimal():
        IF NOT IsNumeric THEN
            UNDO, THROW NEW InvalidStateError(SUBSTITUTE("Box holds &1, not a number", DataType)).
        IF DataType = "DECIMAL" THEN RETURN deDec.
        RETURN DECIMAL(iInt).
    END METHOD.

    METHOD PUBLIC INT64 AsInt64():
        IF NOT IsNumeric THEN
            UNDO, THROW NEW InvalidStateError(SUBSTITUTE("Box holds &1, not a number", DataType)).
        IF DataType = "DECIMAL" THEN RETURN INT64(deDec).
        RETURN iInt.
    END METHOD.

    METHOD PUBLIC LOGICAL AsLogical():
        RequireType("LOGICAL").
        RETURN lLog.
    END METHOD.

    METHOD PUBLIC DATE AsDate():
        RequireType("DATE").
        RETURN daDate.
    END METHOD.

    METHOD PUBLIC DATETIME AsDateTime():
        RequireType("DATETIME").
        RETURN dtDt.
    END METHOD.

    METHOD PUBLIC DATETIME-TZ AsDateTimeTz():
        RequireType("DATETIME-TZ").
        RETURN dtzDt.
    END METHOD.

    METHOD PUBLIC HANDLE AsHandle():
        RequireType("HANDLE").
        RETURN hHdl.
    END METHOD.

    METHOD PUBLIC Object AsObject():
        RequireType("OBJECT").
        RETURN oObj.
    END METHOD.

    METHOD PRIVATE VOID RequireType(INPUT pcType AS CHARACTER):
        IF DataType <> pcType THEN
            UNDO, THROW NEW InvalidStateError(SUBSTITUTE("Box holds &1, not &2", DataType, pcType)).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Text                                                             */
    /* ---------------------------------------------------------------- */

    /* Default text form. LONGCHAR values are cut at 30000 characters;
       use AsLongchar() for the full value. */
    METHOD PUBLIC OVERRIDE CHARACTER ToString():
        DEFINE VARIABLE cOut AS CHARACTER NO-UNDO.

        IF IsUnknown THEN RETURN "?".

        CASE DataType:
            WHEN "CHARACTER"   THEN RETURN cChar.
            WHEN "LONGCHAR" THEN DO:
                cOut = SUBSTRING(lcLong, 1, 30000).
                RETURN cOut.
            END.
            WHEN "INTEGER" OR WHEN "INT64" THEN RETURN STRING(iInt).
            WHEN "DECIMAL"     THEN RETURN STRING(deDec).
            WHEN "LOGICAL"     THEN RETURN STRING(lLog).
            WHEN "DATE"        THEN RETURN STRING(daDate).
            WHEN "DATETIME"    THEN RETURN STRING(dtDt).
            WHEN "DATETIME-TZ" THEN RETURN STRING(dtzDt).
            WHEN "HANDLE"      THEN RETURN STRING(hHdl).
            WHEN "OBJECT"      THEN RETURN oObj:ToString().
        END CASE.

        RETURN "?".
    END METHOD.

    /* Text form using an ABL format mask, e.g. ">>>,>>9.99", "99/99/9999",
       "yes/no", "x(10)". The extra mask "iso" gives ISO-8601 for DATE,
       DATETIME and DATETIME-TZ. Masks are ignored for LONGCHAR, HANDLE
       and OBJECT. */
    METHOD PUBLIC CHARACTER ToString(INPUT pcMask AS CHARACTER):
        IF pcMask = ? OR pcMask = "" THEN RETURN THIS-OBJECT:ToString().
        IF IsUnknown THEN RETURN "?".

        CASE DataType:
            WHEN "CHARACTER" THEN RETURN STRING(cChar, pcMask).
            WHEN "INTEGER" OR WHEN "INT64" THEN RETURN STRING(iInt, pcMask).
            WHEN "DECIMAL" THEN RETURN STRING(deDec, pcMask).
            WHEN "LOGICAL" THEN RETURN STRING(lLog, pcMask).
            WHEN "DATE" THEN DO:
                IF pcMask = "iso" THEN RETURN ISO-DATE(daDate).
                RETURN STRING(daDate, pcMask).
            END.
            WHEN "DATETIME" THEN DO:
                IF pcMask = "iso" THEN RETURN ISO-DATE(dtDt).
                RETURN STRING(dtDt, pcMask).
            END.
            WHEN "DATETIME-TZ" THEN DO:
                IF pcMask = "iso" THEN RETURN ISO-DATE(dtzDt).
                RETURN STRING(dtzDt, pcMask).
            END.
        END CASE.

        RETURN THIS-OBJECT:ToString().
    END METHOD.

    /* Short form for messages: "abc" (CHARACTER), 5 (INTEGER), ? (DATE). */
    METHOD PUBLIC CHARACTER Describe():
        DEFINE VARIABLE cVal  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cType AS CHARACTER NO-UNDO.

        cType = DataType.
        IF DataType = "OBJECT" AND VALID-OBJECT(oObj) THEN
            cType = oObj:GetClass():TypeName.

        IF IsUnknown THEN RETURN SUBSTITUTE("? (&1)", cType).

        cVal = THIS-OBJECT:ToString().
        IF LENGTH(cVal) > 200 THEN cVal = SUBSTRING(cVal, 1, 200) + "...".
        IF IsText THEN cVal = '"' + cVal + '"'.

        RETURN SUBSTITUTE("&1 (&2)", cVal, cType).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Equality                                                         */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC OVERRIDE LOGICAL Equals(INPUT poOther AS Object):
        DEFINE VARIABLE oBox AS Box NO-UNDO.

        IF NOT VALID-OBJECT(poOther) OR NOT TYPE-OF(poOther, Box) THEN RETURN FALSE.
        oBox = CAST(poOther, Box).

        IF IsUnknown OR oBox:IsUnknown THEN
            RETURN IsUnknown AND oBox:IsUnknown.

        IF IsNumeric AND oBox:IsNumeric THEN
            RETURN AsDecimal() = oBox:AsDecimal().

        IF IsText AND oBox:IsText THEN
            RETURN AsLongchar() = oBox:AsLongchar().

        IF DataType <> oBox:DataType THEN RETURN FALSE.

        CASE DataType:
            WHEN "LOGICAL"     THEN RETURN lLog = oBox:AsLogical().
            WHEN "DATE"        THEN RETURN daDate = oBox:AsDate().
            WHEN "DATETIME"    THEN RETURN dtDt = oBox:AsDateTime().
            WHEN "DATETIME-TZ" THEN RETURN dtzDt = oBox:AsDateTimeTz().
            WHEN "HANDLE"      THEN RETURN hHdl = oBox:AsHandle().
            WHEN "OBJECT"      THEN RETURN oObj:Equals(oBox:AsObject()).
        END CASE.

        RETURN FALSE.
    END METHOD.

END CLASS.
