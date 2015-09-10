//  Created by Monte Hurd on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class MWKRecentSearchList, MWKRecentSearchEntry;
@protocol WMFRecentSearchesViewControllerDelegate;

@interface RecentSearchesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) MWKRecentSearchList* recentSearches;

- (void)reloadRecentSearches;

@property (nonatomic, weak) id<WMFRecentSearchesViewControllerDelegate> delegate;

@end


@protocol WMFRecentSearchesViewControllerDelegate <NSObject>

- (void)recentSearchController:(RecentSearchesViewController*)controller didSelectSearchTerm:(MWKRecentSearchEntry*)searchTerm;

@end
