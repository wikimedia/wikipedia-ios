//
//  WMFArticleRevision.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/16/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleRevision.h"

#define WMFArticleRevisionKey(key) WMF_SAFE_KEYPATH([WMFArticleRevision new], key)

typedef NS_ENUM (NSInteger, WMFArticleRevisionError) {
    WMFArticleRevisionErrorMissingRevisionId = 1
};

static NSString* const WMFArticleRevisionErrorDomain = @"WMFArticleRevisionErrorDomain";

@implementation WMFArticleRevision

- (BOOL)validate:(NSError* __autoreleasing*)error {
    if (!self.revisionId) {
        WMFSafeAssign(error, [NSError errorWithDomain:WMFArticleRevisionErrorDomain
                                                 code:WMFArticleRevisionErrorMissingRevisionId
                                             userInfo:nil]);
        return NO;
    }
    return YES;
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{ WMFArticleRevisionKey(revisionId): @"revid",
              WMFArticleRevisionKey(minorEdit): @"minor",
              WMFArticleRevisionKey(sizeInBytes): @"size" };
}

@end
