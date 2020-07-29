#import <WMF/WMFMTLModel.h>

@class WMFFeedArticlePreview;
@class WMFFeedTopReadResponse;
@class WMFFeedImage;
@class WMFFeedNewsStory;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedDayResponse : WMFMTLModel <MTLJSONSerializing>

@property (nonatomic) NSInteger maxAge;
+ (NSString *)WMFFeedDayResponseMaxAgeKey;

@property (nonatomic, strong, nullable, readonly) WMFFeedArticlePreview *featuredArticle;
@property (nonatomic, strong, nullable, readonly) WMFFeedTopReadResponse *topRead;

@property (nonatomic, strong, nullable, readonly) WMFFeedImage *pictureOfTheDay;

@property (nonatomic, strong, nullable, readonly) NSArray<WMFFeedNewsStory *> *newsStories;

@end

NS_ASSUME_NONNULL_END
