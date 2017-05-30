WMF_TECH_DEBT_DEPRECATED
NS_ASSUME_NONNULL_BEGIN
@interface MWLanguageInfo : NSObject

@property (copy) NSString *code;
@property (copy) NSString *dir;

+ (MWLanguageInfo *)languageInfoForCode:(NSString *)code;
+ (BOOL)articleLanguageIsRTL:(nullable MWKArticle *)article;
+ (UISemanticContentAttribute)semanticContentAttributeForWMFLanguage:(nullable NSString *)language;

@end
NS_ASSUME_NONNULL_END
