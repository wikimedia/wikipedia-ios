//  Created by Brion on 11/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MediaWikiKit.h"
#import "NSObjectUtilities.h"

NSString* const WMFDefaultSiteDomain = @"wikipedia.org";

static NSString* const MWKSiteSchemaVersionKey = @"siteSchemaVersion";

typedef NS_ENUM (NSUInteger, MWKSiteNSCodingSchemaVersion) {
    MWKSiteNSCodingSchemaVersion_1 = 1
};

@interface MWKSite ()

@property (readwrite, copy, nonatomic) NSString* domain;
@property (readwrite, copy, nonatomic) NSString* language;

@end

@implementation MWKSite

- (instancetype)initWithDomain:(NSString*)domain language:(NSString*)language {
    NSParameterAssert(domain.length);
    NSParameterAssert(language.length);
    self = [super init];
    if (self) {
        self.domain   = domain;
        self.language = language;
    }
    return self;
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

#pragma mark - Title Helpers

- (MWKTitle*)titleWithString:(NSString*)string {
    return [MWKTitle titleWithString:string site:self];
}

- (MWKTitle*)titleWithInternalLink:(NSString*)path {
    return [[MWKTitle alloc] initWithInternalLink:path site:self];
}

#pragma mark - Computed Properties

- (NSURL*)mobileApiEndpoint {
    return [self apiEndpoint:YES];
}

- (NSURL*)apiEndpoint {
    return [self apiEndpoint:NO];
}

- (NSURL*)apiEndpoint:(BOOL)isMobile {
//    NSURLComponents* apiEndpointComponents = [[NSURLComponents alloc] init];
//    apiEndpointComponents.scheme = @"https";
//    NSMutableArray* hostComponents = [NSMutableArray arrayWithObject:self.language];
//    if (isMobile) {
//        [hostComponents addObject:@"m"];
//    }
//    [hostComponents addObject:self.domain];
//    apiEndpointComponents.host = [hostComponents componentsJoinedByString:@"."];
//    apiEndpointComponents.path = @"";
//    return [apiEndpointComponents URL];
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.%@%@/w/api.php",
                                 self.language,
                                 isMobile ? @"m." : @"",
                                 self.domain]];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (object == nil) {
        return NO;
    } else if ([object isKindOfClass:[MWKSite class]]) {
        return [self isEqualToSite:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToSite:(MWKSite*)other {
    return WMF_EQUAL_PROPERTIES(self, language, isEqualToString:, other)
           && WMF_EQUAL_PROPERTIES(self, domain, isEqualToString:, other);
}

- (NSUInteger)hash {
    return self.domain.hash ^ flipBitsWithAdditionalRotation(self.language.hash, 1);
}

- (id)copyWithZone:(NSZone*)zone {
    // immutable
    return self;
}

@end
