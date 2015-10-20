
#import <Mantle/Mantle.h>
@import CoreLocation;

@class MWKTitle, MWKHistoryEntry, MWKSavedPageEntry;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, WMFHomeSectionType){
    WMFHomeSectionTypeContinueReading,
    WMFHomeSectionTypeToday,
    WMFHomeSectionTypeRandom,
    WMFHomeSectionTypeNearby,
    WMFHomeSectionTypeHistory,
    WMFHomeSectionTypeSaved,
};

@interface WMFHomeSection : MTLModel

+ (instancetype)continueReadingSectionWithTitle:(MWKTitle*)title;
+ (instancetype)todaySection;
+ (instancetype)nearbySectionWithLocation:(nullable CLLocation*)location date:(nullable NSDate*)date;
+ (instancetype)randomSection;
+ (instancetype)historySectionWithHistoryEntry:(MWKHistoryEntry*)entry;
+ (instancetype)savedSectionWithSavedPageEntry:(MWKSavedPageEntry*)entry;

@property (nonatomic, assign, readonly) WMFHomeSectionType type;
@property (nonatomic, strong, readonly) NSDate* dateCreated;

//non-nil for Saved and History
@property (nonatomic, strong, readonly) MWKTitle* title;

//non-nil for Nearby
@property (nonatomic, strong, readonly) CLLocation* location;


@end

NS_ASSUME_NONNULL_END