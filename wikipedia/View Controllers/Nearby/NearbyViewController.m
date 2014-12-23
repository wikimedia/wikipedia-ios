//  Created by Monte Hurd on 8/8/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NearbyViewController.h"
#import "NearbyResultCollectionCell.h"
#import "NearbyFetcher.h"
#import "ThumbnailFetcher.h"
#import "QueuesSingleton.h"
#import "PaddedLabel.h"
#import "WikipediaAppUtils.h"
#import "UIViewController+ModalPop.h"
#import "SessionSingleton.h"
#import "RootViewController.h"
#import "CenterNavController.h"
#import "UIViewController+Alert.h"
#import "NSString+Extras.h"
#import <MapKit/MapKit.h>
#import "Defines.h"
#import "NSString+Extras.h"
#import "UICollectionViewCell+DynamicCellHeight.h"

#define TABLE_CELL_ID @"NearbyResultCollectionCell"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface NearbyViewController ()

@property (strong, nonatomic) NSArray *nearbyDataArray;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *deviceLocation;
@property (strong, nonatomic) CLHeading *deviceHeading;
@property (nonatomic) dispatch_queue_t imageFetchQ;
@property (strong, nonatomic) UIActionSheet *actionSheet;
@property (strong, nonatomic) NSIndexPath *longPressIndexPath;
@property (nonatomic) BOOL refreshNeeded;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) NSString *cachePath;
@property (nonatomic) BOOL headingAvailable;
@property (strong, nonatomic) NearbyResultCollectionCell *offScreenSizingCell;

@end

/*
    // NearbyFetcher returns data formatted as follows:

	self.nearbyDataArray = (
        (
                {
            coordinate = *CLLocationCoordinate2D struct*;
            initialDistance = "207.4141690965082";
            pageid = 26536263;
            pageimage = "Barbican_Centre_logo.svg";
            thumbnail =             {
                height = 38;
                source = "https://upload.wikimedia.org/wikipedia/en/thumb/e/e3/Barbican_Centre_logo.svg/50px-Barbican_Centre_logo.svg.png";
                width = 50;
            };
            title = "Barbican Centre";
        },
                {
            coordinates = *CLLocationCoordinate2D struct*;
            initialDistance = "324.2053114467474";
            pageid = 2303936;
            pageimage = "William_Davenant.jpg";
            thumbnail =             {
                height = 50;
                source = "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/William_Davenant.jpg/33px-William_Davenant.jpg";
                width = 33;
            };
            title = "Rutland House";
        },
        ...
*/

@implementation NearbyViewController

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *rowData = [self getRowDataForIndexPath:indexPath];
    NSString *title = rowData[@"title"];
    [NAV loadArticleWithTitle: [[SessionSingleton sharedInstance].searchSite titleWithString:title]
                     animated: YES
              discoveryMethod: MWK_DISCOVERY_METHOD_SEARCH
            invalidatingCache: NO
                   popToWebVC: NO];

    [self popModalToRoot];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.headingAvailable = [CLLocationManager headingAvailable];
        self.refreshNeeded = YES;
        self.longPressIndexPath = nil;
        self.deviceLocation = nil;
        self.deviceHeading = nil;
        self.nearbyDataArray = @[@[]];
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.activityType = CLActivityTypeFitness;

        // Needed by iOS 8.
        SEL selector = NSSelectorFromString(@"requestWhenInUseAuthorization");
        if ([self.locationManager respondsToSelector:selector]) {
            NSInvocation *invocation =
            [NSInvocation invocationWithMethodSignature: [[self.locationManager class] instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:self.locationManager];
            [invocation invoke];
        }
        
        self.imageFetchQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.placeholderImage = [UIImage imageNamed:@"logo-placeholder-nearby.png"];
        NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        self.cachePath = [cachePaths objectAtIndex:0];
    }
    return self;
}

// Handle nav bar taps. (same way as any other view controller would)
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
        case NAVBAR_LABEL:
            [self popModal];

            break;
        default:
            break;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.locationManager stopUpdatingLocation];

    if (self.headingAvailable) {
        [self.locationManager stopUpdatingHeading];
    }

    [[QueuesSingleton sharedInstance].nearbyFetchManager.operationQueue cancelAllOperations];

    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];
}

-(NavBarMode)navBarMode
{
    return NAVBAR_MODE_X_WITH_LABEL;
}

-(NSString *)title
{
    return MWLocalizedString(@"nearby-title", nil);
}

-(void)refreshWasPulled
{
    [self performSelector:@selector(refresh) withObject:nil afterDelay:0.15];
}

-(void)refresh
{
    self.nearbyDataArray = @[@[]];
    [self.collectionView reloadData];
    self.refreshNeeded = YES;
    
    // Force an update if we already have location data, else by setting
    // refreshNeeded to YES, downloadData will be called next time
    // location info is updated.
    if (self.deviceLocation) {
        [self locationManager:self.locationManager didUpdateLocations:@[self.deviceLocation]];
    }
}

-(UIScrollView *)refreshScrollView
{
    return self.collectionView;
}

-(NSString *)refreshPromptString
{
    return MWLocalizedString(@"nearby-pull-to-refresh-prompt", nil);
}

-(NSString *)refreshRunningString
{
    return MWLocalizedString(@"nearby-pull-to-refresh-is-refreshing", nil);
}

- (void)locationManager: (CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSString *errorMessage = MWLocalizedString(@"nearby-location-general-error", nil); //error.localizedDescription;

    switch (error.code) {
        case kCLErrorDenied:
            errorMessage = [NSString stringWithFormat:@"\n%@\n\n%@\n\n%@\n\n",
                            MWLocalizedString(@"nearby-location-updates-denied", nil),
                            MWLocalizedString(@"nearby-location-updates-enable", nil),
                            MWLocalizedString(@"nearby-location-updates-settings-menu", nil)];
            break;
        default:
            break;
    }
    
    [self showAlert:errorMessage type:ALERT_TYPE_TOP duration:-1];
}

- (void)fetchFinished: (id)sender
          fetchedData: (id)fetchedData
               status: (FetchFinalStatus)status
                error: (NSError *)error
{
    if ([sender isKindOfClass:[NearbyFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                
                //[self showAlert:MWLocalizedString(@"nearby-loaded", nil) type:ALERT_TYPE_TOP duration:-1];
                [self fadeAlert];
                
                self.nearbyDataArray = @[fetchedData];

                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"initialDistance"
                                                                               ascending: YES];
                NSArray *arraySortedByDistance = [self.nearbyDataArray[0] sortedArrayUsingDescriptors:@[sortDescriptor]];
                self.nearbyDataArray = @[arraySortedByDistance];
                
                [self.collectionView reloadData];
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                NSLog(@"nearby op error = %@", error);
                //[self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                break;
            case FETCH_FINAL_STATUS_FAILED:
                NSLog(@"nearby op error = %@", error);
                [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                break;
        }
    }else if ([sender isKindOfClass:[ThumbnailFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
        
                NSString *fileName = [[sender url] lastPathComponent];
                
                // See if cache file found, show it instead of downloading if found.
                NSString *cacheFilePath = [self.cachePath stringByAppendingPathComponent:fileName];
                
                // Save cache file.
                [fetchedData writeToFile:cacheFilePath atomically:YES];
                
                // Then see if cell for this image name is still onscreen and set its image if so.
                UIImage *image = [UIImage imageWithData:fetchedData];
                
                // Check if cell still onscreen! This is important!
                NSArray *visibleRowIndexPaths = [self.collectionView indexPathsForVisibleItems];
                for (NSIndexPath *thisIndexPath in visibleRowIndexPaths.copy) {
                    NSDictionary *rowData = [self getRowDataForIndexPath:thisIndexPath];
                    NSString *url = rowData[@"thumbnail"][@"source"];
                    if ([url.lastPathComponent isEqualToString:fileName]) {
                        NearbyResultCollectionCell *cell = (NearbyResultCollectionCell *)[self.collectionView cellForItemAtIndexPath:thisIndexPath];
                        [cell.thumbView setImage:image isPlaceHolder:NO];
                        [cell setNeedsDisplay];
                        break;
                    }
                }
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                
                break;
            case FETCH_FINAL_STATUS_FAILED:
                
                break;
        }
    }
}

-(void)downloadData
{
    [self showAlert:MWLocalizedString(@"nearby-loading", nil) type:ALERT_TYPE_TOP duration:-1];

    [[QueuesSingleton sharedInstance].nearbyFetchManager.operationQueue cancelAllOperations];

    (void)[[NearbyFetcher alloc] initAndFetchNearbyForLatitude: self.deviceLocation.coordinate.latitude
                                                     longitude: self.deviceLocation.coordinate.longitude
                                                   withManager: [QueuesSingleton sharedInstance].nearbyFetchManager
                                            thenNotifyDelegate: self];
}

- (void)locationManager: (CLLocationManager *)manager
	 didUpdateLocations: (NSArray *)locations
{
    if (locations.count == 0) return;
    
    self.deviceLocation = locations[0];
  
    if (self.refreshNeeded) {
        [self downloadData];
        self.refreshNeeded = NO;
    }else{
        [self updateDistancesAndAnglesOfOnscreenCells];
    }
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self drawOnscreenCells];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)locationManager: (CLLocationManager *)manager
       didUpdateHeading: (CLHeading *)newHeading
{
    self.deviceHeading = newHeading;

    [self updateDistancesAndAnglesOfOnscreenCells];
}

-(void)drawOnscreenCells
{
    [self.collectionView.visibleCells makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}

-(void)updateDistancesAndAnglesOfOnscreenCells
{
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems.copy){
        NearbyResultCollectionCell *cell = (NearbyResultCollectionCell *)[self.collectionView cellForItemAtIndexPath:indexPath];

        [self updateDistancesAndAnglesOfCell:cell atIndexPath:indexPath];
    }
}

-(CLLocationCoordinate2D)getCoordinateFromNSValue:(NSValue *)value
{
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(0, 0);
    if(value)[value getValue:&coord];
    return coord;
}

-(CLLocationDistance)getDistanceToCoordinate:(CLLocationCoordinate2D)coord
{
    CLLocation *articleLocation =
        [[CLLocation alloc] initWithLatitude: coord.latitude
                                   longitude: coord.longitude];
    
    return [self.deviceLocation distanceFromLocation:articleLocation];
}

-(double)getAngleToCoordinate:(CLLocationCoordinate2D)coord
{
    return [self getAngleFromLocation: self.deviceLocation.coordinate
                           toLocation: coord
                     adjustForHeading: self.deviceHeading.trueHeading
                 adjustForOrientation: self.interfaceOrientation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.locationManager.delegate = self;

    self.locationManager.headingFilter = 1.5;
    self.locationManager.distanceFilter = 1.0;

    ((UIScrollView *)self.collectionView).decelerationRate = UIScrollViewDecelerationRateFast;

    [self.locationManager startUpdatingLocation];
    if (self.headingAvailable) {
        [self.locationManager startUpdatingHeading];
    }
    
    UICollectionViewFlowLayout *layout =
        (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    CGFloat topAndBottomMargin = 19.0f * MENUS_SCALE_MULTIPLIER;
    layout.sectionInset = UIEdgeInsetsMake(topAndBottomMargin, 0, topAndBottomMargin, 0);
    
    [self.collectionView registerNib:[UINib nibWithNibName:TABLE_CELL_ID bundle:nil] forCellWithReuseIdentifier:TABLE_CELL_ID];

    // Single off-screen cell for determining dynamic cell height.
    self.offScreenSizingCell =
        [[[NSBundle mainBundle] loadNibNamed:@"NearbyResultCollectionCell" owner:self options:nil] lastObject];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray *sectionArray = self.nearbyDataArray[section];
    return sectionArray.count;
}

-(void)updateDistancesAndAnglesOfCell:(NearbyResultCollectionCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.headingAvailable = self.headingAvailable;

    NSDictionary *rowData = [self getRowDataForIndexPath:indexPath];

    NSValue *coordVal = rowData[@"coordinate"];
    CLLocationCoordinate2D coord = [self getCoordinateFromNSValue:coordVal];
    
    CLLocationDistance distance = [self getDistanceToCoordinate:coord];
    cell.distance = @(distance);
    
    double angle = [self getAngleToCoordinate:coord];
    cell.angle = angle;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = TABLE_CELL_ID;
    NearbyResultCollectionCell *cell = (NearbyResultCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];

    if (!cell.longPressRecognizer) {
        cell.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHappened:)];
        [cell addGestureRecognizer:cell.longPressRecognizer];
    }
    
    [self updateViewsInCell:cell forIndexPath:indexPath];

    NSDictionary *rowData = [self getRowDataForIndexPath:indexPath];
    NSString *url = rowData[@"thumbnail"][@"source"];

    // Set thumbnail placeholder
    [cell.thumbView setImage:self.placeholderImage isPlaceHolder:YES];
    //[cell.thumbView setImage:nil isPlaceHolder:YES];
    if (!url || (url.length == 0)){
        // Don't bother downloading if no thumbURL
        return cell;
    }

    __block NSString *fileName = [url lastPathComponent];

    // See if cache file found, show it instead of downloading if found.
    NSString *cacheFilePath = [self.cachePath stringByAppendingPathComponent:fileName];
    BOOL isDirectory = NO;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath isDirectory:&isDirectory];
    if (fileExists) {
        [cell.thumbView setImage:[UIImage imageWithData:[NSData dataWithContentsOfFile:cacheFilePath]] isPlaceHolder:NO];
    }else{
        // No thumb found so fetch it.
        (void)[[ThumbnailFetcher alloc] initAndFetchThumbnailFromURL: url
                                                         withManager: [QueuesSingleton sharedInstance].nearbyFetchManager
                                                  thenNotifyDelegate: self];
    }
    
    return cell;
}

-(NSDictionary *)getRowDataForIndexPath:(NSIndexPath *)indexPath
{
    return self.nearbyDataArray[indexPath.section][indexPath.row];
}

-(void)updateViewsInCell:(NearbyResultCollectionCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *rowData = [self getRowDataForIndexPath:indexPath];
    
    [cell setTitle:rowData[@"title"] description:rowData[@"description"]];
    
    [self updateDistancesAndAnglesOfCell:cell atIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Update the sizing cell with any data which could change the cell height.
    [self updateViewsInCell:self.offScreenSizingCell forIndexPath:indexPath];

    CGFloat width = collectionView.bounds.size.width;

    // Determine height for the current configuration of the sizing cell.
    CGFloat height = [self.offScreenSizingCell heightForSizingCellOfWidth:width];
    return CGSizeMake(width, height);
}

-(void)longPressHappened:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        CGPoint p = [gestureRecognizer locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
        if (indexPath){
            self.longPressIndexPath = indexPath;

            self.actionSheet = [[UIActionSheet alloc] initWithTitle: nil
                                                           delegate: self
                                                  cancelButtonTitle: MWLocalizedString(@"nearby-cancel", nil)
                                             destructiveButtonTitle: nil
                                                  otherButtonTitles: MWLocalizedString(@"nearby-open-in-maps", nil), nil];
            [self.actionSheet showInView:self.view];
        }
    }
}

-(void)openInMaps:(CLLocationCoordinate2D)location withTitle:(NSString *)title
{
    // NSString *params = [NSString stringWithFormat:@"%f,%f", location.latitude, location.longitude];
    // params = [params urlEncodedUTF8String];
    // title = [title urlEncodedUTF8String];
    // NSString *url = [NSString stringWithFormat:@"http://maps.apple.com/?sll=%@&q=%@", params, title];
    // NSLog(@"url = %@", url);
    // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];

    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate: location
                                                   addressDictionary: nil];
    MKMapItem *item = [[MKMapItem alloc] initWithPlacemark:placemark];
    [item setName:title];
    [item openInMapsWithLaunchOptions:nil];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) return;
    
    NSDictionary *rowData = [self getRowDataForIndexPath:self.longPressIndexPath];

    NSValue *coordVal = rowData[@"coordinate"];
    CLLocationCoordinate2D coord = [self getCoordinateFromNSValue:coordVal];
    
    NSString *title = rowData[@"title"];

    [self openInMaps:CLLocationCoordinate2DMake(coord.latitude, coord.longitude) withTitle:title];
}

-(double)headingBetweenLocation: (CLLocationCoordinate2D)loc1
                    andLocation: (CLLocationCoordinate2D)loc2
{
    // From: http://www.movable-type.co.uk/scripts/latlong.html
	double dy = loc2.longitude - loc1.longitude;
	double y = sin(dy) * cos(loc2.latitude);
	double x = cos(loc1.latitude) * sin(loc2.latitude) - sin(loc1.latitude) * cos(loc2.latitude) * cos(dy);
	return atan2(y, x);
}

-(double)getAngleFromLocation: (CLLocationCoordinate2D)fromLocation
                   toLocation: (CLLocationCoordinate2D)toLocation
             adjustForHeading: (CLLocationDirection)deviceHeading
         adjustForOrientation: (UIInterfaceOrientation)interfaceOrientation
{
    // Get angle between device and article coordinates.
    double angleRadians = [self headingBetweenLocation:fromLocation andLocation:toLocation];

    // Adjust for device rotation (deviceHeading is in degrees).
    double angleDegrees = RADIANS_TO_DEGREES(angleRadians);
    angleDegrees -= deviceHeading;

    if (angleDegrees > 360.0) {
        angleDegrees -= 360.0;
    }else if (angleDegrees < 0.0){
        angleDegrees += 360.0;
    }

    // Adjust for interface orientation.
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            angleDegrees += 90.0;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angleDegrees -= 90.0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            angleDegrees += 180.0;
            break;
        default: //UIInterfaceOrientationPortrait
            break;
    }

    //NSLog(@"angle = %f", angleDegrees);

    return DEGREES_TO_RADIANS(angleDegrees);
}

@end
