//  Created by Monte Hurd on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "Defines.h"
#import "SearchResultFetcher.h"

@protocol WMFRecentSearchesViewControllerDelegate;

@interface RecentSearchesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign, readonly) NSUInteger recentSearchesItemCount;

@property (nonatomic, weak) id<WMFRecentSearchesViewControllerDelegate> delegate;

- (void)saveTerm:(NSString*)term
       forDomain:(NSString*)domain
            type:(SearchType)searchType;

@end


@protocol WMFRecentSearchesViewControllerDelegate <NSObject>

- (void)recentSearchController:(RecentSearchesViewController*)controller didSelectSearchTerm:(NSString*)searchTerm;

@end
