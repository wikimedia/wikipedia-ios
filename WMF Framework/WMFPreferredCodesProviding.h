#ifndef WMFPreferredLanguageCodesProviding_h
#define WMFPreferredLanguageCodesProviding_h
NS_ASSUME_NONNULL_BEGIN
@protocol WMFPreferredCodesProviding

- (void)getPreferredLanguageCodes:(void (^)(NSArray<NSString *> *))completion;
- (void)getPreferredWikiCodes:(void (^)(NSArray<NSString *> *))completion;

@end
NS_ASSUME_NONNULL_END
#endif /* WMFPreferredLanguageCodesProviding_h */
