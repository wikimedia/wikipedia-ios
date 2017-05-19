#import <Mantle/Mantle.h>

@class WMFFeedArticlePreview;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedNewsStory : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable, readonly) NSString *storyHTML;

@property (nullable, nonatomic, copy, readwrite) WMFFeedArticlePreview *featuredArticlePreview;

@property (nullable, nonatomic, copy, readonly) NSArray<WMFFeedArticlePreview *> *articlePreviews;

@property (nullable, nonatomic, copy, readonly) NSDate *midnightUTCMonthAndDay; // Year on this date is invalid

@end

NS_ASSUME_NONNULL_END
