
#import <UIKit/UIKit.h>

@interface SearchResultsController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readonly) IBOutlet UITableView *searchResultsTable;

@property (strong, nonatomic) NSArray *searchResults;
@property (strong, nonatomic) NSString *searchString;

@property (assign, nonatomic) NSUInteger maxResults;
@property (assign, nonatomic) NSUInteger minResultsBeforeRunningFullTextSearch;
@property (assign, nonatomic) BOOL enableSupplementalFullTextSearch;

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


-(void)search;
-(void)clearSearchResults;
-(void)saveSearchTermToRecentList;
-(void)doneTapped;

@end
