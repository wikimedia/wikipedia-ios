//
//  WMFMostReadListTableViewController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/16/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleListDataSourceTableViewController.h"

@class MWKSearchResult;

@interface WMFMostReadListTableViewController : WMFArticleListDataSourceTableViewController

- (instancetype)initWithPreviews:(NSArray<MWKSearchResult*>*)previews
                     fromSiteURL:(NSURL*)siteURL
                         forDate:date
                       dataStore:(MWKDataStore*)dataStore;

@end
