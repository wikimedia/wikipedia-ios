@import WMF.EventLoggingFunnel;

@interface EditFunnel : EventLoggingFunnel

@property NSString *editSessionToken;
@property int userId;

/**
 * Beware that user IDs are per-wiki (per-language) -- we can't save it just at
 * login time.
 */
- (id)initWithUserId:(int)userId;
- (void)logStart;
- (void)logPreview;
/**
 * Parameter should be one of the string keys defined at
 * https://meta.wikimedia.org/wiki/Schema_talk:MobileWikiAppEdit#Schema_missing_enum_for_editSummaryTapped
 */
- (void)logEditSummaryTap:(NSString *)editSummaryTapped;
- (void)logSavedRevision:(int)revID;
- (void)logCaptchaShown;
- (void)logCaptchaFailure;
- (void)logAbuseFilterWarning:(NSString *)name;
- (void)logAbuseFilterError:(NSString *)name;
- (void)logAbuseFilterWarningIgnore:(NSString *)name;
- (void)logAbuseFilterWarningBack:(NSString *)name;
- (void)logSaveAttempt;
- (void)logError:(NSString *)code;

@end
