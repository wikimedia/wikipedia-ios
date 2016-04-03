//
//  WMFRevision.m
//  Wikipedia
//
//  Created by Nick DiStefano on 4/2/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFRevision.h"
#import "NSString+WMFExtras.h"
#import "WikiGlyph_Chars.h"

@implementation WMFRevision

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error {
    NSDictionary *defaults = @{WMF_SAFE_KEYPATH(WMFRevision.new, authorIcon) : WIKIGLYPH_USER_SMILE};
    dictionaryValue = [defaults mtl_dictionaryByAddingEntriesFromDictionary:dictionaryValue];
    return [super initWithDictionary:dictionaryValue error:error];
}


+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{WMF_SAFE_KEYPATH(WMFRevision.new, user): @"user",
             WMF_SAFE_KEYPATH(WMFRevision.new, revisionDate): @"timestamp",
             WMF_SAFE_KEYPATH(WMFRevision.new, parsedComment): @"parsedcomment",
             WMF_SAFE_KEYPATH(WMFRevision.new, parentID): @"parentid",
             WMF_SAFE_KEYPATH(WMFRevision.new, revisionID): @"revid",
             WMF_SAFE_KEYPATH(WMFRevision.new, articleSizeAtRevision): @"size",
             WMF_SAFE_KEYPATH(WMFRevision.new, authorIcon): @"anon",
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

@end
