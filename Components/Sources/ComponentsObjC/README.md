Steps to expose Objective-C files for Swift Components:

1. Create Objective-C .h and .m files as you normally would in Xcode within the `ComponentsObjC` directory
2. Make a symlink in the `include` directory for the header file. 

For example, `cd` to ComponentsObjC directory, then: `ln -s ../WKSourceEditorFormatterBoldItalic.h include/WKSourceEditorFormatterBoldItalic.h` 

3. Add header file to ComponentsObjC.h file in `include` directory.

4. In Swift Components file, add `import ComponentsObjC`.
