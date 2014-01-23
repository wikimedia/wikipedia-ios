//  Created by Jaikumar Bhambhwani on 11/10/12.

#import "NSString+Extras.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Extras)

- (NSString *)urlEncodedUTF8String {
    return (__bridge_transfer id)CFURLCreateStringByAddingPercentEscapes(0, (__bridge CFStringRef)self, 0,
                                                       (__bridge CFStringRef)@";/?:@&=$+{}<>,", kCFStringEncodingUTF8);
}

+ (NSString *)sha1:(NSString *)dataFromString isFile:(BOOL)isFile
{
    NSData *data = nil;
    if(isFile){
        data = [NSData dataWithContentsOfFile:dataFromString];
    }else{
        const char *cstr = [dataFromString cStringUsingEncoding:NSUTF8StringEncoding];
        data = [NSData dataWithBytes:cstr length:dataFromString.length];
    }
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",digest[i]];
    
    return output;
}

-(NSString *)getUrlWithoutScheme
{
    NSRange dividerRange = [self rangeOfString:@"://"];
    if (dividerRange.location == NSNotFound) return self;
    NSUInteger divide = NSMaxRange(dividerRange) - 2;
    //NSString *scheme = [self substringToIndex:divide];
    NSString *path = [self substringFromIndex:divide];
    return path;
}

-(NSString *)getImageMimeTypeForExtension
{
    NSString *lowerCaseSelf = [self lowercaseString];
    if  ([lowerCaseSelf isEqualToString:@"jpg"]) return @"image/jpeg";
    if  ([lowerCaseSelf isEqualToString:@"jpeg"]) return @"image/jpeg";
    if  ([lowerCaseSelf isEqualToString:@"png"]) return @"image/png";
    if  ([lowerCaseSelf isEqualToString:@"gif"]) return @"image/gif";
    return @"";
}

- (NSString *)getWikiImageFileNameWithoutSizePrefix
{
//TODO: optimize this to not use a regex. It's so simple there's no need to create regex objects.
    static NSString *pattern = @"^(\\d+px-)(.+)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
    return [regex stringByReplacingMatchesInString:self options:NSMatchingReportProgress range:NSMakeRange(0, self.length) withTemplate:@"$2"];
}

- (NSDate *)getDateFromIso8601DateString
{
    // See: https://www.mediawiki.org/wiki/Manual:WfTimestamp
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    return  [formatter dateFromString:self];
}

@end
