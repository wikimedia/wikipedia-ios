#!/bin/bash
#   XcodeCoverage by Jon Reid, http://qualitycoding/about/
#   Copyright 2015 Jonathan M. Reid. See LICENSE.txt

scripts="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${scripts}/env.sh"

LCOV_PATH="${scripts}/lcov-1.11/bin"
OBJ_DIR="${OBJECT_FILE_DIR_normal}/${CURRENT_ARCH}"

# Fix for the new LLVM-COV that requires gcov to have a -v parameter
LCOV() {
	"${LCOV_PATH}/lcov" "$@" --gcov-tool "${scripts}/llvm-cov-wrapper.sh"
}
