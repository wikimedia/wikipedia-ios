//  Created by Monte Hurd on 12/16/13.

#import "SearchResultsController.h"
#import "Defines.h"
#import "QueuesSingleton.h"
#import "WebViewController.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SearchNavController.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "SearchResultCell.h"
#import "SearchBarTextField.h"
#import "AlertLabel.h"

@interface SearchResultsController (){
    CGFloat scrollViewDragBeganVerticalOffset_;
}

@end

@implementation SearchResultsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    scrollViewDragBeganVerticalOffset_ = 0.0f;

    self.searchResultsOrdered = [[NSMutableArray alloc] init];
    self.navigationItem.hidesBackButton = YES;

    // Register the search results cell for reuse
    [self.searchResultsTable registerNib:[UINib nibWithNibName:@"SearchResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"SearchResultCell"];

    // Turn off the separator since one gets added in SearchResultCell.m
    self.searchResultsTable.separatorStyle = UITableViewCellSeparatorStyleNone;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchStringChanged) name:@"SearchStringChanged" object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self searchStringChanged];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Hide the keyboard if it was visible when the results are scrolled, but only if
    // the results have been scrolled in excess of some small distance threshold first.
    // This prevents tiny scroll adjustments, which seem to occur occasionally for some
    // reason, from causing the keyboard to hide when the user is typing on it!
    CGFloat distanceScrolled = fabs(scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y);

    if (distanceScrolled > HIDE_KEYBOARD_ON_SCROLL_THRESHOLD) {
        [self.searchNavController resignSearchFieldFirstResponder];
        //NSLog(@"Keyboard Hidden!");
    }
}

-(void)searchStringChanged
{
    NSString *trimmedSearchString = [self.searchNavController.currentSearchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (trimmedSearchString.length == 0) {
        [self popToWebViewController];
        return;
    }
    
    [self searchForTerm:trimmedSearchString];
}

#pragma mark Search term methods (requests titles matching search term and associated thumbnail urls)

- (void)searchForTerm:(NSString *)searchTerm
{
    [self.searchResultsOrdered removeAllObjects];
    [self.searchResultsTable reloadData];
    
    [[QueuesSingleton sharedInstance].articleRetrievalQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].thumbnailQ cancelAllOperations];
    
    // Search for titles op

    // Cancel any in-progress article retrieval operations
    [[QueuesSingleton sharedInstance].searchQ cancelAllOperations];

    // Show "Searching..." message.
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        self.webViewController.alertLabel.text = SEARCH_LOADING_MSG_SEARCHING;
    }];

    MWNetworkOp *searchOp = [[MWNetworkOp alloc] init];
    searchOp.delegate = self;
    searchOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:SEARCH_API_URL]
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
            
            // Show error message.
            // (need to extract msg from error *before* main q block - the error is dealloc'ed by
            // the time the block is dequeued)
            NSString *errorMsg = weakSearchOp.error.localizedDescription;
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                self.webViewController.alertLabel.text = errorMsg;
            }];
            return;
        }else{
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                self.webViewController.alertLabel.text = @"";
            }];
        }
        
        NSArray *searchResults = (NSArray *)weakSearchOp.jsonRetrieved;
        //NSLog(@"searchResults = %@", searchResults);
        
        NSMutableArray *a = @[].mutableCopy;
        for (NSString *title in searchResults[1]) {

            NSString *cleanTitle = [self cleanTitle:title];

            [a addObject:@{@"title": cleanTitle, @"thumbnail": @{}}.mutableCopy];
        }
        self.searchResultsOrdered = a;
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            // We have search titles! Show them right away!
            // NSLog(@"FIRE ONE! Show search result titles.");
            [self.searchResultsTable reloadData];
        });

        //NSLog(@"search op completionBlock for %@", searchTerm);
        // Get article sections text (faster joining array elements than appending a string)
        //NSArray *searchResults = (NSArray *)weakSearchOp.jsonRetrieved;
        //NSLog(@"search results = %@", searchResults);
    };
    
    // Titles thumbnail urls retrieval op (dependent on search op)
    
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
        weakSearchThumbURLsOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:SEARCH_API_URL]
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
            [self.searchResultsTable reloadData];
        });
    };
    
    [[QueuesSingleton sharedInstance].searchQ addOperation:searchThumbURLsOp];
    [[QueuesSingleton sharedInstance].searchQ addOperation:searchOp];
}

#pragma mark Search term highlighting

-(NSAttributedString *)getAttributedTitle:(NSString *)title
{
    // Returns attributed string of title with the current search term highlighted.
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:title];

    // Set base color and font of the entire result title
    [str addAttribute:NSFontAttributeName
                value:SEARCH_FONT
                range:NSMakeRange(0, str.length)];

    [str addAttribute:NSForegroundColorAttributeName
                value:SEARCH_FONT_COLOR
                range:NSMakeRange(0, str.length)];

    for (NSString *word in self.searchNavController.currentSearchStringWordsToHighlight) {
        // Search term highlighting
        NSRange rangeOfThisWordInTitle = [title rangeOfString: word
                                                      options: NSCaseInsensitiveSearch |
                                                               NSDiacriticInsensitiveSearch |
                                                               NSWidthInsensitiveSearch
                                          ];

        [str addAttribute:NSFontAttributeName
                    value:SEARCH_FONT_HIGHLIGHTED
                    range:rangeOfThisWordInTitle];
        
        [str addAttribute:NSForegroundColorAttributeName
                    value:SEARCH_FONT_HIGHLIGHTED_COLOR
                    range:rangeOfThisWordInTitle];
    }
    return str;
}

#pragma mark Search results table methods (requests actual thumb image data)

-(NSString *)cleanTitle:(NSString *)title
{
    return [title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
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
    static NSString *cellID = @"SearchResultCell";
    SearchResultCell *cell = (SearchResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];

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
    [[QueuesSingleton sharedInstance].thumbnailQ addOperation:thumbnailOp];

    //[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (self.searchResultsOrdered.count == 0) return;
    
    NSString *thumbURL = self.searchResultsOrdered[indexPath.row][@"thumbnail"][@"source"];
    //NSLog(@"CANCEL THUMB RETRIEVAL OP HERE for thumb url %@", thumbURL);
    MWNetworkOp *opToCancel = nil;
    for (MWNetworkOp *op in [QueuesSingleton sharedInstance].thumbnailQ.operations) {
        //NSLog(@"in progress op request url = %@", op.request.URL);
        if([thumbURL isEqualToString:op.request.URL.description]){
            // Don't actually cancel the op while in the for loop - prevents mutating [QueuesSingleton sharedInstance].thumbnailQ.operations
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

    // Set CurrentArticleTitle so web view knows what to load.
    title = [self cleanTitle:title];
    
    [[NSUserDefaults standardUserDefaults] setObject:title forKey:@"CurrentArticleTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.searchResultsTable deselectRowAtIndexPath:indexPath animated:YES];

    [self popToWebViewController];
}

#pragma mark Show web view

-(void)popToWebViewController
{
    [self.navigationController popToViewController:self.webViewController animated:NO];
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

#pragma mark Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
