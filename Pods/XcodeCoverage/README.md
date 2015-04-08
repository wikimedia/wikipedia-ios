![XcodeCoverage](http://qualitycoding.org/jrwp/wp-content/uploads/2014/03/XcodeCoverage.png)

XcodeCoverage provides a simple way to generate reports of the code coverage of your Xcode project. Generated reports include HTML and Cobertura XML.

Coverage data excludes Apple's SDKs, and the exclusion rules can be customized.


Installation: Standard
======================

Use the standard installation if you want to customize XcodeCoverage to exclude certain files and directories, such as third-party libraries. Otherwise, the CocoaPods installation described below may be more convenient.

1. Fork this repository.
2. Place the XcodeCoverage folder in the same folder as your Xcode project.
3. In your main target, add a Run Script build phase to execute `XcodeCoverage/exportenv.sh`

A few people have been tripped up by the last step: Make sure you add the script to your main target (your app or library), not your test target.


Installation: CocoaPods
=======================

A [CocoaPod](http://cocoapods.org/) has been added for convenient use in simple projects. There are a couple of things you should be aware of if you are using the CocoaPod instead of the standard method: 

- There will be no actual files added to your project. Files are only added through `preserve_paths`, so they will be available in your `Pods/XcodeCoverage` path, but you will not see them in Xcode, and they will not be compiled by Xcode.
- You will not be able to modify the scripts without those modifications being potentially overwritten by CocoaPods. 

If those caveats are deal-breakers, please use the standard installation method above. 

The steps to install via CocoaPods: 

1. Add `pod 'XcodeCoverage', '~>1.0'` (or whatever [version specification](http://guides.cocoapods.org/using/the-podfile.html#specifying-pod-versions) you desire) to your Podfile. 
2. Run `pod install`. This will download the necessary files.
3. In your main target, add a Run Script build phase to execute
`Pods/XcodeCoverage/exportenv.sh`. 

Again, make sure you add the script to your main target (your app or library), not your test target.


Xcode Project Setup
===================

XcodeCoverage comes with an xcconfig file with the build settings required to instrument your code for coverage analysis.

If you already use an xcconfig, include it in the configuration you want to instrument:
  * Standard installation: `#include "XcodeCoverage/XcodeCoverage.xcconfig"`
  * CocoaPods installation: `#include "Pods/XcodeCoverage/XcodeCoverage.xcconfig"`

If you don't already use an xcconfig, drag XcodeCoverage.xcconfig into your project. Where it prompts "Add to targets," deselect all targets. (Otherwise, it will be included in the bundle.) Then click on your project in Xcode's Navigator pane, and select the Info tab. For the configuration you want to instrument, select XcodeCoverage.

If you'd rather specify the build settings by hand, enable these two settings at the project level:
  * Instrument Program Flow
  * Generate Test Coverage Files

Make sure not to instrument your AppStore release.

Execution
=========

1. Run your unit tests.
2. In Terminal, execute `getcov` in your project's XcodeCoverage folder.

`getcov` has the following command-line options:

  * `--show` or `-s`: Show HTML report.
  * `--xml` or `-x`: Generate Cobertura XML.
  * `-o output_dir`: Specify output directory.
  * `-i info_file`: Specify name of generated lcov info file.
  * `-v`: Enable verbose output.
  * `-h` or `--help`: Show usage.

If you make changes to your test code without changing the production code and want a clean slate, use the `cleancov` script.

If you make changes to your production code, you should clear out all build artifacts before measuring code coverage again. "Clean Build Folder" by holding down the Option key in Xcode's "Product" menu, or by using the ⌥⇧⌘K key combination.

**Optional:** XcodeCoverage can prompt to run code coverage after running unit tests:

  * Edit Xcode scheme -> Test -> Post-actions
  * Set "Shell" to: `/bin/bash`
  * Set "Provide build settings from" to your main target
  * Set script to `source XcodeCoverage/run_code_coverage_post.sh` for standard installation. For CocoaPods installation, use `source Pods/XcodeCoverage/run_code_coverage_post.sh`


Modification
============

If you are using the standard installation, you can modify `exclude_data()` in `getcov` to specify which files to exclude, such as third-party libraries.


Credits
=======

The `lcov` -> Cobertura script is from [https://github.com/eriwen/lcov-to-cobertura-xml/](https://github.com/eriwen/lcov-to-cobertura-xml/) and is bound by [the license of that project](https://github.com/eriwen/lcov-to-cobertura-xml/blob/master/LICENSE.txt). 

