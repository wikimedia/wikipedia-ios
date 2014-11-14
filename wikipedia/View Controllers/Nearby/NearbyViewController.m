//  Created by Monte Hurd on 8/8/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NearbyViewController.h"
#import "NearbyResultCell.h"
#import "NearbyFetcher.h"
#import "ThumbnailFetcher.h"
#import "QueuesSingleton.h"
#import "PaddedLabel.h"
#import "WikipediaAppUtils.h"
#import "UIViewController+ModalPop.h"
#import "SessionSingleton.h"
#import "MWPageTitle.h"
#import "RootViewController.h"
#import "CenterNavController.h"
#import "UIViewController+Alert.h"
#import "NSString+Extras.h"
#import <MapKit/MapKit.h>
#import "Defines.h"
#import "WikiDataShortDescriptionFetcher.h"
#import "NSString+Extras.h"

@interface NearbyViewController ()

@property (strong, nonatomic) NSArray *nearbyDataArray;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
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

@end

/*
    // NearbyFetcher returns data formatted as follows:

	self.nearbyDataArray = (
        (
                {
            coordinates =             {
                globe = earth;
                lat = "51.5202";
                lon = "-0.095";
                primary = "";
            };
            distance = "207.4141690965082";
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
            coordinates =             {
                globe = earth;
                lat = "51.5191";
                lon = "-0.096946";
                primary = "";
            };
            distance = "324.2053114467474";
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *rowData = self.nearbyDataArray[indexPath.section][indexPath.row];
    NSString *title = rowData[@"title"];
    [NAV loadArticleWithTitle: [MWPageTitle titleWithString:title]
                       domain: [SessionSingleton sharedInstance].domain
                     animated: YES
              discoveryMethod: DISCOVERY_METHOD_SEARCH
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
    [self.tableView reloadData];
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
    return self.tableView;
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
             userData: (id)userData
               status: (FetchFinalStatus)status
                error: (NSError *)error
{
    if ([sender isKindOfClass:[NearbyFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                
                //[self showAlert:MWLocalizedString(@"nearby-loaded", nil) type:ALERT_TYPE_TOP duration:-1];
                [self fadeAlert];
                
                self.nearbyDataArray = @[userData];
                [self calculateDistances];
                
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"distance.doubleValue"
                                                                               ascending: YES];
                NSArray *arraySortedByDistance = [self.nearbyDataArray[0] sortedArrayUsingDescriptors:@[sortDescriptor]];
                self.nearbyDataArray = @[arraySortedByDistance];
                
                [self.tableView reloadData];

                // Get WikiData Id's to pass to WikiDataShortDescriptionFetcher.
                NSMutableArray *wikiDataIds = @[].mutableCopy;
                NSMutableDictionary *rowsData = (NSMutableDictionary *)self.nearbyDataArray[0];
                for (NSDictionary *page in rowsData) {
                    id wikiDataId = page[@"wikibase_item"];
                    if(wikiDataId && [wikiDataId isKindOfClass:[NSString class]]){
                        [wikiDataIds addObject:wikiDataId];
                    }
                }

                // Fetch WikiData short descriptions.
                if (wikiDataIds.count > 0){
                    (void)[[WikiDataShortDescriptionFetcher alloc] initAndFetchDescriptionsForIds: wikiDataIds
                                                                                      withManager: [QueuesSingleton sharedInstance].nearbyFetchManager
                                                                               thenNotifyDelegate: self];
                }
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
                [userData writeToFile:cacheFilePath atomically:YES];
                
                // Then see if cell for this image name is still onscreen and set its image if so.
                UIImage *image = [UIImage imageWithData:userData];
                
                // Check if cell still onscreen! This is important!
                NSArray *visibleRowIndexPaths = [self.tableView indexPathsForVisibleRows];
                for (NSIndexPath *thisIndexPath in visibleRowIndexPaths.copy) {
                    NSArray *sectionData = self.nearbyDataArray[thisIndexPath.section];
                    NSDictionary *rowData = sectionData[thisIndexPath.row];
                    NSString *url = rowData[@"thumbnail"][@"source"];
                    if ([url.lastPathComponent isEqualToString:fileName]) {
                        NearbyResultCell *cell = (NearbyResultCell *)[self.tableView cellForRowAtIndexPath:thisIndexPath];
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
    }else if ([sender isKindOfClass:[WikiDataShortDescriptionFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                NSDictionary *wikiDataShortDescriptions = (NSDictionary *)userData;

                // Add wikidata descriptions to respective search results.
                NSMutableDictionary *rowsData = (NSMutableDictionary *)self.nearbyDataArray[0];
                for (NSMutableDictionary *d in rowsData) {
                    NSString *wikiDataId = d[@"wikibase_item"];
                    if(wikiDataId){
                        if ([wikiDataShortDescriptions objectForKey:wikiDataId]) {
                            NSString *shortDesc = wikiDataShortDescriptions[wikiDataId];
                            if (shortDesc) {
                                d[@"wikidata_description"] = [shortDesc capitalizeFirstLetter];
                            }
                        }
                    }
                }
                
                [self.tableView reloadData];
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
        [self calculateDistances];
        
        [self updateDistancesForOnscreenCells];
    }
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Don't wait for heading or location update - on rotate update arrows right away.
    [self updateHeadingForOnscreenCells];
    [self updateDistancesForOnscreenCells];
}

- (void)locationManager: (CLLocationManager *)manager
       didUpdateHeading: (CLHeading *)newHeading
{
    self.deviceHeading = newHeading;

    [self updateHeadingForOnscreenCells];
}

-(void)updateHeadingForOnscreenCells
{
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows.copy){
        NearbyResultCell *cell = (NearbyResultCell *)[self.tableView cellForRowAtIndexPath:indexPath];

        cell.deviceHeading = self.deviceHeading;

        [cell setNeedsDisplay];
    }
}

-(void)updateDistancesForOnscreenCells
{
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows.copy){
        NearbyResultCell *cell = (NearbyResultCell *)[self.tableView cellForRowAtIndexPath:indexPath];

        [self updateLocationDataOfCell:cell atIndexPath:indexPath];

        [cell setNeedsDisplay];
    }
}

-(void)calculateDistances
{
    NSMutableDictionary *rowsData = (NSMutableDictionary *)self.nearbyDataArray[0];
    if (!rowsData || (rowsData.count == 0)) return;
    for (NSMutableDictionary *rowData in rowsData.copy){
        NSDictionary *coords = rowData[@"coordinates"];
        NSNumber *latitude = coords[@"lat"];
        NSNumber *longitude = coords[@"lon"];
        CLLocationDegrees lat1 = latitude.floatValue;
        CLLocationDegrees long1 = longitude.floatValue;
        
        CLLocation *locA =
        [[CLLocation alloc] initWithLatitude: self.deviceLocation.coordinate.latitude
                                   longitude: self.deviceLocation.coordinate.longitude];
        
        CLLocation *locB = [[CLLocation alloc] initWithLatitude:lat1 longitude:long1];
        
        CLLocationDistance distance = [locA distanceFromLocation:locB];
        
        rowData[@"distance"] = @(distance);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    if (self.headingAvailable) {
        [self.locationManager startUpdatingHeading];
    }
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 19)];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"NearbyResultCell" bundle:nil] forCellReuseIdentifier:@"NearbyResultCell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionArray = self.nearbyDataArray[section];
    return [sectionArray count];
}

-(void)updateLocationDataOfCell:(NearbyResultCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.headingAvailable = self.headingAvailable;

    cell.deviceLocation = self.deviceLocation;

    cell.interfaceOrientation = self.interfaceOrientation;

    NSArray *array = self.nearbyDataArray[indexPath.section];
    NSDictionary *rowData = array[indexPath.row];

    NSNumber *distance = rowData[@"distance"];
    cell.distance = distance;

    NSDictionary *coords = rowData[@"coordinates"];
    NSNumber *latitude = coords[@"lat"];
    NSNumber *longitude = coords[@"lon"];
    cell.location = [[CLLocation alloc] initWithLatitude: latitude.doubleValue
                                               longitude: longitude.doubleValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"NearbyResultCell";
    NearbyResultCell *cell = (NearbyResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];

    if (!cell.longPressRecognizer) {
        cell.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHappened:)];
        [cell addGestureRecognizer:cell.longPressRecognizer];
    }
    
    NSArray *sectionData = self.nearbyDataArray[indexPath.section];
    NSDictionary *rowData = sectionData[indexPath.row];
    
    [cell setTitle:rowData[@"title"] description:rowData[@"wikidata_description"]];
    
    [self updateLocationDataOfCell:cell atIndexPath:indexPath];

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

-(void)longPressHappened:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
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
    
    NSArray *sectionData = self.nearbyDataArray[self.longPressIndexPath.section];
    NSDictionary *rowData = sectionData[self.longPressIndexPath.row];

    NSNumber *lat = rowData[@"coordinates"][@"lat"];
    NSNumber *lon = rowData[@"coordinates"][@"lon"];
    NSString *title = rowData[@"title"];

    [self openInMaps:CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue) withTitle:title];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Getting dynamic cell height which respects auto layout constraints is tricky.

    // First get the cell configured exactly as it is for display.
    NearbyResultCell *cell =
        (NearbyResultCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];

    // Then coax the cell into taking on the size that would satisfy its layout constraints (and
    // return that size's height).
    // From: http://stackoverflow.com/a/18746930/135557
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    cell.bounds = CGRectMake(0.0f, 0.0f, tableView.bounds.size.width, cell.bounds.size.height * 10);
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    return height + 1.0f;

    // Note: for this to work the any UILabels used in the cell should use a class which updates the
    // label's preferredMaxLayoutWidth. PaddedLabel does this. Otherwise some words may get cut off when
    // lines wrap.
    // For more info: http://stackoverflow.com/a/17493152/135557
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
