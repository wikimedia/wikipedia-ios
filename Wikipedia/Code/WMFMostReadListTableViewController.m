//
//  WMFMostReadListTableViewController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/16/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFMostReadListTableViewController.h"
#import "WMFMostReadListDataSource.h"

@implementation WMFMostReadListTableViewController

- (instancetype)initWithPreviews:(NSArray<MWKSearchResult*>*)previews
                        fromSite:(MWKSite*)site
                       dataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        self.dataSource = [[WMFMostReadListDataSource alloc] initWithPreviews:previews fromSite:site];
        self.dataStore  = dataStore;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title = MWLocalizedString(@"explore-most-read-more-list-title", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource.tableView = self.tableView;
}

#pragma mark - WMFArticleListTableViewController

- (NSString*)analyticsName {
    return @"More Top Read Articles";
}

@end
