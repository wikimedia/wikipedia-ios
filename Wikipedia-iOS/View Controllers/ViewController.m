//
//  ViewController.m
//  Wikipedia-iOS
//
//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import "ViewController.h"

#import "CommunicationBridge.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "NSString+Extras.h"

#pragma mark Defines

#define SEARCH_THUMBNAIL_WIDTH 110
#define SEARCH_RESULT_HEIGHT 65
#define SEARCH_RESULT_THUMBNAIL_IMAGE_TAG 1001
#define SEARCH_RESULT_TITLE_LABEL_TAG 1002
#define SEARCH_MAX_RESULTS @"25"

@interface ViewController (){

}

@property (strong, atomic) NSMutableDictionary *searchResultsWithThumbURLs;

@end

#pragma mark Internal variables

@implementation ViewController {
    CommunicationBridge *bridge_;
    NSOperationQueue *articleRetrievalQ_;
    NSOperationQueue *searchQ_;
    NSOperationQueue *thumbnailQ_;
    UILabel *debugLabel_;
}

#pragma mark Network activity indicator methods

-(void)networkActivityIndicatorPush
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        // Show status bar spinner
        [[MWNetworkActivityIndicatorManager sharedManager] show];
    });
}

-(void)networkActivityIndicatorPop
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        // Hide status bar spinner
        [[MWNetworkActivityIndicatorManager sharedManager] hide];
    });
}

#pragma mark View lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.searchDisplayController.searchBar.placeholder = @"Search Wikipedia";
    self.searchDisplayController.searchResultsDataSource = (id)self;
    self.searchResultsWithThumbURLs = [[NSMutableDictionary alloc] init];
    
    articleRetrievalQ_ = [[NSOperationQueue alloc] init];
    searchQ_ = [[NSOperationQueue alloc] init];
    thumbnailQ_ = [[NSOperationQueue alloc] init];
    
    bridge_ = [[CommunicationBridge alloc] initWithWebView:self.webView];
    [bridge_ addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
        //NSLog(@"QQQ HEY DOMLoaded!");
    }];
    
    [self setupQMonitorDebuggingLabel];
    
    //self.searchDisplayController.searchBar.backgroundColor = [UIColor redColor];
}

#pragma mark Debugging

-(void)setupQMonitorDebuggingLabel
{
    // Listen in on the Q's op counts
    [articleRetrievalQ_ addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    [searchQ_ addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    [thumbnailQ_ addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    
    // Add a label so we can keep an eye on Q op counts to ensure they go away properly.
    debugLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(8, -1, 320, 50)];
    [self.view addSubview:debugLabel_];
    debugLabel_.backgroundColor = [UIColor clearColor];
    debugLabel_.textColor = [UIColor colorWithRed:0.00 green:0.48 blue:1.00 alpha:1.0];
    debugLabel_.font = [UIFont fontWithName:@"helvetica" size:8];
    debugLabel_.text = @"All Queues Empty";
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        debugLabel_.text = [NSString stringWithFormat:@"QUEUE OP COUNTS: Search %d, Thumb %d, Article %d", searchQ_.operationCount, thumbnailQ_.operationCount, articleRetrievalQ_.operationCount];
    });
}

#pragma mark Search results table methods (requests actual thumb image data)

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // The documentation for ^this^ method recommends initiating async search here, then reloading the search results table
    // once results are obtained.
    [self searchForTerm:searchString];

    return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResultsWithThumbURLs.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //http://stackoverflow.com/questions/18746929/using-auto-layout-in-uitableview-for-dynamic-cell-layouts-heights
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchResultCell"];
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];

    return SEARCH_RESULT_HEIGHT;
    
    /*
    NSString *height = self.searchResultsWithThumbURLs[self.searchResultsWithThumbURLs.allKeys[indexPath.row]][@"height"];
    float h = (height) ? [height floatValue]: SEARCH_THUMBNAIL_WIDTH;
    //if (h < SEARCH_THUMBNAIL_WIDTH) h = SEARCH_THUMBNAIL_WIDTH;
    return h;
    */
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchResultCell"];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:SEARCH_RESULT_THUMBNAIL_IMAGE_TAG];
    UILabel *label = (UILabel *)[cell viewWithTag:SEARCH_RESULT_TITLE_LABEL_TAG];
    
    NSString *title = self.searchResultsWithThumbURLs.allKeys[indexPath.row];
    label.text = title;
    
    NSString *thumbURL = self.searchResultsWithThumbURLs[self.searchResultsWithThumbURLs.allKeys[indexPath.row]][@"source"];

    // Set thumbnail placeholder
    imageView.image = [UIImage imageNamed:@"logo-search-placeholder.png"];
    if (!thumbURL){
        // Don't bother downloading if no thumbURL
        return cell;
    }

    MWNetworkOp *thumbnailOp = [[MWNetworkOp alloc] init];
    thumbnailOp.delegate = self;

    //NSLog(@"thumbURL  = %@", thumbURL);

    thumbnailOp.request = [NSURLRequest requestWithURL:[NSURL URLWithString:thumbURL]];
    
    __weak MWNetworkOp *weakThumbnailOp = thumbnailOp;
    thumbnailOp.aboutToStart = ^{
        //NSLog(@"thumbnail op aboutToStart with request %@", weakThumbnailOp.request);
        [self networkActivityIndicatorPush];
    };
    thumbnailOp.completionBlock = ^(){
        [self networkActivityIndicatorPop];
        if(weakThumbnailOp.isCancelled){
            //NSLog(@"thumbnail op completionBlock bailed (because op was cancelled) for %@", searchTerm);
            return;
        }
        //NSLog(@"thumbnail data retrieved length = %d", weakThumbnailOp.dataRetrieved.length);
        //NSLog(@"thumbnail data retrieved = %@", [NSString stringWithCString:[weakThumbnailOp.dataRetrieved bytes] encoding:NSUTF8StringEncoding]);

        // Needs to be *synchronous* and on main queue!
        dispatch_sync(dispatch_get_main_queue(), ^(){
            UIImage *image = [UIImage imageWithData:weakThumbnailOp.dataRetrieved];
            imageView.image = image;
        });
    };
    [thumbnailQ_ addOperation:thumbnailOp];

    //[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (self.searchResultsWithThumbURLs.count == 0) return;
    
    NSString *thumbURL = self.searchResultsWithThumbURLs[self.searchResultsWithThumbURLs.allKeys[indexPath.row]][@"source"];
    //NSLog(@"CANCEL THUMB RETRIEVAL OP HERE for thumb url %@", thumbURL);
    MWNetworkOp *opToCancel = nil;
    for (MWNetworkOp *op in thumbnailQ_.operations) {
        //NSLog(@"in progress op request url = %@", op.request.URL);
        if([thumbURL isEqualToString:op.request.URL.description]){
            // Don't actually cancel the op while in the for loop - prevents mutating thumbnailQ_.operations
            // while iterating it.
            opToCancel = op;
            break;
        }
    }
    [opToCancel cancel];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = self.searchResultsWithThumbURLs.allKeys[indexPath.row];
    [self navigateToPage:title];
    [self.searchDisplayController setActive:NO animated:YES];
}

- (void)searchDisplayController:(UISearchDisplayController *)searchDisplayController didLoadSearchResultsTableView:(UITableView *)searchResultsTableView
{
    [searchResultsTableView registerNib:[UINib nibWithNibName:@"SearchResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"SearchResultCell"];
}

#pragma mark Search term methods (requests titles matching search term and associated thumbnail urls)

- (void)searchForTerm:(NSString *)searchTerm
{
    [self.searchResultsWithThumbURLs removeAllObjects];
    [self.searchDisplayController.searchResultsTableView reloadData];
    
    [articleRetrievalQ_ cancelAllOperations];
    [thumbnailQ_ cancelAllOperations];
    
    NSString *trimmedSearchTerm = [searchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedSearchTerm.length == 0) return;
    
    #pragma mark Search for titles op

    // Cancel any in-progress article retrieval operations
    [searchQ_ cancelAllOperations];
    
    MWNetworkOp *searchOp = [[MWNetworkOp alloc] init];
    searchOp.delegate = self;
    searchOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:@"https://en.m.wikipedia.org/w/api.php"]
                                             parameters: @{
                                                           @"action": @"opensearch",
                                                           @"search": searchTerm,
                                                           @"limit": SEARCH_MAX_RESULTS,
                                                           @"format": @"json"
                                                           }
                        ];
    
    __weak MWNetworkOp *weakSearchOp = searchOp;
    searchOp.aboutToStart = ^{
        //NSLog(@"search op aboutToStart for %@", searchTerm);
        [self networkActivityIndicatorPush];
    };
    
    searchOp.completionBlock = ^(){
        [self networkActivityIndicatorPop];
        if(weakSearchOp.isCancelled){
            //NSLog(@"search op completionBlock bailed (because op was cancelled) for %@", searchTerm);
            return;
        }
        //NSLog(@"search op completionBlock for %@", searchTerm);
        // Get article sections text (faster joining array elements than appending a string)
        //NSArray *searchResults = (NSArray *)weakSearchOp.jsonRetrieved;
        //NSLog(@"search results = %@", searchResults);
    };
    
    #pragma mark Titles thumbnail urls retrieval op (dependent on search op)
    
    // Thumbnail urls retrieval
    MWNetworkOp *searchThumbURLsOp = [[MWNetworkOp alloc] init];
    __weak MWNetworkOp *weakSearchThumbURLsOp = searchThumbURLsOp;

    [searchThumbURLsOp addDependency:searchOp];
    searchThumbURLsOp.delegate = self;

    searchThumbURLsOp.aboutToStart = ^{
        [self networkActivityIndicatorPush];
        NSArray *searchResults = (NSArray *)weakSearchOp.jsonRetrieved;
        NSArray *titles = searchResults[1];
        NSString *barDelimitedTitles = [titles componentsJoinedByString:@"|"];
        weakSearchThumbURLsOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:@"https://en.m.wikipedia.org/w/api.php"]
                                                              parameters: @{
                                                                            @"action": @"query",
                                                                            @"prop": @"pageimages",
                                                                            @"action": @"query",
                                                                            @"piprop": @"thumbnail|name",
                                                                            @"pilimit": SEARCH_MAX_RESULTS,
                                                                            @"pithumbsize": [NSString stringWithFormat:@"%d", SEARCH_THUMBNAIL_WIDTH],
                                                                            @"titles": barDelimitedTitles,
                                                                            @"format": @"json"}];
        
    };
    
    searchThumbURLsOp.completionBlock = ^(){
        [self networkActivityIndicatorPop];
        if(weakSearchThumbURLsOp.isCancelled){
            //NSLog(@"search thumb urls op completionBlock bailed (because op was cancelled) for %@", searchTerm);
            return;
        }
        //NSLog(@"search op completionBlock for %@", searchTerm);
        //NSLog(@"search op error %@", weakSearchThumbURLsOp.error);

        // Get dictionary of search thumb urls mapped to their respective search terms
        NSDictionary *results = (NSDictionary *)weakSearchThumbURLsOp.jsonRetrieved;

        NSMutableDictionary *searchResultsWithThumbURLs = [@{} mutableCopy];
        if (results.count > 0) {
            NSDictionary *pages = results[@"query"][@"pages"];
            for (NSDictionary *page in pages) {
                searchResultsWithThumbURLs[pages[page][@"title"]] = (pages[page][@"thumbnail"]) ? pages[page][@"thumbnail"] : [@{} mutableCopy];
            }
        }
        //NSLog(@"searchResultsWithThumbURLs = %@", searchResultsWithThumbURLs);

        dispatch_async(dispatch_get_main_queue(), ^(){
            // Update self.searchResultsWithThumbURLs once, not repeatedly in loop. This is
            // because updating searchResultsWithThumbURLs causes the search results table
            // to be updated. Doing so repeatedly in the loop above can make the table view laying
            // out the search results crash complaining that searchResultsWithThumbURLs is being mutated
            // (which the for loop above was doing formerly) while the table view was iterating
            // searchResultsWithThumbURLs (which it does as it lays out the table cells)
            self.searchResultsWithThumbURLs = searchResultsWithThumbURLs;
            
            // We have search results! Show them!
            [self.searchDisplayController.searchResultsTableView reloadData];
        });
    };
    
    [searchQ_ addOperation:searchThumbURLsOp];
    [searchQ_ addOperation:searchOp];
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self navigateToPage:textField.text];
    [textField resignFirstResponder];
    return NO;
}

#pragma Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Action methods

- (IBAction)backButtonPushed:(id)sender {
    [self.webView goBack];
}

- (IBAction)forwardButtonPushed:(id)sender {
    [self.webView goForward];
}

- (IBAction)languageButtonPushed:(id)sender {
}

- (IBAction)actionButtonPushed:(id)sender {
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]
                                                        initWithActivityItems:@[self.webView.request.URL]
                                                        applicationActivities:@[]];
    
    [self presentViewController:activityViewController animated:YES completion:^{
        // Whee!
    }];
}

- (IBAction)bookmarkButtonPushed:(id)sender {
}

- (IBAction)menuButtonPushed:(id)sender {
}

#pragma mark Article loading op

- (void)navigateToPage:(NSString *)pageTitle
{
    // Cancel any in-progress article retrieval operations
    [articleRetrievalQ_ cancelAllOperations];
    
    [searchQ_ cancelAllOperations];
    [thumbnailQ_ cancelAllOperations];
    
    // Send html across bridge to web view
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        [bridge_ sendMessage:@"displayLeadSection" withPayload:@{@"leadSectionHTML": @""}];
        [bridge_ sendMessage:@"displayLeadSection" withPayload:@{@"leadSectionHTML": @"Loading..."}];
    }];
    
    MWNetworkOp *op = [[MWNetworkOp alloc] init];
    op.delegate = self;
    op.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:@"https://en.m.wikipedia.org/w/api.php"]
                                       parameters: @{
                                                     @"action": @"mobileview",
                                                     @"prop": @"sections|text",
                                                     @"sections": @"all",
                                                     @"page": pageTitle,
                                                     @"format": @"json"
                                                     }
                  ];
    __weak MWNetworkOp *weakOp = op;
    op.aboutToStart = ^{
        NSLog(@"aboutToStart for %@", pageTitle);
        [self networkActivityIndicatorPush];
    };
    op.completionBlock = ^(){
        [self networkActivityIndicatorPop];
        if(weakOp.isCancelled){
            //NSLog(@"completionBlock bailed (because op was cancelled) for %@", pageTitle);
            return;
        }
        //NSLog(@"completionBlock for %@", pageTitle);
        // Ensure web view is scrolled to top of new article
        [self.webView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        
        // Get article sections text (faster joining array elements than appending a string)
        NSDictionary *sections = weakOp.jsonRetrieved[@"mobileview"][@"sections"];
        NSMutableArray *sectionText = [@[] mutableCopy];
        for (NSDictionary *section in sections) {
            [sectionText addObject:section[@"text"]];
        }
        
        // Join article sections text
        NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
        NSString *htmlStr = [sectionText componentsJoinedByString:joint];
        
        // Send html across bridge to web view
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
            [bridge_ sendMessage:@"displayLeadSection" withPayload:@{@"leadSectionHTML": htmlStr}];
        }];
    };
    [articleRetrievalQ_ addOperation:op];
}

#pragma mark Progress report

-(void)opProgressed:(MWNetworkOp *)op;
{
    //NSLog(@"Article retrieval progress: %@ of %@", op.bytesWritten, op.bytesExpectedToWrite);
}

@end
