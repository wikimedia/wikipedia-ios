//
//  WMFMostReadSectionController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/10/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFMostReadSectionController.h"
#import "WMFArticlePreviewFetcher.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "WMFArticleListTableViewCell.h"
#import "MWKTitle.h"
#import "MWKSearchResult.h"
#import "WMFArticleViewController.h"
#import "WMFMostReadTitleFetcher.h"
#import "WMFMostReadTitlesResponse.h"
#import "NSDate+Utilities.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFMainPagePlaceholderTableViewCell.h"
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFMostReadSectionController ()

@property (nonatomic, copy, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) NSDate* date;

@property (nonatomic, strong, nullable, readwrite) WMFMostReadTitlesResponseItem* mostReadArticlesResponse;

@property (nonatomic, strong) WMFArticlePreviewFetcher* previewFetcher;
@property (nonatomic, strong) WMFMostReadTitleFetcher* mostReadTitlesFetcher;

@end

@implementation WMFMostReadSectionController

- (instancetype)initWithDate:(NSDate *)date site:(MWKSite *)site dataStore:(MWKDataStore *)dataStore {
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.site = site;
        self.date = date;
    }
    return self;
}

- (NSString*)utcDateString {
    return [[NSDateFormatter wmf_englishUTCSlashDelimitedYearMonthDayFormatter] stringFromDate:self.date];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ site = %@, date = %@", [super description], self.site, [self utcDateString]];
}

- (WMFMostReadTitleFetcher*)mostReadTitlesFetcher {
    if (!_mostReadTitlesFetcher) {
        _mostReadTitlesFetcher = [[WMFMostReadTitleFetcher alloc] init];
    }
    return _mostReadTitlesFetcher;
}

- (WMFArticlePreviewFetcher*)previewFetcher {
    if (!_previewFetcher) {
        _previewFetcher = [[WMFArticlePreviewFetcher alloc] init];
    }
    return _previewFetcher;
}

#pragma mark - WMFExploreSectionController

#pragma mark Meta

- (NSString*)sectionIdentifier {
    return self.description;
}

- (CGFloat)estimatedRowHeight {
    return [WMFArticleListTableViewCell estimatedRowHeight];
}

- (NSString*)analyticsName {
    return @"Top Articles";
}

#pragma mark Header

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"trending-mini"];
}

- (NSAttributedString*)headerTitle {
    return [[NSAttributedString alloc]
            initWithString:MWLocalizedString(@"explore-most-read-heading", nil)
            attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString*)headerSubTitle {
    return [[NSAttributedString alloc]
            initWithString:[[NSDateFormatter wmf_mediumDateFormatterWithoutTime] stringFromDate:self.date]
            attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (UIColor*)headerIconTintColor {
    return [UIColor wmf_blueTintColor];
}

- (UIColor*)headerIconBackgroundColor {
    return [UIColor wmf_lightBlueTintColor];
}

#pragma mark Detail

- (UIViewController*)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[WMFArticleViewController alloc] initWithArticleTitle:[self titleForItemAtIndexPath:indexPath]
                                                        dataStore:self.dataStore];
}

#pragma mark - TitleProviding

- (nullable MWKTitle*)titleForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.items.count) {
        return nil;
    }
    MWKSearchResult* result = (MWKSearchResult*)self.items[indexPath.row];
    if (![result isKindOfClass:[MWKSearchResult class]]) {
        return nil;
    }
    return [[MWKTitle alloc] initWithSite:self.site normalizedTitle:result.displayTitle fragment:nil];
}

#pragma mark - WMFBaseExploreSectionController Subclass

- (nullable NSString*)placeholderCellIdentifier {
    return [WMFMainPagePlaceholderTableViewCell identifier];
}

- (nullable UINib*)placeholderCellNib {
    return [WMFMainPagePlaceholderTableViewCell wmf_classNib];
}

- (NSUInteger)numberOfPlaceholderCells {
    return 5;
}

- (NSString*)cellIdentifier {
    return [WMFArticleListTableViewCell wmf_nibName];
}

- (UINib*)cellNib {
    return [WMFArticleListTableViewCell wmf_classNib];
}

- (void)configureCell:(WMFArticleListTableViewCell*)cell
             withItem:(MWKSearchResult*)item
          atIndexPath:(NSIndexPath*)indexPath {
    [cell setImageURL:item.thumbnailURL];
    [cell setTitleText:item.displayTitle];
    [cell setDescriptionText:item.wikidataDescription];
}

- (AnyPromise*)fetchData {
    @weakify(self);
    return [self.mostReadTitlesFetcher fetchMostReadTitlesForSite:self.site date:self.date]
           .thenInBackground(^id (WMFMostReadTitlesResponseItem* mostReadResponse) {
        @strongify(self);
        NSParameterAssert([mostReadResponse.site isEqualToSite:self.site]);
        if (!self) {
            return [NSError cancelledError];
        }
        self.mostReadArticlesResponse = mostReadResponse;
        NSArray<MWKTitle*>* titlesToPreview = [[mostReadResponse.articles
                                                wmf_safeSubarrayWithRange:NSMakeRange(0, 5)]
                                               bk_map:^MWKTitle*(WMFMostReadTitlesResponseItemArticle* article) {
            // HAX: must normalize title otherwise it won't match fetched previews. this is why pageid > title
            return [[MWKTitle alloc] initWithString:article.titleText site:self.site];
        }];
        return [self.previewFetcher fetchArticlePreviewResultsForTitles:titlesToPreview site:mostReadResponse.site];
    });
}

@end

NS_ASSUME_NONNULL_END
