#import "WMFArticle+CoreDataProperties.h"

@implementation WMFArticle (CoreDataProperties)

+ (NSFetchRequest<WMFArticle *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"WMFArticle"];
}

@dynamic isExcludedFromFeed;
@dynamic isDownloaded;
@dynamic key;
@dynamic viewedDate;
@dynamic viewedFragment;
@dynamic viewedScrollPosition;
@dynamic newsNotificationDate;
@dynamic savedDate;
@dynamic wasSignificantlyViewed;
@dynamic viewedDateWithoutTime;
@dynamic displayTitle;
@dynamic wikidataDescription;
@dynamic snippet;
@dynamic thumbnailURLString;
@dynamic imageURLString;
@dynamic imageWidth;
@dynamic imageHeight;
@dynamic latitude;
@dynamic longitude;
@dynamic pageViews;
@dynamic signedQuadKey;
@dynamic geoDimensionNumber;
@dynamic geoTypeNumber;
@dynamic placesSortOrder;

@end
