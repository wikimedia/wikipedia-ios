#import "WMFSearchFunnel.h"
#import "Wikipedia-Swift.h"

static NSString *const kSchemaName = @"MobileWikiAppSearch";
static int const kSchemaVersion = 18071271; // Please email someone in Discovery (Search Team's Product Manager or a Data Analyst) if you change the schema name or version.
static NSString *const kSearchSessionTokenKey = @"sessionToken";
static NSString *const kAppInstallIdKey = @"appInstallID";
static NSString *const kActionKey = @"action";
static NSString *const kSearchTypeKey = @"typeOfSearch";
static NSString *const kSearchTimeKey = @"timeToDisplayResults";
static NSString *const kSearchResultsCount = @"numberOfResults";
static NSString *const kTimestampKey = @"ts";

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
    return [dict copy];
}

- (NSString *)searchLanguage {
    NSUserDefaults *userDefaults = [NSUserDefaults wmf_userDefaults];
    NSURL *currentSearchLanguageDomain = [userDefaults wmf_currentSearchLanguageDomain];
    NSString *searchLanguage = currentSearchLanguageDomain.wmf_language;
    return searchLanguage;
}

- (void)logSearchStart {
    self.searchSessionToken = nil;
    [self log:@{kActionKey: @"start"} language:[self searchLanguage]];
}

- (void)logSearchAutoSwitch {
    [self log:@{kActionKey: @"autoswitch"} language:[self searchLanguage]];
}

- (void)logSearchDidYouMean {
    [self log:@{kActionKey: @"didyoumean"} language:[self searchLanguage]];
}

- (void)logSearchResultTap {
    [self log:@{kActionKey: @"click"} language:[self searchLanguage]];
}

- (void)logSearchCancel {
    [self log:@{kActionKey: @"cancel"} language:[self searchLanguage]];
}

- (void)logSearchResultsWithTypeOfSearch:(WMFSearchType)type resultCount:(NSUInteger)count elapsedTime:(NSTimeInterval)searchTime {
    [self log:@{ kActionKey: @"results",
                 kSearchTypeKey: [[self class] stringForSearchType:type],
                 kSearchResultsCount: @(count),
                 kSearchTimeKey: @((NSInteger)(searchTime * 1000)) } language:[self searchLanguage]];
}

- (void)logShowSearchErrorWithTypeOfSearch:(WMFSearchType)type elapsedTime:(NSTimeInterval)searchTime {
    [self log:@{ kActionKey: @"error",
                 kSearchTypeKey: [[self class] stringForSearchType:type],
                 kSearchTimeKey: @((NSInteger)(searchTime * 1000)) } language:[self searchLanguage]];
}

+ (NSString *)stringForSearchType:(WMFSearchType)type {
    if (type == WMFSearchTypePrefix) {
        return @"prefix";
    }

    return @"full";
}

@end
