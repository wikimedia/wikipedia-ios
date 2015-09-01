//
//  MWKRelatedSearchResult.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKRelatedSearchResult.h"
#import <hpple/TFHpple.h>

@implementation MWKRelatedSearchResult

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    NSMutableDictionary* jsonKeyPaths = [[super JSONKeyPathsByPropertyKey] mutableCopy];
    jsonKeyPaths[WMF_SAFE_KEYPATH(MWKRelatedSearchResult.new, extractHTML)] = @"extract";
    return jsonKeyPaths;
}

+ (MTLValueTransformer*)extractHTMLJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSString* extract, BOOL* success, NSError* __autoreleasing* error) {
        NSData* extractData = [extract dataUsingEncoding:NSUTF8StringEncoding];
        return [[[[TFHpple hppleWithHTMLData:extractData] searchWithXPathQuery:@"/html/body/p/* | /html/body/p/text()"]
                 valueForKey:WMF_SAFE_KEYPATH([TFHppleElement new], raw)] componentsJoinedByString:@" "];
    }];
}

@end
