#import "NSURLComponents+WMFLinkParsing.h"
#import "NSString+WMFPageUtilities.h"

@implementation NSURLComponents (WMFLinkParsing)

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain
                                    language:(NSString*)language {
    return [self wmf_componentsWithDomain:domain language:language isMobile:NO];
}

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain
                                    language:(NSString*)language
                                    isMobile:(BOOL)isMobile {
    return [self wmf_componentsWithDomain:domain language:language title:nil fragment:nil isMobile:isMobile];
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
        URLComponents.wmf_title = title;
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

- (void)setWmf_title:(NSString*)wmf_title {
    NSString* path = [wmf_title wmf_denormalizedPageTitle];
    if (path != nil && path.length > 0) {
        NSArray* pathComponents = @[WMFInternalLinkPathPrefix, path];
        self.path = [NSString pathWithComponents:pathComponents];
    } else {
        self.path = nil;
    }
}

- (NSString*)wmf_title {
    NSString* title = [[self.path wmf_internalLinkPath] wmf_normalizedPageTitle];
    if (title == nil) {
        title = @"";
    }
    return title;
}

- (void)setWmf_fragment:(NSString*)wmf_fragment {
    self.fragment = wmf_fragment;
}

- (NSString*)wmf_fragment {
    return self.fragment;
}

@end
