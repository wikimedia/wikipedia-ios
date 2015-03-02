#! /bin/bash

PROJECT_DIR="."
WORKSPACE_FN="$PROJECT_DIR/Wikipedia.xcworkspace"
SCRIPTS_ROOT="$PROJECT_DIR/scripts"
UNCRUSTIFY_SCRIPTS="$SCRIPTS_ROOT"
UNCRUSTIFY_CONFIG="$PROJECT_DIR/uncrustify.cfg"
UNCRUSTIFY_FILELIST="$PROJECT_DIR/to_uncrustify.txt"
UNCRUSTIFY_DEBUGLOG="$PROJECT_DIR/uncrustify_debug.log"
UNCRUSTIFY_SRCDIR="$PROJECT_DIR/Wikipedia $PROJECT_DIR/MediaWikiKit"

if ! ls $WORKSPACE_FN > /dev/null; then
  echo "You must be in the root project directory to run this."
  exit 1
fi

if ! uncrustify > /dev/null; then
  echo "The uncrustify binary is not available on your path. You can install it using 'brew install uncrustify'."
  exit 2
fi

find $UNCRUSTIFY_SRCDIR -iname "*.[hm]" > $UNCRUSTIFY_FILELIST

NO_FILES_NEEDED_UNCRUSTIFY=0
while read fn; do
  uncrustify -c $UNCRUSTIFY_CONFIG -lOC -f "$fn" -o "$fn.new" -q
  if ! diff "$fn" "$fn.new" > /dev/null; then
    NO_FILES_NEEDED_UNCRUSTIFY=1
    echo "UNCRUSTIFIED: $fn"
  fi
  mv "$fn.new" "$fn"
done < $UNCRUSTIFY_FILELIST
rm "$UNCRUSTIFY_FILELIST"

find . -iname "*unc-backup*" -print0 | xargs -0 rm
echo "Uncrustification completed.\n"

# Should be 0 if no files needed to be uncrustifed.
exit $NO_FILES_NEEDED_UNCRUSTIFY
