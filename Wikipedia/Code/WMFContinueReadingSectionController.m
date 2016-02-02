//
//  WMFContinueReadingSectionController.m
//  Wikipedia
//
//  Created by Corey Floyd on 10/7/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFContinueReadingSectionController.h"
#import "WMFContinueReadingTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKTitle.h"
#import "MWKDataStore.h"
#import "MWKArticle.h"
#import "NSString+WMFExtras.h"
#import "UITableViewCell+WMFLayout.h"
#import "MWKSection.h"
#import "MWKSectionList.h"
#import "WikipediaAppUtils.h"
#import "Wikipedia-Swift.h"

static NSString* const WMFContinueReadingSectionIdentifier = @"WMFContinueReadingSectionIdentifier";

@interface WMFContinueReadingSectionController ()

@property (nonatomic, strong, readwrite) MWKTitle* title;
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;

@end

@implementation WMFContinueReadingSectionController

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);
    self = [super initWithItems:@[title]];
    if (self) {
        self.title     = title;
        self.dataStore = dataStore;
    }
    return self;
}

#pragma mark - WMFBaseExploreSectionController

- (id)sectionIdentifier {
    return WMFContinueReadingSectionIdentifier;
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"home-continue-reading-mini"];
}

- (UIColor*)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor*)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString*)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-continue-reading-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString*)headerSubTitle {
    NSDate* resignActiveDate     = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];
    NSString* relativeTimeString = [WikipediaAppUtils relativeTimestamp:resignActiveDate];
    return [[NSAttributedString alloc] initWithString:[relativeTimeString wmf_stringByCapitalizingFirstCharacter] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString*)cellIdentifier {
    return [WMFContinueReadingTableViewCell wmf_nibName];
}

- (UINib*)cellNib {
    return [WMFContinueReadingTableViewCell wmf_classNib];
}

- (NSUInteger)numberOfPlaceholderCells {
    return 0;
}

- (void)configureCell:(WMFContinueReadingTableViewCell*)cell withItem:(MWKTitle*)item atIndexPath:(NSIndexPath*)indexPath {
    cell.title.text   = item.text;
    cell.summary.text = [self summaryForTitle:item];
    [cell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodReloadFromNetwork;
}

- (CGFloat)estimatedRowHeight {
    return [WMFContinueReadingTableViewCell estimatedRowHeight];
}

- (NSString*)analyticsName {
    return @"Continue Reading";
}

#pragma mark - WMFTitleProviding

- (nullable MWKTitle*)titleForItemAtIndexPath:(NSIndexPath*)indexPath {
    return self.title;
}

#pragma mark - Utility

- (NSString*)summaryForTitle:(MWKTitle*)title {
    MWKArticle* cachedArticle = [self.dataStore existingArticleWithTitle:self.title];
    if (cachedArticle.entityDescription.length) {
        return [cachedArticle.entityDescription wmf_stringByCapitalizingFirstCharacter];
    } else {
        return [[cachedArticle.sections firstNonEmptySection] summary];
    }
}

@end
