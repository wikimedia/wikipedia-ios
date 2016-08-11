//
//  WMFMostReadListTableViewController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/16/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFMostReadListTableViewController.h"
#import "WMFMostReadListDataSource.h"
#import "NSDateFormatter+WMFExtensions.h"

@implementation WMFMostReadListTableViewController

- (instancetype)initWithPreviews:(NSArray<MWKSearchResult*>*)previews
                     fromSiteURL:(NSURL*)siteURL
                         forDate:date
                       dataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        self.dataSource = [[WMFMostReadListDataSource alloc] initWithPreviews:previews fromSiteURL:siteURL];
        self.dataStore  = dataStore;
        self.title      = [self titleForDate:date];
    }
    return self;
}

- (NSString*)titleForDate:(NSDate*)date {
    return
        [MWLocalizedString(@"explore-most-read-more-list-title-for-date", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                         withString:
         [[NSDateFormatter wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:date]
        ];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource.tableView = self.tableView;
}

#pragma mark - WMFArticleListDataSourceTableViewController

- (NSString*)analyticsContext {
    return @"More Most Read";
}

@end
