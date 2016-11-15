#import "WMFArticle+CoreDataProperties.h"

@implementation WMFArticle (CoreDataProperties)

+ (NSFetchRequest<WMFArticle *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"WMFArticle"];
}

@dynamic blocked;
@dynamic key;
@dynamic lastViewedDate;
@dynamic lastViewedFragment;
@dynamic lastViewedScrollPosition;
@dynamic newsNotificationDate;
@dynamic savedDate;
@dynamic wasSignificantlyViewed;

@end
