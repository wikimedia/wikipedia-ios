#import "WMFFeedDayResponse.h"
#import "WMFFeedArticlePreview.h"
#import "WMFFeedImage.h"
#import "WMFFeedTopReadResponse.h"
#import "WMFFeedNewsStory.h"

NS_ASSUME_NONNULL_BEGIN
@implementation WMFFeedDayResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH(WMFFeedDayResponse.new, featuredArticle): @"tfa",
              WMF_SAFE_KEYPATH(WMFFeedDayResponse.new, topRead): @"mostread",
              WMF_SAFE_KEYPATH(WMFFeedDayResponse.new, pictureOfTheDay): @"image",
              WMF_SAFE_KEYPATH(WMFFeedDayResponse.new, newsStories): @"news" };
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

@end

NS_ASSUME_NONNULL_END
