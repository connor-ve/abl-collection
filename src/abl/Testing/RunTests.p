/*------------------------------------------------------------------------
    File        : abl/Testing/RunTests.p
    Purpose     : Command-line entry point for the test runner.

    Usage (batch, from the repo root) - through the bootstrap, which puts
    src and tests on PROPATH first:
        _progres -b -p tools/test.p -param "dir=tests" -errorstack -catchStop 1
        (Windows: prowin -b ... works the same; prowin32 for 32-bit.)

    Or RUN it from any session whose PROPATH already has the library
    and the test folder.

    Parameters (comma-separated key=value, all optional):
        dir=tests                   directory to search for *Test.cls
        class=abl.Strings.StrFormatTest
                                    run one class instead of a directory
        filter=Strings              only classes whose name contains this
        junit=build/test-results/junit.xml
                                    also write a JUnit XML report
        report=build/test-results/report.txt
                                    write the text report to a file
                                    instead of stdout

    Recommended startup parameters:
        -errorstack     include call stacks in failure details
        -catchStop 1    report STOP conditions as test errors (11.7)

    The last line of output is "RESULT: PASSED" or "RESULT: FAILED",
    which a CI script can search for. The JUnit file is the better
    source for CI dashboards.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Errors.Err.
USING abl.Testing.TestRunner.

DEFINE VARIABLE oRunner AS TestRunner NO-UNDO.
DEFINE VARIABLE cDir    AS CHARACTER  NO-UNDO INITIAL "tests".
DEFINE VARIABLE cClass  AS CHARACTER  NO-UNDO.
DEFINE VARIABLE cFilter AS CHARACTER  NO-UNDO.
DEFINE VARIABLE cJUnit  AS CHARACTER  NO-UNDO.
DEFINE VARIABLE cReport AS CHARACTER  NO-UNDO.
DEFINE VARIABLE cEntry  AS CHARACTER  NO-UNDO.
DEFINE VARIABLE cKey    AS CHARACTER  NO-UNDO.
DEFINE VARIABLE cValue  AS CHARACTER  NO-UNDO.
DEFINE VARIABLE i       AS INTEGER    NO-UNDO.

DO i = 1 TO NUM-ENTRIES(SESSION:PARAMETER):
    cEntry = TRIM(ENTRY(i, SESSION:PARAMETER)).
    IF NUM-ENTRIES(cEntry, "=") < 2 THEN NEXT.

    ASSIGN cKey   = TRIM(ENTRY(1, cEntry, "="))
           cValue = TRIM(SUBSTRING(cEntry, INDEX(cEntry, "=") + 1)).

    CASE cKey:
        WHEN "dir"    THEN cDir    = cValue.
        WHEN "class"  THEN cClass  = cValue.
        WHEN "filter" THEN cFilter = cValue.
        WHEN "junit"  THEN cJUnit  = cValue.
        WHEN "report" THEN cReport = cValue.
    END CASE.
END.

DO ON ERROR UNDO, LEAVE:
    oRunner = NEW TestRunner().
    oRunner:ClassFilter = cFilter.

    IF cClass > "" THEN
        oRunner:RunClass(cClass).
    ELSE
        oRunner:RunDirectory(cDir).

    oRunner:PrintReport(cReport).
    IF cJUnit > "" THEN
        oRunner:WriteJUnit(cJUnit).

    CATCH e AS Progress.Lang.Error:
        cValue = SUBSTRING(Err:Describe(e), 1, 30000).
        PUT UNFORMATTED "Test run aborted: " cValue SKIP.
        PUT UNFORMATTED "RESULT: FAILED" SKIP.
    END CATCH.
END.
