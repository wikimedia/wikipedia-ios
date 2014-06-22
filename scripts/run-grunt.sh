#!/bin/sh

PATH=${PATH}:/usr/local/bin

cd "www/" && {
    npm install
    grunt
}

