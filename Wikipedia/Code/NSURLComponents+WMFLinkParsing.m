#import "NSURLComponents+WMFLinkParsing.h"

@implementation NSURLComponents (WMFLinkParsing)

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain language:(NSString*)language {
    return [NSURLComponents wmf_componentsWithDomain:domain language:language isMobile:NO];
}

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain language:(NSString*)language isMobile:(BOOL)isMobile {
    NSURLComponents* siteURLComponents = [[NSURLComponents alloc] init];
    siteURLComponents.scheme = @"https";
    NSMutableArray* hostComponents = [NSMutableArray array];
    if (language) {
        [hostComponents addObject:language];
    }
    if (isMobile) {
        [hostComponents addObject:@"m"];
    }
    [hostComponents addObject:domain];
    siteURLComponents.host = [hostComponents componentsJoinedByString:@"."];
    return siteURLComponents;
}

@end
