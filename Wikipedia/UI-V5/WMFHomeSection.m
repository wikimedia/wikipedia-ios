
#import "WMFHomeSection.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKHistoryEntry.h"
#import "MWKSavedPageEntry.h"

@interface WMFHomeSection ()

@property (nonatomic, assign, readwrite) WMFHomeSectionType type;
@property (nonatomic, strong, readwrite) MWKTitle* title;
@property (nonatomic, strong, readwrite) NSDate* dateCreated;
@property (nonatomic, strong, readwrite) CLLocation* location;

@end

@implementation WMFHomeSection

- (instancetype)init{
    self = [super init];
    if (self) {
        self.dateCreated = [NSDate date];
    }
    return self;
}

+ (WMFHomeSection*)continueReadingSectionWithTitle:(MWKTitle*)title {
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type  = WMFHomeSectionTypeContinueReading;
    item.title = title;
    return item;
}

+ (WMFHomeSection*)todaySection{
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type = WMFHomeSectionTypeToday;
    return item;
}

+ (WMFHomeSection*)nearbySectionWithLocation:(CLLocation*)location date:(NSDate*)date{
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type = WMFHomeSectionTypeNearby;
    item.location = location;
    if(date){
        item.dateCreated = date;
    }
    return item;
}

+ (WMFHomeSection*)randomSection{
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type = WMFHomeSectionTypeRandom;
    return item;
}

+ (WMFHomeSection*)historySectionWithHistoryEntry:(MWKHistoryEntry*)entry {
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type  = WMFHomeSectionTypeHistory;
    item.title = entry.title;
    item.dateCreated = entry.date;
    return item;
}

+ (WMFHomeSection*)savedSectionWithSavedPageEntry:(MWKSavedPageEntry*)entry {
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type  = WMFHomeSectionTypeSaved;
    item.title = entry.title;
    item.dateCreated = entry.date;
    return item;
}

@end
