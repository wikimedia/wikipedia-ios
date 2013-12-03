//
//  Site.h
//  Wikipedia-iOS
//
//  Created by Brion on 11/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPageTitle.h"

@interface MWSite : NSObject

@property NSString *domain;

- (id)initWithDomain:(NSString *)domain;
- (MWPageTitle *)titleForInternalLink:(NSString *)path;

@end
