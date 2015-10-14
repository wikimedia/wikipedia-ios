//
//  MWKTitle+Random.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKTitle.h"

@interface MWKTitle (Random)

+ (instancetype)random;

+ (instancetype)randomWithFragment:(NSString*)fragment;

@end
