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

@property (readonly) bool anonymous;
@property (readonly) NSString *name;
@property (readonly) NSString *gender; // used to format UI messages on-wiki

-(instancetype)initWithSite:(MWKSite *)site data:(id)data;

@end
