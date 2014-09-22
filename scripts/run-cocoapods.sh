#!/bin/sh

rm -rf "Cocoapods/Pods"
cd "Cocoapods"
pod install --no-integrate
