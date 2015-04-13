//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@interface NSString (Extras)

/// @return A substring of the receiver going up to @c index, or @c length, whichever is shorter.
- (NSString*)wmf_safeSubstringToIndex:(NSUInteger)index;

- (NSString*)urlEncodedUTF8String;
+ (NSString*)sha1:(NSString*)dataFromString isFile:(BOOL)isFile;
- (NSString*)getUrlWithoutScheme;
- (NSString*)getImageMimeTypeForExtension;

- (NSDate*)  getDateFromIso8601DateString;
- (NSString*)getStringWithoutHTML;

- (NSString*)randomlyRepeatMaxTimes:(NSUInteger)maxTimes;

- (NSString*)wikiTitleWithoutUnderscores;
- (NSString*)wikiTitleWithoutSpaces;

- (NSString*)capitalizeFirstLetter;

- (BOOL)wmf_containsString:(NSString*)string;
- (BOOL)wmf_caseInsensitiveContainsString:(NSString*)string;
- (BOOL)wmf_containsString:(NSString*)string options:(NSStringCompareOptions)options;
- (BOOL)wmf_isEqualToStringIgnoringCase:(NSString*)string;

@end
