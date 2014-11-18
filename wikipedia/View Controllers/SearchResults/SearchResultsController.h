//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "FetcherBase.h"

@interface SearchResultsController : UIViewController <UITableViewDelegate, FetchFinishedDelegate>

@property (strong, nonatomic) NSArray *searchResults;
@property (strong, nonatomic) NSString *searchString;

-(void)search;
-(void)clearSearchResults;
-(void)saveSearchTermToRecentList;
-(void)doneTapped;

@end
