@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocalizedDateFormatStrings : NSObject

+ (NSString *)yearsAgoForWikiLanguage:(nullable NSString *)language;

+ (NSString *)hoursAgo;

+ (NSString *)minutesAgo;

@end

extern NSString *const WMFAbbreviatedRelativeDateAgo;
extern NSString *const WMFAbbreviatedRelativeDate;

@interface NSDate (WMFRelativeDate)

- (NSString *)wmf_localizedRelativeDateStringFromLocalDateToNow; // to now

- (NSString *)wmf_fullyLocalizedRelativeDateStringFromLocalDateToNow;

- (NSString *)wmf_localizedRelativeDateStringFromLocalDateToLocalDate:(NSDate *)date;

- (NSString *)wmf_localizedRelativeDateFromMidnightUTCDate;

- (NSDictionary<NSString *, NSString *> *)wmf_localizedRelativeDateStringFromLocalDateToNowAbbreviated;

@end

NS_ASSUME_NONNULL_END
