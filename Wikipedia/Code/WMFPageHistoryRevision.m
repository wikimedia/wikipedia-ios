//
//  WMFRevision.m
//  Wikipedia
//
//  Created by Nick DiStefano on 4/2/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFPageHistoryRevision.h"
#import "NSString+WMFExtras.h"
#import "WikiGlyph_Chars.h"
#import "NSDate+Utilities.h"

@implementation WMFPageHistoryRevision

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error {
    NSDictionary *defaults = @{WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, authorIcon) : WIKIGLYPH_USER_SMILE};
    dictionaryValue = [defaults mtl_dictionaryByAddingEntriesFromDictionary:dictionaryValue];
    return [super initWithDictionary:dictionaryValue error:error];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, user) : @"user",
              WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, revisionDate) : @"timestamp",
              WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, parsedComment) : @"parsedcomment",
              WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, parentID) : @"parentid",
              WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, revisionID) : @"revid",
              WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, articleSizeAtRevision) : @"size",
              WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, authorIcon) : @"anon",
    };
}

+ (NSValueTransformer *)revisionDateJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^(NSString *timeStamp, BOOL *success, NSError *__autoreleasing *error) {
      return [timeStamp wmf_iso8601Date];
    }];
}

+ (NSValueTransformer *)authorIconJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^(NSString *anon, BOOL *success, NSError *__autoreleasing *error) {
      return WIKIGLYPH_USER_SLEEP;
    }];
}

- (NSInteger)daysFromToday {
    return [self.revisionDate distanceInDaysToDate:[NSDate date]];
}

@end
