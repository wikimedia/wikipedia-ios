#import "WMFSearchFunnel.h"
#import "Wikipedia-Swift.h"

static NSString *const kSchemaName = @"MobileWikiAppiOSSearch";
static int const kSchemaVersion = 18289062; // Please email someone in Discovery (Search Team's Product Manager or a Data Analyst) if you change the schema name or version.
static NSString *const kSearchSessionTokenKey = @"session_token";
static NSString *const kAppInstallIdKey = @"app_install_id";
static NSString *const kActionKey = @"action";
static NSString *const kSourceKey = @"source";
static NSString *const kPositionKey = @"position";
static NSString *const kSearchTypeKey = @"search_type";
static NSString *const kSearchTimeKey = @"time_to_display_results";
static NSString *const kIsAnonKey = @"is_anon";
static NSString *const kPrimaryLanguageKey = @"primary_language";
static NSString *const kSessionIDKey = @"session_id";
static NSString *const kSearchResultsCount = @"number_of_results";
static NSString *const kTimestampKey = @"event_dt";

@interface WMFSearchFunnel ()

@property (nonatomic, strong) NSString *searchSessionToken;

@end

@implementation WMFSearchFunnel

- (instancetype)init {
    self = [super initWithSchema:kSchemaName version:kSchemaVersion];
    return self;
}

- (NSString *)searchSessionToken {
    if (!_searchSessionToken) {
        _searchSessionToken = [[NSUUID UUID] UUIDString];
    }
    return _searchSessionToken;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[kAppInstallIdKey] = self.appInstallID;
    dict[kSearchSessionTokenKey] = self.searchSessionToken;
    dict[kTimestampKey] = [self timestamp];
    dict[kSourceKey] = dict[kSourceKey] ?: @"unknown";
    return [dict copy];
}

- (NSString *)searchLanguage {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *searchLanguage = [userDefaults wmf_currentSearchContentLanguageCode];
    return searchLanguage;
}

- (void)logSearchStartFrom:(nonnull NSString *)source {
    self.searchSessionToken = nil;
    NSDictionary *event = @{kActionKey: @"start", kSourceKey: source};
    NSDictionary *standardized = [self standardizedEvent:event];
    [self log:standardized language:[self searchLanguage]];
}

- (void)logSearchAutoSwitch:(nonnull NSString *)source {
    NSDictionary *event = @{kActionKey: @"autoswitch", kSourceKey: source};
    NSDictionary *standardized = [self standardizedEvent:event];
    [self log:standardized language:[self searchLanguage]];
}

- (void)logSearchDidYouMean:(nonnull NSString *)source {
    NSDictionary *event = @{kActionKey: @"didyoumean", kSourceKey: source};
    NSDictionary *standardized = [self standardizedEvent:event];
    [self log:standardized language:[self searchLanguage]];
}

- (void)logSearchResultTapAt:(NSInteger)position source:(nonnull NSString *)source {
    NSDictionary *event = @{kActionKey: @"click", kPositionKey: [NSNumber numberWithInteger:position], kSourceKey: source};
    NSDictionary *standardized = [self standardizedEvent:event];
    [self log:standardized language:[self searchLanguage]];
}

- (void)logSearchCancel:(nonnull NSString *)source {
    NSDictionary *event = @{kActionKey: @"cancel", kSourceKey: source};
    NSDictionary *standardized = [self standardizedEvent:event];
    [self log:standardized language:[self searchLanguage]];
}

- (void)logSearchLangSwitch:(nonnull NSString *)source {
    NSDictionary *event = @{kActionKey: @"langswitch", kSourceKey: source};
    NSDictionary *standardized = [self standardizedEvent:event];
    [self log:standardized language:[self searchLanguage]];
}

- (void)logSearchResultsWithTypeOfSearch:(WMFSearchType)type resultCount:(NSUInteger)count elapsedTime:(NSTimeInterval)searchTime source:(nonnull NSString *)source {
    NSDictionary *event = @{ kActionKey: @"results",
                             kSearchTypeKey: [[self class] stringForSearchType:type],
                             kSearchResultsCount: @(count),
                             kSearchTimeKey: @((NSInteger)(searchTime * 1000)),
                             kSourceKey: source };
    NSDictionary *standardized = [self standardizedEvent:event];
    [self log:standardized language:[self searchLanguage]];
}

- (void)logShowSearchErrorWithTypeOfSearch:(WMFSearchType)type elapsedTime:(NSTimeInterval)searchTime source:(nonnull NSString *)source {
    NSDictionary *event = @{ kActionKey: @"error",
                             kSearchTypeKey: [[self class] stringForSearchType:type],
                             kSearchTimeKey: @((NSInteger)(searchTime * 1000)),
                             kSourceKey: source };
    NSDictionary *standardizedEvent = [self standardizedEvent:event];
    [self log:standardizedEvent language:[self searchLanguage]];
}

- (NSDictionary *)standardizedEvent:(NSDictionary *)event {
    NSMutableDictionary *standardEvent = [[NSMutableDictionary alloc] initWithObjectsAndKeys:self.isAnon, kIsAnonKey, self.primaryLanguage, kPrimaryLanguageKey, self.sessionID, kSessionIDKey, nil];
    [standardEvent addEntriesFromDictionary:event];
    return standardEvent;
}

+ (NSString *)stringForSearchType:(WMFSearchType)type {
    if (type == WMFSearchTypePrefix) {
        return @"prefix";
    }

    return @"full";
}

@end
