
#import <Mantle/Mantle.h>
@import CoreLocation;

@class MWKTitle, MWKHistoryEntry, MWKSavedPageEntry;

NS_ASSUME_NONNULL_BEGIN



/**
 *  Note: Do NOT change these numbers!!
 *  The type is serialized to disk, so if the order of this
 *  enum is modified, the sections will be deserialized incorrectly
 *
 */
typedef NS_ENUM (NSUInteger, WMFHomeSectionType){
    WMFHomeSectionTypeContinueReading = 0,
    WMFHomeSectionTypeMainPage        = 1,
    WMFHomeSectionTypeRandom          = 2,
    WMFHomeSectionTypeNearby          = 3,
    WMFHomeSectionTypeHistory         = 4,
    WMFHomeSectionTypeSaved           = 5,
    WMFHomeSectionTypeFeaturedArticle = 6,
    WMFHomeSectionTypePictureOfTheDay = 7
};

@interface WMFHomeSection : MTLModel

+ (instancetype)continueReadingSectionWithTitle:(MWKTitle*)title;
+ (instancetype)featuredSection;
+ (instancetype)pictureOfTheDaySection;
+ (instancetype)mainPageSection;
+ (instancetype)randomSection;
+ (instancetype)nearbySectionWithLocation:(nullable CLLocation*)location;
+ (instancetype)historySectionWithHistoryEntry:(MWKHistoryEntry*)entry;
+ (instancetype)savedSectionWithSavedPageEntry:(MWKSavedPageEntry*)entry;

@property (nonatomic, assign, readonly) WMFHomeSectionType type;
@property (nonatomic, strong, readonly) NSDate* dateCreated;

//non-nil for Saved and History
@property (nonatomic, strong, readonly) MWKTitle* title;

//non-nil for Nearby
@property (nonatomic, strong, readonly) CLLocation* location;

/**
 *  Use this to sort home sections. Sort currently works like this:
 *  Continue reading is always at the top if present.
 *  The rest of the sections are sorted by their date descending
 *  If featured, main page, random, and nearby are from the "same day", then special sorting takes precendence:
 *  They are always in the order of featured, main page, random, nearby.
 *
 */
- (NSComparisonResult)compare:(WMFHomeSection*)section;

@end

NS_ASSUME_NONNULL_END