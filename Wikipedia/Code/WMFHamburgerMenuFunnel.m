#import "WMFHamburgerMenuFunnel.h"

static NSString *const kSchemaName = @"MobileWikiAppNavMenu";
static int const kSchemaVersion = 12732211;
static NSString *const kAppInstallIdKey = @"appInstallID";
static NSString *const kSessionTokenKey = @"sessionToken";
static NSString *const kActionKey = @"action";
static NSString *const kMenuTypeKey = @"menuItem";

@interface WMFHamburgerMenuFunnel ()

@property (nonatomic, strong) NSString *sessionToken;

@end

@implementation WMFHamburgerMenuFunnel

- (instancetype)init {
    self = [super initWithSchema:kSchemaName version:kSchemaVersion];
    if (self) {
        _sessionToken = [self singleUseUUID];
    }
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[kAppInstallIdKey] = self.appInstallID;
    dict[kSessionTokenKey] = self.sessionToken;
    return [dict copy];
}

- (void)logMenuOpen {
    [self log:@{kActionKey: @"open"}];
}

- (void)logMenuClose {
    [self log:@{kActionKey: @"cancel"}];
}

- (void)logMenuSelectionWithType:(WMFHamburgerMenuItemType)type {
    [self log:@{kActionKey: @"select",
                kMenuTypeKey: [self stringForMenuItemType:type]}];
}

- (NSString *)stringForMenuItemType:(WMFHamburgerMenuItemType)type {
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @(WMFHamburgerMenuItemTypeLogin): @"Login",
            @(WMFHamburgerMenuItemTypeToday): @"Today",
            @(WMFHamburgerMenuItemTypeRandom): @"Random",
            @(WMFHamburgerMenuItemTypeNearby): @"Nearby",
            @(WMFHamburgerMenuItemTypeRecent): @"Recent",
            @(WMFHamburgerMenuItemTypeSavedPages): @"SavedPages",
            @(WMFHamburgerMenuItemTypeMore): @"More",
            @(WMFHamburgerMenuItemTypeUnknown): @"Unknown"
        };
    });
    return map[@(type)] ?: map[@(WMFHamburgerMenuItemTypeUnknown)];
}

@end
