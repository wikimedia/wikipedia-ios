#import <WMF/NSCharacterSet+WMFLinkParsing.h>

@implementation NSCharacterSet (WMFLinkParsing)

+ (NSCharacterSet *)wmf_encodeURIComponentAllowedCharacterSet {
    static dispatch_once_t onceToken;
    static NSCharacterSet *wmf_encodeURIComponentAllowedCharacterSet;
    dispatch_once(&onceToken, ^{
        // Match the functionality of encodeURIComponent() in JavaScript, using this Mozilla reference:
        // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent#Description
        // as per this comment: https://phabricator.wikimedia.org/T249284#6113747
        NSString *encodeURIComponentAllowedCharacters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()";
        NSCharacterSet *encodeURIComponentAllowedCharacterSet = [NSCharacterSet characterSetWithCharactersInString:encodeURIComponentAllowedCharacters];
        wmf_encodeURIComponentAllowedCharacterSet = [encodeURIComponentAllowedCharacterSet copy];
    });
    return wmf_encodeURIComponentAllowedCharacterSet;
}

+ (NSCharacterSet *)wmf_relativePathAndFragmentAllowedCharacterSet {
    static dispatch_once_t onceToken;
    static NSCharacterSet *wmf_relativePathAndFragmentAllowedCharacterSet;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *pathAllowedCharacterSet = [[NSCharacterSet URLPathAllowedCharacterSet] mutableCopy];
        [pathAllowedCharacterSet addCharactersInString:@"#?"];
        wmf_relativePathAndFragmentAllowedCharacterSet = [pathAllowedCharacterSet copy];
    });
    return wmf_relativePathAndFragmentAllowedCharacterSet;
}

@end
