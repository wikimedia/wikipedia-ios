#   XcodeCoverage by Jon Reid, http://qualitycoding/about/
#   Copyright 2015 Jonathan M. Reid. See LICENSE.txt

scripts="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export | egrep '( BUILT_PRODUCTS_DIR)|(CURRENT_ARCH)|(OBJECT_FILE_DIR_normal)|(SRCROOT)|(OBJROOT)' > "${scripts}/env.sh"
