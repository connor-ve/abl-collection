/*------------------------------------------------------------------------
    File        : abl/Testing/Expectation.cls
    Purpose     : Fluent checks on one value. Created by TestCase:Expect().
                  Every check returns the expectation, so checks chain:
                      Expect(cName):ToBeKnown():ToStartWith("A").
                  A failed check throws AssertionFailure.
    Notes       : ToEqual follows ABL equality: numbers compare by value
                  across INTEGER/INT64/DECIMAL; text ignores case and
                  trailing blanks. Use ToEqualExact for case-sensitive.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.Object.
USING abl.Core.Box.
USING abl.Errors.Err.
USING abl.Strings.Str.
USING abl.Testing.AssertionFailure.

CLASS abl.Testing.Expectation:

    DEFINE PRIVATE VARIABLE oActual AS Box NO-UNDO.

    CONSTRUCTOR PUBLIC Expectation(INPUT poActual AS Box):
        oActual = poActual.
    END CONSTRUCTOR.

    /* ---------------------------------------------------------------- */
    /* Equality                                                         */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC Expectation ToEqual(INPUT pcExpected AS CHARACTER):
        RETURN CheckEqual(NEW Box(pcExpected), TRUE).
    END METHOD.

    METHOD PUBLIC Expectation ToEqual(INPUT plcExpected AS LONGCHAR):
        RETURN CheckEqual(NEW Box(plcExpected), TRUE).
    END METHOD.

    METHOD PUBLIC Expectation ToEqual(INPUT piExpected AS INTEGER):
        RETURN CheckEqual(NEW Box(piExpected), TRUE).
    END METHOD.

    METHOD PUBLIC Expectation ToEqual(INPUT piExpected AS INT64):
        RETURN CheckEqual(NEW Box(piExpected), TRUE).
    END METHOD.

    METHOD PUBLIC Expectation ToEqual(INPUT pdExpected AS DECIMAL):
        RETURN CheckEqual(NEW Box(pdExpected), TRUE).
    END METHOD.

    METHOD PUBLIC Expectation ToEqual(INPUT plExpected AS LOGICAL):
        RETURN CheckEqual(NEW Box(plExpected), TRUE).
    END METHOD.

    METHOD PUBLIC Expectation ToEqual(INPUT pdaExpected AS DATE):
        RETURN CheckEqual(NEW Box(pdaExpected), TRUE).
    END METHOD.

    METHOD PUBLIC Expectation ToEqual(INPUT pdtExpected AS DATETIME):
        RETURN CheckEqual(NEW Box(pdtExpected), TRUE).
    END METHOD.

    METHOD PUBLIC Expectation ToEqual(INPUT pdtzExpected AS DATETIME-TZ):
        RETURN CheckEqual(NEW Box(pdtzExpected), TRUE).
    END METHOD.

    METHOD PUBLIC Expectation ToEqual(INPUT phExpected AS HANDLE):
        RETURN CheckEqual(NEW Box(phExpected), TRUE).
    END METHOD.

    /* Objects compare with Equals(); a Box is compared by its value. */
    METHOD PUBLIC Expectation ToEqual(INPUT poExpected AS Object):
        RETURN CheckEqual(ToBox(poExpected), TRUE).
    END METHOD.

    METHOD PUBLIC Expectation ToNotEqual(INPUT pcExpected AS CHARACTER):
        RETURN CheckEqual(NEW Box(pcExpected), FALSE).
    END METHOD.

    METHOD PUBLIC Expectation ToNotEqual(INPUT piExpected AS INTEGER):
        RETURN CheckEqual(NEW Box(piExpected), FALSE).
    END METHOD.

    METHOD PUBLIC Expectation ToNotEqual(INPUT piExpected AS INT64):
        RETURN CheckEqual(NEW Box(piExpected), FALSE).
    END METHOD.

    METHOD PUBLIC Expectation ToNotEqual(INPUT pdExpected AS DECIMAL):
        RETURN CheckEqual(NEW Box(pdExpected), FALSE).
    END METHOD.

    METHOD PUBLIC Expectation ToNotEqual(INPUT plExpected AS LOGICAL):
        RETURN CheckEqual(NEW Box(plExpected), FALSE).
    END METHOD.

    METHOD PUBLIC Expectation ToNotEqual(INPUT pdaExpected AS DATE):
        RETURN CheckEqual(NEW Box(pdaExpected), FALSE).
    END METHOD.

    METHOD PUBLIC Expectation ToNotEqual(INPUT poExpected AS Object):
        RETURN CheckEqual(ToBox(poExpected), FALSE).
    END METHOD.

    /* Case-sensitive text equality. CHARACTER arguments widen to LONGCHAR. */
    METHOD PUBLIC Expectation ToEqualExact(INPUT plcExpected AS LONGCHAR):
        DEFINE VARIABLE oExpected AS Box NO-UNDO.
        RequireText("ToEqualExact").
        IF NOT Str:EqualsExact(oActual:AsLongchar(), plcExpected) THEN DO:
            oExpected = NEW Box(plcExpected).
            FailWith(SUBSTITUTE("Expected &1 to equal &2 exactly (case-sensitive)",
                                oActual:Describe(), oExpected:Describe())).
        END.
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Unknown / logical                                                */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC Expectation ToBeUnknown():
        IF NOT oActual:IsUnknown THEN
            FailWith(SUBSTITUTE("Expected unknown (?) but got &1", oActual:Describe())).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC Expectation ToBeKnown():
        IF oActual:IsUnknown THEN
            FailWith(SUBSTITUTE("Expected a value but got &1", oActual:Describe())).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC Expectation ToBeTrue():
        IF NOT IsLogical(TRUE) THEN
            FailWith(SUBSTITUTE("Expected TRUE but got &1", oActual:Describe())).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC Expectation ToBeFalse():
        IF NOT IsLogical(FALSE) THEN
            FailWith(SUBSTITUTE("Expected FALSE but got &1", oActual:Describe())).
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Numbers                                                          */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC Expectation ToBeGreaterThan(INPUT pdLimit AS DECIMAL):
        RequireNumber("ToBeGreaterThan").
        IF NOT (oActual:AsDecimal() > pdLimit) THEN
            FailWith(SUBSTITUTE("Expected &1 to be greater than &2", oActual:Describe(), pdLimit)).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC Expectation ToBeAtLeast(INPUT pdLimit AS DECIMAL):
        RequireNumber("ToBeAtLeast").
        IF NOT (oActual:AsDecimal() >= pdLimit) THEN
            FailWith(SUBSTITUTE("Expected &1 to be at least &2", oActual:Describe(), pdLimit)).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC Expectation ToBeLessThan(INPUT pdLimit AS DECIMAL):
        RequireNumber("ToBeLessThan").
        IF NOT (oActual:AsDecimal() < pdLimit) THEN
            FailWith(SUBSTITUTE("Expected &1 to be less than &2", oActual:Describe(), pdLimit)).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC Expectation ToBeAtMost(INPUT pdLimit AS DECIMAL):
        RequireNumber("ToBeAtMost").
        IF NOT (oActual:AsDecimal() <= pdLimit) THEN
            FailWith(SUBSTITUTE("Expected &1 to be at most &2", oActual:Describe(), pdLimit)).
        RETURN THIS-OBJECT.
    END METHOD.

    /* Inclusive on both ends. */
    METHOD PUBLIC Expectation ToBeBetween(INPUT pdMin AS DECIMAL, INPUT pdMax AS DECIMAL):
        DEFINE VARIABLE dVal AS DECIMAL NO-UNDO.
        RequireNumber("ToBeBetween").
        dVal = oActual:AsDecimal().
        IF dVal < pdMin OR dVal > pdMax THEN
            FailWith(SUBSTITUTE("Expected &1 to be between &2 and &3", oActual:Describe(), pdMin, pdMax)).
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Text                                                             */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC Expectation ToContain(INPUT pcPart AS CHARACTER):
        RequireText("ToContain").
        IF INDEX(oActual:AsLongchar(), pcPart) = 0 THEN
            FailWith(SUBSTITUTE("Expected &1 to contain &2", oActual:Describe(), Quoted(pcPart))).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC Expectation ToNotContain(INPUT pcPart AS CHARACTER):
        RequireText("ToNotContain").
        IF INDEX(oActual:AsLongchar(), pcPart) > 0 THEN
            FailWith(SUBSTITUTE("Expected &1 not to contain &2", oActual:Describe(), Quoted(pcPart))).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC Expectation ToStartWith(INPUT pcPrefix AS CHARACTER):
        DEFINE VARIABLE cHead AS CHARACTER NO-UNDO.
        RequireText("ToStartWith").
        cHead = SUBSTRING(oActual:AsLongchar(), 1, LENGTH(pcPrefix)).
        IF cHead <> pcPrefix THEN
            FailWith(SUBSTITUTE("Expected &1 to start with &2", oActual:Describe(), Quoted(pcPrefix))).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC Expectation ToEndWith(INPUT pcSuffix AS CHARACTER):
        DEFINE VARIABLE lcVal AS LONGCHAR  NO-UNDO.
        DEFINE VARIABLE cTail AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iLen  AS INT64     NO-UNDO.
        RequireText("ToEndWith").
        ASSIGN lcVal = oActual:AsLongchar()
               iLen  = LENGTH(lcVal).
        IF iLen >= LENGTH(pcSuffix) THEN
            cTail = SUBSTRING(lcVal, iLen - LENGTH(pcSuffix) + 1).
        IF iLen < LENGTH(pcSuffix) OR cTail <> pcSuffix THEN
            FailWith(SUBSTITUTE("Expected &1 to end with &2", oActual:Describe(), Quoted(pcSuffix))).
        RETURN THIS-OBJECT.
    END METHOD.

    /* ABL MATCHES pattern: * any characters, . one character. */
    METHOD PUBLIC Expectation ToMatch(INPUT pcPattern AS CHARACTER):
        RequireText("ToMatch").
        IF NOT (oActual:AsCharacter() MATCHES pcPattern) THEN
            FailWith(SUBSTITUTE("Expected &1 to match &2", oActual:Describe(), Quoted(pcPattern))).
        RETURN THIS-OBJECT.
    END METHOD.

    /* Empty string; unknown is not empty. */
    METHOD PUBLIC Expectation ToBeEmpty():
        RequireText("ToBeEmpty").
        IF oActual:IsUnknown THEN
            FailWith(SUBSTITUTE("Expected an empty string but got &1", oActual:Describe())).
        IF LENGTH(oActual:AsLongchar()) > 0 THEN
            FailWith(SUBSTITUTE("Expected an empty string but got &1", oActual:Describe())).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC Expectation ToHaveLength(INPUT piLength AS INT64):
        RequireText("ToHaveLength").
        IF LENGTH(oActual:AsLongchar()) <> piLength THEN
            FailWith(SUBSTITUTE("Expected length &1 but &2 has length &3",
                                piLength, oActual:Describe(), LENGTH(oActual:AsLongchar()))).
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Objects and handles                                              */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC Expectation ToBeValidObject():
        IF oActual:DataType <> "OBJECT" OR oActual:IsUnknown THEN
            FailWith(SUBSTITUTE("Expected a valid object but got &1", oActual:Describe())).
        RETURN THIS-OBJECT.
    END METHOD.

    /* The object is pcTypeName or inherits/implements it. */
    METHOD PUBLIC Expectation ToBeInstanceOf(INPUT pcTypeName AS CHARACTER):
        ToBeValidObject().
        IF NOT oActual:AsObject():GetClass():IsA(pcTypeName) THEN
            FailWith(SUBSTITUTE("Expected an instance of &1 but got &2", pcTypeName, oActual:Describe())).
        RETURN THIS-OBJECT.
    END METHOD.

    /* Same reference, not just Equals(). */
    METHOD PUBLIC Expectation ToBeSameAs(INPUT poExpected AS Object):
        DEFINE VARIABLE lSame AS LOGICAL NO-UNDO.
        IF oActual:DataType = "OBJECT" THEN
            lSame = (oActual:AsObject() = poExpected).
        IF lSame <> TRUE THEN
            FailWith(SUBSTITUTE("Expected the same object reference as &1 but got &2",
                                ToBox(poExpected):Describe(), oActual:Describe())).
        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC Expectation ToBeValidHandle():
        DEFINE VARIABLE lValid AS LOGICAL NO-UNDO.
        IF oActual:DataType = "HANDLE" THEN
            lValid = VALID-HANDLE(oActual:AsHandle()).
        IF NOT lValid THEN
            FailWith(SUBSTITUTE("Expected a valid handle but got &1", oActual:Describe())).
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Errors                                                           */
    /* ---------------------------------------------------------------- */

    /* The value is an error whose chain has a AblError with this Code. */
    METHOD PUBLIC Expectation ToHaveErrorCode(INPUT pcCode AS CHARACTER):
        RequireError("ToHaveErrorCode").
        IF NOT Err:Is(CAST(oActual:AsObject(), Progress.Lang.Error), pcCode) THEN
            FailWith(SUBSTITUTE("Expected an error with code &1 but got: &2",
                                Quoted(pcCode), Err:Messages(CAST(oActual:AsObject(), Progress.Lang.Error)))).
        RETURN THIS-OBJECT.
    END METHOD.

    /* The value is an error and one of its messages contains pcPart. */
    METHOD PUBLIC Expectation ToHaveMessage(INPUT pcPart AS CHARACTER):
        DEFINE VARIABLE cMsgs AS CHARACTER NO-UNDO.
        RequireError("ToHaveMessage").
        cMsgs = Err:Messages(CAST(oActual:AsObject(), Progress.Lang.Error)).
        IF INDEX(cMsgs, pcPart) = 0 THEN
            FailWith(SUBSTITUTE("Expected error message to contain &1 but got: &2", Quoted(pcPart), cMsgs)).
        RETURN THIS-OBJECT.
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Internals                                                        */
    /* ---------------------------------------------------------------- */

    METHOD PRIVATE Expectation CheckEqual(INPUT poExpected AS Box, INPUT plWantEqual AS LOGICAL):
        DEFINE VARIABLE lEqual AS LOGICAL NO-UNDO.

        lEqual = oActual:Equals(poExpected).

        IF plWantEqual AND NOT lEqual THEN
            FailWith(SUBSTITUTE("Expected &1 but got &2", poExpected:Describe(), oActual:Describe())).
        IF NOT plWantEqual AND lEqual THEN
            FailWith(SUBSTITUTE("Expected anything except &1", poExpected:Describe())).

        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PRIVATE Box ToBox(INPUT poValue AS Object):
        IF VALID-OBJECT(poValue) AND TYPE-OF(poValue, Box) THEN
            RETURN CAST(poValue, Box).
        RETURN NEW Box(poValue).
    END METHOD.

    METHOD PRIVATE LOGICAL IsLogical(INPUT plWanted AS LOGICAL):
        IF oActual:DataType <> "LOGICAL" THEN RETURN FALSE.
        RETURN oActual:AsLogical() = plWanted.
    END METHOD.

    METHOD PRIVATE VOID RequireText(INPUT pcCheck AS CHARACTER):
        IF NOT oActual:IsText THEN
            FailWith(SUBSTITUTE("&1 needs text but got &2", pcCheck, oActual:Describe())).
        IF oActual:IsUnknown AND pcCheck <> "ToBeEmpty" AND pcCheck <> "ToEqualExact" THEN
            FailWith(SUBSTITUTE("&1 needs text but got &2", pcCheck, oActual:Describe())).
    END METHOD.

    METHOD PRIVATE VOID RequireNumber(INPUT pcCheck AS CHARACTER):
        IF NOT oActual:IsNumeric OR oActual:IsUnknown THEN
            FailWith(SUBSTITUTE("&1 needs a number but got &2", pcCheck, oActual:Describe())).
    END METHOD.

    METHOD PRIVATE VOID RequireError(INPUT pcCheck AS CHARACTER):
        IF oActual:DataType <> "OBJECT" OR oActual:IsUnknown THEN
            FailWith(SUBSTITUTE("&1 needs an error object but got &2", pcCheck, oActual:Describe())).
        IF NOT TYPE-OF(oActual:AsObject(), Progress.Lang.Error) THEN
            FailWith(SUBSTITUTE("&1 needs an error object but got &2", pcCheck, oActual:Describe())).
    END METHOD.

    METHOD PRIVATE CHARACTER Quoted(INPUT pcText AS CHARACTER):
        RETURN '"' + pcText + '"'.
    END METHOD.

    METHOD PRIVATE VOID FailWith(INPUT pcMessage AS CHARACTER):
        UNDO, THROW NEW AssertionFailure(pcMessage).
    END METHOD.

END CLASS.
