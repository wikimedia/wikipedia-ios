#! /bin/sh

if [[ `uname -s` != "Darwin" ]]; then
  echo "Only supported on OS X"
  exit 1
fi


find Wikipedia/Localizations -name '*.strings' | xargs grep -E '[1-9]+\$'

if [[ $? == 0 ]]; then
  echo "Found files containing reversed dollar sign!"
  exit 1
fi

find Wikipedia/Localizations -name 'qqq.lproj' -prune -o -name '*.strings' -print | xargs grep '{{'

if [[ $? == 0 ]]; then
  echo "Found files containing templates!"
  exit 1
fi

