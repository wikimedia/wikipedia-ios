//
//  WMFRevisionQueryResults.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/16/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFRevisionQueryResults.h"
#import "WMFArticleRevision.h"

typedef NS_ENUM (NSInteger, WMFRevisionQueryResultsError) {
    WMFRevisionQueryResultsErrorMissingTitle = 1,
    WMFRevisionQueryResultsErrorEmptyRevisions,
};

static NSString* const WMFRevisionQueryResultsErrorDomain = @"WMFRevisionQueryResultsErrorDomain";

@implementation WMFRevisionQueryResults

- (BOOL)validate:(NSError* __autoreleasing*)error {
    if (!self.titleText.length) {
        WMFSafeAssign(error, [NSError errorWithDomain:WMFRevisionQueryResultsErrorDomain
                                                 code:WMFRevisionQueryResultsErrorMissingTitle
                                             userInfo:nil]);
        return NO;
    }

    if (!self.revisions.count) {
        WMFSafeAssign(error, [NSError errorWithDomain:WMFRevisionQueryResultsErrorDomain
                                                 code:WMFRevisionQueryResultsErrorEmptyRevisions
                                             userInfo:nil]);
        return NO;
    }

    return YES;
}

- (void)setRevisions:(NSArray<WMFArticleRevision*>*)revisions {
    _revisions = revisions ? : @[];
}

- (void)setTitleText:(NSString*)titleText {
    _titleText = titleText ? : @"";
}

+ (NSValueTransformer*)revisionsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[WMFArticleRevision class]];
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH([WMFRevisionQueryResults new], titleText): @"title",
              WMF_SAFE_KEYPATH([WMFRevisionQueryResults new], revisions): @"revisions" };
}

@end
