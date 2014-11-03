//
//  MWKRecentSearchEntry.m
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKRecentSearchEntry

-(instancetype)initWithSite:(MWKSite *)site searchTerm:(NSString *)searchTerm
{
    self = [self initWithSite:site];
    if (self) {
        _searchTerm = searchTerm;
    }
    return self;
}

-(instancetype)initWithDict:(NSDictionary *)dict
{
    NSString *domain = [self requiredString:@"domain" dict:dict];
    NSString *language = [self requiredString:@"language" dict:dict];
    NSString *searchTerm = [self requiredString:@"searchTerm" dict:dict];
    MWKSite *site = [[MWKSite alloc] initWithDomain:domain language:language];
    self = [self initWithSite:site searchTerm:searchTerm];
    return self;
}

-(id)dataExport
{
    return @{
             @"domain": self.site.domain,
             @"language": self.site.language,
             @"searchTerm": self.searchTerm
             };
}
@end
