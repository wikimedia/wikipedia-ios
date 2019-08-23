@import WMF.WMFLegacyFetcher;

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFArticleSaveToDiskDidFailNotification;
extern NSString *const WMFArticleSaveToDiskDidFailErrorKey;
extern NSString *const WMFArticleSaveToDiskDidFailArticleURLKey;

@interface SavedArticlesFetcher : WMFLegacyFetcher <NSProgressReporting>

@property (nonatomic, strong) NSProgress *progress;

@property (nonatomic, strong, readonly) NSNumber *fetchesInProcessCount;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
