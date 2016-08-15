//
//  MWKLanguageLinkResponseSerializer.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKLanguageLinkResponseSerializer.h"
#import "MWKLanguageLink.h"
#import <BlocksKit/BlocksKit.h>

@implementation MWKLanguageLinkResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error {
    NSDictionary *json = [super responseObjectForResponse:response data:data error:error];
    if (!json) {
        return nil;
    }
    NSDictionary *pagesByID = json[@"query"][@"pages"];
    return [[pagesByID bk_map:^id(id key, NSDictionary *result) {
      return [result[@"langlinks"] bk_map:^MWKLanguageLink *(NSDictionary *jsonLink) {
        return [[MWKLanguageLink alloc] initWithLanguageCode:jsonLink[@"lang"]
                                               pageTitleText:jsonLink[@"*"]
                                                        name:jsonLink[@"autonym"]
                                               localizedName:jsonLink[@"langname"]];
      }];
    }] bk_reject:^BOOL(id key, id obj) {
      return WMF_IS_EQUAL(obj, [NSNull null]);
    }];
}

@end
