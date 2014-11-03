//
//  MWKSiteDataObject.m
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKSiteDataObject

- (instancetype)initWithSite:(MWKSite *)site
{
    self = [self init];
    if (self) {
        _site = site;
    }
    return self;
}

#pragma mark - title methods

- (MWKTitle *)optionalTitle:(NSString *)key dict:(NSDictionary *)dict
{
    NSString *str = [self optionalString:key dict:dict];
    if (str == nil) {
        return nil;
    } else {
        return [self.site titleWithString:str];
    }
}

- (MWKTitle *)requiredTitle:(NSString *)key dict:(NSDictionary *)dict
{
    NSString *str = [self requiredString:key dict:dict];
    return [self.site titleWithString:str];
}

#pragma mark - user methods

- (MWKUser *)optionalUser:(NSString *)key dict:(NSDictionary *)dict
{
    id user = dict[key];
    if (user == nil) {
        return nil;
    } else {
        return [[MWKUser alloc] initWithSite:self.site data:user];
    }
}

- (MWKUser *)requiredUser:(NSString *)key dict:(NSDictionary *)dict
{
    MWKUser *user = [self optionalUser:key dict:dict];
    if (user == nil) {
        @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"missing required user field"
                                     userInfo:@{@"key": key}];
    } else {
        return user;
    }
}

@end
