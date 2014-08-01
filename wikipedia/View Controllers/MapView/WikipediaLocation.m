//
//  WikipediaLocation.m
//  Wikipedia
//
//  Created by Ulf Buermeyer on 7/11/14.
//  Copyright (c) 2014 Wikimedia Foundation.
//  Provided under MIT-style license; please copy and modify!
//

#import "WikipediaLocation.h"

@implementation WikipediaLocation 


- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                   title:(NSString *)title
                subtitle:(NSString *)subtitle {

    // coordinate is the only required property,
    // see https://developer.apple.com/library/ios/documentation/MapKit/Reference/MKAnnotation_Protocol/Reference/Reference.html
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        _coordinate = coordinate;
        _title = title;
        _subtitle = subtitle;
        return self;
    }
    
    return nil;
}


@end
