//
//  MWKProtectionStatus.m
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKProtectionStatus {
    NSDictionary *_protection;
}

-(instancetype)initWithData:(id)data
{
    self = [self init];
    if (self) {
        NSDictionary *wrapper = @{@"protection": data};
        _protection = [self requiredDictionary:@"protection" dict:wrapper];
    }
    return self;
}

-(NSArray *)protectedActions
{
    return [_protection allKeys];
}

-(NSArray *)allowedGroupsForAction:(NSString *)action
{
    return _protection[action];
}

-(BOOL)isEqual:(id)object
{
    if (object == nil) {
        return NO;
    } else if (![object isKindOfClass:[MWKProtectionStatus class]]) {
        return NO;
    } else {
        MWKProtectionStatus *other = (MWKProtectionStatus *)object;
        
        NSArray *myActions = [self protectedActions];
        NSArray *otherActions = [other protectedActions];
        if ([myActions count] != [otherActions count]) {
            return NO;
        }
        for (NSString *action in myActions) {
            if (![[self allowedGroupsForAction:action] isEqualToArray:[other allowedGroupsForAction:action]]) {
                return NO;
            }
        }
        return YES;
    }
}

-(id)dataExport
{
    return _protection;
}

-(id)copyWithZone:(NSZone *)zone
{
    // immutable
    return self;
}

@end
