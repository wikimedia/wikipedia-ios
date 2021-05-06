#import <WMF/WMFMTLModel.h>

@class WMFFeedArticlePreview;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedOnThisDayEvent : WMFMTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable, readonly) NSString *text;

@property (nonatomic, copy, nullable, readonly) NSNumber *year;

@property (nullable, nonatomic, copy, readonly) NSArray<WMFFeedArticlePreview *> *articlePreviews;

@property (nullable, nonatomic, readonly) NSURL *siteURL;

@property (nullable, nonatomic, readonly) NSString *languageCode;

@property (nullable, nonatomic, readonly) NSString *contentLanguageCode;

@property (nullable, nonatomic, copy) NSNumber *score;

@property (nullable, nonatomic, copy) NSNumber *index;

- (NSNumber *)calculateScore;

@end

NS_ASSUME_NONNULL_END
