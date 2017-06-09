@import Mantle;

@class WMFFeedTopReadArticlePreview;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedTopReadResponse : MTLModel <MTLJSONSerializing>

@property (nullable, nonatomic, strong, readonly) NSDate *date;

@property (nullable, nonatomic, strong, readonly) NSArray<WMFFeedTopReadArticlePreview *> *articlePreviews;

@end

NS_ASSUME_NONNULL_END
