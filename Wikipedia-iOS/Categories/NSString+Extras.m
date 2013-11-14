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

@end
