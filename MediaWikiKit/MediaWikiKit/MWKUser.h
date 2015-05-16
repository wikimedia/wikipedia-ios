//
//  MWKUser.h
//  MediaWikiKit
//
//  Created by Brion on 10/14/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

#import "MWKSiteDataObject.h"

@interface MWKUser : MWKSiteDataObject

@property (readonly, assign, nonatomic) BOOL anonymous;
@property (readonly, copy, nonatomic) NSString* name;
@property (readonly, copy, nonatomic) NSString* gender;

- (instancetype)initWithSite:(MWKSite*)site data:(id)data;

@end
