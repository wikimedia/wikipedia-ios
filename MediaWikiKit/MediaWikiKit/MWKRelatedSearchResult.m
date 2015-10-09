//
//  MWKRelatedSearchResult.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKRelatedSearchResult.h"
#import "MWKArticle.h"

@implementation MWKRelatedSearchResult

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    NSMutableDictionary* jsonKeyPaths = [[super JSONKeyPathsByPropertyKey] mutableCopy];
    jsonKeyPaths[WMF_SAFE_KEYPATH(MWKRelatedSearchResult.new, extract)] = @"extract";
    return jsonKeyPaths;
}

+ (MTLValueTransformer*)extractJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSString* extract, BOOL* success, NSError* __autoreleasing* error) {
        return [MWKArticle cleanSummary:extract];
    }];
}

@end
