//
//  WMFTrendingSectionController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 1/19/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFTrendingSectionController.h"
#import "Wikipedia-Swift.h"

#import "MWKSite.h"
#import "MWKDataStore.h"
#import "WMFTrendingFetcher.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "WMFTrendingFetcher.h"

#import "WMFArticlePreviewTableViewCell.h"
#import "WMFArticlePlaceholderTableViewCell.h"

static NSString* const WMFTrendingSectionIdentifierPrefix = @"WMFTrendingSectionIdentifier";

@interface WMFTrendingSectionController ()

@property (nonatomic, strong) MWKSite* site;
@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) NSDate* date;

@property (nonatomic, strong) WMFTrendingFetcher* fetcher;
@property (nonatomic, strong, nullable) NSArray* results;

@end

@implementation WMFTrendingSectionController
@synthesize delegate=_delegate;

- (instancetype)initWithDate:(NSDate *)date site:(MWKSite *)site dataStore:(MWKDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.site = site;
        self.dataStore = dataStore;
        self.date = date;
    }
    return self;
}

- (WMFTrendingFetcher*)fetcher {
    if (!_fetcher) {
        _fetcher = [[WMFTrendingFetcher alloc] init];
    }
    return _fetcher;
}

#pragma mark - WMFExploreArticleSectionController

- (UITableViewCell*)dequeueCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    if (self.results.count) {
        return [tableView dequeueReusableCellWithIdentifier:[WMFArticlePreviewTableViewCell wmf_nibName]];
    } else {
        return [tableView dequeueReusableCellWithIdentifier:[WMFArticlePlaceholderTableViewCell wmf_nibName]];
    }
}

- (void)registerCellsInTableView:(UITableView *)tableView {
    [tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib]
    forCellReuseIdentifier:[WMFArticlePreviewTableViewCell wmf_nibName]];
    [tableView registerNib:[WMFArticlePlaceholderTableViewCell wmf_classNib]
    forCellReuseIdentifier:[WMFArticlePlaceholderTableViewCell wmf_nibName]];
}

- (void)configureCell:(UITableViewCell *)cell
           withObject:(id)object
          inTableView:(UITableView *)tableView
          atIndexPath:(NSIndexPath *)indexPath {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSParameterAssert([cell isKindOfClass:[WMFArticlePreviewTableViewCell class]]);
        WMFArticlePreviewTableViewCell* previewCell = (WMFArticlePreviewTableViewCell*)cell;
        previewCell.titleText = self.results[indexPath.row][@"article"];
    }
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    if (!self.results || index > self.results.count - 1) {
        return nil;
    } else {
        return [[MWKTitle alloc] initWithSite:self.site
                              normalizedTitle:self.results[index][@"article"]
                                     fragment:nil];
    }
}

- (id)sectionIdentifier {
    return [WMFTrendingSectionIdentifierPrefix stringByAppendingString:
            [[NSDateFormatter wmf_englishSlashDelimitedYearMonthDayFormatter] stringFromDate:self.date]];
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"trending-mini"];
}

- (NSAttributedString*)headerText {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"home-trending-heading", nil)
                                           attributes:nil];
}

- (NSArray*)items {
    if (self.results.count > 0) {
        return [self.results wmf_safeSubarrayWithRange:NSMakeRange(0, 3)];
    } else {
        return @[@0, @1, @2];
    }
}

- (NSString*)analyticsName {
    return @"Trending";
}

#pragma mark - Fetching

- (void)fetchDataIfNeeded {
    if (self.fetcher.isFetching || self.results) {
        return;
    }

    @weakify(self);
    [self.fetcher fetchTrendingForSite:self.site date:self.date]
    .then(^(NSArray* results) {
        @strongify(self);
        self.results = results;
        [self.delegate controller:self didSetItems:self.items];
    });
}

@end
