//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchResultsController.h"
#import "WikipediaAppUtils.h"
#import "Defines.h"
#import "QueuesSingleton.h"
#import "SearchResultCell.h"
#import "SessionSingleton.h"
#import "UIViewController+Alert.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "NSString+Extras.h"
#import "UIViewController+HideKeyboard.h"
#import "CenterNavController.h"
#import "SearchResultFetcher.h"
#import "ThumbnailFetcher.h"
#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "SearchTypeMenu.h"
#import "TopMenuTextFieldContainer.h"
#import "TopMenuTextField.h"
#import "SearchDidYouMeanButton.h"
#import "WikiDataShortDescriptionFetcher.h"
#import "SearchMessageLabel.h"

@interface SearchResultsController (){
    CGFloat scrollViewDragBeganVerticalOffset_;
    ArticleDataContextSingleton *articleDataContext_;
}

@property (nonatomic, strong) NSString *searchSuggestion;
@property (nonatomic, weak) IBOutlet UITableView *searchResultsTable;
@property (nonatomic, strong) NSArray *searchStringWordsToHighlight;

@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) NSString *cachePath;

@property (nonatomic, weak) IBOutlet SearchTypeMenu *searchTypeMenu;
@property (nonatomic, weak) IBOutlet SearchDidYouMeanButton *didYouMeanButton;
@property (nonatomic, weak) IBOutlet SearchMessageLabel *searchMessageLabel;

@property (nonatomic, strong) NSTimer *delayedSearchTimer;

@end

@implementation SearchResultsController

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.searchString = @"";
    
    self.placeholderImage = [UIImage imageNamed:@"logo-placeholder-search.png"];
    
    // NSCachesDirectory can be used as temp storage. iOS will clear this directory if it needs to so
    // don't store anything critical there. Works well here for quick access to thumbs as user scrolls
    // table view.
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.cachePath = [cachePaths objectAtIndex:0];

    self.searchStringWordsToHighlight = @[];
    
    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    scrollViewDragBeganVerticalOffset_ = 0.0f;

    self.searchResults = @[];
    self.searchSuggestion = nil;
    self.navigationItem.hidesBackButton = YES;

    // Register the search results cell for reuse
    [self.searchResultsTable registerNib:[UINib nibWithNibName:@"SearchResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"SearchResultCell"];

    // Turn off the separator since one gets added in SearchResultCell.m
    self.searchResultsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Observe searchTypeMenu's searchType, refresh results if it changes - ie user tapped "Titles" or "Within articles".
    [self.searchTypeMenu addObserver: self
                          forKeyPath: @"searchType"
                             options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                             context: nil];

    self.didYouMeanButton.userInteractionEnabled = YES;
    [self.didYouMeanButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didYouMeanButtonPushed)]];
}

-(void)dealloc
{
    [self.searchTypeMenu removeObserver:self forKeyPath:@"searchType"];
}

-(void)didYouMeanButtonPushed
{
    [self.didYouMeanButton hide];
    TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
    textFieldContainer.textField.text = self.searchSuggestion;
    self.searchString = self.searchSuggestion;
    [self searchAfterDelay:@0.0f];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if ((object == self.searchTypeMenu) && [keyPath isEqualToString:@"searchType"]) {
        [self searchAfterDelay:@0.0f];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self cancelDelayedSearch];
    
    [[QueuesSingleton sharedInstance].searchResultsFetchManager.operationQueue cancelAllOperations];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Important to only auto-search when the view appears if-and-only-if it isn't already showing results!
    if ((self.searchString.length > 0) && (self.searchResults.count == 0)) {
        [self searchAfterDelay:@0.0f];
    }
}

-(void)cancelDelayedSearch
{
    if (self.delayedSearchTimer) {
        [self.delayedSearchTimer invalidate];
        self.delayedSearchTimer = nil;
    }
}

-(void)search
{
    if (self.searchString.length == 0) {
        [self clearSearchResults];
    }else{
        CGFloat delay = (self.searchTypeMenu.searchType == SEARCH_TYPE_TITLES) ? SEARCH_DELAY_PREFIX : SEARCH_DELAY_FULL_TEXT;
        
        [self searchAfterDelay:@(delay)];
    }
}

-(void)searchAfterDelay:(NSNumber *)delay
{
    [self cancelDelayedSearch];

    self.delayedSearchTimer = [NSTimer scheduledTimerWithTimeInterval: delay.floatValue
                                                  target: self
                                                selector: @selector(performSearch)
                                                userInfo: nil
                                                 repeats: NO];
}

-(void)performSearch
{
    if (self.navigationController.topViewController != self) return;

    if (self.searchString.length == 0) return;
    
    [self updateWordsToHighlight];
    
    [self searchForTerm:self.searchString];
}

-(void)updateWordsToHighlight
{
    // Call this only when searchString is updated. Keeps the list of words to highlight up to date.
    // Get the words by splitting searchString on a combination of whitespace and punctuation
    // character sets so search term words get highlighted even if the puncuation in the result is slightly
    // different from the punctuation in the retrieved search result title.
    NSMutableCharacterSet *charSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [charSet formUnionWithCharacterSet:[NSMutableCharacterSet punctuationCharacterSet]];
    self.searchStringWordsToHighlight = [self.searchString componentsSeparatedByCharactersInSet:charSet];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Hide the keyboard if it was visible when the results are scrolled, but only if
    // the results have been scrolled in excess of some small distance threshold first.
    // This prevents tiny scroll adjustments, which seem to occur occasionally for some
    // reason, from causing the keyboard to hide when the user is typing on it!
    CGFloat distanceScrolled = fabs(scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y);

    if (distanceScrolled > HIDE_KEYBOARD_ON_SCROLL_THRESHOLD) {
        [self hideKeyboard];
    }
}

#pragma mark Search term methods (requests titles matching search term and associated thumbnail urls)

-(void)clearSearchResults
{
    [self.searchMessageLabel hide];
    [self.didYouMeanButton hide];
    self.searchResults = @[];
    self.searchSuggestion = nil;
    [self.searchResultsTable reloadData];
    
    [[QueuesSingleton sharedInstance].articleFetchManager.operationQueue cancelAllOperations];
    
    // Cancel any in-progress searches.
    [[QueuesSingleton sharedInstance].searchResultsFetchManager.operationQueue cancelAllOperations];
}

- (void)fetchFinished: (id)sender
             userData: (id)userData
               status: (FetchFinalStatus)status
                error: (NSError *)error;
{
    if ([sender isKindOfClass:[SearchResultFetcher class]]) {
        
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                [self fadeAlert];
                [self.searchMessageLabel hide];

                self.searchResults = ((SearchResultFetcher *)sender).searchResults;

                //NSLog(@"self.searchResultsOrdered = %@", self.searchResultsOrdered);
                
                // We have search titles! Show them right away!
                // NSLog(@"FIRE ONE! Show search result titles.");
                [self.searchResultsTable reloadData];

                // Get WikiData Id's to pass to WikiDataShortDescriptionFetcher.
                NSMutableArray *wikiDataIds = @[].mutableCopy;
                for (NSDictionary *page in self.searchResults) {
                    id wikiDataId = page[@"wikibase_item"];
                    if(wikiDataId && [wikiDataId isKindOfClass:[NSString class]]){
                        [wikiDataIds addObject:wikiDataId];
                    }
                }

                // Fetch WikiData short descriptions.
                if (wikiDataIds.count > 0){
                    (void)[[WikiDataShortDescriptionFetcher alloc] initAndFetchDescriptionsForIds: wikiDataIds
                                                                                      withManager: [QueuesSingleton sharedInstance].searchResultsFetchManager
                                                                               thenNotifyDelegate: self];
                }

            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                [self fadeAlert];
                break;
            case FETCH_FINAL_STATUS_FAILED:
                [self.searchMessageLabel showWithText:error.localizedDescription];
                //[self showAlert:error.localizedDescription type:ALERT_TYPE_MIDDLE duration:-1];
                break;
        }
        
        // Show search suggestion if necessary.
        // Search suggestion can be returned if zero or more search results found.
        // That's why this is here in not in the "SUCCEEDED" case above.
        self.searchSuggestion = ((SearchResultFetcher *)sender).searchSuggestion;
        if (self.searchSuggestion) {
            [self.didYouMeanButton showWithText: MWLocalizedString(@"search-did-you-mean", nil)
                                           term: self.searchSuggestion];
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
                NSArray *visibleRowIndexPaths = [self.searchResultsTable indexPathsForVisibleRows];
                for (NSIndexPath *thisIndexPath in visibleRowIndexPaths.copy) {
                    
                    NSDictionary *rowData = self.searchResults[thisIndexPath.row];
                    NSString *url = rowData[@"thumbnail"][@"source"];
                    if ([url.lastPathComponent isEqualToString:fileName]) {
                        SearchResultCell *cell = (SearchResultCell *)[self.searchResultsTable cellForRowAtIndexPath:thisIndexPath];
                        cell.imageView.image = image;
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
                for (NSMutableDictionary *d in self.searchResults) {
                    NSString *wikiDataId = d[@"wikibase_item"];
                    if(wikiDataId){
                        if ([wikiDataShortDescriptions objectForKey:wikiDataId]) {
                            NSString *shortDesc = wikiDataShortDescriptions[wikiDataId];
                            if (shortDesc) {
                                d[@"wikidata_description"] = shortDesc;
                            }
                        }
                    }
                }
                
                [self.searchResultsTable reloadData];
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                break;
            case FETCH_FINAL_STATUS_FAILED:
                break;
        }
    }
}

- (void)searchForTerm:(NSString *)searchTerm
{
    [self clearSearchResults];

    [self.searchMessageLabel hide];
    
    // Show "Searching..." message.
    [self.searchMessageLabel showWithText:MWLocalizedString(@"search-searching", nil)];
    
    //[self showAlert:MWLocalizedString(@"search-searching", nil) type:ALERT_TYPE_MIDDLE duration:-1];
    
    // Search for titles.
    (void)[[SearchResultFetcher alloc] initAndSearchForTerm: searchTerm
                                                 searchType: self.searchTypeMenu.searchType
                                                withManager: [QueuesSingleton sharedInstance].searchResultsFetchManager
                                         thenNotifyDelegate: self];
}

#pragma mark Search results table methods (requests actual thumb image data)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
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

    NSString *title = self.searchResults[indexPath.row][@"title"];

    NSString *wikidata_description = self.searchResults[indexPath.row][@"wikidata_description"];

    [cell setTitle:title description:wikidata_description highlightWords:self.searchStringWordsToHighlight];
    
    NSString *thumbURL = self.searchResults[indexPath.row][@"thumbnail"][@"source"];

    // Set thumbnail placeholder
    cell.imageView.image = self.placeholderImage;
    cell.useField = NO;
    if (!thumbURL){
        // Don't bother downloading if no thumbURL
        return cell;
    }

    __block NSString *fileName = [thumbURL lastPathComponent];

    // See if cache file found, show it instead of downloading if found.
    NSString *cacheFilePath = [self.cachePath stringByAppendingPathComponent:fileName];
    BOOL isDirectory = NO;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath isDirectory:&isDirectory];
    if (fileExists) {
        cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:cacheFilePath]];
    }else{
        // No thumb found so fetch it.
        (void)[[ThumbnailFetcher alloc] initAndFetchThumbnailFromURL: thumbURL
                                                         withManager: [QueuesSingleton sharedInstance].searchResultsFetchManager
                                                  thenNotifyDelegate: self];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = self.searchResults[indexPath.row][@"title"];

    // Set CurrentArticleTitle so web view knows what to load.
    title = [title wikiTitleWithoutUnderscores];
    
    [self hideKeyboard];

    [NAV loadArticleWithTitle: [MWPageTitle titleWithString:title]
                       domain: [SessionSingleton sharedInstance].domain
                     animated: YES
              discoveryMethod: DISCOVERY_METHOD_SEARCH
            invalidatingCache: NO
                   popToWebVC: YES];
}

#pragma mark Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
