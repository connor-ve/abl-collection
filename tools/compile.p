/*------------------------------------------------------------------------
    File        : tools/compile.p
    Purpose     : Compiles every .cls and .p under the given folders and
                  lists each failure with file, line and message. Run it
                  first on a new OpenEdge install or version.

    Usage (from the repo root):
        _progres -b -p tools/compile.p -param "src,tests"
        _progres -b -p tools/compile.p -param "src,tests,out=build/rcode"

    The folders listed are added to the front of PROPATH, because class
    names are resolved from PROPATH.
    With out=..., r-code is saved there; otherwise nothing is written.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE TEMP-TABLE ttDir NO-UNDO
    FIELD RootPath AS CHARACTER
    FIELD DirPath  AS CHARACTER
    FIELD Scanned  AS LOGICAL
    INDEX ixPath IS PRIMARY UNIQUE DirPath
    INDEX ixScanned Scanned.

DEFINE TEMP-TABLE ttFile NO-UNDO
    FIELD RelPath AS CHARACTER
    INDEX ixPath IS PRIMARY UNIQUE RelPath.

DEFINE STREAM sDir.

DEFINE VARIABLE cOutDir AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEntry  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cRoot   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cName   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFull   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cAttr   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCurDir AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCurRt  AS CHARACTER NO-UNDO.
DEFINE VARIABLE iOk     AS INTEGER   NO-UNDO.
DEFINE VARIABLE iWarn   AS INTEGER   NO-UNDO.
DEFINE VARIABLE iFail   AS INTEGER   NO-UNDO.
DEFINE VARIABLE i       AS INTEGER   NO-UNDO.
DEFINE VARIABLE j       AS INTEGER   NO-UNDO.

/* Parse parameters: bare entries are folders, out=... is the r-code dir. */
DO i = 1 TO NUM-ENTRIES(SESSION:PARAMETER):
    cEntry = TRIM(ENTRY(i, SESSION:PARAMETER)).
    IF cEntry BEGINS "out=" THEN DO:
        cOutDir = SUBSTRING(cEntry, 5).
        NEXT.
    END.

    FILE-INFO:FILE-NAME = cEntry.
    IF FILE-INFO:FULL-PATHNAME = ? THEN DO:
        PUT UNFORMATTED "Folder not found: " cEntry SKIP.
        NEXT.
    END.

    cRoot = RTRIM(REPLACE(FILE-INFO:FULL-PATHNAME, CHR(92), "/"), "/").
    IF NOT CAN-FIND(ttDir WHERE ttDir.DirPath = cRoot) THEN DO:
        CREATE ttDir.
        ASSIGN ttDir.RootPath = cRoot
               ttDir.DirPath  = cRoot.
    END.
END.

/* Put the source folders first on PROPATH so classes resolve. */
cEntry = "".
FOR EACH ttDir:
    cEntry = cEntry + ttDir.RootPath + ",".
END.
PROPATH = cEntry + PROPATH.

IF cOutDir > "" THEN OS-CREATE-DIR VALUE(cOutDir).

/* Walk folders breadth-first and collect source files relative to their root. */
DO WHILE CAN-FIND(FIRST ttDir WHERE ttDir.Scanned = FALSE):
    FIND FIRST ttDir WHERE ttDir.Scanned = FALSE.
    ASSIGN ttDir.Scanned = TRUE
           cCurDir       = ttDir.DirPath
           cCurRt        = ttDir.RootPath.

    INPUT STREAM sDir FROM OS-DIR(cCurDir).
    REPEAT:
        IMPORT STREAM sDir cName cFull cAttr.
        IF cName = "." OR cName = ".." THEN NEXT.
        cFull = REPLACE(cFull, CHR(92), "/").

        IF INDEX(cAttr, "D") > 0 THEN DO:
            IF NOT CAN-FIND(ttDir WHERE ttDir.DirPath = cFull) THEN DO:
                CREATE ttDir.
                ASSIGN ttDir.RootPath = cCurRt
                       ttDir.DirPath  = cFull.
            END.
        END.
        ELSE IF cName MATCHES "*.cls" OR cName MATCHES "*.p" THEN DO:
            cEntry = SUBSTRING(cFull, LENGTH(cCurRt) + 2).
            IF NOT CAN-FIND(ttFile WHERE ttFile.RelPath = cEntry) THEN DO:
                CREATE ttFile.
                ttFile.RelPath = cEntry.
            END.
        END.
    END.
    INPUT STREAM sDir CLOSE.
END.

/* Compile each file by its PROPATH-relative name. */
FOR EACH ttFile:
    IF cOutDir > "" THEN
        COMPILE VALUE(ttFile.RelPath) SAVE INTO VALUE(cOutDir) NO-ERROR.
    ELSE
        COMPILE VALUE(ttFile.RelPath) NO-ERROR.

    IF COMPILER:ERROR THEN DO:
        iFail = iFail + 1.
        PUT UNFORMATTED "FAIL  " ttFile.RelPath SKIP.
        PUT UNFORMATTED SUBSTITUTE("      at &1 line &2 column &3",
                                   COMPILER:FILE-NAME, COMPILER:ERROR-ROW, COMPILER:ERROR-COLUMN) SKIP.
        DO j = 1 TO ERROR-STATUS:NUM-MESSAGES:
            PUT UNFORMATTED "      " ERROR-STATUS:GET-MESSAGE(j) SKIP.
        END.
    END.
    ELSE IF COMPILER:WARNING THEN DO:
        iWarn = iWarn + 1.
        PUT UNFORMATTED "WARN  " ttFile.RelPath SKIP.
        DO j = 1 TO ERROR-STATUS:NUM-MESSAGES:
            PUT UNFORMATTED "      " ERROR-STATUS:GET-MESSAGE(j) SKIP.
        END.
    END.
    ELSE DO:
        iOk = iOk + 1.
        PUT UNFORMATTED "ok    " ttFile.RelPath SKIP.
    END.
END.

PUT UNFORMATTED SKIP SUBSTITUTE("Compiled: &1 ok, &2 with warnings, &3 failed", iOk, iWarn, iFail) SKIP.
PUT UNFORMATTED "RESULT: " (IF iFail = 0 THEN "PASSED" ELSE "FAILED") SKIP.

QUIT.
