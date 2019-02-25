#import "EditFunnel.h"
#import <WMF/SessionSingleton.h>

static NSString *const kAppInstallIdKey = @"app_install_id";
static NSString *const kAnonKey = @"anon";
static NSString *const kTimestampKey = @"client_dt";
static NSString *const kWikidataDescriptionEdit = @"wikidataDescriptionEdit";
static NSString *const kActionKey = @"action";
static NSString *const kRevisionIDKey = @"revID";

@implementation EditFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppEdit
    self = [super initWithSchema:@"MobileWikiAppEdit" version:18115551];
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    // session token should be regenerated at every 'start' event
    if ([eventData[kActionKey] isEqualToString:@"start"]) {
        self.editSessionToken = [self singleUseUUID];
    }
    dict[@"session_token"] = self.editSessionToken;
    dict[kAnonKey] = self.isAnon;
    dict[kAppInstallIdKey] = self.appInstallID;
    dict[kTimestampKey] = self.timestamp;
    //dict[@"pageNS"] = @0; // @todo actually get the namespace...
    return [NSDictionary dictionaryWithDictionary:dict];
}

#pragma mark - EditFunnel methods

- (void)logStart:(NSString *)language {
    [self log:@{kActionKey: @"start"} language:language] ;
}

- (void)logPreview:(NSString *)language {
    [self log:@{kActionKey: @"preview"} language:language];
}

- (void)logEditSummaryTap:(NSString *)editSummaryTapped language:(NSString *)language {
    [self log:@{kActionKey: @"editSummaryTap",
                @"editSummaryTapped": editSummaryTapped ? editSummaryTapped : @""} language:language];
}

- (void)logSavedRevision:(int)revID language:(NSString *)language {
    NSNumber *revIDNumber = [NSNumber numberWithInt:revID];
    [self log:@{kActionKey: @"saved",
                kRevisionIDKey: (revIDNumber ? revIDNumber : @"")} language:language];
}

- (void)logCaptchaShown:(NSString *)language {
    [self log:@{kActionKey: @"captchaShown"} language:language];
}

- (void)logCaptchaFailure:(NSString *)language {
    [self log:@{kActionKey: @"captchaFailure"} language:language];
}

- (void)logAbuseFilterWarning:(NSString *)name language:(NSString *)language {
    [self log:@{kActionKey: @"abuseFilterWarning",
                @"abuseFilterName": (name ? name : @"")} language:language];
}

- (void)logAbuseFilterError:(NSString *)name language:(NSString *)language {
    [self log:@{kActionKey: @"abuseFilterError",
                @"abuseFilterName": (name ? name : @"")} language:language];
}

- (void)logAbuseFilterWarningIgnore:(NSString *)name language:(NSString *)language {
    [self log:@{kActionKey: @"abuseFilterWarningIgnore",
                @"abuseFilterName": (name ? name : @"")} language:language];
}

- (void)logAbuseFilterWarningBack:(NSString *)name language:(NSString *)language {
    [self log:@{kActionKey: @"abuseFilterWarningBack",
                @"abuseFilterName": (name ? name : @"")} language:language];
}

- (void)logSaveAttempt:(NSString *)language {
    [self log:@{kActionKey: @"saveAttempt"} language:language];
}

- (void)logError:(NSString *)code language:(NSString *)language {
    [self log:@{kActionKey: @"error",
                @"errorText": (code ? code : @"")} language:language];
}

- (void)logWikidataDescriptionEditStart:(BOOL)isEditingExistingDescription language:(NSString *)language {
    [self log:@{kActionKey: @"start",
                kWikidataDescriptionEdit: [self wikidataDescriptionType:isEditingExistingDescription]} language:language];
}

- (void)logWikidataDescriptionEditReady:(BOOL)isEditingExistingDescription language:(NSString *)language {
    [self log:@{kActionKey: @"ready",
                kWikidataDescriptionEdit: [self wikidataDescriptionType:isEditingExistingDescription]} language:language];
}

- (void)logWikidataDescriptionEditSaveAttempt:(BOOL)isEditingExistingDescription language:(NSString *)language {
    [self log:@{kActionKey: @"saveAttempt",
                kWikidataDescriptionEdit: [self wikidataDescriptionType:isEditingExistingDescription]} language:language];
}

- (void)logWikidataDescriptionEditSaved:(BOOL)isEditingExistingDescription language:(NSString *)language revID:(NSNumber *)revID {
    [self log:@{kActionKey: @"saved",
                kWikidataDescriptionEdit: [self wikidataDescriptionType:isEditingExistingDescription],
                kRevisionIDKey: revID ?: @""} language:language];
}

- (void)logWikidataDescriptionEditError:(BOOL)isEditingExistingDescription language:(NSString *)language errorText:(NSString *)errorText {
    [self log:@{kActionKey: @"error",
                kWikidataDescriptionEdit: [self wikidataDescriptionType:isEditingExistingDescription],
                @"errorText": errorText} language:language];
}

- (NSString *)wikidataDescriptionType:(BOOL)isEditingExistingWikidataDescription {
    return isEditingExistingWikidataDescription ? @"existing" : @"new";
}

@end
