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

-(void)logSomethingHappened;

@end
