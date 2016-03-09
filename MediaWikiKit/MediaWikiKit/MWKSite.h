//  Created by Brion on 11/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#pragma once

#import <Foundation/Foundation.h>

// forward decl
@class MWKTitle;
@class MWKUser;

@interface MWKSite : NSObject

@property (readonly) NSString *domain;
@property (readonly) NSString *language;

- (instancetype)initWithDomain:(NSString *)domain language:(NSString *)language;

- (MWKTitle *)titleWithString:(NSString *)string;
- (MWKTitle *)titleWithInternalLink:(NSString *)path;

+ (MWKSite *)siteWithDomain:(NSString *)domain language:(NSString *)language;

@end
