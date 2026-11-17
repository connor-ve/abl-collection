/*------------------------------------------------------------------------
    File        : abl/Collections/Map.cls
    Purpose     : Key/value map with CHARACTER keys and values of any type
                  (stored in a Box). Remembers insertion order.

    Usage
        oMap = NEW Map().
        oMap:Put("name", "Ann"):Put("limit", 5000.00):Put("active", TRUE).

        cName  = oMap:GetChar("name", "").
        dLimit = oMap:GetDec("limit", 0).
        IF oMap:Has("active") THEN ...

        oKeys = oMap:Keys().                 insertion order
        DO i = 1 TO oKeys:Length:
            oValue = oMap:Get(oKeys:Get(i)).      a Box
        END.

    Notes       : - Keys are case-insensitive ("Name" and "NAME" are the
                    same key), as with any ABL index. Unknown (?) is not
                    a valid key; "" is.
                  - Typed getters return the default only when the key is
                    missing. A key that is present but holds ? returns ?.
                  - Lookups use an indexed temp-table: fast for any size.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.Object.
USING abl.Collections.CharSlice.
USING abl.Collections.ObjSlice.
USING abl.Core.Box.
USING abl.Errors.ArgumentError.

CLASS abl.Collections.Map:

    DEFINE PRIVATE TEMP-TABLE ttEntry NO-UNDO
        FIELD EntryKey   AS CHARACTER
        FIELD EntryValue AS Progress.Lang.Object
        FIELD Seq        AS INTEGER
        INDEX ixKey IS PRIMARY UNIQUE EntryKey
        INDEX ixSeq Seq.

    DEFINE PRIVATE VARIABLE iCount AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE iSeq   AS INTEGER NO-UNDO.

    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET():
            RETURN iCount.
        END GET.

    DEFINE PUBLIC PROPERTY IsEmpty AS LOGICAL NO-UNDO
        GET():
            RETURN iCount = 0.
        END GET.

    CONSTRUCTOR PUBLIC Map():
    END CONSTRUCTOR.

    /* ---------------------------------------------------------------- */
    /* Put(key, value): adds or replaces; returns the map for chaining   */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC Map Put(INPUT pcKey AS CHARACTER, INPUT pcValue AS CHARACTER):
        RETURN Store(pcKey, NEW Box(pcValue)).
    END METHOD.

    METHOD PUBLIC Map Put(INPUT pcKey AS CHARACTER, INPUT plcValue AS LONGCHAR):
        RETURN Store(pcKey, NEW Box(plcValue)).
    END METHOD.

    METHOD PUBLIC Map Put(INPUT pcKey AS CHARACTER, INPUT piValue AS INTEGER):
        RETURN Store(pcKey, NEW Box(piValue)).
    END METHOD.

    METHOD PUBLIC Map Put(INPUT pcKey AS CHARACTER, INPUT piValue AS INT64):
        RETURN Store(pcKey, NEW Box(piValue)).
    END METHOD.

    METHOD PUBLIC Map Put(INPUT pcKey AS CHARACTER, INPUT pdValue AS DECIMAL):
        RETURN Store(pcKey, NEW Box(pdValue)).
    END METHOD.

    METHOD PUBLIC Map Put(INPUT pcKey AS CHARACTER, INPUT plValue AS LOGICAL):
        RETURN Store(pcKey, NEW Box(plValue)).
    END METHOD.

    METHOD PUBLIC Map Put(INPUT pcKey AS CHARACTER, INPUT pdaValue AS DATE):
        RETURN Store(pcKey, NEW Box(pdaValue)).
    END METHOD.

    METHOD PUBLIC Map Put(INPUT pcKey AS CHARACTER, INPUT pdtValue AS DATETIME):
        RETURN Store(pcKey, NEW Box(pdtValue)).
    END METHOD.

    METHOD PUBLIC Map Put(INPUT pcKey AS CHARACTER, INPUT pdtzValue AS DATETIME-TZ):
        RETURN Store(pcKey, NEW Box(pdtzValue)).
    END METHOD.

    METHOD PUBLIC Map Put(INPUT pcKey AS CHARACTER, INPUT phValue AS HANDLE):
        RETURN Store(pcKey, NEW Box(phValue)).
    END METHOD.

    /* A Box is stored as-is; any other object is boxed. */
    METHOD PUBLIC Map Put(INPUT pcKey AS CHARACTER, INPUT poValue AS Object):
        IF VALID-OBJECT(poValue) AND TYPE-OF(poValue, Box) THEN
            RETURN Store(pcKey, CAST(poValue, Box)).
        RETURN Store(pcKey, NEW Box(poValue)).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Reading                                                          */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC LOGICAL Has(INPUT pcKey AS CHARACTER):
        IF pcKey = ? THEN RETURN FALSE.
        RETURN CAN-FIND(ttEntry WHERE ttEntry.EntryKey = pcKey).
    END METHOD.

    /* The boxed value, or ? when the key is missing. */
    METHOD PUBLIC Box Get(INPUT pcKey AS CHARACTER):
        IF pcKey = ? THEN RETURN ?.
        FIND ttEntry WHERE ttEntry.EntryKey = pcKey NO-ERROR.
        IF NOT AVAILABLE ttEntry THEN RETURN ?.
        RETURN CAST(ttEntry.EntryValue, Box).
    END METHOD.

    /* Any value as text. */
    METHOD PUBLIC CHARACTER GetChar(INPUT pcKey AS CHARACTER, INPUT pcDefault AS CHARACTER):
        DEFINE VARIABLE oValue AS Box NO-UNDO.
        oValue = THIS-OBJECT:Get(pcKey).
        IF NOT VALID-OBJECT(oValue) THEN RETURN pcDefault.
        RETURN oValue:AsCharacter().
    END METHOD.

    /* INTEGER, INT64 or DECIMAL values (decimals are rounded). */
    METHOD PUBLIC INT64 GetInt(INPUT pcKey AS CHARACTER, INPUT piDefault AS INT64):
        DEFINE VARIABLE oValue AS Box NO-UNDO.
        oValue = THIS-OBJECT:Get(pcKey).
        IF NOT VALID-OBJECT(oValue) THEN RETURN piDefault.
        RETURN oValue:AsInt64().
    END METHOD.

    METHOD PUBLIC DECIMAL GetDec(INPUT pcKey AS CHARACTER, INPUT pdDefault AS DECIMAL):
        DEFINE VARIABLE oValue AS Box NO-UNDO.
        oValue = THIS-OBJECT:Get(pcKey).
        IF NOT VALID-OBJECT(oValue) THEN RETURN pdDefault.
        RETURN oValue:AsDecimal().
    END METHOD.

    METHOD PUBLIC LOGICAL GetLog(INPUT pcKey AS CHARACTER, INPUT plDefault AS LOGICAL):
        DEFINE VARIABLE oValue AS Box NO-UNDO.
        oValue = THIS-OBJECT:Get(pcKey).
        IF NOT VALID-OBJECT(oValue) THEN RETURN plDefault.
        RETURN oValue:AsLogical().
    END METHOD.

    METHOD PUBLIC DATE GetDate(INPUT pcKey AS CHARACTER, INPUT pdaDefault AS DATE):
        DEFINE VARIABLE oValue AS Box NO-UNDO.
        oValue = THIS-OBJECT:Get(pcKey).
        IF NOT VALID-OBJECT(oValue) THEN RETURN pdaDefault.
        RETURN oValue:AsDate().
    END METHOD.

    /* The stored object, or ? when the key is missing. */
    METHOD PUBLIC Object GetObj(INPUT pcKey AS CHARACTER):
        DEFINE VARIABLE oValue AS Box NO-UNDO.
        oValue = THIS-OBJECT:Get(pcKey).
        IF NOT VALID-OBJECT(oValue) THEN RETURN ?.
        RETURN oValue:AsObject().
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Removing                                                         */
    /* ---------------------------------------------------------------- */

    /* TRUE when the key was present. */
    METHOD PUBLIC LOGICAL Remove(INPUT pcKey AS CHARACTER):
        IF pcKey = ? THEN RETURN FALSE.
        FIND ttEntry WHERE ttEntry.EntryKey = pcKey NO-ERROR.
        IF NOT AVAILABLE ttEntry THEN RETURN FALSE.
        DELETE ttEntry.
        iCount = iCount - 1.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC Map Clear():
        EMPTY TEMP-TABLE ttEntry.
        ASSIGN iCount = 0
               iSeq   = 0.
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Bulk                                                             */
    /* ---------------------------------------------------------------- */

    /* Keys in the order they were first added. */
    METHOD PUBLIC CharSlice Keys():
        DEFINE VARIABLE oOut AS CharSlice NO-UNDO.
        oOut = NEW CharSlice(0, MAXIMUM(iCount, 8)).
        FOR EACH ttEntry USE-INDEX ixSeq:
            oOut:Append(ttEntry.EntryKey).
        END.
        RETURN oOut.
    END METHOD.

    /* Keys in alphabetical order (case-insensitive). */
    METHOD PUBLIC CharSlice SortedKeys():
        DEFINE VARIABLE oOut AS CharSlice NO-UNDO.
        oOut = NEW CharSlice(0, MAXIMUM(iCount, 8)).
        FOR EACH ttEntry USE-INDEX ixKey:
            oOut:Append(ttEntry.EntryKey).
        END.
        RETURN oOut.
    END METHOD.

    /* Boxed values in key insertion order. */
    METHOD PUBLIC ObjSlice Values():
        DEFINE VARIABLE oOut AS ObjSlice NO-UNDO.
        oOut = NEW ObjSlice(0, MAXIMUM(iCount, 8)).
        FOR EACH ttEntry USE-INDEX ixSeq:
            oOut:Append(ttEntry.EntryValue).
        END.
        RETURN oOut.
    END METHOD.

    /* Copies of the entries; the boxed values themselves are shared. */
    METHOD PUBLIC Map Copy():
        DEFINE VARIABLE oOut AS Map NO-UNDO.
        oOut = NEW Map().
        FOR EACH ttEntry USE-INDEX ixSeq:
            oOut:Put(ttEntry.EntryKey, ttEntry.EntryValue).
        END.
        RETURN oOut.
    END METHOD.

    /* Map[a=1, b=x] in insertion order. */
    METHOD PUBLIC OVERRIDE CHARACTER ToString():
        DEFINE VARIABLE cOut   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iShown AS INTEGER   NO-UNDO.

        FOR EACH ttEntry USE-INDEX ixSeq:
            iShown = iShown + 1.
            IF iShown > 100 THEN DO:
                cOut = cOut + SUBSTITUTE(", ... (&1 more)", iCount - 100).
                LEAVE.
            END.
            cValue = CAST(ttEntry.EntryValue, Box):ToString().
            IF LENGTH(cValue) > 200 THEN cValue = SUBSTRING(cValue, 1, 200) + "...".
            cOut = cOut + (IF iShown > 1 THEN ", " ELSE "") + ttEntry.EntryKey + "=" + cValue.
        END.
        RETURN "Map[" + cOut + "]".
    END METHOD.

    /* ---------------------------------------------------------------- */

    METHOD PRIVATE Map Store(INPUT pcKey AS CHARACTER, INPUT poValue AS Box):
        IF pcKey = ? THEN
            UNDO, THROW NEW ArgumentError("Map key cannot be unknown (?)", "pcKey").

        FIND ttEntry WHERE ttEntry.EntryKey = pcKey NO-ERROR.
        IF NOT AVAILABLE ttEntry THEN DO:
            CREATE ttEntry.
            ASSIGN iSeq             = iSeq + 1
                   iCount           = iCount + 1
                   ttEntry.EntryKey = pcKey
                   ttEntry.Seq      = iSeq.
        END.
        ttEntry.EntryValue = poValue.
        RETURN THIS-OBJECT.
    END METHOD.

END CLASS.
