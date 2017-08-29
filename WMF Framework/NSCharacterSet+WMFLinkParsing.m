#import <WMF/NSCharacterSet+WMFLinkParsing.h>

@implementation NSCharacterSet (WMFLinkParsing)

+ (NSCharacterSet *)wmf_URLPathComponentAllowedCharacterSet {
    static dispatch_once_t onceToken;
    static NSCharacterSet *wmf_URLPathComponentAllowedCharacterSet;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *pathAllowedCharacterSet = [[NSCharacterSet URLPathAllowedCharacterSet] mutableCopy];
        [pathAllowedCharacterSet removeCharactersInString:@"/."];
        wmf_URLPathComponentAllowedCharacterSet = [pathAllowedCharacterSet copy];
    });
    return wmf_URLPathComponentAllowedCharacterSet;
}

@end
