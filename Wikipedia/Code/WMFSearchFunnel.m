#import "WMFSearchFunnel.h"

static NSString *const kSchemaName = @"MobileWikiAppSearch";
static int const kSchemaVersion = 10641988; // Please email someone in Discovery (Search Team's Product Manager or a Data Analyst) if you change the schema name or version.
static NSString *const kSearchSessionTokenKey = @"searchSessionToken";

static NSString *const kActionKey = @"action";
static NSString *const kSearchTypeKey = @"typeOfSearch";
static NSString *const kSearchTimeKey = @"timeToDisplayResults";
static NSString *const kSearchResultsCount = @"numberOfResults";

@interface WMFSearchFunnel ()

@property (nonatomic, strong) NSString *searchSessionToken;

@end

@implementation WMFSearchFunnel

- (instancetype)init {
    self = [super initWithSchema:kSchemaName version:kSchemaVersion];
    if (self) {
        self.rate = 100;
    }
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
    dict[kSearchSessionTokenKey] = self.searchSessionToken;
    return [dict copy];
}

- (void)logSearchStart {
    self.searchSessionToken = nil;
    [self log:@{kActionKey: @"start"}];
}

- (void)logSearchAutoSwitch {
    [self log:@{kActionKey: @"autoswitch"}];
}

- (void)logSearchDidYouMean {
    [self log:@{kActionKey: @"didyoumean"}];
}

- (void)logSearchResultTap {
    [self log:@{kActionKey: @"click"}];
}

- (void)logSearchCancel {
    [self log:@{kActionKey: @"cancel"}];
}

- (void)logSearchResultsWithTypeOfSearch:(WMFSearchType)type resultCount:(NSUInteger)count elapsedTime:(NSTimeInterval)searchTime {
    [self log:@{ kActionKey: @"results",
                 kSearchTypeKey: [[self class] stringForSearchType:type],
                 kSearchResultsCount: @(count),
                 kSearchTimeKey: @((NSInteger)(searchTime * 1000)) }];
}

- (void)logShowSearchErrorWithTypeOfSearch:(WMFSearchType)type elapsedTime:(NSTimeInterval)searchTime {
    [self log:@{ kActionKey: @"error",
                 kSearchTypeKey: [[self class] stringForSearchType:type],
                 kSearchTimeKey: @((NSInteger)(searchTime * 1000)) }];
}

+ (NSString *)stringForSearchType:(WMFSearchType)type {
    if (type == WMFSearchTypePrefix) {
        return @"prefix";
    }

    return @"full";
}

@end
