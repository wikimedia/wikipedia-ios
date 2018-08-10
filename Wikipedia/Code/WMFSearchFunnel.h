@import WMF.EventLoggingFunnel;

typedef NS_ENUM(NSUInteger, WMFSearchType) {
    WMFSearchTypePrefix = 0,
    WMFSearchTypeFull
};

@interface WMFSearchFunnel : EventLoggingFunnel

- (void)logSearchStartFrom:(nonnull NSString *)source;
- (void)logSearchAutoSwitch;
- (void)logSearchDidYouMean;
- (void)logSearchResultTapAt:(NSInteger)position;
- (void)logSearchCancel;
- (void)logSearchLangSwitch:(nonnull NSString *)source;

- (void)logSearchResultsWithTypeOfSearch:(WMFSearchType)type resultCount:(NSUInteger)count elapsedTime:(NSTimeInterval)searchTime;

- (void)logShowSearchErrorWithTypeOfSearch:(WMFSearchType)type elapsedTime:(NSTimeInterval)searchTime;

@end
