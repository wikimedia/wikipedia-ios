//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SavedPagesViewController.h"
#import "WikipediaAppUtils.h"
#import "SavedPagesResultCell.h"
#import "Defines.h"
#import "SessionSingleton.h"
#import "NSString+Extras.h"
#import "DataHousekeeping.h"
#import "SavedPagesFunnel.h"
#import "NSObject+ConstraintsScale.h"
#import "PaddedLabel.h"
#import "QueuesSingleton.h"
#import "SavedArticlesFetcher.h"
#import "WMFProgressLineView.h"
#import <Masonry/Masonry.h>
#import "NSAttributedString+WMFSavedPagesAttributedStrings.h"
#import "UITableView+DynamicCellHeight.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "WMFArticlePresenter.h"
#import "UIView+WMFRTLMirroring.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

static NSString* const kSavedPagesDidShowCancelRefreshAlert = @"WMFSavedPagesDidShowCancelRefreshAlert";
static NSString* const kSavedPagesCellID                    = @"SavedPagesResultCell";

@interface SavedPagesViewController ()<SavedArticlesFetcherDelegate>

@property (strong, nonatomic) IBOutlet UITableView* tableView;

@property (strong, nonatomic) SavedPagesFunnel* funnel;

@property (strong, nonatomic) IBOutlet UIImageView* emptyImage;
@property (strong, nonatomic) IBOutlet PaddedLabel* emptyTitle;
@property (strong, nonatomic) IBOutlet PaddedLabel* emptyDescription;

@property (strong, nonatomic) IBOutlet UIView* emptyContainerView;

@property (strong, nonatomic) WMFProgressLineView* progressView;

@property (strong, nonatomic) MWKUserDataStore* userDataStore;
@property (strong, nonatomic, readonly) MWKSavedPageList* savedPageList;

@property (strong, nonatomic) SavedPagesResultCell* offScreenSizingCell;

@property (strong, nonatomic) UIImage* placeholderThumbnailImage;

@property (strong, nonatomic) UIBarButtonItem* reloadButtonItem;
@property (strong, nonatomic) UIBarButtonItem* trashButtonItem;
@property (strong, nonatomic) UIBarButtonItem* cancelButton;

@end

@implementation SavedPagesViewController

#pragma mark - Accessors

- (MWKSavedPageList*)savedPageList {
    return self.userDataStore.savedPageList;
}

#pragma mark - NavBar

- (NSString*)title {
    return MWLocalizedString(@"saved-pages-title", nil);
}

- (WMFProgressLineView*)progressView {
    if (!_progressView) {
        WMFProgressLineView* progress = [[WMFProgressLineView alloc] initWithFrame:CGRectZero];
        _progressView = progress;
    }

    return _progressView;
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Top menu

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - UIViewController

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.tableView.editing = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    SavedArticlesFetcher* fetcher = [SavedArticlesFetcher sharedInstance];

    if (fetcher) {
        [self resumeRefresh];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationController.navigationBar wmf_mirrorIfDeviceRTL];

    @weakify(self)
    UIBarButtonItem * xButton = [UIBarButtonItem wmf_buttonType:WMF_BUTTON_X handler:^(id sender){
        @strongify(self)
        [self dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItems = @[xButton];

    self.reloadButtonItem = [UIBarButtonItem wmf_buttonType:WMF_BUTTON_RELOAD
                                                    handler:^(id sender){
        @strongify(self)
        [self startRefresh];
    }];
    self.trashButtonItem = [UIBarButtonItem wmf_buttonType:WMF_BUTTON_TRASH
                                                   handler:^(id sender){
        @strongify(self)
        [self showDeleteAllDialog];
    }];

    self.cancelButton = [[UIBarButtonItem alloc] bk_initWithTitle:MWLocalizedString(@"saved-pages-clear-cancel", nil) style:UIBarButtonItemStylePlain handler:^(id sender){
        @strongify(self)
        [self cancelRefresh];
    }];

    self.navigationItem.rightBarButtonItems = @[self.trashButtonItem, self.reloadButtonItem];

    self.userDataStore = [SessionSingleton sharedInstance].userDataStore;

    self.emptyDescription.text = MWLocalizedString(@"saved-pages-description", nil);
    self.emptyTitle.text       = MWLocalizedString(@"saved-pages-none", nil);

    self.funnel = [[SavedPagesFunnel alloc] init];

    self.tableView.contentInset = UIEdgeInsetsMake(4.0f * MENUS_SCALE_MULTIPLIER, 0, 4.0f * MENUS_SCALE_MULTIPLIER, 0);

    // Register the Saved Pages results cell for reuse
    [self.tableView registerNib:[UINib nibWithNibName:@"SavedPagesResultPrototypeView" bundle:nil] forCellReuseIdentifier:kSavedPagesCellID];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self setEmptyOverlayAndTrashIconVisibility];

    [self adjustConstraintsScaleForViews:@[self.emptyImage, self.emptyTitle, self.emptyDescription, self.emptyContainerView]];

    self.emptyTitle.font       = [UIFont boldSystemFontOfSize:17.0 * MENUS_SCALE_MULTIPLIER];
    self.emptyDescription.font = [UIFont systemFontOfSize:14.0 * MENUS_SCALE_MULTIPLIER];

    // Single off-screen cell for determining dynamic cell height.
    self.offScreenSizingCell = (SavedPagesResultCell*)[self.tableView dequeueReusableCellWithIdentifier:kSavedPagesCellID];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.savedPageList.length;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    SavedPagesResultCell* cell = (SavedPagesResultCell*)[tableView dequeueReusableCellWithIdentifier:kSavedPagesCellID];

    MWKArticle* article = [self articleForIndexPath:indexPath];
    [self updateViewsInCell:cell forIndexPath:indexPath withArticle:article];

    MWKImage* thumb = [article.thumbnail largestCachedVariant];

    if (thumb) {
        cell.imageView.image = [thumb asUIImage];
        cell.useField        = YES;
        return cell;
    }

    cell.imageView.image = self.placeholderThumbnailImage;
    cell.useField        = NO;

    return cell;
}

- (UIImage*)placeholderThumbnailImage {
    if (!_placeholderThumbnailImage) {
        _placeholderThumbnailImage = [UIImage imageNamed:@"logo-placeholder-saved.png"];
    }
    return _placeholderThumbnailImage;
}

- (NSAttributedString*)getAttributedStringForArticle:(MWKArticle*)article {
    return [NSAttributedString wmf_attributedStringWithTitle:article.title.text
                                                 description:article.entityDescription
                                                    language:[WikipediaAppUtils languageNameForCode:article.site.language]];
}

- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self.savedPageList entryAtIndex:indexPath.row];
    return [self.userDataStore.dataStore articleWithTitle:savedEntry.title];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    // Update the sizing cell with any data which could change the cell height.
    [self updateViewsInCell:self.offScreenSizingCell forIndexPath:indexPath];
    // Determine height for the current configuration of the sizing cell.
    return [tableView heightForSizingCell:self.offScreenSizingCell];
}

- (void)updateViewsInCell:(SavedPagesResultCell*)cell forIndexPath:(NSIndexPath*)indexPath {
    [self updateViewsInCell:cell forIndexPath:indexPath withArticle:[self articleForIndexPath:indexPath]];
}

- (void)updateViewsInCell:(SavedPagesResultCell*)cell
             forIndexPath:(NSIndexPath*)indexPath
              withArticle:(MWKArticle*)article {
    // Update the sizing cell with any data which could change the cell height.
    cell.savedItemLabel.attributedText = [self getAttributedStringForArticle:article];
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    return YES;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        self.tableView.editing = NO;
        [self performSelector:@selector(deleteSavedPageForIndexPath:) withObject:indexPath afterDelay:0.15f];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self.savedPageList entryAtIndex:indexPath.row];

    [[WMFArticlePresenter sharedInstance] presentArticleWithTitle:savedEntry.title
                                                  discoveryMethod:MWKHistoryDiscoveryMethodSaved];
}

#pragma mark - UI Updates

- (void)showCancelButton {
    self.navigationItem.rightBarButtonItems = @[self.cancelButton];
}

- (void)hideCancelButton {
    self.navigationItem.rightBarButtonItems = @[self.trashButtonItem, self.reloadButtonItem];
}

- (void)showRefreshButton {
    self.reloadButtonItem.enabled = YES;
}

- (void)hideRefreshButton {
    self.reloadButtonItem.enabled = NO;
}

- (void)showRefreshTitle {
//TODO: add i18n!!!
    self.title = @"Updating";
}

- (void)hideRefreshTitle {
    self.title = MWLocalizedString(@"saved-pages-title", nil);
}

- (void)showProgressView {
    self.progressView.alpha = 1.0;
    [self.view addSubview:self.progressView];
    [self.progressView mas_remakeConstraints:^(MASConstraintMaker* make) {
        make.top.equalTo(self.view.mas_top);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.height.equalTo(@2.0);
    }];
}

- (void)hideProgressView {
    self.progressView.alpha = 0.0;
}

- (void)hideTrashButton {
    self.trashButtonItem.enabled = NO;
}

- (void)showTrashButton {
    self.trashButtonItem.enabled = YES;
}

- (void)setEmptyOverlayAndTrashIconVisibility {
    BOOL savedPageFound = (self.savedPageList.length > 0);

    self.emptyOverlay.hidden      = savedPageFound;
    self.reloadButtonItem.enabled = savedPageFound;

    if (savedPageFound) {
        [self showTrashButton];
    } else {
        [self hideTrashButton];
    }
}

- (void)showCancelRefreshAlertIfFirstTime {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    BOOL didShowAlert = [defaults boolForKey:kSavedPagesDidShowCancelRefreshAlert];

    if (!didShowAlert) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:MWLocalizedString(@"saved-pages-refresh-cancel-alert-title", nil) message:MWLocalizedString(@"saved-pages-refresh-cancel-alert-message", nil) delegate:nil cancelButtonTitle:MWLocalizedString(@"saved-pages-refresh-cancel-alert-button", nil) otherButtonTitles:nil];

        [alert show];

        [defaults setBool:YES forKey:kSavedPagesDidShowCancelRefreshAlert];
    }
}

#pragma mark - Delete

- (void)deleteSavedPageForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self.savedPageList entryAtIndex:indexPath.row];
    if (savedEntry) {
        dispatch_promise(^{
            return [self.userDataStore.savedPageList removeSavedPageWithTitle:savedEntry.title];
        }).then(^(){
            return [self.userDataStore.savedPageList save];
        }).then(^(){
            // Remove any orphaned images.
            DataHousekeeping* dataHouseKeeping = [[DataHousekeeping alloc] init];
            [dataHouseKeeping performHouseKeeping];

            [self.tableView beginUpdates];

            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

            [self.tableView endUpdates];

            [self setEmptyOverlayAndTrashIconVisibility];

            [self.funnel logDelete];
        });
    }
}

- (void)deleteAllSavedPages {
    dispatch_promise(^{
        return [self.userDataStore.savedPageList removeAllSavedPages];
    }).then(^(){
        return [self.userDataStore.savedPageList save];
    }).then(^(){
        [self.tableView reloadData];

        [self setEmptyOverlayAndTrashIconVisibility];

        // Remove any orphaned images.
        DataHousekeeping* dataHouseKeeping = [[DataHousekeeping alloc] init];
        [dataHouseKeeping performHouseKeeping];
    });
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.cancelButtonIndex != buttonIndex) {
        [self deleteAllSavedPages];
    }
}

- (void)showDeleteAllDialog {
    UIAlertView* dialog =
        [[UIAlertView alloc] initWithTitle:MWLocalizedString(@"saved-pages-clear-confirmation-heading", nil)
                                   message:MWLocalizedString(@"saved-pages-clear-confirmation-sub-heading", nil)
                                  delegate:self
                         cancelButtonTitle:MWLocalizedString(@"saved-pages-clear-cancel", nil)
                         otherButtonTitles:MWLocalizedString(@"saved-pages-clear-delete-all", nil), nil];
    [dialog show];
}

#pragma mark - Refresh

- (void)startRefresh {
    [[QueuesSingleton sharedInstance].savedPagesFetchManager.operationQueue cancelAllOperations];

    SavedArticlesFetcher* fetcher = [[SavedArticlesFetcher alloc] initAndFetchArticlesForSavedPageList:self.savedPageList inDataStore:self.userDataStore.dataStore withManager:[QueuesSingleton sharedInstance].savedPagesFetchManager thenNotifyDelegate:self];

    [SavedArticlesFetcher setSharedInstance:fetcher];

    self.progressView.progress = 0.0;

    [UIView animateWithDuration:0.25 animations:^{
        [self hideRefreshButton];
        [self showProgressView];
        [self showRefreshTitle];
        [self hideTrashButton];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            [self showCancelButton];
        }];
    }];
}

- (void)resumeRefresh {
    [[SavedArticlesFetcher sharedInstance] getProgress:^(CGFloat progress) {
        if (progress < 100) {
            self.progressView.progress = progress;
            [SavedArticlesFetcher sharedInstance].fetchFinishedDelegate = self;

            [self showProgressView];
            [self showCancelButton];
            [self hideTrashButton];
            [self hideRefreshButton];
            [self showRefreshTitle];
        }
    }];
}

- (void)finishRefresh {
    [SavedArticlesFetcher sharedInstance].fetchFinishedDelegate = nil;
    [SavedArticlesFetcher setSharedInstance:nil];

    [UIView animateWithDuration:0.25 delay:0.5 options:0 animations:^{
        [self hideProgressView];
        [self hideCancelButton];
        [self hideRefreshTitle];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            [self showRefreshButton];
            if (self.savedPageList.length > 0) {
                [self showTrashButton];
            }
        }];

        self.progressView.progress = 0.0;
    }];
}

- (void)cancelRefresh {
    [[QueuesSingleton sharedInstance].savedPagesFetchManager.operationQueue cancelAllOperations];

    [self finishRefresh];

    [self showCancelRefreshAlertIfFirstTime];
}

#pragma mark - SavedArticlesFetcherDelegate

- (void)savedArticlesFetcher:(SavedArticlesFetcher*)savedArticlesFetcher didFetchArticle:(MWKArticle*)article progress:(CGFloat)progress status:(FetchFinalStatus)status error:(NSError*)error {
    [self.progressView setProgress:progress animated:YES];
}

- (void)fetchFinished:(id)sender fetchedData:(id)fetchedData status:(FetchFinalStatus)status error:(NSError*)error {
    __weak __typeof(self) weakSelf = self;

    [self.progressView setProgress:1.0 animated:YES completion:^{
        __typeof(weakSelf) strongSelf = weakSelf;

        [strongSelf finishRefresh];
    }];
}

@end
