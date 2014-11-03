//  Created by Brion on 11/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MediaWikiKit.h"

@implementation MWKSite

- (instancetype)initWithDomain:(NSString *)domain language:(NSString *)language
{
    self = [super init];
    if (self) {
        _domain = [domain copy];
        _language = [language copy];
    }
    return self;
}


#pragma mark - Title methods

- (MWKTitle *)titleWithString:(NSString *)string
{
    return [MWKTitle titleWithString:string site:self];
}

static NSString *localLinkPrefix = @"/wiki/";

- (MWKTitle *)titleWithInternalLink:(NSString *)path
{
    if ([path hasPrefix:localLinkPrefix]) {
        NSString *remainder = [path substringFromIndex:localLinkPrefix.length];
        return [self titleWithString:remainder];
    } else {
        @throw [NSException exceptionWithName:@"SiteBadLinkFormatException" reason:@"unexpected local link format" userInfo:nil];
    }
}

#pragma mark - NSObject methods

- (BOOL)isEqual:(id)object
{
    if (object == nil) {
        return NO;
    } else if (![object isKindOfClass:[MWKSite class]]) {
        return NO;
    } else {
        MWKSite *other = object;
        return [self.domain isEqualToString:other.domain] &&
               [self.language isEqualToString:other.language];
    }
}

#pragma mark - class methods

+ (MWKSite *)siteWithDomain:(NSString *)domain language:(NSString *)language
{
    static NSMutableDictionary *cachedSites = nil;
    if (cachedSites == nil) {
        cachedSites = [[NSMutableDictionary alloc] init];
    }
    NSString *key = [NSString stringWithFormat:@"%@:%@", domain, language];
    MWKSite *site = cachedSites[key];
    if (site == nil) {
        site = [[MWKSite alloc] initWithDomain:domain language:language];
        cachedSites[key] = site;
    }
    return site;
}

@end
