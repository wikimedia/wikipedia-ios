//
//  MWKProtectionStatus.h
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MWKDataObject.h"

@class MWKArticle;

@interface MWKProtectionStatus : MWKDataObject <NSCopying>

-(instancetype)initWithData:(id)data;

-(NSArray *)protectedActions;
-(NSArray *)allowedGroupsForAction:(NSString *)action;

@end
