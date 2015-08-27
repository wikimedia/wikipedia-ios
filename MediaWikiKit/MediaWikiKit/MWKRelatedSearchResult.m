//
//  MWKRelatedSearchResult.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKRelatedSearchResult.h"

@implementation MWKRelatedSearchResult

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    NSMutableDictionary* jsonKeyPaths = [[super JSONKeyPathsByPropertyKey] mutableCopy];
    jsonKeyPaths[WMF_SAFE_KEYPATH(MWKRelatedSearchResult.new, extractHTML)] = @"extract";
    return jsonKeyPaths;
}

@end
