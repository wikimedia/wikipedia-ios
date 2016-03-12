//
//  NSDate+WMFRelativeDate.h
//  Wikipedia
//
//  Created by Corey Floyd on 2/23/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (WMFRelativeDate)

- (NSString*)wmf_relativeTimestamp;

@end
