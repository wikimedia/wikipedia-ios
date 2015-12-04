//
//  NSDate+WMFPOTDTitle.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString* const WMFPOTDTitlePrefix;

@interface NSDate (WMFPOTDTitle)

- (NSString*)wmf_picOfTheDayPageTitle;

@end

NS_ASSUME_NONNULL_END
