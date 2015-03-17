#import <Foundation/Foundation.h>

/**
 * Parse the file page title from an image's source URL.  See tests for examples.
 * @param sourceURL The source URL for an image, i.e. the "src" attribute of the @c \<img\> element.
 * @note This will remove any extra path extensions in @c sourceURL (e.g. ".../10px-foo.svg.png" to "foo.svg").
 * @warning This method does regex parsing, be sure to cache the result if possible.
 */
FOUNDATION_EXPORT NSString* WMFParseImageNameFromSourceURL(NSString* sourceURL) __attribute__((overloadable));

/// Convenience wrapper for @c WMFParseImageNameFromSourceURL(NSString*)
FOUNDATION_EXPORT NSString* WMFParseImageNameFromSourceURL(NSURL* sourceURL) __attribute__((overloadable));


FOUNDATION_EXPORT NSInteger WMFParseSizePrefixFromSourceURL(NSString* sourceURL) __attribute__((overloadable));

/// Convenience wrapper for @c WMFParseSizePrefixFromSourceURL(NSString*)
FOUNDATION_EXPORT NSInteger WMFParseSizePrefixFromSourceURL(NSURL* sourceURL) __attribute__((overloadable));
