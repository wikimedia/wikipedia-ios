//
//  NSDate+WMFPOTDTitle.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFPOTDTitlePrefix;

@interface NSDate (WMFPOTDTitle)

/**
 *  Retrieve the URL path of the commons POTD for the date represented by the receiver.
 *
 *  @note Internally, this fetches the "en" localization of this page, as that's most likely to be available, and
 *        the template doesn't automatically fallback if the chosen language isn't available.
 *
 *  @return A string in the format "/YYYY-MM-DD_(en)"
 */
- (NSString *)wmf_picOfTheDayPageTitle;

@end

NS_ASSUME_NONNULL_END
