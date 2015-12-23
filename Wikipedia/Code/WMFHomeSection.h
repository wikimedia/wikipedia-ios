
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
+ (nullable instancetype)nearbySectionWithLocation:(nullable CLLocation*)location;
+ (instancetype)historySectionWithHistoryEntry:(MWKHistoryEntry*)entry;
+ (instancetype)savedSectionWithSavedPageEntry:(MWKSavedPageEntry*)entry;

/**
 *  Create a section which displays the featured article of the day for a specific site.
 *
 *  @param site The site to retrieve the featured article from.
 *
 *  @return A featured article section, or @c nil if the given site doesn't support featured articles.
 */
+ (nullable instancetype)featuredArticleSectionWithSiteIfSupported:(MWKSite*)site;

///
/// @name Static Sections
///

+ (instancetype)pictureOfTheDaySection;
+ (instancetype)mainPageSection;
+ (instancetype)randomSection;

/**
 *  The type of section.
 *
 *  Determines which metadata properties are available.
 */
@property (nonatomic, assign, readonly) WMFHomeSectionType type;

/**
 *  When the section was created.
 */
@property (nonatomic, strong, readonly) NSDate* dateCreated;

///
/// @name Metadata Properties
///

/**
 *  The site associated with the section, if any.
 *
 *  Used for the featured article section
 */
@property (nonatomic, strong, readonly) MWKSite* site;

/**
 *  The title associated with the section, if any.
 *
 *  For example, the "seed" title for saved or history items.
 */
@property (nonatomic, strong, readonly) MWKTitle* title;

/**
 *  The location associated with the section, if any.
 *
 *  For example, the location used to get articles for the "nearby" section.
 */
@property (nonatomic, strong, readonly) CLLocation* location;

/**
 *  Determine ordering between two sections.
 *
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