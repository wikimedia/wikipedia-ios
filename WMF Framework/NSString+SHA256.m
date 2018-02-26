#import "NSString+SHA256.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (SHA256)

- (NSString *)SHA256 {
    CC_SHA256_CTX hashObject;
    CC_SHA256_Init(&hashObject);

    NSUInteger length = [self length];
    const void *buffer = [self bytes];
    CC_SHA256_Update(&hashObject,
                     (const void *)buffer,
                     (CC_LONG)length);

    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &hashObject);

    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }

    return [[NSString alloc] initWithUTF8String:hash];
}

@end

@implementation NSString (SHA256)

- (NSString *)SHA256 {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] SHA256];
}

@end
