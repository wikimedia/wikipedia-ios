//  Created by Brion on 11/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MediaWikiKit.h"
#import "NSObjectUtilities.h"
#import "NSURL+WMFLinkParsing.h"

NSString* const WMFDefaultSiteDomain = @"wikipedia.org";

static NSString* const MWKSiteSchemaVersionKey = @"siteSchemaVersion";

typedef NS_ENUM (NSUInteger, MWKSiteNSCodingSchemaVersion) {
    MWKSiteNSCodingSchemaVersion_1 = 1
};

@interface MWKSite ()

@property (nonatomic, copy) NSURL* URL;

@end

@implementation MWKSite

- (instancetype)initWithURL:(NSURL*)url {
    self = [super init];
    if (self) {
        NSURLComponents* components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.path     = nil;
        components.fragment = nil;
        self.URL            = [components URL];
    }
    return self;
}

- (instancetype)initWithDomain:(NSString*)domain language:(NSString*)language {
    return [self initWithURL:[NSURL wmf_URLWithDomain:domain language:language]];
}

- (instancetype)initWithLanguage:(NSString*)language {
    return [self initWithDomain:WMFDefaultSiteDomain language:language];
}

+ (instancetype)siteWithLanguage:(NSString*)language {
    return [[self alloc] initWithLanguage:language];
}

+ (MWKSite*)siteWithDomain:(NSString*)domain language:(NSString*)language {
    return [[MWKSite alloc] initWithDomain:domain language:language];
}

+ (instancetype)siteWithCurrentLocale {
    return [self siteWithLocale:[NSLocale currentLocale]];
}

+ (instancetype)siteWithLocale:(NSLocale*)locale {
    return [self siteWithDomain:WMFDefaultSiteDomain language:[locale objectForKey:NSLocaleLanguageCode]];
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        if (!self.URL) {
            NSString* domain   = [self decodeValueForKey:@"domain" withCoder:coder modelVersion:0];
            NSString* language = [self decodeValueForKey:@"language" withCoder:coder modelVersion:0];
            if (domain) {
                self.URL = [NSURL wmf_URLWithDomain:domain language:language];
            }
        }
    }
    return self;
}

#pragma mark - Title Helpers

- (MWKTitle*)titleWithString:(NSString*)string {
    return [MWKTitle titleWithUnescapedString:string site:self];
}

- (MWKTitle*)titleWithUnescapedString:(NSString*)string {
    return [MWKTitle titleWithUnescapedString:string site:self];
}

- (MWKTitle*)titleWithInternalLink:(NSString*)path {
    return [[MWKTitle alloc] initWithInternalLink:path site:self];
}

- (MWKTitle*)titleWithNormalizedTitle:(NSString*)normalizedTitle {
    return [[MWKTitle alloc] initWithSite:self normalizedTitle:normalizedTitle fragment:nil];
}

#pragma mark - Computed Properties

- (NSString*)domain {
    return self.URL.wmf_domain;
}

- (NSString*)language {
    return self.URL.wmf_language;
}

- (NSURL*)mobileApiEndpoint {
    return [self apiEndpoint:YES];
}

- (NSURL*)apiEndpoint {
    return [self apiEndpoint:NO];
}

- (NSString*)urlDomainWithLanguage {
    return self.URL.host;
}

- (NSURL*)mobileURL {
    return self.URL.wmf_mobileURL;
}

- (NSURL*)apiEndpoint:(BOOL)isMobile {
    return [self.URL wmf_URLWithPath:@"/w/api.php" isMobile:isMobile];
}

- (UIUserInterfaceLayoutDirection)layoutDirection {
    return self.URL.wmf_layoutDirection;
}

- (NSTextAlignment)textAlignment {
    return self.URL.wmf_textAlignment;
}

- (BOOL)isEqualToSite:(MWKSite*)other {
    return WMF_EQUAL_PROPERTIES(self, language, isEqualToString:, other)
           && WMF_EQUAL_PROPERTIES(self, domain, isEqualToString:, other);
}

#pragma mark - MTLModel

+ (NSUInteger)modelVersion {
    return 1;
}

// Need to specify storage properties since domain & language are readonly, which Mantle interprets as transitory.
+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString*)propertyKey {
#define IS_MWKSITE_KEY(key) [propertyKey isEqualToString:WMF_SAFE_KEYPATH([MWKSite new], key)]
    if (IS_MWKSITE_KEY(URL)) {
        return MTLPropertyStoragePermanent;
    } else {
        // all other properties are computed from domain and/or language
        return MTLPropertyStorageNone;
    }
}

@end
