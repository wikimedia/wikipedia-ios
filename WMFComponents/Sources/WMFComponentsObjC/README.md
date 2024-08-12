Steps to expose Objective-C files for Swift WMFComponents:

1. Create Objective-C .h and .m files as you normally would in Xcode within the `WMFComponentsObjC` directory
2. Make a symlink in the `include` directory for the header file. 

For example, `cd` to WMFComponentsObjC directory, then: `ln -s ../WMFSourceEditorFormatterBoldItalic.h include/WMFSourceEditorFormatterBoldItalic.h` 

3. Add header file to WMFComponentsObjC.h file in `include` directory.

4. In Swift WMFComponents file, add `import WMFComponentsObjC`.
