//
//  ToCInteractionFunnel.m
//  Wikipedia
//
//  Created by Brion on 6/6/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "ToCInteractionFunnel.h"

@implementation ToCInteractionFunnel

-(id)init
{
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppToCInteraction
    self = [super initWithSchema:@"MobileWikiAppToCInteraction"
                         version:10375484];
    if (self) {
        self.appInstallID = [self persistentUUID:@"ReadingAction"];
    }
    return self;
}

-(NSDictionary *)preprocessData:(NSDictionary *)eventData
{
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[@"appInstallID"] = self.appInstallID;
    return [NSDictionary dictionaryWithDictionary: dict];
}

-(void)logOpen
{
    [self log:@{@"action": @"open"}];
}

-(void)logClose
{
    [self log:@{@"action": @"close"}];
}

-(void)logClick
{
    [self log:@{@"action": @"click"}];
}

@end
