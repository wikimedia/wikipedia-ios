#import "WMFFeedNewsStory.h"
#import "WMFFeedArticlePreview.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedNewsStory

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, storyHTML): @"story",
              WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, articlePreviews): @"links",
              WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, featuredArticlePreview): @"featuredArticlePreview" };
}

+ (NSValueTransformer *)articlePreviewsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[WMFFeedArticlePreview class]];
}

+ (NSUInteger)modelVersion {
    return 3;
}

@end

NS_ASSUME_NONNULL_END
