/*------------------------------------------------------------------------
    File        : abl/Collections/Internal/CharChunk.cls
    GENERATED   : by tools/gen-collections.sh from tools/templates/Chunk.cls.tpl.
                  Edit the template and regenerate; edits here are lost.
    Purpose     : One fixed-size block of CHARACTER values for CharStore.
                  Items is a public array so the store reads and writes it
                  without a method call per element. Not for direct use.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS abl.Collections.Internal.CharChunk FINAL:

    DEFINE PUBLIC VARIABLE Items AS CHARACTER EXTENT NO-UNDO.

    DEFINE PUBLIC PROPERTY Size AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC CharChunk(INPUT piSize AS INTEGER):
        EXTENT(Items) = piSize.
        Size = piSize.
    END CONSTRUCTOR.

END CLASS.
