//
//  MWKUser.m
//  MediaWikiKit
//
//  Created by Brion on 10/14/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKUser

-(instancetype)initWithSite:(MWKSite *)site data:(id)data
{
    self = [self initWithSite:site];
    if ([data isKindOfClass:[NSNull class]]) {
        _anonymous = YES;
        _name = nil;
        _gender = nil;
    } else if ([data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)data;
        _anonymous = NO;
        _name   = [self requiredString:@"name"   dict:dict];
        _gender = [self requiredString:@"gender" dict:dict];
    } else {
        @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"expected null or user info dict, got something else"
                                     userInfo:@{@"data": data}];
    }
    return self;
}

- (id)dataExport
{
    if (self.anonymous) {
        return [NSNull null];
    } else {
        return @{@"name": self.name,
                 @"gender": self.gender};
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self dataExport]];
}

- (BOOL)isEqual:(id)object
{
    if (object == nil) {
        return NO;
    } else if (![object isKindOfClass:[MWKUser class]]) {
        return NO;
    } else {
        MWKUser *other = object;
        if (self.anonymous && other.anonymous) {
            // well that's all we can do for now
            return YES;
        } else {
            return (self.anonymous == other.anonymous) &&
                   [self.name isEqualToString:other.name] &&
                   [self.gender isEqualToString:other.gender];
        }
    }
}

@end
