//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@interface NSString (Extras)

/// @return A substring of the receiver going up to @c index, or @c length, whichever is shorter.
- (NSString*)wmf_safeSubstringToIndex:(NSUInteger)index;

/// @return A substring of the receiver starting at @c index or an empty string if the recevier is too short.
- (NSString*)wmf_safeSubstringFromIndex:(NSUInteger)index;

- (NSString*)wmf_UTF8StringWithPercentEscapes;

- (NSString*)wmf_schemelessURL;

- (NSString*)wmf_mimeTypeForExtension;

- (NSDate*)wmf_iso8601Date;

- (NSString*)wmf_stringByRemovingHTML;

- (NSString*)wmf_randomlyRepeatMaxTimes:(NSUInteger)maxTimes;

- (NSString*)wmf_stringByReplacingUndrescoresWithSpaces;

- (NSString*)wmf_stringByReplacingSpacesWithUnderscores;

- (NSString*)wmf_stringByCapitalizingFirstCharacter;

- (BOOL)wmf_containsString:(NSString*)string;

- (BOOL)wmf_caseInsensitiveContainsString:(NSString*)string;

- (BOOL)wmf_containsString:(NSString*)string options:(NSStringCompareOptions)options;

- (BOOL)wmf_isEqualToStringIgnoringCase:(NSString*)string;

@end
