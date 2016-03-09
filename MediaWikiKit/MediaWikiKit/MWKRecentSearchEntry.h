//
//  MWKRecentSearchEntry.h
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"

@interface MWKRecentSearchEntry : MWKSiteDataObject

@property (readonly) NSString *searchTerm;

-(instancetype)initWithSite:(MWKSite *)site searchTerm:(NSString *)searchTerm;
-(instancetype)initWithDict:(NSDictionary *)dict;

@end
