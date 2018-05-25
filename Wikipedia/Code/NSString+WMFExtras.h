@import UIKit;

NS_ASSUME_NONNULL_BEGIN
@interface NSString (WMFExtras)

/// @return A substring of the receiver going up to @c index, or @c length, whichever is shorter.
- (NSString *)wmf_safeSubstringToIndex:(NSUInteger)index;

/// @return A substring of the receiver starting at @c index or an empty string if the recevier is too short.
- (NSString *)wmf_safeSubstringFromIndex:(NSUInteger)index;

- (NSString *)wmf_UTF8StringWithPercentEscapes;

- (NSString *)wmf_schemelessURL;

/**
 * Get the MIME type for a string obtained via another string or URL's `pathExtension` property.
 *
 * For example: <code>[[@"foo.png" pathExtension] wmf_asMIMEType]</code>
 *
 * @return The MIME type for the receiver.
 */
- (NSString *)wmf_asMIMEType;

- (NSDate *)wmf_iso8601Date;

- (NSString *)wmf_randomlyRepeatMaxTimes:(NSUInteger)maxTimes;

- (NSString *)wmf_stringByReplacingUnderscoresWithSpaces;

- (NSString *)wmf_stringByReplacingSpacesWithUnderscores;

- (NSString *)wmf_stringBySanitizingForJavaScript;

- (NSString *)wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:(nullable NSString *)wikipediaLanguage; //Language is the string `en` in `en.wikipedia.org` or `de` in `de.wikipedia.org`. nil will use the current locale

- (BOOL)wmf_containsString:(NSString *)string;

- (BOOL)wmf_caseInsensitiveContainsString:(NSString *)string;

- (BOOL)wmf_containsString:(NSString *)string options:(NSStringCompareOptions)options;

- (BOOL)wmf_isEqualToStringIgnoringCase:(NSString *)string;

- (NSString *)wmf_trim;

- (NSString *)wmf_substringBeforeString:(NSString *)string;
- (NSString *)wmf_substringAfterString:(NSString *)string;

@end
NS_ASSUME_NONNULL_END
