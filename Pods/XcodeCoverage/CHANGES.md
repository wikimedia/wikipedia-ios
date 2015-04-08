Version 1.2.2
-------------
_22 Mar 2015_

* Add `getcov` command line parameters, making it easier to use XcodeCoverage in continuous integration. _Thanks to: Tom Aylesworth_
* Add Cobertura XML generation. _Thanks to: Ellen Shapiro_
* Support use as CocoaPod. _Thanks to: Ellen Shapiro_
* Update to lcov 1.11. _Thanks to: Ellen Shapiro_
* Add XcodeCoverage.xcconfig for simple project setup.


Version 1.1.1
-------------
_13 Nov 2014_

* Exclude "Developer/SDKs" instead of "Applications/Xcode.app" so that people can use multiple versions of Xcode. _Thanks to: Cédric Luthi_
* Quote arguments to support built products directory containing spaces. _Thanks to: Cédric Luthi_
* Fix functionality optional post-test dialog in other locales by forcing buttons to be in English.


Version 1.1.0
-------------
_30 Mar 2014_

* Support Xcode 5.1. _Thanks to: Mike Maietta_
* Add optional post-test script `run_code_coverage_post.sh` to prompt whether to generate coverage report. _Thanks to: Matthew Purland_
* Improve function coverage by specifying `--derive-func-data`. _Thanks to: jstevenco_
* Directly include copy of lcov 1.10.


Version 1.0.1
-------------
_09 Mar 2014_

* Fix: Use `CURRENT_ARCH` instead of `NATIVE_ARCH`. _Thanks to: Scott Densmore_
* Improve scripts so they can be run from any working directory.
* Export `OBJROOT` so that customizations can include subprojects.


Version 1.0.0
-------------
_01 Dec 2012_

* Initial release
