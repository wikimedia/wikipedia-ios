//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@interface NSString (Extras)

- (NSString *)urlEncodedUTF8String;
+ (NSString *)sha1:(NSString *)dataFromString isFile:(BOOL)isFile;
- (NSString *)getUrlWithoutScheme; 
- (NSString *)getImageMimeTypeForExtension;
- (NSString *)getWikiImageFileNameWithoutSizePrefix;

- (NSDate *)getDateFromIso8601DateString;
- (NSString *)getStringWithoutHTML;

- (NSString *)randomlyRepeatMaxTimes:(NSUInteger)maxTimes;

- (NSString *)wikiTitleWithoutUnderscores;
- (NSString *)wikiTitleWithoutSpaces;

- (NSString *)capitalizeFirstLetter;

@end
