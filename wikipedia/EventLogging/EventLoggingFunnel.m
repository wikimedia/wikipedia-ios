//
//  EventLoggingFunnel.m
//  Wikipedia
//
//  Created by Brion on 5/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "EventLoggingFunnel.h"
#import "LogEventOp.h"
#import "QueuesSingleton.h"
#import "SessionSingleton.h"

@implementation EventLoggingFunnel

-(id)initWithSchema:(NSString *)schema version:(int)revision
{
    if (self) {
        self.schema = schema;
        self.revision = revision;
    }
    return self;
}

-(NSDictionary *)preprocessData:(NSDictionary *)eventData
{
    return eventData;
}

-(void)log:(NSDictionary *)eventData
{
    if ([SessionSingleton sharedInstance].sendUsageReports) {
        LogEventOp *logOp = [[LogEventOp alloc] initWithSchema: self.schema
                                                      revision: self.revision
                                                         event: [self preprocessData:eventData]];
        
        [[QueuesSingleton sharedInstance].eventLoggingQ addOperation:logOp];
    }
}

-(NSString *)singleUseUUID
{
    return [[NSUUID UUID] UUIDString];
}

-(NSString *)persistentUUID:(NSString *)key
{
    NSString *prefKey = [@"EventLoggingID-" stringByAppendingString:key];
    NSString *uuid = [[NSUserDefaults standardUserDefaults] objectForKey:prefKey];
    if (!uuid) {
        uuid = [self singleUseUUID];
        [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:prefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return uuid;
}

@end
