//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "FetcherBase.h"

@interface SearchResultsController : UIViewController <UITableViewDelegate, FetchFinishedDelegate>

// Presents a view controller which, in its viewWillAppear method, does a
// search for the NavController's currentSearchString and presents a list
// of search results.

// This method will force a fresh of search results. Note: If popping to this view
// controller or pushing this view controller onto the nav stack calling
// "refreshSearchResults" is unnecessary as it is automatically called when this
// view controller fires its viewWillAppear method. Probably use only in cases where
// this view controller is already on top of the nav stack and the search term has
// changed.
-(void)refreshSearchResults;
-(void)clearSearchResults;

@end
