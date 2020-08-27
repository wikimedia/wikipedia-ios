#import <WMF/WMFMTLModel.h>

@class WMFFeedArticlePreview;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedNewsStory : WMFMTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable, readonly) NSString *storyHTML;

@property (nullable, nonatomic, copy, readwrite) WMFFeedArticlePreview *featuredArticlePreview;

@property (nullable, nonatomic, copy, readonly) NSArray<WMFFeedArticlePreview *> *articlePreviews;

@property (nullable, nonatomic, copy, readonly) NSDate *midnightUTCMonthAndDay; // Year on this date is invalid

+ (nullable NSString *)semanticFeaturedArticleTitleFromStoryHTML:(NSString *)storyHTML siteURL:(NSURL *)siteURL;

@end

NS_ASSUME_NONNULL_END
