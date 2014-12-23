//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchResultsController.h"
#import "WikipediaAppUtils.h"
#import "Defines.h"
#import "QueuesSingleton.h"
#import "SearchResultCell.h"
#import "SessionSingleton.h"
#import "UIViewController+Alert.h"
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
#import "SearchMessageLabel.h"
#import "RecentSearchesViewController.h"
#import "NSArray+Predicate.h"
#import "SearchResultAttributedString.h"
#import "UITableView+DynamicCellHeight.h"

#define TABLE_CELL_ID @"SearchResultCell"

@interface SearchResultsController (){
    CGFloat scrollViewDragBeganVerticalOffset_;
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

@property (strong, nonatomic) RecentSearchesViewController *recentSearchesViewController;

@property (nonatomic, weak) IBOutlet UIView *recentSearchesContainer;

@property (nonatomic) BOOL ignoreScrollEvents;

@property (strong, nonatomic) NSDictionary *attributesTitle;
@property (strong, nonatomic) NSDictionary *attributesDescription;
@property (strong, nonatomic) NSDictionary *attributesHighlight;
@property (strong, nonatomic) NSDictionary *attributesSnippet;
@property (strong, nonatomic) NSDictionary *attributesSnippetHighlight;

@property (strong, nonatomic) SearchResultCell *offScreenSizingCell;

@end

@implementation SearchResultsController

-(void)setupStringAttributes
{
    NSMutableParagraphStyle *descriptionParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    descriptionParagraphStyle.paragraphSpacingBefore = SEARCH_RESULT_PADDING_ABOVE_DESCRIPTION;

    NSMutableParagraphStyle *snippetParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    snippetParagraphStyle.paragraphSpacingBefore = SEARCH_RESULT_PADDING_ABOVE_SNIPPET;
    
    self.attributesDescription =
    @{
      NSFontAttributeName : SEARCH_RESULT_DESCRIPTION_FONT,
      NSForegroundColorAttributeName : SEARCH_RESULT_DESCRIPTION_FONT_COLOR,
      NSParagraphStyleAttributeName : descriptionParagraphStyle
      };
    
    self.attributesTitle =
    @{
      NSFontAttributeName : SEARCH_RESULT_FONT,
      NSForegroundColorAttributeName : SEARCH_RESULT_FONT_COLOR
      };

    self.attributesSnippet =
    @{
      NSParagraphStyleAttributeName : snippetParagraphStyle,
      NSFontAttributeName : SEARCH_RESULT_SNIPPET_FONT,
      NSForegroundColorAttributeName : SEARCH_RESULT_SNIPPET_FONT_COLOR
      };

    self.attributesSnippetHighlight =
    @{
      NSParagraphStyleAttributeName : snippetParagraphStyle,
      NSFontAttributeName : SEARCH_RESULT_SNIPPET_FONT,
      NSForegroundColorAttributeName : SEARCH_RESULT_SNIPPET_HIGHLIGHT_COLOR
      };
    
    self.attributesHighlight =
    @{
      NSFontAttributeName : SEARCH_RESULT_FONT_HIGHLIGHTED,
      NSForegroundColorAttributeName : SEARCH_RESULT_FONT_HIGHLIGHTED_COLOR
      };
}

-(void)setSearchString:(NSString *)searchString
{
    _searchString = searchString;
    
    [self updateRecentSearchesContainerVisibility];
}

-(void)updateRecentSearchesContainerVisibility
{
    BOOL shouldHide = (
        (self.searchString.length == 0)
        &&
        (self.recentSearchesViewController.recentSearchesItemCount.integerValue > 0)
    ) ? NO : YES;

    if (self.recentSearchesContainer.hidden == shouldHide) return;

    [UIView transitionWithView: self.recentSearchesContainer
                      duration: 0.25
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: NULL
                    completion: NULL];
    
    self.recentSearchesContainer.hidden = shouldHide;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString: @"RecentSearchesViewController_embed"]) {
		self.recentSearchesViewController = (RecentSearchesViewController *) [segue destinationViewController];
	}
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupStringAttributes];

    self.ignoreScrollEvents = NO;
    self.searchString = @"";
    
    self.placeholderImage = [UIImage imageNamed:@"logo-placeholder-search.png"];
    
    // NSCachesDirectory can be used as temp storage. iOS will clear this directory if it needs to so
    // don't store anything critical there. Works well here for quick access to thumbs as user scrolls
    // table view.
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.cachePath = [cachePaths objectAtIndex:0];

    self.searchStringWordsToHighlight = @[];
    
    scrollViewDragBeganVerticalOffset_ = 0.0f;

    self.searchResults = @[];
    self.searchSuggestion = nil;
    self.navigationItem.hidesBackButton = YES;

    // Register the search results cell for reuse
    [self.searchResultsTable registerNib:[UINib nibWithNibName:@"SearchResultPrototypeView" bundle:nil] forCellReuseIdentifier:TABLE_CELL_ID];

    // Turn off the separator since one gets added in SearchResultCell.m
    self.searchResultsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Observe searchTypeMenu's searchType, refresh results if it changes - ie user tapped "Titles" or "Within articles".
    [self.searchTypeMenu addObserver: self
                          forKeyPath: @"searchType"
                             options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                             context: nil];

    self.didYouMeanButton.userInteractionEnabled = YES;
    [self.didYouMeanButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didYouMeanButtonPushed)]];

    [self.recentSearchesViewController addObserver: self
                                        forKeyPath: @"recentSearchesItemCount"
                                           options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                           context: nil];

    // Single off-screen cell for determining dynamic cell height.
    self.offScreenSizingCell = (SearchResultCell *)[self.searchResultsTable dequeueReusableCellWithIdentifier:TABLE_CELL_ID];
}

-(void)dealloc
{
    [self.searchTypeMenu removeObserver:self forKeyPath:@"searchType"];
    [self.recentSearchesViewController removeObserver:self forKeyPath: @"recentSearchesItemCount"];
}

-(void)didYouMeanButtonPushed
{
    [self.didYouMeanButton hide];
    TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
    textFieldContainer.textField.text = self.searchSuggestion;
    self.searchString = self.searchSuggestion;
    [self searchAfterDelay:@0.0f reason:SEARCH_REASON_DID_YOU_MEAN_TAPPED];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if ((object == self.searchTypeMenu) && [keyPath isEqualToString:@"searchType"]) {
        [self searchAfterDelay:@0.0f reason:SEARCH_REASON_SEARCH_TYPE_MENU_TAPPED];
    }else if ((object == self.recentSearchesViewController) && [keyPath isEqualToString:@"recentSearchesItemCount"]) {
        [self updateRecentSearchesContainerVisibility];
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
        [self searchAfterDelay:@0.05f reason:SEARCH_REASON_VIEW_APPEARED];
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
        
        [self searchAfterDelay:@(delay) reason:SEARCH_REASON_SEARCH_STRING_CHANGED];
    }
}

-(void)searchAfterDelay:(NSNumber *)delay reason:(SearchReason)reason
{
    [self cancelDelayedSearch];

    self.delayedSearchTimer = [NSTimer scheduledTimerWithTimeInterval: delay.floatValue
                                                               target: self
                                                             selector: @selector(performSearch:)
                                                             userInfo: @{@"reason": @(reason)}
                                                              repeats: NO];
}

-(void)performSearch:(NSTimer *)timer
{
    // Reminder: do not call "performSearch:" directly - only "searchAfterDelay:reason:" should do so.
    // To search call "searchAfterDelay:reason:" - this is because it ensures delayed searches get cancelled.

    SearchReason reason = ((NSNumber *)timer.userInfo[@"reason"]).integerValue;

    if (self.navigationController.topViewController != self) return;

    if (self.searchString.length == 0) return;

    if (reason == SEARCH_REASON_NO_PREFIX_RESULTS) {
        // Switch to in-article search.
        self.searchTypeMenu.searchType = SEARCH_TYPE_IN_ARTICLES;
        // Show "Searching..." message.
        [self.searchMessageLabel showWithText:MWLocalizedString(@"search-searching", nil)];
    }
    
    [self updateWordsToHighlight];
    
    [self searchForTerm:self.searchString reason:reason];
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
    if (self.ignoreScrollEvents) return;
    
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

-(void)updateAttributeTextForSearchType: (SearchType) searchType
{
    for (NSMutableDictionary *result in self.searchResults) {
        //TODO: change name of "SearchResultAttributedString" to "SearchResultStringStyler" or something... it's an NSObject!
        SearchResultAttributedString *attributedResult =
        [SearchResultAttributedString initWithTitle: result[@"title"]
                                            snippet: result[@"snippet"]
                                wikiDataDescription: result[@"description"]
                                     highlightWords: self.searchStringWordsToHighlight
                                         searchType: searchType
                                    attributesTitle: self.attributesTitle
                              attributesDescription: self.attributesDescription
                                attributesHighlight: self.attributesHighlight
                                  attributesSnippet: self.attributesSnippet
                         attributesSnippetHighlight: self.attributesSnippetHighlight];
        
        result[@"attributedText"] = attributedResult;
    }
}

- (void)fetchFinished: (id)sender
          fetchedData: (id)fetchedData
               status: (FetchFinalStatus)status
                error: (NSError *)error;
{
    if ([sender isKindOfClass:[SearchResultFetcher class]]) {

        SearchResultFetcher *searchResultFetcher = (SearchResultFetcher *)sender;
        
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                [self fadeAlert];
                [self.searchMessageLabel hide];

                self.searchResults = searchResultFetcher.searchResults;

                //NSLog(@"self.searchResultsOrdered = %@", self.searchResultsOrdered);

                [self updateAttributeTextForSearchType:searchResultFetcher.searchType];
                
                // We have search titles! Show them right away!
                // NSLog(@"FIRE ONE! Show search result titles.");
                [self.searchResultsTable reloadData];
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                [self fadeAlert];
                break;
            case FETCH_FINAL_STATUS_FAILED:

                if(error.code == SEARCH_RESULT_ERROR_NO_MATCHES){
                    [self clearSearchResults];
                    [self.searchMessageLabel showWithText:error.localizedDescription];

                    // If this set of results came from a title search and no results were found,
                    // switch to in-article and re-run the search. But don't do so if the search
                    // is being triggered by a change in the search type menu selection.
                    if(
                       (searchResultFetcher.searchType == SEARCH_TYPE_TITLES)
                       &&
                       (searchResultFetcher.searchReason != SEARCH_REASON_SEARCH_TYPE_MENU_TAPPED)
                       ){

                        if(!ENABLE_FULL_TEXT_SEARCH) return;
                        
                        // Note: the search button is not switched until "performSearch:" is
                        // invoked as a result of the "searchAfterDelay:reason:" call below.
                        // That way the users can see the "No search results" message in association
                        // with the "Titles" button briefly before the in-article search is
                        // automatically kicked off.
                        [self searchAfterDelay:@1.08f reason:SEARCH_REASON_NO_PREFIX_RESULTS];
                        return;
                    }
                }else{
                    [self.searchMessageLabel showWithText:error.localizedDescription];
                }
            
                //[self.searchMessageLabel showWithText:error.localizedDescription];
                //[self showAlert:error.localizedDescription type:ALERT_TYPE_MIDDLE duration:-1];
                break;
        }
        
        // Show search suggestion if necessary.
        // Search suggestion can be returned if zero or more search results found.
        // That's why this is here in not in the "SUCCEEDED" case above.
        self.searchSuggestion = searchResultFetcher.searchSuggestion;
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
                [fetchedData writeToFile:cacheFilePath atomically:YES];
                
                // Then see if cell for this image name is still onscreen and set its image if so.
                UIImage *image = [UIImage imageWithData:fetchedData];
                
                // Check if cell still onscreen! This is important!
                NSArray *visibleRowIndexPaths = [self.searchResultsTable indexPathsForVisibleRows];
                for (NSIndexPath *thisIndexPath in visibleRowIndexPaths.copy) {
                    
                    NSDictionary *rowData = self.searchResults[thisIndexPath.row];
                    NSString *url = rowData[@"thumbnail"][@"source"];
                    if ([url.lastPathComponent isEqualToString:fileName]) {
                        SearchResultCell *cell = (SearchResultCell *)[self.searchResultsTable cellForRowAtIndexPath:thisIndexPath];
                        cell.resultImageView.image = image;
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

-(void)scrollTableToTop
{
    if ([self.searchResultsTable numberOfRowsInSection:0] > 0) {
        // Ignore scroll event so keyboard doesn't disappear.
        self.ignoreScrollEvents = YES;
        [UIView animateWithDuration:0.15f animations:^{
            [self.searchResultsTable scrollToRowAtIndexPath: [NSIndexPath indexPathForRow:0 inSection:0]
                                           atScrollPosition: UITableViewScrollPositionTop
                                                   animated: NO];
        } completion:^(BOOL done){
            self.ignoreScrollEvents = NO;
        }];
    }
}

- (void)searchForTerm:(NSString *)searchTerm reason:(SearchReason)reason
{
    // Reminder: do not call "searchForTerm:reason:" directly - only "performSearch:" should do so.
    // To search call "searchAfterDelay:reason:" - this is because it ensures delayed searches get cancelled.

    [self scrollTableToTop];

    [self.didYouMeanButton hide];
    
    // Show "Searching..." message.
    //[self.searchMessageLabel showWithText:MWLocalizedString(@"search-searching", nil)];
    
    //[self showAlert:MWLocalizedString(@"search-searching", nil) type:ALERT_TYPE_MIDDLE duration:-1];
    
    // Search! Only call this here!
    (void)[[SearchResultFetcher alloc] initAndSearchForTerm: searchTerm
                                                 searchType: self.searchTypeMenu.searchType
                                               searchReason: reason
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
    // Update the sizing cell with any data which could change the cell height.
    self.offScreenSizingCell.resultLabel.attributedText = self.searchResults[indexPath.row][@"attributedText"];

    // Determine height for the current configuration of the sizing cell.
    return [tableView heightForSizingCell:self.offScreenSizingCell];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = TABLE_CELL_ID;
    SearchResultCell *cell = (SearchResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];

    NSString *thumbURL = self.searchResults[indexPath.row][@"thumbnail"][@"source"];

    // For performance reasons, "attributedText" is build when data is retrieved, not here when the cell
    // is about to be displayed.
    cell.resultLabel.attributedText = self.searchResults[indexPath.row][@"attributedText"];
    
    // Set thumbnail placeholder
    cell.resultImageView.image = self.placeholderImage;

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
        cell.resultImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:cacheFilePath]];
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
    [self hideKeyboard];

    NSString *title = self.searchResults[indexPath.row][@"title"];

    [self loadArticleWithTitle:title];
}

-(void)loadArticleWithTitle:(NSString *)title
{
    [self saveSearchTermToRecentList];

    // Set CurrentArticleTitle so web view knows what to load.
    title = [title wikiTitleWithoutUnderscores];

    [NAV loadArticleWithTitle: [[SessionSingleton sharedInstance].searchSite titleWithString:title]
                     animated: YES
              discoveryMethod: MWK_DISCOVERY_METHOD_SEARCH
            invalidatingCache: NO
                   popToWebVC: YES];
}

-(void)doneTapped
{
    if(self.searchResults.count == 0) return;

    // If there is an exact match in the search results for the current search term,
    // load that article.
    if ([self perfectSearchStringTitleMatchFoundInSearchResults]){
        [self loadArticleWithTitle:self.searchString];
    }else{
        // Else load title of first result.
        NSDictionary *firstItem = self.searchResults.firstObject;
        if (firstItem[@"title"]) [self loadArticleWithTitle:firstItem[@"title"]];
    }
}

-(void)saveSearchTermToRecentList
{
    [self.recentSearchesViewController saveTerm: self.searchString
                                      forDomain: [SessionSingleton sharedInstance].searchSite.language
                                           type: self.searchTypeMenu.searchType];
}

-(BOOL)perfectSearchStringTitleMatchFoundInSearchResults
{
    if(self.searchResults.count == 0) return NO;
    id perfectMatch =
        [self.searchResults firstMatchForPredicate:[NSPredicate predicateWithFormat:@"(title == %@)", self.searchString]];
    
    BOOL perfectMatchFound = perfectMatch ? YES : NO;
    return perfectMatchFound;
}

#pragma mark Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
