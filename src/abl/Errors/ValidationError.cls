/*------------------------------------------------------------------------
    File        : abl/Errors/ValidationError.cls
    Purpose     : Input failed one or more rules. Collects every field
                  problem so the caller sees all of them at once, not
                  just the first. Code "Validation", HTTP 422.
    Usage       :
        DEFINE VARIABLE oVal AS ValidationError NO-UNDO.
        oVal = NEW ValidationError("Customer is invalid").
        IF ttCust.Name = "" THEN oVal:AddFieldError("name", "is required").
        IF ttCust.CreditLimit < 0 THEN oVal:AddFieldError("creditLimit", "cannot be negative").
        oVal:ThrowIfAny().
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonObject.

CLASS abl.Errors.ValidationError INHERITS abl.Errors.AblError:

    /* Array of objects with "field" and "message"; also under Context "fields". */
    DEFINE PUBLIC PROPERTY FieldErrors AS JsonArray NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY FieldCount AS INTEGER NO-UNDO
        GET():
            RETURN FieldErrors:Length.
        END GET.

    CONSTRUCTOR PUBLIC ValidationError(INPUT pcMessage AS CHARACTER):
        SUPER("Validation", pcMessage, ?).
        ASSIGN HttpStatus  = 422
               FieldErrors = NEW JsonArray().
        Context:Add("fields", FieldErrors).
    END CONSTRUCTOR.

    METHOD PUBLIC ValidationError AddFieldError(INPUT pcField AS CHARACTER, INPUT pcMessage AS CHARACTER):
        DEFINE VARIABLE oItem AS JsonObject NO-UNDO.

        oItem = NEW JsonObject().
        oItem:Add("field", pcField).
        oItem:Add("message", pcMessage).
        FieldErrors:Add(oItem).

        /* Also a normal error message, so plain GetMessage() callers see it. */
        THIS-OBJECT:AddMessage(SUBSTITUTE("&1: &2", pcField, pcMessage), 0).

        RETURN THIS-OBJECT.
    END METHOD.

    METHOD PUBLIC LOGICAL HasFieldErrors():
        RETURN FieldErrors:Length > 0.
    END METHOD.

    METHOD PUBLIC VOID ThrowIfAny():
        IF FieldErrors:Length > 0 THEN
            UNDO, THROW THIS-OBJECT.
    END METHOD.

END CLASS.
