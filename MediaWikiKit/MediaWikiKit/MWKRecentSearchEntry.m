//
//  MWKRecentSearchEntry.m
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@interface MWKRecentSearchEntry ()

@property (readwrite, copy, nonatomic) NSString* searchTerm;

@end

@implementation MWKRecentSearchEntry

- (instancetype)initWithSite:(MWKSite*)site searchTerm:(NSString*)searchTerm {
    self = [self initWithSite:site];
    if (self) {
        self.searchTerm = searchTerm;
    }
    return self;
}

- (instancetype)initWithDict:(NSDictionary*)dict {
    NSString* domain     = [self requiredString:@"domain" dict:dict];
    NSString* language   = [self requiredString:@"language" dict:dict];
    NSString* searchTerm = [self requiredString:@"searchTerm" dict:dict];
    MWKSite* site        = [[MWKSite alloc] initWithDomain:domain language:language];
    self = [self initWithSite:site searchTerm:searchTerm];
    return self;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@ %@", [super description], self.site, self.searchTerm];
}

WMF_SYNTHESIZE_IS_EQUAL(MWKRecentSearchEntry, isEqualToRecentSearch:)

- (BOOL)isEqualToRecentSearch:(MWKRecentSearchEntry*)rhs {
    return WMF_RHS_PROP_EQUAL(site, isEqualToSite:)
           && WMF_RHS_PROP_EQUAL(searchTerm, isEqualToString:);
}

- (NSUInteger)hash {
    return self.searchTerm.hash ^ flipBitsWithAdditionalRotation(self.site.hash, 1);
}

#pragma mark - MWKListObject

- (id <NSCopying>)listIndex {
    return self.searchTerm;
}

- (id)dataExport {
    return @{
               @"domain": self.site.domain,
               @"language": self.site.language,
               @"searchTerm": self.searchTerm
    };
}

@end
