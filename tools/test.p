/*------------------------------------------------------------------------
    File        : tools/test.p
    Purpose     : Bootstrap for the test runner. Puts src and tests on
                  PROPATH, then runs abl/Testing/RunTests.p. It must not
                  reference any abl class itself, because those cannot
                  be found until PROPATH is set.

    Usage (from the repo root):
        _progres -b -p tools/test.p -errorstack -catchStop 1
        _progres -b -p tools/test.p -param "filter=Strings" -errorstack -catchStop 1
        _progres -b -p tools/test.p -param "junit=build/test-results/junit.xml" -errorstack -catchStop 1

    All -param options are passed through; see abl/Testing/RunTests.p.
------------------------------------------------------------------------*/
PROPATH = "src,tests," + PROPATH.
RUN abl/Testing/RunTests.p.
QUIT.
