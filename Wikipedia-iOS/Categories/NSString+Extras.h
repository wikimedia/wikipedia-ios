//  Created by Jaikumar Bhambhwani on 11/10/12.

@interface NSString (Extras)

- (NSString *)urlEncodedUTF8String;
+ (NSString *)sha1:(NSString *)dataFromString isFile:(BOOL)isFile;
- (NSString *)getUrlWithoutScheme; 
- (NSString *)getImageMimeTypeForExtension;
- (NSString *)getWikiImageFileNameWithoutSizePrefix;

- (NSDate *)getDateFromIso8601DateString;

@end
