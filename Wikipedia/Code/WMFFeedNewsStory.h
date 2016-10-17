#import <Mantle/Mantle.h>

@class WMFFeedArticlePreview;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedNewsStory : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong, nullable, readonly) NSString *storyHTML;

@property (nullable, nonatomic, strong, readonly) NSArray<WMFFeedArticlePreview *> *articlePreviews;

@end

NS_ASSUME_NONNULL_END
