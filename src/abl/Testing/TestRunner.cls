/*------------------------------------------------------------------------
    File        : abl/Testing/TestRunner.cls
    Purpose     : Finds test classes, runs their Test* methods, and reports
                  the results as console text and/or JUnit XML (which CI
                  tools such as Jenkins, GitLab and Azure DevOps read).
    Usage       : Normally through abl/Testing/RunTests.p. Directly:
                    oRunner = NEW TestRunner().
                    oRunner:ClassFilter = "Strings".
                    oRunner:RunDirectory("tests").
                    oRunner:PrintReport("").
                    oRunner:WriteJUnit("build/test-results/junit.xml").
    Discovery   : Every file named *Test.cls under the directory. The
                  directory must be on PROPATH, because the class name is
                  the file path relative to it
                  (tests/app/InvoiceTest.cls -> app.InvoiceTest).
    Notes       : Test methods run in alphabetical order. Tests should not
                  depend on that order.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.Object.
USING abl.Errors.ArgumentError.
USING abl.Errors.Err.
USING abl.Testing.AssertionFailure.
USING abl.Testing.SkipSignal.
USING abl.Testing.TestCase.

CLASS abl.Testing.TestRunner:

    DEFINE PRIVATE TEMP-TABLE ttResult NO-UNDO
        FIELD Seq        AS INTEGER
        FIELD ClassName  AS CHARACTER
        FIELD TestName   AS CHARACTER
        FIELD Outcome    AS CHARACTER   /* PASS FAIL ERROR SKIP */
        FIELD DurationMs AS INT64
        FIELD Summary    AS CHARACTER
        FIELD Detail     AS CHARACTER
        INDEX ixSeq IS PRIMARY UNIQUE Seq
        INDEX ixClass ClassName Seq.

    DEFINE PRIVATE TEMP-TABLE ttMethod NO-UNDO
        FIELD MethodName AS CHARACTER
        INDEX ixName IS PRIMARY UNIQUE MethodName.

    DEFINE PRIVATE TEMP-TABLE ttDir NO-UNDO
        FIELD DirPath AS CHARACTER
        FIELD Scanned AS LOGICAL
        INDEX ixPath IS PRIMARY UNIQUE DirPath
        INDEX ixScanned Scanned.

    DEFINE PRIVATE TEMP-TABLE ttClass NO-UNDO
        FIELD ClassName AS CHARACTER
        INDEX ixName IS PRIMARY UNIQUE ClassName.

    DEFINE PRIVATE STREAM sDir.
    DEFINE PRIVATE STREAM sOut.

    DEFINE PRIVATE VARIABLE iSeq       AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE dtStarted  AS DATETIME-TZ NO-UNDO.
    DEFINE PRIVATE VARIABLE lToFile    AS LOGICAL  NO-UNDO.

    /* Only run classes whose name contains this text. Empty = all. */
    DEFINE PUBLIC PROPERTY ClassFilter AS CHARACTER NO-UNDO INITIAL ""
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Passed  AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY Failed  AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY Errored AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY Skipped AS INTEGER NO-UNDO GET. PRIVATE SET.

    DEFINE PUBLIC PROPERTY Total AS INTEGER NO-UNDO
        GET():
            RETURN Passed + Failed + Errored + Skipped.
        END GET.

    DEFINE PUBLIC PROPERTY AllPassed AS LOGICAL NO-UNDO
        GET():
            RETURN Failed = 0 AND Errored = 0.
        END GET.

    CONSTRUCTOR PUBLIC TestRunner():
        dtStarted = NOW.
    END CONSTRUCTOR.

    /* ---------------------------------------------------------------- */
    /* Running                                                          */
    /* ---------------------------------------------------------------- */

    /* Run every *Test.cls under pcRoot (searched recursively). */
    METHOD PUBLIC VOID RunDirectory(INPUT pcRoot AS CHARACTER):
        DEFINE VARIABLE cRoot AS CHARACTER NO-UNDO.

        FILE-INFO:FILE-NAME = pcRoot.
        IF FILE-INFO:FULL-PATHNAME = ? OR INDEX(FILE-INFO:FILE-TYPE, "D") = 0 THEN
            UNDO, THROW NEW ArgumentError(SUBSTITUTE("Test directory not found: &1", pcRoot), "pcRoot").

        cRoot = RTRIM(NormalizePath(FILE-INFO:FULL-PATHNAME), "/").

        EMPTY TEMP-TABLE ttDir.
        EMPTY TEMP-TABLE ttClass.

        CREATE ttDir.
        ttDir.DirPath = cRoot.

        /* Breadth-first walk without recursion, so one stream suffices. */
        DO WHILE CAN-FIND(FIRST ttDir WHERE ttDir.Scanned = FALSE):
            FIND FIRST ttDir WHERE ttDir.Scanned = FALSE.
            ttDir.Scanned = TRUE.
            ScanDirectory(cRoot, ttDir.DirPath).
        END.

        FOR EACH ttClass:
            RunClass(ttClass.ClassName).
        END.
    END METHOD.

    /* Run one test class by its full name, e.g. "abl.Strings.StrFormatTest". */
    METHOD PUBLIC VOID RunClass(INPUT pcClassName AS CHARACTER):
        DEFINE VARIABLE oObj      AS Object   NO-UNDO.
        DEFINE VARIABLE oCase     AS TestCase NO-UNDO.
        DEFINE VARIABLE lReady    AS LOGICAL  NO-UNDO.
        DEFINE VARIABLE dtStart   AS DATETIME-TZ NO-UNDO.

        dtStart = NOW.

        /* Load */
        DO ON ERROR UNDO, LEAVE:
            oObj = DYNAMIC-NEW pcClassName ().
            CATCH eLoad AS Progress.Lang.Error:
                AddResult(pcClassName, "(load)", "ERROR", Elapsed(dtStart),
                          "Could not load class: " + Err:Messages(eLoad), Err:Describe(eLoad)).
            END CATCH.
        END.
        IF NOT VALID-OBJECT(oObj) THEN RETURN.

        IF NOT TYPE-OF(oObj, TestCase) THEN DO:
            AddResult(pcClassName, "(load)", "ERROR", 0,
                      "Class does not inherit abl.Testing.TestCase", "").
            RETURN.
        END.

        oCase = CAST(oObj, TestCase).
        CollectTestMethods(oObj:GetClass()).

        IF NOT CAN-FIND(FIRST ttMethod) THEN DO:
            AddResult(pcClassName, "(none)", "SKIP", 0, "No PUBLIC VOID Test* methods without parameters", "").
            RETURN.
        END.

        /* BeforeAll */
        lReady = TRUE.
        dtStart = NOW.
        DO ON ERROR UNDO, LEAVE:
            oCase:BeforeAll().
            CATCH eBefore AS Progress.Lang.Error:
                lReady = FALSE.
                AddResult(pcClassName, "BeforeAll", "ERROR", Elapsed(dtStart),
                          Err:Messages(eBefore), Err:Describe(eBefore)).
            END CATCH.
        END.

        IF lReady THEN
            FOR EACH ttMethod:
                RunTest(oCase, pcClassName, ttMethod.MethodName).
            END.

        /* AfterAll */
        dtStart = NOW.
        DO ON ERROR UNDO, LEAVE:
            oCase:AfterAll().
            CATCH eAfter AS Progress.Lang.Error:
                AddResult(pcClassName, "AfterAll", "ERROR", Elapsed(dtStart),
                          Err:Messages(eAfter), Err:Describe(eAfter)).
            END CATCH.
        END.
    END METHOD.

    /* One test: Setup, the method, Teardown, all in a transaction that is
       undone afterwards when RollbackDb is TRUE. */
    METHOD PRIVATE VOID RunTest(INPUT poCase      AS TestCase,
                                INPUT pcClassName AS CHARACTER,
                                INPUT pcMethod    AS CHARACTER):
        DEFINE VARIABLE cOutcome AS CHARACTER NO-UNDO INITIAL "PASS".
        DEFINE VARIABLE cSummary AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcDetail AS LONGCHAR  NO-UNDO.
        DEFINE VARIABLE dtStart  AS DATETIME-TZ  NO-UNDO.

        dtStart = NOW.

        TestTx:
        DO TRANSACTION:

            DO ON ERROR UNDO, LEAVE:
                poCase:Setup().
                DYNAMIC-INVOKE(poCase, pcMethod).

                CATCH eFail AS AssertionFailure:
                    ASSIGN cOutcome = "FAIL"
                           cSummary = eFail:GetMessage(1)
                           lcDetail = Err:Describe(eFail).
                END CATCH.
                CATCH eSkip AS SkipSignal:
                    ASSIGN cOutcome = "SKIP"
                           cSummary = eSkip:GetMessage(1).
                END CATCH.
                CATCH eErr AS Progress.Lang.Error:
                    ASSIGN cOutcome = "ERROR"
                           cSummary = Err:Messages(eErr)
                           lcDetail = Err:Describe(eErr).
                END CATCH.
                /* STOP conditions (lock wait timeouts, STOP-AFTER, a RUN of a
                   missing program) are catchable as objects from 11.7 when
                   the session runs with -catchStop 1. */
                CATCH eStop AS Progress.Lang.Stop:
                    ASSIGN cOutcome = "ERROR"
                           cSummary = "STOP condition: " + eStop:GetClass():TypeName.
                END CATCH.
            END.

            DO ON ERROR UNDO, LEAVE:
                poCase:Teardown().
                CATCH eDown AS Progress.Lang.Error:
                    IF cOutcome = "PASS" THEN
                        ASSIGN cOutcome = "ERROR"
                               cSummary = "Teardown failed: " + Err:Messages(eDown)
                               lcDetail = Err:Describe(eDown).
                END CATCH.
            END.

            IF poCase:RollbackDb THEN
                UNDO TestTx, LEAVE TestTx.
        END.

        AddResult(pcClassName, pcMethod, cOutcome, Elapsed(dtStart), cSummary, lcDetail).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Reporting                                                        */
    /* ---------------------------------------------------------------- */

    /* Human-readable report. pcFile = "" writes to the default output
       (stdout in batch mode). */
    METHOD PUBLIC VOID PrintReport(INPUT pcFile AS CHARACTER):
        DEFINE VARIABLE cLastClass AS CHARACTER NO-UNDO INITIAL ?.

        OpenOut(pcFile).

        FOR EACH ttResult BY ttResult.Seq:
            IF ttResult.ClassName <> cLastClass OR cLastClass = ? THEN DO:
                IF cLastClass <> ? THEN Emit("").
                Emit(ttResult.ClassName).
                cLastClass = ttResult.ClassName.
            END.
            Emit(SUBSTITUTE("  &1  &2 (&3 ms)", STRING(ttResult.Outcome, "x(5)"), ttResult.TestName, ttResult.DurationMs)).
            IF ttResult.Outcome <> "PASS" AND ttResult.Summary > "" THEN
                Emit("         " + ttResult.Summary).
        END.

        IF CAN-FIND(FIRST ttResult WHERE ttResult.Outcome = "FAIL" OR ttResult.Outcome = "ERROR") THEN DO:
            Emit("").
            Emit("---- Details ----").
            FOR EACH ttResult WHERE ttResult.Outcome = "FAIL" OR ttResult.Outcome = "ERROR" BY ttResult.Seq:
                Emit("").
                Emit(SUBSTITUTE("&1 &2:&3", ttResult.Outcome, ttResult.ClassName, ttResult.TestName)).
                Emit(ttResult.Detail).
            END.
        END.

        Emit("").
        Emit(SUBSTITUTE("Tests: &1 total, &2 passed, &3 failed, &4 errors, &5 skipped in &6 ms",
                        Total, Passed, Failed, Errored, Skipped, Elapsed(dtStarted))).
        Emit("RESULT: " + (IF AllPassed THEN "PASSED" ELSE "FAILED")).

        CloseOut().
    END METHOD.

    /* JUnit XML, the de facto CI test report format. */
    METHOD PUBLIC VOID WriteJUnit(INPUT pcFile AS CHARACTER):
        DEFINE VARIABLE lcXml      AS LONGCHAR  NO-UNDO.
        DEFINE VARIABLE cLastClass AS CHARACTER NO-UNDO INITIAL ?.
        DEFINE VARIABLE iTests     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE iFails     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE iErrors    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE iSkips     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE iMs        AS INT64     NO-UNDO.
        DEFINE BUFFER bResult FOR ttResult.

        FIX-CODEPAGE(lcXml) = "UTF-8".
        lcXml = '<?xml version="1.0" encoding="UTF-8"?>~n'
              + SUBSTITUTE('<testsuites tests="&1" failures="&2" errors="&3" skipped="&4" time="&5">~n',
                           Total, Failed, Errored, Skipped, Seconds(Elapsed(dtStarted))).

        FOR EACH ttResult BY ttResult.Seq:
            IF ttResult.ClassName <> cLastClass OR cLastClass = ? THEN DO:
                IF cLastClass <> ? THEN lcXml = lcXml + '  </testsuite>~n'.
                cLastClass = ttResult.ClassName.

                ASSIGN iTests = 0 iFails = 0 iErrors = 0 iSkips = 0 iMs = 0.
                FOR EACH bResult WHERE bResult.ClassName = cLastClass:
                    ASSIGN iTests = iTests + 1
                           iMs    = iMs + bResult.DurationMs.
                    CASE bResult.Outcome:
                        WHEN "FAIL"  THEN iFails  = iFails + 1.
                        WHEN "ERROR" THEN iErrors = iErrors + 1.
                        WHEN "SKIP"  THEN iSkips  = iSkips + 1.
                    END CASE.
                END.

                lcXml = lcXml + SUBSTITUTE('  <testsuite name="&1" tests="&2" failures="&3" errors="&4" skipped="&5" time="&6">~n',
                                           XmlEscape(cLastClass), iTests, iFails, iErrors, iSkips, Seconds(iMs)).
            END.

            lcXml = lcXml + SUBSTITUTE('    <testcase classname="&1" name="&2" time="&3"',
                                       XmlEscape(ttResult.ClassName), XmlEscape(ttResult.TestName),
                                       Seconds(ttResult.DurationMs)).
            CASE ttResult.Outcome:
                WHEN "PASS" THEN
                    lcXml = lcXml + '/>~n'.
                WHEN "SKIP" THEN
                    lcXml = lcXml + SUBSTITUTE('>~n      <skipped message="&1"/>~n    </testcase>~n',
                                               XmlEscape(ttResult.Summary)).
                OTHERWISE
                    lcXml = lcXml + SUBSTITUTE('>~n      <&1 message="&2">&3</&1>~n    </testcase>~n',
                                               (IF ttResult.Outcome = "FAIL" THEN "failure" ELSE "error"),
                                               XmlEscape(ttResult.Summary), XmlEscape(ttResult.Detail)).
            END CASE.
        END.

        IF cLastClass <> ? THEN lcXml = lcXml + '  </testsuite>~n'.
        lcXml = lcXml + '</testsuites>~n'.

        EnsureParentDir(pcFile).
        COPY-LOB FROM lcXml TO FILE pcFile.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Discovery                                                        */
    /* ---------------------------------------------------------------- */

    METHOD PRIVATE VOID ScanDirectory(INPUT pcRoot AS CHARACTER, INPUT pcDir AS CHARACTER):
        DEFINE VARIABLE cName  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFull  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cAttr  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cClass AS CHARACTER NO-UNDO.

        INPUT STREAM sDir FROM OS-DIR(pcDir).
        REPEAT:
            IMPORT STREAM sDir cName cFull cAttr.
            IF cName = "." OR cName = ".." THEN NEXT.
            cFull = NormalizePath(cFull).

            IF INDEX(cAttr, "D") > 0 THEN DO:
                IF NOT CAN-FIND(ttDir WHERE ttDir.DirPath = cFull) THEN DO:
                    CREATE ttDir.
                    ttDir.DirPath = cFull.
                END.
            END.
            ELSE IF INDEX(cAttr, "F") > 0 AND cName MATCHES "*Test.cls" THEN DO:
                /* tests/abl/Strings/StrFormatTest.cls -> abl.Strings.StrFormatTest */
                cClass = SUBSTRING(cFull, LENGTH(pcRoot) + 2).
                cClass = SUBSTRING(cClass, 1, LENGTH(cClass) - 4).
                cClass = REPLACE(cClass, "/", ".").

                IF (ClassFilter = "" OR INDEX(cClass, ClassFilter) > 0)
                   AND NOT CAN-FIND(ttClass WHERE ttClass.ClassName = cClass) THEN DO:
                    CREATE ttClass.
                    ttClass.ClassName = cClass.
                END.
            END.
        END.
        INPUT STREAM sDir CLOSE.
    END METHOD.

    METHOD PRIVATE VOID CollectTestMethods(INPUT poClass AS Progress.Lang.Class):
        DEFINE VARIABLE oMethods AS Progress.Reflect.Method EXTENT NO-UNDO.
        DEFINE VARIABLE i        AS INTEGER NO-UNDO.

        EMPTY TEMP-TABLE ttMethod.

        oMethods = poClass:GetMethods(Progress.Reflect.Flags:Public OR Progress.Reflect.Flags:Instance).
        IF EXTENT(oMethods) = ? THEN RETURN.

        DO i = 1 TO EXTENT(oMethods):
            IF NOT oMethods[i]:Name BEGINS "Test" THEN NEXT.
            IF NOT TakesNoParameters(oMethods[i]) THEN NEXT.
            IF CAN-FIND(ttMethod WHERE ttMethod.MethodName = oMethods[i]:Name) THEN NEXT.
            CREATE ttMethod.
            ttMethod.MethodName = oMethods[i]:Name.
        END.
    END METHOD.

    /* Separate method so the indeterminate array is fresh on every call. */
    METHOD PRIVATE LOGICAL TakesNoParameters(INPUT poMethod AS Progress.Reflect.Method):
        DEFINE VARIABLE oParams AS Progress.Reflect.Parameter EXTENT NO-UNDO.
        oParams = poMethod:GetParameters().
        RETURN EXTENT(oParams) = ? OR EXTENT(oParams) = 0.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Helpers                                                          */
    /* ---------------------------------------------------------------- */

    METHOD PRIVATE VOID AddResult(INPUT pcClassName AS CHARACTER,
                                  INPUT pcTestName  AS CHARACTER,
                                  INPUT pcOutcome   AS CHARACTER,
                                  INPUT piMs        AS INT64,
                                  INPUT pcSummary   AS CHARACTER,
                                  INPUT plcDetail   AS LONGCHAR):
        DEFINE VARIABLE cDetail AS CHARACTER NO-UNDO.

        IF plcDetail <> ? THEN
            cDetail = SUBSTRING(plcDetail, 1, 30000).

        iSeq = iSeq + 1.
        CREATE ttResult.
        ASSIGN ttResult.Seq        = iSeq
               ttResult.ClassName  = pcClassName
               ttResult.TestName   = pcTestName
               ttResult.Outcome    = pcOutcome
               ttResult.DurationMs = piMs
               ttResult.Summary    = (IF pcSummary = ? THEN "" ELSE SUBSTRING(pcSummary, 1, 2000))
               ttResult.Detail     = cDetail.

        CASE pcOutcome:
            WHEN "PASS"  THEN Passed  = Passed + 1.
            WHEN "FAIL"  THEN Failed  = Failed + 1.
            WHEN "ERROR" THEN Errored = Errored + 1.
            WHEN "SKIP"  THEN Skipped = Skipped + 1.
        END CASE.
    END METHOD.

    METHOD PRIVATE INT64 Elapsed(INPUT pdtStart AS DATETIME-TZ):
        RETURN INTERVAL(NOW, pdtStart, "milliseconds").
    END METHOD.

    /* Milliseconds as "1.234", independent of SESSION:NUMERIC-FORMAT. */
    METHOD PRIVATE CHARACTER Seconds(INPUT piMs AS INT64):
        RETURN STRING(TRUNCATE(piMs / 1000, 0)) + "." + STRING(piMs MOD 1000, "999").
    END METHOD.

    METHOD PRIVATE CHARACTER NormalizePath(INPUT pcPath AS CHARACTER):
        RETURN REPLACE(pcPath, CHR(92), "/").
    END METHOD.

    METHOD PRIVATE CHARACTER XmlEscape(INPUT pcText AS CHARACTER):
        IF pcText = ? THEN RETURN "".
        pcText = REPLACE(pcText, "&", "&amp;").
        pcText = REPLACE(pcText, "<", "&lt;").
        pcText = REPLACE(pcText, ">", "&gt;").
        pcText = REPLACE(pcText, '"', "&quot;").
        pcText = REPLACE(pcText, "'", "&apos;").
        RETURN pcText.
    END METHOD.

    METHOD PRIVATE VOID EnsureParentDir(INPUT pcFile AS CHARACTER):
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iSep  AS INTEGER   NO-UNDO.

        cPath = NormalizePath(pcFile).
        iSep  = R-INDEX(cPath, "/").
        IF iSep > 1 THEN
            OS-CREATE-DIR VALUE(SUBSTRING(cPath, 1, iSep - 1)).
    END METHOD.

    METHOD PRIVATE VOID OpenOut(INPUT pcFile AS CHARACTER):
        lToFile = (pcFile > "").
        IF lToFile THEN DO:
            EnsureParentDir(pcFile).
            OUTPUT STREAM sOut TO VALUE(pcFile).
        END.
    END METHOD.

    METHOD PRIVATE VOID CloseOut():
        IF lToFile THEN OUTPUT STREAM sOut CLOSE.
        lToFile = FALSE.
    END METHOD.

    METHOD PRIVATE VOID Emit(INPUT pcLine AS CHARACTER):
        IF lToFile THEN
            PUT STREAM sOut UNFORMATTED pcLine SKIP.
        ELSE
            PUT UNFORMATTED pcLine SKIP.
    END METHOD.

END CLASS.
