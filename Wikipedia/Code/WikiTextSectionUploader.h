@import Foundation;
@import WMF.WMFLegacyFetcher;

typedef NS_ENUM(NSInteger, WikiTextSectionUploaderErrors) {
    WikiTextSectionUploaderErrorsUnknown = 0,
    WikiTextSectionUploaderErrorsServer = 1,
    WikiTextSectionUploaderErrorsNeedsCaptcha = 2,
    WikiTextSectionUploaderErrorsAbuseFilterDisallowed = 3,
    WikiTextSectionUploaderErrorsAbuseFilterWarning = 4,
    WikiTextSectionUploaderErrorsAbuseFilterOther = 5
};

NS_ASSUME_NONNULL_BEGIN

@interface WikiTextSectionUploader : WMFLegacyFetcher
// Note: "section" parameter needs to be a string because the
// api returns transcluded section indexes with a "T-" prefix
- (void)uploadWikiText:(nullable NSString *)wikiText
         forArticleURL:(NSURL *)articleURL
               section:(NSString *)section
               summary:(nullable NSString *)summary
             captchaId:(nullable NSString *)captchaId
           captchaWord:(nullable NSString *)captchaWord
            completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion;
@end

NS_ASSUME_NONNULL_END
