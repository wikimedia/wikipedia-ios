WMF_TECH_DEBT_DEPRECATED
@interface MWLanguageInfo : NSObject

@property (copy) NSString *code;
@property (copy) NSString *dir;

+ (MWLanguageInfo *)languageInfoForCode:(NSString *)code;
+ (BOOL)articleLanguageIsRTL:(MWKArticle *)article;

@end
