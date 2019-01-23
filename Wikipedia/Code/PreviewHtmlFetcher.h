@import WMF.WMFLegacyFetcher;

@interface PreviewHtmlFetcher : WMFLegacyFetcher

- (void)fetchHTMLForWikiText:(NSString *)wikiText articleURL:(NSURL *)articleURL completion:(void (^)(NSString * _Nullable result, NSError * _Nullable error))completion;

@end
