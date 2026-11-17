/*------------------------------------------------------------------------
    File        : abl/Errors/Guard.cls
    Purpose     : One-line argument checks at the top of a method. Each
                  throws an ArgumentError naming the parameter.
    Usage       :
        Guard:NotNull(poCustomer, "poCustomer").
        Guard:NotBlank(pcName, "pcName").
        Guard:InRange(piQty, 1, 999, "piQty").
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING abl.Errors.ArgumentError.

CLASS abl.Errors.Guard FINAL:

    CONSTRUCTOR PRIVATE Guard():
    END CONSTRUCTOR.

    METHOD PUBLIC STATIC VOID NotNull(INPUT poValue AS Progress.Lang.Object, INPUT pcName AS CHARACTER):
        IF NOT VALID-OBJECT(poValue) THEN
            UNDO, THROW NEW ArgumentError(SUBSTITUTE("&1 must not be unknown", pcName), pcName).
    END METHOD.

    /* Not unknown, not empty, not only spaces. */
    METHOD PUBLIC STATIC VOID NotBlank(INPUT pcValue AS CHARACTER, INPUT pcName AS CHARACTER):
        IF pcValue = ? OR TRIM(pcValue) = "" THEN
            UNDO, THROW NEW ArgumentError(SUBSTITUTE("&1 must not be blank", pcName), pcName).
    END METHOD.

    METHOD PUBLIC STATIC VOID NotUnknown(INPUT pdValue AS DECIMAL, INPUT pcName AS CHARACTER):
        IF pdValue = ? THEN
            UNDO, THROW NEW ArgumentError(SUBSTITUTE("&1 must not be unknown", pcName), pcName).
    END METHOD.

    METHOD PUBLIC STATIC VOID ValidHandle(INPUT phValue AS HANDLE, INPUT pcName AS CHARACTER):
        IF NOT VALID-HANDLE(phValue) THEN
            UNDO, THROW NEW ArgumentError(SUBSTITUTE("&1 must be a valid handle", pcName), pcName).
    END METHOD.

    /* Inclusive on both ends. INTEGER and INT64 arguments widen to DECIMAL. */
    METHOD PUBLIC STATIC VOID InRange(INPUT pdValue AS DECIMAL,
                                      INPUT pdMin   AS DECIMAL,
                                      INPUT pdMax   AS DECIMAL,
                                      INPUT pcName  AS CHARACTER):
        IF pdValue = ? OR pdValue < pdMin OR pdValue > pdMax THEN
            UNDO, THROW NEW ArgumentError(
                SUBSTITUTE("&1 must be between &2 and &3 (got &4)", pcName, pdMin, pdMax, pdValue),
                pcName).
    END METHOD.

    METHOD PUBLIC STATIC VOID Positive(INPUT pdValue AS DECIMAL, INPUT pcName AS CHARACTER):
        IF pdValue = ? OR pdValue <= 0 THEN
            UNDO, THROW NEW ArgumentError(SUBSTITUTE("&1 must be positive (got &2)", pcName, pdValue), pcName).
    END METHOD.

    /* General-purpose: Guard:IsTrue(pdtTo >= pdtFrom, "pdtTo must not be before pdtFrom"). */
    METHOD PUBLIC STATIC VOID IsTrue(INPUT plCondition AS LOGICAL, INPUT pcMessage AS CHARACTER):
        IF plCondition <> TRUE THEN
            UNDO, THROW NEW ArgumentError(pcMessage).
    END METHOD.

END CLASS.
