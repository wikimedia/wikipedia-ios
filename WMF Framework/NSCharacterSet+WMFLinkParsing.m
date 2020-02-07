#import <WMF/NSCharacterSet+WMFLinkParsing.h>

@implementation NSCharacterSet (WMFLinkParsing)

+ (NSCharacterSet *)wmf_URLArticleTitlePathComponentAllowedCharacterSet {
    static dispatch_once_t onceToken;
    static NSCharacterSet *wmf_URLArticleTitleAllowedCharacterSet;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *pathAllowedCharacterSet = [[NSCharacterSet URLPathAllowedCharacterSet] mutableCopy];
        [pathAllowedCharacterSet removeCharactersInString:@"/."];
        wmf_URLArticleTitleAllowedCharacterSet = [pathAllowedCharacterSet copy];
    });
    return wmf_URLArticleTitleAllowedCharacterSet;
}

+ (NSCharacterSet *)wmf_relativePathAndFragmentAllowedCharacterSet {
    static dispatch_once_t onceToken;
    static NSCharacterSet *wmf_relativePathAndFragmentAllowedCharacterSet;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *pathAllowedCharacterSet = [[NSCharacterSet URLPathAllowedCharacterSet] mutableCopy];
        [pathAllowedCharacterSet addCharactersInString:@"#"];
        wmf_relativePathAndFragmentAllowedCharacterSet = [pathAllowedCharacterSet copy];
    });
    return wmf_relativePathAndFragmentAllowedCharacterSet;
}

@end
