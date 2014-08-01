//
//  MapViewController.h
//  Wikipedia
//
//  Created by Ulf Buermeyer on 2014/07/11
//  Copyright (c) 2014 Wikimedia Foundation.
//  Provided under MIT-style license; please copy and modify!
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

#import "WikipediaLocation.h"
#import "WikiGlyphButton.h"
#import "WikiGlyphLabel.h"
#import "WikiGlyph_Chars.h"

#define GEOHACK_URL_PREFIX      @"https://tools.wmflabs.org/geohack/geohack.php"
#define WIKIPEDIA_ANNOTATION    @"WikipediaLocationAnnotation"

@interface MapViewController : UIViewController <MKMapViewDelegate> {
    // need ivars for properties that use custom getters / setters
    NSString *_geohackURL;
}

@property IBOutlet MKMapView *map;
@property IBOutlet WikiGlyphButton *dismissButton;
@property IBOutlet WikiGlyphButton *mapStyleButton;
@property IBOutlet WikiGlyphButton *geoHackButton;
@property NSString *geohackURL;
@property (readonly) WikipediaLocation *wikipediaLocation;

@end
