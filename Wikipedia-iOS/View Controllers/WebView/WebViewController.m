//
//  ViewController.m
//  Wikipedia-iOS
//
//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import "WebViewController.h"

#import "CommunicationBridge.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "NSString+Extras.h"
#import "SearchResultCell.h"
#import "SearchBarLogoView.h"
#import "SearchBarTextField.h"

#import <CoreData/CoreData.h>
#import "Article.h"
#import "DiscoveryContext.h"
#import "DataContextSingleton.h"
#import "Section.h"
#import "History.h"
#import "Saved.h"
#import "DiscoveryMethod.h"
#import "Image.h"
#import "HistoryViewController.h"
#import "NSDate-Utilities.h"

#pragma mark Defines

#define SEARCH_THUMBNAIL_WIDTH 110
#define SEARCH_RESULT_HEIGHT 60
#define SEARCH_MAX_RESULTS @"25"

#define SEARCH_FONT [UIFont fontWithName:@"HelveticaNeue" size:16.0]
#define SEARCH_FONT_COLOR [UIColor colorWithWhite:0.0 alpha:0.85]

#define SEARCH_FONT_HIGHLIGHTED [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0]
#define SEARCH_FONT_HIGHLIGHTED_COLOR [UIColor blackColor]

#define SEARCH_FIELD_PLACEHOLDER_TEXT @"Search Wikipedia"
#define SEARCH_FIELD_PLACEHOLDER_TEXT_COLOR [UIColor colorWithRed:0.57 green:0.58 blue:0.59 alpha:1.0]

#define SEARCH_API_URL @"https://en.m.wikipedia.org/w/api.php"

#define SEARCH_LOADING_MSG_SECTION_ZERO @"Loading..."
#define SEARCH_LOADING_MSG_SECTION_REMAINING @"Loading the rest of the article..."

@interface WebViewController (){

}

@property (strong, nonatomic) SearchBarTextField *searchField;
@property (strong, atomic) NSMutableArray *searchResultsOrdered;
@property (strong, nonatomic) NSString *apiURL;
@property (strong, nonatomic) NSString *loadingSectionZeroMessage;
@property (strong, nonatomic) NSString *loadingSectionsRemainingMessage;
@property (strong, nonatomic) NSString *searchFieldPlaceholderText;

@property (strong, nonatomic) Site *currentSite;
@property (strong, nonatomic) Domain *currentDomain;

@property (strong, nonatomic) DiscoveryMethod *searchDiscoveryMethod;
@property (strong, nonatomic) DiscoveryMethod *linkDiscoveryMethod;
@property (strong, nonatomic) DiscoveryMethod *randomDiscoveryMethod;

@property (strong, nonatomic) NSString *currentSearchString;
@property (strong, nonatomic) NSArray *currentSearchStringWordsToHighlight;

@end

#pragma mark Internal variables

@implementation WebViewController {
    CommunicationBridge *bridge_;
    NSOperationQueue *articleRetrievalQ_;
    NSOperationQueue *searchQ_;
    NSOperationQueue *thumbnailQ_;
    UIView *navBarSubview_;
    CGFloat scrollViewDragBeganVerticalOffset_;
    DataContextSingleton *dataContext_;
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

    dataContext_ = [DataContextSingleton sharedInstance];

// TODO: update these associations based on Brion's comments.   -   -   -   -   -   -   -   -   -

    // Add site for article
    self.currentSite = (Site *)[self getEntityForName: @"Site" withPredicate:[NSPredicate predicateWithFormat:@"name == %@", @"wikipedia.org"]];
    
    // Add domain for article
    self.currentDomain = (Domain *)[self getEntityForName: @"Domain" withPredicate:[NSPredicate predicateWithFormat:@"name == %@", @"en"]];
    
    self.searchDiscoveryMethod = (DiscoveryMethod *)[self getEntityForName: @"DiscoveryMethod" withPredicate:[NSPredicate predicateWithFormat:@"name == %@", @"search"]];
    
    self.linkDiscoveryMethod = (DiscoveryMethod *)[self getEntityForName: @"DiscoveryMethod" withPredicate:[NSPredicate predicateWithFormat:@"name == %@", @"link"]];
    
    self.randomDiscoveryMethod = (DiscoveryMethod *)[self getEntityForName: @"DiscoveryMethod" withPredicate:[NSPredicate predicateWithFormat:@"name == %@", @"random"]];

//  -   -   -   -   -   -   -   -   -

    [self setupNavbarSubview];

    // Need to switch to localized strings...
    NSString *loadingMsgDiv = @"<div style='text-align:center;font-weight:bold'>";
    self.loadingSectionZeroMessage = [NSString stringWithFormat:@"%@%@</div>", loadingMsgDiv, SEARCH_LOADING_MSG_SECTION_ZERO];
    self.loadingSectionsRemainingMessage = [NSString stringWithFormat:@"%@%@</div>", loadingMsgDiv, SEARCH_LOADING_MSG_SECTION_REMAINING];
    self.searchFieldPlaceholderText = SEARCH_FIELD_PLACEHOLDER_TEXT;
    
    self.apiURL = SEARCH_API_URL;

    self.currentSearchString = @"";
    self.currentSearchStringWordsToHighlight = @[];
    self.searchField.attributedPlaceholder = [self getAttributedPlaceholderString];
    self.searchResultsOrdered = [[NSMutableArray alloc] init];
    
    scrollViewDragBeganVerticalOffset_ = 0.0f;
    
    articleRetrievalQ_ = [[NSOperationQueue alloc] init];
    searchQ_ = [[NSOperationQueue alloc] init];
    thumbnailQ_ = [[NSOperationQueue alloc] init];
    
    bridge_ = [[CommunicationBridge alloc] initWithWebView:self.webView];
    [bridge_ addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
        //NSLog(@"QQQ HEY DOMLoaded!");
    }];

    __weak WebViewController *weakSelf = self;
    [bridge_ addListener:@"linkClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSString *href = payload[@"href"];
        if ([href hasPrefix:@"/wiki/"]) {
            NSString *title = [href substringWithRange:NSMakeRange(6, href.length - 6)];
            [weakSelf navigateToPage:title discoveryMethod:weakSelf.linkDiscoveryMethod];
        }else if ([href hasPrefix:@"//"]) {
            href = [@"http:" stringByAppendingString:href];
            
NSString *msg = [NSString stringWithFormat:@"To do: add code for navigating to external link: %@", href];
[weakSelf.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"alert('%@')", msg]];

        }
    }];
    
    [self setupQMonitorDebuggingLabel];
    
    // Perform search when text entered into searchField
    [self.searchField addTarget:self action:@selector(reloadSearchResultsTableForSearchString) forControlEvents:UIControlEventEditingChanged];

    // Register the search results cell for reuse
    [self.searchResultsTable registerNib:[UINib nibWithNibName:@"SearchResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"SearchResultCell"];

    // Turn off the separator since one gets added in SearchResultCell.m
    self.searchResultsTable.separatorStyle = UITableViewCellSeparatorStyleNone;

    // Ensure web view can appear beneath translucent nav bar when scrolled up
    for (UIView *subview in self.webView.subviews) {
        subview.clipsToBounds = NO;
    }

    // Ensure the keyboard hides if the web view is scrolled
    self.webView.scrollView.delegate = self;

    // Prime the web view's content div. Without something in the div, the first
    // time an article loads, its "Loading..." message doesn't display in time
    // for some reason.
    [bridge_ sendMessage:@"append" withPayload:@{@"html": @"&nbsp;"}];

    // Observe changes to nav bar's bounds so the nav bar's subview's frame can be
    // kept in sync so it always overlays it perfectly, even as rotation animation
    // tweens the nav bar frame.
    [self.navigationController.navigationBar addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:nil];
    
    // Observe the visibility of the search results table so the web view can be made
    // to show when the results table is not, and vice-versa.
    [self.searchResultsTable addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
    
    // Force the nav bar's subview to update for initial display - needed for iOS 6.
    [self updateNavBarSubviewFrame];
}

#pragma mark Debugging

-(void)setupQMonitorDebuggingLabel
{
    // Listen in on the Q's op counts
    [articleRetrievalQ_ addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    [searchQ_ addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    [thumbnailQ_ addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    
    // Add a label so we can keep an eye on Q op counts to ensure they go away properly.
    self.debugLabel.text = @"All Queues Empty";
}

#pragma mark Nav bar subview

-(void)updateNavBarSubviewFrame
{
    // To get the search box floating over a translucent view it was placed as a subview of
    // the nav bar, but the nav bar doesn't do autolayout on it's subviews, so the subview
    // is resized manually here.
    navBarSubview_.frame = self.navigationController.navigationBar.bounds;
    //self.searchField.frame = navBarSubview_.bounds;
    CGFloat rightPadding = (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) ? 0.0f : 6.0f;
    
    self.searchField.frame = CGRectMake(
                                        navBarSubview_.bounds.origin.x,
                                        navBarSubview_.bounds.origin.y,
                                        navBarSubview_.bounds.size.width - rightPadding,
                                        navBarSubview_.bounds.size.height
                                        );

    // Make the search field's leftView (a UIImageView) be as tall as the search field
    // so its image can resize accordingly
    self.searchField.leftView.frame = CGRectMake(self.searchField.leftView.frame.origin.x, self.searchField.leftView.frame.origin.y, self.searchField.leftView.frame.size.width, self.searchField.frame.size.height);
}

-(void)setupNavbarSubview
{
    navBarSubview_ = [[UIView alloc] init];
    navBarSubview_.backgroundColor = [UIColor clearColor];
    navBarSubview_.translatesAutoresizingMaskIntoConstraints = NO;

    [self.navigationController.navigationBar addSubview:navBarSubview_];
    
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.navigationController.navigationBar.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:0.97];
    }

    self.searchField = [[SearchBarTextField alloc] init];
    self.searchField.delegate = self;
    self.searchField.returnKeyType = UIReturnKeyGo;
    self.searchField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchField.font = SEARCH_FONT;
    self.searchField.textColor = SEARCH_FONT_HIGHLIGHTED_COLOR;
    //self.searchField.frame = CGRectInset(navBarSubview_.frame, 3, 3);

    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    self.searchField.leftView = [[SearchBarLogoView alloc] initWithFrame:CGRectMake(0, 0, 65, 50)];

    self.searchField.leftView.backgroundColor = [UIColor clearColor];
    self.searchField.clearButtonMode = UITextFieldViewModeAlways;
    self.searchField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    [navBarSubview_ addSubview:self.searchField];

    //navBarSubview_.layer.borderWidth = 0.5f;
    //self.searchField.layer.borderWidth = 0.5f;
    //navBarSubview_.layer.borderColor = [UIColor greenColor].CGColor;
    //self.searchField.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
    //self.navigationController.navigationBar.backgroundColor = [UIColor greenColor];
    //self.navigationController.navigationBar.layer.borderWidth = 0.5;
    //self.navigationController.navigationBar.layer.borderColor = [UIColor purpleColor].CGColor;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(historyToggle)];
    [self.searchField.leftView addGestureRecognizer:tap];
}

-(NSAttributedString *)getAttributedPlaceholderString
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:self.searchFieldPlaceholderText];

    [str addAttribute:NSFontAttributeName
                value:SEARCH_FONT_HIGHLIGHTED
                range:NSMakeRange(0, str.length)];

    [str addAttribute:NSForegroundColorAttributeName
                value:SEARCH_FIELD_PLACEHOLDER_TEXT_COLOR
                range:NSMakeRange(0, str.length)];

    return str;
}

#pragma mark History

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Ensure the web VC is the top VC.
    [self.navigationController popToViewController:self animated:YES];
}

-(void)historyToggle
{
    if(self.navigationController.topViewController != self){
        // Hide if it's already showing.
        [self.navigationController popToViewController:self animated:YES];
        return;
    }
    self.searchField.text = @"";
    [self.searchField resignFirstResponder];
    [self performSegueWithIdentifier:@"ShowHistorySegue" sender:self];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"operationCount"]) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            self.debugLabel.text = [NSString stringWithFormat:@"QUEUE OP COUNTS: Search %lu, Thumb %lu, Article %lu", (unsigned long)searchQ_.operationCount, (unsigned long)thumbnailQ_.operationCount, (unsigned long)articleRetrievalQ_.operationCount];
        });
    }else if(object == self.navigationController.navigationBar){
        [self updateNavBarSubviewFrame];
    }else if(object == self.searchResultsTable){
        self.webView.hidden = !self.searchResultsTable.hidden;
    }
}

#pragma mark Scroll

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    /*
    // Hides nav bar when a scroll threshold is exceeded. Probably only want to do this
    // when the webView's scrollView scrolls. Probably also want to set the status bar to
    // be not transparent when the nav bar is hidden - if not possible could position a
    // view just behind it, but above the webView.
    if (scrollView == self.webView.scrollView) {
        CGFloat f = scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y;
        if (f < -55 && !self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }else if (f > 55 && self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            //[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        }
    }
    */

    // Hide the keyboard if it was visible when the results are scrolled, but only if
    // the results have been scrolled in excess of some small distance threshold first.
    // This prevents tiny scroll adjustments, which seem to occur occasionally for some
    // reason, from causing the keyboard to hide when the user is typing on it!
    CGFloat distanceScrolled = fabs(scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y);
    if (self.searchField.isFirstResponder && distanceScrolled > 55) {
        [self.searchField resignFirstResponder];
        //NSLog(@"Keyboard Hidden!");
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    scrollViewDragBeganVerticalOffset_ = scrollView.contentOffset.y;
}

#pragma mark Search results table methods (requests actual thumb image data)

- (void)reloadSearchResultsTableForSearchString
{
    NSString *searchString = self.searchField.text;

    self.currentSearchString = searchString;
    [self updateWordsToHighlight];

    NSString *trimmedSearchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (trimmedSearchString.length == 0){
        self.searchResultsTable.hidden = YES;
        self.searchField.clearButtonMode = UITextFieldViewModeNever;
        return;
    }
    
    self.searchField.clearButtonMode = UITextFieldViewModeAlways;
    [self searchForTerm:searchString];
    self.searchResultsTable.hidden = NO;
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
    NSNumber *thumbWidth = self.searchResultsOrdered[indexPath.row][@"thumbnail"][@"width"];
    NSNumber *thumbHeight = self.searchResultsOrdered[indexPath.row][@"thumbnail"][@"height"];

    // Check for db record for thumb. If found use it rather than downloading it again!
    Image *thumbnailFromDB = (Image *)[self getEntityForName: @"Image" withPredicate:[NSPredicate predicateWithFormat:@"sourceUrl == %@", thumbURL]];

    if(thumbnailFromDB){
        // Yay! Cached thumbnail found! Use it!
        // Needs to be synchronous!
        UIImage *image = [UIImage imageWithData:thumbnailFromDB.data];
        cell.imageView.image = image;
        cell.useField = YES;
        return cell;
    }

    // If execution reaches this point a cached core data thumb was not found.

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

        // Save thumbnail to core data article.image record for later use. This can be async.
        NSMutableData *thumbData = weakThumbnailOp.dataRetrieved;
        dispatch_async(dispatch_get_main_queue(), ^(){
            Article *article = (Article *)[self getEntityForName: @"Article" withPredicate:[NSPredicate predicateWithFormat:@"title == %@", title]];
            if (!article) {
                article = [NSEntityDescription insertNewObjectForEntityForName:@"Article" inManagedObjectContext:dataContext_];
                article.title = title;
                article.dateCreated = [NSDate date];
            }
            
            Image *thumb = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:dataContext_];
            thumb.data = thumbData;
            thumb.fileName = [thumbURL lastPathComponent];
            thumb.extension = [thumbURL pathExtension];
            thumb.imageDescription = nil;
            thumb.sourceUrl = thumbURL;
            thumb.dateRetrieved = [NSDate date];
            thumb.width = thumbWidth;
            thumb.height = thumbHeight;
            
            article.thumbnailImage = thumb;

            article.site = self.currentSite;
            article.domain = self.currentDomain;

            NSError *error = nil;
            [dataContext_ save:&error];
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

    [self navigateToPage:title discoveryMethod:self.searchDiscoveryMethod];

    self.searchField.text = @"";
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

    for (NSString *word in self.currentSearchStringWordsToHighlight) {
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

-(void)updateWordsToHighlight
{
    // Call this only when currentSearchString_ is updated. Keeps the list of words to highlight up to date.
    // Get the words by splitting currentSearchString_ on a combination of whitespace and punctuation
    // character sets so search term words get highlighted even if the puncuation in the result is slightly
    // different from the punctuation in the retrieved search result title.
    NSMutableCharacterSet *charSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [charSet formUnionWithCharacterSet:[NSMutableCharacterSet punctuationCharacterSet]];
    self.currentSearchStringWordsToHighlight = [self.currentSearchString componentsSeparatedByCharactersInSet:charSet];
}

#pragma mark Search term methods (requests titles matching search term and associated thumbnail urls)

- (void)searchForTerm:(NSString *)searchTerm
{
    [self.searchResultsOrdered removeAllObjects];
    [self.searchResultsTable reloadData];
    
    [articleRetrievalQ_ cancelAllOperations];
    [thumbnailQ_ cancelAllOperations];
    
    // Search for titles op

    // Cancel any in-progress article retrieval operations
    [searchQ_ cancelAllOperations];
    
    MWNetworkOp *searchOp = [[MWNetworkOp alloc] init];
    searchOp.delegate = self;
    searchOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:self.apiURL]
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
        weakSearchThumbURLsOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:self.apiURL]
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
    
    [searchQ_ addOperation:searchThumbURLsOp];
    [searchQ_ addOperation:searchOp];
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self navigateToPage:textField.text discoveryMethod:self.searchDiscoveryMethod];

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

#pragma mark Article loading ops

- (void)navigateToPage:(NSString *)pageTitle discoveryMethod:(DiscoveryMethod *)discoveryMethod
{
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {

        self.searchResultsTable.hidden = YES;
        [self.searchField resignFirstResponder];
        
        // Clear out previous page's html
        [bridge_ sendMessage:@"clear" withPayload:@{}];

        // Add a "Loading..." message as first element of cleared page
        [bridge_ sendMessage:@"append" withPayload:@{@"html": self.loadingSectionZeroMessage}];

        [self retrieveArticleForPageTitle:pageTitle discoveryMethod:discoveryMethod];
    }];
}

- (void)retrieveArticleForPageTitle:(NSString *)pageTitle discoveryMethod:(DiscoveryMethod *)discoveryMethod
{
    Article *article = (Article *)[self getEntityForName: @"Article" withPredicate:[NSPredicate predicateWithFormat:@"title == %@", pageTitle]];
    
    // If core data article with sections already exists just show it
    if (article) {
        if (article.section.count > 0) {
            [self displayArticle:article];
            return;
        }
        // If no sections in the existing article don't return. Allows sections to be retrieved if core data
        // article was created when thumbnails were retrieved (before any sections are fetched).
    }else{
        // Else create core data article and then proceed to retrieve its data
        article = [NSEntityDescription insertNewObjectForEntityForName:@"Article" inManagedObjectContext:dataContext_];
        article.title = pageTitle;
        article.dateCreated = [NSDate date];
    }

    // Cancel any in-progress article retrieval operations
    [articleRetrievalQ_ cancelAllOperations];
    
    [searchQ_ cancelAllOperations];
    [thumbnailQ_ cancelAllOperations];

    // Retrieve first section op
    
    MWNetworkOp *firstSectionOp = [[MWNetworkOp alloc] init];
    firstSectionOp.delegate = self;
    firstSectionOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:self.apiURL]
                                       parameters: @{
                                                     @"action": @"mobileview",
                                                     @"prop": @"sections|text",
                                                     @"sections": @"0",
                                                     @"page": pageTitle,
                                                     @"format": @"json"
                                                     }
                  ];
    __weak MWNetworkOp *weakOp = firstSectionOp;
    firstSectionOp.aboutToStart = ^{
        //NSLog(@"aboutToStart for %@", pageTitle);
        [self networkActivityIndicatorPush];
    };
    firstSectionOp.completionBlock = ^(){
        [self networkActivityIndicatorPop];
        if(weakOp.isCancelled){
            //NSLog(@"completionBlock bailed (because op was cancelled) for %@", pageTitle);
            return;
        }
        //NSLog(@"completionBlock for %@", pageTitle);
        // Ensure web view is scrolled to top of new article
        [self.webView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        
        article.lastScrollLocation = @0.0f;

        // Get article sections text (faster joining array elements than appending a string)
        NSDictionary *sections = weakOp.jsonRetrieved[@"mobileview"][@"sections"];
        NSMutableArray *sectionText = [@[] mutableCopy];
        for (NSDictionary *section in sections) {
            if ([section valueForKey:@"text"]){
                [sectionText addObject:section[@"text"]];
            }
        }
        
        // Join article sections text
        NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
        NSString *htmlStr = [sectionText componentsJoinedByString:joint];

        // Add sections for article
        Section *section0 = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:dataContext_];
        section0.index = @0;
        section0.title = @"";
        section0.dateRetrieved = [NSDate date];
        section0.html = htmlStr;
        article.section = [NSSet setWithObjects:section0, nil];
        
        // Add history for article
        History *history0 = [NSEntityDescription insertNewObjectForEntityForName:@"History" inManagedObjectContext:dataContext_];
        history0.dateVisited = [NSDate date];
        //history0.dateVisited = [NSDate dateWithDaysBeforeNow:1];
        history0.discoveryMethod = discoveryMethod;
        [article addHistoryObject:history0];

        article.site = self.currentSite;
        article.domain = self.currentDomain;

        // Add saved for article
        //Saved *saved0 = [NSEntityDescription insertNewObjectForEntityForName:@"Saved" inManagedObjectContext:dataContext_];
        //saved0.dateSaved = [NSDate date];
        //[article addSavedObject:saved0];
        
        // Save the article!
        NSError *error = nil;
        [dataContext_ save:&error];

        NSLog(@"error = %@", error);
        NSLog(@"error = %@", error.localizedDescription);

        // Send html across bridge to web view
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
            // Clear out the loading message at the top of page
            [bridge_ sendMessage:@"clear" withPayload:@{}];
            // Add the first section html
            [bridge_ sendMessage:@"append" withPayload:@{@"html": htmlStr}];
            // Add a loading message beneath the first section so user can see more is on the way
            [bridge_ sendMessage: @"append"
                     withPayload: @{@"html": [NSString stringWithFormat:@"<div id='loadingMessage'>%@</div>", self.loadingSectionsRemainingMessage]}];
        }];
    };
    
    // Retrieve remaining sections op (dependent on first section op)
    
    MWNetworkOp *remainingSectionsOp = [[MWNetworkOp alloc] init];
    remainingSectionsOp.delegate = self;
    
    // Retrieval of remaining sections depends on retrieving first section
    [remainingSectionsOp addDependency:firstSectionOp];

    remainingSectionsOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:self.apiURL]
                                       parameters: @{
                                                     @"action": @"mobileview",
                                                     @"prop": @"sections|text",
                                                     @"sections": @"1-",
                                                     @"page": pageTitle,
                                                     @"format": @"json"
                                                     }
                  ];
    __weak MWNetworkOp *weakRemainingSectionsOp = remainingSectionsOp;
    remainingSectionsOp.aboutToStart = ^{
        //NSLog(@"aboutToStart for %@", pageTitle);
        [self networkActivityIndicatorPush];
    };
    remainingSectionsOp.completionBlock = ^(){
        [self networkActivityIndicatorPop];
        if(weakRemainingSectionsOp.isCancelled){
            //NSLog(@"completionBlock bailed (because op was cancelled) for %@", pageTitle);
            return;
        }
        
        // Get article sections text (faster joining array elements than appending a string)
        NSDictionary *sections = weakRemainingSectionsOp.jsonRetrieved[@"mobileview"][@"sections"];
        NSMutableArray *sectionText = [@[] mutableCopy];
        for (NSDictionary *section in sections) {
            if ([section valueForKey:@"text"]){
                [sectionText addObject:section[@"text"]];

                // Add sections for article
                Section *thisSection = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:dataContext_];
                thisSection.index = section[@"id"];
                thisSection.title = section[@"line"];
                thisSection.html = section[@"text"];
                thisSection.dateRetrieved = [NSDate date];
                [article addSectionObject:thisSection];
            }
        }

        NSError *error = nil;
        [dataContext_ save:&error];

        // Join article sections text
        NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
        NSString *htmlStr = [sectionText componentsJoinedByString:joint];
        
        // Send html across bridge to web view
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
            // Clear out the loading message beneath the first section
            [bridge_ sendMessage:@"remove" withPayload:@{@"element": @"loadingMessage"}];
            // Add the remaining sections beneath the first section
            [bridge_ sendMessage:@"append" withPayload:@{@"html": htmlStr}];
        }];
    };
    
    [articleRetrievalQ_ addOperation:remainingSectionsOp];
    [articleRetrievalQ_ addOperation:firstSectionOp];
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

#pragma mark Display article from core data

- (void)displayArticle:(Article *)article
{
    // Get sorted sections for this article (sorts the article.section NSSet into sortedSections)
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
    NSArray *sortedSections = [article.section sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSMutableArray *sectionText = [@[] mutableCopy];
    
    for (Section *section in sortedSections) {
        if (section.html){
            [sectionText addObject:section.html];
        }
    }

    // Join article sections text
    NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
    NSString *htmlStr = [sectionText componentsJoinedByString:joint];

    // Send html across bridge to web view
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        // Clear out the loading message at the top of page
        [bridge_ sendMessage:@"clear" withPayload:@{}];
        // Display all sections
        [bridge_ sendMessage:@"append" withPayload:@{@"html": htmlStr}];
    }];
}

#pragma mark Get core data entity

-(NSManagedObject *)getEntityForName:(NSString *)entityName withPredicate:(NSPredicate *)predicate
{
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName
                                              inManagedObjectContext: dataContext_];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];

    error = nil;
    NSArray *methods = [dataContext_ executeFetchRequest:fetchRequest error:&error];
    //XCTAssert(error == nil, @"Could not fetch article.");

    if (methods.count == 1) {
        NSManagedObject *method = (NSManagedObject *)methods[0];
        return method;
    }else{
        return nil;
    }
}

@end
