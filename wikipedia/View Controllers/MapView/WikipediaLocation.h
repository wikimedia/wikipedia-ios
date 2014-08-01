//
//  WikipediaLocation.h
//  Wikipedia
//
//  Created by Ulf Buermeyer on 7/11/14.
//  Copyright (c) 2014 Wikimedia Foundation.
//  Provided under MIT-style license; please copy and modify!
//

#import <MapKit/MapKit.h>
#import <Foundation/Foundation.h>

@interface WikipediaLocation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic, readonly, copy) NSString *title;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                   title:(NSString *)title
                subtitle:(NSString *)subtitle;

@end
