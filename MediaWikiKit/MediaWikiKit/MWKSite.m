//  Created by Brion on 11/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MediaWikiKit.h"
#import "WikipediaAppUtils.h"

@interface MWKSite ()

@property (readwrite, copy, nonatomic) NSString* domain;
@property (readwrite, copy, nonatomic) NSString* language;

@end

@implementation MWKSite

#pragma mark - Setup

+ (MWKSite*)siteWithDomain:(NSString*)domain language:(NSString*)language {
    static NSMutableDictionary* cachedSites = nil;
    if (cachedSites == nil) {
        cachedSites = [[NSMutableDictionary alloc] init];
    }
    NSString* key = [NSString stringWithFormat:@"%@:%@", domain, language];
    MWKSite* site = cachedSites[key];
    if (site == nil) {
        site             = [[MWKSite alloc] initWithDomain:domain language:language];
        cachedSites[key] = site;
    }
    return site;
}

- (instancetype)initWithDomain:(NSString*)domain language:(NSString*)language {
    self = [super init];
    if (self) {
        self.domain   = domain;
        self.language = language;
    }
    return self;
}

#pragma mark - Title Helpers

- (MWKTitle*)titleWithString:(NSString*)string {
    return [MWKTitle titleWithString:string site:self];
}

static NSString* localLinkPrefix = @"/wiki/";

- (MWKTitle*)titleWithInternalLink:(NSString*)path {
    if ([path hasPrefix:localLinkPrefix]) {
        NSString* remainder = [[path substringFromIndex:localLinkPrefix.length]
                               stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        return [self titleWithString:remainder];
    } else {
        @throw [NSException exceptionWithName:@"SiteBadLinkFormatException" reason:@"unexpected local link format" userInfo:nil];
    }
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
    return [self.domain isEqualToString:other.domain]
           && [self.language isEqualToString:other.language];
}

- (NSUInteger)hash {
    return [self.domain hash] ^ CircularBitwiseRotation([self.language hash], 1);
}

@end
