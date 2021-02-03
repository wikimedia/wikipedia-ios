#import <WMF/WMFFeedTopReadResponse.h>
#import <WMF/WMFFeedArticlePreview.h>
#import <WMF/NSDateFormatter+WMFExtensions.h>
#import <WMF/WMFComparison.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedTopReadResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{WMF_SAFE_KEYPATH(WMFFeedTopReadResponse.new, date): @"date",
             WMF_SAFE_KEYPATH(WMFFeedTopReadResponse.new, articlePreviews): @"articles"};
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

+ (NSArray<NSString *> *)languageVariantCodePropagationSubelementKeys {
    return @[@"articlePreviews"];
}

// No languageVariantCodePropagationURLKeys

@end

NS_ASSUME_NONNULL_END
