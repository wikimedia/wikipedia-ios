
#import "MTLModel.h"

typedef NS_ENUM (NSUInteger, WMFSectionSchemaItemType){
    WMFSectionSchemaItemTypeContinueReading,
    WMFSectionSchemaItemTypeRecent,
    WMFSectionSchemaItemTypeSaved,
    WMFSectionSchemaItemTypeNearby,
};

@interface WMFSectionSchemaItem : MTLModel

+ (WMFSectionSchemaItem*)nearbyItem;
+ (WMFSectionSchemaItem*)continueReadingItemWithTitle:(MWKTitle*)title;
+ (WMFSectionSchemaItem*)recentItemWithTitle:(MWKTitle*)title;
+ (WMFSectionSchemaItem*)savedItemWithTitle:(MWKTitle*)title;

@property (nonatomic, assign, readonly) WMFSectionSchemaItemType type;
@property (nonatomic, strong, readonly) MWKTitle* title;

@end
