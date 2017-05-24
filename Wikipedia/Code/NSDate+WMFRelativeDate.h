#import <Foundation/Foundation.h>

@interface NSDate (WMFRelativeDate)

- (NSString *)wmf_relativeTimestamp;

- (NSString *)wmf_localizedRelativeDateFromMidnightUTCDate;

@end
