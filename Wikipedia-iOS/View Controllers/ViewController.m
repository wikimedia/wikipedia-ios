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
#import "SearchResultCell.h"

#pragma mark Defines

#define SEARCH_THUMBNAIL_WIDTH 110
#define SEARCH_RESULT_HEIGHT 64
#define SEARCH_MAX_RESULTS @"25"

@interface ViewController (){

}

@property (strong, atomic) NSMutableArray *searchResultsOrdered;

@end

#pragma mark Internal variables

@implementation ViewController {
    CommunicationBridge *bridge_;
    NSOperationQueue *articleRetrievalQ_;
    NSOperationQueue *searchQ_;
    NSOperationQueue *thumbnailQ_;
    UILabel *debugLabel_;
    NSString *currentSearchString_;
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

    currentSearchString_ = @"";
    self.searchDisplayController.searchBar.placeholder = @"Search Wikipedia";
    self.searchDisplayController.searchResultsDataSource = (id)self;
    self.searchResultsOrdered = [[NSMutableArray alloc] init];
    
    articleRetrievalQ_ = [[NSOperationQueue alloc] init];
    searchQ_ = [[NSOperationQueue alloc] init];
    thumbnailQ_ = [[NSOperationQueue alloc] init];
    
    bridge_ = [[CommunicationBridge alloc] initWithWebView:self.webView];
    [bridge_ addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
        //NSLog(@"QQQ HEY DOMLoaded!");
    }];

    __weak ViewController *weakSelf = self;
    [bridge_ addListener:@"linkClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSString *href = payload[@"href"];
        if ([href hasPrefix:@"/wiki/"]) {
            NSString *title = [href substringWithRange:NSMakeRange(6, href.length - 6)];
            [weakSelf navigateToPage:title];
        }else if ([href hasPrefix:@"//"]) {
            href = [@"http:" stringByAppendingString:href];
            
NSString *msg = [NSString stringWithFormat:@"To do: add code for navigating to external link: %@", href];
[weakSelf.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"alert('%@')", msg]];

        }
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
        debugLabel_.text = [NSString stringWithFormat:@"QUEUE OP COUNTS: Search %lu, Thumb %lu, Article %lu", (unsigned long)searchQ_.operationCount, (unsigned long)thumbnailQ_.operationCount, (unsigned long)articleRetrievalQ_.operationCount];
    });
}

#pragma mark Search results table methods (requests actual thumb image data)

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{

    currentSearchString_ = searchString;

    // The documentation for ^this^ method recommends initiating async search here, then reloading the search results table
    // once results are obtained.
    [self searchForTerm:searchString];

    return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResultsOrdered.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SEARCH_RESULT_HEIGHT;
    
    /*
    NSString *height = self.searchResultsOrdered[indexPath.row][@"thumbnail"][@"height"];
    float h = (height) ? [height floatValue]: SEARCH_THUMBNAIL_WIDTH;
    //if (h < SEARCH_THUMBNAIL_WIDTH) h = SEARCH_THUMBNAIL_WIDTH;
    return h;
    */
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchResultCell *cell = (SearchResultCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchResultCell"];

    NSString *title = self.searchResultsOrdered[indexPath.row][@"title"];

    cell.textLabel.attributedText = [self getAttributedTitle:title];
    
    NSString *thumbURL = self.searchResultsOrdered[indexPath.row][@"thumbnail"][@"source"];

    // Set thumbnail placeholder
    cell.imageView.image = [UIImage imageNamed:@"logo-search-placeholder.png"];
    cell.useField = NO;
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
            cell.imageView.image = image;
            cell.useField = YES;
        });
    };
    [thumbnailQ_ addOperation:thumbnailOp];

    //[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (self.searchResultsOrdered.count == 0) return;
    
    NSString *thumbURL = self.searchResultsOrdered[indexPath.row][@"thumbnail"][@"source"];
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
    NSString *title = self.searchResultsOrdered[indexPath.row][@"title"];
    [self navigateToPage:title];
    [self.searchDisplayController setActive:NO animated:YES];
}

- (void)searchDisplayController:(UISearchDisplayController *)searchDisplayController didLoadSearchResultsTableView:(UITableView *)searchResultsTableView
{
    [searchResultsTableView registerNib:[UINib nibWithNibName:@"SearchResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"SearchResultCell"];

    // Turn off the separator since one gets added in SearchResultCell.m
    searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark Search term highlighter

-(NSAttributedString *)getAttributedTitle:(NSString *)title
{
    // Returns attributed string of title with the current search term highlighted.
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:title];

    // Non-search term
    [str addAttribute:NSFontAttributeName
                value:[UIFont fontWithName:@"HelveticaNeue" size:15.0]
                range:NSMakeRange(0, title.length)];

    [str addAttribute:NSForegroundColorAttributeName
                value:[UIColor colorWithWhite:0.0 alpha:0.85]
                range:NSMakeRange(0, title.length)];

    // Search term
    [str addAttribute:NSFontAttributeName
                value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0]
                range:NSMakeRange(0, currentSearchString_.length)];

    [str addAttribute:NSForegroundColorAttributeName
                value:[UIColor blackColor] //colorWithRed:0.00 green:0.48 blue:1.00 alpha:1.0]
                range:NSMakeRange(0, currentSearchString_.length)];
    
    return str;
}

#pragma mark Search term methods (requests titles matching search term and associated thumbnail urls)

- (void)searchForTerm:(NSString *)searchTerm
{
    [self.searchResultsOrdered removeAllObjects];
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

        if(weakSearchOp.error){
            //NSLog(@"search op completionBlock bailed on error %@", weakSearchOp.error);
            return;
        }
        
        NSArray *searchResults = (NSArray *)weakSearchOp.jsonRetrieved;
        //NSLog(@"searchResults = %@", searchResults);
        
        NSMutableArray *a = @[].mutableCopy;
        for (NSString *title in searchResults[1]) {
            [a addObject:@{@"title": title, @"thumbnail": @{}}.mutableCopy];
        }
        self.searchResultsOrdered = a;
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            // We have search titles! Show them right away!
            // NSLog(@"FIRE ONE! Show search result titles.");
            [self.searchDisplayController.searchResultsTableView reloadData];
        });

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

        if (results.count > 0) {
            NSDictionary *pages = results[@"query"][@"pages"];
            for (NSDictionary *page in pages) {
                NSString *titleFromThumbOpResults = pages[page][@"title"];
                for (NSMutableDictionary *searchOpResult in self.searchResultsOrdered) {
                    if ([searchOpResult[@"title"] isEqualToString:titleFromThumbOpResults]) {
                        searchOpResult[@"thumbnail"] = (pages[page][@"thumbnail"]) ? pages[page][@"thumbnail"] : [@{} mutableCopy];
                        break;
                    }
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^(){
            // Now we also have search thumbnail url data in searchResultsOrdered! Reload so thumb downloads
            // for on-screen cells can happen!
            // NSLog(@"FIRE TWO! Reload table data so it will download thumbnail images for on-screen search results.");
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
        //NSLog(@"aboutToStart for %@", pageTitle);
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
    return;
    if (op.dataRetrieved.length) {
        NSLog(@"Receive progress: %lu of %lu", (unsigned long)op.dataRetrieved.length, (unsigned long)op.dataRetrievedExpectedLength);
    }else{
        NSLog(@"Send progress: %@ of %@", op.bytesWritten, op.bytesExpectedToWrite);
    }
}

@end
