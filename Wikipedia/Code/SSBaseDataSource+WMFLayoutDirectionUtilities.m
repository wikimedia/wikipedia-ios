//
//  SSBaseDataSource+WMFLayoutDirectionUtilities.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/30/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "SSBaseDataSource+WMFLayoutDirectionUtilities.h"

@implementation SSBaseDataSource (WMFLayoutDirectionUtilities)

- (NSUInteger)wmf_startingIndexForApplicationLayoutDirection {
    return [self wmf_startingIndexForLayoutDirection:
                     [[UIApplication sharedApplication] userInterfaceLayoutDirection]];
}

- (NSUInteger)wmf_startingIndexForLayoutDirection:(UIUserInterfaceLayoutDirection)layoutDirection {
    return layoutDirection == UIUserInterfaceLayoutDirectionRightToLeft ? self.numberOfItems - 1 : 0;
}

@end
