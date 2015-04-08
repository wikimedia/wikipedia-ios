#!/bin/bash
#   XcodeCoverage by Jon Reid, http://qualitycoding/about/
#   Copyright 2015 Jonathan M. Reid. See LICENSE.txt

if [ "$1" = "-v" ]; then
  echo "llvm-cov-wrapper 4.2.1"
  exit 0
else
  /usr/bin/gcov "$@"
fi
