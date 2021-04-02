#ifndef WMFPreferredLanguageCodesProviding_h
#define WMFPreferredLanguageCodesProviding_h
NS_ASSUME_NONNULL_BEGIN
@protocol WMFPreferredLanguageInfoProvider

- (void)getPreferredContentLanguageCodes:(void (^)(NSArray<NSString *> *))completion;
- (void)getPreferredLanguageCodes:(void (^)(NSArray<NSString *> *))completion;

@end
NS_ASSUME_NONNULL_END
#endif /* WMFPreferredLanguageCodesProviding_h */
