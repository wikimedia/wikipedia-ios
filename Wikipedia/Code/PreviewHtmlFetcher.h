@import WMF.FetcherBase;
@class AFHTTPSessionManager;

@interface PreviewHtmlFetcher : FetcherBase

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndFetchHtmlForWikiText:(NSString *)wikiText
                                 articleURL:(NSURL *)articleURL
                                withManager:(AFHTTPSessionManager *)manager
                         thenNotifyDelegate:(id<FetchFinishedDelegate>)delegate;
@end
