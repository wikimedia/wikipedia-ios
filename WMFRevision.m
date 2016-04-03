//
//  WMFRevision.m
//  Wikipedia
//
//  Created by Nick DiStefano on 4/2/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFRevision.h"
#import "NSString+WMFExtras.h"

@implementation WMFRevision

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{WMF_SAFE_KEYPATH(WMFRevision.new, user): @"user",
             WMF_SAFE_KEYPATH(WMFRevision.new, revisionDate): @"timestamp",
             WMF_SAFE_KEYPATH(WMFRevision.new, parsedComment): @"parsedcomment",
             WMF_SAFE_KEYPATH(WMFRevision.new, parentID): @"parentid",
             WMF_SAFE_KEYPATH(WMFRevision.new, revisionID): @"revid",
             WMF_SAFE_KEYPATH(WMFRevision.new, articleSizeAtRevision): @"size",
             };
}

+ (NSValueTransformer *)revisionDateJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^(NSString *timeStamp, BOOL *success, NSError *__autoreleasing *error) {
        return [timeStamp wmf_iso8601Date];
    }];
}

@end
