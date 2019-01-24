@import Foundation;
@import WMF.WMFLegacyFetcher;

typedef NS_ENUM(NSInteger, WikiTextSectionUploaderErrors) {
    WIKITEXT_UPLOAD_ERROR_UNKNOWN = 0,
    WIKITEXT_UPLOAD_ERROR_SERVER = 1,
    WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA = 2,
    WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED = 3,
    WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING = 4,
    WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER = 5
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
