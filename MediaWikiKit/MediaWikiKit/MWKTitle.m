//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MediaWikiKit.h"

@implementation MWKTitle

#pragma mark - Class methods

+(MWKTitle *)titleWithString:(NSString *)str site:(MWKSite *)site
{
    return [[MWKTitle alloc] initWithString:str site:site];
}

+(NSString *)normalize:(NSString *)str
{
    // @todo implement fuller normalization?
    return [str stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

#pragma mark - Initializers

-(instancetype)initWithString:(NSString *)str site:(MWKSite *)site
{
    self = [self init];
    if (self) {
        _site = site;
        NSArray *bits = [str componentsSeparatedByString:@"#"];
        _text = [MWKTitle normalize:bits[0]];
        if (bits.count > 1) {
            _fragment = bits[1];
        } else {
            _fragment = nil;
        }
    }
    return self;
}

#pragma mark - Property getters

-(NSString *)namespace
{
    // @todo implement namespace detection and normalization
    // doing this right requires some site info
    return nil;
}

-(NSString *)_prefix
{
    // @todo implement namespace prefixing once namespaces are handled
    return @"";
}

-(NSString *)prefixedText
{
    return [[self _prefix] stringByAppendingString:self.text];
}

-(NSString *)prefixedDBKey
{
    return [self.prefixedText stringByReplacingOccurrencesOfString:@" " withString:@"_"];
}

-(NSString *)prefixedURL
{
    return [self.prefixedDBKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

-(NSString *)fragmentForURL
{
    if (self.fragment) {
        // @fixme we use some weird escaping system...?
        return [@"#" stringByAppendingString:[self.fragment stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    } else {
        return @"";
    }
}

-(NSURL *)mobileURL;
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.m.%@/wiki/%@",
                                                           self.site.language,
                                                           self.site.domain,
                                                           self.prefixedURL]];
}

-(NSURL *)desktopURL;
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.%@/wiki/%@",
                                 self.site.language,
                                 self.site.domain,
                                 self.prefixedURL]];
}


-(BOOL)isEqual:(id)object
{
    if (object == nil) {
        return NO;
    } else if (![object isKindOfClass:[MWKTitle class]]) {
        return NO;
    } else {
        MWKTitle *other = object;
        return [self.site isEqual:other.site] &&
            [self.prefixedText isEqualToString:other.prefixedText] &&
            ((self.fragment == nil && other.fragment == nil) || [self.fragment isEqualToString:other.fragment]);
    }
}

-(NSString *)description
{
    if (self.fragment) {
        return [NSString stringWithFormat:@"%@:%@:%@#%@", self.site.domain, self.site.language, self.prefixedText, self.fragment];
    } else {
        return [NSString stringWithFormat:@"%@:%@:%@", self.site.domain, self.site.language, self.prefixedText];
    }
}


#pragma mark - NSCopying protocol methods

- (id)copyWithZone:(NSZone *)zone
{
    // Titles are immutable
    return self;
}

@end
