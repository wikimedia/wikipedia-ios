#import "WMFArticle+CoreDataClass.h"

@implementation WMFArticle

#pragma mark - Transient properties

- (NSDate *)viewedCalendarDate {
    NSString *key = @"viewedCalendarDate";
    [self willAccessValueForKey:key];
    NSDate *viewedCalendarDate = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    
    if (!viewedCalendarDate) {
        NSDate *viewedDate = self.viewedDate;
        if (viewedDate) {
            NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
            NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:viewedDate];
            viewedCalendarDate = [calendar dateFromComponents:components];
            [self setPrimitiveValue:viewedCalendarDate forKey:key];
        }
    }
    return viewedCalendarDate;
}

- (void)setviewedDate:(NSDate *)viewedDate {
    NSString *key = @"viewedDate";
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:nil forKey:@"viewedCalendarDate"];
    [self setPrimitiveValue:viewedDate forKey:key];
    [self didChangeValueForKey:key];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"viewedCalendarDate"]) {
        if (keyPaths) {
            keyPaths = [keyPaths setByAddingObject:@"viewedDate"];
        } else {
            keyPaths = [NSSet setWithObject:@"viewedDate"];
        }
    }
    return keyPaths;
}

@end
