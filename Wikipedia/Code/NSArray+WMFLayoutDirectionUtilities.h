//
//  NSArray+WMFLayoutDirectionUtilities.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/20/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (WMFLayoutDirectionUtilities)

- (NSUInteger)wmf_startingIndexForApplicationLayoutDirection;

- (NSUInteger)wmf_startingIndexForLayoutDirection:
    (UIUserInterfaceLayoutDirection)layoutDirection;

- (instancetype)wmf_reverseArrayIfApplicationIsRTL;

- (instancetype)wmf_reverseArrayIfRTL:
    (UIUserInterfaceLayoutDirection)layoutDirection;

@end
