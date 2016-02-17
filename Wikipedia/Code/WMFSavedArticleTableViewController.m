//
//  WMFSavedArticleTableViewController.m
//  Wikipedia
//
//  Created by Corey Floyd on 12/22/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFSavedArticleTableViewController.h"
#import "PiwikTracker+WMFExtensions.h"
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

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title = MWLocalizedString(@"saved-title", nil);
}

- (MWKSavedPageList*)savedPageList {
    return self.dataStore.userDataStore.savedPageList;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];

    self.tableView.estimatedRowHeight = [WMFArticlePreviewTableViewCell estimatedRowHeight];

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
        cell.saveButtonController.analyticsContext = self;
    };

    self.dataSource = ds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[PiwikTracker sharedInstance] wmf_logView:self];
}

- (WMFEmptyViewType)emptyViewType {
    return WMFEmptyViewTypeNoSavedPages;
}

- (NSString*)analyticsContext {
    return @"Saved";
}

- (NSString*)analyticsName {
    return [self analyticsContext];
}

- (BOOL)showsDeleteAllButton {
    return YES;
}

- (NSString*)deleteButtonText {
    return MWLocalizedString(@"saved-clear-all", nil);
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
