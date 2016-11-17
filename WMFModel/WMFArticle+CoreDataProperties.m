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
@dynamic viewedDateWithoutTime;
@dynamic displayTitle;
@dynamic wikidataDescription;
@dynamic snippet;
@dynamic thumbnailURLString;
@dynamic latitude;
@dynamic longitude;
@dynamic pageViews;


#pragma mark - Transient properties

- (NSDate *)viewdDateWithoutTime {
    NSString *key = @"viewedDateWithoutTime";
    [self willAccessValueForKey:key];
    NSDate *viewedDateWithoutTime = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    
    if (!viewedDateWithoutTime) {
        NSDate *viewedDate = self.viewedDate;
        if (viewedDate) {
            NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
            NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:viewedDate];
            viewedDateWithoutTime = [calendar dateFromComponents:components];
            [self setPrimitiveValue:viewedDateWithoutTime forKey:key];
        }
    }
    return viewedDateWithoutTime;
}

- (void)setViewedDate:(NSDate *)viewedDate {
    NSString *key = @"viewedDate";
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:nil forKey:@"viewedDateWithoutTime"];
    [self setPrimitiveValue:viewedDate forKey:key];
    [self didChangeValueForKey:key];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"viewedDateWithoutTime"]) {
        if (keyPaths) {
            keyPaths = [keyPaths setByAddingObject:@"viewedDate"];
        } else {
            keyPaths = [NSSet setWithObject:@"viewedDate"];
        }
    }
    return keyPaths;
}


@end
