#import <WMF/FetcherBase.h>

@class MWKSection;

typedef NS_ENUM(NSInteger, WikiTextFetcherErrorType) {
    WIKITEXT_FETCHER_ERROR_UNKNOWN = 0,
    WIKITEXT_FETCHER_ERROR_API = 1,
    WIKITEXT_FETCHER_ERROR_INCOMPLETE = 2
};

@class AFHTTPSessionManager;

@interface WikiTextSectionFetcher : FetcherBase

@property (strong, nonatomic, readonly) MWKSection *section;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndFetchWikiTextForSection:(MWKSection *)section
                                   withManager:(AFHTTPSessionManager *)manager
                            thenNotifyDelegate:(id<FetchFinishedDelegate>)delegate;
@end
