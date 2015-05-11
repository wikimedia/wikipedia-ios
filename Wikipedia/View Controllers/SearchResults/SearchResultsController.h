
#import <UIKit/UIKit.h>

@class WMFIntrinsicContentSizeAwareTableView;
@class WMFSearchFunnel;

@interface SearchResultsController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readonly) IBOutlet WMFIntrinsicContentSizeAwareTableView* searchResultsTable;

@property (strong, nonatomic) NSArray* searchResults;
@property (strong, nonatomic) NSString* searchString;

/**
 *  Set the funnel for tracking search results
 */
@property (strong, nonatomic) WMFSearchFunnel* searchFunnel;

/**
 *  Specify articles that should not be displayed in the search results
 */
@property (strong, nonatomic) NSArray* articlesToExcludeFromResults;

/**
 *  Search Results VC configured for normal full display
 *
 *  @return The VC
 */
+ (SearchResultsController*)standardSearchResultsController;

/**
 *  The Search Results VC configured for display at the bottom of the webview
 *
 *  @return The VC
 */
+ (SearchResultsController*)readMoreSearchResultsController;


- (void)search;
- (void)clearSearchResults;
- (void)saveSearchTermToRecentList;
- (void)doneTapped;

@end
