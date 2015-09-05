//
//  MWKTitleAssociated.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWKTitle;

@protocol MWKTitleAssociated <NSObject>

- (MWKTitle* __nullable)title;

@end
