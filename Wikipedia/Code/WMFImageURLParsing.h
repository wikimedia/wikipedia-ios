#import <Foundation/Foundation.h>

/**
 * Parse the file page title from an image's source URL and then unescape and normalize it. The returned string will be unescaped and precomposed using canonical mapping. See tests for examples.
 * @param sourceURL The source URL for an image, i.e. the "src" attribute of the @c \<img\> element.
 * @note This will remove any extra path extensions in @c sourceURL (e.g. ".../10px-foo.svg.png" to "foo.svg").
 * @warning This method does regex parsing, be sure to cache the result if possible.
 */
FOUNDATION_EXPORT NSString *WMFParseUnescapedNormalizedImageNameFromSourceURL(NSString *sourceURL) __attribute__((overloadable));

/// Convenience wrapper for @c WMFParseImageNameFromSourceURL(NSString*)
FOUNDATION_EXPORT NSString *WMFParseUnescapedNormalizedImageNameFromSourceURL(NSURL *sourceURL) __attribute__((overloadable));

/**
 * Parse the file page title from an image's source URL.  See tests for examples.
 * @param sourceURL The source URL for an image, i.e. the "src" attribute of the @c \<img\> element.
 * @note This will remove any extra path extensions in @c sourceURL (e.g. ".../10px-foo.svg.png" to "foo.svg").
 * @warning This method does regex parsing, be sure to cache the result if possible.
 */
FOUNDATION_EXPORT NSString *WMFParseImageNameFromSourceURL(NSString *sourceURL) __attribute__((overloadable));

/// Convenience wrapper for @c WMFParseImageNameFromSourceURL(NSString*)
FOUNDATION_EXPORT NSString *WMFParseImageNameFromSourceURL(NSURL *sourceURL) __attribute__((overloadable));

FOUNDATION_EXPORT NSInteger WMFParseSizePrefixFromSourceURL(NSString *sourceURL) __attribute__((overloadable));

/// Convenience wrapper for @c WMFParseSizePrefixFromSourceURL(NSString*)
FOUNDATION_EXPORT NSInteger WMFParseSizePrefixFromSourceURL(NSURL *sourceURL) __attribute__((overloadable));

FOUNDATION_EXPORT NSString *WMFOriginalImageURLStringFromURLString(NSString *URLString);

/**
 * @param sourceURL A commons or lang wiki image url with or without a size prefix (the size prefix is the "XXXpx-" part of "https://upload.wikimedia.org/wikipedia/commonsOrLangCode/thumb/.../Filename.jpg/XXXpx-Filename.jpg" )
 * @param newSizePrefix A new size prefix number. If the sourceURL had a prefix number, this number will replace it. If it did not have a size prefix it will be added as will the "/thumb/" portion.
 * @return An image url in the form of "https://upload.wikimedia.org/wikipedia/commonsOrLangCode/thumb/.../Filename.jpg/XXXpx-Filename.jpg" where the image size prefix has been changed to newSizePrefix
 */
FOUNDATION_EXPORT NSString *WMFChangeImageSourceURLSizePrefix(NSString *sourceURL, NSInteger newSizePrefix) __attribute__((overloadable));
