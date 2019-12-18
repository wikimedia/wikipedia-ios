#import "WMFPageHistoryRevision.h"
@import WMF.WMFComparison;
@import WMF.NSString_WMFExtras;
@import WMF.NSCalendar_WMFCommonCalendars;

@implementation WMFPageHistoryRevision

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error {
    NSDictionary *defaults = @{ WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, isAnon): @NO, WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, isMinor): @NO };
    dictionaryValue = [defaults mtl_dictionaryByAddingEntriesFromDictionary:dictionaryValue];
    return [super initWithDictionary:dictionaryValue error:error];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, user): @"user",
        WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, revisionDate): @"timestamp",
        WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, parsedComment): @"parsedcomment",
        WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, parentID): @"parentid",
        WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, revisionID): @"revid",
        WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, articleSizeAtRevision): @"size",
        WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, isAnon): @"anon",
        WMF_SAFE_KEYPATH(WMFPageHistoryRevision.new, isMinor): @"minor",
    };
}

+ (NSValueTransformer *)revisionDateJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^(NSString *timeStamp, BOOL *success, NSError *__autoreleasing *error) {
        return [timeStamp wmf_iso8601Date];
    }];
}

+ (NSValueTransformer *)isAnonJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        return @YES;
    }];
}

+ (NSValueTransformer *)isMinorJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        return @YES;
    }];
}

- (NSInteger)daysFromToday {
    NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];
    NSInteger days = [calendar wmf_daysFromDate:self.revisionDate toDate:[NSDate date]];
    return days;
}

@end
