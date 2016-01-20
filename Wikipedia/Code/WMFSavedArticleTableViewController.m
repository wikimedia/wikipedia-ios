//
//  WMFSavedArticleTableViewController.m
//  Wikipedia
//
//  Created by Corey Floyd on 12/22/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFSavedArticleTableViewController.h"

#import "NSString+WMFExtras.h"

#import "WMFSavedPagesDataSource.h"
#import "MWKDataStore.h"
#import "MWKUserDataStore.h"

#import "MWKArticle.h"
#import "MWKTitle.h"
#import "MWKSavedPageEntry.h"

#import "WMFSaveButtonController.h"

#import "WMFArticlePreviewTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"


@implementation WMFSavedArticleTableViewController

- (MWKSavedPageList*)savedPageList {
    return self.dataStore.userDataStore.savedPageList;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = MWLocalizedString(@"saved-title", nil);

    [self.tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];

    WMFSavedPagesDataSource* ds = [[WMFSavedPagesDataSource alloc] initWithSavedPagesList:[self savedPageList]];

    ds.cellClass = [WMFArticlePreviewTableViewCell class];

    @weakify(self);
    ds.cellConfigureBlock = ^(WMFArticlePreviewTableViewCell* cell,
                              MWKSavedPageEntry* entry,
                              UITableView* tableView,
                              NSIndexPath* indexPath) {
        @strongify(self);
        MWKArticle* article = [[self dataStore] articleWithTitle:entry.title];
        [cell setSaveableTitle:article.title savedPageList:[self savedPageList]];
        cell.titleText       = article.title.text;
        cell.descriptionText = [article.entityDescription wmf_stringByCapitalizingFirstCharacter];
        cell.snippetText     = [article summary];
        [cell setImage:[article bestThumbnailImage]];
        [cell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
        cell.saveButtonController.analyticsSource = self;
    };

    self.dataSource = ds;
}

- (WMFEmptyViewType)emptyViewType {
    return WMFEmptyViewTypeNoSavedPages;
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSaved;
}

- (NSString*)analyticsName {
    return @"Saved";
}

- (BOOL)showsDeleteAllButton {
    return YES;
}

- (NSString*)deleteAllConfirmationText {
    return MWLocalizedString(@"saved-pages-clear-confirmation-heading", nil);
}

- (NSString*)deleteText {
    return MWLocalizedString(@"saved-pages-clear-delete-all", nil);
}

- (NSString*)deleteCancelText {
    return MWLocalizedString(@"saved-pages-clear-cancel", nil);
}

@end
