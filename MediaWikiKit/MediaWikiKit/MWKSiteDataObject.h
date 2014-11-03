//
//  MWKSiteDataObject.h
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataObject.h"

@class MWKTitle;
@class MWKSite;
@class MWKUser;

@interface MWKSiteDataObject : MWKDataObject

@property (readonly) MWKSite *site;

- (instancetype)initWithSite:(MWKSite *)site;

- (MWKTitle *)optionalTitle:(NSString *)key dict:(NSDictionary *)dict;
- (MWKTitle *)requiredTitle:(NSString *)key dict:(NSDictionary *)dict;

- (MWKUser *)optionalUser:(NSString *)key dict:(NSDictionary *)dict;
- (MWKUser *)requiredUser:(NSString *)key dict:(NSDictionary *)dict;


@end
