/*------------------------------------------------------------------------
    File        : tests/abl/Core/BoxTest.cls
    Purpose     : Tests for abl.Core.Box.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Core.Box.
USING abl.Testing.TestCase.

CLASS abl.Core.BoxTest INHERITS TestCase:

    METHOD PUBLIC VOID TestDataTypeIsRecorded():
        DEFINE VARIABLE oA AS Box NO-UNDO.
        oA = NEW Box("a").
        Expect(oA:DataType):ToEqual("CHARACTER").
        oA = NEW Box(NOW).
        Expect(oA:DataType):ToEqual("DATETIME-TZ").
    END METHOD.

    METHOD PUBLIC VOID TestNumbersCompareAcrossTypes():
        DEFINE VARIABLE oInt AS Box NO-UNDO.
        DEFINE VARIABLE oDec AS Box NO-UNDO.
        ASSIGN oInt = NEW Box(5)
               oDec = NEW Box(5.0).
        Expect(oInt:Equals(oDec)):ToBeTrue().
        Expect(oInt:DataType):ToEqual("INTEGER").
        Expect(oDec:DataType):ToEqual("DECIMAL").
    END METHOD.

    METHOD PUBLIC VOID TestTextEqualityIgnoresCase():
        DEFINE VARIABLE oA AS Box NO-UNDO.
        DEFINE VARIABLE oB AS Box NO-UNDO.
        ASSIGN oA = NEW Box("Hello")
               oB = NEW Box("HELLO").
        Expect(oA:Equals(oB)):ToBeTrue().
    END METHOD.

    METHOD PUBLIC VOID TestDifferentTypesAreNotEqual():
        DEFINE VARIABLE oA AS Box NO-UNDO.
        DEFINE VARIABLE oB AS Box NO-UNDO.
        ASSIGN oA = NEW Box("5")
               oB = NEW Box(5).
        Expect(oA:Equals(oB)):ToBeFalse().
    END METHOD.

    METHOD PUBLIC VOID TestUnknownHandling():
        DEFINE VARIABLE iNull AS INTEGER NO-UNDO INITIAL ?.
        DEFINE VARIABLE oA    AS Box     NO-UNDO.
        ASSIGN oA = NEW Box(iNull).
        Expect(oA:IsUnknown):ToBeTrue().
        Expect(oA:ToString()):ToEqual("?").
        Expect(oA:Equals(Box:OfUnknown())):ToBeTrue().
        Expect(oA:Equals(NEW Box(0))):ToBeFalse().
    END METHOD.

    METHOD PUBLIC VOID TestDescribe():
        DEFINE VARIABLE oA AS Box NO-UNDO.
        oA = NEW Box("abc").
        Expect(oA:Describe()):ToEqualExact('"abc" (CHARACTER)').
        oA = NEW Box(42).
        Expect(oA:Describe()):ToEqualExact("42 (INTEGER)").
    END METHOD.

    METHOD PUBLIC VOID TestIsoMaskOnDate():
        DEFINE VARIABLE oA AS Box NO-UNDO.
        oA = NEW Box(DATE(1, 2, 2026)).
        Expect(oA:ToString("iso")):ToEqualExact("2026-01-02").
    END METHOD.

    METHOD PUBLIC VOID TestAsDecimalOnTextThrows():
        DEFINE VARIABLE oCaught AS Progress.Lang.Error NO-UNDO.
        DEFINE VARIABLE oA      AS Box                 NO-UNDO.
        DEFINE VARIABLE dValue  AS DECIMAL             NO-UNDO.
        oA = NEW Box("x").
        DO ON ERROR UNDO, LEAVE:
            dValue = oA:AsDecimal().
            CATCH e AS Progress.Lang.Error:
                oCaught = e.
            END CATCH.
        END.
        Expect(oCaught):ToHaveErrorCode("InvalidState").
    END METHOD.

    METHOD PUBLIC VOID TestLongcharKeepsFullValue():
        DEFINE VARIABLE lcBig AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE oA    AS Box      NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER  NO-UNDO.
        DO i = 1 TO 5000:
            lcBig = lcBig + "0123456789".
        END.
        oA = NEW Box(lcBig).
        Expect(LENGTH(oA:AsLongchar())):ToEqual(50000).
    END METHOD.

END CLASS.
