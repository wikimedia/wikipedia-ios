#!/bin/bash

#echo $PWD

PREFIX="http://bits.wikimedia.org/en.wikipedia.org/load.php?debug=true&lang=en&only=styles&skin=vector&modules="

cd "wikipedia/assets/" && {
    curl -L -f -o 'styles.css'       "${PREFIX}mobile.app.pagestyles.ios"
    curl -L -f -o 'abusefilter.css'  "${PREFIX}mobile.app.pagestyles.ios"
    curl -L -f -o 'preview.css'      "${PREFIX}mobile.app.preview"
}

