@import Foundation;
@import WMF.WMFLegacyFetcher;

typedef NS_ENUM(NSInteger, WikiTextSectionUploaderErrorType) {
    WikiTextSectionUploaderErrorTypeUnknown = 0,
    WikiTextSectionUploaderErrorTypeServer = 1,
    WikiTextSectionUploaderErrorTypeNeedsCaptcha = 2,
    WikiTextSectionUploaderErrorTypeAbuseFilterDisallowed = 3,
    WikiTextSectionUploaderErrorTypeAbuseFilterWarning = 4,
    WikiTextSectionUploaderErrorTypeAbuseFilterOther = 5,
    WikiTextSectionUploaderErrorTypeBlocked = 6,
    WikiTextSectionUploaderErrorTypeProtectedPage = 7,
};

NS_ASSUME_NONNULL_BEGIN

extern NSString *const NSErrorUserInfoDisplayError;

@interface WikiTextSectionUploader : WMFLegacyFetcher
// Note: "section" parameter needs to be a string because the
// api returns transcluded section indexes with a "T-" prefix
- (void)uploadWikiText:(nullable NSString *)wikiText
         forArticleURL:(NSURL *)articleURL
               section:(nullable NSString *)section
               summary:(nullable NSString *)summary
           isMinorEdit:(BOOL)isMinorEdit
        addToWatchlist:(BOOL)addToWatchlist
             baseRevID:(nullable NSNumber *)baseRevID
             captchaId:(nullable NSString *)captchaId
           captchaWord:(nullable NSString *)captchaWord
              editTags:(nullable NSArray<NSString *> *)editTags
            completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion;

- (void)addSectionWithSummary:(NSString *)summary
                         text:(NSString *)text
                forArticleURL:(NSURL *)articleURL
                   completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion;

- (void)appendToSection:(NSString *)section
                   text:(NSString *)text
          forArticleURL:(NSURL *)articleURL
             completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion;

- (void)prependToSectionID:(NSString *)sectionID
                         text:(NSString *)text
                forArticleURL:(NSURL *)articleURL
                      summary:(nullable NSString *)summary
            isMinorEdit:(BOOL)isMinorEdit
               baseRevID:(nullable NSNumber *)baseRevID
             editTags:(nullable NSArray<NSString *> *)editTags
              completion:(void (^)(NSDictionary * _Nullable result, NSError * _Nullable error))completion;
@end

NS_ASSUME_NONNULL_END
