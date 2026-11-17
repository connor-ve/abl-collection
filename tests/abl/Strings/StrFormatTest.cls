/*------------------------------------------------------------------------
    File        : tests/abl/Strings/StrFormatTest.cls
    Purpose     : Tests for Str:Format and Args.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Json.ObjectModel.JsonObject.
USING abl.Errors.ArgumentError.
USING abl.Strings.Args.
USING abl.Strings.Str.
USING abl.Testing.TestCase.

CLASS abl.Strings.StrFormatTest INHERITS TestCase:

    DEFINE PRIVATE VARIABLE cSavedNumFormat  AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cSavedDateFormat AS CHARACTER NO-UNDO.

    /* Masks depend on session formats; pin them so results are stable. */
    METHOD PUBLIC OVERRIDE VOID BeforeAll():
        ASSIGN cSavedNumFormat        = SESSION:NUMERIC-FORMAT
               cSavedDateFormat       = SESSION:DATE-FORMAT
               SESSION:NUMERIC-FORMAT = "American"
               SESSION:DATE-FORMAT    = "mdy".
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID AfterAll():
        ASSIGN SESSION:NUMERIC-FORMAT = cSavedNumFormat
               SESSION:DATE-FORMAT    = cSavedDateFormat.
    END METHOD.

    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestSinglePlaceholder():
        Expect(Str:Format("Hello [name]", Args:Of("name", "World"))):ToEqualExact("Hello World").
    END METHOD.

    METHOD PUBLIC VOID TestRepeatedAndMultiple():
        Expect(Str:Format("[a]-[b]-[a]", Args:Of("a", "x"):Add("b", "y"))):ToEqualExact("x-y-x").
    END METHOD.

    METHOD PUBLIC VOID TestNoPlaceholdersReturnsTemplate():
        Expect(Str:Format("plain text", Args:Of("unused", 1))):ToEqualExact("plain text").
    END METHOD.

    METHOD PUBLIC VOID TestEmptyTemplate():
        Expect(Str:Format("", Args:Of("a", 1))):ToBeEmpty().
    END METHOD.

    /* The reason this exists: SUBSTITUTE stops at 9. */
    METHOD PUBLIC VOID TestMoreThanNineValues():
        DEFINE VARIABLE oArgs     AS Args      NO-UNDO.
        DEFINE VARIABLE cTemplate AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cExpected AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i         AS INTEGER   NO-UNDO.

        oArgs = NEW Args().
        DO i = 1 TO 15:
            oArgs:Add("p" + STRING(i), i).
            ASSIGN cTemplate = cTemplate + (IF i > 1 THEN " " ELSE "") + "[p" + STRING(i) + "]"
                   cExpected = cExpected + (IF i > 1 THEN " " ELSE "") + STRING(i).
        END.

        Expect(oArgs:Count):ToEqual(15).
        Expect(Str:Format(cTemplate, oArgs)):ToEqualExact(cExpected).
    END METHOD.

    METHOD PUBLIC VOID TestNamesAreCaseInsensitiveAndTrimmed():
        Expect(Str:Format("[ NAME ]", Args:Of("name", "ok"))):ToEqualExact("ok").
    END METHOD.

    METHOD PUBLIC VOID TestAddReplacesExistingName():
        DEFINE VARIABLE oArgs AS Args NO-UNDO.
        oArgs = Args:Of("a", "first"):Add("a", "second").
        Expect(oArgs:Count):ToEqual(1).
        Expect(Str:Format("[a]", oArgs)):ToEqualExact("second").
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Masks                                                            */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestDecimalMask():
        Expect(Str:Format("[amt:>>>,>>9.99]", Args:Of("amt", 1234.5))):ToEqualExact("  1,234.50").
    END METHOD.

    METHOD PUBLIC VOID TestIntegerMaskWithColonInside():
        /* Only the first colon separates name from mask. */
        Expect(Str:Format("[t:99:99]", Args:Of("t", 930))):ToEqualExact("09:30").
    END METHOD.

    METHOD PUBLIC VOID TestCharacterMaskTruncates():
        Expect(Str:Format("[c:x(3)]", Args:Of("c", "abcdef"))):ToEqualExact("abc").
    END METHOD.

    METHOD PUBLIC VOID TestLogicalMask():
        Expect(Str:Format("[ok:on/off]", Args:Of("ok", TRUE))):ToEqualExact("on").
    END METHOD.

    METHOD PUBLIC VOID TestDateMask():
        Expect(Str:Format("[d:99/99/9999]", Args:Of("d", DATE(3, 15, 2026)))):ToEqualExact("03/15/2026").
    END METHOD.

    METHOD PUBLIC VOID TestDateIso():
        Expect(Str:Format("[d:iso]", Args:Of("d", DATE(3, 15, 2026)))):ToEqualExact("2026-03-15").
    END METHOD.

    METHOD PUBLIC VOID TestValueTooBigForMaskThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            Str:Format("[n:99]", Args:Of("n", 12345)).
            CATCH e AS Progress.Lang.Error:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveErrorCode("Format").
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* Escapes and errors                                               */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestEscapedBrackets():
        Expect(Str:Format("[[literal]] [x]", Args:Of("x", 1))):ToEqualExact("[literal] 1").
    END METHOD.

    METHOD PUBLIC VOID TestUnknownValuePrintsQuestionMark():
        DEFINE VARIABLE cNull AS CHARACTER NO-UNDO INITIAL ?.
        Expect(Str:Format("v=[v]", Args:Of("v", cNull))):ToEqualExact("v=?").
    END METHOD.

    METHOD PUBLIC VOID TestMissingValueThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            Str:Format("Hi [nope]", Args:Of("name", "x")).
            CATCH e AS ArgumentError:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveErrorCode("Argument"):ToHaveMessage("nope").
    END METHOD.

    METHOD PUBLIC VOID TestUnclosedBracketThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            Str:Format("Hi [name", Args:Of("name", "x")).
            CATCH e AS ArgumentError:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveMessage("Unclosed").
    END METHOD.

    METHOD PUBLIC VOID TestStrayClosingBracketThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            Str:Format("a ] b", Args:Of("x", 1)).
            CATCH e AS ArgumentError:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveMessage("Unmatched").
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* JSON input and LONGCHAR                                          */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestFormatFromJsonObject():
        DEFINE VARIABLE oJson AS JsonObject NO-UNDO.
        oJson = NEW JsonObject().
        oJson:Add("name", "Ann").
        oJson:Add("count", 3).
        oJson:Add("active", TRUE).
        Expect(Str:Format("[name] has [count] ([active:yes/no])", oJson)):ToEqualExact("Ann has 3 (yes)").
    END METHOD.

    METHOD PUBLIC VOID TestFormatLongBeyondCharacterLimit():
        DEFINE VARIABLE lcTemplate AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE lcOut      AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE i          AS INTEGER  NO-UNDO.

        DO i = 1 TO 4000:
            lcTemplate = lcTemplate + "[w] ".
        END.
        lcOut = Str:FormatLong(lcTemplate, Args:Of("w", "word-wide")).

        /* 4000 x "word-wide " = 40000 characters, past the 32K CHARACTER limit. */
        Expect(LENGTH(lcOut)):ToEqual(40000).
    END METHOD.

    /* ---------------------------------------------------------------- */
    /* EqualsExact                                                      */
    /* ---------------------------------------------------------------- */

    METHOD PUBLIC VOID TestEqualsExactIsCaseSensitive():
        Expect(Str:EqualsExact("abc", "abc")):ToBeTrue().
        Expect(Str:EqualsExact("abc", "ABC")):ToBeFalse().
        Expect(Str:EqualsExact("abc", "abc ")):ToBeFalse().
    END METHOD.

END CLASS.
