
@import Mantle;
@import CoreLocation;

@class MWKTitle, MWKHistoryEntry, MWKSavedPageEntry;

typedef NS_ENUM (NSUInteger, WMFHomeSectionType){
    WMFHomeSectionTypeContinueReading,
    WMFHomeSectionTypeToday,
    WMFHomeSectionTypeRandom,
    WMFHomeSectionTypeNearby,
    WMFHomeSectionTypeHistory,
    WMFHomeSectionTypeSaved,
};

@interface WMFHomeSection : MTLModel

+ (WMFHomeSection*)continueReadingSectionWithTitle:(MWKTitle*)title;
+ (WMFHomeSection*)todaySection;
+ (WMFHomeSection*)nearbySectionWithLocation:(CLLocation*)location date:(NSDate*)date;
+ (WMFHomeSection*)randomSection;
+ (WMFHomeSection*)historySectionWithHistoryEntry:(MWKHistoryEntry*)entry;
+ (WMFHomeSection*)savedSectionWithSavedPageEntry:(MWKSavedPageEntry*)entry;

@property (nonatomic, assign, readonly) WMFHomeSectionType type;
@property (nonatomic, strong, readonly) NSDate* dateCreated;

//non-nil for Saved and History
@property (nonatomic, strong, readonly) MWKTitle* title;

//non-nil for Nearby
@property (nonatomic, strong, readonly) CLLocation* location;


@end
