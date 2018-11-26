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

+ (NSCharacterSet *)wmf_URLQueryAllowedCharacterSet {
    static dispatch_once_t onceToken;
    static NSCharacterSet *wmf_URLQueryAllowedCharacterSet;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *queryAllowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
        [queryAllowedCharacterSet removeCharactersInString:@"+"];
        wmf_URLQueryAllowedCharacterSet = [queryAllowedCharacterSet copy];
    });
    return wmf_URLQueryAllowedCharacterSet;
}

@end
