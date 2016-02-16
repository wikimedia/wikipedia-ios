//
//  WMFMostReadSectionController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/10/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFMostReadSectionController.h"
#import "Wikipedia-Swift.h"

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
#import "NSNumber+MWKTitleNamespace.h"
#import <Tweaks/FBTweakInline.h>
#import "WMFMostReadListTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFMostReadSectionController ()

@property (nonatomic, copy, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) NSDate* date;
@property (nonatomic, strong, readonly) NSString* localDateDisplayString;

@property (nonatomic, strong, nullable, readwrite) WMFMostReadTitlesResponseItem* mostReadArticlesResponse;
@property (nonatomic, strong, nullable, readwrite) NSArray<MWKSearchResult*>* previews;

@property (nonatomic, strong) WMFArticlePreviewFetcher* previewFetcher;
@property (nonatomic, strong) WMFMostReadTitleFetcher* mostReadTitlesFetcher;

@end

@implementation WMFMostReadSectionController
@synthesize localDateDisplayString = _localDateDisplayString;

- (instancetype)initWithDate:(NSDate*)date site:(MWKSite*)site dataStore:(MWKDataStore*)dataStore {
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.site = site;
        self.date = date;
    }
    return self;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ site = %@, date = %@", [super description], self.site, [self englishUTCDateString]];
}

#pragma mark - Accessors

- (void)setPreviews:(nullable NSArray<MWKSearchResult*>*)previews {
    _previews = [previews bk_select:^BOOL (MWKSearchResult* preview) {
        return [preview.titleNamespace wmf_isMainNamespace];
    }];
}

/**
 *  String to display to the user for the receiver's date.
 *
 *  "Most read" articles are computed for UTC dates. UTC time zone is used because converting to the user's time zone
 *  might accidentally change the "day" the app displays based on the the offset between UTC & the device's default time
 *  zone.  For example: 02/12/2016 01:26 UTC converted to EST is 02/11/2016 20:26, one day off!
 *
 *  @return A string formatted with the current locale, in the UTC time zone.
 */
- (NSString*)localDateDisplayString {
    if (!_localDateDisplayString) {
        _localDateDisplayString = [[NSDateFormatter wmf_utcMediumDateFormatterWithoutTime] stringFromDate:self.date];
    }
    return _localDateDisplayString;
}

/**
 *  Stable string for the receiver's date that doesn't vary by current calendar, locale, or time zone.
 *
 *  This is necessary to ensure that cached sections are retrievable when the locale, calendar, etc. changes.
 *
 *  @return An english-formatted string of the receiver's date in the UTC time zone.
 */
- (NSString*)englishUTCDateString {
    return [[NSDateFormatter wmf_englishUTCSlashDelimitedYearMonthDayFormatter] stringFromDate:self.date];
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
    return [NSString stringWithFormat:@"%@_%@", self.site, [self englishUTCDateString]];
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
    // fall back to language code if it can't be localized
    NSString* language        = [[NSLocale currentLocale] wmf_localizedLanguageNameForCode:self.site.language] ? : self.site.language;
    NSString* headingWithSite =
        [MWLocalizedString(@"explore-most-read-heading", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                        withString:language];
    NSDictionary* attributes = @{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]};
    return [[NSAttributedString alloc] initWithString:headingWithSite attributes:attributes];
}

- (NSAttributedString*)headerSubTitle {
    NSString* subheading =
        [MWLocalizedString(@"explore-most-read-subheading", nil)
         stringByReplacingOccurrencesOfString:@"$1"
                                   withString:self.localDateDisplayString];
    return [[NSAttributedString alloc]
            initWithString:subheading
                attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (UIColor*)headerIconTintColor {
    return [UIColor wmf_blueTintColor];
}

- (UIColor*)headerIconBackgroundColor {
    return [UIColor wmf_lightBlueTintColor];
}

#pragma mark Footer

- (NSString*)footerText {
    return MWLocalizedString(@"explore-most-read-footer", nil);
}

- (UIViewController*)moreViewController {
    return [[WMFMostReadListTableViewController alloc] initWithPreviews:self.previews
                                                               fromSite:self.site
                                                              dataStore:self.dataStore];
}

#pragma mark Detail

- (UIViewController*)detailViewControllerForItemAtIndexPath:(NSIndexPath*)indexPath {
    return [[WMFArticleViewController alloc] initWithArticleTitle:[self titleForItemAtIndexPath:indexPath]
                                                        dataStore:self.dataStore];
}

#pragma mark - TitleProviding

- (nullable MWKTitle*)titleForItemAtIndexPath:(NSIndexPath*)indexPath {
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
           .then(^id (WMFMostReadTitlesResponseItem* mostReadResponse) {
        @strongify(self);
        NSParameterAssert([mostReadResponse.site isEqualToSite:self.site]);
        if (!self) {
            return [NSError cancelledError];
        }
        self.mostReadArticlesResponse = mostReadResponse;
        WMF_TECH_DEBT_TODO(need to test for issues with really long query strings);
        NSArray<MWKTitle*>* titlesToPreview = [mostReadResponse.articles
                                               bk_map:^MWKTitle*(WMFMostReadTitlesResponseItemArticle* article) {
            // HAX: must normalize title otherwise it won't match fetched previews. this is why pageid > title
            return [[MWKTitle alloc] initWithString:article.titleText site:self.site];
        }];
        return [self.previewFetcher fetchArticlePreviewResultsForTitles:titlesToPreview
                                                                   site:mostReadResponse.site
                                                          extractLength:0];
    })
           .then(^NSArray<MWKSearchResult*>*(NSArray<MWKSearchResult*>* previews) {
        @strongify(self);
        self.previews = previews;
        // only return first 5 previews to the section, store the rest internally for the full list view
        return [self.previews wmf_safeSubarrayWithRange:NSMakeRange(0, 5)];
    });
}

@end

NS_ASSUME_NONNULL_END
