#import "WMFArticle+CoreDataProperties.h"

@implementation WMFArticle (CoreDataProperties)

+ (NSFetchRequest<WMFArticle *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"WMFArticle"];
}

@dynamic isBlocked;
@dynamic key;
@dynamic viewedDate;
@dynamic viewedFragment;
@dynamic viewedScrollPosition;
@dynamic newsNotificationDate;
@dynamic savedDate;
@dynamic wasSignificantlyViewed;
@dynamic viewedCalendarDate;

@end
