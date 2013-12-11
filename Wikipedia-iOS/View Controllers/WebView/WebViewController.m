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
#import "ArticleCoreDataObjects.h"
#import "ArticleDataContextSingleton.h"
#import "HistoryViewController.h"
#import "NSDate-Utilities.h"
#import "SessionSingleton.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "AlertLabel.h"
#import "UIWebView+Reveal.h"

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

#define SEARCH_LOADING_MSG_SECTION_ZERO @"Loading first section of the article..."
#define SEARCH_LOADING_MSG_SECTION_REMAINING @"Loading the rest of the article..."
#define SEARCH_LOADING_MSG_ARTICLE_LOADED @"Article loaded."
#define SEARCH_LOADING_MSG_SEARCHING @"Searching..."

@interface WebViewController (){

}

@property (strong, nonatomic) SearchBarTextField *searchField;
@property (strong, atomic) NSMutableArray *searchResultsOrdered;
@property (strong, nonatomic) NSString *apiURL;

@property (strong, nonatomic) NSString *searchDiscoveryMethod;
@property (strong, nonatomic) NSString *linkDiscoveryMethod;
@property (strong, nonatomic) NSString *randomDiscoveryMethod;

@property (strong, nonatomic) NSString *currentSearchString;
@property (strong, nonatomic) NSArray *currentSearchStringWordsToHighlight;

@property (strong, nonatomic) NSString *currentArticleTitle;

@property (strong, nonatomic) CommunicationBridge *bridge;

@property (nonatomic) CGPoint scrollOffset;
@property (nonatomic) BOOL unsafeToScroll;

@end

#pragma mark Internal variables

@implementation WebViewController {
    NSOperationQueue *articleRetrievalQ_;
    NSOperationQueue *searchQ_;
    NSOperationQueue *thumbnailQ_;
    UIView *navBarSubview_;
    CGFloat scrollViewDragBeganVerticalOffset_;
    ArticleDataContextSingleton *articleDataContext_;
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewFinishedLoading) name:@"WebViewFinishedLoading" object:nil];
    self.unsafeToScroll = NO;
    self.scrollOffset = CGPointZero;

    self.currentArticleTitle = @"";
    self.alertLabel.text = @"";

    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

// TODO: update these associations based on Brion's comments.   -   -   -   -   -   -   -   -   -

    self.searchDiscoveryMethod = @"search";
    
    self.linkDiscoveryMethod = @"link";
    
    self.randomDiscoveryMethod = @"random";

//  -   -   -   -   -   -   -   -   -

    [self setupNavbarSubview];
    
    self.apiURL = SEARCH_API_URL;

    self.currentSearchString = @"";
    self.currentSearchStringWordsToHighlight = @[];
    self.searchField.attributedPlaceholder = [self getAttributedPlaceholderString];
    self.searchResultsOrdered = [[NSMutableArray alloc] init];
    
    scrollViewDragBeganVerticalOffset_ = 0.0f;
    
    articleRetrievalQ_ = [[NSOperationQueue alloc] init];
    searchQ_ = [[NSOperationQueue alloc] init];
    thumbnailQ_ = [[NSOperationQueue alloc] init];
    
    [self setupQMonitorDebuggingLabel];

    // Comment out to show the q debugging label.
    self.debugLabel.alpha = 0.0f;
    
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

#pragma mark Webview obj-c to javascript bridge

-(void)resetBridge
{
    // This needs to be called before sending a new page of html to the embedded UIWebView.
    // The bridge is the web view's delegate, and one of the web view delegate methods which
    // the bridge implements is "webViewDidFinishLoad:". This method only gets called the first
    // time a page is displayed unless the bridge is reset before beginning to send a page of
    // html. "webViewDidFinishLoad:" seems the only *reliable* way of being notified when the
    // page dom has been loaded and the web view's view had taken on the size of the content
    // it is rendering. It is only then that we can scroll to a saved article's previous
    // scroll offsets.

    // Because the bridge is a property now, rather than a private var, ARC should take care of
    // cleanup when the bridge is reset.
//TODO: confirm this comment ^
    self.bridge = [[CommunicationBridge alloc] initWithWebView:self.webView];
    [self.bridge addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
        //NSLog(@"QQQ HEY DOMLoaded!");
    }];

    __weak WebViewController *weakSelf = self;
    [self.bridge addListener:@"linkClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
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

    self.unsafeToScroll = NO;
    self.scrollOffset = CGPointZero;
}

#pragma mark Loading last-viewed article on app start

-(void)setLastViewedArticleTitle:(NSString *)lastViewedArticleTitle
{
    [[NSUserDefaults standardUserDefaults] setObject:lastViewedArticleTitle forKey:@"LastViewedArticleTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)getLastViewedArticleTitle
{
    NSString *lastViewedArticleTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastViewedArticleTitle"];
    return lastViewedArticleTitle;
}

-(void)viewDidAppear:(BOOL)animated
{
    // Should be ok to call "navigateToPage:" on viewDidAppear because it contains logic preventing
    // reloads of pages already being displayed.
    [self navigateToPage:[self getLastViewedArticleTitle] discoveryMethod:nil];
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
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:SEARCH_FIELD_PLACEHOLDER_TEXT];

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

    self.alertLabel.hidden = YES;
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

#pragma mark Web view scroll offset recording

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(!decelerate) [self scrollViewScrollingEnded:scrollView];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self scrollViewScrollingEnded:scrollView];
}

-(void)scrollViewScrollingEnded:(UIScrollView *)scrollView
{
    if (scrollView == self.webView.scrollView) {
        // Once we've started scrolling around don't allow the webview delegate to scroll
        // to a saved position! Super annoying otherwise.
        self.unsafeToScroll = YES;

        // Save scroll location
        Article *article = [articleDataContext_ getArticleForTitle:self.currentArticleTitle];
        article.lastScrollX = @(scrollView.contentOffset.x);
        article.lastScrollY = @(scrollView.contentOffset.y);
        NSError *error = nil;
        [articleDataContext_ save:&error];
    }
}

#pragma mark Web view scroll offset - using it!

-(void)webViewFinishedLoading
{
    if(!self.unsafeToScroll){
        [self.webView.scrollView setContentOffset:self.scrollOffset animated:NO];
    }
    [self.webView reveal];
}

#pragma mark Scroll hiding keyboard threshold

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
    NSNumber *thumbWidth = self.searchResultsOrdered[indexPath.row][@"thumbnail"][@"width"];
    NSNumber *thumbHeight = self.searchResultsOrdered[indexPath.row][@"thumbnail"][@"height"];

    // Check for db record for thumb. If found use it rather than downloading it again!
    Image *thumbnailFromDB = (Image *)[articleDataContext_ getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", thumbURL];

    if(thumbnailFromDB){

//TODO: update thumbnailFromDB.dateLastAccessed here! Probably on background thread. Not sure best way to ensure just single object will be updated...

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

            Article *article = [articleDataContext_ getArticleForTitle:title];
            
            Image *thumb = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:articleDataContext_];
            thumb.data = thumbData;
            thumb.fileName = [thumbURL lastPathComponent];
            thumb.extension = [thumbURL pathExtension];
            thumb.imageDescription = nil;
            thumb.sourceUrl = thumbURL;
            thumb.dateRetrieved = [NSDate date];
            thumb.dateLastAccessed = [NSDate date];
            thumb.width = thumbWidth;
            thumb.height = thumbHeight;
            thumb.mimeType = @"image/jpeg";
            
            article.thumbnailImage = thumb;

            article.site = [SessionSingleton sharedInstance].site;     //self.currentSite;
            article.domain = [SessionSingleton sharedInstance].domain; //self.currentDomain;

            NSError *error = nil;
            [articleDataContext_ save:&error];
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

    // Show "Searching..." message.
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        self.alertLabel.text = SEARCH_LOADING_MSG_SEARCHING;
    }];

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
            
            // Show error message.
            // (need to extract msg from error *before* main q block - the error is dealloc'ed by
            // the time the block is dequeued)
            NSString *errorMsg = weakSearchOp.error.localizedDescription;
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                self.alertLabel.text = errorMsg;
            }];
            return;
        }else{
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                self.alertLabel.text = @"";
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

- (void)navigateToPage:(NSString *)title discoveryMethod:(NSString *)discoveryMethod
{
    static BOOL isFirstArticle = YES;

    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        NSString *cleanTitle = [self cleanTitle:title];

        // Hide the search results.
        self.searchResultsTable.hidden = YES;
        // Hide the keyboard.
        [self.searchField resignFirstResponder];

        // Don't try to load nothing. Core data takes exception with such nonsense.
        if (cleanTitle == nil) return;
        
        // Don't reload an article if it's already showing! The exception is if the article
        // being shown is the first article being shown. In that case, lastViewedArticleTitle
        // isn't currently onscreen so it doesn't matter (and won't flicker).
        if ([cleanTitle isEqualToString:[self getLastViewedArticleTitle]] && !isFirstArticle) return;

        // Fade the web view out so there's not a flickery transition between old and new html.
//TODO: Fix this. It causes fade out even when no connection, which blanks out current article.
        //[self.webView fade];

        self.currentArticleTitle = cleanTitle;
        isFirstArticle = NO;
        [self setLastViewedArticleTitle:cleanTitle];
        
        // Show loading message
        self.alertLabel.text = SEARCH_LOADING_MSG_SECTION_ZERO;
        
        [self retrieveArticleForPageTitle:cleanTitle discoveryMethod:discoveryMethod];
    }];
}

- (void)retrieveArticleForPageTitle:(NSString *)pageTitle discoveryMethod:(NSString *)discoveryMethod
{
    Article *article = [articleDataContext_ getArticleForTitle:pageTitle];

    // If article with sections just show them
    if (article.section.count > 0) {
        [self displayArticle:article];
        return;
    }

    // If no sections core data article may have been created when thumbnails were retrieved (before any sections are fetched)
    // or may not have had any sections last time we checked. So check now.

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
                                                     @"onlyrequestedsections": @"1",
                                                     @"sectionprop": @"toclevel|line|anchor",
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

        if (weakOp.error) {
            // Show error message.
            // (need to extract msg from error *before* main q block - the error is dealloc'ed by
            // the time the block is dequeued)
            NSString *errorMsg = weakOp.error.localizedDescription;
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                self.alertLabel.text = errorMsg;
            }];

            // Remove the article so it doesn't get saved.
            [articleDataContext_ deleteObject:article];
            
            return;
        }

        if(weakOp.isCancelled){
            //NSLog(@"completionBlock bailed (because op was cancelled) for %@", pageTitle);
            
            // Remove the article so it doesn't get saved.
            [articleDataContext_ deleteObject:article];

            return;
        }
        //NSLog(@"completionBlock for %@", pageTitle);

        // Check for error retrieving section zero data.
        if(weakOp.jsonRetrieved[@"error"]){
            NSDictionary *errorDict = weakOp.jsonRetrieved[@"error"];
            //NSLog(@"errorDict = %@", errorDict);
            
            // Set error condition so dependent remaining sections op doesn't even start.
            weakOp.error = [NSError errorWithDomain:@"Section Zero Op" code:001 userInfo:errorDict];
            
            // Remove the article so it doesn't get saved.
            [articleDataContext_ deleteObject:article];
            
            // Send html across bridge to web view
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                // Show the api's "Page not found" message as first element of cleared page.
                self.alertLabel.text = errorDict[@"info"];
            }];
            
            return;
        }

        article.lastScrollX = @0.0f;
        article.lastScrollY = @0.0f;

        // Get article section zero html
        NSArray *sections = weakOp.jsonRetrieved[@"mobileview"][@"sections"];
        NSDictionary *section0Dict = (sections.count == 1) ? sections[0] : nil;

        NSString *section0HTML = @"";
        if (section0Dict && [section0Dict[@"id"] isEqual: @0] && section0Dict[@"text"]) {
            section0HTML = section0Dict[@"text"];
        }

        // Add sections for article
        Section *section0 = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:articleDataContext_];
        section0.index = @0;
        section0.title = @"";
        section0.dateRetrieved = [NSDate date];
        section0.html = section0HTML;
        section0.anchor = @"";
        article.section = [NSSet setWithObjects:section0, nil];
        
        // Add history for article
        History *history0 = [NSEntityDescription insertNewObjectForEntityForName:@"History" inManagedObjectContext:articleDataContext_];
        history0.dateVisited = [NSDate date];
        //history0.dateVisited = [NSDate dateWithDaysBeforeNow:31];
        history0.discoveryMethod = discoveryMethod;
        [article addHistoryObject:history0];

        article.site = [[SessionSingleton sharedInstance] site];   //self.currentSite;
        article.domain = [[SessionSingleton sharedInstance] domain]; //self.currentDomain;

        // Add saved for article
        //Saved *saved0 = [NSEntityDescription insertNewObjectForEntityForName:@"Saved" inManagedObjectContext:dataContext_];
        //saved0.dateSaved = [NSDate date];
        //[article addSavedObject:saved0];
        
        // Save the article!
        NSError *error = nil;
        [articleDataContext_ save:&error];

        if (error) {
            NSLog(@"error = %@", error);
            NSLog(@"error = %@", error.localizedDescription);
        }

        // Send html across bridge to web view
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {

            // See comments inside resetBridge.
            [self resetBridge];

            // Add the first section html
            [self.bridge sendMessage:@"append" withPayload:@{@"html": section0HTML}];

            // Show the web view again. (Had faded it out to prevent flickery transition to new html.)
//TODO: Fix this. It causes fade out even when no connection, which blanks out current article.
//            [self.webView reveal];

            if(sections.count > 1){
                // Show loading more sections message so user can see more is on the way
                self.alertLabel.text = SEARCH_LOADING_MSG_SECTION_REMAINING;
            }else{
                // Show article loaded message
                self.alertLabel.text = SEARCH_LOADING_MSG_ARTICLE_LOADED;
                // Then hide the message (hidden has been overriden to fade out slowly)
                self.alertLabel.hidden = YES;
            }
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
                                                     @"onlyrequestedsections": @"1",
                                                     @"sectionprop": @"toclevel|line|anchor",
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
            if (![section[@"id"] isEqual: @0]) {
                [sectionText addObject:section[@"text"]];

                // Add sections for article
                Section *thisSection = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:articleDataContext_];
                thisSection.index = section[@"id"];
                thisSection.title = section[@"line"];
                thisSection.html = section[@"text"];
                thisSection.tocLevel = section[@"toclevel"];
                thisSection.dateRetrieved = [NSDate date];
                thisSection.anchor = (section[@"anchor"]) ? section[@"anchor"] : @"";
                [article addSectionObject:thisSection];
            }
        }

        NSError *error = nil;
        [articleDataContext_ save:&error];

        // Join article sections text
        NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
        NSString *htmlStr = [sectionText componentsJoinedByString:joint];
        
        // Send html across bridge to web view
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
            // Show article loaded message
            self.alertLabel.text = SEARCH_LOADING_MSG_ARTICLE_LOADED;
            // Then hide the message (hidden has been overriden to fade out slowly)
            self.alertLabel.hidden = YES;
            
            // Add the remaining sections beneath the first section
            [self.bridge sendMessage:@"append" withPayload:@{@"html": htmlStr}];
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

    // See comments inside resetBridge.
    [self resetBridge];

    self.scrollOffset = CGPointMake(article.lastScrollX.floatValue, article.lastScrollY.floatValue);

    // Join article sections text
    NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
    NSString *htmlStr = [sectionText componentsJoinedByString:joint];

    // Send html across bridge to web view
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        // Show article loaded message
        self.alertLabel.text = SEARCH_LOADING_MSG_ARTICLE_LOADED;
        // Then hide the message (hidden has been overriden to fade out slowly)
        self.alertLabel.hidden = YES;

        // Display all sections
        [self.bridge sendMessage:@"append" withPayload:@{@"html": htmlStr}];        
    }];
}

-(void)scrollWebViewToOffset:(NSString *)offset
{
    CGPoint p = CGPointFromString(offset);
    [self.webView.scrollView setContentOffset:p animated:NO];
}

@end
