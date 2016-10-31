#import "WMFExploreViewController.h"

#import "BlocksKit+UIKit.h"
#import "Wikipedia-Swift.h"

#import <Masonry/Masonry.h>

#import "PiwikTracker+WMFExtensions.h"

#import "YapDatabase+WMFExtensions.h"
#import "WMFContentGroupDataStore.h"
#import "MWKDataStore.h"
#import "WMFArticlePreviewDataStore.h"
#import "MWKLanguageLinkController.h"

#import "WMFLocationManager.h"
#import "CLLocation+WMFBearing.h"

#import "WMFContentGroup+WMFFeedContentDisplaying.h"
#import "WMFContentGroup+WMFDatabaseStorable.h"
#import "WMFArticlePreview.h"
#import "MWKHistoryEntry.h"

#import "WMFFeedArticlePreview.h"
#import "WMFFeedNewsStory.h"
#import "WMFFeedImage.h"

#import "WMFDataSource.h"

#import "WMFSaveButtonController.h"

#import "WMFColumnarCollectionViewLayout.h"

#import "UIFont+WMFStyle.h"
#import "UIViewController+WMFEmptyView.h"
#import "UIView+WMFDefaultNib.h"

#import "WMFExploreSectionHeader.h"
#import "WMFExploreSectionFooter.h"
#import "WMFFeedNotificationHeader.h"

#import "WMFLeadingImageTrailingTextButton.h"

#import "WMFArticleListCollectionViewCell.h"
#import "WMFArticlePreviewCollectionViewCell.h"
#import "WMFPicOfTheDayCollectionViewCell.h"
#import "WMFNearbyArticleCollectionViewCell.h"

#import "UIViewController+WMFArticlePresentation.h"
#import "UIViewController+WMFSearch.h"

#import "WMFArticleViewController.h"
#import "WMFImageGalleryViewController.h"
#import "WMFRandomArticleViewController.h"
#import "WMFFirstRandomViewController.h"
#import "WMFMorePageListViewController.h"
#import "WMFSettingsViewController.h"

#import "NSProcessInfo+WMFOperatingSystemVersionChecks.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFFeedEmptyFooterReuseIdentifier = @"WMFFeedEmptyFooterReuseIdentifier";

@interface WMFExploreViewController () <WMFLocationManagerDelegate, WMFDataSourceDelegate, WMFColumnarCollectionViewLayoutDelegate, WMFArticlePreviewingActionsDelegate, UIViewControllerPreviewingDelegate>

@property (nonatomic, strong) WMFLocationManager *locationManager;

@property (nonatomic, strong) id<WMFDataSource> sectionDataSource;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, strong, nullable) WMFContentGroup *groupForPreviewedCell;

@property (nonatomic, weak) id<UIViewControllerPreviewing> previewingContext;

@property (nonatomic, strong) WMFContentGroupDataStore *internalContentStore;

@property (nonatomic, strong, nullable) WMFFeedNotificationHeader *notificationHeader;

@end

@implementation WMFExploreViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title = MWLocalizedString(@"home-title", nil);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b adjustsImageWhenHighlighted];
        UIImage *w = [UIImage imageNamed:@"W"];
        [b setImage:w forState:UIControlStateNormal];
        [b sizeToFit];
        @weakify(self);
        [b bk_addEventHandler:^(id sender) {
            @strongify(self);
            [self.collectionView setContentOffset:CGPointZero animated:YES];
        }
              forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = b;
        self.navigationItem.titleView.isAccessibilityElement = YES;
        self.navigationItem.titleView.accessibilityLabel = MWLocalizedString(@"home-accessibility-label", nil);
        self.navigationItem.titleView.accessibilityTraits |= UIAccessibilityTraitHeader;
        self.navigationItem.leftBarButtonItem = [self settingsBarButtonItem];
        self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItem];
    }
    return self;
}

#pragma mark - Accessors

- (void)setRefreshControl:(UIRefreshControl *)refreshControl {
    [_refreshControl removeFromSuperview];

    _refreshControl = refreshControl;

    if (_refreshControl) {
        _refreshControl.layer.zPosition = -100;
        if ([self.collectionView respondsToSelector:@selector(setRefreshControl:)]) {
            self.collectionView.refreshControl = _refreshControl;
        } else {
            [self.collectionView addSubview:_refreshControl];
        }
    }
}

- (UIBarButtonItem *)settingsBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(didTapSettingsButton:)];
}

- (WMFContentGroupDataStore *)internalContentStore {
    if (_internalContentStore == nil) {
        _internalContentStore = [[WMFContentGroupDataStore alloc] initWithDatabase:[YapDatabase sharedInstance]];
        _internalContentStore.databaseSyncingEnabled = NO;
    }
    return _internalContentStore;
}

- (MWKSavedPageList *)savedPages {
    NSParameterAssert(self.userStore);
    return self.userStore.savedPageList;
}

- (MWKHistoryList *)history {
    NSParameterAssert(self.userStore);
    return self.userStore.historyList;
}

- (WMFLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [WMFLocationManager fineLocationManager];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (id<WMFDataSource>)sectionDataSource {
    NSParameterAssert(self.internalContentStore);
    if (!_sectionDataSource) {
        _sectionDataSource = [self.internalContentStore contentGroupDataSource];
        _sectionDataSource.granularDelegateCallbacksEnabled = NO;
    }
    return _sectionDataSource;
}

- (NSURL *)currentSiteURL {
    return [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL];
}

- (NSUInteger)numberOfSectionsInExploreFeed {
    return [self.sectionDataSource numberOfItems];
}

- (BOOL)canScrollToTop {
    WMFContentGroup *group = [self sectionAtIndex:0];
    NSParameterAssert(group);
    NSArray *content = [self.internalContentStore contentForContentGroup:group];
    return [content count] > 0;
}

#pragma mark - Actions

- (void)didTapSettingsButton:(UIBarButtonItem *)sender {
    [self showSettings];
}

- (void)showSettings {
    UINavigationController *settingsContainer =
        [[UINavigationController alloc] initWithRootViewController:
                                            [WMFSettingsViewController settingsViewControllerWithDataStore:self.userStore
                                                                                              previewStore:self.previewStore]];
    [self presentViewController:settingsContainer
                       animated:YES
                     completion:nil];
}

#pragma mark - Feed Sources

- (void)updateFeedSources {
    WMFTaskGroup *group = [WMFTaskGroup new];
    [self.contentSources enumerateObjectsUsingBlock:^(id<WMFContentSource> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        //TODO: nearby doesnt always fire
        [group enter];
        [obj loadNewContentForce:NO
                      completion:^{
                          [group leave];
                      }];
    }];

    [group waitInBackgroundWithTimeout:12
                            completion:^{
                                [self resetRefreshControl];
                                [self.internalContentStore syncDataStoreToDatabase];
                            }];
}

- (void)updateFeedWithLatestDatabaseContent {
    [self.internalContentStore syncDataStoreToDatabase];
}

#pragma mark - Section Access

- (WMFContentGroup *)sectionAtIndex:(NSUInteger)sectionIndex {
    return (WMFContentGroup *)[self.sectionDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:sectionIndex inSection:0]];
}

- (WMFContentGroup *)sectionForIndexPath:(NSIndexPath *)indexPath {
    return (WMFContentGroup *)[self.sectionDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.section inSection:0]];
}

- (NSUInteger)indexForSection:(WMFContentGroup *)section {
    return [self.sectionDataSource indexPathForObject:section].row;
}

#pragma mark - Content Access

- (nullable NSArray<id> *)contentForGroup:(WMFContentGroup *)group {
    NSArray<id> *content = [self.internalContentStore contentForContentGroup:group];
    return content;
}

- (nullable NSArray<id> *)contentForSectionAtIndex:(NSUInteger)sectionIndex {
    WMFContentGroup *section = [self sectionAtIndex:sectionIndex];
    return [self contentForGroup:section];
}

- (nullable NSArray<NSURL *> *)contentURLsForGroup:(WMFContentGroup *)group {
    NSArray<id> *content = [self.internalContentStore contentForContentGroup:group];

    if ([group contentType] == WMFContentTypeTopReadPreview) {
        content = [content bk_map:^id(WMFFeedTopReadArticlePreview *obj) {
            return [obj articleURL];
        }];
    } else if ([group contentType] == WMFContentTypeStory) {
        content = [content bk_map:^id(WMFFeedNewsStory *obj) {
            return [[obj featuredArticlePreview] articleURL] ?: [[[obj articlePreviews] firstObject] articleURL];
        }];
    } else if ([group contentType] != WMFContentTypeURL) {
        content = nil;
    }
    return content;
}

- (nullable NSURL *)contentURLForIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    if ([section contentType] == WMFContentTypeTopReadPreview) {

        NSArray<WMFFeedTopReadArticlePreview *> *content = [self contentForSectionAtIndex:indexPath.section];

        if (indexPath.row >= [content count]) {
            NSAssert(false, @"Attempting to reference an out of bound index");
            return nil;
        }

        return [content[indexPath.row] articleURL];

    } else if ([section contentType] == WMFContentTypeURL) {

        NSArray<NSURL *> *content = [self contentForSectionAtIndex:indexPath.section];
        if (indexPath.row >= [content count]) {
            NSAssert(false, @"Attempting to reference an out of bound index");
            return nil;
        }
        return content[indexPath.row];

    } else if ([section contentType] == WMFContentTypeStory) {
        NSArray<WMFFeedNewsStory *> *content = [self contentForSectionAtIndex:indexPath.section];
        if (indexPath.row >= [content count]) {
            NSAssert(false, @"Attempting to reference an out of bound index");
            return nil;
        }
        return [[content[indexPath.row] featuredArticlePreview] articleURL] ?: [[[content[indexPath.row] articlePreviews] firstObject] articleURL];
    } else {
        return nil;
    }
}

- (nullable WMFArticlePreview *)previewForIndexPath:(NSIndexPath *)indexPath {
    NSURL *url = [self contentURLForIndexPath:indexPath];
    if (url == nil) {
        return nil;
    }
    return [self.previewStore itemForURL:url];
}

- (nullable WMFFeedTopReadArticlePreview *)topReadPreviewForIndexPath:(NSIndexPath *)indexPath {
    NSArray<WMFFeedTopReadArticlePreview *> *content = [self contentForSectionAtIndex:indexPath.section];
    return [content objectAtIndex:indexPath.row];
}

- (nullable MWKHistoryEntry *)userDataForIndexPath:(NSIndexPath *)indexPath {
    NSURL *url = [self contentURLForIndexPath:indexPath];
    if (url == nil) {
        return nil;
    }
    return [self.userStore entryForURL:url];
}

- (nullable WMFFeedImage *)imageInfoForIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    if ([section contentType] != WMFContentTypeImage) {
        return nil;
    }
    return [self.internalContentStore contentForContentGroup:section][indexPath.row];
}

#pragma mark - Refresh Control

- (void)resetRefreshControl {
    if (![self.refreshControl isRefreshing]) {
        return;
    }
    [self.refreshControl endRefreshing];
}

#pragma mark - Notification

- (void)sizeNotificationHeader {

    WMFFeedNotificationHeader *header = self.notificationHeader;
    if (!header.superview) {
        return;
    }

    //First layout pass to get height
    [header mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(-136));
        make.leading.trailing.equalTo(self.collectionView.superview);
    }];

    [header sizeToFit];
    [header setNeedsLayout];
    [header layoutIfNeeded];

    CGRect f = header.frame;

    //Second layout pass to reset the top constraint
    [header mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(-f.size.height));
        make.height.equalTo(@(f.size.height));
        make.leading.trailing.equalTo(self.collectionView.superview);
    }];

    [header sizeToFit];
    [header setNeedsLayout];
    [header layoutIfNeeded];

    UIEdgeInsets insets = self.collectionView.contentInset;
    insets.top = f.size.height;
    self.collectionView.contentInset = insets;
}

- (void)setNotificationHeaderBasedOnSizeClass {
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.notificationHeader = [WMFFeedNotificationHeader wmf_viewFromClassNib];
    } else {
        self.notificationHeader = [[[UINib nibWithNibName:@"WmfFeedNotificationHeaderiPad" bundle:nil] instantiateWithOwner:nil options:nil] firstObject];
    }
}

- (void)showNotificationHeader {

    if (self.notificationHeader) {
        [self.notificationHeader removeFromSuperview];
        self.notificationHeader = nil;
    }

    [self setNotificationHeaderBasedOnSizeClass];

    WMFFeedNotificationHeader *header = self.notificationHeader;
    [self.collectionView addSubview:self.notificationHeader];
    [self sizeNotificationHeader];

    @weakify(self);
    [header.enableNotificationsButton bk_addEventHandler:^(id sender) {
        @strongify(self);
        [[PiwikTracker sharedInstance] wmf_logActionEnableInContext:header contentType:header];

        [[WMFNotificationsController sharedNotificationsController] requestAuthenticationIfNecessaryWithCompletionHandler:^(BOOL granted, NSError *_Nullable error) {
            if (error) {
                [self wmf_showAlertWithError:error];
            }
        }];
        [[NSUserDefaults wmf_userDefaults] wmf_setInTheNewsNotificationsEnabled:YES];
        [self showHideNotificationIfNeccesary];

    }
                                        forControlEvents:UIControlEventTouchUpInside];

    [[NSUserDefaults wmf_userDefaults] wmf_setDidShowNewsNotificationCardInFeed:YES];
}

- (void)showHideNotificationIfNeccesary {

    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionLessThan:10]) {
        return;
    }

    if (![[NSUserDefaults wmf_userDefaults] wmf_inTheNewsNotificationsEnabled] && ![[NSUserDefaults wmf_userDefaults] wmf_didShowNewsNotificationCardInFeed]) {
        [self showNotificationHeader];

    } else {

        if (self.notificationHeader) {

            [UIView animateWithDuration:0.3
                animations:^{

                    UIEdgeInsets insets = self.collectionView.contentInset;
                    insets.top = 0.0;
                    self.collectionView.contentInset = insets;

                    self.notificationHeader.alpha = 0.0;

                }
                completion:^(BOOL finished) {

                    [self.notificationHeader removeFromSuperview];
                    self.notificationHeader = nil;

                }];
        }
    }
}

#pragma mark - UIViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self wmf_orientationMaskPortraitiPhoneAnyiPad];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerCellsAndViews];
    self.collectionView.scrollsToTop = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl bk_addEventHandler:^(id sender) {
        [self updateFeedSources];
    }
                           forControlEvents:UIControlEventValueChanged];
    [self resetRefreshControl];
    self.sectionDataSource.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForPreviewingIfAvailable];
    [self showHideNotificationIfNeccesary];
    for (UICollectionViewCell *cell in self.collectionView.visibleCells) {
        cell.selected = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    NSParameterAssert(self.contentStore);
    NSParameterAssert(self.userStore);
    NSParameterAssert(self.contentSources);
    NSParameterAssert(self.internalContentStore);
    [super viewDidAppear:animated];

    [[PiwikTracker sharedInstance] wmf_logView:self];
    [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_exploreViewActivity]];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self registerForPreviewingIfAvailable];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (self.notificationHeader) {
        [self showNotificationHeader];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.sectionDataSource numberOfItems];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    WMFContentGroup *contentGroup = [self sectionAtIndex:section];
    NSParameterAssert(contentGroup);
    NSArray *feedContent = [self contentForSectionAtIndex:section];
    return MIN([feedContent count], [contentGroup maxNumberOfCells]);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *contentGroup = [self sectionForIndexPath:indexPath];
    NSParameterAssert(contentGroup);
    WMFArticlePreview *preview = [self previewForIndexPath:indexPath];
    MWKHistoryEntry *userData = [self userDataForIndexPath:indexPath];

    switch ([contentGroup displayType]) {
        case WMFFeedDisplayTypePage: {
            WMFArticleListCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFArticleListCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configureListCell:cell withPreview:preview userData:userData atIndexPath:indexPath];
            return cell;
        } break;
        case WMFFeedDisplayTypePageWithPreview: {
            WMFArticlePreviewCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFArticlePreviewCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configurePreviewCell:cell withSection:contentGroup preview:preview userData:userData atIndexPath:indexPath];
            return cell;
        } break;
        case WMFFeedDisplayTypePageWithLocation: {
            WMFNearbyArticleCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFNearbyArticleCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configureNearbyCell:cell withPreview:preview userData:userData atIndexPath:indexPath];
            return cell;

        } break;
        case WMFFeedDisplayTypePhoto: {
            WMFFeedImage *imageInfo = [self imageInfoForIndexPath:indexPath];
            WMFPicOfTheDayCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFPicOfTheDayCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configurePhotoCell:cell withImageInfo:imageInfo atIndexPath:indexPath];
            return cell;
        } break;
        case WMFFeedDisplayTypeStory: {
            InTheNewsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[InTheNewsCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configureStoryCell:cell withSection:(WMFNewsContentGroup *)contentGroup preview:preview userData:userData atIndexPath:indexPath];
            return cell;
        } break;

        default:
            NSAssert(false, @"Unknown Display Type");
            return nil;
            break;
    }
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [self collectionView:collectionView viewForSectionHeaderAtIndexPath:indexPath];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return [self collectionView:collectionView viewForSectionFooterAtIndexPath:indexPath];
    } else {
        NSAssert(false, @"Unknown Supplementary View Type");
        return [UICollectionReusableView new];
    }
}

#pragma mark - UICollectionViewDelegate

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForItemAtIndexPath:(NSIndexPath *)indexPath forColumnWidth:(CGFloat)columnWidth {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];

    switch ([section displayType]) {
        case WMFFeedDisplayTypePage: {
            return [WMFArticleListCollectionViewCell estimatedRowHeight];
        } break;
        case WMFFeedDisplayTypePageWithPreview: {
            return [WMFArticlePreviewCollectionViewCell estimatedRowHeight];
        } break;
        case WMFFeedDisplayTypePageWithLocation: {
            return [WMFNearbyArticleCollectionViewCell estimatedRowHeight];
        } break;
        case WMFFeedDisplayTypePhoto: {
            return [WMFPicOfTheDayCollectionViewCell estimatedRowHeight];
        } break;
        case WMFFeedDisplayTypeStory: {
            return [InTheNewsCollectionViewCell estimatedRowHeight];
        } break;
        default:
            NSAssert(false, @"Unknown Content Type");
            return [WMFArticleListCollectionViewCell estimatedRowHeight];
            break;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForHeaderInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    return 66;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForFooterInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    WMFContentGroup *sectionObject = [self sectionAtIndex:section];
    if ([sectionObject moreType] == WMFFeedMoreTypeNone) {
        return 0.0;
    } else {
        return 50.0;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView prefersWiderColumnForSectionAtIndex:(NSUInteger)index {
    WMFContentGroup *section = [self sectionAtIndex:index];
    return [section prefersWiderColumn];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {

    if ([cell isKindOfClass:[WMFNearbyArticleCollectionViewCell class]] || [self isDisplayingLocationCell]) {
        [self.locationManager startMonitoringLocation];
    } else {
        [self.locationManager stopMonitoringLocation];
    }
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    [[PiwikTracker sharedInstance] wmf_logActionImpressionInContext:self contentType:section];
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSectionHeaderAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    NSParameterAssert(section);
    WMFExploreSectionHeader *header = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName] forIndexPath:indexPath];

    header.image = [[section headerIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    header.imageTintColor = [section headerIconTintColor];
    header.imageBackgroundColor = [section headerIconBackgroundColor];

    NSMutableAttributedString *title = [[section headerTitle] mutableCopy];
    [title addAttribute:NSFontAttributeName value:[UIFont wmf_exploreSectionHeaderTitleFont] range:NSMakeRange(0, title.length)];
    header.title = title;

    NSMutableAttributedString *subTitle = [[section headerSubTitle] mutableCopy];
    [subTitle addAttribute:NSFontAttributeName value:[UIFont wmf_exploreSectionHeaderSubTitleFont] range:NSMakeRange(0, subTitle.length)];
    header.subTitle = subTitle;

    @weakify(self);
    @weakify(section);
    header.whenTapped = ^{
        @strongify(self);
        [self didTapHeaderInSection:indexPath.section];
    };

    if (([section blackListOptions] & WMFFeedBlacklistOptionContent) && [section headerContentURL]) {
        header.rightButtonEnabled = YES;
        [[header rightButton] setImage:[UIImage imageNamed:@"overflow-mini"] forState:UIControlStateNormal];
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
        [header.rightButton bk_addEventHandler:^(id sender) {
            @strongify(section);
            @strongify(self);
            if (!self || !section) {
                return;
            }
            UIAlertController *menuActionSheet = [self menuActionSheetForSection:section];

            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                menuActionSheet.modalPresentationStyle = UIModalPresentationPopover;
                menuActionSheet.popoverPresentationController.sourceView = sender;
                menuActionSheet.popoverPresentationController.sourceRect = [sender bounds];
                menuActionSheet.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
                [self presentViewController:menuActionSheet animated:YES completion:nil];
            } else {
                menuActionSheet.popoverPresentationController.sourceView = self.navigationController.tabBarController.tabBar.superview;
                menuActionSheet.popoverPresentationController.sourceRect = self.navigationController.tabBarController.tabBar.frame;
                [self presentViewController:menuActionSheet animated:YES completion:nil];
            }
        }
                              forControlEvents:UIControlEventTouchUpInside];
    } else {
        header.rightButtonEnabled = NO;
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    }

    return header;
}

#pragma mark - WMFHeaderMenuProviding

- (UIAlertController *)menuActionSheetForSection:(WMFContentGroup *)section {
    NSURL *url = [section headerContentURL];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"home-hide-suggestion-prompt", nil)
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *_Nonnull action) {
                                                [self.userStore.blackList addBlackListArticleURL:url];
                                                [self.userStore notifyWhenWriteTransactionsComplete:^{
                                                    NSUInteger index = [self indexForSection:section];
                                                    self.sectionDataSource.delegate = nil;
                                                    [self updateFeedWithLatestDatabaseContent];
                                                    [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:index]];
                                                    self.sectionDataSource.delegate = self;
                                                }];
                                            }]];
    [sheet addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"home-hide-suggestion-cancel", nil) style:UIAlertActionStyleCancel handler:NULL]];
    return sheet;
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSectionFooterAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];
    NSParameterAssert(group);

    if ([group moreType] == WMFFeedMoreTypeNone) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFFeedEmptyFooterReuseIdentifier forIndexPath:indexPath];
    }

    WMFExploreSectionFooter *footer = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName] forIndexPath:indexPath];
    footer.visibleBackgroundView.alpha = 1.0;
    footer.moreLabel.text = [group footerText];
    footer.moreLabel.textColor = [UIColor wmf_exploreSectionFooterTextColor];
    @weakify(self);
    footer.whenTapped = ^{
        @strongify(self);
        [self presentMoreViewControllerForSectionAtIndex:indexPath.section animated:YES];
    };
    return footer;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [self presentDetailViewControllerForItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - Cells, Headers and Footers

- (void)registerCellsAndViews {

    [self.collectionView registerNib:[WMFExploreSectionHeader wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName]];

    [self.collectionView registerNib:[WMFExploreSectionFooter wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName]];

    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFFeedEmptyFooterReuseIdentifier];

    [self.collectionView registerNib:[WMFArticleListCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticleListCollectionViewCell wmf_nibName]];

    [self.collectionView registerNib:[WMFArticlePreviewCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticlePreviewCollectionViewCell wmf_nibName]];

    [self.collectionView registerNib:[WMFNearbyArticleCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFNearbyArticleCollectionViewCell wmf_nibName]];

    [self.collectionView registerNib:[WMFPicOfTheDayCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFPicOfTheDayCollectionViewCell wmf_nibName]];

    [self.collectionView registerNib:[InTheNewsCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[InTheNewsCollectionViewCell wmf_nibName]];
}

- (void)configureListCell:(WMFArticleListCollectionViewCell *)cell withPreview:(WMFArticlePreview *)preview userData:(MWKHistoryEntry *)userData atIndexPath:(NSIndexPath *)indexPath {
    cell.titleText = [preview.displayTitle wmf_stringByRemovingHTML];
    cell.titleLabel.accessibilityLanguage = userData.url.wmf_language;
    cell.descriptionText = [preview.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    [cell setImageURL:preview.thumbnailURL];
}

- (void)configurePreviewCell:(WMFArticlePreviewCollectionViewCell *)cell withSection:(WMFContentGroup *)section preview:(WMFArticlePreview *)preview userData:(MWKHistoryEntry *)userData atIndexPath:(NSIndexPath *)indexPath {
    cell.titleText = [preview.displayTitle wmf_stringByRemovingHTML];
    cell.descriptionText = [preview.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    cell.snippetText = preview.snippet;
    [cell setImageURL:preview.thumbnailURL];
    [cell setSaveableURL:preview.url savedPageList:self.userStore.savedPageList];
    cell.saveButtonController.analyticsContext = [self analyticsContext];
    cell.saveButtonController.analyticsContentType = [section analyticsContentType];
}

- (void)configureNearbyCell:(WMFNearbyArticleCollectionViewCell *)cell withPreview:(WMFArticlePreview *)preview userData:(MWKHistoryEntry *)userData atIndexPath:(NSIndexPath *)indexPath {
    cell.titleText = [preview.displayTitle wmf_stringByRemovingHTML];
    cell.descriptionText = [preview.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    [cell setImageURL:preview.thumbnailURL];
    [self updateLocationCell:cell location:preview.location];
}

- (void)configurePhotoCell:(WMFPicOfTheDayCollectionViewCell *)cell withImageInfo:(WMFFeedImage *)imageInfo atIndexPath:(NSIndexPath *)indexPath {
    [cell setImageURL:imageInfo.imageThumbURL];
    if (imageInfo.imageDescription.length) {
        [cell setDisplayTitle:[imageInfo.imageDescription wmf_stringByRemovingHTML]];
    } else {
        [cell setDisplayTitle:imageInfo.canonicalPageTitle];
    }
    //    self.referenceImageView = cell.potdImageView;
}

- (void)configureStoryCell:(InTheNewsCollectionViewCell *)cell withSection:(WMFNewsContentGroup *)section preview:(WMFArticlePreview *)preview userData:(MWKHistoryEntry *)userData atIndexPath:(NSIndexPath *)indexPath {
    NSArray<WMFFeedNewsStory *> *stories = [self contentForGroup:section];
    if (indexPath.item >= stories.count) {
        return;
    }
    WMFFeedNewsStory *story = stories[indexPath.item];
    cell.bodyHTML = story.storyHTML;
    cell.imageURL = preview.thumbnailURL;
}

- (BOOL)isDisplayingLocationCell {
    __block BOOL hasLocationCell = NO;
    [[self.collectionView visibleCells] enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj isKindOfClass:[WMFNearbyArticleCollectionViewCell class]]) {
            hasLocationCell = YES;
            *stop = YES;
        }

    }];
    return hasLocationCell;
}

- (void)updateLocationCells {
    [[self.collectionView indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:obj];
        if ([cell isKindOfClass:[WMFNearbyArticleCollectionViewCell class]]) {
            WMFArticlePreview *preview = [self previewForIndexPath:obj];
            [self updateLocationCell:(WMFNearbyArticleCollectionViewCell *)cell location:preview.location];
        }
    }];
}

- (void)updateLocationCell:(WMFNearbyArticleCollectionViewCell *)cell location:(CLLocation *)location {
    [cell setDistance:[self.locationManager.location distanceFromLocation:location]];
    [cell setBearing:[self.locationManager.location wmf_bearingToLocation:location forCurrentHeading:self.locationManager.heading]];
}

- (void)selectItem:(NSUInteger)item inSection:(NSUInteger)section {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

- (NSIndexPath *)topIndexPathToMaintainFocus {

    __block NSIndexPath *top = nil;
    [[self.collectionView indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        WMFContentGroup *group = [self sectionAtIndex:obj.section];
        if ([group isKindOfClass:[WMFMainPageContentGroup class]]) {
            return;
        }
        top = obj;
        *stop = YES;
    }];

    return top;
}

#pragma mark - Header Action

- (void)didTapHeaderInSection:(NSUInteger)section {
    WMFContentGroup *group = [self sectionAtIndex:section];

    switch ([group headerActionType]) {
        case WMFFeedHeaderActionTypeOpenHeaderContent: {
            NSURL *url = [group headerContentURL];
            [self wmf_pushArticleWithURL:url dataStore:self.userStore previewStore:self.previewStore animated:YES];
        } break;
        case WMFFeedHeaderActionTypeOpenFirstItem: {
            [self selectItem:0 inSection:section];
        } break;
        case WMFFeedHeaderActionTypeOpenMore: {
            [self presentMoreViewControllerForSectionAtIndex:section animated:YES];
        } break;
        default:
            NSAssert(false, @"Unknown header action");
            break;
    }
}

#pragma mark - More View Controller

- (void)presentMoreViewControllerForGroup:(WMFContentGroup *)group animated:(BOOL)animated {
    [[PiwikTracker sharedInstance] wmf_logActionTapThroughMoreInContext:self contentType:group];
    NSArray<NSURL *> *URLs = [self contentURLsForGroup:group];
    NSAssert([[URLs firstObject] isKindOfClass:[NSURL class]], @"Attempting to present More VC with somehting other than URLs");
    if (![[URLs firstObject] isKindOfClass:[NSURL class]]) {
        return;
    }

    switch (group.moreType) {
        case WMFFeedMoreTypePageList: {
            WMFMorePageListViewController *vc = [[WMFMorePageListViewController alloc] initWithGroup:group articleURLs:URLs userDataStore:self.userStore previewStore:self.previewStore];
            vc.cellType = WMFMorePageListCellTypeNormal;
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        case WMFFeedMoreTypePageListWithPreview: {
            WMFMorePageListViewController *vc = [[WMFMorePageListViewController alloc] initWithGroup:group articleURLs:URLs userDataStore:self.userStore previewStore:self.previewStore];
            vc.cellType = WMFMorePageListCellTypePreview;
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        case WMFFeedMoreTypePageListWithLocation: {
            WMFMorePageListViewController *vc = [[WMFMorePageListViewController alloc] initWithGroup:group articleURLs:URLs userDataStore:self.userStore previewStore:self.previewStore];
            vc.cellType = WMFMorePageListCellTypeLocation;
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        case WMFFeedMoreTypePageWithRandomButton: {
            WMFFirstRandomViewController *vc = [[WMFFirstRandomViewController alloc] initWithSiteURL:[self currentSiteURL] dataStore:self.userStore previewStore:self.previewStore];
            [self.navigationController pushViewController:vc animated:animated];
        } break;

        default:
            NSAssert(false, @"Unknown More Type");
            break;
    }
}

- (void)presentMoreViewControllerForSectionAtIndex:(NSUInteger)sectionIndex animated:(BOOL)animated {
    WMFContentGroup *group = [self sectionAtIndex:sectionIndex];
    [self presentMoreViewControllerForGroup:group animated:animated];
}

#pragma mark - Detail View Controller

- (nullable UIViewController *)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];

    switch ([group detailType]) {
        case WMFFeedDetailTypePage: {
            NSURL *url = [self contentURLForIndexPath:indexPath];
            WMFArticleViewController *vc = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.userStore previewStore:self.previewStore];
            return vc;
        } break;
        case WMFFeedDetailTypePageWithRandomButton: {
            NSURL *url = [self contentURLForIndexPath:indexPath];
            WMFRandomArticleViewController *vc = [[WMFRandomArticleViewController alloc] initWithArticleURL:url dataStore:self.userStore previewStore:self.previewStore];
            return vc;
        } break;
        case WMFFeedDetailTypeGallery: {
            return [[WMFPOTDImageGalleryViewController alloc] initWithDates:@[group.date]];
        } break;
        case WMFFeedDetailTypeStory: {
            NSArray<WMFFeedNewsStory *> *stories = [self contentForGroup:group];
            if (indexPath.item >= stories.count) {
                return nil;
            }
            WMFFeedNewsStory *story = stories[indexPath.item];
            InTheNewsViewController *vc = [self inTheNewsViewControllerForStory:story date:group.date];
            return vc;
        } break;
        default:
            NSAssert(false, @"Unknown Detail Type");
            break;
    }
    return nil;
}

- (void)presentDetailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    UIViewController *vc = [self detailViewControllerForItemAtIndexPath:indexPath];
    if (vc == nil) {
        return;
    }

    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];
    [[PiwikTracker sharedInstance] wmf_logActionTapThroughInContext:self contentType:group];

    switch ([group detailType]) {
        case WMFFeedDetailTypePage: {
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        case WMFFeedDetailTypePageWithRandomButton: {
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        case WMFFeedDetailTypeGallery: {
            [self presentViewController:vc animated:animated completion:nil];
        } break;
        case WMFFeedDetailTypeStory: {
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        default:
            NSAssert(false, @"Unknown Detail Type");
            break;
    }
}

#pragma mark - WMFDataSourceDelegate

- (void)dataSourceDidUpdateAllData:(id<WMFDataSource>)dataSource {
    [self.collectionView reloadData];
}

- (void)dataSource:(id<WMFDataSource>)dataSource didDeleteSectionsAtIndexes:(NSIndexSet *)indexes {
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView deleteSections:indexes];
    //    } completion:NULL];
}
- (void)dataSource:(id<WMFDataSource>)dataSource didInsertSectionsAtIndexes:(NSIndexSet *)indexes {
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView insertSections:indexes];
    //    } completion:NULL];
}

- (void)dataSource:(id<WMFDataSource>)dataSource didDeleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView deleteItemsAtIndexPaths:indexPaths];
    //    } completion:NULL];
}
- (void)dataSource:(id<WMFDataSource>)dataSource didInsertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView insertItemsAtIndexPaths:indexPaths];
    //    } completion:NULL];
}
- (void)dataSource:(id<WMFDataSource>)dataSource didMoveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView deleteItemsAtIndexPaths:@[fromIndexPath]];
    //        [self.collectionView insertItemsAtIndexPaths:@[toIndexPath]];
    //    } completion:NULL];
}
- (void)dataSource:(id<WMFDataSource>)dataSource didUpdateRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    //    } completion:NULL];
}

#pragma mark - WMFLocationManager

- (void)locationManager:(WMFLocationManager *)controller didUpdateLocation:(CLLocation *)location {
    [self updateLocationCells];
}

- (void)locationManager:(WMFLocationManager *)controller didUpdateHeading:(CLHeading *)heading {
    [self updateLocationCells];
}

- (void)locationManager:(WMFLocationManager *)controller didReceiveError:(NSError *)error {
    //TODO: probably not displaying the error, but maybe?
}

#pragma mark - Previewing

- (void)registerForPreviewingIfAvailable {
    [self wmf_ifForceTouchAvailable:^{
        [self unregisterPreviewing];
        self.previewingContext = [self registerForPreviewingWithDelegate:self
                                                              sourceView:self.collectionView];
    }
        unavailable:^{
            [self unregisterPreviewing];
        }];
}

- (void)unregisterPreviewing {
    if (self.previewingContext) {
        [self unregisterForPreviewingWithContext:self.previewingContext];
        self.previewingContext = nil;
    }
}

#pragma mark - WMFArticlePreviewingActionsDelegate

- (void)readMoreArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)articleController {
    [self wmf_pushArticleViewController:articleController animated:YES];
}

- (void)shareArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)articleController
                                       shareActivityController:(UIActivityViewController *)shareActivityController {
    [self presentViewController:shareActivityController animated:YES completion:NULL];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (nullable UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                       viewControllerForLocation:(CGPoint)location {
    UICollectionViewLayoutAttributes *layoutAttributes = nil;

    if ([self.collectionViewLayout respondsToSelector:@selector(layoutAttributesAtPoint:)]) {
        layoutAttributes = [(id)self.collectionViewLayout layoutAttributesAtPoint:location];
    }

    if (layoutAttributes == nil) {
        return nil;
    }

    NSIndexPath *previewIndexPath = layoutAttributes.indexPath;
    NSInteger section = previewIndexPath.section;
    NSInteger sectionCount = [self.collectionView numberOfItemsInSection:section];

    if ([layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter] && sectionCount > 0) {
        //preview the last item in the section when tapping the footer
        previewIndexPath = [NSIndexPath indexPathForItem:sectionCount - 1 inSection:section];
    }

    if (previewIndexPath.row >= sectionCount) {
        return nil;
    }

    WMFContentGroup *group = [self sectionForIndexPath:previewIndexPath];
    self.groupForPreviewedCell = group;

    previewingContext.sourceRect = [self.collectionView cellForItemAtIndexPath:previewIndexPath].frame;

    UIViewController *vc = [self detailViewControllerForItemAtIndexPath:previewIndexPath];
    [[PiwikTracker sharedInstance] wmf_logActionPreviewInContext:self contentType:group];

    if ([vc isKindOfClass:[WMFArticleViewController class]]) {
        ((WMFArticleViewController *)vc).articlePreviewingActionsDelegate = self;
    }

    return vc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController *)viewControllerToCommit {
    [[PiwikTracker sharedInstance] wmf_logActionTapThroughInContext:self contentType:self.groupForPreviewedCell];
    self.groupForPreviewedCell = nil;

    if ([viewControllerToCommit isKindOfClass:[WMFArticleViewController class]]) {
        [self wmf_pushArticleViewController:(WMFArticleViewController *)viewControllerToCommit animated:YES];
    } else if ([viewControllerToCommit isKindOfClass:[InTheNewsViewController class]]) {
        [self.navigationController pushViewController:viewControllerToCommit animated:YES];
    } else {
        [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

#pragma mark - In The News

- (InTheNewsViewController *)inTheNewsViewControllerForStory:(WMFFeedNewsStory *)story date:(nullable NSDate *)date {
    InTheNewsViewController *vc = [[InTheNewsViewController alloc] initWithStory:story dataStore:self.userStore previewStore:self.previewStore];
    NSString *format = MWLocalizedString(@"in-the-news-title-for-date", nil);
    if (format && date) {
        NSString *dateString = [[NSDateFormatter wmf_shortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:date];
        NSString *title = [format stringByReplacingOccurrencesOfString:@"$1" withString:dateString];
        vc.title = title;
    } else {
        vc.title = MWLocalizedString(@"in-the-news-title", nil);
    }
    return vc;
}

- (void)showInTheNewsForStory:(WMFFeedNewsStory *)story date:(nullable NSDate *)date animated:(BOOL)animated {
    InTheNewsViewController *vc = [self inTheNewsViewControllerForStory:story date:date];
    [self.navigationController pushViewController:vc animated:animated];
}

#pragma mark - Analytics

- (NSString *)analyticsContext {
    return @"Explore";
}

- (NSString *)analyticsName {
    return [self analyticsContext];
}

@end

NS_ASSUME_NONNULL_END
