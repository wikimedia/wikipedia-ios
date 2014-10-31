//
//  ToCInteractionFunnel.h
//  Wikipedia
//
//  Created by Brion on 6/6/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "EventLoggingFunnel.h"

@interface ToCInteractionFunnel : EventLoggingFunnel

@property NSString *appInstallID;

-(id)init;
-(NSDictionary *)preprocessData:(NSDictionary *)eventData;

-(void)logOpen;
-(void)logClose;
-(void)logClick;

@end
