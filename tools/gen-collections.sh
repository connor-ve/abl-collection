#!/usr/bin/env bash
# Regenerates the typed collection classes from tools/templates.
#
#   bash tools/gen-collections.sh        (from the repo root, or anywhere)
#
# ABL has no generics, so each element type gets its own classes, all made
# from one template. Fix bugs in the template, never in the generated files.
#
# Template tokens:
#   @NAME@   short type name used in class names (Char -> CharSlice)
#   @TYPE@   ABL data type of the elements
#   @P@      parameter prefix for that type (pc, pi, ...)
#   @ZERO@   value given to new or cleared elements
# Markers /*@DEFS@*/ and /*@METHODS@*/ are replaced by the matching
# parts/<part>.defs.part and parts/<part>.methods.part files.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
tpl="$root/tools/templates"
out="$root/src/abl/Collections"
mkdir -p "$out/Internal"

render() {
    # render <template> <target> <name> <type> <prefix> <zero> [parts...]
    local template=$1 target=$2 name=$3 type=$4 prefix=$5 zero=$6
    shift 6

    local defs methods work
    defs=$(mktemp)
    methods=$(mktemp)
    work=$(mktemp)

    for part in "$@"; do
        if [ -f "$tpl/parts/$part.defs.part" ]; then cat "$tpl/parts/$part.defs.part" >> "$defs"; fi
        if [ -f "$tpl/parts/$part.methods.part" ]; then cat "$tpl/parts/$part.methods.part" >> "$methods"; fi
    done

    sed -e "/@DEFS@/{r $defs" -e 'd}' "$tpl/$template" \
        | sed -e "/@METHODS@/{r $methods" -e 'd}' > "$work"

    sed -e "s/@NAME@/$name/g" \
        -e "s/@TYPE@/$type/g" \
        -e "s/@P@/$prefix/g" \
        -e "s/@ZERO@/$zero/g" \
        "$work" > "$target"

    rm -f "$defs" "$methods" "$work"
    echo "  ${target#$root/}"
}

slice() {
    # slice <name> <type> <prefix> <zero> [parts...]
    local name=$1 type=$2 prefix=$3 zero=$4
    shift 4
    render Slice.cls.tpl "$out/${name}Slice.cls"          "$name" "$type" "$prefix" "$zero" "$@"
    render Store.cls.tpl "$out/Internal/${name}Store.cls" "$name" "$type" "$prefix" "$zero"
    render Chunk.cls.tpl "$out/Internal/${name}Chunk.cls" "$name" "$type" "$prefix" "$zero"
}

set_of() {
    # set_of <name> <type> <prefix>
    render Set.cls.tpl "$out/${1}Set.cls" "$1" "$2" "$3" "?"
}

echo "Generating collections:"

#     name  ABL type              prefix zero   parts
slice Char  CHARACTER             pc     '""'   eq-scalar ordered char
slice Int   INT64                 pi     0      eq-scalar ordered numeric
slice Dec   DECIMAL               pd     0      eq-scalar ordered numeric
slice Log   LOGICAL               pl     FALSE  eq-scalar
slice Date  DATE                  pda    ?      eq-scalar ordered
slice Obj   Progress.Lang.Object  po     ?      eq-object

set_of Char CHARACTER pc
set_of Int  INT64     pi

echo "Done."
