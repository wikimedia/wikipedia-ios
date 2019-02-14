@import WMF.EventLoggingFunnel;

@interface EditFunnel : EventLoggingFunnel

@property NSString *editSessionToken;

- (void)logStart:(NSString *)language;
- (void)logPreview:(NSString *)language;
/**
 * Parameter should be one of the string keys defined at
 * https://meta.wikimedia.org/wiki/Schema_talk:MobileWikiAppEdit#Schema_missing_enum_for_editSummaryTapped
 */
- (void)logEditSummaryTap:(NSString *)editSummaryTapped language:(NSString *)language;
- (void)logSavedRevision:(int)revID language:(NSString *)language;
- (void)logCaptchaShown:(NSString *)language;
- (void)logCaptchaFailure:(NSString *)language;
- (void)logAbuseFilterWarning:(NSString *)name language:(NSString *)language;
- (void)logAbuseFilterError:(NSString *)name language:(NSString *)language;
- (void)logAbuseFilterWarningIgnore:(NSString *)name language:(NSString *)language;
- (void)logAbuseFilterWarningBack:(NSString *)name language:(NSString *)language;
- (void)logSaveAttempt:(NSString *)language;
- (void)logError:(NSString *)code language:(NSString *)language;

- (void)logWikidataDescriptionEditStart:(BOOL)isEditingExistingDescription language:(NSString *)language;
- (void)logWikidataDescriptionEditReady:(BOOL)isEditingExistingDescription language:(NSString *)language;
- (void)logWikidataDescriptionEditSaveAttempt:(BOOL)isEditingExistingDescription language:(NSString *)language;
- (void)logWikidataDescriptionEditSaved:(BOOL)isEditingExistingDescription language:(NSString *)language revID:(NSNumber *)revID;
- (void)logWikidataDescriptionEditError:(BOOL)isEditingExistingDescription language:(NSString *)language errorText:(NSString *)errorText;

@end
