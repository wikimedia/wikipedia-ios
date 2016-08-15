//
//  CLLocation+WMFComparison.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/29/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (WMFComparison)

- (BOOL)wmf_isEqual:(CLLocation *)location;

@end

@interface CLPlacemark (WMFComparison)

- (BOOL)wmf_isEqual:(CLPlacemark *)placemark;

@end
