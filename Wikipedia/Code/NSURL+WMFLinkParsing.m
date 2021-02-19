#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/NSURLComponents+WMFLinkParsing.h>
#import <WMF/NSURL+WMFExtras.h>
#import <WMF/WMF-Swift.h>
#import <objc/runtime.h>

NSString *const WMFMediaWikiDomain = @"mediawiki.org";
NSString *const WMFAPIPath = @"/w/api.php";
NSString *const WMFEditPencil = @"WMFEditPencil";

@implementation NSURL (WMFLinkParsing)

#pragma mark - Constructors

+ (nullable NSURL *)wmf_wikimediaCommonsURL {
    NSURLComponents *URLComponents = [[NSURLComponents alloc] init];
    URLComponents.scheme = @"https";
    URLComponents.host = [NSURLComponents wmf_hostWithDomain:@"wikimedia.org" subDomain:@"commons" isMobile:NO];
    return [URLComponents URL];
}

+ (NSURL *)wmf_URLWithDefaultSiteAndlanguage:(nullable NSString *)language {
    return [self wmf_URLWithDomain:WMFConfiguration.current.defaultSiteDomain language:language];
}

+ (NSURL *)wmf_URLWithDefaultSiteAndLocale:(NSLocale *)locale {
    return [self wmf_URLWithDomain:WMFConfiguration.current.defaultSiteDomain language:[locale objectForKey:NSLocaleLanguageCode]];
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

+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL title:(nullable NSString *)title fragment:(nullable NSString *)fragment query:(nullable NSString *)query {
    return [siteURL wmf_URLWithTitle:title fragment:fragment query:query];
}

+ (NSRegularExpression *)invalidPercentEscapesRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *percentEscapesRegex;
    dispatch_once(&onceToken, ^{
        percentEscapesRegex = [NSRegularExpression regularExpressionWithPattern:@"%[^0-9A-F]|%[0-9A-F][^0-9A-F]" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    return percentEscapesRegex;
}

+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL escapedDenormalizedTitleQueryAndFragment:(NSString *)titleQueryAndFragment {
    NSAssert(![titleQueryAndFragment wmf_isWikiResource],
             @"Didn't expect %@ to be an internal link. Use initWithInternalLink:site: instead.",
             titleQueryAndFragment);
    NSAssert([[NSURL invalidPercentEscapesRegex] matchesInString:titleQueryAndFragment options:0 range:NSMakeRange(0, titleQueryAndFragment.length)].count == 0, @"%@ should only have valid percent escapes", titleQueryAndFragment);
    if ([titleQueryAndFragment wmf_isWikiResource]) {
        return [NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedInternalLink:titleQueryAndFragment];
    } else {
        // Resist the urge to use NSURLComponents, it doesn't handle certain page paths we need to handle like "Talk:India"
        NSArray *splitQuery = [titleQueryAndFragment componentsSeparatedByString:@"?"];
        NSString *query = nil;
        NSString *fragment = nil;
        NSArray *bits = nil;
        NSString *title = nil;
        if (splitQuery.count > 1) {
            query = [splitQuery lastObject];
            bits = [query componentsSeparatedByString:@"#"];
            query = [bits firstObject];
            title = [splitQuery firstObject];
        } else {
            bits = [titleQueryAndFragment componentsSeparatedByString:@"#"];
            title = [bits firstObject];
        }
        if (bits.count > 1) {
            fragment = [bits[1] stringByRemovingPercentEncoding];
        }
        fragment = [fragment precomposedStringWithCanonicalMapping];
        title = [title wmf_unescapedNormalizedPageTitle];
        return [NSURL wmf_URLWithSiteURL:siteURL title:title fragment:fragment query:query];
    }
}

+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL escapedDenormalizedInternalLink:(NSString *)internalLink {
    NSAssert(internalLink.length == 0 || [internalLink wmf_isWikiResource],
             @"Expected string with internal link prefix but got: %@", internalLink);
    return [self wmf_URLWithSiteURL:siteURL escapedDenormalizedTitleQueryAndFragment:[internalLink wmf_pathWithoutWikiPrefix]];
}

- (NSURL *)wmf_URLWithTitle:(NSString *)title {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.wmf_title = title;
    return [components wmf_URLWithLanguageVariantCode:self.wmf_languageVariantCode];
}

- (NSURL *)wmf_URLWithTitle:(NSString *)title fragment:(nullable NSString *)fragment query:(nullable NSString *)query {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.wmf_title = title;
    components.wmf_fragment = fragment;
    components.percentEncodedQuery = query;
    return [components wmf_URLWithLanguageVariantCode:self.wmf_languageVariantCode];
}

- (NSURL *)wmf_URLWithFragment:(nullable NSString *)fragment {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.wmf_fragment = fragment;
    return [components wmf_URLWithLanguageVariantCode:self.wmf_languageVariantCode];
}

- (NSURL *)wmf_URLWithPath:(NSString *)path isMobile:(BOOL)isMobile {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.path = [path precomposedStringWithCanonicalMapping];
    if (isMobile != self.wmf_isMobile) {
        components.host = [NSURLComponents wmf_hostWithDomain:self.wmf_domain language:self.wmf_language isMobile:isMobile];
    }
    return [components wmf_URLWithLanguageVariantCode:self.wmf_languageVariantCode];
}

- (NSURL *)wmf_siteURL {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.path = nil;
    components.fragment = nil;
    return [components wmf_URLWithLanguageVariantCode:self.wmf_languageVariantCode];
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

- (BOOL)wmf_isWikiCitation {
    return [self.fragment wmf_isCitationFragment];
}

- (BOOL)wmf_isEditPencil {
    return [[self wmf_pathWithoutWikiPrefix] isEqualToString:WMFEditPencil];
}

- (BOOL)wmf_isPeekable {
    if ([self.absoluteString isEqualToString:@""] ||
        [self.fragment wmf_isReferenceFragment] ||
        [self.fragment wmf_isCitationFragment] ||
        [self.fragment wmf_isEndNoteFragment] ||
        [self wmf_isEditPencil]) {
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

- (NSURL *)wmf_canonicalURL {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.host = [NSURLComponents wmf_hostWithDomain:self.wmf_domain language:self.wmf_language isMobile:NO];
    components.path = [components.path stringByRemovingPercentEncoding] ?: components.path;
    components.scheme = @"https";
    return [components wmf_URLWithLanguageVariantCode:self.wmf_languageVariantCode];
}

- (NSURL *)wmf_databaseURL {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.host = [NSURLComponents wmf_hostWithDomain:self.wmf_domain language:self.wmf_language isMobile:NO];
    components.path = [components.path stringByRemovingPercentEncoding] ?: components.path;
    components.fragment = nil;
    components.query = nil;
    components.scheme = @"https";
    return [components wmf_URLWithLanguageVariantCode:self.wmf_languageVariantCode];
}

- (NSString *)wmf_databaseKey {
    return self.wmf_databaseURL.absoluteString.precomposedStringWithCanonicalMapping;
}

- (NSString *)wmf_title {
    if (![self wmf_isWikiResource]) {
        return nil;
    }
    return [[NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:false] wmf_title];
}

- (NSString *)wmf_titleWithUnderscores {
    if (![self wmf_isWikiResource]) {
        return nil;
    }
    return [[NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:false] wmf_titleWithUnderscores];
}

- (BOOL)wmf_isNonStandardURL {
    return self.wmf_language == nil;
}

static id wmf_languageVariantAssociatedObjectKey;
- (nullable NSString *)wmf_languageVariantCode {
    return (NSString *)[objc_getAssociatedObject(self, &wmf_languageVariantAssociatedObjectKey) copy];
}

// Odd naming is to match automatic Obj-C property naming conventions
- (void) setWmf_languageVariantCode:(nullable NSString *)code {
    objc_setAssociatedObject(self, &wmf_languageVariantAssociatedObjectKey, code, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)wmf_contentLanguageCode {
    NSString *languageVariantCode = self.wmf_languageVariantCode;
    if (!languageVariantCode || [languageVariantCode isEqualToString:@""]) {
        return self.wmf_language;
    } else {
        return languageVariantCode;
    }
}

@end

#pragma mark - WMFInMemoryURLKey

@interface WMFInMemoryURLKey ()
@property (nonatomic, copy) NSString *databaseKey;
@property (nonatomic, copy, nullable) NSString *languageVariantCode;
@end

@implementation WMFInMemoryURLKey: NSObject
-(instancetype) initWithDatabaseKey:(NSString *)databaseKey languageVariantCode:(nullable NSString *)languageVariantCode {
    if (self = [super init]) {
        self.databaseKey = databaseKey;
        self.languageVariantCode = languageVariantCode;
    }
    return self;
}

-(nullable instancetype) initWithURL:(NSURL *)URL {
    NSString *databaseKey = URL.wmf_databaseKey;
    if (!databaseKey) { return nil; }
    else { return [self initWithDatabaseKey:databaseKey languageVariantCode:URL.wmf_languageVariantCode]; }
}

- (nullable NSURL *)URL {
    NSURL *URL = [NSURL URLWithString:self.databaseKey];
    URL.wmf_languageVariantCode = self.languageVariantCode;
    return URL;
}

WMF_SYNTHESIZE_IS_EQUAL(WMFInMemoryURLKey, isEqualToInMemoryURLKey:)

- (BOOL)isEqualToInMemoryURLKey:(WMFInMemoryURLKey *)rhs {
    return WMF_RHS_PROP_EQUAL(databaseKey, isEqualToString:) && WMF_RHS_PROP_EQUAL(languageVariantCode, isEqualToString:);
}

- (NSUInteger)hash {
    return self.databaseKey.hash ^ flipBitsWithAdditionalRotation(self.languageVariantCode.hash, 1); // When languageVariantCode is nil, the XOR flips the bits
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ databaseKey: %@, languageVariantCode: %@", [super description], self.databaseKey, self.languageVariantCode];
}

- (NSString *)userInfoString {
    return self.languageVariantCode ? [NSString stringWithFormat:@"%@__%@", self.databaseKey, self.languageVariantCode] : self.databaseKey;
}

@end

@implementation NSURL (WMFInMemoryURLKeyExtensions)
- (nullable WMFInMemoryURLKey *)wmf_inMemoryKey {
    return [[WMFInMemoryURLKey alloc] initWithURL:self];
}
@end

