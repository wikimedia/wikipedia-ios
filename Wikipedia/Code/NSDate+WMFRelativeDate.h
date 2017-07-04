@import Foundation;

@interface WMFLocalizedDateFormatStrings : NSObject

+ (NSString *)yearsAgo;

@end

@interface NSDate (WMFRelativeDate)

- (NSString *)wmf_localizedRelativeDateStringFromLocalDateToNow; // to now

- (NSString *)wmf_localizedRelativeDateStringFromLocalDateToLocalDate:(NSDate *)date;

- (NSString *)wmf_localizedRelativeDateFromMidnightUTCDate;

@end
