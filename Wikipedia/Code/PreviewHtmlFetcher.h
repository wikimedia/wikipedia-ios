@import WMF.WMFLegacyFetcher;

NS_ASSUME_NONNULL_BEGIN

@interface PreviewHtmlFetcher : WMFLegacyFetcher

- (void)fetchHTMLForWikiText:(nullable NSString *)wikiText articleURL:(nullable NSURL *)articleURL completion:(void (^)(NSString * _Nullable result, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
