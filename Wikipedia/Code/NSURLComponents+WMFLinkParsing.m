#import <WMF/NSURLComponents+WMFLinkParsing.h>
#import <WMF/NSCharacterSet+WMFLinkParsing.h>
#import <WMF/WMF-Swift.h>

@implementation NSURLComponents (WMFLinkParsing)

+ (NSURLComponents *)wmf_componentsWithDomain:(NSString *)domain
                                     language:(NSString *)language {
    return [self wmf_componentsWithDomain:domain language:language isMobile:NO];
}

+ (NSURLComponents *)wmf_componentsWithDomain:(NSString *)domain
                                     language:(NSString *)language
                                     isMobile:(BOOL)isMobile {
    return [self wmf_componentsWithDomain:domain language:language title:nil fragment:nil isMobile:isMobile];
}

+ (NSURLComponents *)wmf_componentsWithDomain:(NSString *)domain
                                     language:(NSString *)language
                                        title:(NSString *)title {
    return [self wmf_componentsWithDomain:domain language:language title:title fragment:nil];
}

+ (NSURLComponents *)wmf_componentsWithDomain:(NSString *)domain
                                     language:(NSString *)language
                                        title:(NSString *)title
                                     fragment:(NSString *)fragment {
    return [self wmf_componentsWithDomain:domain language:language title:title fragment:fragment isMobile:NO];
}

+ (NSURLComponents *)wmf_componentsWithDomain:(NSString *)domain
                                     language:(NSString *)language
                                        title:(NSString *)title
                                     fragment:(NSString *)fragment
                                     isMobile:(BOOL)isMobile {
    NSURLComponents *URLComponents = [[NSURLComponents alloc] init];
    URLComponents.scheme = @"https";
    URLComponents.host = [NSURLComponents wmf_hostWithDomain:domain language:language isMobile:isMobile];
    if (fragment != nil) {
        URLComponents.wmf_fragment = fragment;
    }
    if (title != nil) {
        URLComponents.wmf_title = title;
    }
    return URLComponents;
}

+ (NSString *)wmf_hostWithDomain:(NSString *)domain
                        language:(NSString *)language
                        isMobile:(BOOL)isMobile {
    return [self wmf_hostWithDomain:domain subDomain:language isMobile:isMobile];
}

+ (NSString *)wmf_hostWithDomain:(NSString *)domain
                       subDomain:(NSString *)subDomain
                        isMobile:(BOOL)isMobile {
    NSMutableArray *hostComponents = [NSMutableArray array];
    if (subDomain) {
        [hostComponents addObject:subDomain];
    }
    if (isMobile) {
        [hostComponents addObject:@"m"];
    }
    if (domain) {
        [hostComponents addObject:domain];
    }
    return [hostComponents componentsJoinedByString:@"."];
}

- (void)setWmf_titleWithUnderscores:(NSString *_Nullable)titleWithUnderscores {
    NSString *path = [titleWithUnderscores stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet wmf_encodeURIComponentAllowedCharacterSet]];
    if (path != nil && path.length > 0) {
        NSArray *pathComponents = @[@"/wiki/", path];
        self.percentEncodedPath = [NSString pathWithComponents:pathComponents];
    } else {
        self.percentEncodedPath = nil;
    }
}

- (void)setWmf_title:(NSString *)wmf_title {
    self.wmf_titleWithUnderscores = [wmf_title wmf_denormalizedPageTitle];
}

- (NSString *)wmf_title {
    NSString *title = [[self.path wmf_pathWithoutWikiPrefix] wmf_normalizedPageTitle];
    if (title == nil) {
        title = @"";
    }
    return title;
}

- (NSString *)wmf_titleWithUnderscores {
    NSString *title = [[self.path wmf_pathWithoutWikiPrefix] wmf_denormalizedPageTitle];
    if (title == nil) {
        title = @"";
    }
    return title;
}

- (void)setWmf_fragment:(NSString *)wmf_fragment {
    self.fragment = [wmf_fragment precomposedStringWithCanonicalMapping];
}

- (NSString *)wmf_fragment {
    return [self.fragment precomposedStringWithCanonicalMapping];
}

- (NSURLComponents *)wmf_componentsByRemovingQueryItemsNamed:(NSSet<NSString *> *)queryItemNames {
    if (self.queryItems.count == 0) {
        return self;
    }
    NSURLComponents *updatedComponents = [self copy];
    NSMutableArray *validQueryItems = [NSMutableArray arrayWithCapacity:self.queryItems.count];
    for (NSURLQueryItem *queryItem in self.queryItems) {
        if ([queryItemNames containsObject:queryItem.name]) {
            continue;
        }
        [validQueryItems addObject:queryItem];
    }
    updatedComponents.queryItems = validQueryItems.count > 0 ? validQueryItems : nil;
    return updatedComponents;
}

- (nullable NSString *)wmf_valueForQueryItemNamed:(NSString *)queryItemName {
    NSString *value = nil;
    for (NSURLQueryItem *queryItem in self.queryItems) {
        if (![queryItem.name isEqualToString:queryItemName]) {
            continue;
        }
        value = queryItem.value;
        break;
    }
    return value;
}

- (nullable NSString *)wmf_eventLoggingLabel {
    return [self wmf_valueForQueryItemNamed:@"event_logging_label"];
}

- (nullable NSURLComponents *)wmf_componentsByRemovingInternalQueryParameters {
    return [self wmf_componentsByRemovingQueryItemsNamed:[NSSet setWithObject:@"event_logging_label"]];
}

- (nullable NSURL *)wmf_URLWithLanguageVariantCode:(nullable NSString *)code {
    NSURL *url = self.URL;
    url.wmf_languageVariantCode = code;
    return url;
}

@end
