//
//  SSArrayDataSource+WMFReverseIfRTL.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/8/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <SSDataSources/SSDataSources.h>

@interface SSArrayDataSource (WMFReverseIfRTL)

/**
 *  Initialize a data source with @c items, reversing if the application is in a legacy, RTL environment.
 *
 *  Reversing the items when RTL and iOS 8 is part of having RTL-compliant galleries, since the first item needs to be
 *  at the "end" of the list <i>and</i> the last needs to begin scrolled to the end.  iOS 9 handles all of this for us
 *  at the UIKit level.
 *
 *  @param items The items to populate the receiver with.
 *
 *  @return A new data source.
 */
- (instancetype)wmf_initWithItemsAndReverseIfNeeded:(NSArray*)items;

@end
