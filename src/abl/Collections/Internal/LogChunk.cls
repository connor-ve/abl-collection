/*------------------------------------------------------------------------
    File        : abl/Collections/Internal/LogChunk.cls
    GENERATED   : by tools/gen-collections.sh from tools/templates/Chunk.cls.tpl.
                  Edit the template and regenerate; edits here are lost.
    Purpose     : One fixed-size block of LOGICAL values for LogStore.
                  Items is a public array so the store reads and writes it
                  without a method call per element. Not for direct use.
------------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS abl.Collections.Internal.LogChunk FINAL:

    DEFINE PUBLIC VARIABLE Items AS LOGICAL EXTENT NO-UNDO.

    DEFINE PUBLIC PROPERTY Size AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC LogChunk(INPUT piSize AS INTEGER):
        EXTENT(Items) = piSize.
        Size = piSize.
    END CONSTRUCTOR.

END CLASS.
