#import "WMFFeedTopReadResponse.h"
#import "WMFFeedArticlePreview.h"
#import "NSDateFormatter+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedTopReadResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH(WMFFeedTopReadResponse.new, date): @"date",
              WMF_SAFE_KEYPATH(WMFFeedTopReadResponse.new, articlePreviews): @"articles" };
}

+ (NSValueTransformer *)articlePreviewsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[WMFFeedTopReadArticlePreview class]];
}

+ (NSValueTransformer *)dateJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        NSDate *date = [[NSDateFormatter wmf_yearMonthDayZDateFormatter] dateFromString:value];
        return date;
    }];
}

@end

NS_ASSUME_NONNULL_END
