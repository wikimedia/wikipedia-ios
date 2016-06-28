//
//  MWKRecentSearchEntry.h
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"
#import "MWKList.h"

@interface MWKRecentSearchEntry : MWKSiteDataObject<MWKListObject>

@property (readonly, copy, nonatomic) NSString* searchTerm;

- (instancetype)initWithURL:(NSURL*)url searchTerm:(NSString*)searchTerm;
- (instancetype)initWithDict:(NSDictionary*)dict;

@end
