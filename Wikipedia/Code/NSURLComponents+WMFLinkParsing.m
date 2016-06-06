#import "NSURLComponents+WMFLinkParsing.h"
#import "NSString+WMFPageUtilities.h"

@implementation NSURLComponents (WMFLinkParsing)

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain
                                    language:(NSString*)language {
    return [self wmf_componentsWithDomain:domain language:language title:nil];
}

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain
                                    language:(NSString*)language
                                       title:(NSString*)title {
    return [self wmf_componentsWithDomain:domain language:language title:title fragment:nil];
}

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain
                                    language:(NSString*)language
                                       title:(NSString*)title
                                    fragment:(NSString*)fragment {
    return [self wmf_componentsWithDomain:domain language:language title:title fragment:fragment isMobile:NO];
}

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain
                                    language:(NSString*)language
                                       title:(NSString*)title
                                    fragment:(NSString*)fragment
                                    isMobile:(BOOL)isMobile {
    NSURLComponents* URLComponents = [[NSURLComponents alloc] init];
    URLComponents.scheme = @"https";
    URLComponents.host   = [NSURLComponents wmf_hostWithDomain:domain language:language isMobile:isMobile];
    if (fragment != nil) {
        URLComponents.fragment = fragment;
    }
    if (title != nil) {
        NSString* path = [[title wmf_denormalizedPageTitle] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        URLComponents.path = path;
    }
    return URLComponents;
}

+ (NSString*)wmf_hostWithDomain:(NSString*)domain
                       language:(NSString*)language
                       isMobile:(BOOL)isMobile {
    NSMutableArray* hostComponents = [NSMutableArray array];
    if (language) {
        [hostComponents addObject:language];
    }
    if (isMobile) {
        [hostComponents addObject:@"m"];
    }
    [hostComponents addObject:domain];
    return [hostComponents componentsJoinedByString:@"."];
}

@end
