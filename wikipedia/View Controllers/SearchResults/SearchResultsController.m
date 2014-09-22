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

@interface SearchResultsController (){
    CGFloat scrollViewDragBeganVerticalOffset_;
    ArticleDataContextSingleton *articleDataContext_;
}

@property (strong, atomic) NSArray *searchResultsOrdered;
@property (weak, nonatomic) IBOutlet UITableView *searchResultsTable;
@property (strong, nonatomic) NSArray *currentSearchStringWordsToHighlight;

@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) NSString *cachePath;

@end

@implementation SearchResultsController

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.placeholderImage = [UIImage imageNamed:@"logo-placeholder-search.png"];
    
    // NSCachesDirectory can be used as temp storage. iOS will clear this directory if it needs to so
    // don't store anything critical there. Works well here for quick access to thumbs as user scrolls
    // table view.
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.cachePath = [cachePaths objectAtIndex:0];

    self.currentSearchStringWordsToHighlight = @[];
    
    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    scrollViewDragBeganVerticalOffset_ = 0.0f;

    self.searchResultsOrdered = [[NSMutableArray alloc] init];
    self.navigationItem.hidesBackButton = YES;

    // Register the search results cell for reuse
    [self.searchResultsTable registerNib:[UINib nibWithNibName:@"SearchResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"SearchResultCell"];

    // Turn off the separator since one gets added in SearchResultCell.m
    self.searchResultsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshSearchResults];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[QueuesSingleton sharedInstance].searchResultsFetchManager.operationQueue cancelAllOperations];
}

-(void)refreshSearchResults
{
    if (ROOT.topMenuViewController.currentSearchString.length == 0) return;
    
    [self updateWordsToHighlight];
    
    [self searchForTerm:ROOT.topMenuViewController.currentSearchString];
}

-(void)updateWordsToHighlight
{
    // Call this only when currentSearchString is updated. Keeps the list of words to highlight up to date.
    // Get the words by splitting currentSearchString on a combination of whitespace and punctuation
    // character sets so search term words get highlighted even if the puncuation in the result is slightly
    // different from the punctuation in the retrieved search result title.
    NSMutableCharacterSet *charSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [charSet formUnionWithCharacterSet:[NSMutableCharacterSet punctuationCharacterSet]];
    self.currentSearchStringWordsToHighlight = [ROOT.topMenuViewController.currentSearchString componentsSeparatedByCharactersInSet:charSet];
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
    self.searchResultsOrdered = @[];
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
                self.searchResultsOrdered = userData;
                ROOT.topMenuViewController.currentSearchResultsOrdered = self.searchResultsOrdered.copy;
                
                // We have search titles! Show them right away!
                // NSLog(@"FIRE ONE! Show search result titles.");
                [self.searchResultsTable reloadData];
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                [self fadeAlert];
                break;
            case FETCH_FINAL_STATUS_FAILED:
                [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                break;
        }
    }

    if ([sender isKindOfClass:[ThumbnailFetcher class]]) {
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
                    
                    NSDictionary *rowData = self.searchResultsOrdered[thisIndexPath.row];
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
    }
}

- (void)searchForTerm:(NSString *)searchTerm
{
    [self clearSearchResults];
    
    // Show "Searching..." message.
    [self showAlert:MWLocalizedString(@"search-searching", nil) type:ALERT_TYPE_TOP duration:-1];
    
    // Search for titles.
    (void)[[SearchResultFetcher alloc] initAndSearchForTerm: searchTerm
                                                withManager: [QueuesSingleton sharedInstance].searchResultsFetchManager
                                         thenNotifyDelegate: self];
}

#pragma mark Search term highlighting

-(NSAttributedString *)getAttributedTitle:(NSString *)title
{
    // Returns attributed string of title with the current search term highlighted.
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:title];

    // Set base color and font of the entire result title
    [str addAttribute:NSFontAttributeName
                value:SEARCH_RESULT_FONT
                range:NSMakeRange(0, str.length)];

    [str addAttribute:NSForegroundColorAttributeName
                value:SEARCH_RESULT_FONT_COLOR
                range:NSMakeRange(0, str.length)];

    for (NSString *word in self.currentSearchStringWordsToHighlight.copy) {
        // Search term highlighting
        NSRange rangeOfThisWordInTitle = [title rangeOfString: word
                                                      options: NSCaseInsensitiveSearch |
                                                               NSDiacriticInsensitiveSearch |
                                                               NSWidthInsensitiveSearch
                                          ];

        [str addAttribute:NSFontAttributeName
                    value:SEARCH_RESULT_FONT_HIGHLIGHTED
                    range:rangeOfThisWordInTitle];
        
        [str addAttribute:NSForegroundColorAttributeName
                    value:SEARCH_RESULT_FONT_HIGHLIGHTED_COLOR
                    range:rangeOfThisWordInTitle];
    }
    return str;
}

#pragma mark Search results table methods (requests actual thumb image data)

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
    NSString *title = self.searchResultsOrdered[indexPath.row][@"title"];

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
