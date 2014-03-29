//  Created by Monte Hurd on 12/16/13.

#import "SearchResultsController.h"
#import "Defines.h"
#import "QueuesSingleton.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "SearchResultCell.h"
#import "NavBarTextField.h"
#import "SessionSingleton.h"
#import "UIViewController+Alert.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "NSString+Extras.h"
#import "UIViewController+HideKeyboard.h"
#import "NavController.h"
#import "SearchOp.h"
#import "SearchThumbUrlsOp.h"
#import "NSManagedObjectContext+SimpleFetch.h"

#define NAV ((NavController *)self.navigationController)

@interface SearchResultsController (){
    CGFloat scrollViewDragBeganVerticalOffset_;
    ArticleDataContextSingleton *articleDataContext_;
}

@property (strong, atomic) NSMutableArray *searchResultsOrdered;
@property (weak, nonatomic) IBOutlet UITableView *searchResultsTable;
@property (strong, nonatomic) NSArray *currentSearchStringWordsToHighlight;

@end

@implementation SearchResultsController

- (void)viewDidLoad
{
    [super viewDidLoad];

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

-(void)refreshSearchResults
{
    if (NAV.currentSearchString.length == 0) return;
    
    [self updateWordsToHighlight];
    
    [self searchForTerm:NAV.currentSearchString];
}

-(void)updateWordsToHighlight
{
    // Call this only when currentSearchString is updated. Keeps the list of words to highlight up to date.
    // Get the words by splitting currentSearchString on a combination of whitespace and punctuation
    // character sets so search term words get highlighted even if the puncuation in the result is slightly
    // different from the punctuation in the retrieved search result title.
    NSMutableCharacterSet *charSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [charSet formUnionWithCharacterSet:[NSMutableCharacterSet punctuationCharacterSet]];
    self.currentSearchStringWordsToHighlight = [NAV.currentSearchString componentsSeparatedByCharactersInSet:charSet];
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
    [self.searchResultsOrdered removeAllObjects];
    [self.searchResultsTable reloadData];
    
    [[QueuesSingleton sharedInstance].articleRetrievalQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].thumbnailQ cancelAllOperations];
    
    // Cancel any in-progress article retrieval operations
    [[QueuesSingleton sharedInstance].searchQ cancelAllOperations];
}

- (void)searchForTerm:(NSString *)searchTerm
{
    [self clearSearchResults];
    
    // Show "Searching..." message.
    [self showAlert:NSLocalizedString(@"search-searching", nil)];
    
    
    
    
    // Titles thumbnail urls retrieval op (dependent on search op)
    SearchThumbUrlsOp *searchThumbURLsOp = [[SearchThumbUrlsOp alloc] initWithCompletionBlock: ^(NSDictionary *searchThumbUrlsResults){
        
        [articleDataContext_.workerContext performBlockAndWait:^(){
            
            for (NSMutableDictionary *searchOpResult in [self.searchResultsOrdered copy]) {
                
                if ([searchThumbUrlsResults objectForKey:searchOpResult[@"title"]]) {
                    searchOpResult[@"thumbnail"] = [searchThumbUrlsResults[searchOpResult[@"title"]] copy];
                    
                    // If url thumb found, prepare a core data Image object so URLCache will know this is an image
                    // to intercept. (Removing this would turn off thumbnail caching, but a better way to handle
                    // too many thumbnails would be periodically removing Image records which aren't referenced by
                    // a SectionImage record.)
                    
//TODO: write code to do the periodic core data store cleanup mentioned in above comment.
                    
                    NSString *src = searchOpResult[@"thumbnail"][@"source"];
                    NSNumber *height = searchOpResult[@"thumbnail"][@"height"];
                    NSNumber *width = searchOpResult[@"thumbnail"][@"width"];
                    if (src && height && width) {
                        [self insertPlaceHolderImageEntityIntoContext: articleDataContext_.workerContext
                                                      forImageWithUrl: src
                                                                width: width
                                                               height: height
                         ];
                    }
                }
            }
            
            NSError *error = nil;
            [articleDataContext_.workerContext save:&error];
            
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            // Now we also have search thumbnail url data in searchResultsOrdered! Reload so thumb downloads
            // for on-screen cells can happen!
            // NSLog(@"FIRE TWO! Reload table data so it will download thumbnail images for on-screen search results.");
            [self.searchResultsTable reloadData];
        });
        
    } cancelledBlock: ^(NSError *error){
        
        [self showAlert:@""];
        
    } errorBlock: ^(NSError *error){
        
        [self showAlert:error.localizedDescription];
        
    }];
    
    __weak SearchThumbUrlsOp *weakSearchThumbURLsOp = searchThumbURLsOp;
    
    
    
    
    // Search for titles op.
    SearchOp *searchOp = [[SearchOp alloc] initWithSearchTerm: searchTerm
                                              completionBlock: ^(NSArray *searchResults){
                                                  
                                                  [self showAlert:@""];
                                                  
                                                  NSMutableArray *orderedResults = @[].mutableCopy;
                                                  for (NSString *title in searchResults) {
                                                      
                                                      NSString *cleanTitle = [self cleanTitle:title];
                                                      
                                                      [orderedResults addObject:@{@"title": cleanTitle, @"thumbnail": @{}}.mutableCopy];
                                                  }
                                                  self.searchResultsOrdered = orderedResults;
                                                  
                                                  NAV.currentSearchResultsOrdered = self.searchResultsOrdered;
                                                  
                                                  dispatch_async(dispatch_get_main_queue(), ^(){
                                                      // We have search titles! Show them right away!
                                                      // NSLog(@"FIRE ONE! Show search result titles.");
                                                      [self.searchResultsTable reloadData];
                                                  });
                                                  
                                                  // Let the dependant thumb url op know what search terms it needs to act on.
                                                  weakSearchThumbURLsOp.titles = searchResults;
                                                  
                                              } cancelledBlock: ^(NSError *error){
                                                  
                                                  [self showAlert:@""];
                                                  
                                              } errorBlock: ^(NSError *error){
                                                  
                                                  [self showAlert:error.localizedDescription];
                                                  
                                              }];
    
    
    
    
    searchOp.delegate = self;
    searchThumbURLsOp.delegate = self;
    
    [searchThumbURLsOp addDependency:searchOp];
    
    [QueuesSingleton sharedInstance].searchQ.suspended = YES;
    [[QueuesSingleton sharedInstance].searchQ addOperation:searchThumbURLsOp];
    [[QueuesSingleton sharedInstance].searchQ addOperation:searchOp];
    [QueuesSingleton sharedInstance].searchQ.suspended = NO;
}

#pragma mark Core data Image record placeholder for thumbnail (so they get cached)

-(void)insertPlaceHolderImageEntityIntoContext: (NSManagedObjectContext *)context
                               forImageWithUrl: (NSString *)url
                                         width: (NSNumber *)width
                                        height: (NSNumber *)height
{
    Image *existingImage = (Image *)[context getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", [url getUrlWithoutScheme]];
    // If there's already an image record for this exact url, don't create another one!!!
    if (!existingImage) {
        Image *image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:context];
        image.imageData = [NSEntityDescription insertNewObjectForEntityForName:@"ImageData" inManagedObjectContext:context];
        image.imageData.data = [[NSData alloc] init];
        image.dataSize = @(image.imageData.data.length);
        image.fileName = [url lastPathComponent];
        image.fileNameNoSizePrefix = [image.fileName getWikiImageFileNameWithoutSizePrefix];
        image.extension = [url pathExtension];
        image.imageDescription = nil;
        image.sourceUrl = [url getUrlWithoutScheme];
        image.dateRetrieved = [NSDate date];
        image.dateLastAccessed = [NSDate date];
        image.width = @(width.integerValue);
        image.height = @(height.integerValue);
        image.mimeType = [image.extension getImageMimeTypeForExtension];
    }
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
        [[MWNetworkActivityIndicatorManager sharedManager] push];
    };
    thumbnailOp.completionBlock = ^(){
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
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
    
    [self hideKeyboard];

    [self.searchResultsTable deselectRowAtIndexPath:indexPath animated:YES];

    [NAV loadArticleWithTitle: title
                       domain: [SessionSingleton sharedInstance].domain
                     animated: YES
              discoveryMethod: DISCOVERY_METHOD_SEARCH];
}

#pragma mark Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
