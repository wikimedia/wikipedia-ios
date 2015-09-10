
#import "MTLModel.h"

typedef NS_ENUM (NSUInteger, WMFSectionSchemaItemType){
    WMFSectionSchemaItemTypeRecent,
    WMFSectionSchemaItemTypeSaved,
    WMFSectionSchemaItemTypeNearby,
};

@interface WMFSectionSchemaItem : MTLModel

+ (WMFSectionSchemaItem*)nearbyItem;
+ (WMFSectionSchemaItem*)recentItemWithTitle:(MWKTitle*)title;
+ (WMFSectionSchemaItem*)savedItemWithTitle:(MWKTitle*)title;

@property (nonatomic, assign, readonly) WMFSectionSchemaItemType type;
@property (nonatomic, strong, readonly) MWKTitle* title;

@end
