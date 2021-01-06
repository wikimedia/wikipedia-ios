@import UIKit;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFPOTDTitlePrefix;

@interface NSDate (WMFPOTDTitle)

/**
 *  Retrieve the URL path of the commons POTD for the date represented by the receiver.
 *
 *  @return A string in the format "Template:Potd/YYYY-MM-DD"
 */
- (NSString *)wmf_picOfTheDayPageTitle;

@end

NS_ASSUME_NONNULL_END
