@import UIKit;
@import WMF.Swift;

@class MWKRecentSearchList, MWKRecentSearchEntry;
@protocol WMFRecentSearchesViewControllerDelegate;

@interface RecentSearchesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, WMFThemeable>

@property (nonatomic, strong) MWKRecentSearchList *recentSearches;

- (void)reloadRecentSearches;

- (void)deselectAllAnimated:(BOOL)animated;

@property (nonatomic, weak) id<WMFRecentSearchesViewControllerDelegate> delegate;

@end

@protocol WMFRecentSearchesViewControllerDelegate <NSObject>

- (void)recentSearchController:(RecentSearchesViewController *)controller didSelectSearchTerm:(MWKRecentSearchEntry *)searchTerm;

@end
