//
//  WMFArticleRevision.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/16/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleRevision.h"

#define WMFArticleRevisionKey(key) WMF_SAFE_KEYPATH([WMFArticleRevision new], key)

@implementation WMFArticleRevision

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{ WMFArticleRevisionKey(revisionId): @"revid",
              WMFArticleRevisionKey(minorEdit): @"minor",
              WMFArticleRevisionKey(sizeInBytes): @"size" };
}

@end
