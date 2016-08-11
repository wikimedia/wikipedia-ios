
#import <Mantle/Mantle.h>
@import CoreLocation;

@class MWKHistoryEntry;

NS_ASSUME_NONNULL_BEGIN



/**
 *  Note: Do NOT change these numbers!!
 *  The type is serialized to disk, so if the order of this
 *  enum is modified, the sections will be deserialized incorrectly
 *
 */
typedef NS_ENUM (NSUInteger, WMFExploreSectionType){
    WMFExploreSectionTypeContinueReading = 0,
    WMFExploreSectionTypeMainPage        = 1,
    WMFExploreSectionTypeRandom          = 2,
    WMFExploreSectionTypeNearby          = 3,
    WMFExploreSectionTypeHistory         = 4,
    WMFExploreSectionTypeSaved           = 5,
    WMFExploreSectionTypeFeaturedArticle = 6,
    WMFExploreSectionTypePictureOfTheDay = 7,
    WMFExploreSectionTypeMostRead        = 8
};

@interface WMFExploreSection : MTLModel

+ (instancetype)mostReadSectionForDate:(NSDate*)date siteURL:(NSURL*)url;
+ (instancetype)continueReadingSectionWithArticleURL:(NSURL*)url;
+ (instancetype)nearbySectionWithLocation:(CLLocation*)location placemark:(nullable CLPlacemark*)placemark siteURL:(NSURL*)url;
+ (instancetype)historySectionWithHistoryEntry:(MWKHistoryEntry*)entry;
+ (instancetype)savedSectionWithSavedPageEntry:(MWKHistoryEntry*)entry;
+ (instancetype)pictureOfTheDaySectionWithDate:(NSDate*)date;
+ (instancetype)randomSectionWithSiteURL:(NSURL*)url;

/**
 *  Create a section which displays the featured article of the day for a specific site.
 *
 *  @param site The site to retrieve the featured article from.
 *
 *  @return A featured article section, or @c nil if the given site doesn't support featured articles.
 */
+ (nullable instancetype)featuredArticleSectionWithSiteURLIfSupported:(NSURL*)url;

///
/// @name Static Sections
///

+ (instancetype)mainPageSectionWithSiteURL:(NSURL*)url;

/**
 *  Returns the max number of sections for a section type
 *
 *  @param type The type of sections
 *
 *  @return The max number of sections
 */
+ (NSUInteger)maxNumberOfSectionsForType:(WMFExploreSectionType)type;

/**
 *  Returns the max number of all sections
 *
 *  @return The total max number of ALL sections types
 */
+ (NSUInteger)totalMaxNumberOfSections;


/**
 *  The type of section.
 *
 *  Determines which metadata properties are available.
 */
@property (nonatomic, assign, readonly) WMFExploreSectionType type;

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
@property (nonatomic, strong, readonly) NSURL* siteURL;

/**
 *  The title associated with the section, if any.
 *
 *  For example, the "seed" title for saved or history items.
 */
@property (nonatomic, strong, readonly) NSURL* articleURL;

/**
 *  The location associated with the section, if any.
 *
 *  For example, the location used to get articles for the "nearby" section.
 */
@property (nonatomic, strong, readonly) CLLocation* location;

/**
 *  The placemark associated with the section, if any.
 *
 */
@property (nonatomic, strong, readonly) CLPlacemark* placemark;

/**
 *  The date to fetch most read reuslts for.
 *
 *  This is not the same as date created, as the date the section was created (and how it's sorted with respect to
 *  other sections) is not the same as the date results were fetched for.
 */
@property (nonatomic, strong, readonly) NSDate* mostReadFetchDate;

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
- (NSComparisonResult)compare:(WMFExploreSection*)section;

@end

NS_ASSUME_NONNULL_END