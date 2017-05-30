#import <Foundation/Foundation.h>

@interface NSDate (WMFRelativeDate)

- (NSString *)wmf_localizedRelativeDateStringFromLocalDateToNow; // to now

- (NSString *)wmf_localizedRelativeDateStringFromLocalDateToLocalDate:(NSDate *)date;

- (NSString *)wmf_localizedRelativeDateFromMidnightUTCDate;

@end
