//
//  ReadingActionFunnel.h
//  Wikipedia
//
//  Created by Brion on 5/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "EventLoggingFunnel.h"

@interface ReadingActionFunnel : EventLoggingFunnel

@property NSString *appInstallID;

/**
 * Note this method is not actually used; the appInstallID key is instead
 * sent with the 'action=mobileview' API request on a fresh page read.
 */
- (void)logSomethingHappened;

@end
