//
//  WMFMostReadListTableViewController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/16/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleListTableViewController.h"

@class MWKSearchResult;

@interface WMFMostReadListTableViewController : WMFArticleListTableViewController

- (instancetype)initWithPreviews:(NSArray<MWKSearchResult*>*)previews
                        fromSite:(MWKSite*)site
                         forDate:date
                       dataStore:(MWKDataStore*)dataStore;

@end
