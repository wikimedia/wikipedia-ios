//
//  Site.m
//  Wikipedia-iOS
//
//  Created by Brion on 11/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import "MWSite.h"

@implementation MWSite

- (id)initWithDomain:(NSString *)domain
{
    self = [super init];
    if (self) {
        self.domain = domain;
    }
    return self;
}

- (BOOL)isEqual:(id)other
{
    if (other == nil) {
        return NO;
    }
    if (![other isKindOfClass:self.class]) {
        return NO;
    }
    MWSite *otherSite = other;
    return [self.domain isEqualToString:otherSite.domain];
}

static NSString *localLinkPrefix = @"/wiki/";

- (MWPageTitle *)titleForInternalLink:(NSString *)path
{
    if ([path hasPrefix:localLinkPrefix]) {
        NSString *remainder = [path substringFromIndex:localLinkPrefix.length];
        NSArray *chunks = [remainder componentsSeparatedByString:@"#"];
        // todo: use the hash
        NSString *rawTitle = chunks[0];
        // todo: kill namespaces from here
        return [MWPageTitle titleFromNamespace:@"" text:rawTitle];
    } else {
        @throw [NSException exceptionWithName:@"SiteBadLinkFormatException" reason:@"unexpected local link format" userInfo:nil];
    }
}

@end
