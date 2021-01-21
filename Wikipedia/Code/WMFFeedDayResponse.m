#import <WMF/WMFFeedDayResponse.h>
#import <WMF/WMFFeedArticlePreview.h>
#import <WMF/WMFFeedImage.h>
#import <WMF/WMFFeedTopReadResponse.h>
#import <WMF/WMFFeedNewsStory.h>
#import <WMF/WMFComparison.h>

NS_ASSUME_NONNULL_BEGIN
@implementation WMFFeedDayResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{WMF_SAFE_KEYPATH(WMFFeedDayResponse.new, featuredArticle): @"tfa",
             WMF_SAFE_KEYPATH(WMFFeedDayResponse.new, topRead): @"mostread",
             WMF_SAFE_KEYPATH(WMFFeedDayResponse.new, pictureOfTheDay): @"image",
             WMF_SAFE_KEYPATH(WMFFeedDayResponse.new, newsStories): @"news"};
}

+ (NSValueTransformer *)featuredArticleJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[WMFFeedArticlePreview class]];
}

+ (NSValueTransformer *)topReadJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[WMFFeedTopReadResponse class]];
}

+ (NSValueTransformer *)pictureOfTheDayJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[WMFFeedImage class]];
}

+ (NSValueTransformer *)newsStoriesJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[WMFFeedNewsStory class]];
}

+ (NSString *)WMFFeedDayResponseMaxAgeKey {
    return @"WMFFeedDayResponseMaxAge";
}

+ (NSArray<NSString *> *)languageVariantCodePropagationSubelementKeys {
    return @[@"featuredArticle",
             @"topRead",
             @"pictureOfTheDay",
             @"newsStories"];
}

// No languageVariantCodePropagationURLKeys

@end

NS_ASSUME_NONNULL_END
