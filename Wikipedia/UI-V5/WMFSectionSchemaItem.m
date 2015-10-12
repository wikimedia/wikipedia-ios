
#import "WMFSectionSchemaItem.h"

@interface WMFSectionSchemaItem ()

@property (nonatomic, assign, readwrite) WMFSectionSchemaItemType type;
@property (nonatomic, strong, readwrite) MWKTitle* title;

@end

@implementation WMFSectionSchemaItem

+ (WMFSectionSchemaItem*)nearbyItem {
    WMFSectionSchemaItem* item = [[WMFSectionSchemaItem alloc] init];
    item.type = WMFSectionSchemaItemTypeNearby;
    return item;
}

+ (WMFSectionSchemaItem*)continueReadingItemWithTitle:(MWKTitle*)title {
    WMFSectionSchemaItem* item = [[WMFSectionSchemaItem alloc] init];
    item.type  = WMFSectionSchemaItemTypeContinueReading;
    item.title = title;
    return item;
}

+ (WMFSectionSchemaItem*)recentItemWithTitle:(MWKTitle*)title {
    WMFSectionSchemaItem* item = [[WMFSectionSchemaItem alloc] init];
    item.type  = WMFSectionSchemaItemTypeRecent;
    item.title = title;
    return item;
}

+ (WMFSectionSchemaItem*)savedItemWithTitle:(MWKTitle*)title {
    WMFSectionSchemaItem* item = [[WMFSectionSchemaItem alloc] init];
    item.type  = WMFSectionSchemaItemTypeSaved;
    item.title = title;
    return item;
}

@end
