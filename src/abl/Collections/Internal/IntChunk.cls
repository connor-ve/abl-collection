/*------------------------------------------------------------------------
    File        : abl/Collections/Internal/IntChunk.cls
    GENERATED   : by tools/gen-collections.sh from tools/templates/Chunk.cls.tpl.
                  Edit the template and regenerate; edits here are lost.
    Purpose     : One fixed-size block of INT64 values for IntStore.
                  Items is a public array so the store reads and writes it
                  without a method call per element. Not for direct use.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS abl.Collections.Internal.IntChunk FINAL:

    DEFINE PUBLIC VARIABLE Items AS INT64 EXTENT NO-UNDO.

    DEFINE PUBLIC PROPERTY Size AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC IntChunk(INPUT piSize AS INTEGER):
        EXTENT(Items) = piSize.
        Size = piSize.
    END CONSTRUCTOR.

END CLASS.
