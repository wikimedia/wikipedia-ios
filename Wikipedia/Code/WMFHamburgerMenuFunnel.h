@import WMF.EventLoggingFunnel;

typedef NS_ENUM(NSUInteger, WMFHamburgerMenuItemType) {
    WMFHamburgerMenuItemTypeLogin,
    WMFHamburgerMenuItemTypeToday,
    WMFHamburgerMenuItemTypeRandom,
    WMFHamburgerMenuItemTypeNearby,
    WMFHamburgerMenuItemTypeRecent,
    WMFHamburgerMenuItemTypeSavedPages,
    WMFHamburgerMenuItemTypeMore,
    WMFHamburgerMenuItemTypeUnknown
};

@interface WMFHamburgerMenuFunnel : EventLoggingFunnel

- (void)logMenuOpen;
- (void)logMenuClose;
- (void)logMenuSelectionWithType:(WMFHamburgerMenuItemType)type;

@end
