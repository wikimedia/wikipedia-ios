#import <Foundation/Foundation.h>

@interface NSDate (WMFRelativeDate)

- (NSString *)wmf_localizedRelativeDateFromLocalDate;

- (NSString *)wmf_localizedRelativeDateFromMidnightUTCDate;

@end
