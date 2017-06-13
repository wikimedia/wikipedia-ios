@import Foundation;
@import WMF.NSDateFormatter_WMFExtensions;

#import "NSDate+WMFPOTDTitle.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFPOTDTitlePrefix = @"Template:Potd";

@implementation NSDate (WMFPOTDTitle)

- (NSString *)wmf_picOfTheDayPageTitle {
    return [self wmf_picOfTheDayPageTitleForLanguage:@"en"];
}

- (NSString *)wmf_picOfTheDayPageTitleForLanguage:(NSString *)language {
    NSString *potdTitleDateComponent = [[NSDateFormatter wmf_englishHyphenatedYearMonthDayFormatter] stringFromDate:self];
    NSParameterAssert(potdTitleDateComponent);
    return [WMFPOTDTitlePrefix stringByAppendingFormat:@"/%@_(%@)", potdTitleDateComponent, language];
}

@end

NS_ASSUME_NONNULL_END
