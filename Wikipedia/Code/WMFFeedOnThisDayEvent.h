@import Mantle.MTLModel;
@import Mantle.MTLJSONAdapter;

@class WMFFeedArticlePreview;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedOnThisDayEvent : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable, readonly) NSString *text;

@property (nonatomic, copy, nullable, readonly) NSNumber *year;

@property (nullable, nonatomic, copy, readonly) NSArray<WMFFeedArticlePreview *> *articlePreviews;

@end

NS_ASSUME_NONNULL_END
