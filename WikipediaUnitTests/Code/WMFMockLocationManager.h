//
//  WMFMockLocationManager.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/23/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFLocationManager.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Location manger which doesn't subscribe to location updates from CLLocationManager.
 *
 *  Never asks CLLocationManager for updates, allowing tests to manually trigger events & set location
 *  and heading values.
 */
@interface WMFMockLocationManager : WMFLocationManager

- (void)setLocation:(CLLocation *)location;

- (void)setHeading:(CLHeading *)heading;

@end

NS_ASSUME_NONNULL_END
