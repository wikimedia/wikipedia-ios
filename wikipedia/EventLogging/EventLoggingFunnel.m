//
//  EventLoggingFunnel.m
//  Wikipedia
//
//  Created by Brion on 5/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "EventLoggingFunnel.h"
#import "EventLogger.h"
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
    SessionSingleton *session = [SessionSingleton sharedInstance];
    NSString *wiki = [session.site.language stringByAppendingString:@"wiki"];
    [self log:eventData forWiki:wiki];
}

-(void)log:(NSDictionary *)eventData forWiki:(NSString *)wiki
{
    if ([SessionSingleton sharedInstance].sendUsageReports) {
        (void)[[EventLogger alloc] initAndLogEvent:[self preprocessData:eventData]
                                        forSchema: self.schema
                                         revision: self.revision
                                             wiki: wiki];
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
