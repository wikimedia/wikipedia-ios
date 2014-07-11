//
//  MapViewController.m
//  Wikipedia
//
//  Created by Ulf Buermeyer on 2014/07/11
//  Copyright (c) 2014 Wikimedia Foundation.
//  Provided under MIT-style license; please copy and modify!
//

#import "MapViewController.h"

@interface MapViewController ()

// may only be changed internally in order to assure sync with geohackURL
@property (readwrite) WikipediaLocation *wikipediaLocation;

@end


@implementation MapViewController

#pragma mark - custom getters / setters

- (NSString *)geohackURL {
    return _geohackURL;
}


- (void) setGeohackURL:(NSString *)geohackURL {

    if ([geohackURL isEqualToString:_geohackURL]) {
        // location unchanged
        return;
    }
    
    // ok, new location URL
    
    // store
    _geohackURL = geohackURL;
    
    // delete old annotation, just in case
    // we have to check if the anno's class is indeed WikipediaLocation as it might be MKUserLocation
    // or some future Apple addition
    NSArray *annotations = [self.map annotations];
    for (id <MKAnnotation> anno in annotations) {
        if ([anno isKindOfClass:[WikipediaLocation class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.map removeAnnotation:anno];
            });
        }
    } // end loop over annotations
    
    // retrieve coordinates & title string from geohack URL
    // ex: https://tools.wmflabs.org/geohack/geohack.php?pagename=Coit_Tower&params=37_48_09_N_122_24_21_W_region:US-CA_type:landmark
    NSLog(@"parsing geohack URL %@ ... ", geohackURL);
    NSRange range = [geohackURL rangeOfString:GEOHACK_URL_PREFIX];
    NSString *query = [geohackURL substringFromIndex:range.location + 1]; // add 1 to skip '?'
    
    // explode query parameters
    NSArray *params = [query componentsSeparatedByString:@"&"];
    
    // zero-init fields for path components
    NSString *pagename = @"";
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(CLLocationDistanceMax, CLLocationDistanceMax); // CLLocationDistanceMax = NaN for coordinates
    
    // loop over query params
    for (NSString *param in params) {
        
        range = [param rangeOfString:@"pagename"];
        if (range.location != NSNotFound) {
            pagename = [param substringFromIndex:range.location + range.length + 1];
            pagename = [self brushUpTitleString:pagename];
            continue;
        }

        range = [param rangeOfString:@"params"];
        if (range.location != NSNotFound) {
            NSString *coordsString = [param substringFromIndex:range.location + range.length + 1];
            coordinate = [self coordinateFromString:coordsString];
        }
        
    } // end loop over query params
    
    NSLog(@"parsing URL completed, found pagename %@ & lng/lat %f / %f",
          pagename, coordinate.longitude, coordinate.latitude);
    
    // valid coordinates? add annotation
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        self.wikipediaLocation = [[WikipediaLocation alloc] initWithCoordinate:coordinate
                                                                         title:pagename subtitle:nil];
        
        // this needs to be done on the main thread & we may be on any, who knows
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displayAnnotation];
        });
    } // end valid coordinates
    
}


// replace all _ by spaces, capitalize all words in title
- (NSString *)brushUpTitleString:(NSString *)rawTitle {

    NSArray *titleComponents = [rawTitle componentsSeparatedByString:@"_"];
    NSString *newTitle = @"";
    for (NSString *comp in titleComponents) {
        NSString *firstChar = [comp substringToIndex:1];
        NSString *tail = [comp substringFromIndex:1];
        firstChar = [firstChar uppercaseString];
        if([newTitle length] > 0) {
            // already word in title? prepend by space
            newTitle = [newTitle stringByAppendingString:@" "];
        }
        newTitle = [newTitle stringByAppendingString:firstChar];
        // tail might be nil if a title comp is only one character
        if(tail) {
            newTitle = [newTitle stringByAppendingString:tail];
        }
    }

    return newTitle;
}


- (CLLocationCoordinate2D) coordinateFromString:(NSString *)string {

    // "NaN" - init coordinates
    CLLocationDegrees lng = CLLocationDistanceMax;
    CLLocationDegrees lat = CLLocationDistanceMax;
    
    // loop over components of coordinate string
    NSArray *components = [string componentsSeparatedByString:@"_"];
    int step = 0;
    CLLocationDegrees buffer;
    
    for (NSString *comp in components) {
        CLLocationDegrees value = [comp floatValue];
        
        // numerical value?
        // TODO: this fails for coordinates including lng or lat of exactly 0.0 - should be caught
        if (value != 0.0) {
            if (step == 0) {
                // degrees
                buffer = value;
                step++;
                continue;
            }
            else if (step == 1) {
                // minutes
                buffer += (value / 60.0);
                step++;
                continue;
            }
            else if (step == 2) {
                // seconds
                buffer += (value / 3600.0);
                continue;
            }
        } // end comp represents a number
        
        // no number? ok, NSWE chars
        // -> move buffer to appropriate coordinate variable (lng, lat) and set sign +/-
        if ([comp isEqualToString:@"N"]) {
            lat = buffer;
            buffer = 0.0;
            step = 0;
            continue;
        }
        if ([comp isEqualToString:@"S"]) {
            lat = -buffer;
            buffer = 0.0;
            step = 0;
            continue;
        }
        if ([comp isEqualToString:@"E"]) {
            lng = buffer;
            buffer = 0.0;
            step = 0;
            continue;
        }
        if ([comp isEqualToString:@"W"]) {
            lng = -buffer;
            buffer = 0.0;
            step = 0;
            continue;
        }
        
    } // end loop over params components
    
    // check results
    if (lng != CLLocationDistanceMax && lat != CLLocationDistanceMax) {
        // both set to valid values
        return CLLocationCoordinate2DMake(lat, lng);
    }
    
    // parsing failed: return invalid coordinate
    return CLLocationCoordinate2DMake(CLLocationDistanceMax, CLLocationDistanceMax);

}



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // iOS 7 tweaks
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.navigationController.navigationBar.tintColor = [UIColor darkGrayColor];
    }
    
    // basic map config
    self.map.showsUserLocation = NO;
    self.map.delegate = self;
    self.map.mapType = MKMapTypeStandard;
    
    // set map region to display BEFORE zooming in on pin
    // but only if wikipedia location is not yet set
    if (!self.wikipediaLocation) {
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(0.0, 0.0);
        MKCoordinateSpan worldSpan = MKCoordinateSpanMake(90.0, 180.0);
        MKCoordinateRegion region = MKCoordinateRegionMake(center, worldSpan);
        [self.map setRegion:region animated:NO];
    }
    
    // config buttons
    CGFloat size = 34;
    CGFloat baselineOffset = 2.0;

    // dismiss button
    [self.dismissButton.label setWikiText:WIKIGLYPH_X
                                    color:[UIColor blackColor]
                                     size:size
                           baselineOffset:baselineOffset];
    self.dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.dismissButton.enabled = YES;
    [self.dismissButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget: self
                                                                         action: @selector(dismissButtonPushed:)]];
    // map style button
    [self.mapStyleButton.label setWikiText:WIKIGLYPH_GEAR
                                    color:[UIColor blackColor]
                                     size:size
                           baselineOffset:baselineOffset];
    self.mapStyleButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapStyleButton.enabled = YES;
    [self.mapStyleButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                     action: @selector(mapStyleButtonPushed:)]];
    
    // geohack button
    [self.geoHackButton.label setWikiText:WIKIGLYPH_SHARE
                                     color:[UIColor blackColor]
                                      size:size
                            baselineOffset:baselineOffset];
    self.geoHackButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.geoHackButton.enabled = YES;
    [self.geoHackButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                     action: @selector(geoHackButtonPushed:)]];
}


- (void) viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];
    
}


#pragma mark annotation handling
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation {
    
    // check if the view is requested for the only supported annotation, realEstate
    if (![annotation isKindOfClass:[WikipediaLocation class]]) {
        NSLog(@"view for unsupported annotation of class %@ requested",
              NSStringFromClass([annotation class]));
        return nil;
    }

    MKPinAnnotationView *pv = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                              reuseIdentifier:WIKIPEDIA_ANNOTATION];
    pv.draggable = NO;
    pv.animatesDrop = YES;
    pv.enabled = YES;
    pv.canShowCallout = YES;

    // icon
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, 30, 30)];
    imageView.image = [UIImage imageNamed:@"logo-search-placeholder.png"];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    // add rounded corners to annotation icon
    /*
    imageView.layer.cornerRadius = 3;
    imageView.layer.masksToBounds = YES;
    imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    imageView.layer.borderWidth = 1;
     */

    // add accessory view = image to callout
    pv.leftCalloutAccessoryView = imageView;

    return pv;
}


// once self.wikipediaLocation is set, add it as an annotation & zoom in on it
- (void) displayAnnotation {
    
    NSLog(@"displaying self.wikipediaLocation: %@", self.wikipediaLocation);
    
    NSAssert(self.wikipediaLocation, @"self.wikipediaLocation must be set to be displayed");
    if (!self.wikipediaLocation) {
        return;
    }
    
    // choose map region
    CLLocationCoordinate2D center = self.wikipediaLocation.coordinate;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(center,
                                                                   1000,
                                                                   1000);     // span in meters
    [self.map setRegion:region animated:YES];
    
    // add annotation
    [self.map addAnnotation:self.wikipediaLocation];
    
    // select it
    [self.map selectAnnotation:self.wikipediaLocation animated:YES];
    
    // show user location as well
    [self.map setShowsUserLocation:YES];
    
}

#pragma mark - button actions

- (IBAction)dismissButtonPushed:(id)sender {

    NSLog(@"dismissButtonPushed");
    
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];

}


- (IBAction)geoHackButtonPushed:(id)sender {
    
    NSLog(@"geoHackButtonPushed");
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.geohackURL]];
    
}


- (IBAction)mapStyleButtonPushed:(id)sender {
    
    NSLog(@"mapStyleButtonPushed");
    
    [self toggleMapStyle];
    
}


- (void) toggleMapStyle {

    MKMapType mapType = self.map.mapType;
    MKMapType newMapType;
    
    switch (mapType) {
        case MKMapTypeStandard:
            newMapType = MKMapTypeHybrid;
            break;
        case MKMapTypeHybrid:
            newMapType = MKMapTypeSatellite;
            break;
        default:
            newMapType = MKMapTypeStandard;
            break;
    }
    
    self.map.mapType = newMapType;

}





@end
