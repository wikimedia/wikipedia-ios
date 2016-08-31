
#import <Foundation/Foundation.h>

@interface WMFFeedSection : NSObject

/**
 *  The date associated with the section.
 */
@property (nonatomic, strong, readonly) NSDate *date;

/**
 *  The site associated with the section.
 */
@property (nonatomic, strong, readonly) NSURL *siteURL;

@end


@interface WMFContinueReadingFeedSection : WMFFeedSection

@end

@interface WMFMainPageFeedSection : WMFFeedSection

@end

@interface WMFRelatedPagesFeedSection : WMFFeedSection

/**
 *  The url of the article to fetch related titles for.
 */
@property (nonatomic, strong, readonly) NSURL *articleURL;

@end

@interface WMFNearbyFeedSection : WMFFeedSection

/**
 *  The location fetch nearby articles for.
 */
@property (nonatomic, strong, readonly) CLLocation *location;

/**
 *  The placemark cooresponding to the section above.
 */
@property (nonatomic, strong, readonly) CLPlacemark *placemark;

@end

@interface WMFPictureOfTheDayFeedSection : WMFFeedSection

@end

@interface WMFRandomFeedSection : WMFFeedSection

@end

@interface WMFFeaturedArticleFeedSection : WMFFeedSection

@end

@interface WMFMostReadFeedSection : WMFFeedSection

/**
 *  The date to fetch most read reuslts for. Usually this is the day before "date". As we don't get this data until the day after.
 */
@property (nonatomic, strong, readonly) NSDate *mostReadFetchDate;

@end

