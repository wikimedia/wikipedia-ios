@import WMF.EventLoggingFunnel;

typedef NS_ENUM(NSUInteger, WMFSearchType) {
    WMFSearchTypePrefix = 0,
    WMFSearchTypeFull
};

@interface WMFSearchFunnel : EventLoggingFunnel

- (void)logSearchStartFrom:(nullable NSString *)source;
- (void)logSearchAutoSwitch;
- (void)logSearchDidYouMean;
- (void)logSearchResultTap;
- (void)logSearchCancel;
- (void)logSearchLangSwitch:(nullable NSString *)source;

- (void)logSearchResultsWithTypeOfSearch:(WMFSearchType)type resultCount:(NSUInteger)count elapsedTime:(NSTimeInterval)searchTime;

- (void)logShowSearchErrorWithTypeOfSearch:(WMFSearchType)type elapsedTime:(NSTimeInterval)searchTime;

@end
