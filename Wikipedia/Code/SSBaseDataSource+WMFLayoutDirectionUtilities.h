//
//  SSBaseDataSource+WMFLayoutDirectionUtilities.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/30/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <SSDataSources/SSDataSources.h>

@interface SSBaseDataSource (WMFLayoutDirectionUtilities)

- (NSUInteger)wmf_startingIndexForApplicationLayoutDirection;

- (NSUInteger)wmf_startingIndexForLayoutDirection:(UIUserInterfaceLayoutDirection)layoutDirection;

@end
