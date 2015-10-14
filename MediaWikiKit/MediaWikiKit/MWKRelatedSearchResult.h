//
//  MWKRelatedSearchResult.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSearchResult.h"

@interface MWKRelatedSearchResult : MWKSearchResult

@property (nonatomic, copy, readonly) NSString* extract;

@end
