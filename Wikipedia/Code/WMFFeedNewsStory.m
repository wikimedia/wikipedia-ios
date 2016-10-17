#import "WMFFeedNewsStory.h"
#import "WMFFeedArticlePreview.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedNewsStory

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, storyHTML): @"story",
              WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, articlePreviews): @"links" };
}

+ (NSValueTransformer *)articlePreviewsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[WMFFeedArticlePreview class]];
}

@end

NS_ASSUME_NONNULL_END
