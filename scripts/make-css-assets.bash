#!/bin/bash

#echo $PWD

PREFIX="http://bits.wikimedia.org/en.wikipedia.org/load.php?debug=true&lang=en&only=styles&skin=vector&modules="

cd "wikipedia/assets/" && {
    curl -o 'styles.css'       "${PREFIX}mobile.app.pagestyles.ios"
    curl -o 'abusefilter.css'  "${PREFIX}mobile.app.pagestyles.ios"
    curl -o 'preview.css'      "${PREFIX}mobile.app.preview"
}

