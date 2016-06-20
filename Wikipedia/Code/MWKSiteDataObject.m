//
//  MWKSiteDataObject.m
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@interface MWKSiteDataObject ()

@property (readwrite, strong, nonatomic) MWKSite* site;

@end

@implementation MWKSiteDataObject

- (instancetype)initWithSite:(MWKSite*)site {
    NSParameterAssert(site);
    self = [self init];
    if (self) {
        self.site = site;
    }
    return self;
}

#pragma mark - title methods

- (MWKTitle*)optionalTitle:(NSString*)key dict:(NSDictionary*)dict {
    if ([dict[key] isKindOfClass:[NSNumber class]] && ![dict[key] boolValue]) {
        // false sometimes happens. Thanks PHP and weak typing!
        return nil;
    }
    NSString* str = [self optionalString:key dict:dict];
    if (str == nil || str.length == 0) {
        return nil;
    } else {
        return [self.site titleWithString:str];
    }
}

- (MWKTitle*)requiredTitle:(NSString*)key dict:(NSDictionary*)dict {
    return [self requiredTitle:key dict:dict allowEmpty:YES];
}

- (MWKTitle*)requiredTitle:(NSString*)key dict:(NSDictionary*)dict allowEmpty:(BOOL)allowEmpty {
    NSString* str = [self requiredString:key dict:dict allowEmpty:allowEmpty];
    return [self.site titleWithUnescapedString:str];
}

#pragma mark - user methods

- (MWKUser*)optionalUser:(NSString*)key dict:(NSDictionary*)dict {
    id user = dict[key];
    if (user == nil) {
        return nil;
    } else {
        return [[MWKUser alloc] initWithSite:self.site data:user];
    }
}

- (MWKUser*)requiredUser:(NSString*)key dict:(NSDictionary*)dict {
    MWKUser* user = [self optionalUser:key dict:dict];
    if (user == nil) {
        return [self optionalUser:key dict:@{key: [NSNull null]}];
        /*
           @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"missing required user field"
                                     userInfo:@{@"key": key}];
         */
    } else {
        return user;
    }
}

@end
