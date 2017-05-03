#import "NSURL+WMFLinkParsing.h"
#import "NSString+WMFExtras.h"
#import "NSString+WMFPageUtilities.h"
#import "NSURLComponents+WMFLinkParsing.h"

#if WMF_USE_BETA_CLUSTER
NSString *const WMFDefaultSiteDomain = @"wikipedia.beta.wmflabs.org";
NSString *const WMFDefaultSiteMainDomain = @"wikipedia.org";
#else
NSString *const WMFDefaultSiteDomain = @"wikipedia.org";
#endif
NSString *const WMFMediaWikiDomain = @"mediawiki.org";
NSString *const WMFInternalLinkPathPrefix = @"/wiki/";
NSString *const WMFAPIPath = @"/w/api.php";

@interface NSString (WMFLinkParsing)

- (BOOL)wmf_isWikiResource;

@end

@implementation NSString (WMFLinkParsing)

- (BOOL)wmf_isWikiResource {
    return [self containsString:WMFInternalLinkPathPrefix];
}

@end

@implementation NSURL (WMFLinkParsing)

#pragma mark - Constructors

+ (nullable NSURL *)wmf_wikimediaCommonsURL {
    NSURLComponents *URLComponents = [[NSURLComponents alloc] init];
    URLComponents.scheme = @"https";
    URLComponents.host = [NSURLComponents wmf_hostWithDomain:@"wikimedia.org" subDomain:@"commons" isMobile:NO];
    return [URLComponents URL];
}

+ (NSURL *)wmf_URLWithDefaultSiteAndlanguage:(nullable NSString *)language {
    return [self wmf_URLWithDomain:WMFDefaultSiteDomain language:language];
}

+ (NSURL *)wmf_URLWithDefaultSiteAndLocale:(NSLocale *)locale {
    return [self wmf_URLWithDomain:WMFDefaultSiteDomain language:[locale objectForKey:NSLocaleLanguageCode]];
}

+ (NSURL *)wmf_URLWithDefaultSiteAndCurrentLocale {
    return [self wmf_URLWithDefaultSiteAndLocale:[NSLocale currentLocale]];
}

+ (NSURL *)wmf_URLWithDomain:(NSString *)domain language:(nullable NSString *)language {
    return [[NSURLComponents wmf_componentsWithDomain:domain language:language] URL];
}

+ (NSURL *)wmf_URLWithDomain:(NSString *)domain language:(nullable NSString *)language title:(NSString *)title fragment:(nullable NSString *)fragment {
    return [[NSURLComponents wmf_componentsWithDomain:domain language:language title:title fragment:fragment] URL];
}

+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL title:(nullable NSString *)title fragment:(nullable NSString *)fragment {
    return [siteURL wmf_URLWithTitle:title fragment:fragment];
}

+ (NSRegularExpression *)invalidPercentEscapesRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *percentEscapesRegex;
    dispatch_once(&onceToken, ^{
        percentEscapesRegex = [NSRegularExpression regularExpressionWithPattern:@"%[^0-9A-F]|%[0-9A-F][^0-9A-F]" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    return percentEscapesRegex;
}

+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL unescapedDenormalizedTitleAndFragment:(NSString *)path {
    NSAssert(![path wmf_isWikiResource],
             @"Didn't expect %@ to be an internal link. Use initWithInternalLink:site: instead.",
             path);
    if ([path wmf_isWikiResource]) {
        return [NSURL wmf_URLWithSiteURL:siteURL unescapedDenormalizedInternalLink:path];
    } else {
        NSArray *bits = [path componentsSeparatedByString:@"#"];
        NSString *fragment = nil;
        if (bits.count > 1) {
            fragment = bits[1];
        }
        fragment = [fragment precomposedStringWithCanonicalMapping];
        return [NSURL wmf_URLWithSiteURL:siteURL title:[[bits firstObject] wmf_normalizedPageTitle] fragment:fragment];
    }
}

+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL escapedDenormalizedTitleAndFragment:(NSString *)path {
    NSAssert(![path wmf_isWikiResource],
             @"Didn't expect %@ to be an internal link. Use initWithInternalLink:site: instead.",
             path);
    NSAssert([[NSURL invalidPercentEscapesRegex] matchesInString:path options:0 range:NSMakeRange(0, path.length)].count == 0, @"%@ should only have valid percent escapes", path);
    if ([path wmf_isWikiResource]) {
        return [NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedInternalLink:path];
    } else {
        NSArray *bits = [path componentsSeparatedByString:@"#"];
        NSString *fragment = nil;
        if (bits.count > 1) {
            fragment = bits[1];
        }
        return [NSURL wmf_URLWithSiteURL:siteURL title:[[bits firstObject] wmf_unescapedNormalizedPageTitle] fragment:fragment];
    }
}

+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL unescapedDenormalizedInternalLink:(NSString *)internalLink {
    NSAssert(internalLink.length == 0 || [internalLink wmf_isWikiResource],
             @"Expected string with internal link prefix but got: %@", internalLink);
    return [self wmf_URLWithSiteURL:siteURL unescapedDenormalizedTitleAndFragment:[internalLink wmf_pathWithoutWikiPrefix]];
}

+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL escapedDenormalizedInternalLink:(NSString *)internalLink {
    NSAssert(internalLink.length == 0 || [internalLink wmf_isWikiResource],
             @"Expected string with internal link prefix but got: %@", internalLink);
    return [self wmf_URLWithSiteURL:siteURL escapedDenormalizedTitleAndFragment:[internalLink wmf_pathWithoutWikiPrefix]];
}

- (NSURL *)wmf_URLWithTitle:(NSString *)title {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.wmf_title = title;
    return components.URL;
}

- (NSURL *)wmf_wikipediaSchemeURLWithTitle:(NSString *)title {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.wmf_title = title;
    components.scheme = @"wikipedia";
    return components.URL;
}

- (NSURL *)wmf_wikipediaSchemeURL {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.scheme = @"wikipedia";
    return components.URL;
}

- (NSURL *)wmf_summaryEndpointURL {
    NSURL *siteURL = self.wmf_siteURL;
    NSString *title = self.wmf_title;
    if (!siteURL || !title) {
        return nil;
    }
    NSString *path = [NSString pathWithComponents:@[@"/api", @"rest_v1", @"page", @"summary", title]];
    return [siteURL wmf_URLWithPath:path isMobile:NO];
}

- (NSURL *)wmf_URLWithTitle:(NSString *)title fragment:(NSString *)fragment {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.wmf_title = title;
    components.wmf_fragment = fragment;
    return components.URL;
}

- (NSURL *)wmf_URLWithFragment:(nullable NSString *)fragment {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.wmf_fragment = fragment;
    return components.URL;
}

- (NSURL *)wmf_URLWithPath:(NSString *)path isMobile:(BOOL)isMobile {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.path = [path precomposedStringWithCanonicalMapping];
    if (isMobile != self.wmf_isMobile) {
        components.host = [NSURLComponents wmf_hostWithDomain:self.wmf_domain language:self.wmf_language isMobile:isMobile];
    }
    return components.URL;
}

- (NSURL *)wmf_siteURL {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.path = nil;
    components.fragment = nil;
    return [components URL];
}

- (NSURL *)wmf_APIURL:(BOOL)isMobile {
    return [[self wmf_siteURL] wmf_URLWithPath:WMFAPIPath isMobile:isMobile];
}

+ (NSURL *)wmf_APIURLForURL:(NSURL *)URL isMobile:(BOOL)isMobile {
    return [[URL wmf_siteURL] wmf_URLWithPath:WMFAPIPath isMobile:isMobile];
}

+ (NSURL *)wmf_mobileAPIURLForURL:(NSURL *)URL {
    return [NSURL wmf_APIURLForURL:URL isMobile:YES];
}

+ (NSURL *)wmf_desktopAPIURLForURL:(NSURL *)URL {
    return [NSURL wmf_APIURLForURL:URL isMobile:NO];
}

+ (NSURL *)wmf_mobileURLForURL:(NSURL *)url {
    if (url.wmf_isMobile) {
        return url;
    } else {
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.host = [NSURLComponents wmf_hostWithDomain:url.wmf_domain language:url.wmf_language isMobile:YES];
        return components.URL;
    }
}

+ (NSURL *)wmf_desktopURLForURL:(NSURL *)url {
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.host = [NSURLComponents wmf_hostWithDomain:url.wmf_domain language:url.wmf_language isMobile:NO];
    return components.URL;
}

#pragma mark - Properties

- (BOOL)wmf_isWikiResource {
    static NSString *wikiResourceSuffix = nil;
#if WMF_USE_BETA_CLUSTER
    static NSString *mainWikiResourceSuffix = nil;
#endif
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wikiResourceSuffix = [NSString stringWithFormat:@".%@", WMFDefaultSiteDomain];
#if WMF_USE_BETA_CLUSTER
        mainWikiResourceSuffix = [NSString stringWithFormat:@".%@", WMFDefaultSiteMainDomain];
#endif
    });
    NSString *lowercaseHost = self.host.lowercaseString;
    return (!lowercaseHost
#if WMF_USE_BETA_CLUSTER
            || [lowercaseHost isEqualToString:WMFDefaultSiteMainDomain] || [lowercaseHost hasSuffix:mainWikiResourceSuffix]
#endif
            || [lowercaseHost isEqualToString:WMFDefaultSiteDomain] || [lowercaseHost hasSuffix:wikiResourceSuffix] || [lowercaseHost isEqualToString:WMFMediaWikiDomain] || [lowercaseHost hasSuffix:WMFMediaWikiDomain]) &&
           [self.path wmf_isWikiResource];
}

- (BOOL)wmf_isWikiCitation {
    return [self.fragment wmf_isCitationFragment];
}

- (BOOL)wmf_isPeekable {
    if ([self.absoluteString isEqualToString:@""] ||
        [self.fragment wmf_isReferenceFragment] ||
        [self.fragment wmf_isCitationFragment] ||
        [self.fragment wmf_isEndNoteFragment]) {
        return NO;
    }
    if (![self wmf_isWikiResource]) {
        if ([self.scheme hasPrefix:@"http"]) {
            return YES;
        }
    } else {
        if (![self wmf_isIntraPageFragment]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)wmf_isMobile {
    NSArray *hostComponents = [self.host componentsSeparatedByString:@"."];
    if (hostComponents.count < 3) {
        return NO;
    } else {
        if ([hostComponents[0] isEqualToString:@"m"]) {
            return true;
        } else {
            return [hostComponents[1] isEqualToString:@"m"];
        }
    }
}

- (NSString *)wmf_pathWithoutWikiPrefix {
    return [self.path wmf_pathWithoutWikiPrefix];
}

- (NSString *)wmf_domain {
    NSArray *hostComponents = [self.host componentsSeparatedByString:@"."];
    if (hostComponents.count < 3) {
        return self.host;
    } else {
        NSInteger firstIndex = 1;
        if ([hostComponents[1] isEqualToString:@"m"]) {
            firstIndex = 2;
        }
        NSArray *subarray = [hostComponents subarrayWithRange:NSMakeRange(firstIndex, hostComponents.count - firstIndex)];
        return [subarray componentsJoinedByString:@"."];
    }
}

- (NSString *)wmf_language {
    NSArray *hostComponents = [self.host componentsSeparatedByString:@"."];
    if (hostComponents.count < 3) {
        return nil;
    } else {
        NSString *potentialLanguage = hostComponents[0];
        return [potentialLanguage isEqualToString:@"m"] ? nil : potentialLanguage;
    }
}

- (NSURL *)wmf_articleDatabaseKeyURL {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.host = [NSURLComponents wmf_hostWithDomain:self.wmf_domain language:self.wmf_language isMobile:NO];
    components.fragment = nil;
    components.scheme = @"https";
    return components.URL;
}

- (NSString *)wmf_articleDatabaseKey {
    return self.wmf_articleDatabaseKeyURL.absoluteString.precomposedStringWithCanonicalMapping;
}

- (NSString *)wmf_title {
    if (![self wmf_isWikiResource]) {
        return nil;
    }
    NSString *title = [[self.path wmf_pathWithoutWikiPrefix] wmf_normalizedPageTitle];
    if (title == nil) {
        title = @"";
    }
    return title;
}

- (NSString *)wmf_titleWithUnderScores {
    if (![self wmf_isWikiResource]) {
        return nil;
    }
    NSString *title = [[self.path wmf_pathWithoutWikiPrefix] wmf_denormalizedPageTitle];
    if (title == nil) {
        title = @"";
    }
    return title;
}

- (BOOL)wmf_isNonStandardURL {
    return self.wmf_language == nil;
}

@end
