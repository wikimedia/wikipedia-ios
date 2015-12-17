//
//  WMFRevisionQueryResults.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/16/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFRevisionQueryResults.h"
#import "WMFArticleRevision.h"

@implementation WMFRevisionQueryResults

+ (NSValueTransformer*)revisionsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[WMFArticleRevision class]];
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH([WMFRevisionQueryResults new], titleText): @"title",
              WMF_SAFE_KEYPATH([WMFRevisionQueryResults new], revisions): @"revisions" };
}

@end
