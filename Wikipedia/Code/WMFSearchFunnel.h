@import WMF.EventLoggingFunnel;

typedef NS_ENUM(NSUInteger, WMFSearchType) {
    WMFSearchTypePrefix = 0,
    WMFSearchTypeFull
};

@interface WMFSearchFunnel : EventLoggingFunnel

- (void)logSearchStartFrom:(nonnull NSString *)source;
- (void)logSearchAutoSwitch:(nonnull NSString *)source;
- (void)logSearchDidYouMean:(nonnull NSString *)source;
- (void)logSearchResultTapAt:(NSInteger)position source:(nonnull NSString *)source;
- (void)logSearchCancel:(nonnull NSString *)source;
- (void)logSearchLangSwitch:(nonnull NSString *)source;

- (void)logSearchResultsWithTypeOfSearch:(WMFSearchType)type resultCount:(NSUInteger)count elapsedTime:(NSTimeInterval)searchTime source:(nonnull NSString *)source;

- (void)logShowSearchErrorWithTypeOfSearch:(WMFSearchType)type elapsedTime:(NSTimeInterval)searchTime source:(nonnull NSString *)source;

@end
