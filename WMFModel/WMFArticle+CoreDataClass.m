#import "WMFArticle+CoreDataClass.h"

@implementation WMFArticle

#pragma mark - Transient properties

- (NSDate *)lastViewedCalendarDate {
    NSString *key = @"lastViewedCalendarDate";
    [self willAccessValueForKey:key];
    NSDate *lastViewedCalendarDate = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    
    if (!lastViewedCalendarDate) {
        NSDate *lastViewedDate = self.lastViewedDate;
        if (lastViewedDate) {
            NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
            NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:lastViewedDate];
            lastViewedCalendarDate = [calendar dateFromComponents:components];
            [self setPrimitiveValue:lastViewedCalendarDate forKey:key];
        }
    }
    return lastViewedCalendarDate;
}

- (void)setLastViewedDate:(NSDate *)lastViewedDate {
    NSString *key = @"lastViewedDate";
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:nil forKey:@"lastViewedCalendarDate"];
    [self setPrimitiveValue:lastViewedDate forKey:key];
    [self didChangeValueForKey:key];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"lastViewedCalendarDate"]) {
        if (keyPaths) {
            keyPaths = [keyPaths setByAddingObject:@"lastViewedDate"];
        } else {
            keyPaths = [NSSet setWithObject:@"lastViewedDate"];
        }
    }
    return keyPaths;
}

@end
