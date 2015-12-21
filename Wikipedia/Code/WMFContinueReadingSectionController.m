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
#import "NSString+Extras.h"
#import "UITableViewCell+WMFLayout.h"
#import "MWKSection.h"
#import "MWKSectionList.h"

static NSString* const WMFContinueReadingSectionIdentifier = @"WMFContinueReadingSectionIdentifier";

@interface WMFContinueReadingSectionController ()

@property (nonatomic, strong, readwrite) MWKTitle* title;
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;

@end

@implementation WMFContinueReadingSectionController
@synthesize delegate = _delegate;

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.title     = title;
        self.dataStore = dataStore;
    }
    return self;
}

- (id)sectionIdentifier {
    return WMFContinueReadingSectionIdentifier;
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"home-continue-reading-mini"];
}

- (NSAttributedString*)headerText {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"home-continue-reading-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_homeSectionHeaderTextColor]}];
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodReloadFromNetwork;
}

- (NSArray*)items {
    return @[self.title];
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    return self.title;
}

- (void)registerCellsInTableView:(UITableView*)tableView {
    [tableView registerNib:[WMFContinueReadingTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFContinueReadingTableViewCell identifier]];
}

- (UITableViewCell*)dequeueCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    return [WMFContinueReadingTableViewCell cellForTableView:tableView];
}

- (void)configureCell:(UITableViewCell*)cell withObject:(id)object inTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFContinueReadingTableViewCell class]]) {
        WMFContinueReadingTableViewCell* readingCell = (id)cell;
        readingCell.title.text   = self.title.text;
        readingCell.summary.text = [self summaryForTitle:self.title];
        [readingCell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
    }
}

- (NSString*)summaryForTitle:(MWKTitle*)title {
    MWKArticle* cachedArticle = [self.dataStore existingArticleWithTitle:self.title];
    if (cachedArticle.entityDescription.length) {
        return [cachedArticle.entityDescription wmf_stringByCapitalizingFirstCharacter];
    } else {
        return [[cachedArticle.sections firstNonEmptySection] summary];
    }
}

- (NSString*)analyticsName {
    return @"Continue Reading";
}

@end
